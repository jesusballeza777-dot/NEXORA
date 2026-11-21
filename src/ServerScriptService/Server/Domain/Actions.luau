--!strict
-- Casos de uso del jugador: orquestan las reglas de dominio sobre un perfil.
-- Los servicios de Roblox solo validan la petición (tipos, frecuencia, proximidad,
-- secuencia) y llaman aquí. Las pruebas de integración usan exactamente este código.
--
-- Cada acción devuelve Result con, opcionalmente:
--   data.analytics  = { {name, fields} }  eventos a registrar
--   data.onboarding = { pasos completados }

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Onboarding = require(Shared.Config.Onboarding)
local Encounters = require(Shared.Config.Encounters)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)
local SanctuaryRules = require(script.Parent.SanctuaryRules)
local RewardRules = require(script.Parent.RewardRules)
local OnboardingRules = require(script.Parent.OnboardingRules)
local EncounterRules = require(script.Parent.EncounterRules)
local ShopRules = require(script.Parent.ShopRules)

type Profile = Types.Profile
export type Ctx = PetRules.Ctx & { coinMultiplier: number? }

local Actions = {}

local HOME_HABITAT = "Hogar_H1"
local FIRST_COLLECT_BONUS = 50 -- primera recogida del tutorial (p. 110 "primera recogida de Monedas")

local function first(p: Profile, analytics: { any }, name: string, now: number, fields: { [string]: any }?)
	if not p.firsts[name] then
		p.firsts[name] = now
		table.insert(analytics, { name = name, fields = fields or {} })
	end
end

local function finish(p: Profile, r: Result.Result, analytics: { any }, now: number): Result.Result
	local steps = OnboardingRules.refresh(p, now)
	if r.ok then
		local data = r.data or {}
		data.analytics = analytics
		data.onboarding = steps
		data.onboardingStep = p.onboarding.step
		r.data = data
	end
	for _, s in ipairs(steps) do
		if s == "tutorial_completed" then
			table.insert(analytics, { name = "tutorial_completed", fields = {} })
		end
	end
	return r
end

function Actions.onLoad(p: Profile, ctx: Ctx): Result.Result
	p.loginCount += 1
	p.lastLoginAt = ctx.now
	local analytics = {}
	if p.loginCount == 1 then
		first(p, analytics, "onboarding_started", ctx.now)
	end
	OnboardingRules.onLoad(p, ctx.now)
	return finish(p, Result.ok({ step = p.onboarding.step }), analytics, ctx.now)
end

function Actions.finishIntro(p: Profile, skipped: boolean, ctx: Ctx): Result.Result
	local analytics = {}
	if not p.firsts.intro_finished then
		table.insert(analytics, { name = "intro_finished", fields = { skipped = skipped } })
	end
	OnboardingRules.finishIntro(p, skipped, ctx.now)
	return finish(p, Result.ok(), analytics, ctx.now)
end

function Actions.chooseStarter(p: Profile, eggId: string, ctx: Ctx): Result.Result
	if p.onboarding.step ~= "ChooseEgg" then
		return Result.fail("NotNow")
	end
	if PetRules.starterPet(p) then
		return Result.fail("StarterAlreadyChosen")
	end
	local speciesId: string? = nil
	for _, egg in ipairs(Onboarding.StarterEggs) do
		if egg.eggId == eggId then
			speciesId = egg.speciesId
		end
	end
	if not speciesId then
		return Result.fail("UnknownEgg")
	end
	local created = PetRules.create(p, speciesId :: string, { kind = "Starter", ref = eggId, at = ctx.now })
	if not created.ok then
		return created
	end
	local petId = (created.data :: any).petId
	PetRules.setCompanion(p, petId)
	local analytics = {}
	first(p, analytics, "starter_egg_selected", ctx.now, { egg = eggId, species = speciesId })
	return finish(p, Result.ok({ petId = petId, speciesId = speciesId }), analytics, ctx.now)
end

function Actions.ackHatch(p: Profile, ctx: Ctx): Result.Result
	if not PetRules.starterPet(p) then
		return Result.fail("NoStarter")
	end
	local analytics = {}
	first(p, analytics, "hatch_completed", ctx.now)
	first(p, analytics, "pet_follow_started", ctx.now)
	return finish(p, Result.ok(), analytics, ctx.now)
end

-- El jugador llega a su Lote Hogar (proximidad validada por el servicio).
function Actions.visitHome(p: Profile, ctx: Ctx): Result.Result
	local analytics = {}
	table.insert(analytics, { name = "sanctuary_visit", fields = {} })
	if not PetRules.starterPet(p) then
		return finish(p, Result.ok({ gifted = false }), analytics, ctx.now)
	end
	local gifted = false
	if not p.lots.Hogar.unlocked then
		SanctuaryRules.unlockLot(p, "Hogar", ctx, FIRST_COLLECT_BONUS)
		local g = RewardRules.grant(
			p,
			"onboarding:gift",
			{ bundleId = "OnboardingGift" },
			{ kind = "Onboarding", ref = "Gift" },
			ctx
		)
		gifted = g.ok
		first(p, analytics, "habitat_opened", ctx.now)
		table.insert(analytics, { name = "unlock_granted", fields = { unlock = "LoteHogar" } })
	end
	return finish(p, Result.ok({ gifted = gifted }), analytics, ctx.now)
end

function Actions.place(p: Profile, petId: string, slot: number, ctx: Ctx): Result.Result
	return finish(p, SanctuaryRules.place(p, petId, HOME_HABITAT, slot, ctx), {}, ctx.now)
end

function Actions.remove(p: Profile, slot: number, ctx: Ctx): Result.Result
	return finish(p, SanctuaryRules.remove(p, HOME_HABITAT, slot, ctx), {}, ctx.now)
end

function Actions.collect(p: Profile, ctx: Ctx): Result.Result
	local r = SanctuaryRules.collect(p, HOME_HABITAT, ctx)
	local analytics = {}
	if r.ok and (r.data :: any).coins > 0 then
		table.insert(analytics, { name = "coins_collected", fields = { amount = (r.data :: any).coins } })
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.feed(p: Profile, petId: string, foodId: string, ctx: Ctx): Result.Result
	local r = PetRules.feed(p, petId, foodId, ctx)
	local analytics = {}
	if r.ok then
		first(p, analytics, "first_feed", ctx.now, { food = foodId })
		if (r.data :: any).bondGained > 0 then
			first(p, analytics, "first_bond_gain", ctx.now, { via = "feed" })
		end
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.play(p: Profile, petId: string, ctx: Ctx): Result.Result
	local r = PetRules.play(p, petId, ctx)
	local analytics = {}
	if r.ok and (r.data :: any).bondGained > 0 then
		first(p, analytics, "first_bond_gain", ctx.now, { via = "play" })
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.evolve(p: Profile, petId: string, ctx: Ctx): Result.Result
	local r = PetRules.evolve(p, petId, ctx)
	local analytics = {}
	if r.ok then
		table.insert(analytics, { name = "pet_evolved", fields = { species = p.pets[petId].speciesId } })
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.setCompanion(p: Profile, petId: string, ctx: Ctx): Result.Result
	return finish(p, PetRules.setCompanion(p, petId), {}, ctx.now)
end

function Actions.setNickname(p: Profile, petId: string, filtered: string?, ctx: Ctx): Result.Result
	return finish(p, PetRules.setNickname(p, petId, filtered), {}, ctx.now)
end

function Actions.buyFood(p: Profile, foodId: string, quantity: number, ctx: Ctx): Result.Result
	local r = ShopRules.buyFood(p, foodId, quantity)
	local analytics = {}
	if r.ok then
		table.insert(analytics, { name = "food_purchased", fields = { food = foodId, quantity = quantity } })
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.canStartEncounter(p: Profile, encounterId: string): Result.Result
	if
		p.onboarding.step ~= "Done"
		and OnboardingRules.stepIndex(p.onboarding.step) < OnboardingRules.stepIndex("FirstBattle")
	then
		return Result.fail("FinishTutorialFirst")
	end
	return EncounterRules.canStart(p, encounterId)
end

function Actions.markBattleStarted(p: Profile, encounterId: string, ctx: Ctx): { any }
	local analytics = { { name = "battle_started", fields = { encounter = encounterId } } }
	first(p, analytics, "first_battle_started", ctx.now, { encounter = encounterId })
	return analytics
end

function Actions.finishEncounter(
	p: Profile,
	encounterId: string,
	battleId: string,
	won: boolean,
	turns: number,
	participants: { string },
	ctx: Ctx
): Result.Result
	local r = EncounterRules.applyResult(p, encounterId, battleId, won, participants, ctx)
	local analytics = { { name = "battle_finished", fields = { encounter = encounterId, won = won, turns = turns } } }
	if r.ok then
		first(p, analytics, "first_battle_completed", ctx.now, { encounter = encounterId, won = won })
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.claimReward(p: Profile, rewardId: string, ctx: Ctx): Result.Result
	local r = RewardRules.claim(p, rewardId, ctx)
	local analytics = {}
	if r.ok then
		first(p, analytics, "first_reward_claimed", ctx.now, {
			reward = rewardId,
			secondsSinceStart = ctx.now - p.createdAt,
		})
		for _, u in ipairs((r.data :: any).newUnlocks) do
			table.insert(analytics, { name = "unlock_granted", fields = { unlock = u } })
		end
	end
	return finish(p, r, analytics, ctx.now)
end

Actions.HOME_HABITAT = HOME_HABITAT
Actions.EncounterOrder = Encounters.Order

return Actions
