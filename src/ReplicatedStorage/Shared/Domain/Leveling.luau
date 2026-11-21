--!strict
-- Curva de experiencia, Vínculo y requisitos del Tallado (p. 115).
-- Puro: no muta perfiles; devuelve resultados que los servicios aplican.

local Config = script.Parent.Parent.Config
local Progression = require(Config.Progression)
local SpeciesConfig = require(Config.Species)
local Rarities = require(Config.Rarities)

local Leveling = {}

-- XP para pasar del nivel L al L+1 = 40 × L^1.5 (redondeada al entero más cercano)
function Leveling.xpToNext(level: number): number
	if level >= Progression.LevelCap then
		return 0
	end
	return math.floor(Progression.XpBase * level ^ Progression.XpExponent + 0.5)
end

-- XP acumulada necesaria para alcanzar `level` desde el nivel 1
function Leveling.totalXpForLevel(level: number): number
	local total = 0
	for l = 1, math.min(level, Progression.LevelCap) - 1 do
		total += Leveling.xpToNext(l)
	end
	return total
end

export type XpResult = { level: number, xp: number, levelsGained: number, overflowDiscarded: number }

-- Aplica XP a (nivel, xp dentro del nivel). Al tope, la XP sobrante se descarta.
function Leveling.addXp(level: number, xp: number, amount: number): XpResult
	assert(amount >= 0, "La XP no puede ser negativa")
	local lvl, cur = level, xp + math.floor(amount)
	local gained = 0
	while lvl < Progression.LevelCap do
		local need = Leveling.xpToNext(lvl)
		if cur < need then
			break
		end
		cur -= need
		lvl += 1
		gained += 1
	end
	local discarded = 0
	if lvl >= Progression.LevelCap then
		discarded = cur
		cur = 0
	end
	return { level = lvl, xp = cur, levelsGained = gained, overflowDiscarded = discarded }
end

function Leveling.bondHearts(bond: number): number
	local hearts = 0
	for _, threshold in ipairs(Progression.Bond.Thresholds) do
		if bond >= threshold then
			hearts += 1
		end
	end
	return hearts
end

function Leveling.nextBondThreshold(bond: number): number?
	for _, threshold in ipairs(Progression.Bond.Thresholds) do
		if bond < threshold then
			return threshold
		end
	end
	return nil
end

function Leveling.talladoLevel(speciesId: string): number
	local species = SpeciesConfig.ById[speciesId]
	return Rarities.ById[species.rarity].talladoLevel
end

-- ¿Puede tallarse? Devuelve (ok, motivo)
function Leveling.canEvolve(pet: { speciesId: string, form: string, level: number, bond: number }): (boolean, string?)
	if pet.form ~= "Brote" then
		return false, "AlreadyTallado"
	end
	if pet.level < Leveling.talladoLevel(pet.speciesId) then
		return false, "LevelTooLow"
	end
	if Leveling.bondHearts(pet.bond) < Progression.Bond.TallarRequiredHearts then
		return false, "BondTooLow"
	end
	return true, nil
end

export type Objective = { kind: string, text: string, current: number, target: number }

-- Próximo objetivo visible en la ficha del monstruo ("¿qué sigue?").
function Leveling.nextObjective(
	pet: { speciesId: string, form: string, level: number, xp: number, bond: number }
): Objective
	local species = SpeciesConfig.ById[pet.speciesId]
	if pet.form == "Brote" then
		local need = Leveling.talladoLevel(pet.speciesId)
		if pet.level < need then
			return {
				kind = "ReachTalladoLevel",
				text = string.format("Nivel %d para tallarse en %s", need, species.talladoName),
				current = pet.level,
				target = need,
			}
		end
		local hearts = Leveling.bondHearts(pet.bond)
		if hearts < Progression.Bond.TallarRequiredHearts then
			return {
				kind = "BondForTallado",
				text = string.format("%d corazones de Vínculo para tallarse", Progression.Bond.TallarRequiredHearts),
				current = hearts,
				target = Progression.Bond.TallarRequiredHearts,
			}
		end
		return { kind = "ReadyToEvolve", text = "¡Listo para tallarse!", current = 1, target = 1 }
	end
	if pet.level < Progression.NexoUnlockLevel then
		return {
			kind = "ReachNexoLevel",
			text = string.format("Nivel %d: Golpe Nexo", Progression.NexoUnlockLevel),
			current = pet.level,
			target = Progression.NexoUnlockLevel,
		}
	end
	return { kind = "Mastery", text = "Entrena hasta el nivel 50", current = pet.level, target = Progression.LevelCap }
end

return Leveling
