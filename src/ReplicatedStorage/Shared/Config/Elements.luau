--!strict
-- Los doce elementos (Biblia v5.0, p. 31–34).
-- Estado: rueda DEFINIDA como "provisional" en la fuente; multiplicadores en
-- Config/Combat (hipótesis de beta ×1.25 / ×0.85, ver docs/DESIGN_DECISIONS.md D-001).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type ElementId =
	"Agua"
	| "Fuego"
	| "Aire"
	| "Tierra"
	| "Metal"
	| "Flora"
	| "Rayo"
	| "Artificio"
	| "Luz"
	| "Sombra"
	| "Mente"
	| "Astral"

export type ElementDef = {
	id: ElementId,
	name: string,
	ring: "Primordial" | "Materia" | "Arcano",
	strongAgainst: { ElementId },
	-- Derivado: elementos que vencen a este (se valida en tests).
	weakAgainst: { ElementId },
	color: { number }, -- RGB 0-255
	motif: string,
	speciesCount: number, -- recuento de la fuente (p. 31), validado contra Species
}

local Elements: { [string]: ElementDef } = {
	Agua = {
		id = "Agua",
		name = "Agua",
		ring = "Primordial",
		strongAgainst = { "Fuego", "Metal" },
		weakAgainst = { "Flora", "Rayo" },
		color = { 64, 170, 214 },
		motif = "Ríos, cántaros y espuma. Formas fluidas, aletas y branquias.",
		speciesCount = 7,
	},
	Fuego = {
		id = "Fuego",
		name = "Fuego",
		ring = "Primordial",
		strongAgainst = { "Flora", "Sombra" },
		weakAgainst = { "Agua", "Mente" },
		color = { 236, 112, 50 },
		motif = "Brasas, comales y hornos. Lóbulos de llama y grietas encendidas.",
		speciesCount = 7,
	},
	Aire = {
		id = "Aire",
		name = "Aire",
		ring = "Primordial",
		strongAgainst = { "Tierra", "Flora" },
		weakAgainst = { "Metal", "Luz" },
		color = { 170, 214, 226 },
		motif = "Papalotes, plumas y remolinos. Alas, colas largas y espirales abiertas.",
		speciesCount = 9,
	},
	Tierra = {
		id = "Tierra",
		name = "Tierra",
		ring = "Primordial",
		strongAgainst = { "Rayo", "Metal" },
		weakAgainst = { "Aire", "Astral" },
		color = { 184, 132, 76 },
		motif = "Barro, grecas y piedra. Volúmenes pesados y caparazones.",
		speciesCount = 6,
	},
	Metal = {
		id = "Metal",
		name = "Metal",
		ring = "Materia",
		strongAgainst = { "Aire", "Astral" },
		weakAgainst = { "Agua", "Tierra" },
		color = { 164, 172, 184 },
		motif = "Hojalata repujada, herrería y remaches. Placas y filos.",
		speciesCount = 5,
	},
	Flora = {
		id = "Flora",
		name = "Flora",
		ring = "Materia",
		strongAgainst = { "Agua", "Luz" },
		weakAgainst = { "Fuego", "Aire" },
		color = { 104, 176, 88 },
		motif = "Maguey, vainas y chinampas. Hojas, raíces y flores.",
		speciesCount = 5,
	},
	Rayo = {
		id = "Rayo",
		name = "Rayo",
		ring = "Materia",
		strongAgainst = { "Agua", "Mente" },
		weakAgainst = { "Tierra", "Artificio" },
		color = { 244, 206, 60 },
		motif = "Fulgurita, cobre y chicharras. Zigzag y puntas metálicas.",
		speciesCount = 5,
	},
	Artificio = {
		id = "Artificio",
		name = "Artificio",
		ring = "Materia",
		strongAgainst = { "Rayo", "Astral" },
		weakAgainst = { "Sombra", "Mente" },
		color = { 196, 140, 92 },
		motif = "Juguetes de cuerda, rehiletes y engranes. Juntas y llaves.",
		speciesCount = 7,
	},
	Luz = {
		id = "Luz",
		name = "Luz",
		ring = "Arcano",
		strongAgainst = { "Sombra", "Aire" },
		weakAgainst = { "Flora", "Astral" },
		color = { 250, 226, 150 },
		motif = "Velas, porcelana y vitral. Halos y superficies pulidas.",
		speciesCount = 9,
	},
	Sombra = {
		id = "Sombra",
		name = "Sombra",
		ring = "Arcano",
		strongAgainst = { "Mente", "Artificio" },
		weakAgainst = { "Fuego", "Luz" },
		color = { 110, 84, 160 },
		motif = "Rebozo, niebla y luna. Siluetas suaves y bordes difusos.",
		speciesCount = 7,
	},
	Mente = {
		id = "Mente",
		name = "Mente",
		ring = "Arcano",
		strongAgainst = { "Artificio", "Fuego" },
		weakAgainst = { "Rayo", "Sombra" },
		color = { 214, 120, 190 },
		motif = "Caracolas, tinta y espirales. Ojos grandes y patrones hipnóticos.",
		speciesCount = 5,
	},
	Astral = {
		id = "Astral",
		name = "Astral",
		ring = "Arcano",
		strongAgainst = { "Luz", "Tierra" },
		weakAgainst = { "Metal", "Artificio" },
		color = { 96, 120, 214 },
		motif = "Estrellas, cráteres y auroras. Puntos de luz y órbitas.",
		speciesCount = 7,
	},
}

local Order: { ElementId } = {
	"Agua",
	"Fuego",
	"Aire",
	"Tierra",
	"Metal",
	"Flora",
	"Rayo",
	"Artificio",
	"Luz",
	"Sombra",
	"Mente",
	"Astral",
}

return Freeze.deep({
	ById = Elements,
	Order = Order,
})
