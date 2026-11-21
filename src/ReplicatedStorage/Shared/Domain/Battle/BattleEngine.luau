--!strict
-- Motor de combate por turnos simultáneos (Biblia v5.0 p. 40).
--
-- * Puro y determinista: no usa APIs de Roblox; todo azar sale de un Rng sembrado.
--   El servidor es el único que lo ejecuta (BattleService); el cliente solo recibe
--   eventos para animarlos. Los tests de Lune lo ejecutan directamente.
-- * Equipos de hasta 3 por lado con un monstruo en campo (arquitectura de Arena 1v1);
--   el vertical slice usa 1 contra 1. Los cambios de monstruo llegan en Fase 2.
-- * Duraciones: cuentan finales de turno. Si el afectado ya actuó este turno, el
--   efecto dura un turno más, para que "1 turno" siempre afecte a una acción real.
--
-- Orden de consumo del Rng (el prototipo web replica este mismo orden):
--   1) desempate de velocidad (solo si hay empate real)
--   2) confusión (si aplica) 3) precisión (solo si < 100 %) 4) por impacto:
--   variación y crítico 5) probabilidades de efectos en orden de lista
--   6) talentos de contacto / parálisis extra.

local Shared = script.Parent.Parent.Parent
local Config = Shared.Config
local Abilities = require(Config.Abilities)
local Combat = require(Config.Combat)
local Talents = require(Config.Talents)
local SpeciesConfig = require(Config.Species)
local Encounters = require(Config.Encounters)
local Progression = require(Config.Progression)
local Stats = require(Shared.Domain.Stats)
local ElementChart = require(Shared.Domain.ElementChart)
local RngModule = require(Shared.Domain.Rng)

type Rng = RngModule.Rng
type MoveDef = Abilities.MoveDef

export type CombatantSpec = {
	speciesId: string,
	form: string,
	level: number,
	petId: string?,
	nickname: string?,
	isOpaco: boolean?,
	modifier: string?,
	loadout: { string }?,
}

export type Mod = { stat: string, amount: number, turns: number }

export type Combatant = {
	uid: string,
	side: number,
	slot: number,
	petId: string?,
	speciesId: string,
	form: string,
	level: number,
	name: string,
	rarity: string,
	isOpaco: boolean,
	elements: { string },
	base: { [string]: number },
	scale: number,
	maxHp: number,
	hp: number,
	savia: number,
	nexoUsed: number,
	moves: { string },
	talent: string?,
	statuses: { [string]: number },
	mods: { Mod },
	shield: { amount: number, turns: number, thornsStatus: string?, thornsChance: number? }?,
	block: number, -- finales de turno restantes (0 = sin bloqueo)
	dodge: number,
	reflect: { percent: number, turns: number, filter: string }?,
	hot: { percent: number, turns: number }?,
	empowerNext: number,
	nextSpecialFails: boolean,
	damagedThisTurn: boolean,
	wasHitLastTurn: boolean,
	actedThisTurn: boolean,
	fainted: boolean,
}

export type Side = {
	index: number,
	controller: "Player" | "AI",
	ai: string?,
	team: { Combatant },
	active: number,
}

export type Action = { kind: "Move", moveId: string } | { kind: "Forfeit" }

export type Event = { [string]: any }

export type BattleState = {
	battleId: string,
	seed: number,
	rng: Rng,
	turn: number,
	maxTurns: number,
	phase: "Choosing" | "Ended",
	sides: { Side },
	pending: { [number]: Action },
	outcome: { winner: number?, reason: string }?,
	log: { Event },
}

local BattleEngine = {}

local NEGATIVE_STATUSES = { "Burn", "Paralysis", "Stun", "Sleep", "Confuse" }
local INCAPACITATING = { Sleep = true, Stun = true, Paralysis = true }
-- Orden fijo de comprobación (no depender del orden de pairs()).
local INCAPACITATING_ORDER = { "Sleep", "Stun", "Paralysis" }

-- ======================================================================
-- Construcción
-- ======================================================================

function BattleEngine.defaultLoadout(speciesId: string, form: string, level: number): { string }
	local species = SpeciesConfig.ById[speciesId]
	assert(species, "Especie desconocida: " .. speciesId)
	local moves: { string } = {}
	local primary = species.elements[1]
	if primary then
		local rep = Abilities.ByElement[primary]
		for i = 1, Combat.Loadout.Basics do
			if rep.basics[i] then
				table.insert(moves, rep.basics[i])
			end
		end
		for i = 1, Combat.Loadout.Specials do
			if rep.specials[i] then
				table.insert(moves, rep.specials[i])
			end
		end
	end
	if species.signature then
		table.insert(moves, species.signature)
	end
	if primary and form == "Tallado" and level >= Progression.NexoUnlockLevel then
		table.insert(moves, Abilities.ByElement[primary].nexo)
	end
	return moves
end

function BattleEngine.createCombatant(spec: CombatantSpec, side: number, slot: number): Combatant
	local species = SpeciesConfig.ById[spec.speciesId]
	assert(species, "Especie desconocida: " .. spec.speciesId)
	local multipliers = nil
	if spec.modifier then
		local mod = Encounters.Modifiers[spec.modifier]
		multipliers = if mod then mod.statMultipliers else nil
	end
	local base = Stats.effective(spec.speciesId, spec.form, spec.level, multipliers :: any)
	local maxHp = Stats.maxHp(base.VID)
	local name = spec.nickname or (if spec.form == "Tallado" then species.talladoName else species.broteName)
	if spec.isOpaco then
		name = "Opaco de " .. name
	end
	return {
		uid = string.format("S%dC%d", side, slot),
		side = side,
		slot = slot,
		petId = spec.petId,
		speciesId = spec.speciesId,
		form = spec.form,
		level = spec.level,
		name = name,
		rarity = species.rarity,
		isOpaco = spec.isOpaco == true,
		elements = table.clone(species.elements),
		base = base :: any,
		scale = Stats.scale(spec.form, spec.level),
		maxHp = maxHp,
		hp = maxHp,
		savia = Combat.Savia.Start,
		nexoUsed = 0,
		moves = spec.loadout or BattleEngine.defaultLoadout(spec.speciesId, spec.form, spec.level),
		talent = species.talent,
		statuses = {},
		mods = {},
		shield = nil,
		block = 0,
		dodge = 0,
		reflect = nil,
		hot = nil,
		empowerNext = 0,
		nextSpecialFails = false,
		damagedThisTurn = false,
		wasHitLastTurn = false,
		actedThisTurn = false,
		fainted = false,
	}
end

export type BattleSetup = {
	battleId: string,
	seed: number,
	maxTurns: number?,
	sides: { { controller: "Player" | "AI", ai: string?, team: { CombatantSpec } } },
}

local function talentOf(c: Combatant)
	return if c.talent then Talents.ById[c.talent] else nil
end

function BattleEngine.new(setup: BattleSetup): BattleState
	assert(#setup.sides == 2, "El combate requiere dos lados")
	local sides: { Side } = {}
	for i, s in ipairs(setup.sides) do
		assert(#s.team >= 1 and #s.team <= 3, "Cada equipo lleva de 1 a 3 monstruos")
		local team = {}
		for slot, spec in ipairs(s.team) do
			table.insert(team, BattleEngine.createCombatant(spec, i, slot))
		end
		table.insert(sides, { index = i, controller = s.controller, ai = s.ai, team = team, active = 1 })
	end
	local state: BattleState = {
		battleId = setup.battleId,
		seed = setup.seed,
		rng = RngModule.new(setup.seed),
		turn = 0,
		maxTurns = setup.maxTurns or Combat.MaxTurns,
		phase = "Choosing",
		sides = sides,
		pending = {},
		outcome = nil,
		log = {},
	}
	-- Talentos de inicio de combate
	for _, side in ipairs(sides) do
		local c = side.team[side.active]
		local t = talentOf(c)
		if t and t.kind == "BattleStartSavia" then
			c.savia = math.min(Combat.Savia.Max, c.savia + (t.amount or 1))
			table.insert(state.log, { t = "Talent", target = c.uid, talent = t.id, savia = c.savia })
		end
	end
	return state
end

-- ======================================================================
-- Consultas
-- ======================================================================

function BattleEngine.active(state: BattleState, side: number): Combatant
	local s = state.sides[side]
	return s.team[s.active]
end

local function opponentOf(state: BattleState, side: number): Combatant
	return BattleEngine.active(state, if side == 1 then 2 else 1)
end

function BattleEngine.moveCost(move: MoveDef): number
	if move.kind == "Basic" then
		return 0
	elseif move.kind == "Nexo" then
		return Combat.Savia.NexoCost
	end
	return Combat.Savia.SpecialCost
end

export type MoveOption = { moveId: string, usable: boolean, reason: string?, cost: number, kind: string }

function BattleEngine.availableMoves(state: BattleState, side: number): { MoveOption }
	local c = BattleEngine.active(state, side)
	local out: { MoveOption } = {}
	for _, id in ipairs(c.moves) do
		local m = Abilities.ById[id]
		if m then
			local cost = BattleEngine.moveCost(m)
			local usable, reason = true, nil
			if c.savia < cost then
				usable, reason = false, "NotEnoughSavia"
			elseif m.kind == "Nexo" and c.nexoUsed >= Combat.Savia.NexoUsesPerBattle then
				usable, reason = false, "NexoUsed"
			end
			table.insert(out, { moveId = id, usable = usable, reason = reason, cost = cost, kind = m.kind })
		end
	end
	return out
end

function BattleEngine.canUse(state: BattleState, side: number, moveId: string): (boolean, string?)
	for _, opt in ipairs(BattleEngine.availableMoves(state, side)) do
		if opt.moveId == moveId then
			return opt.usable, opt.reason
		end
	end
	return false, "MoveNotEquipped"
end

function BattleEngine.submit(state: BattleState, side: number, action: Action): (boolean, string?)
	if state.phase ~= "Choosing" then
		return false, "BattleEnded"
	end
	if side ~= 1 and side ~= 2 then
		return false, "BadSide"
	end
	if state.pending[side] then
		return false, "AlreadySubmitted"
	end
	if action.kind == "Move" then
		local ok, reason = BattleEngine.canUse(state, side, (action :: any).moveId)
		if not ok then
			return false, reason
		end
	end
	state.pending[side] = action
	return true, nil
end

-- ======================================================================
-- Atributos con modificadores
-- ======================================================================

local function modSum(c: Combatant, stat: string): number
	local total = 0
	for _, m in ipairs(c.mods) do
		if m.stat == stat then
			total += m.amount
		end
	end
	return total
end

function BattleEngine.stat(c: Combatant, stat: string): number
	return c.base[stat] * math.max(0.3, 1 + modSum(c, stat))
end

local function durationFor(target: Combatant, turns: number): number
	return if target.actedThisTurn then turns + 1 else turns
end

local function emit(state: BattleState, events: { Event }, e: Event)
	table.insert(events, e)
	table.insert(state.log, e)
end

-- ======================================================================
-- Efectos
-- ======================================================================

local function hasStatus(c: Combatant, list: { string }): boolean
	for _, s in ipairs(list) do
		if (c.statuses[s] or 0) > 0 then
			return true
		end
	end
	return false
end

local function applyStatus(state: BattleState, events: { Event }, target: Combatant, status: string, turns: number)
	if target.fainted then
		return
	end
	if status == "Sleep" and target.rarity == "Misterio" then
		emit(state, events, { t = "Immune", target = target.uid, status = status })
		return
	end
	local d = if INCAPACITATING[status] or status == "Confuse" then turns else durationFor(target, turns)
	target.statuses[status] = math.max(target.statuses[status] or 0, d)
	emit(state, events, { t = "Status", target = target.uid, status = status, turns = target.statuses[status] })
end

local function applyMod(
	state: BattleState,
	events: { Event },
	target: Combatant,
	stat: string,
	amount: number,
	turns: number
)
	if target.fainted then
		return
	end
	table.insert(target.mods, { stat = stat, amount = amount, turns = durationFor(target, turns) })
	emit(state, events, { t = "Mod", target = target.uid, stat = stat, amount = amount, turns = turns })
end

local function heal(state: BattleState, events: { Event }, target: Combatant, percent: number)
	if target.fainted then
		return
	end
	local t = talentOf(target)
	local bonus = if t and t.kind == "HealingBonus" then (t.percent or 0) else 0
	local amount = math.floor(target.maxHp * percent * (1 + bonus) + 0.5)
	local before = target.hp
	target.hp = math.min(target.maxHp, target.hp + amount)
	emit(state, events, { t = "Heal", target = target.uid, amount = target.hp - before, hp = target.hp })
end

local function cleanse(state: BattleState, events: { Event }, target: Combatant, onlyOne: boolean)
	local removed = {}
	for _, s in ipairs(NEGATIVE_STATUSES) do
		if (target.statuses[s] or 0) > 0 then
			target.statuses[s] = nil
			table.insert(removed, s)
			if onlyOne then
				break
			end
		end
	end
	if not onlyOne then
		local kept = {}
		for _, m in ipairs(target.mods) do
			if m.amount > 0 then
				table.insert(kept, m)
			end
		end
		target.mods = kept
	end
	emit(state, events, { t = "Cleanse", target = target.uid, removed = removed })
end

local function faintIfNeeded(state: BattleState, events: { Event }, c: Combatant)
	if not c.fainted and c.hp <= 0 then
		c.hp = 0
		c.fainted = true
		emit(state, events, { t = "Faint", target = c.uid })
	end
end

-- Aplica daño respetando bloqueo y escudo. Devuelve el daño a la vida.
local function dealDamage(
	state: BattleState,
	events: { Event },
	target: Combatant,
	amount: number,
	ignoreShields: boolean,
	info: { [string]: any }
): (number, boolean)
	if target.block > 0 then
		target.block = 0
		emit(state, events, { t = "Block", target = target.uid })
		return 0, true
	end
	local remaining = amount
	if target.shield and not ignoreShields then
		local absorbed = math.min(target.shield.amount, remaining)
		target.shield.amount -= absorbed
		remaining -= absorbed
		if absorbed > 0 then
			emit(state, events, { t = "ShieldAbsorb", target = target.uid, amount = absorbed })
		end
		if target.shield.amount <= 0 then
			target.shield = nil
		end
	end
	target.hp -= remaining
	target.damagedThisTurn = true
	local e =
		{ t = "Damage", target = target.uid, amount = remaining, hp = math.max(0, target.hp), maxHp = target.maxHp }
	for k, v in pairs(info) do
		e[k] = v
	end
	emit(state, events, e)
	faintIfNeeded(state, events, target)
	return remaining, false
end

-- ======================================================================
-- Fórmula de daño (p. 40) + D-002
-- ======================================================================

export type DamageRoll = { amount: number, effectiveness: string, crit: boolean, multiplier: number }

function BattleEngine.computeDamage(
	state: BattleState,
	attacker: Combatant,
	target: Combatant,
	move: MoveDef,
	power: number
): DamageRoll
	local isBasic = move.kind == "Basic"
	local atkStat = move.useStat or (if isBasic then "ATQ" else "ESE")
	local A = BattleEngine.stat(attacker, atkStat)
	local D: number
	if isBasic then
		D = BattleEngine.stat(target, "DEF")
	else
		D = (BattleEngine.stat(target, "DEF") + BattleEngine.stat(target, "ESE")) / 2
	end
	local tt = talentOf(target)
	if tt and tt.kind == "DefenseVsElements" and move.element then
		for _, e in ipairs(tt.elements or {}) do
			if e == move.element then
				D *= 1 + (tt.percent or 0)
			end
		end
	end
	local dmg = power * (A / (A + D)) * Combat.DamageRatioMultiplier
	if Combat.ScaleDamageByAttackerLevel then
		dmg *= attacker.scale
	end
	local elem = ElementChart.multiplier(move.element, target.elements, move.kind == "Nexo")
	dmg *= elem
	if move.element and table.find(attacker.elements, move.element) then
		dmg *= Combat.Element.Affinity
	end
	dmg *= state.rng:range(Combat.VarianceMin, Combat.VarianceMax)
	local crit = state.rng:chance(Combat.CritChance + (move.critBonus or 0))
	if crit then
		dmg *= Combat.CritMultiplier
	end
	-- Bonos condicionales de la propia jugada
	for _, eff in ipairs(move.effects) do
		if eff.type == "BonusIfTargetStatus" and eff.statuses and hasStatus(target, eff.statuses) then
			dmg *= 1 + (eff.amount or 0)
		elseif eff.type == "BonusIfHitLastTurn" and attacker.wasHitLastTurn then
			dmg *= 1 + (eff.amount or 0)
		end
	end
	if attacker.empowerNext > 0 then
		dmg *= 1 + attacker.empowerNext
	end
	if isBasic and tt and tt.kind == "ReduceBasicDamageTaken" then
		dmg *= 1 - (tt.percent or 0)
	end
	return {
		amount = math.max(1, math.floor(dmg + 0.5)),
		effectiveness = ElementChart.classify(elem),
		crit = crit,
		multiplier = elem,
	}
end

-- ======================================================================
-- Ejecución de una jugada
-- ======================================================================

local function accuracyFor(attacker: Combatant, target: Combatant): number
	local acc = Combat.BaseAccuracy * (1 + modSum(attacker, "Precision"))
	local evasion = math.clamp(modSum(target, "Evasion"), 0, Combat.MaxEvasion)
	return math.clamp(acc - evasion, Combat.MinAccuracy, 1)
end

local function executeMove(state: BattleState, events: { Event }, actor: Combatant, target: Combatant, move: MoveDef)
	local cost = BattleEngine.moveCost(move)
	if move.kind == "Basic" then
		actor.savia = math.min(Combat.Savia.Max, actor.savia + Combat.Savia.BasicGain)
	else
		actor.savia -= cost
		if move.kind == "Nexo" then
			actor.nexoUsed += 1
		end
	end
	emit(state, events, { t = "Move", actor = actor.uid, move = move.id, savia = actor.savia })

	if (move.kind == "Special" or move.kind == "Signature") and actor.nextSpecialFails then
		actor.nextSpecialFails = false
		emit(state, events, { t = "Fail", actor = actor.uid, reason = "Sabotage" })
		return
	end

	local ignoreShields = false
	for _, eff in ipairs(move.effects) do
		if eff.type == "IgnoreShields" then
			ignoreShields = true
		end
	end

	local totalDamage = 0
	local landed = true
	local contactHit = false -- al menos un impacto no bloqueado (para espinas/contacto)
	local thorns = if target.shield and target.shield.thornsStatus
		then { status = target.shield.thornsStatus, chance = target.shield.thornsChance or 1 }
		else nil
	if move.power > 0 then
		local acc = accuracyFor(actor, target)
		if acc < 1 and not state.rng:chance(acc) then
			emit(state, events, { t = "Miss", actor = actor.uid, target = target.uid })
			landed = false
		elseif target.dodge > 0 then
			target.dodge = 0
			emit(state, events, { t = "Dodge", target = target.uid })
			landed = false
		else
			local hits = move.hits or 1
			for _ = 1, hits do
				if target.fainted then
					break
				end
				local roll = BattleEngine.computeDamage(state, actor, target, move, move.power)
				local dealt, blocked = dealDamage(state, events, target, roll.amount, ignoreShields, {
					source = actor.uid,
					move = move.id,
					eff = roll.effectiveness,
					crit = roll.crit,
				})
				totalDamage += dealt
				if not blocked then
					contactHit = true
				end
				-- Reflejo del defensor
				if target.reflect and dealt > 0 then
					local f = target.reflect.filter
					if f == "All" or (f == "Special" and move.kind ~= "Basic") then
						local back = math.max(1, math.floor(dealt * target.reflect.percent + 0.5))
						actor.hp -= back
						emit(
							state,
							events,
							{ t = "Reflect", target = actor.uid, amount = back, hp = math.max(0, actor.hp) }
						)
						faintIfNeeded(state, events, actor)
					end
				end
			end
			actor.empowerNext = 0
		end
	end

	if not landed then
		return
	end

	-- Efectos de la jugada (en orden de lista)
	for _, eff in ipairs(move.effects) do
		local kind = eff.type
		local to = if eff.target == "Target" then target else actor
		if Abilities.IgnoredIn1v1[kind] then
			continue
		elseif kind == "Status" then
			local chance = eff.chance or 1
			if move.kind == "Basic" and eff.status == "Paralysis" then
				local t = talentOf(actor)
				if t and t.kind == "BasicStatusChanceBonus" then
					chance += t.chance or 0
				end
			end
			if not to.fainted and state.rng:chance(chance) then
				applyStatus(state, events, to, eff.status :: string, eff.turns or 1)
			end
		elseif kind == "StatMod" then
			if not to.fainted and state.rng:chance(eff.chance or 1) then
				applyMod(state, events, to, eff.stat :: string, eff.amount or 0, eff.turns or 1)
			end
		elseif kind == "Heal" then
			heal(state, events, actor, eff.percent or 0)
		elseif kind == "HealOverTime" then
			actor.hot = { percent = eff.percent or 0, turns = durationFor(actor, eff.turns or 1) }
			emit(state, events, { t = "Regen", target = actor.uid, turns = eff.turns })
		elseif kind == "Shield" then
			local amount = math.floor(actor.maxHp * (eff.percent or 0) + 0.5)
			actor.shield = {
				amount = amount,
				turns = durationFor(actor, eff.turns or 1),
				thornsStatus = eff.thornsStatus,
				thornsChance = eff.thornsChance,
			}
			emit(state, events, { t = "Shield", target = actor.uid, amount = amount })
		elseif kind == "ShieldFromDamage" then
			if totalDamage > 0 then
				local amount = math.floor(totalDamage * (eff.percent or 0) + 0.5)
				actor.shield = { amount = amount, turns = durationFor(actor, eff.turns or 2) }
				emit(state, events, { t = "Shield", target = actor.uid, amount = amount })
			end
		elseif kind == "Block" then
			actor.block = durationFor(actor, 1)
			emit(state, events, { t = "Guard", target = actor.uid, kind = "Block" })
		elseif kind == "Dodge" then
			actor.dodge = durationFor(actor, 1)
			emit(state, events, { t = "Guard", target = actor.uid, kind = "Dodge" })
		elseif kind == "Reflect" then
			actor.reflect =
				{ percent = eff.percent or 0, turns = durationFor(actor, eff.turns or 1), filter = eff.filter or "All" }
			emit(state, events, { t = "Guard", target = actor.uid, kind = "Reflect" })
		elseif kind == "Drain" then
			if totalDamage > 0 and not actor.fainted then
				local amount = math.max(1, math.floor(totalDamage * (eff.percent or 0) + 0.5))
				actor.hp = math.min(actor.maxHp, actor.hp + amount)
				emit(state, events, { t = "Heal", target = actor.uid, amount = amount, hp = actor.hp })
			end
		elseif kind == "StealSavia" then
			if not target.fainted and target.savia > 0 and state.rng:chance(eff.chance or 1) then
				local n = math.min(target.savia, eff.amount or 1)
				target.savia -= n
				emit(state, events, { t = "Savia", target = target.uid, savia = target.savia, delta = -n })
			end
		elseif kind == "Cleanse" then
			cleanse(state, events, actor, false)
		elseif kind == "CleanseOne" then
			cleanse(state, events, actor, true)
		elseif kind == "SelfRecoil" then
			local amount = math.floor(actor.maxHp * (eff.percent or 0) + 0.5)
			actor.hp = math.max(1, actor.hp - amount)
			emit(state, events, { t = "Recoil", target = actor.uid, amount = amount, hp = actor.hp })
		elseif kind == "NullifyBuffs" then
			local kept = {}
			for _, m in ipairs(target.mods) do
				if m.amount < 0 then
					table.insert(kept, m)
				end
			end
			target.mods = kept
			emit(state, events, { t = "Nullify", target = target.uid })
		elseif kind == "EmpowerNext" then
			actor.empowerNext = eff.amount or 0
			emit(state, events, { t = "Empower", target = actor.uid, amount = actor.empowerNext })
		elseif kind == "NextSpecialFails" then
			if state.rng:chance(eff.chance or 1) then
				target.nextSpecialFails = true
				emit(state, events, { t = "Sabotage", target = target.uid })
			end
		elseif kind == "CopyBuff" then
			for i = #target.mods, 1, -1 do
				local m = target.mods[i]
				if m.amount > 0 then
					applyMod(state, events, actor, m.stat, m.amount, 2)
					break
				end
			end
		end
	end

	-- Reacciones al golpe (escudo con espinas y talento Comal Tibio)
	if contactHit then
		if thorns and not actor.fainted then
			if state.rng:chance(thorns.chance) then
				applyStatus(state, events, actor, thorns.status, Combat.Status.Burn.defaultTurns)
			end
		end
		local tt = talentOf(target)
		if move.contact and tt and tt.kind == "ContactBurnChance" and not actor.fainted then
			if state.rng:chance(tt.chance or 0) then
				applyStatus(state, events, actor, "Burn", Combat.Status.Burn.defaultTurns)
			end
		end
	end

	-- Talento: básicos con parálisis extra cuando la jugada no la trae
	if move.kind == "Basic" and totalDamage > 0 and not target.fainted then
		local t = talentOf(actor)
		if t and t.kind == "BasicStatusChanceBonus" then
			local hasOwn = false
			for _, eff in ipairs(move.effects) do
				if eff.type == "Status" and eff.status == t.status then
					hasOwn = true
				end
			end
			if not hasOwn and state.rng:chance(t.chance or 0) then
				applyStatus(state, events, target, t.status :: string, 1)
			end
		end
	end
end

-- ======================================================================
-- Resolución del turno
-- ======================================================================

local function priorityOf(action: Action?): number
	if action and action.kind == "Move" then
		local m = Abilities.ById[(action :: any).moveId]
		return if m and m.priority then m.priority else 0
	end
	return 0
end

local function tieBreaker(action: Action?): boolean
	if action and action.kind == "Move" then
		local m = Abilities.ById[(action :: any).moveId]
		if m then
			for _, eff in ipairs(m.effects) do
				if eff.type == "TieBreakFirst" then
					return true
				end
			end
		end
	end
	return false
end

local function finish(state: BattleState, events: { Event }, winner: number?, reason: string)
	state.phase = "Ended"
	state.outcome = { winner = winner, reason = reason }
	-- Restaurar a los Opacos derrotados: "Nadie muere en NEXORA" (p. 112)
	if winner then
		local loserSide = state.sides[if winner == 1 then 2 else 1]
		for _, c in ipairs(loserSide.team) do
			if c.isOpaco then
				emit(state, events, { t = "Restored", target = c.uid })
			end
		end
	end
	emit(state, events, { t = "End", winner = winner, reason = reason, turn = state.turn })
end

local function sideDefeated(side: Side): boolean
	for _, c in ipairs(side.team) do
		if not c.fainted then
			return false
		end
	end
	return true
end

local function endOfTurn(state: BattleState, events: { Event })
	for _, side in ipairs(state.sides) do
		local c = side.team[side.active]
		if not c.fainted then
			-- Quemadura
			if (c.statuses.Burn or 0) > 0 then
				local amount = math.max(1, math.floor(c.maxHp * Combat.Status.Burn.damagePercent + 0.5))
				c.hp -= amount
				emit(
					state,
					events,
					{ t = "StatusTick", target = c.uid, status = "Burn", amount = amount, hp = math.max(0, c.hp) }
				)
				faintIfNeeded(state, events, c)
			end
			-- Curación por turnos
			if not c.fainted and c.hot then
				heal(state, events, c, c.hot.percent)
			end
			-- Talento: Regeneración
			local t = talentOf(c)
			if
				not c.fainted
				and t
				and t.kind == "EndTurnHealIfUndamaged"
				and not c.damagedThisTurn
				and c.hp < c.maxHp
			then
				heal(state, events, c, t.percent or 0)
			end
		end
		-- Duraciones
		if (c.statuses.Burn or 0) > 0 then
			c.statuses.Burn -= 1
			if c.statuses.Burn <= 0 then
				c.statuses.Burn = nil
			end
		end
		local kept = {}
		for _, m in ipairs(c.mods) do
			m.turns -= 1
			if m.turns > 0 then
				table.insert(kept, m)
			end
		end
		c.mods = kept
		if c.shield then
			c.shield.turns -= 1
			if c.shield.turns <= 0 then
				c.shield = nil
			end
		end
		if c.reflect then
			c.reflect.turns -= 1
			if c.reflect.turns <= 0 then
				c.reflect = nil
			end
		end
		if c.hot then
			c.hot.turns -= 1
			if c.hot.turns <= 0 then
				c.hot = nil
			end
		end
		if c.block > 0 then
			c.block -= 1
		end
		if c.dodge > 0 then
			c.dodge -= 1
		end
		c.wasHitLastTurn = c.damagedThisTurn
	end
end

function BattleEngine.resolveTurn(state: BattleState): { Event }
	assert(state.phase == "Choosing", "El combate ya terminó")
	assert(state.pending[1] and state.pending[2], "Faltan acciones por elegir")
	local events: { Event } = {}
	state.turn += 1
	emit(state, events, { t = "Turn", n = state.turn })

	-- Rendirse termina el combate sin recompensas para quien se retira
	for i = 1, 2 do
		local a = state.pending[i]
		if a and a.kind == "Forfeit" then
			state.pending = {}
			finish(state, events, if i == 1 then 2 else 1, "Forfeit")
			return events
		end
	end

	local actors = {}
	for i = 1, 2 do
		local c = BattleEngine.active(state, i)
		c.damagedThisTurn = false
		c.actedThisTurn = false
		table.insert(actors, { side = i, c = c, action = state.pending[i] })
	end

	-- Orden: prioridad, luego VEL efectiva, luego desempate (Ráfaga o azar)
	local a, b = actors[1], actors[2]
	local pa, pb = priorityOf(a.action), priorityOf(b.action)
	local first
	if pa ~= pb then
		first = if pa > pb then 1 else 2
	else
		local va, vb = BattleEngine.stat(a.c, "VEL"), BattleEngine.stat(b.c, "VEL")
		if math.abs(va - vb) > 1e-9 then
			first = if va > vb then 1 else 2
		else
			local ta, tb = tieBreaker(a.action), tieBreaker(b.action)
			if ta ~= tb then
				first = if ta then 1 else 2
			else
				first = if state.rng:chance(0.5) then 1 else 2
			end
		end
	end
	local order = if first == 1 then { a, b } else { b, a }

	for _, entry in ipairs(order) do
		local actor: Combatant = entry.c
		if actor.fainted or state.phase == "Ended" then
			continue
		end
		local target = opponentOf(state, entry.side)
		-- Se marca antes de actuar: los efectos que el propio actor se aplica cuentan
		-- este turno como ya jugado y duran sus turnos completos.
		actor.actedThisTurn = true
		local skipped = false
		for _, status in ipairs(INCAPACITATING_ORDER) do
			if (actor.statuses[status] or 0) > 0 then
				actor.statuses[status] -= 1
				if actor.statuses[status] <= 0 then
					actor.statuses[status] = nil
				end
				emit(state, events, { t = "Skip", actor = actor.uid, status = status })
				skipped = true
				break
			end
		end
		if not skipped and (actor.statuses.Confuse or 0) > 0 then
			actor.statuses.Confuse -= 1
			if actor.statuses.Confuse <= 0 then
				actor.statuses.Confuse = nil
			end
			if state.rng:chance(Combat.Status.Confuse.selfHitChance) then
				local selfMove = {
					id = "ConfusionSelfHit",
					name = "Confusión",
					kind = "Basic",
					power = Combat.Status.Confuse.selfHitPower,
					effects = {},
					text = "",
				} :: any
				local roll = BattleEngine.computeDamage(state, actor, actor, selfMove, selfMove.power)
				emit(state, events, { t = "Confused", actor = actor.uid })
				dealDamage(
					state,
					events,
					actor,
					roll.amount,
					true,
					{ source = actor.uid, move = "ConfusionSelfHit", eff = "Neutral", crit = false }
				)
				skipped = true
			end
		end
		if not skipped then
			local action = entry.action :: any
			local move = Abilities.ById[action.moveId]
			executeMove(state, events, actor, target, move)
		end
		for i = 1, 2 do
			if sideDefeated(state.sides[i]) then
				finish(state, events, if i == 1 then 2 else 1, "Defeat")
				break
			end
		end
	end

	if state.phase ~= "Ended" then
		endOfTurn(state, events)
		for i = 1, 2 do
			if state.phase ~= "Ended" and sideDefeated(state.sides[i]) then
				finish(state, events, if i == 1 then 2 else 1, "Defeat")
			end
		end
	end

	if state.phase ~= "Ended" and state.turn >= state.maxTurns then
		local c1, c2 = BattleEngine.active(state, 1), BattleEngine.active(state, 2)
		local r1, r2 = c1.hp / c1.maxHp, c2.hp / c2.maxHp
		finish(state, events, if r1 > r2 then 1 else 2, "TurnLimit")
	end

	state.pending = {}
	return events
end

-- Instantánea serializable para el cliente (sin Rng ni datos internos).
function BattleEngine.snapshot(state: BattleState): { [string]: any }
	local sides = {}
	for _, side in ipairs(state.sides) do
		local team = {}
		for _, c in ipairs(side.team) do
			local mods = {}
			for _, m in ipairs(c.mods) do
				table.insert(mods, { stat = m.stat, amount = m.amount, turns = m.turns })
			end
			table.insert(team, {
				uid = c.uid,
				petId = c.petId,
				speciesId = c.speciesId,
				form = c.form,
				level = c.level,
				name = c.name,
				isOpaco = c.isOpaco,
				elements = c.elements,
				hp = c.hp,
				maxHp = c.maxHp,
				savia = c.savia,
				statuses = table.clone(c.statuses),
				mods = mods,
				shield = if c.shield then c.shield.amount else 0,
				fainted = c.fainted,
				moves = c.moves,
			})
		end
		table.insert(sides, { index = side.index, controller = side.controller, active = side.active, team = team })
	end
	return {
		battleId = state.battleId,
		turn = state.turn,
		phase = state.phase,
		sides = sides,
		outcome = state.outcome,
	}
end

return BattleEngine
