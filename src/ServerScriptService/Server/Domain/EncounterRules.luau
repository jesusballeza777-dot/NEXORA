--!strict
-- Modo aventura (Acto I): requisitos, construcción del combate desde el perfil, estrellas
-- y retos, tesoros, rescates y premios por etapa, región, acto y jefe.
-- * El resultado lo decide el motor del servidor; aquí solo se aplica una vez por combate
--   (recompensa "battle:<id>", pendiente → reclamada con procedencia).
-- * Repetir una etapa superada da el 25 % de Monedas y XP con un tope de 10 al día.
-- * Sin energía: se puede jugar cuanto se quiera (p. 111).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Encounters = require(Shared.Config.Encounters)
local SpeciesConfig = require(Shared.Config.Species)
local Rarities = require(Shared.Config.Rarities)
local ElementChart = require(Shared.Domain.ElementChart)
local Rng = require(Shared.Domain.Rng)
local BattleEngine = require(Shared.Domain.Battle.BattleEngine)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)
local PetRules = require(script.Parent.PetRules)
local RewardRules = require(script.Parent.RewardRules)
local CollectionRules = require(script.Parent.CollectionRules)
local EggRules = require(script.Parent.EggRules)
local HistoryRules = require(script.Parent.HistoryRules)

type Profile = Types.Profile

local EncounterRules = {}

-- Derrotas con XP de consolación por día (las victorias tienen su propio tope de repetición)
EncounterRules.DAILY_CONSOLATION_LIMIT = 10
-- Equipo de jefe: coste máximo como la Arena 1v1 (p. 113)
EncounterRules.BOSS_TEAM_COST = 12

-- Resumen del combate que usa la evaluación de estrellas (BattleEngine.summary)
export type BattleSummary = {
	turns: number,
	faints: number,
	elements: { [string]: boolean },
	rootsCut: number,
	teamSize: number,
}

local function stars(p: Profile, id: string): { boolean }
	return p.story.stars[id] or { false, false, false }
end

local function hasAllStars(p: Profile, id: string): boolean
	local s = p.story.stars[id]
	return s ~= nil and s[1] == true and s[2] == true and s[3] == true
end

function EncounterRules.regionDef(regionIndex: number)
	return Encounters.Regions[regionIndex]
end

function EncounterRules.regionCleared(p: Profile, regionIndex: number): boolean
	local region = Encounters.Regions[regionIndex]
	if not region then
		return false
	end
	for _, id in ipairs(region.stages) do
		if not p.story.cleared[id] then
			return false
		end
	end
	return true
end

function EncounterRules.regionAllStars(p: Profile, regionIndex: number): boolean
	local region = Encounters.Regions[regionIndex]
	if not region then
		return false
	end
	for _, id in ipairs(region.stages) do
		if not hasAllStars(p, id) then
			return false
		end
	end
	return true
end

function EncounterRules.isUnlocked(p: Profile, encounterId: string): boolean
	local enc = Encounters.ById[encounterId]
	if not enc then
		return false
	end
	for _, req in ipairs(enc.requires) do
		if not p.story.cleared[req] then
			return false
		end
	end
	if enc.requiresRegionStars and not EncounterRules.regionAllStars(p, enc.requiresRegionStars :: number) then
		return false
	end
	return true
end

local function resolveSpecies(p: Profile, opp: Encounters.OpponentDef): string?
	if opp.speciesId then
		return opp.speciesId
	end
	local starter = PetRules.starterPet(p)
	if not starter or not opp.byStarterElement then
		return nil
	end
	local element = SpeciesConfig.ById[starter.speciesId].elements[1]
	return (opp.byStarterElement :: any)[element]
end

function EncounterRules.opponentsFor(p: Profile, encounterId: string): { string }
	local enc = Encounters.ById[encounterId]
	local out = {}
	for _, opp in ipairs(enc.opponents) do
		local id = resolveSpecies(p, opp)
		if id then
			table.insert(out, id)
		end
	end
	return out
end

-- Primer rival (compatibilidad con el mundo de la Fase 1)
function EncounterRules.opponentSpecies(p: Profile, encounterId: string): string?
	local enc = Encounters.ById[encounterId]
	if not enc or #enc.opponents == 0 then
		return nil
	end
	return resolveSpecies(p, enc.opponents[1])
end

-- Monstruos que pelean: el equipo elegido (o el acompañante), hasta el tamaño de la etapa.
function EncounterRules.participantsFor(p: Profile, encounterId: string): { string }
	local enc = Encounters.ById[encounterId]
	local limit = if enc then enc.teamSize else 3
	local out = {}
	for _, petId in ipairs(p.team) do
		if p.pets[petId] and #out < limit then
			table.insert(out, petId)
		end
	end
	if #out == 0 and p.companionPetId and p.pets[p.companionPetId] then
		table.insert(out, p.companionPetId)
	end
	return out
end

function EncounterRules.teamCost(p: Profile, petIds: { string }): number
	local total = 0
	for _, id in ipairs(petIds) do
		local pet = p.pets[id]
		if pet then
			local rarity = Rarities.ById[SpeciesConfig.ById[pet.speciesId].rarity]
			total += if pet.form == "Tallado" then rarity.teamCost else rarity.teamCost - 1
		end
	end
	return total
end

function EncounterRules.canStart(p: Profile, encounterId: string): Result.Result
	local enc = Encounters.ById[encounterId]
	if not enc then
		return Result.fail("UnknownEncounter")
	end
	if enc.stageType == "Tesoro" then
		return Result.fail("NotABattle")
	end
	if not EncounterRules.isUnlocked(p, encounterId) then
		return Result.fail("EncounterLocked")
	end
	local team = EncounterRules.participantsFor(p, encounterId)
	if #team == 0 then
		return Result.fail("NoCompanion")
	end
	if enc.stageType == "Jefe" and EncounterRules.teamCost(p, team) > EncounterRules.BOSS_TEAM_COST then
		return Result.fail("TeamTooCostly")
	end
	if #EncounterRules.opponentsFor(p, encounterId) ~= #enc.opponents then
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
	local act = Encounters.Acts[enc.act]
	local team = {}
	for _, petId in ipairs(EncounterRules.participantsFor(p, encounterId)) do
		local pet = p.pets[petId]
		table.insert(team, {
			speciesId = pet.speciesId,
			form = pet.form,
			level = pet.level,
			petId = pet.id,
			nickname = pet.nickname,
			loadout = pet.loadout,
		})
	end
	local foes = {}
	for i, opp in ipairs(enc.opponents) do
		table.insert(foes, {
			speciesId = EncounterRules.opponentsFor(p, encounterId)[i],
			guardianId = opp.guardianId,
			form = opp.form,
			level = opp.level,
			isOpaco = true,
			modifier = opp.modifier,
			rootHeal = if opp.rooted then act.rootHeal else nil,
		})
	end
	return {
		battleId = battleId,
		seed = seed,
		sides = {
			{ controller = "Player", team = team },
			{ controller = "AI", ai = enc.ai, team = foes },
		},
	}
end

local function dayIndex(now: number): number
	return math.floor(now / 86400)
end

-- ¿Se cumplió el reto (★★★) de la etapa?
function EncounterRules.challengeMet(p: Profile, enc: Encounters.EncounterDef, summary: BattleSummary): boolean
	local c = enc.challenge
	if c.kind == "MaxTurns" then
		return summary.turns <= c.value
	elseif c.kind == "CutRoots" then
		return summary.rootsCut >= c.value
	elseif c.kind == "UseElement" then
		return summary.elements[c.value] == true
	elseif c.kind == "TeamMax" then
		return summary.teamSize <= c.value
	elseif c.kind == "FirstTry" then
		return (p.counters["losses:" .. enc.id] or 0) == 0
	end
	return false
end

-- Marca estrellas (nunca se pierden). Devuelve las estrellas nuevas.
local function awardStars(p: Profile, id: string, earned: { boolean }): number
	local current = stars(p, id)
	local fresh = 0
	local merged = {}
	for i = 1, 3 do
		merged[i] = current[i] or earned[i]
		if merged[i] and not current[i] then
			fresh += 1
		end
	end
	p.story.stars[id] = merged
	return fresh
end

-- Premios de región/acto/jefe que se desbloquean al completar una etapa. Se agregan a la
-- recompensa de esa etapa (spec) y al resultado (info). Cada uno se concede una vez.
local function milestoneRewards(p: Profile, enc: Encounters.EncounterDef, spec: any, info: any, now: number)
	local region = Encounters.Regions[enc.region]
	local act = Encounters.Acts[enc.act]
	if
		region
		and EncounterRules.regionCleared(p, region.index)
		and not p.story.regionRewards[region.id .. ":clear"]
	then
		p.story.regionRewards[region.id .. ":clear"] = now
		table.insert(spec.decor, region.clearDecor)
		p.codex[region.clearCodex] = p.codex[region.clearCodex] or now
		table.insert(info.codex, region.clearCodex)
		info.regionCleared = region.index
		info.slotsOpened = EggRules.refreshSlots(p)
	end
	if
		region
		and EncounterRules.regionAllStars(p, region.index)
		and not p.story.regionRewards[region.id .. ":stars"]
	then
		p.story.regionRewards[region.id .. ":stars"] = now
		table.insert(spec.chests, act.regionStarsChest)
		info.regionStars = region.index
	end
	if enc.stageType == "Jefe" and not p.guardians[act.guardian] then
		p.guardians[act.guardian] = now
		table.insert(spec.unlocks, act.completeUnlock)
		info.guardianRestored = act.guardian
	end
	if not p.story.actRewards[act.id .. ":stars"] then
		local all = true
		for _, id in ipairs(Encounters.Order) do
			local e = Encounters.ById[id]
			if e.act == act.id and not hasAllStars(p, id) then
				all = false
				break
			end
		end
		if all then
			p.story.actRewards[act.id .. ":stars"] = now
			table.insert(spec.frames, act.allStars.frame)
			table.insert(spec.titles, act.allStars.title)
			info.actAllStars = act.id
		end
	end
end

-- Completa una etapa ganada (combate o tesoro): estrellas, premio de primera vez o de
-- repetición, hitos. Calcula todo antes de mutar lo irreversible.
local function completeStage(
	p: Profile,
	enc: Encounters.EncounterDef,
	earned: { boolean },
	participants: { string },
	rewardId: string,
	source: { kind: string, ref: string, battleId: string? },
	ctx: PetRules.Ctx,
	rescueSeed: string?
): Result.Result
	local firstClear = p.story.cleared[enc.id] == nil
	local today = dayIndex(ctx.now)
	local repeatCount = if p.story.repeatDay == today then p.story.repeatCount else 0
	if not firstClear and repeatCount >= Encounters.Repeat.DailyRewardedRepeats then
		p.story.cleared[enc.id].wins += 1
		local fresh = awardStars(p, enc.id, earned)
		return Result.ok({ won = true, firstClear = false, capped = true, stars = stars(p, enc.id), newStars = fresh })
	end
	local spec: any = {
		currencies = {},
		petXp = 0,
		petIds = participants,
		chests = {},
		eggs = {},
		decor = {},
		titles = {},
		frames = {},
		unlocks = {},
	}
	local info: any = { codex = {} }
	if firstClear then
		spec.bundleId = enc.firstClearBonus
		spec.title = if enc.firstClearBonus then nil else enc.name
		spec.currencies.Monedas = enc.baseReward.Monedas
		spec.petXp = enc.baseReward.petXp
		if enc.firstClearChest then
			table.insert(spec.chests, enc.firstClearChest)
		end
		if enc.firstClearDecor then
			table.insert(spec.decor, enc.firstClearDecor)
		end
	else
		local scale = Encounters.Repeat.RewardScale
		spec.title = enc.name .. " · repetición"
		spec.currencies.Monedas = math.floor(enc.baseReward.Monedas * scale)
		spec.petXp = math.floor(enc.baseReward.petXp * scale)
	end
	-- Rescate: 10 % de huevo de la especie rescatada (tirada reproducible por combate)
	if enc.rescue and rescueSeed then
		local roll = Rng.new(Rng.seedFromString(rescueSeed)):next()
		if roll < enc.rescue.eggChance then
			table.insert(spec.eggs, enc.rescue.speciesId)
			info.rescueEgg = enc.rescue.speciesId
		end
	end
	-- Estado del avance (antes de los hitos, que dependen de él)
	if firstClear then
		p.story.cleared[enc.id] = { firstClearAt = ctx.now, wins = 1 }
		for _, entryId in ipairs(enc.firstClearCodex or {}) do
			p.codex[entryId] = p.codex[entryId] or ctx.now
			table.insert(info.codex, entryId)
		end
	else
		p.story.cleared[enc.id].wins += 1
		p.story.repeatDay = today
		p.story.repeatCount = repeatCount + 1
	end
	local fresh = awardStars(p, enc.id, earned)
	milestoneRewards(p, enc, spec, info, ctx.now)
	local created = RewardRules.create(p, rewardId, spec, source, ctx.now)
	if not created.ok then
		return created
	end
	HistoryRules.add(p, {
		kind = "Stage",
		ref = enc.id,
		detail = string.format(
			"%d★",
			(stars(p, enc.id)[1] and 1 or 0) + (stars(p, enc.id)[2] and 1 or 0) + (stars(p, enc.id)[3] and 1 or 0)
		),
		at = ctx.now,
		source = enc.stageType,
	})
	info.won = true
	info.firstClear = firstClear
	info.rewardId = rewardId
	info.stars = stars(p, enc.id)
	info.newStars = fresh
	info.chests = spec.chests
	return Result.ok(info)
end

-- Aplica el resultado de un combate terminado. `won` y `summary` los decide el motor.
function EncounterRules.applyResult(
	p: Profile,
	encounterId: string,
	battleId: string,
	won: boolean,
	participants: { string },
	ctx: PetRules.Ctx,
	reason: string?,
	summary: BattleSummary?
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
		-- Retirarse nunca da premio (si no, empezar y huir sería una granja de XP).
		if reason == "Forfeit" then
			return Result.ok({ won = false, forfeited = true })
		end
		p.counters["losses:" .. encounterId] = (p.counters["losses:" .. encounterId] or 0) + 1
		-- Derrota real: XP de consolación directa, con tope diario
		local today = dayIndex(ctx.now)
		if (p.counters.lossXpDay or 0) ~= today then
			p.counters.lossXpDay = today
			p.counters.lossXpCount = 0
		end
		if (p.counters.lossXpCount or 0) >= EncounterRules.DAILY_CONSOLATION_LIMIT then
			return Result.ok({ won = false, capped = true })
		end
		p.counters.lossXpCount = (p.counters.lossXpCount or 0) + 1
		local results = {}
		for _, petId in ipairs(participants) do
			local pet = p.pets[petId]
			if pet then
				results[petId] = PetRules.addXp(pet, enc.lossPetXp, ctx)
			end
		end
		return Result.ok({ won = false, pets = results })
	end

	-- Restaurar a los Opacos vencidos: entran al Bestiario
	local restored = {}
	for _, speciesId in ipairs(EncounterRules.opponentsFor(p, encounterId)) do
		if SpeciesConfig.ById[speciesId] then
			if CollectionRules.restore(p, speciesId, ctx.now) then
				table.insert(restored, speciesId)
			end
		end
	end

	local sum: BattleSummary = summary or { turns = 99, faints = 1, elements = {}, rootsCut = 0, teamSize = 3 }
	local earned = { true, sum.faints == 0, EncounterRules.challengeMet(p, enc, sum) }
	local r = completeStage(
		p,
		enc,
		earned,
		participants,
		rewardId,
		{ kind = "Encounter", ref = encounterId, battleId = battleId },
		ctx,
		"rescue:" .. battleId
	)
	if r.ok and r.data then
		(r.data :: any).newSpecies = restored;
		(r.data :: any).opponents = #enc.opponents
		if sum.turns < (p.story.bestTurns[encounterId] or math.huge) then
			p.story.bestTurns[encounterId] = sum.turns
		end
	end
	return r
end

-- Etapa de Tesoro: acertijo elemental. Correcto si el elemento elegido es eficaz contra
-- el sello (ElementChart). Se puede reintentar sin coste; las estrellas premian acertar
-- pronto: ★ abrirlo · ★★ en dos intentos o menos · ★★★ reto (al primer intento).
function EncounterRules.solveTreasure(
	p: Profile,
	encounterId: string,
	element: string,
	ctx: PetRules.Ctx
): Result.Result
	local enc = Encounters.ById[encounterId]
	if not enc or enc.stageType ~= "Tesoro" or not enc.riddle then
		return Result.fail("NotATreasure")
	end
	if not EncounterRules.isUnlocked(p, encounterId) then
		return Result.fail("EncounterLocked")
	end
	local riddle = enc.riddle :: any
	if not table.find(riddle.options, element) then
		return Result.fail("BadOption")
	end
	local attempts = (p.story.treasureAttempts[encounterId] or 0) + 1
	p.story.treasureAttempts[encounterId] = attempts
	if ElementChart.classify(ElementChart.multiplier(element, { riddle.sealElement }, false)) ~= "Strong" then
		p.counters["losses:" .. encounterId] = (p.counters["losses:" .. encounterId] or 0) + 1
		return Result.ok({ solved = false, attempts = attempts })
	end
	local wins = if p.story.cleared[encounterId] then p.story.cleared[encounterId].wins else 0
	local rewardId = string.format("treasure:%s:%d", encounterId, wins + 1)
	local earned = {
		true,
		attempts - (p.counters["treasureBase:" .. encounterId] or 0) <= 2,
		EncounterRules.challengeMet(p, enc, { turns = 0, faints = 0, elements = {}, rootsCut = 0, teamSize = 0 }),
	}
	p.counters["treasureBase:" .. encounterId] = attempts
	local r = completeStage(
		p,
		enc,
		earned,
		EncounterRules.participantsFor(p, encounterId),
		rewardId,
		{ kind = "Treasure", ref = encounterId },
		ctx,
		nil
	)
	if r.ok and r.data then
		(r.data :: any).solved = true
	end
	return r
end

return EncounterRules
