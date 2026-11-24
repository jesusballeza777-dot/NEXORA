--!strict
-- Paisaje de Valle Copal (Fase 3 · docs/WORLD_BUILDING.md). Datos, no lógica:
-- Server/World/Landform los convierte en rellenos de Terrain y Server/World/* en Parts.
-- Las posiciones de juego (spawn, estaciones, lotes, Linde) siguen en Config/World;
-- aquí solo vive lo visual: relieve, agua, barrios, flora destacada y vida ambiental.
-- Coordenadas en studs, Y hacia arriba. El valle jugable queda a Y = 0 (plano).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	-- Suelo base: un bloque de pasto con la superficie en Y = 0
	Ground = { center = { 0, -8, 0 }, size = { 840, 16, 840 } },

	-- Colinas del cuenco: varias bolas superpuestas por colina (nunca domos sueltos).
	-- { x, y, z, radio, material }. La cima queda en y + radio.
	Hills = {
		-- Norte: telón detrás de las Puertas de los biomas
		{ -10, -70, -252, 140, "Grass" },
		{ 78, -60, -228, 110, "Grass" },
		{ -98, -52, -218, 106, "Grass" },
		{ 28, 14, -196, 40, "LeafyGrass" },
		{ -62, 8, -186, 34, "LeafyGrass" },
		{ 140, -60, -200, 100, "Grass" },
		-- Este: macizo de la cascada y ladera de las terrazas
		{ 292, -62, 24, 122, "Grass" },
		{ 262, -50, -70, 104, "Grass" },
		{ 264, -40, 122, 96, "Grass" },
		{ 232, 6, 6, 34, "LeafyGrass" },
		-- Sur: lomas suaves detrás de los lotes
		{ -72, -56, 268, 112, "Grass" },
		{ 58, -52, 254, 102, "Grass" },
		{ 182, -46, 246, 96, "Grass" },
		{ -176, -42, 220, 92, "Grass" },
		{ -18, 12, 214, 32, "LeafyGrass" },
		{ 116, 6, 206, 30, "LeafyGrass" },
		-- Oeste: la Linde, más áspera
		{ -272, -50, -40, 110, "Grass" },
		{ -280, -42, 66, 96, "Grass" },
		{ -238, -46, -142, 96, "Grass" },
		{ -246, -40, 156, 86, "Grass" },
		-- Anillo exterior: cierra el horizonte (en Roblox detrás no hay nada)
		{ 0, -120, -430, 210, "Grass" },
		{ 330, -120, -200, 200, "Grass" },
		{ 400, -120, 140, 200, "Grass" },
		{ 120, -120, 420, 210, "Grass" },
		{ -220, -120, 390, 200, "Grass" },
		{ -420, -120, 60, 210, "Grass" },
		{ -320, -120, -300, 200, "Grass" },
	},

	LumpSeed = 6061, -- lomas satélite sobre cada colina (Landform.lumps)

	-- Afloramientos sobre las laderas: { x, z, radio, cuánto asoman, material }.
	-- La altura se calcula sobre la superficie de las colinas (Landform).
	Outcrops = {
		{ -40, -176, 9, 6, "Rock" },
		{ 36, -160, 7, 4, "Rock" },
		{ -128, -150, 8, 5, "Rock" },
		{ 96, -150, 6, 4, "Rock" },
		{ -186, -24, 11, 7, "Basalt" },
		{ -196, 20, 9, 6, "Basalt" },
		{ -176, -92, 10, 6, "Basalt" },
		{ -168, -60, 6, 4, "Basalt" },
		{ -205, 100, 8, 5, "Rock" },
		{ 210, 120, 8, 5, "Rock" },
		{ -40, 190, 7, 4, "Rock" },
		{ 150, 180, 6, 4, "Rock" },
	},

	-- Lomas bajas dentro del valle (lejos de las zonas de juego): { x, z, radio, altura }
	Mounds = {
		{ -78, -100, 22, 3 },
		{ 84, -92, 20, 2.5 },
		{ -40, 168, 22, 3 },
		{ 70, 166, 18, 2.5 },
		{ 196, -10, 16, 2 },
		{ -150, 120, 18, 2.5 },
	},

	-- Terrazas de cultivo en la ladera noreste (anillos escalonados con muro de piedra)
	Terraces = {
		center = { 178, -98 },
		rings = 6,
		outerRadius = 72,
		step = 9, -- ancho de cada terraza
		rise = 4, -- altura de cada escalón
		wall = 2.5, -- borde de piedra visible
		jitter = 3, -- desplazamiento de cada anillo (que no sea un pastel perfecto)
		cap = { 178, 6, -102, 22 },
		-- Arco que mira al valle (grados, como atan2(z, x) desde el centro)
		visibleArc = { 105, 215 },
	},

	-- Río: el trazado vive en Config/World.River; aquí, la sección de terreno
	River = {
		waterLevel = -1.2, -- superficie del agua
		bed = -5, -- fondo
		bank = 4.5, -- orilla de barro a cada lado
		sampleStep = 4,
		sandBars = { { 30, 50, 5 }, { -50, 76, 5 }, { 128, 80, 4 }, { 78, 44, 4 } },
	},

	-- Cascada: el río nace en el macizo del este y cae desde un saliente de roca
	Waterfall = {
		cliff = { center = { 202, 11, 46 }, size = { 32, 22, 60 } },
		ledge = { center = { 184.5, 15.5, 46 }, size = { 5, 3, 14 } },
		channel = { from = { 240, 46 }, to = { 182, 46 }, width = 9, floor = 16, water = 19.5 },
		fall = { center = { 180.5, 9.1, 46 }, size = { 4, 20.6, 9 } },
		pool = { center = { 170, 48 }, radius = 13 },
		rocks = {
			{ 188, 4, 28, 8 },
			{ 189, 12, 66, 9 },
			{ 186, 2, 36, 5 },
			{ 185, 2, 57, 5 },
			{ 160, -1, 38, 3.5 },
			{ 178, -1, 62, 3 },
			{ 196, 20, 24, 7 },
			{ 200, 21, 70, 8 },
			{ 192, 18, 56, 5 },
			{ 194, 19, 34, 5 },
			{ 212, 22, 52, 9 },
		},
	},

	-- Lago de las Chinampas, al oeste (círculos de agua) e islas de cultivo
	Lagoon = {
		circles = {
			{ -118, 56, 18 },
			{ -140, 50, 20 },
			{ -163, 58, 20 },
			{ -148, 70, 16 },
			{ -128, 70, 12 },
		},
		islands = {
			{ center = { -126, 49 }, size = { 24, 10 }, yaw = 6 },
			{ center = { -153, 49 }, size = { 20, 10 }, yaw = -5 },
			{ center = { -128, 67 }, size = { 22, 10 }, yaw = -3 },
			{ center = { -156, 67 }, size = { 18, 10 }, yaw = 4 },
		},
		islandTop = 0.6,
		dock = { -101, 38 },
	},

	-- Caminos de tierra (Terrain.Ground al ras): polilíneas { ancho, {x, z}… }
	Paths = {
		{ 9, { 0, 36 }, { 0, 52 } }, -- plaza → puente principal
		{ 9, { 0, 76 }, { 0, 87 } },
		{ 7, { -110, 87 }, { 168, 87 } }, -- camino de los lotes
		{ 10, { 26, 16 }, { 52, 18 }, { 124, 18 } }, -- calle del mercado
		{ 7, { 106, 24 }, { 104, 50 } }, -- mercado → puente del este
		{ 7, { 104, 74 }, { 104, 87 } },
		{ 7, { -28, 14 }, { -52, 16 }, { -74, 12 }, { -92, -4 }, { -104, -20 }, { -114, -38 }, { -122, -56 } }, -- Linde
		{ 5, { -60, 15 }, { -86, 28 }, { -100, 36 } }, -- embarcadero
		{ 6, { 30, -74 }, { 30, -88 }, { 0, -96 }, { -30, -90 } }, -- explanada de las Puertas
		{ 5, { 140, 4 }, { 132, -30 }, { 118, -52 } }, -- taller → terrazas
	},

	-- Manchas de material al ras (Linde gris, tierra gastada): { x, z, radio, material }
	Patches = {
		{ 0, 8, 33, "Ground" }, -- borde gastado de la plaza
		{ -78, 10, 15, "Slate" },
		{ -104, -20, 15, "Slate" },
		{ -122, -56, 15, "Slate" },
		{ -92, -30, 9, "Basalt" },
		{ -136, -30, 10, "Basalt" },
		{ -100, 12, 7, "Basalt" },
		{ -128, -78, 9, "Basalt" },
		{ 0, -36, 36, "LeafyGrass" }, -- césped tierno al pie del árbol
	},

	-- Torre del Nexo: el árbol y sus siete estaciones
	Torre = {
		slabRings = { { 10.5, 14.5 }, { 14.5, 19 } }, -- losas del basamento (radios)
		walkway = { inner = 20, outer = 33 }, -- calzada del Gabinete
		-- Cada estación se construye un poco hacia fuera (deja libre la calzada) y mira a `face`
		stations = {
			Despensa = { outward = 3, face = "tree" },
			Criadero = { outward = 7, face = "tree" },
			Mirador = { outward = 6, face = "tree" },
			PortalArenas = { outward = 2, face = "tree" },
			RepisaCofres = { outward = 2, face = "tree" },
			Tablon = { outward = 0, face = "plaza" },
			Circulo = { outward = 0, face = "plaza" },
		},
	},

	-- El Gabinete que Camina: ruta circular alrededor del Gran Nexo (la recorre el cliente)
	Gabinete = {
		radius = 27,
		dockStation = "Despensa", -- descansa frente a su despensa
		speed = 2.2, -- studs por segundo
		rest = 34, -- segundos de descanso en la despensa por vuelta
		turn = 3, -- segundos para girar al salir y al llegar
		stride = 3.2, -- studs recorridos por ciclo de paso (las patas no patinan)
		halfSpan = 10.1, -- media envergadura de las patas (calzada libre)
	},

	-- Barrio de los Oficios (este): puestos del mercado y taller
	Market = {
		stalls = {
			{ kind = "Cantaros", position = { 62, 0, 6 }, face = { 62, 18 } },
			{ kind = "Frutas", position = { 84, 0, 5 }, face = { 84, 18 } },
			{ kind = "Comal", position = { 106, 0, 6 }, face = { 106, 18 } },
			{ kind = "Canastas", position = { 72, 0, 31 }, face = { 72, 18 } },
			{ kind = "Flores", position = { 94, 0, 31 }, face = { 94, 18 } },
		},
		papel = { { { 74, 10 }, { 74, 27 } }, { { 98, 10 }, { 98, 27 } } },
	},
	Workshop = { position = { 138, 0, 15 }, face = { 110, 15 } },

	-- Plaza: estela, bancas, faroles y papel picado alto
	Plaza = {
		estela = { -15, 22 },
		benches = { { -27, 12 }, { 27, 12 }, { -18, 34 }, { 18, 34 } },
		lanterns = { { -21, 28 }, { 21, 28 }, { -28, -2 }, { 28, -2 } },
		papelHeight = 15,
		papelStrings = { { { -31, 22 }, { 31, 22 } }, { { -31, 4 }, { 31, 4 } } },
	},

	-- Árboles protagonistas que encuadran las vistas (además del reparto con semilla)
	HeroTrees = {
		{ species = "Sabino", x = -62, z = -14, scale = 1.15 },
		{ species = "Sabino", x = 66, z = -52, scale = 1.0 },
		{ species = "Sabino", x = -52, z = 92, scale = 0.95 },
		{ species = "Colorin", x = 40, z = 40, scale = 1.0 },
		{ species = "Colorin", x = -42, z = 38, scale = 0.9 },
		{ species = "Copal", x = 150, z = 40, scale = 1.1 },
		{ species = "Sabino", x = 178, z = -102, scale = 1.2 },
	},

	-- Vida ambiental (la anima el cliente: Client/Controllers/AmbientLifeController)
	Life = {
		budget = { partsPerFrame = 520, refresh = 0.5 },
		-- Distancias de LOD por tipo: completo hasta `near`, a media frecuencia hasta `far`
		lod = {
			sway = { near = 60, far = 140 },
			birds = { near = 120, far = 320 },
			fish = { near = 60, far = 140 },
			butterflies = { near = 50, far = 110 },
			heart = { near = 90, far = 220 },
			gabinete = { near = 120, far = 260 },
		},
		flocks = {
			{ center = { 0, 96, -36 }, radius = 46, count = 7, speed = 0.11, seed = 3 },
			{ center = { 118, 58, -48 }, radius = 40, count = 6, speed = -0.14, seed = 9 },
		},
		fish = {
			{ origin = { -140, 60 }, heading = 20, period = 9, offset = 0 },
			{ origin = { -124, 77 }, heading = 200, period = 12, offset = 4 },
			{ origin = { 28, 58 }, heading = 160, period = 11, offset = 7 },
			{ origin = { 152, 59 }, heading = 340, period = 14, offset = 2 },
		},
		butterflies = {
			{ center = { -36, 2, 30 }, radius = 7, count = 4, seed = 2 },
			{ center = { 0, 2, 96 }, radius = 9, count = 4, seed = 5 },
			{ center = { -142, 2, 58 }, radius = 10, count = 4, seed = 8 },
		},
		sway = { lantern = { amplitude = 0.07, speed = 1.3 }, papel = { amplitude = 0.32, speed = 2.4 } },
		heart = { bpm = 52, scale = 0.09 },
	},
})
