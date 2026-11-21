--!strict
-- Encuentros PvE del vertical slice: Acto I · Valle Copal · Región 1 ("Linde de las
-- Chinampas"). Estructura de etapas y reglas de repetición de la Biblia (p. 111–114).
-- El primer Opaco depende del inicial elegido (p. 48: Kuachi→Opaco de Flora,
-- Xolumi→Opaco de Fuego, Teselo→Opaco de Rayo). La especie concreta es PROVISIONAL (B-004).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type EncounterDef = {
	id: string,
	name: string,
	act: string,
	region: number,
	stage: number,
	stageType: "Combate" | "Elite" | "Tesoro" | "Rescate" | "Jefe",
	opponent: {
		speciesId: string?,
		byStarterElement: { [string]: string }?,
		form: "Brote" | "Tallado",
		level: number,
		modifier: string?,
	},
	ai: "Tutorial" | "Normal",
	requires: string?, -- encuentro previo superado
	baseReward: { Monedas: number, petXp: number },
	firstClearBonus: string?, -- id en Config/Rewards
	lossPetXp: number,
	worldMarker: string, -- id del marcador físico en Config/World
}

local Encounters: { [string]: EncounterDef } = {
	valle_r1_e1 = {
		id = "valle_r1_e1",
		name = "El primer Opaco",
		act = "ActoI",
		region = 1,
		stage = 1,
		stageType = "Combate",
		opponent = {
			byStarterElement = { Fuego = "agavo", Agua = "comalu", Tierra = "zizi" },
			form = "Brote",
			level = 1,
		},
		ai = "Tutorial",
		baseReward = { Monedas = 200, petXp = 150 },
		firstClearBonus = "FirstOpacoRestored",
		lossPetXp = 40,
		worldMarker = "Encounter1",
	},
	valle_r1_e2 = {
		id = "valle_r1_e2",
		name = "Opaco del Canal",
		act = "ActoI",
		region = 1,
		stage = 2,
		stageType = "Combate",
		opponent = { speciesId = "barrock", form = "Brote", level = 4 },
		ai = "Normal",
		requires = "valle_r1_e1",
		baseReward = { Monedas = 350, petXp = 250 },
		firstClearBonus = "CanalCleared",
		lossPetXp = 60,
		worldMarker = "Encounter2",
	},
	valle_r1_e3 = {
		id = "valle_r1_e3",
		name = "Élite: Opaco de la Vaina",
		act = "ActoI",
		region = 1,
		stage = 3,
		stageType = "Elite",
		opponent = { speciesId = "vainas", form = "Brote", level = 7, modifier = "Coraza" },
		ai = "Normal",
		requires = "valle_r1_e2",
		baseReward = { Monedas = 600, petXp = 400 },
		firstClearBonus = "EliteVainaCleared",
		lossPetXp = 80,
		worldMarker = "Encounter3",
	},
}

-- Modificadores de élite (p. 111: niebla, coraza o furia)
local Modifiers = {
	Coraza = { name = "Coraza", statMultipliers = { DEF = 1.15 } },
	Furia = { name = "Furia", statMultipliers = { ATQ = 1.15 } },
	Niebla = { name = "Niebla", statMultipliers = { VEL = 1.10 } },
}

return Freeze.deep({
	ById = Encounters,
	Order = { "valle_r1_e1", "valle_r1_e2", "valle_r1_e3" },
	Modifiers = Modifiers,
	Repeat = {
		RewardScale = 0.25, -- p. 111
		DailyRewardedRepeats = 10,
	},
})
