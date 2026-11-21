--!strict
-- Paquetes de recompensa deterministas de la Fase 1. Ninguno es aleatorio.
-- Cada concesión real se registra con procedencia en el perfil (Server/Domain/RewardRules).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type RewardBundle = {
	id: string,
	title: string,
	currencies: { [string]: number }?,
	items: { [string]: number }?,
	petXp: number?,
	unlocks: { string }?,
}

local Bundles: { [string]: RewardBundle } = {
	OnboardingGift = {
		id = "OnboardingGift",
		title = "Regalo del Gabinete",
		currencies = { Monedas = 100 },
		items = { RacionBasica = 3 },
		unlocks = { "LoteHogar", "Habitat_Hogar_H1" },
	},
	FirstOpacoRestored = {
		id = "FirstOpacoRestored",
		title = "¡Primer Opaco restaurado!",
		currencies = { Gemas = 10 },
		items = { RacionBioma = 2 },
		unlocks = { "Encounter_valle_r1_e2", "Despensa" },
	},
	CanalCleared = {
		id = "CanalCleared",
		title = "El canal recupera su color",
		items = { Festin = 1 },
		unlocks = { "Encounter_valle_r1_e3" },
	},
	EliteVainaCleared = {
		id = "EliteVainaCleared",
		title = "Élite restaurado",
		currencies = { Gemas = 5 },
		items = { Festin = 1 },
		unlocks = { "Region1Complete" },
	},
}

return Freeze.deep({ ById = Bundles })
