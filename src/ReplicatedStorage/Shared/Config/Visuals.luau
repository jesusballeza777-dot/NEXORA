--!strict
-- VisualConfiguration por especie. Describe BLOCKOUTS provisionales construidos con
-- primitivas (Client/Creatures/CreatureBuilder) a partir de un arquetipo.
-- Ningún valor aquí es un diseño aprobado: ver docs/ART_DIRECTION.md y
-- docs/art/STARTERS_REDESIGN.md. Cuando exista un modelo aprobado, "assetStatus"
-- pasa a "Approved" y "modelAsset" apunta al activo real (nunca se inventan IDs).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type Palette = {
	body: { number },
	belly: { number },
	accent: { number },
	emissive: { number },
	eye: { number },
	iris: { number },
}

export type VisualDef = {
	archetype: string,
	assetStatus: "Blockout" | "Approved",
	modelAsset: string?,
	broteScale: number,
	talladoScale: number, -- ×1.4–×1.7 (p. 20)
	brote: Palette,
	tallado: Palette,
	signatureFeature: string, -- rasgo firma que debe conservarse entre formas
}

local function rgb(r: number, g: number, b: number): { number }
	return { r, g, b }
end

local Visuals: { [string]: VisualDef } = {
	kuachi = {
		archetype = "Opossum",
		assetStatus = "Blockout",
		broteScale = 1.0,
		talladoScale = 1.55,
		signatureFeature = "Bolsa-horno encendida y cola de ceniza con punta de brasa",
		brote = {
			body = rgb(158, 138, 122),
			belly = rgb(222, 204, 184),
			accent = rgb(92, 78, 70),
			emissive = rgb(255, 150, 60),
			eye = rgb(24, 20, 18),
			iris = rgb(24, 20, 18),
		},
		tallado = {
			body = rgb(98, 90, 88),
			belly = rgb(64, 56, 54),
			accent = rgb(44, 38, 36),
			emissive = rgb(255, 104, 30),
			eye = rgb(250, 236, 214),
			iris = rgb(255, 120, 40),
		},
	},
	xolumi = {
		archetype = "Axolotl",
		assetStatus = "Blockout",
		broteScale = 1.0,
		talladoScale = 1.6,
		signatureFeature = "Branquias plumosas turquesa y barro negro bruñido",
		brote = {
			body = rgb(34, 36, 42),
			belly = rgb(58, 62, 72),
			accent = rgb(64, 206, 196),
			emissive = rgb(110, 236, 220),
			eye = rgb(14, 14, 16),
			iris = rgb(14, 14, 16),
		},
		tallado = {
			body = rgb(22, 24, 30),
			belly = rgb(40, 42, 50),
			accent = rgb(214, 170, 74),
			emissive = rgb(120, 240, 226),
			eye = rgb(240, 236, 220),
			iris = rgb(70, 200, 230),
		},
	},
	teselo = {
		archetype = "Tortoise",
		assetStatus = "Blockout",
		broteScale = 1.0,
		talladoScale = 1.5,
		signatureFeature = "Caparazón de grecas (teselas) que evoluciona a terrazas con disco de cielo",
		brote = {
			body = rgb(156, 132, 98),
			belly = rgb(196, 168, 122),
			accent = rgb(62, 150, 122),
			emissive = rgb(236, 206, 120),
			eye = rgb(22, 20, 18),
			iris = rgb(22, 20, 18),
		},
		tallado = {
			body = rgb(120, 98, 72),
			belly = rgb(176, 146, 100),
			accent = rgb(52, 138, 112),
			emissive = rgb(246, 210, 110),
			eye = rgb(246, 238, 220),
			iris = rgb(206, 150, 60),
		},
	},
	comalu = {
		archetype = "Armadillo",
		assetStatus = "Blockout",
		broteScale = 0.95,
		talladoScale = 1.55,
		signatureFeature = "Bandas de comal de barro con costuras de brasa",
		brote = {
			body = rgb(168, 74, 52),
			belly = rgb(214, 160, 120),
			accent = rgb(40, 30, 28),
			emissive = rgb(255, 120, 50),
			eye = rgb(20, 18, 16),
			iris = rgb(20, 18, 16),
		},
		tallado = {
			body = rgb(120, 52, 40),
			belly = rgb(60, 40, 36),
			accent = rgb(30, 24, 22),
			emissive = rgb(255, 96, 30),
			eye = rgb(240, 230, 210),
			iris = rgb(255, 110, 40),
		},
	},
	agavo = {
		archetype = "Agave",
		assetStatus = "Blockout",
		broteScale = 1.0,
		talladoScale = 1.6,
		signatureFeature = "Roseta de pencas con cara al centro",
		brote = {
			body = rgb(110, 160, 120),
			belly = rgb(170, 200, 150),
			accent = rgb(64, 120, 96),
			emissive = rgb(160, 230, 170),
			eye = rgb(20, 24, 20),
			iris = rgb(20, 24, 20),
		},
		tallado = {
			body = rgb(80, 136, 104),
			belly = rgb(140, 180, 130),
			accent = rgb(48, 160, 120),
			emissive = rgb(120, 240, 170),
			eye = rgb(236, 240, 220),
			iris = rgb(90, 200, 120),
		},
	},
	zizi = {
		archetype = "Cicada",
		assetStatus = "Blockout",
		broteScale = 0.9,
		talladoScale = 1.5,
		signatureFeature = "Alas de vidrio y abdomen-tambor",
		brote = {
			body = rgb(176, 196, 80),
			belly = rgb(220, 220, 140),
			accent = rgb(196, 120, 60),
			emissive = rgb(255, 230, 90),
			eye = rgb(24, 24, 20),
			iris = rgb(24, 24, 20),
		},
		tallado = {
			body = rgb(150, 170, 60),
			belly = rgb(200, 190, 110),
			accent = rgb(184, 104, 52),
			emissive = rgb(255, 220, 60),
			eye = rgb(240, 240, 220),
			iris = rgb(255, 210, 60),
		},
	},
	barrock = {
		archetype = "Jar",
		assetStatus = "Blockout",
		broteScale = 1.0,
		talladoScale = 1.6,
		signatureFeature = "Cántaro con asa-oreja y grecas blancas",
		brote = {
			body = rgb(176, 98, 64),
			belly = rgb(214, 150, 110),
			accent = rgb(240, 232, 214),
			emissive = rgb(120, 200, 240),
			eye = rgb(24, 20, 18),
			iris = rgb(24, 20, 18),
		},
		tallado = {
			body = rgb(150, 82, 54),
			belly = rgb(190, 130, 96),
			accent = rgb(226, 186, 80),
			emissive = rgb(110, 200, 250),
			eye = rgb(240, 232, 214),
			iris = rgb(90, 170, 230),
		},
	},
	vainas = {
		archetype = "Beetle",
		assetStatus = "Blockout",
		broteScale = 0.95,
		talladoScale = 1.55,
		signatureFeature = "Élitros de vaina y cuerno de semilla",
		brote = {
			body = rgb(118, 150, 70),
			belly = rgb(200, 160, 80),
			accent = rgb(88, 70, 40),
			emissive = rgb(220, 240, 120),
			eye = rgb(20, 22, 18),
			iris = rgb(20, 22, 18),
		},
		tallado = {
			body = rgb(96, 128, 56),
			belly = rgb(186, 140, 64),
			accent = rgb(70, 56, 32),
			emissive = rgb(210, 240, 100),
			eye = rgb(236, 236, 214),
			iris = rgb(190, 220, 80),
		},
	},
	-- ===== Fase 2 · Opacos del Acto I =====
	-- Blockout provisional con ARQUETIPO PRESTADO (no es diseño): solo para que estas
	-- especies existan como enemigos y huevos en la beta. Paletas por elemento y rasgo
	-- de la ficha (SpeciesLore). Sustituir cuando haya concepto aprobado.
	zunzi = {
		archetype = "Cicada",
		assetStatus = "Blockout",
		broteScale = 0.85,
		talladoScale = 1.45,
		signatureFeature = "Arquetipo prestado (Cicada): alas rápidas de colibrí azul",
		brote = {
			body = rgb(70, 130, 200),
			belly = rgb(170, 210, 236),
			accent = rgb(40, 70, 130),
			emissive = rgb(150, 220, 255),
			eye = rgb(18, 20, 28),
			iris = rgb(18, 20, 28),
		},
		tallado = {
			body = rgb(50, 100, 180),
			belly = rgb(140, 190, 226),
			accent = rgb(220, 230, 240),
			emissive = rgb(130, 210, 255),
			eye = rgb(236, 240, 250),
			iris = rgb(80, 170, 255),
		},
	},
	pabilo = {
		archetype = "Jar",
		assetStatus = "Blockout",
		broteScale = 0.85,
		talladoScale = 1.45,
		signatureFeature = "Arquetipo prestado (Jar): cuerpo de cera con pabilo encendido",
		brote = {
			body = rgb(240, 226, 196),
			belly = rgb(250, 240, 220),
			accent = rgb(232, 168, 72),
			emissive = rgb(255, 200, 90),
			eye = rgb(30, 24, 18),
			iris = rgb(30, 24, 18),
		},
		tallado = {
			body = rgb(232, 214, 180),
			belly = rgb(246, 232, 204),
			accent = rgb(214, 140, 60),
			emissive = rgb(255, 190, 70),
			eye = rgb(250, 240, 220),
			iris = rgb(255, 170, 60),
		},
	},
	lumbro = {
		archetype = "Agave",
		assetStatus = "Blockout",
		broteScale = 0.95,
		talladoScale = 1.55,
		signatureFeature = "Arquetipo prestado (Agave): cuernos-farol de luz cálida",
		brote = {
			body = rgb(214, 176, 110),
			belly = rgb(240, 214, 160),
			accent = rgb(255, 210, 120),
			emissive = rgb(255, 230, 150),
			eye = rgb(28, 22, 16),
			iris = rgb(28, 22, 16),
		},
		tallado = {
			body = rgb(196, 150, 90),
			belly = rgb(230, 196, 140),
			accent = rgb(255, 200, 100),
			emissive = rgb(255, 220, 130),
			eye = rgb(250, 240, 220),
			iris = rgb(255, 200, 90),
		},
	},
	dienton = {
		archetype = "Armadillo",
		assetStatus = "Blockout",
		broteScale = 0.95,
		talladoScale = 1.55,
		signatureFeature = "Arquetipo prestado (Armadillo): anillos de madera y musgo",
		brote = {
			body = rgb(132, 96, 64),
			belly = rgb(186, 150, 110),
			accent = rgb(90, 140, 80),
			emissive = rgb(150, 210, 110),
			eye = rgb(22, 18, 14),
			iris = rgb(22, 18, 14),
		},
		tallado = {
			body = rgb(112, 80, 52),
			belly = rgb(170, 132, 94),
			accent = rgb(80, 130, 70),
			emissive = rgb(140, 200, 100),
			eye = rgb(240, 232, 214),
			iris = rgb(150, 210, 110),
		},
	},
}

-- Estilo "Opaco": la niebla gris desatura la especie; al vencerlo recupera su color.
local Opaco = {
	tint = rgb(128, 128, 134),
	desaturation = 0.85,
	fogColor = rgb(150, 150, 160),
}

local RarityFrames = {
	Comun = { frame = rgb(214, 200, 176), style = "Liso" },
	Raro = { frame = rgb(72, 140, 230), style = "Azul" },
	Epico = { frame = rgb(156, 96, 222), style = "Violeta con esquinas" },
	Legendario = { frame = rgb(236, 184, 64), style = "Oro" },
	Unico = { frame = rgb(140, 230, 220), style = "Iridiscente" },
	Misterio = { frame = rgb(60, 60, 60), style = "Punteado imposible" },
}

-- Rasgos de cara comunes de los blockouts (Brote: rubor y sonrisa; Tallado: ceño)
local Face = {
	blush = rgb(255, 146, 158),
	mouth = rgb(40, 24, 22),
	mouthOnDark = rgb(236, 150, 160), -- sobre cuerpos muy oscuros (Xolumi) la boca se aclara
	sclera = rgb(250, 250, 246),
}

return Freeze.deep({
	ById = Visuals,
	Face = Face,
	Opaco = Opaco,
	RarityFrames = RarityFrames,
})
