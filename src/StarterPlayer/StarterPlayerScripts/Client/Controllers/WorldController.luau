--!strict
-- Vida del mundo en el cliente:
-- * Acompañantes de TODOS los jugadores (estado público del servidor) que siguen a
--   su dueño con suavidad, guardan distancia, se adaptan al terreno y nunca se
--   pierden (si quedan lejos, reaparecen junto al jugador).
-- * Monstruos del hábitat de cada lote, Opacos en la Linde y huevos que laten.
-- * Activación de ProximityPrompts según el paso del onboarding.
-- * Llegada al Lote Hogar (el servidor valida la proximidad).
-- Rendimiento móvil: solo se animan criaturas a menos de 140 studs de la cámara.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config:WaitForChild("World"))
local Onboarding = require(Shared.Config:WaitForChild("Onboarding"))
local Encounters = require(Shared.Config:WaitForChild("Encounters"))

local Client = script.Parent.Parent
local CreatureBuilder = require(Client.Creatures.CreatureBuilder)
local Net = require(Client.Net)
local State = require(Client.State)

type Creature = CreatureBuilder.Creature

local WorldController = {}

local player = Players.LocalPlayer
local valle: Folder
local publicFolder: Folder
local companions: { [number]: { creature: Creature, key: string, pos: Vector3, yaw: number } } = {}
local habitatPets: { [string]: Creature } = {}
local opacos: { [string]: { creature: Creature, key: string } } = {}
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
	local heart = valle:WaitForChild("GranNexo"):WaitForChild("NexoHeart") :: BasePart
	TweenService:Create(
		heart,
		TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = heart.Size * 1.08 }
	):Play()
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
				opacos[id] = { creature = c, key = want }
			end
		end
	end
end

function WorldController.suspend(on: boolean)
	suspended = on
	for _, entry in pairs(companions) do
		entry.creature.model.Parent = if on then nil else Workspace
	end
	for _, o in pairs(opacos) do
		o.creature.model.Parent = if on then nil else Workspace
	end
end

function WorldController.react(userId: number?)
	local entry = companions[userId or player.UserId]
	if entry then
		entry.creature.react = 0.9
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

local function updateCompanions(t: number, dt: number)
	local camera = Workspace.CurrentCamera
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
				local c = CreatureBuilder.build(data.speciesId, data.form)
				if suspended then
					c.model.Parent = nil
				end
				rec = { creature = c, key = key, pos = root.Position, yaw = 0 }
				companions[userId] = rec
			end
			local r = rec :: any
			-- Seguimiento: a un lado y detrás del dueño, con suavizado y sin tirones
			local look = root.CFrame.LookVector
			local right = root.CFrame.RightVector
			local target = root.Position - look * 4 + right * 3.2
			local flat = Vector3.new(target.X - r.pos.X, 0, target.Z - r.pos.Z)
			local dist = flat.Magnitude
			if dist > 60 then
				r.pos = target -- se perdió la referencia: reaparece junto al jugador
			elseif dist > 1.2 then
				local step = math.min(dist, (6 + dist * 1.6) * dt)
				r.pos += flat.Unit * step
				-- La criatura mira a su +Z local: yaw = atan2(x, z) apunta hacia donde camina
				r.yaw = math.atan2(flat.X, flat.Z)
			end
			local y = groundY(r.pos)
			r.pos = Vector3.new(r.pos.X, y, r.pos.Z)
			if not suspended and camera and (camera.CFrame.Position - r.pos).Magnitude < 140 then
				CreatureBuilder.update(r.creature, CFrame.new(r.pos) * CFrame.Angles(0, r.yaw, 0), t, dt, dist > 1.2)
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

local function updateHabitats(t: number, dt: number)
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
					local c = habitatPets[key]
					if not c then
						c = CreatureBuilder.build(pet.speciesId, pet.form)
						habitatPets[key] = c
					end
					local off = World.Lots.slotOffsets[tonumber(slotKey) or 1]
					CreatureBuilder.update(
						c :: Creature,
						CFrame.new(center + v3(off) + Vector3.new(0, 1.9, 0)) * CFrame.Angles(0, math.pi, 0),
						t,
						dt,
						false
					)
				end
			end
		end
	end
	for key, c in pairs(habitatPets) do
		if not wanted[key] then
			c:destroy()
			habitatPets[key] = nil
		end
	end
end

local function updateOpacos(t: number, dt: number)
	for id, o in pairs(opacos) do
		local marker = World.Encounters[Encounters.ById[id].worldMarker]
		local pos = v3(marker.position)
		if not suspended then
			CreatureBuilder.update(
				o.creature,
				CFrame.new(pos + Vector3.new(0, groundY(pos) - pos.Y, 0)) * CFrame.Angles(0, math.pi / 2, 0),
				t,
				dt,
				false
			)
		end
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
		updateCompanions(t, dt)
		updateHabitats(t, dt)
		updateOpacos(t, dt)
		updateEggs(t)
		acc += dt
		if acc > 0.4 then
			acc = 0
			checkHomeArrival(os.clock())
		end
	end)
end

return WorldController
