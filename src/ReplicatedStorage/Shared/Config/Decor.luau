--!strict
-- Decoración del Lote Hogar (Fase 2, primera versión controlada).
-- La Biblia propone plantillas de construcción y 6 espacios para objetos libres (p. 30,
-- "Lotes"): aquí hay 6 espacios fijos alrededor del hábitat y un catálogo pequeño de
-- objetos deterministas (sin aleatoriedad), obtenidos jugando (encargos, etapas, Códice).
-- Sin editor de construcción todavía. Todo objeto es del jugador y lo valida el servidor.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type DecorDef = {
	id: string,
	name: string,
	category: string,
	description: string,
	footprint: string, -- "Small" | "Medium"
	color: { number },
	accent: { number },
	shape: string, -- forma del blockout ("Lantern", "Planter", "Banner", "Stone", "Bench", "Arch")
}

local function rgb(r: number, g: number, b: number): { number }
	return { r, g, b }
end

local Items: { [string]: DecorDef } = {
	FarolDeCopal = {
		id = "FarolDeCopal",
		name = "Farol de copal",
		category = "Luz",
		description = "Un farol de papel que brilla al atardecer.",
		footprint = "Small",
		color = rgb(232, 168, 72),
		accent = rgb(255, 214, 120),
		shape = "Lantern",
	},
	MacetaDeCempasuchil = {
		id = "MacetaDeCempasuchil",
		name = "Maceta de cempasúchil",
		category = "Flora",
		description = "Flores naranjas en una olla de barro.",
		footprint = "Small",
		color = rgb(176, 98, 64),
		accent = rgb(242, 140, 30),
		shape = "Planter",
	},
	EstandarteDePapelPicado = {
		id = "EstandarteDePapelPicado",
		name = "Estandarte de papel picado",
		category = "Fiesta",
		description = "Banderines de colores entre dos postes.",
		footprint = "Medium",
		color = rgb(140, 100, 66),
		accent = rgb(232, 74, 110),
		shape = "Banner",
	},
	PiedraDeGreca = {
		id = "PiedraDeGreca",
		name = "Piedra de greca",
		category = "Piedra",
		description = "Un monolito tallado con grecas del Valle.",
		footprint = "Medium",
		color = rgb(196, 182, 160),
		accent = rgb(62, 150, 122),
		shape = "Stone",
	},
	BancaDeMadera = {
		id = "BancaDeMadera",
		name = "Banca de madera",
		category = "Mobiliario",
		description = "Para descansar junto a tus monstruos.",
		footprint = "Medium",
		color = rgb(140, 100, 66),
		accent = rgb(96, 70, 52),
		shape = "Bench",
	},
	ArcoDeRaices = {
		id = "ArcoDeRaices",
		name = "Arco de raíces",
		category = "Flora",
		description = "Raíces de Copalia que vuelven a florecer. Recuerdo del Acto I.",
		footprint = "Medium",
		color = rgb(96, 70, 52),
		accent = rgb(104, 190, 96),
		shape = "Arch",
	},
}

return Freeze.deep({
	FreeSlots = 6,
	-- Posiciones relativas al centro del lote (Config/World.Lots), fuera de los pedestales
	SlotOffsets = {
		{ -18, 0, -14 },
		{ 18, 0, -14 },
		{ -20, 0, 2 },
		{ 20, 0, 2 },
		{ -8, 0, 18 },
		{ 8, 0, 18 },
	},
	ById = Items,
	Order = {
		"FarolDeCopal",
		"MacetaDeCempasuchil",
		"EstandarteDePapelPicado",
		"PiedraDeGreca",
		"BancaDeMadera",
		"ArcoDeRaices",
	},
	-- Plantillas de construcción: disposiciones predefinidas de un toque
	Templates = {
		{ id = "Fiesta", name = "Fiesta del Valle", slots = { "EstandarteDePapelPicado", "FarolDeCopal" } },
		{ id = "Jardin", name = "Jardín de copal", slots = { "MacetaDeCempasuchil", "PiedraDeGreca" } },
	},
})
