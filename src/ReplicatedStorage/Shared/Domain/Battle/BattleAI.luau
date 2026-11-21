--!strict
-- IA de los Opacos. Determinista con el Rng del combate.
--   Tutorial: solo básicos; 70 % el de mayor daño esperado, 30 % uno al azar.
--   Normal: Golpe Nexo si puede; cura si está bajo; especiales/firma con Savia;
--           si no, el mejor básico (25 % de variedad).

local Shared = script.Parent.Parent.Parent
local Abilities = require(Shared.Config.Abilities)
local Combat = require(Shared.Config.Combat)
local ElementChart = require(Shared.Domain.ElementChart)
local BattleEngine = require(script.Parent.BattleEngine)

type BattleState = BattleEngine.BattleState

local BattleAI = {}

local function expectedDamage(state: BattleState, side: number, moveId: string): number
	local me = BattleEngine.active(state, side)
	local foe = BattleEngine.active(state, if side == 1 then 2 else 1)
	local m = Abilities.ById[moveId]
	if not m or m.power <= 0 then
		return 0
	end
	local isBasic = m.kind == "Basic"
	local A = BattleEngine.stat(me, m.useStat or (if isBasic then "ATQ" else "ESE"))
	local D = if isBasic
		then BattleEngine.stat(foe, "DEF")
		else (BattleEngine.stat(foe, "DEF") + BattleEngine.stat(foe, "ESE")) / 2
	local elem = ElementChart.multiplier(m.element, foe.elements, m.kind == "Nexo")
	local aff = if m.element and table.find(me.elements, m.element) then Combat.Element.Affinity else 1
	return m.power * (m.hits or 1) * A / (A + D) * elem * aff
end

local function isHeal(moveId: string): boolean
	local m = Abilities.ById[moveId]
	for _, eff in ipairs(m.effects) do
		if eff.type == "Heal" or eff.type == "HealOverTime" then
			return true
		end
	end
	return false
end

local function pickBest(state: BattleState, side: number, ids: { string }): string?
	local best, bestScore = nil, -1
	for _, id in ipairs(ids) do
		local score = expectedDamage(state, side, id)
		if score > bestScore then
			best, bestScore = id, score
		end
	end
	return best
end

function BattleAI.choose(state: BattleState, side: number, profile: string?): string
	local options = BattleEngine.availableMoves(state, side)
	local basics, specials, nexo = {}, {}, nil
	for _, opt in ipairs(options) do
		if opt.usable then
			if opt.kind == "Basic" then
				table.insert(basics, opt.moveId)
			elseif opt.kind == "Nexo" then
				nexo = opt.moveId
			else
				table.insert(specials, opt.moveId)
			end
		end
	end
	assert(#basics > 0, "Un monstruo siempre tiene al menos un básico disponible")
	local rng = state.rng

	if profile == "Tutorial" then
		if rng:chance(0.7) then
			return pickBest(state, side, basics) :: string
		end
		return basics[rng:int(1, #basics)]
	end

	if nexo then
		return nexo
	end
	local me = BattleEngine.active(state, side)
	if #specials > 0 then
		if me.hp / me.maxHp < 0.4 then
			for _, id in ipairs(specials) do
				if isHeal(id) then
					return id
				end
			end
		end
		if rng:chance(0.6) then
			local damaging = {}
			for _, id in ipairs(specials) do
				if Abilities.ById[id].power > 0 then
					table.insert(damaging, id)
				end
			end
			if #damaging > 0 then
				return pickBest(state, side, damaging) :: string
			end
			return specials[rng:int(1, #specials)]
		end
	end
	if rng:chance(0.25) then
		return basics[rng:int(1, #basics)]
	end
	return pickBest(state, side, basics) :: string
end

return BattleAI
