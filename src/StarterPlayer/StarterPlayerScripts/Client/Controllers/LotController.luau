--!strict
-- Presencia de la Fase 2 en los lotes (para todos los jugadores, desde el estado público
-- que publica WorldService): decoración en los 6 espacios, vitrina de exhibición y la
-- incubadora con huevo flotante, dos anillos giratorios, haz de luz y grietas de luz al
-- 25/50/75 % (Biblia p. 102). Todo es decorado del cliente: sin colisión ni consultas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config:WaitForChild("World"))
local Decor = require(Shared.Config:WaitForChild("Decor"))
local Rarities = require(Shared.Config:WaitForChild("Rarities"))

local Client = script.Parent.Parent
local CreatureBuilder = require(Client.Creatures.CreatureBuilder)
local State = require(Client.State)

type Creature = CreatureBuilder.Creature

local LotController = {}

type LotRec = {
	key: string,
	folder: Folder,
	showcase: { Creature },
	egg: BasePart?,
	rings: { BasePart },
	cracks: { BasePart },
	incubator: any,
}

local publicFolder: Folder
local lots: { [string]: LotRec } = {}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function decode(value: any): any
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, value)
	return if ok then data else nil
end

local function piece(
	parent: Instance,
	shape: "Block" | "Ball" | "Cylinder",
	size: Vector3,
	cf: CFrame,
	color: Color3,
	neon: boolean?
): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = not neon
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- cilindro vertical

-- Blockouts de los objetos de decoración (Config/Decor.shape)
local function buildProp(parent: Instance, def: Decor.DecorDef, base: Vector3)
	local c, a = rgb(def.color), rgb(def.accent)
	if def.shape == "Lantern" then
		piece(parent, "Cylinder", Vector3.new(4, 0.4, 0.4), CFrame.new(base + Vector3.new(0, 2, 0)) * UP, c)
		piece(parent, "Ball", Vector3.new(1.4, 1.4, 1.4), CFrame.new(base + Vector3.new(0, 4.4, 0)), a, true)
	elseif def.shape == "Planter" then
		piece(parent, "Cylinder", Vector3.new(1.4, 2, 2), CFrame.new(base + Vector3.new(0, 0.7, 0)) * UP, c)
		for k = 0, 4 do
			local ang = k / 5 * math.pi * 2
			piece(
				parent,
				"Ball",
				Vector3.new(0.7, 0.7, 0.7),
				CFrame.new(base + Vector3.new(math.cos(ang) * 0.5, 1.7, math.sin(ang) * 0.5)),
				a
			)
		end
	elseif def.shape == "Banner" then
		for _, x in ipairs({ -2.5, 2.5 }) do
			piece(parent, "Cylinder", Vector3.new(5, 0.3, 0.3), CFrame.new(base + Vector3.new(x, 2.5, 0)) * UP, c)
		end
		local colors = { a, Color3.fromRGB(250, 186, 50), Color3.fromRGB(64, 170, 214), Color3.fromRGB(150, 96, 222) }
		for k = 1, 4 do
			piece(
				parent,
				"Block",
				Vector3.new(0.9, 1.1, 0.08),
				CFrame.new(base + Vector3.new(-2.5 + k, 4.2 - math.sin(k / 5 * math.pi) * 0.5, 0)),
				colors[k]
			)
		end
	elseif def.shape == "Stone" then
		piece(parent, "Block", Vector3.new(1.6, 3.6, 1.2), CFrame.new(base + Vector3.new(0, 1.8, 0)), c)
		piece(parent, "Block", Vector3.new(1.2, 0.3, 1.25), CFrame.new(base + Vector3.new(0, 2.6, 0)), a)
		piece(parent, "Block", Vector3.new(1.2, 0.3, 1.25), CFrame.new(base + Vector3.new(0, 1.4, 0)), a)
	elseif def.shape == "Bench" then
		piece(parent, "Block", Vector3.new(4, 0.3, 1.2), CFrame.new(base + Vector3.new(0, 1.1, 0)), c)
		for _, x in ipairs({ -1.6, 1.6 }) do
			piece(parent, "Block", Vector3.new(0.3, 1, 1), CFrame.new(base + Vector3.new(x, 0.5, 0)), a)
		end
	elseif def.shape == "Arch" then
		for _, x in ipairs({ -2, 2 }) do
			piece(parent, "Cylinder", Vector3.new(4.5, 0.7, 0.7), CFrame.new(base + Vector3.new(x, 2.25, 0)) * UP, c)
		end
		piece(parent, "Block", Vector3.new(4.8, 0.6, 0.7), CFrame.new(base + Vector3.new(0, 4.6, 0)), c)
		for k = -2, 2 do
			piece(parent, "Ball", Vector3.new(0.8, 0.8, 0.8), CFrame.new(base + Vector3.new(k, 5.1, 0)), a)
		end
	end
end

local function clear(rec: LotRec)
	for _, c in ipairs(rec.showcase) do
		c:destroy()
	end
	rec.folder:Destroy()
end

local function rebuild(userId: string, lotIndex: number, decorSlots: any, showcase: any, incubator: any, key: string)
	local old = lots[userId]
	if old then
		clear(old)
	end
	local center = v3(World.Lots.positions[lotIndex])
	local folder = Instance.new("Folder")
	folder.Name = "LotFx_" .. userId
	folder.Parent = Workspace
	local rec: LotRec =
		{ key = key, folder = folder, showcase = {}, egg = nil, rings = {}, cracks = {}, incubator = incubator }
	for slot, decorId in ipairs(decorSlots or {}) do
		local def = if type(decorId) == "string" then Decor.ById[decorId] else nil
		local off = Decor.SlotOffsets[slot]
		if def and off then
			buildProp(folder, def, center + v3(off))
		end
	end
	local vit = center + v3(World.Lots.vitrinaOffset)
	for i, s in ipairs(showcase or {}) do
		local c = CreatureBuilder.build(s.speciesId, s.form)
		CreatureBuilder.pose(c, CFrame.new(vit + Vector3.new((i - 2) * 4, 2.2, 0)) * CFrame.Angles(0, math.pi, 0))
		table.insert(rec.showcase, c)
	end
	if incubator then
		local inc = center + v3(World.Lots.incubatorOffset)
		local rar = Rarities.ById[incubator.rarity]
		local color = if rar then rgb(rar.frameColor) else Color3.fromRGB(255, 214, 140)
		-- Haz de luz y pedestal de copal
		piece(folder, "Cylinder", Vector3.new(14, 2.2, 2.2), CFrame.new(inc + Vector3.new(0, 7, 0)) * UP, color, true).Transparency =
			0.82
		rec.egg = piece(
			folder,
			"Ball",
			Vector3.new(1.6, 2.1, 1.6),
			CFrame.new(inc + Vector3.new(0, 3.5, 0)),
			Color3.fromRGB(246, 217, 166)
		)
		for k = 1, 2 do
			local ring =
				piece(folder, "Cylinder", Vector3.new(0.12, 3.4 + k * 0.6, 3.4 + k * 0.6), CFrame.new(inc), color, true)
			ring.Transparency = 0.35
			table.insert(rec.rings, ring)
		end
		for _ = 1, 3 do
			local crack = piece(
				folder,
				"Block",
				Vector3.new(0.12, 0.6, 0.12),
				CFrame.new(inc),
				Color3.fromRGB(255, 236, 180),
				true
			)
			crack.Transparency = 1
			table.insert(rec.cracks, crack)
		end
	end
	lots[userId] = rec
end

local function sync()
	local seen: { [string]: boolean } = {}
	for _, entry in ipairs(publicFolder:GetChildren()) do
		local lotIndex = entry:GetAttribute("LotIndex")
		if lotIndex then
			local d, s, i = entry:GetAttribute("Decor"), entry:GetAttribute("Showcase"), entry:GetAttribute("Incubator")
			local key = tostring(lotIndex) .. "|" .. tostring(d) .. "|" .. tostring(s) .. "|" .. tostring(i)
			seen[entry.Name] = true
			local rec = lots[entry.Name]
			if not rec or rec.key ~= key then
				rebuild(entry.Name, lotIndex, decode(d), decode(s), decode(i), key)
			end
		end
	end
	for userId, rec in pairs(lots) do
		if not seen[userId] then
			clear(rec)
			lots[userId] = nil
		end
	end
end

local function animate(t: number)
	local view = State.view
	local now = os.time() + (if view then view.serverTime - os.time() else 0)
	for _, rec in pairs(lots) do
		local inc = rec.incubator
		if rec.egg and inc then
			local base = rec.egg.Position
			local center = Vector3.new(base.X, 3.5, base.Z)
			local bob = math.sin(t * 1.6) * 0.25
			local total = math.max(1, inc.readyAt - inc.startedAt)
			local p = math.clamp((now - inc.startedAt) / total, 0, 1)
			local ready = p >= 1
			local shake = if ready then math.sin(t * 18) * 0.08 else 0
			rec.egg.CFrame = CFrame.new(center + Vector3.new(0, bob, 0)) * CFrame.Angles(0, t * 0.6, shake)
			for k, ring in ipairs(rec.rings) do
				local dir = if k == 1 then 1 else -1
				ring.CFrame = CFrame.new(center + Vector3.new(0, bob, 0))
					* CFrame.Angles(t * 0.9 * dir, 0.4 * k, t * 0.5 * dir)
			end
			for k, crack in ipairs(rec.cracks) do
				local open = p >= (k * 0.25)
				crack.Transparency = if open then 0 else 1
				crack.CFrame = rec.egg.CFrame
					* CFrame.new(math.cos(k * 2.1) * 0.75, (k - 2) * 0.45, math.sin(k * 2.1) * 0.75)
			end
		end
	end
end

function LotController.start()
	publicFolder = ReplicatedStorage:WaitForChild("NexoPublic") :: Folder
	local t, acc = 0, 1
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		acc += dt
		if acc >= 0.5 then
			acc = 0
			sync()
		end
		animate(t)
	end)
end

return LotController
