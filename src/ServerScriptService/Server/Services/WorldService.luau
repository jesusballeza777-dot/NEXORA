--!strict
-- Mundo del servidor: construye Valle Copal, asigna un Lote Hogar a cada jugador,
-- publica estado público (acompañante y hábitat) para que todos los clientes lo vean,
-- valida proximidad física y ejecuta el viaje rápido del menú del árbol.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config.World)
local Encounters = require(Shared.Config.Encounters)

local Server = script.Parent.Parent
local ValleBuilder = require(Server.World.ValleBuilder)
local Log = require(Server.Util.Log).scope("World")

local LATENCY_TOLERANCE = 8 -- studs extra por latencia de red

local WorldService = {}

local lots: { Model } = {}
local owners: { [number]: Player } = {} -- índice de lote → jugador
local lotOf: { [Player]: number } = {}
local publicFolder: Folder

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

function WorldService.init()
	local built = ValleBuilder.build()
	lots = built.lots
	publicFolder = Instance.new("Folder")
	publicFolder.Name = "NexoPublic"
	publicFolder.Parent = ReplicatedStorage
	Log.info("Valle Copal construido: %d lotes", #lots)
end

function WorldService.lotCenter(player: Player): Vector3?
	local index = lotOf[player]
	return if index then v3(World.Lots.positions[index]) else nil
end

function WorldService.lotIndex(player: Player): number?
	return lotOf[player]
end

local function assignLot(player: Player)
	for i = 1, #lots do
		if owners[i] == nil then
			owners[i] = player
			lotOf[player] = i
			player:SetAttribute("LotIndex", i)
			local sign = lots[i]:FindFirstChild("Sign")
			local billboard = sign and sign:FindFirstChild("OwnerLabel")
			local text = billboard and billboard:FindFirstChildOfClass("TextLabel")
			if text then
				text.Text = "Lote Hogar de " .. player.DisplayName
			end
			return
		end
	end
	Log.warn("Sin lotes libres para %d (servidor lleno)", player.UserId)
end

local function releaseLot(player: Player)
	local i = lotOf[player]
	if i then
		owners[i] = nil
		lotOf[player] = nil
		local sign = lots[i]:FindFirstChild("Sign")
		local billboard = sign and sign:FindFirstChild("OwnerLabel")
		local text = billboard and billboard:FindFirstChildOfClass("TextLabel")
		if text then
			text.Text = "Lote libre"
		end
	end
	local entry = publicFolder:FindFirstChild(tostring(player.UserId))
	if entry then
		entry:Destroy()
	end
end

-- Estado público mínimo (para que otros jugadores vean tu acompañante y tu hábitat).
function WorldService.publish(player: Player, view: { [string]: any })
	local entry = publicFolder:FindFirstChild(tostring(player.UserId)) :: Configuration?
	if not entry then
		local cfg = Instance.new("Configuration")
		cfg.Name = tostring(player.UserId)
		cfg.Parent = publicFolder
		entry = cfg
	end
	local companion = nil
	local habitat = {}
	for _, pet in ipairs(view.pets) do
		if pet.id == view.companionPetId then
			companion = { speciesId = pet.speciesId, form = pet.form, name = pet.name }
		end
		if pet.habitat and pet.slot then
			habitat[tostring(pet.slot)] = { speciesId = pet.speciesId, form = pet.form, petId = pet.id }
		end
	end
	local e = entry :: Configuration
	e:SetAttribute("LotIndex", lotOf[player])
	e:SetAttribute("Companion", if companion then HttpService:JSONEncode(companion) else "")
	e:SetAttribute("Habitat", HttpService:JSONEncode(habitat))
end

-- Proximidad física validada en el servidor (Contract.near).
function WorldService.isNear(player: Player, anchor: string, args: { any }): boolean
	local pos = rootPosition(player)
	if not pos then
		return false
	end
	local function within(center: Vector3, radius: number): boolean
		local flat = Vector3.new(pos.X - center.X, 0, pos.Z - center.Z)
		return flat.Magnitude <= radius + LATENCY_TOLERANCE
	end
	if anchor == "PlayerLot" then
		local c = WorldService.lotCenter(player)
		return c ~= nil and within(c, World.Lots.interactRadius)
	elseif anchor == "StarterEggs" then
		for _, p in pairs(World.StarterEggPedestals) do
			if within(v3(p), World.EggInteractRadius) then
				return true
			end
		end
		return false
	elseif anchor == "Encounter" then
		local enc = Encounters.ById[args[1]]
		local marker = enc and World.Encounters[enc.worldMarker]
		return marker ~= nil and within(v3(marker.position), marker.radius)
	else
		local station = World.Stations[anchor]
		return station ~= nil and within(v3(station.position), station.radius)
	end
end

-- Viaje rápido desde el menú del árbol (destinos fijos y validados).
function WorldService.travel(player: Player, destination: string): { ok: boolean, err: string? }
	local target: Vector3? = nil
	local point = World.TravelPoints[destination]
	if point == "PlayerLot" then
		local c = WorldService.lotCenter(player)
		target = if c then c + Vector3.new(0, 4, 20) else nil
	elseif type(point) == "table" then
		target = v3(point)
	end
	if not target then
		return { ok = false, err = "UnknownDestination" }
	end
	local character = player.Character
	if not character or not character.PrimaryPart then
		return { ok = false, err = "NoCharacter" }
	end
	character:PivotTo(CFrame.new(target))
	return { ok = true }
end

function WorldService.start()
	Players.PlayerAdded:Connect(assignLot)
	for _, p in ipairs(Players:GetPlayers()) do
		assignLot(p)
	end
	Players.PlayerRemoving:Connect(releaseLot)
end

return WorldService
