--!strict
-- Encuentros PvE: requisitos, construcción del combate desde el perfil y aplicación
-- del resultado (recompensa pendiente con procedencia; repetición al 25 %, tope diario).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Encounters = require(Shared.Config.Encounters)
local SpeciesConfig = require(Shared.Config.Species)
local BattleEngine = require(Shared.Domain.Battle.BattleEngine)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)
local RewardRules = require(script.Parent.RewardRules)

type Profile = Types.Profile

local EncounterRules = {}

function EncounterRules.isUnlocked(p: Profile, encounterId: string): boolean
	local enc = Encounters.ById[encounterId]
	if not enc then
		return false
	end
	if enc.requires == nil then
		return true
	end
	return p.story.cleared[enc.requires] ~= nil
end

function EncounterRules.opponentSpecies(p: Profile, encounterId: string): string?
	local enc = Encounters.ById[encounterId]
	if enc.opponent.speciesId then
		return enc.opponent.speciesId
	end
	local starter = PetRules.starterPet(p)
	if not starter then
		return nil
	end
	local element = SpeciesConfig.ById[starter.speciesId].elements[1]
	return (enc.opponent.byStarterElement :: any)[element]
end

function EncounterRules.canStart(p: Profile, encounterId: string): Result.Result
	local enc = Encounters.ById[encounterId]
	if not enc then
		return Result.fail("UnknownEncounter")
	end
	if not EncounterRules.isUnlocked(p, encounterId) then
		return Result.fail("EncounterLocked")
	end
	if not p.companionPetId or not p.pets[p.companionPetId] then
		return Result.fail("NoCompanion")
	end
	if not EncounterRules.opponentSpecies(p, encounterId) then
		return Result.fail("NoOpponent")
	end
	return Result.ok()
end

function EncounterRules.buildSetup(
	p: Profile,
	encounterId: string,
	battleId: string,
	seed: number
): BattleEngine.BattleSetup
	local enc = Encounters.ById[encounterId]
	local team = {}
	for _, petId in ipairs(p.team) do
		local pet = p.pets[petId]
		if pet then
			table.insert(team, {
				speciesId = pet.speciesId,
				form = pet.form,
				level = pet.level,
				petId = pet.id,
				nickname = pet.nickname,
				loadout = pet.loadout,
			})
		end
	end
	return {
		battleId = battleId,
		seed = seed,
		sides = {
			{ controller = "Player", team = team },
			{
				controller = "AI",
				ai = enc.ai,
				team = {
					{
						speciesId = EncounterRules.opponentSpecies(p, encounterId) :: string,
						form = enc.opponent.form,
						level = enc.opponent.level,
						isOpaco = true,
						modifier = enc.opponent.modifier,
					},
				},
			},
		},
	}
end

local function dayIndex(now: number): number
	return math.floor(now / 86400)
end

-- Aplica el resultado de un combate terminado. `won` lo decide el motor del servidor.
function EncounterRules.applyResult(
	p: Profile,
	encounterId: string,
	battleId: string,
	won: boolean,
	participants: { string },
	ctx: PetRules.Ctx
): Result.Result
	local enc = Encounters.ById[encounterId]
	if not enc then
		return Result.fail("UnknownEncounter")
	end
	local rewardId = "battle:" .. battleId
	if RewardRules.isKnown(p, rewardId) then
		return Result.fail("ResultAlreadyApplied")
	end

	for _, petId in ipairs(participants) do
		local pet = p.pets[petId]
		if pet then
			if won then
				pet.stats.battlesWon += 1
			else
				pet.stats.battlesLost += 1
			end
		end
	end

	if not won then
		-- Derrota: XP de consolación directa (sin pantalla de recompensa)
		local results = {}
		for _, petId in ipairs(participants) do
			local pet = p.pets[petId]
			if pet then
				results[petId] = PetRules.addXp(pet, enc.lossPetXp, ctx)
			end
		end
		return Result.ok({ won = false, pets = results })
	end

	-- Se calcula todo antes de mutar: si la recompensa no puede crearse, el perfil
	-- queda intacto (nunca "superado sin recompensa").
	local firstClear = p.story.cleared[encounterId] == nil
	local today = dayIndex(ctx.now)
	local repeatCount = if p.story.repeatDay == today then p.story.repeatCount else 0
	local spec: RewardRules.RewardSpec
	if firstClear then
		spec = {
			bundleId = enc.firstClearBonus,
			currencies = { Monedas = enc.baseReward.Monedas },
			petXp = enc.baseReward.petXp,
			petIds = participants,
		}
	else
		if repeatCount >= Encounters.Repeat.DailyRewardedRepeats then
			p.story.cleared[encounterId].wins += 1
			return Result.ok({ won = true, firstClear = false, capped = true })
		end
		local scale = Encounters.Repeat.RewardScale
		spec = {
			title = "Opaco restaurado de nuevo",
			currencies = { Monedas = math.floor(enc.baseReward.Monedas * scale) },
			petXp = math.floor(enc.baseReward.petXp * scale),
			petIds = participants,
		}
	end
	local created =
		RewardRules.create(p, rewardId, spec, { kind = "Encounter", ref = encounterId, battleId = battleId }, ctx.now)
	if not created.ok then
		return created
	end
	if firstClear then
		p.story.cleared[encounterId] = { firstClearAt = ctx.now, wins = 1 }
	else
		p.story.cleared[encounterId].wins += 1
		p.story.repeatDay = today
		p.story.repeatCount = repeatCount + 1
	end
	return Result.ok({ won = true, firstClear = firstClear, rewardId = rewardId })
end

return EncounterRules
