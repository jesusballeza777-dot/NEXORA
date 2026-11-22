--!strict
-- Seres Sagrados del Nexo (Biblia compacta p. 12–13 y 113): jefes opacados del modo
-- aventura. No son especies del catálogo de 50: rareza Única (presupuesto 128, coste 6),
-- una copia por cuenta, no se crían. Al restaurarlos entran al Cofre Nexo.
--
-- Lo que dice la Biblia de Copalia: garza colosal con patas de raíces y alas de hojas y
-- faroles; Flora (+ Luz, lectura de columnas superpuestas en p. 12: confirmar con la v5);
-- talento Raíz Madre (cura 6 % al equipo al final de cada turno); Golpe Nexo Bosque de
-- Faroles (120, cura 40 % al equipo); fase 1 cura a sus aliados con raíces, fase 2 apaga
-- la luz con faroles (−20 % de precisión); al restaurarla los hábitats del Valle
-- producen +10 % de XP. Opacada: las raíces se secan, los faroles se apagan.
-- PROPUESTA (D-027): reparto de atributos dentro del presupuesto 128, umbral de fase al
-- 50 % de VID, multiplicador de VID por enfrentar a un equipo de 3 y su lista de ataques.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type PhaseEffect =
	{ type: "EndRoots" }
	| { type: "SideAccuracy", amount: number }
	| { type: "GainSavia", amount: number }
	| { type: "Cleanse" }

export type PhaseDef = { id: string, threshold: number, text: string, effects: { PhaseEffect } }

export type GuardianDef = {
	id: string,
	name: string,
	shortName: string,
	epithet: string,
	act: string,
	biome: string,
	elements: { string },
	rarity: string,
	cost: number,
	stats: { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number },
	statsStatus: string,
	hpMultiplier: number,
	level: number, -- nivel de combate (el acto recomienda el 15)
	talentName: string,
	talentText: string,
	rootHeal: number,
	moves: { string },
	nexoName: string,
	phases: { PhaseDef },
	description: string,
	opacado: string,
	restoreBonus: string,
	restoreBonusData: { kind: string, biome: string, percent: number },
}

local Guardians: { [string]: GuardianDef } = {
	copalia = {
		id = "copalia",
		name = "Copalia, la Garza de Raíces",
		shortName = "Copalia",
		epithet = "Guardiana del Valle Copal",
		act = "ActoI",
		biome = "ValleCopal",
		elements = { "Flora", "Luz" },
		rarity = "Unico",
		cost = 6,
		-- Suma 128 (presupuesto Único). Reparto: PROPUESTA hasta tener la ficha de la v5.
		stats = { VID = 30, ATQ = 24, DEF = 26, ESE = 28, VEL = 20 },
		statsStatus = "Propuesta",
		-- PROPUESTA simulada (tools/sim/boss): a nivel 10 con VID ×0,9, el nivel recomendado
		-- del acto (15) gana ~56 % con una política ingenua y ~96 % con 3 Tallados.
		hpMultiplier = 0.9,
		level = 10,
		talentName = "Raíz Madre",
		talentText = "Cura 6 % al equipo al final de cada turno mientras sus raíces sigan vivas.",
		rootHeal = 0.06,
		moves = { "LatigoDeEnredadera", "Destello", "EspinasDeMaguey", "LanzaSolar", "BosqueDeFaroles" },
		nexoName = "Bosque de Faroles",
		phases = {
			{
				id = "FarolesApagados",
				threshold = 0.5,
				text = "Copalia arranca sus raíces y apaga los faroles: tu equipo pierde 20 % de precisión.",
				effects = {
					{ type = "EndRoots" },
					{ type = "SideAccuracy", amount = -0.2 },
					{ type = "GainSavia", amount = 3 },
				},
			},
		},
		description = "Garza colosal cuyas patas son raíces y cuyas alas están tejidas de hojas y faroles.",
		opacado = "Las raíces se secan, los faroles se apagan y el valle pierde el color.",
		restoreBonus = "Los hábitats del Valle producen +10 % de XP.",
		restoreBonusData = { kind = "HabitatXp", biome = "ValleCopal", percent = 0.10 },
	},
}

return Freeze.deep({ ById = Guardians, Order = { "copalia" } })
