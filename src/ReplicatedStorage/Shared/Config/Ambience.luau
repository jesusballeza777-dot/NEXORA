--!strict
-- Ambiente visual de Valle Copal en Roblox: luz de tarde dorada, atmósfera cálida,
-- posproceso con mesura, colores de los materiales del terreno, paleta del valle y
-- reparto de flora. Datos, no lógica: Server/World/* los aplica.
-- Reglas de la Biblia visual Genesis (§4, §7): pigmentos ≤ 70 % de saturación (HSV),
-- luces cálidas y sombras frías, bloom ≤ 0,6 con umbral ≥ 0,9, contraste +0,05…+0,1 y
-- saturación cercana a 0, atmósfera 0,30–0,38 y sol de tarde a unos 30° de altura.

local Freeze = require(script.Parent.Parent.Util.Freeze)

local function rgb(r: number, g: number, b: number): { number }
	return { r, g, b }
end

return Freeze.deep({
	Lighting = {
		clockTime = 15.9, -- tarde dorada: sol a ~30° (Genesis §7)
		brightness = 2.5,
		geographicLatitude = 23,
		ambient = rgb(62, 70, 74), -- sombras frías (jade azulado), nunca negras
		outdoorAmbient = rgb(138, 128, 120),
		environmentDiffuseScale = 0.55,
		environmentSpecularScale = 0.5,
		shadowSoftness = 0.25,
	},
	Atmosphere = {
		density = 0.34,
		offset = 0.1,
		color = rgb(232, 200, 166),
		decay = rgb(150, 120, 130),
		glare = 0.3,
		haze = 1.6,
	},
	Bloom = { intensity = 0.5, size = 26, threshold = 1.4 },
	SunRays = { intensity = 0.05, spread = 0.6 },
	Grade = { saturation = 0.04, contrast = 0.08, tint = rgb(255, 246, 234) },

	Clouds = { cover = 0.5, density = 0.5, color = rgb(255, 238, 226) },

	-- Paleta del valle (Genesis §4.2). Nombres en inglés; valores de la Biblia.
	Palette = {
		copal = rgb(232, 168, 72),
		copalGlow = rgb(255, 196, 96),
		copalPale = rgb(246, 217, 166),
		jade = rgb(62, 150, 122),
		jadeDeep = rgb(47, 110, 92),
		jadePale = rgb(143, 209, 185),
		clay = rgb(176, 98, 64),
		clayDark = rgb(138, 74, 48),
		clayPale = rgb(217, 146, 106),
		stone = rgb(196, 182, 160),
		stoneMid = rgb(154, 140, 120),
		stoneDark = rgb(110, 98, 82),
		bark = rgb(96, 70, 58),
		barkDark = rgb(63, 46, 38),
		barkPale = rgb(138, 106, 84),
		leaf = rgb(86, 150, 92),
		leafDeep = rgb(59, 110, 68),
		leafPale = rgb(156, 195, 106),
		cacao = rgb(42, 28, 21),
		cacaoMid = rgb(58, 39, 29),
		adobe = rgb(214, 170, 128),
		brass = rgb(196, 150, 72),
		cream = rgb(240, 226, 200),
		basalt = rgb(86, 84, 92),
		fog = rgb(150, 150, 160),
		opaco = rgb(132, 134, 128),
	},
	-- Papel picado: rosa, ámbar, azul, violeta y verde, solo en acentos (≤ 70 % sat.)
	Papel = {
		rgb(214, 84, 120),
		rgb(236, 172, 72),
		rgb(72, 160, 200),
		rgb(150, 104, 200),
		rgb(110, 176, 100),
	},

	Terrain = {
		decoration = true, -- briznas de pasto animadas por el viento (Terrain.Decoration)
		-- Color de cada material del terreno (Terrain:SetMaterialColor)
		materials = {
			Grass = rgb(104, 152, 84),
			LeafyGrass = rgb(78, 128, 74),
			Ground = rgb(158, 122, 88),
			Mud = rgb(108, 82, 62),
			Sand = rgb(204, 184, 144),
			Rock = rgb(128, 120, 110),
			Slate = rgb(112, 104, 92),
			Basalt = rgb(84, 82, 92),
		},
		water = { color = rgb(58, 138, 120), transparency = 0.55, waveSize = 0.06, waveSpeed = 6, reflectance = 0.25 },
	},

	-- Matas de flores (cempasúchil, bugambilia, flor de calabaza…) repartidas con semilla
	-- fija: el valle es idéntico en todos los servidores. Se evitan plaza, caminos,
	-- lotes, río, estaciones y Linde.
	Flowers = {
		seed = 1717,
		clusters = 60,
		minRadius = 34,
		maxRadius = 170,
		petalsPerCluster = 3,
		petalSize = 0.9,
		colors = {
			rgb(236, 152, 72), -- cempasúchil
			rgb(214, 84, 140), -- bugambilia
			rgb(246, 236, 214),
			rgb(240, 196, 84), -- flor de calabaza
			rgb(150, 104, 200),
		},
	},

	-- Árboles, arbustos y rocas: especies con plantilla y variación determinista
	Flora = {
		seed = 2024,
		attempts = 1900,
		minRadius = 40,
		maxRadius = 270,
		species = {
			Ahuejote = { trunk = rgb(118, 100, 78), leaves = { rgb(86, 132, 72), rgb(104, 146, 80) } },
			Copal = { trunk = rgb(150, 92, 66), leaves = { rgb(140, 182, 98), rgb(110, 160, 86) } },
			Sabino = { trunk = rgb(96, 70, 58), leaves = { rgb(52, 100, 70), rgb(66, 116, 74), rgb(47, 92, 78) } },
			Colorin = { trunk = rgb(110, 90, 72), leaves = { rgb(96, 146, 82) }, bloom = rgb(204, 86, 62) },
			Opacado = { trunk = rgb(110, 108, 104), leaves = { rgb(140, 146, 132) } },
		},
		bush = { rgb(70, 124, 72), rgb(96, 146, 82), rgb(62, 108, 80) },
		bougainvillea = rgb(196, 78, 132),
		agave = rgb(110, 150, 132),
		maize = { rgb(124, 160, 82), rgb(170, 160, 92) },
		reed = { rgb(118, 128, 70), rgb(146, 138, 84), rgb(96, 104, 62) },
		rock = rgb(150, 138, 120),
	},

	-- Linde de las Chinampas: juncos y rocas de basalto alrededor de cada Opaco
	Linde = {
		reedClustersPerZone = 7,
		reedColors = { rgb(118, 128, 70), rgb(146, 138, 84), rgb(96, 104, 62) },
		boulder = rgb(96, 96, 104),
	},

	-- Motas de copal que flotan sobre la plaza y el árbol (una sola fuente de partículas)
	Motes = {
		center = { 0, 16, -20 },
		size = { 80, 26, 80 },
		color = rgb(255, 214, 120),
		rate = 8,
		lifetime = { 4, 7 },
		particleSize = 0.28,
		speed = { 0.2, 0.7 },
	},
})
