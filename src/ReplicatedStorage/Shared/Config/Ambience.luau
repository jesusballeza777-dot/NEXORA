--!strict
-- Ambiente visual de Valle Copal en Roblox: luz de tarde dorada, atmósfera cálida,
-- posproceso suave, terreno con pasto animado, nubes, flores y motas de copal.
-- Mismo espíritu que la vista previa web (docs/ART_DIRECTION.md). Datos, no lógica:
-- Server/World/ValleBuilder los aplica. Presupuesto móvil: sin luces extra, una sola
-- fuente de partículas ambiental y flores de pocas piezas sin colisión.

local Freeze = require(script.Parent.Parent.Util.Freeze)

local function rgb(r: number, g: number, b: number): { number }
	return { r, g, b }
end

return Freeze.deep({
	Lighting = {
		clockTime = 16.6, -- tarde dorada
		brightness = 2.4,
		geographicLatitude = 23,
		ambient = rgb(70, 56, 52),
		outdoorAmbient = rgb(150, 128, 112),
		environmentDiffuseScale = 0.55,
		environmentSpecularScale = 0.5,
		shadowSoftness = 0.25,
	},
	Atmosphere = {
		density = 0.32,
		offset = 0.12,
		color = rgb(232, 196, 160),
		decay = rgb(150, 110, 120),
		glare = 0.35,
		haze = 1.4,
	},
	Bloom = { intensity = 0.55, size = 28, threshold = 1.6 },
	SunRays = { intensity = 0.06, spread = 0.6 },
	Grade = { saturation = 0.1, contrast = 0.07, tint = rgb(255, 246, 234) },

	Clouds = { cover = 0.52, density = 0.55, color = rgb(255, 238, 226) },

	Terrain = {
		decoration = true, -- briznas de pasto animadas por el viento (Terrain.Decoration)
		grass = rgb(104, 160, 84),
		mud = rgb(118, 90, 68),
		water = { color = rgb(70, 150, 150), transparency = 0.6, waveSize = 0.08, waveSpeed = 6, reflectance = 0.3 },
	},

	-- Matas de flores (cempasúchil, bugambilia, flor de calabaza…) repartidas con semilla
	-- fija: el valle es idéntico en todos los servidores. Se evitan plaza, caminos,
	-- lotes, río, estaciones y Linde.
	Flowers = {
		seed = 1717,
		clusters = 64,
		minRadius = 34,
		maxRadius = 150,
		petalsPerCluster = 3,
		petalSize = 0.9,
		colors = {
			rgb(242, 140, 30), -- cempasúchil
			rgb(222, 64, 140), -- bugambilia
			rgb(250, 244, 230),
			rgb(250, 200, 60),
			rgb(150, 96, 222),
		},
	},

	-- Árboles, rocas y arbustos alrededor del área de juego (mismo reparto que la vista
	-- previa web: semilla fija, fuera de zonas de interacción).
	Scatter = {
		seed = 2024,
		attempts = 90,
		minRadius = 60,
		maxRadius = 230,
		treeChance = 0.62,
		rockChance = 0.2, -- el resto son arbustos
		trunk = rgb(96, 70, 52),
		leaves = { rgb(70, 132, 74), rgb(98, 156, 84), rgb(132, 182, 98) },
		rock = rgb(143, 133, 118),
	},

	-- Linde de las Chinampas: juncos y rocas de basalto alrededor de cada Opaco
	Linde = {
		reedClustersPerZone = 9,
		reedColors = { rgb(118, 128, 70), rgb(146, 138, 84), rgb(96, 104, 62) },
		boulder = rgb(96, 96, 104),
	},

	-- Motas de copal que flotan sobre la plaza y el árbol (una sola fuente de partículas)
	Motes = {
		center = { 0, 9, -8 },
		size = { 70, 12, 70 },
		color = rgb(255, 214, 120),
		rate = 7,
		lifetime = { 4, 7 },
		particleSize = 0.28,
		speed = { 0.2, 0.7 },
	},
})
