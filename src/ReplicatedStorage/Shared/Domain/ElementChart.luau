--!strict
-- Rueda de ventajas: multiplicador elemental de un ataque contra un defensor.
-- Multiplica por cada elemento del defensor y aplica tope/suelo (Config/Combat).

local Config = script.Parent.Parent.Config
local Elements = require(Config.Elements)
local Combat = require(Config.Combat)

local ElementChart = {}

export type Effectiveness = "Strong" | "Weak" | "Neutral"

-- Multiplicador de un elemento atacante contra UN elemento defensor.
function ElementChart.single(attack: string, defend: string): number
	local a = Elements.ById[attack]
	if not a then
		return Combat.Element.Neutral
	end
	for _, e in ipairs(a.strongAgainst) do
		if e == defend then
			return Combat.Element.Strong
		end
	end
	for _, e in ipairs(a.weakAgainst) do
		if e == defend then
			return Combat.Element.Weak
		end
	end
	return Combat.Element.Neutral
end

-- Multiplicador total contra un defensor de 0–3 elementos.
-- isNexo: el Golpe Nexo nunca baja de NexoFloor (p. 34).
function ElementChart.multiplier(attack: string?, defenderElements: { string }, isNexo: boolean?): number
	if attack == nil or #defenderElements == 0 then
		return Combat.Element.Neutral
	end
	local m = 1
	for _, d in ipairs(defenderElements) do
		m *= ElementChart.single(attack :: string, d)
	end
	local floor = if isNexo then math.max(Combat.Element.Floor, Combat.Element.NexoFloor) else Combat.Element.Floor
	return math.clamp(m, floor, Combat.Element.Cap)
end

function ElementChart.classify(mult: number): Effectiveness
	if mult > 1.0001 then
		return "Strong"
	elseif mult < 0.9999 then
		return "Weak"
	end
	return "Neutral"
end

-- Debilidades y resistencias netas de una combinación de elementos (para la ficha).
function ElementChart.defensiveProfile(defenderElements: { string }): { weakTo: { string }, resists: { string } }
	local weakTo, resists = {}, {}
	for _, atk in ipairs(Elements.Order) do
		local m = ElementChart.multiplier(atk, defenderElements, false)
		if m > 1.0001 then
			table.insert(weakTo, atk)
		elseif m < 0.9999 then
			table.insert(resists, atk)
		end
	end
	return { weakTo = weakTo, resists = resists }
end

return ElementChart
