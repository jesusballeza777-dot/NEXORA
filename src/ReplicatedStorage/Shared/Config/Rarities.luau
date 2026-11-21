--!strict
-- Rarezas (Biblia v5.0 p. 25–27, 35, 43, 89, 115).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type RarityId = "Comun" | "Raro" | "Epico" | "Legendario" | "Unico" | "Misterio"

export type RarityDef = {
	id: RarityId,
	name: string,
	order: number,
	statBudget: number, -- p. 35 (DEFINIDO)
	teamCost: number, -- p. 43 (coste del Tallado; Brote = coste - 1)
	talladoLevel: number, -- p. 115 (DEFINIDO)
	incubationSeconds: number, -- p. 89 (DEFINIDO; Únicos/Misterio en pregunta 28)
	elementsAllowed: string, -- p. 34
	frameColor: { number }, -- p. 25 (liso, azul, violeta, oro, iridiscente, punteado)
	auraEmitters: number, -- p. 26 presupuesto técnico (máximo)
	catalogCount: number, -- p. 9/42: 18 · 14 · 10 · 5 · 2 · 1
	coinsPerHour: number, -- p. 92 generación en hábitat
}

local Rarities: { [string]: RarityDef } = {
	Comun = {
		id = "Comun",
		name = "Común",
		order = 1,
		statBudget = 100,
		teamCost = 2,
		talladoLevel = 12,
		incubationSeconds = 5 * 60,
		elementsAllowed = "1",
		frameColor = { 214, 200, 176 },
		auraEmitters = 0,
		catalogCount = 18,
		coinsPerHour = 30,
	},
	Raro = {
		id = "Raro",
		name = "Raro",
		order = 2,
		statBudget = 108,
		teamCost = 3,
		talladoLevel = 15,
		incubationSeconds = 20 * 60,
		elementsAllowed = "1 o 2",
		frameColor = { 72, 140, 230 },
		auraEmitters = 1,
		catalogCount = 14,
		coinsPerHour = 45,
	},
	Epico = {
		id = "Epico",
		name = "Épico",
		order = 3,
		statBudget = 116,
		teamCost = 4,
		talladoLevel = 18,
		incubationSeconds = 2 * 3600,
		elementsAllowed = "2",
		frameColor = { 156, 96, 222 },
		auraEmitters = 2,
		catalogCount = 10,
		coinsPerHour = 60,
	},
	Legendario = {
		id = "Legendario",
		name = "Legendario",
		order = 4,
		statBudget = 124,
		teamCost = 5,
		talladoLevel = 20,
		incubationSeconds = 8 * 3600,
		elementsAllowed = "2 o 3",
		frameColor = { 236, 184, 64 },
		auraEmitters = 3,
		catalogCount = 5,
		coinsPerHour = 90,
	},
	Unico = {
		id = "Unico",
		name = "Único",
		order = 5,
		statBudget = 128,
		teamCost = 6,
		talladoLevel = 22,
		incubationSeconds = 24 * 3600,
		elementsAllowed = "3",
		frameColor = { 140, 230, 220 },
		auraEmitters = 3,
		catalogCount = 2,
		coinsPerHour = 120,
	},
	Misterio = {
		id = "Misterio",
		name = "Misterio",
		order = 6,
		statBudget = 120, -- PROPUESTA v5 (pregunta 43/44)
		teamCost = 5, -- PROPUESTA v5 (pregunta 44)
		talladoLevel = 25,
		incubationSeconds = 72 * 3600,
		elementsAllowed = "Eco",
		frameColor = { 60, 60, 60 },
		auraEmitters = 3,
		catalogCount = 1,
		coinsPerHour = 120,
	},
}

local Order: { RarityId } = { "Comun", "Raro", "Epico", "Legendario", "Unico", "Misterio" }

return Freeze.deep({
	ById = Rarities,
	Order = Order,
})
