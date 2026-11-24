--!strict
-- Esquema del perfil persistente, migraciones y validación.
-- Regla: cualquier cambio de forma del perfil sube CURRENT_VERSION y añade una
-- migración en Migrations[versiónAnterior]. Las migraciones son puras y se prueban.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Freeze = require(Shared.Util.Freeze)
local Economy = require(Shared.Config.Economy)
local Sanctuary = require(Shared.Config.Sanctuary)
local SpeciesConfig = require(Shared.Config.Species)
local Incubation = require(Shared.Config.Incubation)
local Encounters = require(Shared.Config.Encounters)
local Decor = require(Shared.Config.Decor)
local Types = require(Shared.Types)

type Profile = Types.Profile

local ProfileSchema = {}

-- v1: vertical slice (Fase 1) · v2: colección, huevos, incubadora, cofres, historial,
-- misiones, estrellas del Acto I, Códice, decoración, vitrina, títulos y marcos (Fase 2)
ProfileSchema.CURRENT_VERSION = 3

local function newIncubators(): { Types.IncubatorSlot }
	local slots = {}
	for i = 1, Incubation.MaxSlots do
		slots[i] = { unlocked = i == 1, eggId = nil }
	end
	return slots
end

local function newDecorSlots(): { string | false }
	local slots: { string | false } = {}
	for i = 1, Decor.FreeSlots do
		slots[i] = false
	end
	return slots
end

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
		story = {
			cleared = {},
			repeatDay = 0,
			repeatCount = 0,
			stars = {},
			bestTurns = {},
			regionRewards = {},
			actRewards = {},
			treasureAttempts = {},
		},
		onboarding = { step = "Intro", completed = false, introSkipped = nil, startedAt = now },
		unlocks = {},
		rewards = { pending = {}, ledger = {}, ledgerOrder = {} },
		firsts = {},
		counters = {},
		collection = {},
		eggs = {},
		nextEggSerial = 1,
		incubators = newIncubators(),
		chests = {},
		nextChestSerial = 1,
		history = {},
		quests = { day = -1, daily = {}, dailyBonusClaimed = false, week = -1, weekly = nil },
		codex = {},
		decor = { slots = newDecorSlots(), owned = {} },
		showcase = {},
		titles = { owned = {}, equipped = nil },
		frames = { owned = {}, equipped = nil },
		guardians = {},
		-- v3
		achievements = {},
	}
end

-- Especie del Opaco de un encuentro de la Fase 1 para un perfil dado (la del tutorial
-- depende del elemento del inicial). Se usa en la migración 1→2.
local function phase1Opponent(data: { [string]: any }, encounterId: string): string?
	local enc = Encounters.ById[encounterId]
	if not enc then
		return nil
	end
	local opp = (enc :: any).opponents and (enc :: any).opponents[1] or (enc :: any).opponent
	if not opp then
		return nil
	end
	if opp.speciesId then
		return opp.speciesId
	end
	if opp.byStarterElement then
		for _, pet in pairs(data.pets or {}) do
			if pet.acquired and pet.acquired.kind == "Starter" then
				local sp = SpeciesConfig.ById[pet.speciesId]
				return sp and opp.byStarterElement[sp.elements[1]] or nil
			end
		end
	end
	return nil
end

-- Migraciones: Migrations[v] transforma un perfil de la versión v a la v+1.
-- Puras: no conocen la hora actual salvo por los datos del propio perfil.
ProfileSchema.Migrations = {
	-- 1 → 2: la colección se reconstruye con lo que el jugador ya tiene; las etapas
	-- superadas en la Fase 1 cuentan como ★ (no se sabe si perdió monstruos).
	[1] = function(data: { [string]: any }): { [string]: any }
		local collection: { [string]: any } = {}
		local function entry(speciesId: string): { [string]: any }
			collection[speciesId] = collection[speciesId] or {}
			return collection[speciesId]
		end
		for _, pet in pairs(data.pets or {}) do
			local e = entry(pet.speciesId)
			local at = (pet.acquired and pet.acquired.at) or data.createdAt or 0
			e.broteAt = math.min(e.broteAt or at, at)
			e.count = (e.count or 0) + 1
			if pet.form == "Tallado" then
				e.talladoAt = pet.evolvedAt or at
			end
		end
		local story = data.story or {}
		story.stars = story.stars or {}
		for encounterId, cleared in pairs(story.cleared or {}) do
			story.stars[encounterId] = story.stars[encounterId] or { true, false, false }
			local opp = phase1Opponent(data, encounterId)
			if opp then
				local e = entry(opp)
				e.seenAt = e.seenAt or cleared.firstClearAt
				e.restoredAt = e.restoredAt or cleared.firstClearAt
			end
		end
		data.story = story
		data.collection = collection
		-- El resto de secciones de la v2 se crean vacías en reconcile() con la plantilla.
		return data
	end,
	-- 2 → 3: logros (D-033). Se crea la sección y se reconstruye el contador de huevos
	-- eclosionados con los monstruos nacidos de huevo; los logros ya cumplidos se marcan
	-- (con su premio) la próxima vez que se carga el perfil (AchievementRules.refresh).
	[2] = function(data: { [string]: any }): { [string]: any }
		data.achievements = data.achievements or {}
		local counters = data.counters or {}
		if counters.eggsHatched == nil then
			local hatched = 0
			for _, pet in pairs(data.pets or {}) do
				if pet.acquired and pet.acquired.kind == "Egg" then
					hatched += 1
				end
			end
			counters.eggsHatched = hatched
		end
		data.counters = counters
		return data
	end,
} :: { [number]: (data: { [string]: any }) -> { [string]: any } }

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
	-- Fase 2: huevos ↔ incubadora coherentes (un huevo en una sola ranura y viceversa)
	local incubating: { [string]: number } = {}
	for i, slot in ipairs(p.incubators) do
		if slot.eggId then
			local egg = p.eggs[slot.eggId]
			if not egg then
				return false, "SlotWithUnknownEgg"
			end
			if egg.state ~= "Incubating" or egg.slot ~= i then
				return false, "EggSlotMismatch"
			end
			if incubating[slot.eggId] then
				return false, "EggInTwoSlots"
			end
			incubating[slot.eggId] = i
		end
	end
	for id, egg in pairs(p.eggs) do
		if egg.id ~= id then
			return false, "EggIdMismatch"
		end
		if not SpeciesConfig.ById[egg.speciesId] then
			return false, "UnknownEggSpecies:" .. tostring(egg.speciesId)
		end
		if egg.state == "Incubating" and incubating[id] == nil then
			return false, "IncubatingEggWithoutSlot"
		end
	end
	for _, petId in ipairs(p.showcase) do
		if not p.pets[petId] then
			return false, "ShowcaseNotOwned"
		end
	end
	for _, decorId in ipairs(p.decor.slots) do
		if decorId and (p.decor.owned[decorId :: string] or 0) <= 0 then
			return false, "DecorNotOwned"
		end
	end
	return true, nil
end

return ProfileSchema
