--!strict
-- Distribución de Valle Copal (vertical slice). Coordenadas en studs, Y hacia arriba.
-- Composición: el Gran Nexo es el ancla visual; el spawn mira hacia él; el río separa
-- la plaza de los Lotes Hogar; la Linde de las Chinampas (combate) queda al oeste y
-- el Mirador de Biomas (portal a regiones futuras) detrás del árbol.
-- Lo compartimos con el cliente y con el prototipo web para mantener una sola fuente.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type Vec = { number } -- {x, y, z}

return Freeze.deep({
	MaxPlayers = 6,
	SpawnPoint = { 0, 3, 34 },
	SpawnRadius = 10,

	GranNexo = {
		position = { 0, 0, -36 },
		trunkHeight = 58,
		trunkRadius = 9,
		canopyRadius = 38,
		interactRadius = 26, -- un toque en el tronco abre el menú (móvil)
	},

	Plaza = { center = { 0, 0, 8 }, radius = 30 },

	-- Huevos iniciales: junto al árbol, en arco frente al spawn.
	StarterEggPedestals = {
		EggBrasa = { -9, 0, -6 },
		EggBarro = { 0, 0, -9 },
		EggGreca = { 9, 0, -6 },
	},
	EggInteractRadius = 12,

	-- Estaciones alrededor del árbol (p. 11). Solo "Despensa" funciona en Fase 1;
	-- el resto son espacios reservados con su señalización.
	Stations = {
		Despensa = { position = { -34, 0, -20 }, label = "Despensa del Gabinete", implemented = true, radius = 14 },
		Mirador = { position = { 26, 0, -64 }, label = "Mirador de Biomas", implemented = false, radius = 14 },
		Criadero = { position = { -30, 0, -60 }, label = "Criadero", implemented = false, radius = 14 },
		PortalArenas = { position = { 38, 0, -28 }, label = "Portal de Arenas", implemented = false, radius = 14 },
		Tablon = { position = { -40, 0, 6 }, label = "Tablón de Encargos", implemented = false, radius = 12 },
		Circulo = { position = { 40, 0, 6 }, label = "Círculo de Encuentro", implemented = false, radius = 12 },
		RepisaCofres = { position = { 0, 0, -82 }, label = "Repisa de Cofres", implemented = false, radius = 12 },
	},

	-- Portal visual hacia biomas futuros (Mirador), detrás del árbol.
	BiomeGates = {
		{ biome = "MareaCoralina", position = { 46, 0, -96 } },
		{ biome = "CumbreBrasa", position = { 16, 0, -108 } },
		{ biome = "MesetaFulgor", position = { -16, 0, -108 } },
		{ biome = "VeloAstral", position = { -46, 0, -96 } },
	},

	-- Río y chinampas
	River = {
		points = { { -150, 0, 70 }, { -70, 0, 62 }, { 0, 0, 66 }, { 70, 0, 58 }, { 150, 0, 70 } },
		width = 18,
	},
	Bridges = { { 0, 0, 64 }, { 104, 0, 62 } },

	-- Lotes Hogar: una fila al sur del río. Cada jugador recibe uno al entrar.
	Lots = {
		size = { 44, 44 },
		positions = {
			{ -96, 0, 112 },
			{ -48, 0, 112 },
			{ 0, 0, 112 },
			{ 48, 0, 112 },
			{ 96, 0, 112 },
			{ 144, 0, 112 },
		},
		-- Desplazamientos relativos al centro del lote
		habitatOffset = { 0, 0, -4 },
		slotOffsets = { { -9, 0, -10 }, { 9, 0, -10 }, { -9, 0, 4 }, { 9, 0, 4 } },
		collectorOffset = { 16, 0, 14 },
		incubatorOffset = { -16, 0, 14 },
		vitrinaOffset = { 0, 0, 18 },
		interactRadius = 34,
	},

	-- Linde de las Chinampas: tres Opacos en niebla gris a lo largo de un sendero.
	Encounters = {
		Encounter1 = { position = { -78, 0, 10 }, radius = 18 },
		Encounter2 = { position = { -104, 0, -20 }, radius = 18 },
		Encounter3 = { position = { -122, 0, -56 }, radius = 18 },
	},

	-- Puntos de viaje rápido del menú del árbol (el menú lleva a la estación, no la
	-- usa a distancia: el santuario y el combate siguen siendo lugares físicos).
	TravelPoints = {
		Plaza = { 0, 3, 30 },
		LoteHogar = "PlayerLot",
		Linde = { -66, 3, 18 },
		Despensa = { -26, 3, -14 },
	},
})
