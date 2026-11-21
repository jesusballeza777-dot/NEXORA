--!strict
-- Reglas de PetInstance: creación, acompañante, nombre, alimentación, juego (Vínculo),
-- experiencia y Tallado. Puras: mutan el perfil recibido y devuelven un Result.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SpeciesConfig = require(Shared.Config.Species)
local Economy = require(Shared.Config.Economy)
local Progression = require(Shared.Config.Progression)
local Sanctuary = require(Shared.Config.Sanctuary)
local Onboarding = require(Shared.Config.Onboarding)
local Leveling = require(Shared.Domain.Leveling)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)

type Profile = Types.Profile
type PetInstance = Types.PetInstance

export type Ctx = { now: number, xpMultiplier: number?, skipCooldowns: boolean? }

local PetRules = {}

local function placedCount(p: Profile): number
	local n = 0
	for _, lot in pairs(p.lots) do
		for _, h in pairs(lot.habitats) do
			for _, id in ipairs(h.slots) do
				if id then
					n += 1
				end
			end
		end
	end
	return n
end

function PetRules.petCount(p: Profile): number
	local n = 0
	for _ in pairs(p.pets) do
		n += 1
	end
	return n
end

-- Monstruos en el Vivero (no colocados en un hábitat)
function PetRules.inventoryUsed(p: Profile): number
	return PetRules.petCount(p) - placedCount(p)
end

function PetRules.create(p: Profile, speciesId: string, source: Types.AcquisitionSource): Result.Result
	local species = SpeciesConfig.ById[speciesId]
	if not species then
		return Result.fail("UnknownSpecies")
	end
	if PetRules.inventoryUsed(p) >= p.inventoryCapacity then
		return Result.fail("InventoryFull")
	end
	local id = string.format("U%d-%d", p.userId, p.nextPetSerial)
	if p.pets[id] then
		return Result.fail("PetIdCollision") -- no debería ocurrir nunca: el serial es monótono
	end
	p.nextPetSerial += 1
	local pet: PetInstance = {
		id = id,
		speciesId = speciesId,
		form = "Brote",
		level = 1,
		xp = 0,
		bond = 0,
		nickname = nil,
		acquired = source,
		traits = { veta = "Base", temple = "Neutro", don = nil, goldVein = false },
		lineage = { generation = 0, parents = nil },
		lastPlayedAt = 0,
		evolvedAt = nil,
		loadout = nil,
		stats = { battlesWon = 0, battlesLost = 0, timesFed = 0 },
	}
	p.pets[id] = pet
	return Result.ok({ petId = id })
end

function PetRules.setCompanion(p: Profile, petId: string?): Result.Result
	if petId ~= nil and not p.pets[petId] then
		return Result.fail("PetNotOwned")
	end
	p.companionPetId = petId
	p.team = if petId then { petId } else {}
	return Result.ok({ petId = petId })
end

-- `filtered` ya debe venir filtrado por TextService en el servidor.
function PetRules.setNickname(p: Profile, petId: string, filtered: string?): Result.Result
	local pet = p.pets[petId]
	if not pet then
		return Result.fail("PetNotOwned")
	end
	if filtered == nil or filtered == "" then
		pet.nickname = nil
		return Result.ok({ nickname = nil })
	end
	if utf8.len(filtered) == nil or (utf8.len(filtered) :: number) > Onboarding.MaxNicknameLength then
		return Result.fail("BadNickname")
	end
	pet.nickname = filtered
	return Result.ok({ nickname = filtered })
end

function PetRules.addXp(pet: PetInstance, amount: number, ctx: Ctx): { [string]: any }
	local mult = ctx.xpMultiplier or 1
	local gained = math.floor(amount * mult)
	local r = Leveling.addXp(pet.level, pet.xp, gained)
	pet.level, pet.xp = r.level, r.xp
	return { xpGained = gained, level = r.level, levelsGained = r.levelsGained }
end

function PetRules.addBond(pet: PetInstance, amount: number): number
	local before = pet.bond
	pet.bond = math.min(Progression.Bond.Max, pet.bond + amount)
	return pet.bond - before
end

function PetRules.feed(p: Profile, petId: string, foodId: string, ctx: Ctx): Result.Result
	local pet = p.pets[petId]
	if not pet then
		return Result.fail("PetNotOwned")
	end
	local food = Economy.Foods[foodId]
	if not food then
		return Result.fail("UnknownFood")
	end
	if (p.items[foodId] or 0) < 1 then
		return Result.fail("NoFood")
	end
	if pet.level >= Progression.LevelCap and food.bond == 0 then
		return Result.fail("MaxLevel")
	end
	p.items[foodId] -= 1
	if p.items[foodId] == 0 then
		p.items[foodId] = nil
	end
	local xp = PetRules.addXp(pet, food.xp, ctx)
	local bondGained = PetRules.addBond(pet, food.bond)
	pet.stats.timesFed += 1
	return Result.ok({
		petId = petId,
		foodId = foodId,
		xpGained = xp.xpGained,
		level = xp.level,
		levelsGained = xp.levelsGained,
		bondGained = bondGained,
		bond = pet.bond,
	})
end

function PetRules.play(p: Profile, petId: string, ctx: Ctx): Result.Result
	local pet = p.pets[petId]
	if not pet then
		return Result.fail("PetNotOwned")
	end
	local wait = Progression.Bond.PlayCooldownSeconds - (ctx.now - pet.lastPlayedAt)
	if wait > 0 and not ctx.skipCooldowns then
		return { ok = false, err = "Cooldown", data = { retryIn = math.ceil(wait) } }
	end
	pet.lastPlayedAt = ctx.now
	local gained = PetRules.addBond(pet, Progression.Bond.PlayGain)
	return Result.ok({ petId = petId, bondGained = gained, bond = pet.bond, hearts = Leveling.bondHearts(pet.bond) })
end

function PetRules.evolve(p: Profile, petId: string, ctx: Ctx): Result.Result
	local pet = p.pets[petId]
	if not pet then
		return Result.fail("PetNotOwned")
	end
	local ok, reason = Leveling.canEvolve(pet)
	if not ok then
		return Result.fail(reason :: string)
	end
	pet.form = "Tallado"
	pet.evolvedAt = ctx.now
	pet.loadout = nil -- se recalcula con el repertorio del Tallado
	return Result.ok({ petId = petId, form = "Tallado" })
end

-- Primer monstruo de la cuenta proveniente de un huevo inicial (para el primer Opaco).
function PetRules.starterPet(p: Profile): PetInstance?
	local best: PetInstance? = nil
	for _, pet in pairs(p.pets) do
		if pet.acquired.kind == "Starter" then
			if best == nil or pet.acquired.at < best.acquired.at then
				best = pet
			end
		end
	end
	return best
end

PetRules.MaxCompanions = Sanctuary.MaxCompanions

return PetRules
