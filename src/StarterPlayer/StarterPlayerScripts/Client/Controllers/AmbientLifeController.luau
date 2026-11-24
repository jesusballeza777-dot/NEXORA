--!strict
-- Vida ambiental del valle (Bloque J), solo en el cliente y con LOD por distancia.
-- Anima las instancias que el servidor etiqueta con CollectionService:
--   AmbientSway         · faroles que oscilan, papel picado que se mece, canoas que flotan
--   AmbientHeart        · el corazón del Gran Nexo que late (lub-dub) y su luz
--   GabineteWalk        · el Gabinete que Camina: vuelta al árbol con marcha trípode
--   AmbientBirds        · bandadas que circulan
--   AmbientFish         · peces que saltan de vez en cuando
--   AmbientButterflies  · mariposas sobre las flores
-- Reglas: las poses salen de funciones puras (AmbientMotion); un único Heartbeat con
-- presupuesto de piezas por fotograma (AmbientMotion.schedule); fuera de `far` no se
-- anima nada y entre `near` y `far` va a media frecuencia (Config/Landscape.Life.lod).
-- Todas las piezas se mueven en un solo Workspace:BulkMoveTo por fotograma.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local AmbientMotion = require(script.Parent.AmbientMotion)

local AmbientLifeController = {}

local Life = Landscape.Life

AmbientLifeController.Tags =
	{ "AmbientSway", "AmbientHeart", "GabineteWalk", "AmbientBirds", "AmbientFish", "AmbientButterflies" }

type Rest = { part: BasePart, offset: CFrame }
type Agent = {
	kind: string,
	inst: Instance,
	anchor: Vector3,
	lod: { near: number, far: number },
	tier: AmbientMotion.Tier,
	cost: number,
	seed: number,
	pivot: CFrame,
	parts: { Rest },
	data: any,
}

local agents: { Agent } = {}
local tracked: { [Instance]: Agent } = {}
local frame = 0
local lastRefresh = -math.huge
local moveParts: { BasePart } = {}
local moveCFrames: { CFrame } = {}

local function rest(root: Instance, pivot: CFrame): { Rest }
	local out: { Rest } = {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(out, { part = d, offset = pivot:ToObjectSpace(d.CFrame) })
		end
	end
	return out
end

local function push(part: BasePart, cf: CFrame)
	table.insert(moveParts, part)
	table.insert(moveCFrames, cf)
end

local function pivotOf(inst: Instance): CFrame
	if inst:IsA("Model") then
		return inst.WorldPivot
	end
	return (inst :: BasePart).CFrame
end

local function wings(model: Instance, pivot: CFrame): { [string]: Rest }
	local out: { [string]: Rest } = {}
	for _, d in ipairs(model:GetChildren()) do
		if d:IsA("BasePart") then
			out[d.Name] = { part = d, offset = pivot:ToObjectSpace(d.CFrame) }
		end
	end
	return out
end

-- Registra una instancia etiquetada (una vez); calcula las posiciones de reposo
function AmbientLifeController.track(inst: Instance, tag: string): Agent?
	if tracked[inst] then
		return tracked[inst]
	end
	local pivot = pivotOf(inst)
	local agent: Agent = {
		kind = tag,
		inst = inst,
		anchor = pivot.Position,
		lod = Life.lod.sway,
		tier = "off",
		cost = 1,
		seed = (pivot.Position.X * 0.37 + pivot.Position.Z * 0.61) % 6.28,
		pivot = pivot,
		parts = {},
		data = {},
	}
	if tag == "AmbientSway" then
		local kind = inst:GetAttribute("SwayKind") or "lantern"
		agent.data.kind = kind
		if kind == "papel" then
			local flags = {}
			for _, d in ipairs(inst:GetChildren()) do
				if d:IsA("BasePart") and d.Name == "Flag" then
					table.insert(flags, { part = d, offset = d.CFrame, half = d.Size.Y / 2 })
				end
			end
			agent.data.flags = flags
			agent.cost = math.max(1, #flags)
		else
			agent.parts = rest(inst, pivot)
			agent.cost = math.max(1, #agent.parts)
		end
	elseif tag == "AmbientHeart" then
		local heart = inst :: BasePart
		local core = heart.Parent and heart.Parent:FindFirstChild("HeartCore")
		agent.lod = Life.lod.heart
		agent.data.heart = heart
		agent.data.baseSize = heart:GetAttribute("BaseSize") or heart.Size
		agent.data.light = core and core:FindFirstChildOfClass("PointLight")
		agent.data.brightness = if agent.data.light then agent.data.light.Brightness else 0
	elseif tag == "GabineteWalk" then
		local tree = World.GranNexo.position
		local center = Vector3.new(tree[1], 0, tree[3])
		local dock = pivot.Position
		agent.lod = Life.lod.gabinete
		agent.data.center = center
		agent.data.dockAngle = math.atan2(dock.Z - center.Z, dock.X - center.X)
		local body = inst:FindFirstChild("Body")
		agent.parts = if body then rest(body, pivot) else {}
		local legs = {}
		for _, leg in ipairs(inst:GetChildren()) do
			if leg:IsA("Model") and string.match(leg.Name, "^Leg%d$") then
				local hip = leg.WorldPivot
				table.insert(legs, {
					hip = pivot:ToObjectSpace(hip),
					side = leg:GetAttribute("Side") or 1,
					gait = leg:GetAttribute("Gait") or 0,
					parts = rest(leg, hip),
				})
			end
		end
		agent.data.legs = legs
		local cost = #agent.parts
		for _, l in ipairs(legs) do
			cost += #l.parts
		end
		agent.cost = math.max(1, cost)
	elseif tag == "AmbientBirds" then
		local cfg = Life.flocks[inst:GetAttribute("Flock") or 1]
		agent.lod = Life.lod.birds
		agent.data.cfg = cfg
		agent.anchor = Vector3.new(cfg.center[1], cfg.center[2], cfg.center[3])
		local birds = {}
		for _, b in ipairs(inst:GetChildren()) do
			if b:IsA("Model") then
				table.insert(birds, wings(b, b.WorldPivot))
			end
		end
		agent.data.birds = birds
		agent.cost = #birds * 3
	elseif tag == "AmbientFish" then
		agent.lod = Life.lod.fish
		agent.data.cfg = Life.fish[inst:GetAttribute("Fish") or 1]
		agent.parts = rest(inst, pivot)
		agent.data.visible = false
		agent.cost = #agent.parts
	elseif tag == "AmbientButterflies" then
		local cfg = Life.butterflies[inst:GetAttribute("Group") or 1]
		agent.lod = Life.lod.butterflies
		agent.data.cfg = cfg
		local list = {}
		for _, b in ipairs(inst:GetChildren()) do
			if b:IsA("Model") then
				table.insert(list, wings(b, b.WorldPivot))
			end
		end
		agent.data.list = list
		agent.cost = #list * 2
	else
		return nil
	end
	tracked[inst] = agent
	table.insert(agents, agent)
	return agent
end

function AmbientLifeController.untrack(inst: Instance)
	local agent = tracked[inst]
	if agent then
		tracked[inst] = nil
		local i = table.find(agents, agent)
		if i then
			table.remove(agents, i)
		end
	end
end

local function setVisible(rests: { Rest }, visible: boolean)
	for _, r in ipairs(rests) do
		r.part.Transparency = if visible then 0 else 1
	end
end

local Apply: { [string]: (Agent, number) -> () } = {}

Apply.AmbientSway = function(a: Agent, t: number)
	local kind = a.data.kind
	if kind == "papel" then
		for i, f in ipairs(a.data.flags) do
			local pitch = AmbientMotion.sway(t, a.seed + i * 0.7, Life.sway.papel)
			local hinge = CFrame.new(0, f.half, 0)
			push(f.part, f.offset * hinge * CFrame.Angles(pitch, 0, 0) * hinge:Inverse())
		end
		return
	end
	local cf: CFrame
	if kind == "bob" then
		local dy, roll = AmbientMotion.bob(t, a.seed)
		cf = a.pivot * CFrame.new(0, dy, 0) * CFrame.Angles(0, 0, roll)
	else
		local pitch, roll = AmbientMotion.sway(t, a.seed, Life.sway.lantern)
		cf = a.pivot * CFrame.Angles(pitch, 0, roll)
	end
	for _, r in ipairs(a.parts) do
		push(r.part, cf * r.offset)
	end
end

Apply.AmbientHeart = function(a: Agent, t: number)
	local scale, glow = AmbientMotion.heart(t, Life.heart)
	a.data.heart.Size = a.data.baseSize * scale
	if a.data.light then
		a.data.light.Brightness = a.data.brightness * glow
	end
end

Apply.GabineteWalk = function(a: Agent, t: number)
	local pose = AmbientMotion.gabinete(t, Landscape.Gabinete, a.data.dockAngle)
	local c = a.data.center
	local pos = Vector3.new(c.X + pose.x, pose.bob, c.Z + pose.z)
	local body = CFrame.lookAt(pos, pos + Vector3.new(pose.lookX, 0, pose.lookZ))
	for _, r in ipairs(a.parts) do
		push(r.part, body * r.offset)
	end
	for _, leg in ipairs(a.data.legs) do
		local swing, lift = AmbientMotion.leg(pose.phase, leg.gait, pose.walking)
		-- La pata cuelga de la cadera: compensa el balanceo del cuerpo para no flotar
		local hip = body * leg.hip * CFrame.new(0, -pose.bob, 0)
		local legCf = hip * CFrame.Angles(0, swing * leg.side, 0) * CFrame.Angles(0, 0, lift * leg.side)
		for _, r in ipairs(leg.parts) do
			push(r.part, legCf * r.offset)
		end
	end
end

Apply.AmbientBirds = function(a: Agent, t: number)
	local cfg = a.data.cfg
	for i, b in ipairs(a.data.birds) do
		local pose = AmbientMotion.bird(t, i, cfg)
		local pos = a.anchor + Vector3.new(pose.x, pose.y, pose.z)
		local cf = CFrame.lookAt(pos, pos + Vector3.new(pose.lookX, 0, pose.lookZ))
		if b.Body then
			push(b.Body.part, cf * b.Body.offset)
		end
		for name, side in pairs({ WingL = -1, WingR = 1 }) do
			local w = b[name]
			if w then
				push(w.part, cf * CFrame.Angles(0, 0, pose.flap * side) * w.offset)
			end
		end
	end
end

Apply.AmbientFish = function(a: Agent, t: number)
	local pose = AmbientMotion.fish(t, a.data.cfg)
	if pose.visible ~= a.data.visible then
		a.data.visible = pose.visible
		setVisible(a.parts, pose.visible)
	end
	if pose.visible then
		local wl = Landscape.River.waterLevel
		local p = a.pivot.Position
		local yaw = a.pivot - p
		local cf = CFrame.new(p.X, wl + pose.y, p.Z)
			* yaw
			* CFrame.new(0, 0, -pose.forward)
			* CFrame.Angles(pose.pitch, 0, 0)
		for _, r in ipairs(a.parts) do
			push(r.part, cf * r.offset)
		end
	end
end

Apply.AmbientButterflies = function(a: Agent, t: number)
	local cfg = a.data.cfg
	for i, b in ipairs(a.data.list) do
		local pose = AmbientMotion.butterfly(t, i, cfg)
		local cf = CFrame.new(a.anchor + Vector3.new(pose.x, pose.y - 1.5, pose.z)) * CFrame.Angles(0, pose.yaw, 0)
		for name, side in pairs({ WingL = -1, WingR = 1 }) do
			local w = b[name]
			if w then
				push(w.part, cf * CFrame.Angles(0, 0, pose.flap * side) * w.offset)
			end
		end
	end
end

-- Un fotograma: recalcula niveles de detalle cada `refresh` s, reparte el presupuesto y
-- mueve todas las piezas de una vez. Devuelve cuántas piezas movió (para pruebas).
function AmbientLifeController.step(now: number, cameraPos: Vector3): number
	frame += 1
	if now - lastRefresh >= Life.budget.refresh or now < lastRefresh then
		lastRefresh = now
		for _, a in ipairs(agents) do
			local tier = AmbientMotion.lodTier((cameraPos - a.anchor).Magnitude, a.lod)
			if tier == "off" and a.kind == "AmbientFish" and a.data.visible then
				a.data.visible = false
				setVisible(a.parts, false)
			end
			a.tier = tier
		end
	end
	table.clear(moveParts)
	table.clear(moveCFrames)
	for _, i in ipairs(AmbientMotion.schedule(agents, frame, Life.budget.partsPerFrame)) do
		local a = agents[i]
		Apply[a.kind](a, now)
	end
	if #moveParts > 0 then
		Workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	return #moveParts
end

function AmbientLifeController.count(): number
	return #agents
end

function AmbientLifeController.start()
	local CollectionService = game:GetService("CollectionService")
	local RunService = game:GetService("RunService")
	for _, tag in ipairs(AmbientLifeController.Tags) do
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			AmbientLifeController.track(inst, tag)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst: Instance)
			AmbientLifeController.track(inst, tag)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(AmbientLifeController.untrack)
	end
	RunService.Heartbeat:Connect(function()
		local camera = Workspace.CurrentCamera
		if camera then
			AmbientLifeController.step(Workspace:GetServerTimeNow(), camera.CFrame.Position)
		end
	end)
end

return AmbientLifeController
