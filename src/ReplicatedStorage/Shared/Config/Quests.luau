--!strict
-- Tablón de Encargos de la Torre del Nexo (Biblia compacta p. 13: "3 encargos diarios y
-- 1 semanal; recompensas en Monedas y cofres de Madera o Plata"; Genesis F2 §10).
-- * Cada encargo diario da entre 150 y 250 Monedas según su dificultad (Genesis F2).
-- * Completar y reclamar los tres diarios da un Cofre de Madera.
-- * El semanal da Monedas y un Cofre de Plata (PROPUESTA de cifra: 1 200 Monedas).
-- * Reinicio: 00:00 UTC (hora del servidor, como la Vitrina p. 13). Semana: lunes 00:00 UTC.
-- * El progreso lo mueven eventos internos del servidor; el cliente nunca lo envía.
-- Para añadir un encargo basta con una entrada aquí (event + target): sin tocar código.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type QuestDef = {
	id: string,
	title: string,
	description: string,
	event: string, -- evento interno que suma progreso (ver QuestRules.Events)
	target: number,
	coins: number,
	difficulty: "Easy" | "Medium" | "Hard",
	requiresUnlock: string?, -- solo se sortea si el jugador ya tiene acceso a la actividad
}

local Daily: { QuestDef } = {
	{
		id = "D_Feed4",
		title = "Panza llena",
		description = "Alimenta a tus monstruos 4 veces.",
		event = "Feed",
		target = 4,
		coins = 150,
		difficulty = "Easy",
	},
	{
		id = "D_Play3",
		title = "Rato de juego",
		description = "Juega 3 veces con tus monstruos.",
		event = "Play",
		target = 3,
		coins = 150,
		difficulty = "Easy",
	},
	{
		id = "D_Collect2",
		title = "Cosecha del lote",
		description = "Recoge Monedas en tu hábitat 2 veces.",
		event = "CollectCoins",
		target = 2,
		coins = 150,
		difficulty = "Easy",
	},
	{
		id = "D_Win2",
		title = "Dos Opacos menos",
		description = "Gana 2 combates contra Opacos.",
		event = "BattleWon",
		target = 2,
		coins = 200,
		difficulty = "Medium",
	},
	{
		id = "D_Stages2",
		title = "Camino del Valle",
		description = "Supera 2 etapas del Acto I.",
		event = "StageCleared",
		target = 2,
		coins = 200,
		difficulty = "Medium",
	},
	{
		id = "D_Incubate1",
		title = "Calor de copal",
		description = "Pon un huevo en la incubadora.",
		event = "IncubationStarted",
		target = 1,
		coins = 200,
		difficulty = "Medium",
		requiresUnlock = "HasEgg",
	},
	{
		id = "D_Xp1500",
		title = "Entrenamiento",
		description = "Consigue 1 500 de XP para tus monstruos.",
		event = "PetXp",
		target = 1500,
		coins = 250,
		difficulty = "Hard",
	},
	{
		id = "D_Stars3",
		title = "Constelación",
		description = "Gana 3 estrellas en etapas del Acto I.",
		event = "StarEarned",
		target = 3,
		coins = 250,
		difficulty = "Hard",
	},
	{
		id = "D_Chest1",
		title = "Cofre abierto",
		description = "Abre un cofre en la Repisa de Cofres.",
		event = "ChestOpened",
		target = 1,
		coins = 250,
		difficulty = "Hard",
		requiresUnlock = "HasChest",
	},
}

local Weekly: { QuestDef } = {
	{
		id = "W_Restore12",
		title = "Devolver el color",
		description = "Restaura 12 Opacos esta semana.",
		event = "OpacoRestored",
		target = 12,
		coins = 1200,
		difficulty = "Hard",
	},
	{
		id = "W_Hatch3",
		title = "Nidada de la semana",
		description = "Haz eclosionar 3 huevos esta semana.",
		event = "EggHatched",
		target = 3,
		coins = 1200,
		difficulty = "Hard",
		requiresUnlock = "HasEgg",
	},
	{
		id = "W_Discover2",
		title = "Nuevas páginas",
		description = "Descubre 2 especies nuevas para el Álbum.",
		event = "SpeciesDiscovered",
		target = 2,
		coins = 1200,
		difficulty = "Hard",
	},
}

return Freeze.deep({
	Daily = Daily,
	Weekly = Weekly,
	DailyCount = 3,
	-- Un encargo de cada dificultad: fácil, medio y difícil (variedad garantizada)
	DailyMix = { "Easy", "Medium", "Hard" },
	DailyBonusChest = "Madera",
	WeeklyChest = "Plata",
	ResetHourUtc = 0,
	-- 1970-01-01 fue jueves: desplazar 3 días hace que la semana empiece el lunes
	WeekOffsetDays = 3,
})
