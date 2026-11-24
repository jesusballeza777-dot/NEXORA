--!strict
-- Huevos e incubadora (Biblia compacta p. 27; Genesis F2 §8).
-- * La especie y los rasgos se fijan AL OBTENER el huevo; la eclosión nunca vuelve a
--   sortear nada.
-- * Tiempos absolutos del servidor: startedAt/readyAt. El temporizador sigue corriendo
--   con el jugador desconectado; al volver se ve el tiempo real restante.
-- * Ranuras 1–5 configurables (Config/Incubation); sin aceleraciones con Gemas en la beta.
-- * Una eclosión no puede perder el huevo: si el Vivero está lleno, el huevo espera listo.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SpeciesConfig = require(Shared.Config.Species)
local Incubation = require(Shared.Config.Incubation)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)
local CollectionRules = require(script.Parent.CollectionRules)
local HistoryRules = require(script.Parent.HistoryRules)

type Profile = Types.Profile

local EggRules = {}

-- Rasgos estándar (Biblia p. 27: "Veta base, Temple neutro, sin mutación"). Las
-- mutaciones y linajes llegarán con la crianza; el campo ya existe en el huevo.
local function standardTraits(): Types.PetTraits
	return { veta = "Base", temple = "Neutro", don = nil, goldVein = false }
end

function EggRules.storedCount(p: Profile): number
	local n = 0
	for _, egg in pairs(p.eggs) do
		if egg.state == "Stored" then
			n += 1
		end
	end
	return n
end

function EggRules.hasRoom(p: Profile, extra: number?): boolean
	return EggRules.storedCount(p) + (extra or 1) <= Incubation.EggStorageCapacity
end

function EggRules.grant(
	p: Profile,
	speciesId: string,
	source: Types.AcquisitionSource,
	now: number,
	traits: Types.PetTraits?
): Result.Result
	local sp = SpeciesConfig.ById[speciesId]
	if not sp then
		return Result.fail("UnknownSpecies")
	end
	if not EggRules.hasRoom(p) then
		return Result.fail("EggStorageFull")
	end
	local id = string.format("E%d-%d", p.userId, p.nextEggSerial)
	if p.eggs[id] then
		return Result.fail("EggIdCollision")
	end
	p.nextEggSerial += 1
	p.counters.eggsObtained = (p.counters.eggsObtained or 0) + 1
	p.eggs[id] = {
		id = id,
		speciesId = speciesId,
		rarity = sp.rarity,
		traits = traits or standardTraits(),
		source = source,
		obtainedAt = now,
		state = "Stored",
		slot = nil,
		startedAt = nil,
		readyAt = nil,
	}
	HistoryRules.add(
		p,
		{ kind = "Egg", ref = id, rarity = sp.rarity, speciesId = speciesId, at = now, source = source.kind }
	)
	return Result.ok({ eggId = id, speciesId = speciesId, rarity = sp.rarity })
end

function EggRules.seconds(rarity: string): number
	return (Incubation.SecondsByRarity :: any)[rarity] or Incubation.SecondsByRarity.Comun
end

-- Progreso 0..1 con el reloj del servidor
function EggRules.progress(egg: Types.EggInstance, now: number): number
	if egg.state ~= "Incubating" or not egg.startedAt or not egg.readyAt then
		return 0
	end
	local total = math.max(1, egg.readyAt - egg.startedAt)
	return math.clamp((now - egg.startedAt) / total, 0, 1)
end

function EggRules.startIncubation(p: Profile, eggId: string, slotIndex: number, now: number): Result.Result
	local egg = p.eggs[eggId]
	if not egg then
		return Result.fail("EggNotOwned")
	end
	if egg.state ~= "Stored" then
		return Result.fail("EggAlreadyIncubating")
	end
	local slot = p.incubators[slotIndex]
	if not slot then
		return Result.fail("BadSlot")
	end
	if not slot.unlocked then
		return Result.fail("SlotLocked")
	end
	if slot.eggId then
		return Result.fail("SlotBusy")
	end
	slot.eggId = eggId
	egg.state = "Incubating"
	egg.slot = slotIndex
	egg.startedAt = now
	egg.readyAt = now + EggRules.seconds(egg.rarity)
	return Result.ok({ eggId = eggId, slot = slotIndex, readyAt = egg.readyAt })
end

-- Eclosión: solo si el reloj del servidor alcanzó readyAt.
function EggRules.hatch(p: Profile, slotIndex: number, now: number): Result.Result
	local slot = p.incubators[slotIndex]
	if not slot or not slot.eggId then
		return Result.fail("SlotEmpty")
	end
	local egg = p.eggs[slot.eggId :: string]
	if not egg or egg.state ~= "Incubating" then
		return Result.fail("SlotEmpty")
	end
	if now < (egg.readyAt :: number) then
		return Result.fail("NotReady")
	end
	local created = PetRules.create(p, egg.speciesId, { kind = "Egg", ref = egg.id, at = now })
	if not created.ok then
		return created -- p. ej. InventoryFull: el huevo sigue listo, nada se pierde
	end
	local petId = (created.data :: any).petId
	p.pets[petId].traits = table.clone(egg.traits)
	p.counters.eggsHatched = (p.counters.eggsHatched or 0) + 1
	slot.eggId = nil
	p.eggs[egg.id] = nil
	local found = CollectionRules.obtain(p, egg.speciesId, "Brote", now)
	HistoryRules.add(p, {
		kind = "Hatch",
		ref = petId,
		rarity = egg.rarity,
		speciesId = egg.speciesId,
		at = now,
		source = egg.source.kind,
	})
	return Result.ok({
		petId = petId,
		speciesId = egg.speciesId,
		rarity = egg.rarity,
		eggId = egg.id,
		newSpecies = found.newSpecies,
		newCard = found.newCard,
	})
end

-- ¿Se cumple el requisito de una ranura? (Story: ref "region:<acto>:<n>")
function EggRules.slotRequirementMet(p: Profile, rule: Incubation.SlotRule): boolean
	if rule.unlock == "Start" then
		return true
	elseif rule.unlock == "Story" then
		return rule.ref ~= nil and p.story.regionRewards[(rule.ref :: string) .. ":clear"] ~= nil
	end
	return false
end

-- Desbloqueo de ranuras: las de historia se abren solas (refreshSlots); las de Monedas
-- se compran con Monedas ganadas jugando. Gemas y pase no están disponibles en la beta.
function EggRules.refreshSlots(p: Profile): { number }
	local opened = {}
	for _, rule in ipairs(Incubation.Slots) do
		local slot = p.incubators[rule.slot]
		if slot and not slot.unlocked and rule.availableInBeta and EggRules.slotRequirementMet(p, rule) then
			slot.unlocked = true
			table.insert(opened, rule.slot)
		end
	end
	return opened
end

function EggRules.buySlot(p: Profile, slotIndex: number): Result.Result
	local rule = Incubation.Slots[slotIndex]
	local slot = p.incubators[slotIndex]
	if not rule or not slot then
		return Result.fail("BadSlot")
	end
	if slot.unlocked then
		return Result.fail("AlreadyUnlocked")
	end
	if not rule.availableInBeta then
		return Result.fail("NotAvailable")
	end
	if rule.unlock ~= "Monedas" or not rule.price then
		return Result.fail("NotPurchasable")
	end
	-- Las ranuras se abren en orden
	if slotIndex > 1 and not p.incubators[slotIndex - 1].unlocked then
		return Result.fail("PreviousSlotLocked")
	end
	local cost = (rule.price :: any).Monedas
	if (p.currencies.Monedas or 0) < cost then
		return Result.fail("NotEnoughMonedas")
	end
	p.currencies.Monedas -= cost
	slot.unlocked = true
	return Result.ok({ slot = slotIndex, cost = cost })
end

return EggRules
