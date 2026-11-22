--!strict
-- Cálculo de atributos efectivos (p. 35):
--   atributo = base_tallado × factorForma × (0.4 + 0.012 × nivel)
--   PV = VID efectiva × 10

local Config = script.Parent.Parent.Config
local Progression = require(Config.Progression)
local SpeciesConfig = require(Config.Species)

local Stats = {}

export type StatBlock = { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number }

Stats.Keys = { "VID", "ATQ", "DEF", "ESE", "VEL" }

function Stats.levelFactor(level: number): number
	return Progression.LevelScaleBase + Progression.LevelScalePerLevel * level
end

function Stats.formFactor(form: string): number
	return (Progression.FormFactor :: any)[form] or Progression.FormFactor.Brote
end

-- Escala total de una criatura (forma × nivel). A nivel 50 en Tallado vale 1.0.
function Stats.scale(form: string, level: number): number
	return Stats.formFactor(form) * Stats.levelFactor(level)
end

-- Atributos efectivos a partir de un bloque de atributos (especie o Ser Sagrado).
function Stats.effectiveFrom(
	block: StatBlock,
	form: string,
	level: number,
	multipliers: { [string]: number }?
): StatBlock
	local s = Stats.scale(form, level)
	local out = {} :: any
	for _, key in ipairs(Stats.Keys) do
		local m = if multipliers and multipliers[key] then multipliers[key] else 1
		out[key] = (block :: any)[key] * s * m
	end
	return out :: StatBlock
end

function Stats.effective(speciesId: string, form: string, level: number, multipliers: { [string]: number }?): StatBlock
	local species = SpeciesConfig.ById[speciesId]
	assert(species, "Especie desconocida: " .. tostring(speciesId))
	return Stats.effectiveFrom(species.stats :: any, form, level, multipliers)
end

function Stats.maxHp(effectiveVid: number): number
	return math.max(1, math.floor(effectiveVid * Progression.HpPerVid + 0.5))
end

-- Atributos "de ficha" (base de la forma, sin nivel): lo que se muestra como barras.
function Stats.formBase(speciesId: string, form: string): StatBlock
	local species = SpeciesConfig.ById[speciesId]
	local f = Stats.formFactor(form)
	local out = {} :: any
	for _, key in ipairs(Stats.Keys) do
		out[key] = math.floor((species.stats :: any)[key] * f + 0.5)
	end
	return out :: StatBlock
end

return Stats
