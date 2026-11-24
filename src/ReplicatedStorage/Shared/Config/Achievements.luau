--!strict
-- Logros (Biblia compacta p. 91: «Gemas: … logros»; Genesis F2 §8.1 y §9.2: huevos y
-- cofres también se obtienen por logros; §19: el perfil guarda los logros).
-- La Biblia no trae la lista: todo este archivo es PROPUESTA (D-033).
-- * Premios fijos y visibles antes de conseguirlos: sin azar ni porcentajes.
-- * 10 Gemas por logro, como el regalo del primer combate (D-012). En la beta
--   las Gemas no compran aceleraciones ni cofres.
-- * Cada métrica se calcula en el servidor a partir del perfil; el cliente no informa
--   de progreso. Las metas caben en el contenido del Acto I (lo comprueba Phase2Config).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type Metric =
	"SpeciesDiscovered" -- especies vistas, restauradas u obtenidas (Bestiario ≥ 1)
	| "SpeciesRestored" -- especies de Opacos restauradas
	| "EggsHatched" -- huevos eclosionados en la incubadora (el inicial no cuenta)
	| "Tallados" -- especies con la carta Tallado
	| "Stars" -- estrellas del Acto I
	| "Guardians" -- Seres Sagrados restaurados

export type AchievementDef = {
	id: string,
	name: string,
	description: string,
	symbol: string,
	metric: Metric,
	goal: number,
	reward: {
		currencies: { [string]: number }?,
		chests: { string }?,
		eggs: { string }?,
		titles: { string }?,
	},
}

local GEMS = 10

local Order = {
	"primer_latido",
	"curiosidad",
	"primer_tallado",
	"niebla_disipada",
	"naturalista",
	"cielo_de_copal",
	"raiz_restaurada",
}

local ById: { [string]: AchievementDef } = {
	primer_latido = {
		id = "primer_latido",
		name = "Primer latido",
		description = "Eclosiona un huevo en la incubadora.",
		symbol = "🥚",
		metric = "EggsHatched",
		goal = 1,
		reward = { currencies = { Gemas = GEMS }, chests = { "Madera" } },
	},
	curiosidad = {
		id = "curiosidad",
		name = "Ojos curiosos",
		description = "Descubre 5 especies en el Bestiario.",
		symbol = "🔍",
		metric = "SpeciesDiscovered",
		goal = 5,
		reward = { currencies = { Gemas = GEMS }, chests = { "Madera" } },
	},
	primer_tallado = {
		id = "primer_tallado",
		name = "Primer Tallado",
		description = "Haz que un monstruo evolucione a Tallado.",
		symbol = "✨",
		metric = "Tallados",
		goal = 1,
		reward = { currencies = { Gemas = GEMS }, chests = { "Plata" }, titles = { "Tallador" } },
	},
	niebla_disipada = {
		id = "niebla_disipada",
		name = "Niebla disipada",
		description = "Restaura 4 especies de Opacos.",
		symbol = "🌫",
		metric = "SpeciesRestored",
		goal = 4,
		-- Huevo de especie fijada y visible: Zunzi (Común, también rescatable en el Acto I)
		reward = { currencies = { Gemas = GEMS }, eggs = { "zunzi" } },
	},
	naturalista = {
		id = "naturalista",
		name = "Naturalista del Valle",
		description = "Descubre 8 especies en el Bestiario.",
		symbol = "📖",
		metric = "SpeciesDiscovered",
		goal = 8,
		reward = { currencies = { Gemas = GEMS }, chests = { "Plata" } },
	},
	cielo_de_copal = {
		id = "cielo_de_copal",
		name = "Cielo de copal",
		description = "Consigue 24 estrellas en el Acto I.",
		symbol = "★",
		metric = "Stars",
		goal = 24,
		reward = { currencies = { Gemas = GEMS }, chests = { "Oro" } },
	},
	raiz_restaurada = {
		id = "raiz_restaurada",
		name = "Raíz restaurada",
		description = "Restaura a Copalia, guardiana del Valle Copal.",
		symbol = "🪶",
		metric = "Guardians",
		goal = 1,
		reward = { currencies = { Gemas = GEMS }, titles = { "Amigo de Copalia" } },
	},
}

return Freeze.deep({
	Order = Order,
	ById = ById,
	GemsPerAchievement = GEMS,
})
