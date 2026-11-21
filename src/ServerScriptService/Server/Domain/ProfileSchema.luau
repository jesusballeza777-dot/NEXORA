--!strict
-- Esquema del perfil persistente, migraciones y validación.
-- Regla: cualquier cambio de forma del perfil sube CURRENT_VERSION y añade una
-- migración en Migrations[versiónAnterior]. Las migraciones son puras y se prueban.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Freeze = require(Shared.Util.Freeze)
local Economy = require(Shared.Config.Economy)
local Sanctuary = require(Shared.Config.Sanctuary)
local SpeciesConfig = require(Shared.Config.Species)
local Types = require(Shared.Types)

type Profile = Types.Profile

local ProfileSchema = {}

ProfileSchema.CURRENT_VERSION = 1

local function newHabitat(id: string, now: number): Types.HabitatState
	local slots: { string | false } = {}
	for i = 1, Sanctuary.SlotsPerHabitat do
		slots[i] = false
	end
	return { id = id, slots = slots, level = 1, lastCollectAt = now, accrued = 0, bonusCoins = 0 }
end

function ProfileSchema.new(userId: number, now: number): Profile
	local lots = {}
	for lotId, lot in pairs(Sanctuary.Lots) do
		if lot.implemented then
			local habitats = {}
			for _, hid in ipairs(lot.habitats) do
				habitats[hid] = newHabitat(hid, now)
			end
			lots[lotId] = { unlocked = false, habitats = habitats }
		end
	end
	return {
		schemaVersion = ProfileSchema.CURRENT_VERSION,
		userId = userId,
		createdAt = now,
		lastLoginAt = now,
		loginCount = 0,
		playSeconds = 0,
		currencies = { Monedas = Economy.StartingBalance.Monedas, Gemas = Economy.StartingBalance.Gemas },
		items = {},
		pets = {},
		nextPetSerial = 1,
		companionPetId = nil,
		team = {},
		inventoryCapacity = Sanctuary.InventoryCapacity,
		lots = lots,
		story = { cleared = {}, repeatDay = 0, repeatCount = 0 },
		onboarding = { step = "Intro", completed = false, introSkipped = nil, startedAt = now },
		unlocks = {},
		rewards = { pending = {}, ledger = {}, ledgerOrder = {} },
		firsts = {},
		counters = {},
	}
end

-- Migraciones: Migrations[v] transforma un perfil de la versión v a la v+1.
-- (Vacío en la v1: no hay perfiles publicados anteriores.)
ProfileSchema.Migrations = {} :: { [number]: (data: { [string]: any }) -> { [string]: any } }

-- Rellena claves ausentes desde la plantilla sin pisar datos existentes.
local function reconcile(target: { [string]: any }, template: { [string]: any })
	for k, v in pairs(template) do
		if target[k] == nil then
			target[k] = Freeze.copy(v)
		elseif type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil and #v == 0 then
			reconcile(target[k], v)
		end
	end
end

function ProfileSchema.migrate(data: { [string]: any }, now: number, migrations: { [number]: any }?): Profile
	local list = migrations or ProfileSchema.Migrations
	local version = data.schemaVersion or 0
	assert(version <= ProfileSchema.CURRENT_VERSION, "Perfil de una versión futura: " .. tostring(version))
	while version < ProfileSchema.CURRENT_VERSION do
		local step = list[version]
		if step then
			data = step(data)
		end
		version += 1
		data.schemaVersion = version
	end
	reconcile(data, ProfileSchema.new(data.userId or 0, now) :: any)
	return data :: any
end

-- Validación de coherencia: se ejecuta al cargar y antes de guardar.
function ProfileSchema.validate(p: Profile): (boolean, string?)
	for cur, amount in pairs(p.currencies) do
		if type(amount) ~= "number" or amount < 0 or amount ~= amount then
			return false, "BadCurrency:" .. cur
		end
	end
	for item, n in pairs(p.items) do
		if type(n) ~= "number" or n < 0 or math.floor(n) ~= n then
			return false, "BadItem:" .. item
		end
	end
	local placed: { [string]: boolean } = {}
	for _, lot in pairs(p.lots) do
		for _, h in pairs(lot.habitats) do
			for _, petId in ipairs(h.slots) do
				if petId then
					if not p.pets[petId :: string] then
						return false, "SlotWithUnknownPet"
					end
					if placed[petId :: string] then
						return false, "PetInTwoSlots"
					end
					placed[petId :: string] = true
				end
			end
		end
	end
	for id, pet in pairs(p.pets) do
		if pet.id ~= id then
			return false, "PetIdMismatch"
		end
		if not SpeciesConfig.ById[pet.speciesId] then
			return false, "UnknownSpecies:" .. tostring(pet.speciesId)
		end
	end
	if p.companionPetId and not p.pets[p.companionPetId] then
		return false, "CompanionNotOwned"
	end
	return true, nil
end

return ProfileSchema
