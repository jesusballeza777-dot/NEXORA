--!strict
-- Códice del Nexo (Biblia compacta p. 114): cartas de lore (cada jefe, región y Opaco deja
-- una), Pistas Veladas (etapas secretas) y Bestiario (las fichas viven en SpeciesLore).
-- Textos breves: una idea por carta, para leer en segundos. Los textos de regiones,
-- etapas y pistas son PROPUESTA narrativa (D-029) coherente con la Biblia: no amplían el
-- canon de personajes ni deciden preguntas abiertas.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type CodexEntry = {
	id: string,
	kind: "Lore" | "Velada" | "Guardian",
	title: string,
	text: string,
	symbol: string, -- icono corto para la carta
	act: string,
}

local Entries: { [string]: CodexEntry } = {
	["region:ActoI:1"] = {
		id = "region:ActoI:1",
		kind = "Lore",
		title = "La Linde de las Chinampas",
		text = "Los canales unían los huertos flotantes. Cuando llegó la niebla gris, los juncos dejaron de cantar.",
		symbol = "🌾",
		act = "ActoI",
	},
	["region:ActoI:2"] = {
		id = "region:ActoI:2",
		kind = "Lore",
		title = "El Mercado de Copal",
		text = "Aquí se cambiaba copal por historias. Los faroles del mercado se apagaron uno a uno.",
		symbol = "🏮",
		act = "ActoI",
	},
	["region:ActoI:3"] = {
		id = "region:ActoI:3",
		kind = "Lore",
		title = "Las Raíces del Gran Nexo",
		text = "Bajo el árbol duermen raíces que recuerdan cada semilla del Valle. Alguien las oye latir.",
		symbol = "🌳",
		act = "ActoI",
	},
	["opaco:ActoI"] = {
		id = "opaco:ActoI",
		kind = "Lore",
		title = "La niebla gris",
		text = "Un Opaco no está perdido: solo olvidó su color. Al vencerlo, la niebla se disipa y vuelve a ser quien era.",
		symbol = "🌫",
		act = "ActoI",
	},
	["guardian:copalia"] = {
		id = "guardian:copalia",
		kind = "Guardian",
		title = "Copalia, la Garza de Raíces",
		text = "Guardiana del Valle Copal. Sus patas son raíces y sus alas, hojas y faroles. Al restaurarla, los hábitats del Valle crecen con más fuerza.",
		symbol = "🪶",
		act = "ActoI",
	},
	["velada:cartografo"] = {
		id = "velada:cartografo",
		kind = "Velada",
		title = "Huellas de tinta",
		text = "En la arena de la Linde hay huellas que se secan como tinta. Una figura con un mapa por capa pasó por aquí.",
		symbol = "🗺",
		act = "ActoI",
	},
	["velada:bordadora"] = {
		id = "velada:bordadora",
		kind = "Velada",
		title = "Una pluma cosida",
		text = "Entre los puestos del mercado quedó una pluma atravesada por un hilo que brilla como un rayo.",
		symbol = "🪡",
		act = "ActoI",
	},
	["velada:relojero"] = {
		id = "velada:relojero",
		kind = "Velada",
		title = "Un engrane quieto",
		text = "Junto a las raíces hay un engrane enorme. Por un instante, el tiempo pareció detenerse a su alrededor.",
		symbol = "⚙",
		act = "ActoI",
	},
}

return Freeze.deep({
	ById = Entries,
	Order = {
		"opaco:ActoI",
		"region:ActoI:1",
		"region:ActoI:2",
		"region:ActoI:3",
		"guardian:copalia",
		"velada:cartografo",
		"velada:bordadora",
		"velada:relojero",
	},
})
