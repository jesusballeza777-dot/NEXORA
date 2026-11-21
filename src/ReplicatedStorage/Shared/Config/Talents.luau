--!strict
-- Talentos de las especies de la Fase 1 (fichas p. 49–60). El resto de talentos
-- existe en la Biblia y se incorporará con sus especies.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type TalentDef = {
	id: string,
	name: string,
	kind: string,
	amount: number?,
	percent: number?,
	chance: number?,
	elements: { string }?,
	status: string?,
	text: string,
}

local Talents: { [string]: TalentDef } = {
	BolsaDeBrasas = {
		id = "BolsaDeBrasas",
		name = "Bolsa de Brasas",
		kind = "BattleStartSavia",
		amount = 1,
		text = "Al entrar en combate guarda 1 de Savia extra (máx. 1 por combate).",
	},
	Regeneracion = {
		id = "Regeneracion",
		name = "Regeneración",
		kind = "EndTurnHealIfUndamaged",
		percent = 0.06,
		text = "Recupera 6 % de VID al final de cada turno en el que no recibió daño.",
	},
	CaparazonDeGrecas = {
		id = "CaparazonDeGrecas",
		name = "Caparazón de Grecas",
		kind = "ReduceBasicDamageTaken",
		percent = 0.20,
		text = "Recibe −20 % de daño de los ataques básicos.",
	},
	ComalTibio = {
		id = "ComalTibio",
		name = "Comal Tibio",
		kind = "ContactBurnChance",
		chance = 0.15,
		text = "Los rivales que lo golpean con contacto tienen 15 % de quemarse.",
	},
	BarroFresco = {
		id = "BarroFresco",
		name = "Barro Fresco",
		kind = "HealingBonus",
		percent = 0.15,
		text = "Sus curaciones curan 15 % más.",
	},
	PencaGruesa = {
		id = "PencaGruesa",
		name = "Penca Gruesa",
		kind = "DefenseVsElements",
		percent = 0.15,
		elements = { "Agua", "Rayo" },
		text = "+15 % DEF contra Agua y Rayo.",
	},
	Siembra = {
		id = "Siembra",
		name = "Siembra",
		kind = "SeedOnSpecial", -- requiere cambios de monstruo: sin efecto en 1v1
		percent = 0.08,
		text = "Cada vez que usa un especial deja una semilla: el siguiente aliado que entra cura 8 %.",
	},
	CantoEstatico = {
		id = "CantoEstatico",
		name = "Canto Estático",
		kind = "BasicStatusChanceBonus",
		status = "Paralysis",
		chance = 0.10,
		text = "Sus ataques básicos tienen +10 % de parálisis.",
	},
}

return Freeze.deep({ ById = Talents })
