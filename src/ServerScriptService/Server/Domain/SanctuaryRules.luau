--!strict
-- Lote Hogar y hábitats: colocar/retirar monstruos y producción de Monedas/XP.
-- La producción se liquida por tiempo del servidor (os.time), nunca por el cliente.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Rarities = require(Shared.Config.Rarities)
local SpeciesConfig = require(Shared.Config.Species)
local Sanctuary = require(Shared.Config.Sanctuary)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)

type Profile = Types.Profile

local SanctuaryRules = {}

local function findHabitat(p: Profile, habitatId: string): (Types.HabitatState?, string?)
	for lotId, lot in pairs(p.lots) do
		local h = lot.habitats[habitatId]
		if h then
			return h, lotId
		end
	end
	return nil, nil
end
SanctuaryRules.findHabitat = findHabitat

function SanctuaryRules.locationOf(p: Profile, petId: string): (string?, number?)
	for _, lot in pairs(p.lots) do
		for hid, h in pairs(lot.habitats) do
			for i, id in ipairs(h.slots) do
				if id == petId then
					return hid, i
				end
			end
		end
	end
	return nil, nil
end

-- Monedas por hora de un monstruo en su hábitat (p. 92): rareza × forma × bono nativo.
function SanctuaryRules.petCoinRate(p: Profile, petId: string, lotBiome: string?): number
	local pet = p.pets[petId]
	if not pet then
		return 0
	end
	local species = SpeciesConfig.ById[pet.speciesId]
	local rate = Rarities.ById[species.rarity].coinsPerHour
	if pet.form == "Brote" then
		rate *= Economy.Habitat.BroteProductionFactor
	end
	if lotBiome and species.biome == lotBiome then
		rate *= 1 + Sanctuary.NativeBonus.coins
	end
	return rate
end

function SanctuaryRules.habitatRate(p: Profile, habitatId: string): number
	local h, lotId = findHabitat(p, habitatId)
	if not h then
		return 0
	end
	local biome = Sanctuary.Lots[lotId :: string].biome
	local total = 0
	for _, id in ipairs(h.slots) do
		if id then
			total += SanctuaryRules.petCoinRate(p, id :: string, biome)
		end
	end
	return total
end

-- Monedas pendientes en el recolector: liquidadas (accrued) + producción desde la última
-- liquidación (tope de 8 h) + reserva del tutorial.
function SanctuaryRules.preview(p: Profile, habitatId: string, now: number): number
	local h = findHabitat(p, habitatId)
	if not h then
		return 0
	end
	local elapsed = math.clamp(now - h.lastCollectAt, 0, Economy.Habitat.OfflineCapSeconds)
	local fresh = math.floor(SanctuaryRules.habitatRate(p, habitatId) * elapsed / 3600)
	return (h.accrued or 0) + fresh + h.bonusCoins
end

-- Liquida la producción en curso al recolector (sin pagarla) y aplica la XP pasiva a los
-- monstruos que estaban en el hábitat. Se llama antes de cambiar la ocupación para que
-- nunca se pierda ni se duplique producción.
local function settle(p: Profile, habitatId: string, h: Types.HabitatState, ctx: PetRules.Ctx): number
	local elapsed = math.clamp(ctx.now - h.lastCollectAt, 0, Economy.Habitat.OfflineCapSeconds)
	local rate = SanctuaryRules.habitatRate(p, habitatId)
	local coins = math.floor(rate * elapsed / 3600)
	local capAmount = rate * Economy.Habitat.OfflineCapSeconds / 3600
	local before = h.accrued or 0
	h.accrued = math.min(before + coins, math.max(capAmount, before))
	local xp = math.floor(Economy.Habitat.PassiveXpPerMinute * elapsed / 60)
	if xp > 0 then
		for _, id in ipairs(h.slots) do
			if id and p.pets[id :: string] then
				PetRules.addXp(p.pets[id :: string], xp, ctx)
			end
		end
	end
	h.lastCollectAt = ctx.now
	return xp
end

-- Recoge las Monedas del recolector (acción explícita del jugador).
function SanctuaryRules.collect(
	p: Profile,
	habitatId: string,
	ctx: PetRules.Ctx & { coinMultiplier: number? }
): Result.Result
	local h, lotId = findHabitat(p, habitatId)
	if not h then
		return Result.fail("UnknownHabitat")
	end
	if not p.lots[lotId :: string].unlocked then
		return Result.fail("LotLocked")
	end
	local xp = settle(p, habitatId, h, ctx)
	local coins = math.floor(((h.accrued or 0) + h.bonusCoins) * (ctx.coinMultiplier or 1))
	h.accrued = 0
	h.bonusCoins = 0
	if coins > 0 then
		p.currencies.Monedas = math.min(Economy.MaxBalance.Monedas, p.currencies.Monedas + coins)
	end
	return Result.ok({ habitatId = habitatId, coins = coins, xpPerPet = xp, balance = p.currencies.Monedas })
end

function SanctuaryRules.place(
	p: Profile,
	petId: string,
	habitatId: string,
	slot: number,
	ctx: PetRules.Ctx
): Result.Result
	if not p.pets[petId] then
		return Result.fail("PetNotOwned")
	end
	local h, lotId = findHabitat(p, habitatId)
	if not h then
		return Result.fail("UnknownHabitat")
	end
	if not p.lots[lotId :: string].unlocked then
		return Result.fail("LotLocked")
	end
	if slot < 1 or slot > #h.slots or math.floor(slot) ~= slot then
		return Result.fail("BadSlot")
	end
	if h.slots[slot] then
		return Result.fail("SlotOccupied")
	end
	if SanctuaryRules.locationOf(p, petId) then
		return Result.fail("AlreadyPlaced")
	end
	-- Liquidar antes de cambiar la tasa de producción
	settle(p, habitatId, h, ctx)
	h.slots[slot] = petId
	return Result.ok({ habitatId = habitatId, slot = slot, petId = petId })
end

function SanctuaryRules.remove(p: Profile, habitatId: string, slot: number, ctx: PetRules.Ctx): Result.Result
	local h = findHabitat(p, habitatId)
	if not h then
		return Result.fail("UnknownHabitat")
	end
	if slot < 1 or slot > #h.slots or math.floor(slot) ~= slot then
		return Result.fail("BadSlot")
	end
	local petId = h.slots[slot]
	if not petId then
		return Result.fail("SlotEmpty")
	end
	if PetRules.inventoryUsed(p) >= p.inventoryCapacity then
		return Result.fail("InventoryFull")
	end
	settle(p, habitatId, h, ctx)
	h.slots[slot] = false
	return Result.ok({ habitatId = habitatId, slot = slot, petId = petId })
end

function SanctuaryRules.unlockLot(
	p: Profile,
	lotId: string,
	ctx: PetRules.Ctx,
	firstCollectBonus: number?
): Result.Result
	local lot = p.lots[lotId]
	if not lot then
		return Result.fail("UnknownLot")
	end
	if lot.unlocked then
		return Result.ok({ lotId = lotId, already = true })
	end
	lot.unlocked = true
	for _, h in pairs(lot.habitats) do
		h.lastCollectAt = ctx.now
		h.bonusCoins = firstCollectBonus or 0
	end
	return Result.ok({ lotId = lotId })
end

return SanctuaryRules
