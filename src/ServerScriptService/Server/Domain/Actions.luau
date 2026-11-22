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
local CollectionRules = require(script.Parent.CollectionRules)
local EggRules = require(script.Parent.EggRules)
local ChestRules = require(script.Parent.ChestRules)
local QuestRules = require(script.Parent.QuestRules)
local DecorRules = require(script.Parent.DecorRules)
local Sanctuary = require(Shared.Config.Sanctuary)

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

-- Progreso de encargos por un evento interno del servidor (nunca del cliente)
local function track(p: Profile, analytics: { any }, event: string, amount: number, now: number)
	if amount <= 0 then
		return
	end
	for _, questId in ipairs(QuestRules.track(p, event, amount, now)) do
		table.insert(analytics, { name = "quest_completed", fields = { quest = questId } })
	end
end

local function secondsSinceStart(p: Profile, now: number): number
	return now - p.createdAt
end

local function discovered(p: Profile, analytics: { any }, speciesId: string, via: string, now: number)
	table.insert(analytics, { name = "species_discovered", fields = { species = speciesId, via = via } })
	track(p, analytics, "SpeciesDiscovered", 1, now)
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
	QuestRules.refresh(p, ctx.now)
	EggRules.refreshSlots(p)
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
	if CollectionRules.obtain(p, speciesId :: string, "Brote", ctx.now).newSpecies then
		discovered(p, analytics, speciesId :: string, "Starter", ctx.now)
	end
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
		track(p, analytics, "CollectCoins", 1, ctx.now)
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
		track(p, analytics, "Feed", 1, ctx.now)
		track(p, analytics, "PetXp", (r.data :: any).xpGained or 0, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.play(p: Profile, petId: string, ctx: Ctx): Result.Result
	local r = PetRules.play(p, petId, ctx)
	local analytics = {}
	if r.ok and (r.data :: any).bondGained > 0 then
		first(p, analytics, "first_bond_gain", ctx.now, { via = "play" })
	end
	if r.ok then
		track(p, analytics, "Play", 1, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.evolve(p: Profile, petId: string, ctx: Ctx): Result.Result
	local r = PetRules.evolve(p, petId, ctx)
	local analytics = {}
	if r.ok then
		local speciesId = p.pets[petId].speciesId
		table.insert(analytics, { name = "pet_evolved", fields = { species = speciesId } })
		first(p, analytics, "first_evolution", ctx.now, { seconds = secondsSinceStart(p, ctx.now) })
		local found = CollectionRules.obtain(p, speciesId, "Tallado", ctx.now, false)
		local data = r.data :: any
		data.newCard = found.newCard
		data.speciesId = speciesId
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
	local enc = Encounters.ById[encounterId]
	local analytics = {
		{ name = "battle_started", fields = { encounter = encounterId } },
		{ name = "adventure_stage_started", fields = { stage = encounterId, kind = enc.stageType } },
	}
	if enc.stageType == "Jefe" then
		table.insert(analytics, { name = "guardian_battle_started", fields = { stage = encounterId } })
	end
	first(p, analytics, "first_battle_started", ctx.now, { encounter = encounterId })
	-- Ver a un Opaco lo registra en el Bestiario (nivel 1)
	for _, speciesId in ipairs(EncounterRules.opponentsFor(p, encounterId)) do
		if CollectionRules.see(p, speciesId, ctx.now) then
			discovered(p, analytics, speciesId, "Seen", ctx.now)
		end
	end
	return analytics
end

-- Registra lo que deja una etapa completada (combate o tesoro) en analítica y encargos.
local function stageCompleted(p: Profile, analytics: { any }, encounterId: string, data: any, ctx: Ctx)
	local enc = Encounters.ById[encounterId]
	table.insert(analytics, {
		name = "adventure_stage_completed",
		fields = { stage = encounterId, firstClear = data.firstClear == true, kind = enc.stageType },
	})
	first(p, analytics, "first_stage_completed", ctx.now, { seconds = secondsSinceStart(p, ctx.now) })
	track(p, analytics, "StageCleared", 1, ctx.now)
	if (data.newStars or 0) > 0 then
		for _ = 1, data.newStars do
			table.insert(analytics, { name = "stage_star_earned", fields = { stage = encounterId } })
		end
		track(p, analytics, "StarEarned", data.newStars, ctx.now)
	end
	for _, entryId in ipairs(data.codex or {}) do
		table.insert(analytics, { name = "codex_entry_unlocked", fields = { entry = entryId } })
	end
	if data.guardianRestored then
		table.insert(analytics, { name = "guardian_defeated", fields = { guardian = data.guardianRestored } })
	end
end

function Actions.finishEncounter(
	p: Profile,
	encounterId: string,
	battleId: string,
	won: boolean,
	turns: number,
	participants: { string },
	ctx: Ctx,
	reason: string?,
	summary: EncounterRules.BattleSummary?
): Result.Result
	local r = EncounterRules.applyResult(p, encounterId, battleId, won, participants, ctx, reason, summary)
	local analytics = {
		-- turns es numérico: AnalyticsTracker lo usa como valor del evento
		{
			name = "battle_finished",
			fields = { encounter = encounterId, won = won, reason = reason or "Defeat", turns = turns },
		},
	}
	if r.ok then
		first(p, analytics, "first_battle_completed", ctx.now, { encounter = encounterId, won = won })
		if won then
			local data = r.data :: any
			track(p, analytics, "BattleWon", 1, ctx.now)
			local enc = Encounters.ById[encounterId]
			table.insert(
				analytics,
				{ name = "opaco_restored", fields = { stage = encounterId, amount = #enc.opponents } }
			)
			track(p, analytics, "OpacoRestored", #enc.opponents, ctx.now)
			for _, speciesId in ipairs(data.newSpecies or {}) do
				discovered(p, analytics, speciesId, "Restored", ctx.now)
			end
			stageCompleted(p, analytics, encounterId, data, ctx)
		end
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.solveTreasure(p: Profile, encounterId: string, element: string, ctx: Ctx): Result.Result
	local r = EncounterRules.solveTreasure(p, encounterId, element, ctx)
	local analytics = {}
	if r.ok and (r.data :: any).solved then
		stageCompleted(p, analytics, encounterId, r.data, ctx)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.claimReward(p: Profile, rewardId: string, ctx: Ctx): Result.Result
	local r = RewardRules.claim(p, rewardId, ctx)
	local analytics = {}
	if r.ok then
		local data = r.data :: any
		first(p, analytics, "first_reward_claimed", ctx.now, {
			reward = rewardId,
			secondsSinceStart = ctx.now - p.createdAt,
		})
		for _, u in ipairs(data.newUnlocks) do
			table.insert(analytics, { name = "unlock_granted", fields = { unlock = u } })
		end
		for _, chestId in ipairs(data.chestIds or {}) do
			table.insert(analytics, { name = "chest_obtained", fields = { chest = p.chests[chestId].chestType } })
		end
		for _, eggId in ipairs(data.eggIds or {}) do
			table.insert(analytics, { name = "egg_obtained", fields = { species = p.eggs[eggId].speciesId } })
		end
		local xp = 0
		for _, res in pairs(data.pets or {}) do
			xp += res.xpGained or 0
		end
		track(p, analytics, "PetXp", xp, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

-- ===================== Fase 2: huevos, cofres, encargos, santuario =====================

function Actions.openChest(p: Profile, chestId: string, ctx: Ctx): Result.Result
	local r = ChestRules.open(p, chestId, ctx.now)
	local analytics = {}
	if r.ok then
		local data = r.data :: any
		table.insert(analytics, { name = "chest_opened", fields = { chest = data.chestType } })
		for _, eggId in ipairs(data.eggIds) do
			table.insert(analytics, { name = "egg_obtained", fields = { species = p.eggs[eggId].speciesId } })
		end
		for _, entryId in ipairs(data.codex) do
			table.insert(analytics, { name = "codex_entry_unlocked", fields = { entry = entryId } })
		end
		track(p, analytics, "ChestOpened", 1, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.startIncubation(p: Profile, eggId: string, slot: number, ctx: Ctx): Result.Result
	local r = EggRules.startIncubation(p, eggId, slot, ctx.now)
	local analytics = {}
	if r.ok then
		table.insert(analytics, { name = "incubation_started", fields = { species = p.eggs[eggId].speciesId } })
		track(p, analytics, "IncubationStarted", 1, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.hatchEgg(p: Profile, slot: number, ctx: Ctx): Result.Result
	local r = EggRules.hatch(p, slot, ctx.now)
	local analytics = {}
	if r.ok then
		local data = r.data :: any
		table.insert(analytics, { name = "incubation_completed", fields = { species = data.speciesId } })
		table.insert(analytics, { name = "egg_hatched", fields = { species = data.speciesId, rarity = data.rarity } })
		first(p, analytics, "first_hatch", ctx.now, { seconds = secondsSinceStart(p, ctx.now) })
		if PetRules.petCount(p) >= 2 then
			first(p, analytics, "second_creature", ctx.now, { seconds = secondsSinceStart(p, ctx.now) })
		end
		if data.newSpecies then
			discovered(p, analytics, data.speciesId, "Hatch", ctx.now)
		end
		track(p, analytics, "EggHatched", 1, ctx.now)
	end
	return finish(p, r, analytics, ctx.now)
end

function Actions.buyIncubatorSlot(p: Profile, slot: number, ctx: Ctx): Result.Result
	return finish(p, EggRules.buySlot(p, slot), {}, ctx.now)
end

function Actions.claimQuest(p: Profile, kind: string, index: number, ctx: Ctx): Result.Result
	local r = QuestRules.claim(p, kind, index, ctx.now)
	local analytics = {}
	if r.ok then
		local data = r.data :: any
		table.insert(analytics, { name = "quest_claimed", fields = { quest = data.questId, kind = kind } })
		if data.chestType then
			table.insert(analytics, { name = "chest_obtained", fields = { chest = data.chestType } })
		end
	end
	return finish(p, r, analytics, ctx.now)
end

-- Equipo para la aventura: hasta 3 monstruos propios, sin repetir (el acompañante no cambia)
function Actions.setTeam(p: Profile, petIds: { string }, ctx: Ctx): Result.Result
	if #petIds == 0 or #petIds > Sanctuary.MaxTeamSize then
		return Result.fail("BadTeamSize")
	end
	local seen: { [string]: boolean } = {}
	for _, id in ipairs(petIds) do
		if not p.pets[id] then
			return Result.fail("PetNotOwned")
		end
		if seen[id] then
			return Result.fail("DuplicatePet")
		end
		seen[id] = true
	end
	p.team = table.clone(petIds)
	return finish(p, Result.ok({ team = p.team }), {}, ctx.now)
end

local function sanctuaryUpdated(r: Result.Result, what: string): { any }
	return if r.ok then { { name = "sanctuary_updated", fields = { change = what } } } else {}
end

function Actions.placeDecor(p: Profile, slot: number, decorId: string?, ctx: Ctx): Result.Result
	local r = DecorRules.place(p, slot, decorId)
	return finish(p, r, sanctuaryUpdated(r, "Decor"), ctx.now)
end

function Actions.applyDecorTemplate(p: Profile, templateId: string, ctx: Ctx): Result.Result
	local r = DecorRules.applyTemplate(p, templateId)
	return finish(p, r, sanctuaryUpdated(r, "Template"), ctx.now)
end

function Actions.setShowcase(p: Profile, petIds: { string }, ctx: Ctx): Result.Result
	local r = DecorRules.setShowcase(p, petIds)
	return finish(p, r, sanctuaryUpdated(r, "Showcase"), ctx.now)
end

function Actions.expandInventory(p: Profile, ctx: Ctx): Result.Result
	local r = DecorRules.expandInventory(p)
	return finish(p, r, sanctuaryUpdated(r, "Inventory"), ctx.now)
end

function Actions.equipTitle(p: Profile, titleId: string?, ctx: Ctx): Result.Result
	if titleId and not p.titles.owned[titleId] then
		return Result.fail("TitleNotOwned")
	end
	p.titles.equipped = titleId
	return finish(p, Result.ok({ title = titleId }), {}, ctx.now)
end

Actions.HOME_HABITAT = HOME_HABITAT
Actions.EncounterOrder = Encounters.Order

return Actions
