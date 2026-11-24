--!strict
-- Vida del mundo en el cliente:
-- * Acompañantes de TODOS los jugadores (estado público del servidor) que siguen a
--   su dueño con suavidad, guardan distancia, se adaptan al terreno y nunca se
--   pierden (si quedan lejos, reaparecen junto al jugador).
-- * Monstruos del hábitat de cada lote, Opacos en la Linde y huevos que laten.
-- * Activación de ProximityPrompts según el paso del onboarding.
-- * Llegada al Lote Hogar (el servidor valida la proximidad).
-- Rendimiento móvil (Genesis §9): LOD por distancia a la cámara. 0–60 completo; 60–140
-- sin partículas y con animación a la mitad; más de 140 el modelo se oculta y el
-- acompañante solo avanza su seguimiento 4 veces por segundo, sin rayos.
-- Seguimiento: Shared/Domain/FollowSteering (puro). Animación: Client/Animation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config:WaitForChild("World"))
local Onboarding = require(Shared.Config:WaitForChild("Onboarding"))
local Encounters = require(Shared.Config:WaitForChild("Encounters"))
local CreatureMotion = require(Shared.Config:WaitForChild("CreatureMotion"))
local FollowSteering = require(Shared.Domain:WaitForChild("FollowSteering"))

local Client = script.Parent.Parent
local CreatureBuilder = require(Client.Creatures.CreatureBuilder)
local Net = require(Client.Net)
local State = require(Client.State)
local CreatureAnimator = require(Client.Animation.CreatureAnimator)
local MotionStateMachine = require(Client.Animation.MotionStateMachine)
local AuraController = require(Client.VFX.AuraController)
local VFXPlan = require(Client.VFX.VFXPlan)

type Creature = CreatureBuilder.Creature

local WorldController = {}

local player = Players.LocalPlayer
local valle: Folder
local publicFolder: Folder
-- Cada criatura del mundo lleva su animador, su aura y su nivel de detalle
type Live = { creature: Creature, anim: any, lod: string, shown: boolean }
local companions: { [number]: any } = {}
local habitatPets: { [string]: Live } = {}
local opacos: { [string]: any } = {}
local Follow = CreatureMotion.Follow
local suspended = false -- durante el combate el controlador de batalla toma el escenario
local handlers: { [string]: (any) -> () } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
-- Solo superficies sólidas: el papel picado, los halos y los letreros no son suelo
rayParams.RespectCanCollide = true

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function groundY(pos: Vector3): number
	local hit = Workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rayParams)
	return if hit then hit.Position.Y else 0
end

local function decode(value: any): any
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, value)
	return if ok then data else nil
end

local function startEncounterAt(zone: Instance)
	local marker = zone:GetAttribute("Marker")
	for _, id in ipairs(Encounters.Order) do
		if Encounters.ById[id].worldMarker == marker then
			local r = Net.request("Battle.Start", id)
			if not r.ok then
				handlers.toast(Net.message(r.err))
			end
			return
		end
	end
end

local function onPrompt(prompt: ProximityPrompt)
	local parent = prompt.Parent
	if not parent then
		return
	end
	local name = prompt.Name
	if name == "ChooseEgg" then
		handlers.confirmEgg(parent:GetAttribute("EggId"))
	elseif name == "NexoMenu" then
		handlers.openNexo(nil)
	elseif name == "EncounterPrompt" then
		startEncounterAt(parent)
	elseif name == "Station" then
		-- Cada estación de la Torre abre su pantalla (mismas que el acceso rápido)
		handlers.openStation(parent:GetAttribute("StationId"))
	elseif name == "CollectPrompt" then
		local r = Net.request("Sanctuary.Collect")
		handlers.toast(if r.ok then string.format("+%d Monedas", r.data.coins) else Net.message(r.err))
	elseif name == "SlotPrompt" then
		handlers.openSanctuary(nil)
	end
end

function WorldController.init(h: { [string]: (any) -> () })
	handlers = h
	valle = Workspace:WaitForChild("ValleCopal") :: Folder
	publicFolder = ReplicatedStorage:WaitForChild("NexoPublic") :: Folder
	rayParams.FilterDescendantsInstances = { Workspace.Terrain, valle }

	-- Prompts físicos → acciones (el servidor vuelve a validar proximidad y estado).
	-- Un único despachador en ProximityPromptService: funciona aunque las piezas lleguen
	-- tarde (streaming, recreación del mundo) y no deja prompts sin conectar.
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
		if who == player and prompt:IsDescendantOf(valle) then
			onPrompt(prompt)
		end
	end)
	-- El latido del corazón del Nexo lo anima AmbientLifeController (etiqueta AmbientHeart)
end

local function myLot(): Model?
	local index = player:GetAttribute("LotIndex")
	return if index then (valle.Lots :: any):FindFirstChild("Lot" .. tostring(index)) else nil
end

-- Activa/desactiva prompts según el estado del perfil (un aviso de tutorial a la vez).
function WorldController.applyState(view: any)
	local step = view.onboarding.step
	local hasStarter = #view.pets > 0
	for _, egg in ipairs(valle.StarterEggs:GetChildren()) do
		local prompt = egg:FindFirstChild("ChooseEgg") :: ProximityPrompt?
		if prompt then
			prompt.Enabled = step == "ChooseEgg"
		end
		if egg:GetAttribute("EggId") and egg:IsA("BasePart") then
			(egg :: BasePart).Transparency = if hasStarter then 1 else 0
		end
	end
	local lot = myLot()
	local habitat = view.habitats.Hogar_H1
	if lot then
		for _, d in ipairs(lot:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				d.Enabled = habitat ~= nil and habitat.unlocked
			end
		end
	end
	for _, zone in ipairs(valle.Encounters:GetChildren()) do
		local prompt = zone:FindFirstChild("EncounterPrompt") :: ProximityPrompt?
		local marker = zone:GetAttribute("Marker")
		for _, id in ipairs(Encounters.Order) do
			if Encounters.ById[id].worldMarker == marker and prompt then
				local e = view.encounters[id]
				prompt.Enabled = e.unlocked
					and (step == "FirstBattle" or view.onboarding.completed or step == "ClaimReward")
				prompt.ObjectText = Encounters.ById[id].name
			end
		end
	end
	WorldController.syncOpacos(view)
end

function WorldController.syncOpacos(view: any)
	for id, enc in pairs(Encounters.ById) do
		local e = view.encounters[id]
		-- Solo las etapas con marcador físico en la Linde tienen un Opaco en el mundo
		local want = if enc.worldMarker
				and e
				and e.unlocked
				and e.opponent
			then e.opponent .. (if e.cleared then "R" else "O")
			else ""
		local cur = opacos[id]
		if (cur and cur.key or "") ~= want then
			if cur then
				cur.creature:destroy()
			end
			opacos[id] = nil
			if want ~= "" then
				local c = CreatureBuilder.build(e.opponent, enc.opponent.form, { opaco = not e.cleared })
				if suspended then
					c.model.Parent = nil
				end
				AuraController.attach(c)
				opacos[id] = { creature = c, key = want, anim = CreatureAnimator.new(c), lod = "Full", shown = true }
			end
		end
	end
end

-- Muestra u oculta el modelo según el combate (suspended) y el nivel de detalle
local function show(live: any, visible: boolean)
	local want = visible and not suspended
	if live.shown ~= want then
		live.shown = want
		live.creature.model.Parent = if want then Workspace else nil
	end
end

function WorldController.suspend(on: boolean)
	suspended = on
	for _, entry in pairs(companions) do
		show(entry, entry.lod ~= "None")
	end
	for _, o in pairs(opacos) do
		show(o, o.lod ~= "None")
	end
end

function WorldController.react(userId: number?)
	local entry = companions[userId or player.UserId]
	if entry then
		entry.anim:trigger("Happy") -- Kuachi a veces se hace el muerto al jugar
	end
end

local lastVisit = 0
local function checkHomeArrival(now: number)
	local view = State.view
	if not view or view.onboarding.step ~= "MeetHome" or now - lastVisit < 2 then
		return
	end
	local index = player:GetAttribute("LotIndex")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if index and root then
		local center = v3(World.Lots.positions[index])
		if (Vector3.new(root.Position.X, 0, root.Position.Z) - center).Magnitude < World.Lots.interactRadius - 4 then
			lastVisit = now
			local r = Net.request("Sanctuary.Visit")
			if r.ok and r.data and r.data.gifted then
				handlers.toast("El Gabinete te regala el Lote Hogar: 3 Raciones y 100 Monedas")
				handlers.openSanctuary(nil)
			end
		end
	end
end

-- Rayo horizontal contra paredes (las rampas y el suelo no cuentan como obstáculo)
local function wallRay(y: number): FollowSteering.Raycast
	return function(x: number, z: number, dx: number, dz: number, length: number): number?
		local hit = Workspace:Raycast(Vector3.new(x, y + 1.2, z), Vector3.new(dx * length, 0, dz * length), rayParams)
		if hit and math.abs(hit.Normal.Y) < 0.6 then
			return hit.Distance
		end
		return nil
	end
end

local function cameraPos(): Vector3?
	local camera = Workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function lodFor(live: any, pos: Vector3, cam: Vector3?): string
	live.lod = if cam then VFXPlan.lod((pos - cam).Magnitude, live.lod) else "Full"
	return live.lod
end

local function newCompanion(speciesId: string, form: string, root: BasePart): any
	local c = CreatureBuilder.build(speciesId, form)
	if suspended then
		c.model.Parent = nil
	end
	AuraController.attach(c)
	local look = root.CFrame.LookVector
	local profile = MotionStateMachine.profile(speciesId)
	local start = root.Position - look * Follow.back
	return {
		creature = c,
		key = speciesId .. form,
		anim = CreatureAnimator.new(c),
		steer = FollowSteering.new(start.X, start.Z, math.atan2(look.X, look.Z), profile.inertia),
		y = root.Position.Y,
		fx = look.X,
		fz = look.Z,
		lod = "Full",
		shown = not suspended,
		farAcc = 0,
		ownerAir = false,
		pause = profile.pause,
		pauseIn = if profile.pause then profile.pause.every[2] else 0,
		pauseLeft = 0,
		rng = Random.new(),
	}
end

-- Pausas de paseo (Xolumi): se para un momento si no se ha quedado atrás
local function pausing(r: any, dt: number, ownerDistance: number): boolean
	local pz = r.pause
	if not pz then
		return false
	end
	if r.pauseLeft > 0 then
		r.pauseLeft -= dt
		if ownerDistance > Follow.maxDistance + 3 then
			r.pauseLeft = 0
		end
		return r.pauseLeft > 0
	end
	if r.steer.moving then
		r.pauseIn -= dt
		if r.pauseIn <= 0 then
			r.pauseIn = r.rng:NextNumber(pz.every[1], pz.every[2])
			r.pauseLeft = r.rng:NextNumber(pz.duration[1], pz.duration[2])
		end
	end
	return false
end

local function updateCompanions(dt: number)
	local cam = cameraPos()
	local seen: { [number]: boolean } = {}
	for _, entry in ipairs(publicFolder:GetChildren()) do
		local userId = tonumber(entry.Name)
		local owner = if userId then Players:GetPlayerByUserId(userId) else nil
		local data = decode(entry:GetAttribute("Companion"))
		local character = owner and owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if userId and data and root and data.speciesId then
			seen[userId] = true
			local key = data.speciesId .. data.form
			local rec = companions[userId]
			if not rec or rec.key ~= key then
				if rec then
					rec.creature:destroy()
				end
				rec = newCompanion(data.speciesId, data.form, root)
				companions[userId] = rec
			end
			local r = rec :: any
			local look = root.CFrame.LookVector
			local flat = math.sqrt(look.X * look.X + look.Z * look.Z)
			if flat > 0.1 then
				r.fx, r.fz = look.X / flat, look.Z / flat
			end
			local rp = root.Position
			local ownerState = { x = rp.X, z = rp.Z, fx = r.fx, fz = r.fz }
			local s = r.steer
			local pos = Vector3.new(s.x, r.y, s.z)
			if lodFor(r, pos, cam) == "None" then
				-- Lejos de la cámara: oculto y con pasos baratos (sin rayos ni animación)
				show(r, false)
				r.farAcc += dt
				if r.farAcc >= Follow.farInterval then
					FollowSteering.step(s, ownerState, r.farAcc, Follow, nil)
					r.farAcc = 0
					r.y = rp.Y - 2.5
				end
			else
				show(r, true)
				local ownerDistance = math.sqrt((s.x - rp.X) ^ 2 + (s.z - rp.Z) ^ 2)
				if not pausing(r, dt, ownerDistance) then
					FollowSteering.step(s, ownerState, dt, Follow, if r.lod == "Full" then wallRay(r.y) else nil)
				else
					s.speed, s.moving, s.yawRate = 0, false, 0
				end
				local gy = groundY(Vector3.new(s.x, rp.Y, s.z))
				r.y = gy
				-- Si el dueño salta, el acompañante da su saltito
				local air = root.AssemblyLinearVelocity.Y > 8
				if air and not r.ownerAir then
					r.anim:jump()
				end
				r.ownerAir = air
				-- En reposo mira a su dueño
				r.anim:setLookTarget(if s.moving then nil else rp + Vector3.new(0, 1, 0))
				if not suspended then
					r.anim:update(
						dt,
						CFrame.new(s.x, gy, s.z) * CFrame.Angles(0, s.yaw, 0),
						{ speed = s.speed, yawRate = s.yawRate, groundY = gy },
						r.lod
					)
				end
			end
		end
	end
	for userId, rec in pairs(companions) do
		if not seen[userId] then
			rec.creature:destroy()
			companions[userId] = nil
		end
	end
end

local function updateHabitats(dt: number)
	local cam = cameraPos()
	local wanted: { [string]: boolean } = {}
	for _, entry in ipairs(publicFolder:GetChildren()) do
		local lotIndex = entry:GetAttribute("LotIndex")
		local habitat = decode(entry:GetAttribute("Habitat"))
		local companion = decode(entry:GetAttribute("Companion"))
		if lotIndex and habitat then
			local center = v3(World.Lots.positions[lotIndex])
			for slotKey, pet in pairs(habitat) do
				local key = string.format("%s:%s:%s%s", entry.Name, slotKey, pet.speciesId, pet.form)
				-- El acompañante que pasea con su dueño deja su lugar con la marca de "paseando"
				local walking = companion and companion.speciesId == pet.speciesId and companion.form == pet.form
				if not walking then
					wanted[key] = true
					local live = habitatPets[key]
					if not live then
						local c = CreatureBuilder.build(pet.speciesId, pet.form)
						AuraController.attach(c)
						live = { creature = c, anim = CreatureAnimator.new(c), lod = "Full", shown = true }
						habitatPets[key] = live
					end
					local l = live :: Live
					local off = World.Lots.slotOffsets[tonumber(slotKey) or 1]
					local pos = center + v3(off) + Vector3.new(0, 1.9, 0)
					local lod = lodFor(l, pos, cam)
					show(l, lod ~= "None")
					l.anim:update(dt, CFrame.new(pos) * CFrame.Angles(0, math.pi, 0), { speed = 0 }, lod)
				end
			end
		end
	end
	for key, live in pairs(habitatPets) do
		if not wanted[key] then
			live.creature:destroy()
			habitatPets[key] = nil
		end
	end
end

local function updateOpacos(dt: number)
	if suspended then
		return
	end
	local cam = cameraPos()
	local character = player.Character
	local me = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id, o in pairs(opacos) do
		local marker = World.Encounters[Encounters.ById[id].worldMarker]
		local pos = v3(marker.position)
		pos = Vector3.new(pos.X, groundY(pos), pos.Z)
		local lod = lodFor(o, pos, cam)
		show(o, lod ~= "None")
		-- El Opaco se pone en guardia si te acercas (Teselo se resguarda)
		local near = me ~= nil and (me.Position - pos).Magnitude < 16
		o.anim:hold(if near and o.creature.opaco > 0.5 then "Warn" else nil, o.anim.profile.defend)
		o.anim:setLookTarget(if near and me then me.Position else nil)
		o.anim:update(dt, CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), { speed = 0 }, lod)
	end
end

local function updateEggs(t: number)
	if State.step() ~= "ChooseEgg" then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, eggDef in ipairs(Onboarding.StarterEggs) do
		local egg = valle.StarterEggs:FindFirstChild(eggDef.eggId) :: BasePart?
		if egg and root then
			local light = egg:FindFirstChildOfClass("PointLight") or Instance.new("PointLight")
			light.Color = Color3.fromRGB(eggDef.pulseColor[1], eggDef.pulseColor[2], eggDef.pulseColor[3])
			light.Range = 12
			local near = (egg.Position - root.Position).Magnitude < World.EggInteractRadius + 4
			light.Brightness = if near then 2 + math.sin(t * 5) * 1.5 else 0
			light.Parent = egg
		end
	end
end

function WorldController.start()
	local t = 0
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		updateCompanions(dt)
		updateHabitats(dt)
		updateOpacos(dt)
		updateEggs(t)
		acc += dt
		if acc > 0.4 then
			acc = 0
			checkHomeArrival(os.clock())
		end
	end)
end

return WorldController
