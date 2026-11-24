--!strict
-- Dirección de arte de los cinco biomas (Fase 3). Datos, no lógica.
--
-- Qué hay aquí, por bioma:
--   · paleta con la función de cada color (pigmento, emisivo o acento del elemento);
--   · preajustes de luz por momento (Tarde, Crepusculo, Noche) con Lighting, Atmosphere,
--     ColorCorrection, Bloom, SunRays y Clouds;
--   · terreno (material base de Roblox, nombre de la MaterialVariant y color), agua y niebla;
--   · la muestra ambiental (parcela de 120×120 studs) con su landmark, recorrido y presupuesto.
--
-- Estado:
--   · ValleCopal parte de Config/Ambience.luau (lo que construye ValleBuilder hoy) con los
--     ajustes propuestos en docs/LIGHTING_DIRECTION.md §9.
--   · Los otros cuatro biomas son PROPUESTA de arte y esperan aprobación humana.
--   · Nadie aplica este archivo todavía; Ambience.luau sigue mandando en el juego.
--   · Las MaterialVariant nombradas aquí no existen aún en Roblox: son el plan de
--     docs/MATERIAL_LIBRARY.md §5.
--
-- Reglas que comprueba tests/Unit/BiomeArt.spec.luau (Biblia visual, docs/ART_BIBLE_GENESIS.md):
--   · pigmentos ≤ 70 % de saturación (HSV); los emisivos y los acentos del elemento van aparte;
--   · Atmosphere.Density entre 0,30 y 0,38; bloom ≤ 0,6 con umbral ≥ 0,9;
--   · ColorCorrection con contraste +0,05…+0,10 y saturación cercana a 0.
--
-- Colores en RGB 0-255, como Ambience. La paleta y el terreno llevan además su hex
-- (es el que citan los documentos); el RGB se deriva del hex para que no se separen.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type RGB = { number }
export type BiomeId = "ValleCopal" | "MareaCoralina" | "CumbreBrasa" | "MesetaFulgor" | "VeloAstral"
export type MomentId = "Tarde" | "Crepusculo" | "Noche"
-- Pigmento: superficie (≤ 70 % de saturación) · Emisivo: luz (Neon, PointLight, partículas)
-- · Acento: color de elemento o señal (puede pasar del 70 %, siempre en piezas pequeñas).
export type SwatchKind = "Pigmento" | "Emisivo" | "Acento"

export type Swatch = { id: string, hex: string, rgb: RGB, kind: SwatchKind, role: string }

export type LightingPreset = {
	brightness: number,
	clockTime: number,
	geographicLatitude: number,
	ambient: RGB,
	outdoorAmbient: RGB,
	colorShiftTop: RGB,
	colorShiftBottom: RGB,
	environmentDiffuseScale: number,
	environmentSpecularScale: number,
	shadowSoftness: number,
	exposureCompensation: number,
}

export type AtmospherePreset = {
	density: number,
	offset: number,
	color: RGB,
	decay: RGB,
	glare: number,
	haze: number,
}

export type ColorCorrectionPreset = { brightness: number, contrast: number, saturation: number, tintColor: RGB }
export type BloomPreset = { intensity: number, size: number, threshold: number }
export type SunRaysPreset = { intensity: number, spread: number }
export type CloudsPreset = { cover: number, density: number, color: RGB }

export type Preset = {
	label: string,
	Lighting: LightingPreset,
	Atmosphere: AtmospherePreset,
	ColorCorrection: ColorCorrectionPreset,
	Bloom: BloomPreset,
	SunRays: SunRaysPreset,
	Clouds: CloudsPreset,
}

-- material: nombre de Enum.Material de terreno · variant: MaterialVariant propuesta (MAT_...)
export type TerrainEntry = { material: string, variant: string, hex: string, rgb: RGB, role: string }

export type WaterLook = {
	color: RGB,
	transparency: number,
	reflectance: number,
	waveSize: number,
	waveSpeed: number,
}

export type Landmark = {
	id: string,
	name: string,
	description: string,
	size: { number }, -- {ancho X, alto Y, fondo Z} en studs
	position: { number }, -- centro de la base, relativo al centro de la parcela
	visibleFrom: number, -- studs a los que se reconoce su silueta
}

export type SampleBudget = {
	terrainFills: number,
	parts: number,
	lights: number,
	emitters: number,
	particlesPerSecond: number,
}

export type Sample = {
	plotSize: { number }, -- {X, Z} en studs
	landmark: Landmark,
	path: { { number } }, -- recorrido del jugador, de la entrada al landmark
	budget: SampleBudget,
}

export type BiomeArtDef = {
	id: BiomeId,
	name: string,
	status: string,
	elements: { string },
	guardian: string,
	defaultMoment: MomentId,
	palette: { Swatch },
	presets: { Tarde: Preset, Crepusculo: Preset, Noche: Preset },
	terrain: { TerrainEntry },
	water: WaterLook,
	fogColor: RGB,
	sample: Sample?,
}

local function rgb(r: number, g: number, b: number): RGB
	return { r, g, b }
end

local function hexToRgb(hex: string): RGB
	return {
		tonumber(string.sub(hex, 2, 3), 16) :: number,
		tonumber(string.sub(hex, 4, 5), 16) :: number,
		tonumber(string.sub(hex, 6, 7), 16) :: number,
	}
end

local function sw(id: string, hex: string, kind: SwatchKind, role: string): Swatch
	return { id = id, hex = hex, rgb = hexToRgb(hex), kind = kind, role = role }
end

local function ground(material: string, variant: string, hex: string, role: string): TerrainEntry
	return { material = material, variant = variant, hex = hex, rgb = hexToRgb(hex), role = role }
end

local ById: { [string]: BiomeArtDef } = {}

-- ---------------------------------------------------------------------------
-- Valle Copal · centro del mundo · Flora, Tierra y Aire · Copalia
-- ---------------------------------------------------------------------------
ById.ValleCopal = {
	id = "ValleCopal",
	name = "Valle Copal",
	status = "Existente (Config/Ambience.luau) con ajustes PROPUESTOS",
	elements = { "Flora", "Tierra", "Aire" },
	guardian = "Copalia, la Garza de Raíces",
	defaultMoment = "Tarde",
	palette = {
		sw("copal", "#E8A848", "Pigmento", "Copal: escalonados de la plaza, toldos, interfaz"),
		sw("copalLuz", "#FFC460", "Emisivo", "Faroles, corazón del Gran Nexo, vetas de luz"),
		sw("jade", "#3E967A", "Pigmento", "Agua de chinampa, azulejo, acciones de cuidado"),
		sw(
			"jadeSombra",
			"#2F6E5C",
			"Pigmento",
			"Sombra fría de referencia (de ella salen OutdoorAmbient y ColorShift_Bottom)"
		),
		sw("turquesa", "#4FA9A3", "Pigmento", "Río, azulejos, cintas de mercado"),
		sw("hojaCalida", "#7FA650", "Pigmento", "Pasto y copas al sol"),
		sw("hojaProfunda", "#3B6E44", "Pigmento", "Copas en sombra, sotobosque"),
		sw("beige", "#D9C9A8", "Pigmento", "Piedra clara de la plaza, adobe encalado"),
		sw("ocre", "#C08A44", "Pigmento", "Tierra de camino, petates, tejas viejas"),
		sw("barro", "#B06240", "Pigmento", "Adobe rojo, cerámica, tejas"),
		sw("corteza", "#60463A", "Pigmento", "Gran Nexo, vigas, troncos"),
		sw("cacao", "#3A271D", "Pigmento", "Sombra de la arquitectura, interiores"),
		sw("cempasuchil", "#E6964A", "Pigmento", "Flores de cempasúchil (bajo el tope de saturación)"),
		sw("bugambilia", "#D6488C", "Pigmento", "Bugambilias y papel picado"),
	},
	presets = {
		Tarde = {
			label = "Tarde dorada (por defecto)",
			Lighting = {
				brightness = 2.4,
				clockTime = 15.8, -- hoy 16.6; ~30° de sol (Genesis §7)
				geographicLatitude = 23,
				ambient = rgb(60, 64, 66),
				outdoorAmbient = rgb(124, 136, 134), -- hoy (150, 128, 112): sombras frías, no pardas
				colorShiftTop = rgb(236, 200, 150),
				colorShiftBottom = rgb(50, 80, 82),
				environmentDiffuseScale = 0.55,
				environmentSpecularScale = 0.5,
				shadowSoftness = 0.2,
				exposureCompensation = 0,
			},
			Atmosphere = {
				density = 0.32,
				offset = 0.12,
				color = rgb(232, 196, 160),
				decay = rgb(128, 140, 150), -- hoy (150, 110, 120): los planos lejanos se enfrían
				glare = 0.35,
				haze = 1.4,
			},
			ColorCorrection = { brightness = 0, contrast = 0.07, saturation = 0.03, tintColor = rgb(255, 246, 234) },
			Bloom = { intensity = 0.55, size = 28, threshold = 1.6 },
			SunRays = { intensity = 0.06, spread = 0.6 },
			Clouds = { cover = 0.52, density = 0.55, color = rgb(255, 238, 226) },
		},
		Crepusculo = {
			label = "Crepúsculo: faroles encendidos",
			Lighting = {
				brightness = 1.8,
				clockTime = 17.6,
				geographicLatitude = 23,
				ambient = rgb(56, 52, 64),
				outdoorAmbient = rgb(112, 108, 132),
				colorShiftTop = rgb(255, 160, 104),
				colorShiftBottom = rgb(56, 64, 100),
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.55,
				shadowSoftness = 0.3,
				exposureCompensation = 0.1,
			},
			Atmosphere = {
				density = 0.35,
				offset = 0.18,
				color = rgb(236, 164, 124),
				decay = rgb(96, 92, 136),
				glare = 1.0,
				haze = 2.0,
			},
			ColorCorrection = { brightness = 0, contrast = 0.08, saturation = 0, tintColor = rgb(255, 238, 228) },
			Bloom = { intensity = 0.6, size = 32, threshold = 1.2 },
			SunRays = { intensity = 0.1, spread = 0.4 },
			Clouds = { cover = 0.6, density = 0.5, color = rgb(244, 196, 178) },
		},
		Noche = {
			label = "Noche de luna: el copal guía",
			Lighting = {
				brightness = 1.2,
				clockTime = 22,
				geographicLatitude = 23,
				ambient = rgb(42, 46, 62),
				outdoorAmbient = rgb(82, 96, 124),
				colorShiftTop = rgb(150, 170, 210),
				colorShiftBottom = rgb(30, 40, 64),
				environmentDiffuseScale = 0.4,
				environmentSpecularScale = 0.4,
				shadowSoftness = 0.35,
				exposureCompensation = 0.3,
			},
			Atmosphere = {
				density = 0.33,
				offset = 0.1,
				color = rgb(92, 110, 150),
				decay = rgb(40, 48, 80),
				glare = 0,
				haze = 1.2,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.06, saturation = -0.05, tintColor = rgb(226, 232, 255) },
			Bloom = { intensity = 0.6, size = 34, threshold = 1.0 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.4, density = 0.4, color = rgb(118, 128, 160) },
		},
	},
	terrain = {
		ground("Grass", "MAT_ValleCopal_Pasto", "#68A054", "Pasto con Terrain.Decoration (color actual de Ambience)"),
		ground("LeafyGrass", "MAT_ValleCopal_Sotobosque", "#4E8046", "Bajo los árboles y en las lindes"),
		ground("Mud", "MAT_ValleCopal_LodoChinampa", "#765A44", "Orillas del río y chinampas (color actual)"),
		ground("Ground", "MAT_ValleCopal_TierraCamino", "#9C7852", "Caminos gastados donde más se pisa"),
		ground("Cobblestone", "MAT_ValleCopal_Calzada", "#AA9E8A", "Calzadas hacia las puertas de los biomas"),
	},
	water = { color = rgb(70, 150, 150), transparency = 0.6, reflectance = 0.3, waveSize = 0.08, waveSpeed = 6 },
	fogColor = rgb(232, 196, 160),
	sample = nil, -- el Valle ya existe: lo construye ValleBuilder
}

-- ---------------------------------------------------------------------------
-- Marea Coralina · arrecifes, manglares y cenotes · Agua, Mente y Astral · Marejadra
-- ---------------------------------------------------------------------------
ById.MareaCoralina = {
	id = "MareaCoralina",
	name = "Marea Coralina",
	status = "PROPUESTA",
	elements = { "Agua", "Mente", "Astral" },
	guardian = "Marejadra, el Hipocampo de Coral",
	defaultMoment = "Tarde",
	palette = {
		sw("turquesa", "#38A8A6", "Pigmento", "Agua somera, azulejo, color que define el bioma"),
		sw("turquesaClara", "#8FD3C8", "Pigmento", "Espuma, arena mojada, reflejos"),
		sw("coral", "#E07A5F", "Pigmento", "Coral vivo, acentos cálidos"),
		sw("coralClaro", "#F2B8A2", "Pigmento", "Coral a contraluz, conchas"),
		sw("azulProfundo", "#28507A", "Pigmento", "Fondo del cenote, agua profunda"),
		sw("azulNoche", "#1C3352", "Pigmento", "Cuevas y sombras sumergidas"),
		sw("violeta", "#6E5A9E", "Pigmento", "Medusas y perlas en sombra (Mente)"),
		sw("arena", "#E3D3B0", "Pigmento", "Arena de arrecife"),
		sw("caliza", "#BFB59E", "Pigmento", "Paredes del cenote y ruinas"),
		sw("mangle", "#5C6B3E", "Pigmento", "Raíces y copas del manglar"),
		sw("perla", "#DDF4F0", "Emisivo", "Perlas de Marejadra encendidas"),
		sw("bioluz", "#5FE3D0", "Emisivo", "Medusas y túneles de luz"),
	},
	presets = {
		Tarde = {
			label = "Mediodía tardío: la luz entra en el agua",
			Lighting = {
				brightness = 2.6,
				clockTime = 14.6,
				geographicLatitude = 18,
				ambient = rgb(52, 66, 72),
				outdoorAmbient = rgb(112, 140, 150),
				colorShiftTop = rgb(240, 226, 200),
				colorShiftBottom = rgb(40, 92, 104),
				environmentDiffuseScale = 0.6,
				environmentSpecularScale = 0.75,
				shadowSoftness = 0.3,
				exposureCompensation = 0,
			},
			Atmosphere = {
				density = 0.33,
				offset = 0.08,
				color = rgb(172, 212, 216),
				decay = rgb(78, 108, 150),
				glare = 0.5,
				haze = 1.8,
			},
			ColorCorrection = { brightness = 0, contrast = 0.06, saturation = 0.02, tintColor = rgb(240, 252, 255) },
			Bloom = { intensity = 0.5, size = 30, threshold = 1.3 },
			SunRays = { intensity = 0.1, spread = 0.5 },
			Clouds = { cover = 0.42, density = 0.45, color = rgb(246, 250, 255) },
		},
		Crepusculo = {
			label = "Crepúsculo coral",
			Lighting = {
				brightness = 1.8,
				clockTime = 17.6,
				geographicLatitude = 18,
				ambient = rgb(56, 50, 70),
				outdoorAmbient = rgb(108, 100, 140),
				colorShiftTop = rgb(255, 168, 140),
				colorShiftBottom = rgb(48, 56, 110),
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.7,
				shadowSoftness = 0.3,
				exposureCompensation = 0.1,
			},
			Atmosphere = {
				density = 0.35,
				offset = 0.16,
				color = rgb(234, 166, 150),
				decay = rgb(72, 66, 128),
				glare = 0.9,
				haze = 2.0,
			},
			ColorCorrection = { brightness = 0, contrast = 0.08, saturation = 0, tintColor = rgb(255, 240, 240) },
			Bloom = { intensity = 0.55, size = 32, threshold = 1.2 },
			SunRays = { intensity = 0.1, spread = 0.4 },
			Clouds = { cover = 0.55, density = 0.5, color = rgb(240, 186, 186) },
		},
		Noche = {
			label = "Noche bioluminiscente",
			Lighting = {
				brightness = 1.1,
				clockTime = 23,
				geographicLatitude = 18,
				ambient = rgb(30, 44, 64),
				outdoorAmbient = rgb(60, 92, 120),
				colorShiftTop = rgb(130, 176, 210),
				colorShiftBottom = rgb(24, 48, 70),
				environmentDiffuseScale = 0.4,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.35,
				exposureCompensation = 0.35,
			},
			Atmosphere = {
				density = 0.32,
				offset = 0.1,
				color = rgb(60, 104, 140),
				decay = rgb(22, 38, 70),
				glare = 0,
				haze = 1.2,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.07, saturation = -0.03, tintColor = rgb(220, 240, 255) },
			Bloom = { intensity = 0.6, size = 36, threshold = 0.95 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.35, density = 0.4, color = rgb(90, 120, 150) },
		},
	},
	terrain = {
		ground("Sand", "MAT_MareaCoralina_ArenaArrecife", "#D9C8A2", "Playas, bancos de arena del arrecife"),
		ground("Limestone", "MAT_MareaCoralina_CalizaCenote", "#BDB39A", "Paredes y bóvedas del cenote"),
		ground("Salt", "MAT_MareaCoralina_Coral", "#C98A78", "Roca de coral (desaturada; el coral vivo son mallas)"),
		ground("Pavement", "MAT_MareaCoralina_LosaSumergida", "#8A9690", "Losas de las ruinas sumergidas"),
	},
	water = { color = rgb(56, 158, 156), transparency = 0.78, reflectance = 0.35, waveSize = 0.12, waveSpeed = 8 },
	fogColor = rgb(172, 212, 216),
	sample = {
		plotSize = { 120, 120 },
		landmark = {
			id = "WD_MareaCoralina_ArcoMarejadra_A",
			name = "Arco de Marejadra",
			description = "Arco de coral sobre la boca del cenote, con perlas que se encienden al restaurar a Marejadra",
			size = { 36, 30, 14 },
			position = { 0, 0, -30 },
			visibleFrom = 120,
		},
		path = { { 0, 0, 56 }, { -30, 0, 22 }, { -20, 0, -4 }, { 0, 0, -10 }, { 0, -6, -30 }, { 36, -6, -44 } },
		budget = { terrainFills = 30, parts = 380, lights = 5, emitters = 3, particlesPerSecond = 40 },
	},
}

-- ---------------------------------------------------------------------------
-- Cumbre Brasa · volcanes, hornos y forjas · Fuego, Metal y Tierra · Obsidárion
-- ---------------------------------------------------------------------------
ById.CumbreBrasa = {
	id = "CumbreBrasa",
	name = "Cumbre Brasa",
	status = "PROPUESTA",
	elements = { "Fuego", "Metal", "Tierra" },
	guardian = "Obsidárion, el Coloso de la Fragua",
	defaultMoment = "Tarde",
	palette = {
		sw("naranjaHorno", "#D68A48", "Pigmento", "Barro cocido al fuego, toldos de herrería"),
		sw("cobre", "#B8734A", "Pigmento", "Cobre martillado, calderos, canales"),
		sw("rojoVolcanico", "#9A4232", "Pigmento", "Roca volcánica oxidada, tejas de forja"),
		sw("piedraOscura", "#3E3A3C", "Pigmento", "Basalto, muros de forja"),
		sw("ceniza", "#7A7270", "Pigmento", "Ceniza, caminos, Opaco"),
		sw("oroCalido", "#D9A64E", "Pigmento", "Remates de latón y oro cálido"),
		sw("hojalata", "#A8A39A", "Pigmento", "Hojalata repujada de faroles y techos"),
		sw("barroHorno", "#A65A3A", "Pigmento", "Hornos de barro"),
		sw("obsidiana", "#1E1A22", "Pigmento", "Obsidiana de Obsidárion y de los filos"),
		sw("lava", "#FF7A2E", "Emisivo", "Lava domesticada y bocas de horno"),
		sw("brasa", "#FFB347", "Emisivo", "Brasas y chispas"),
	},
	presets = {
		Tarde = {
			label = "Atardecer naranja (Biblia p. 9)",
			Lighting = {
				brightness = 2.2,
				clockTime = 17.2,
				geographicLatitude = 20,
				ambient = rgb(60, 50, 52),
				outdoorAmbient = rgb(110, 98, 104),
				colorShiftTop = rgb(255, 172, 112),
				colorShiftBottom = rgb(120, 52, 32), -- rebote de la lava desde abajo
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.65,
				shadowSoftness = 0.25,
				exposureCompensation = 0,
			},
			Atmosphere = {
				density = 0.37,
				offset = 0.15,
				color = rgb(222, 144, 96),
				decay = rgb(92, 62, 64),
				glare = 0.8,
				haze = 2.4,
			},
			ColorCorrection = { brightness = 0, contrast = 0.09, saturation = 0, tintColor = rgb(255, 236, 220) },
			Bloom = { intensity = 0.55, size = 30, threshold = 1.2 },
			SunRays = { intensity = 0.12, spread = 0.5 },
			Clouds = { cover = 0.6, density = 0.6, color = rgb(230, 170, 140) },
		},
		Crepusculo = {
			label = "Crepúsculo de fragua",
			Lighting = {
				brightness = 1.6,
				clockTime = 17.6,
				geographicLatitude = 20,
				ambient = rgb(58, 42, 46),
				outdoorAmbient = rgb(100, 80, 92),
				colorShiftTop = rgb(255, 130, 80),
				colorShiftBottom = rgb(140, 50, 28),
				environmentDiffuseScale = 0.45,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.3,
				exposureCompensation = 0.15,
			},
			Atmosphere = {
				density = 0.38,
				offset = 0.2,
				color = rgb(214, 110, 78),
				decay = rgb(70, 44, 56),
				glare = 1.2,
				haze = 2.6,
			},
			ColorCorrection = { brightness = 0, contrast = 0.09, saturation = -0.02, tintColor = rgb(255, 228, 214) },
			Bloom = { intensity = 0.6, size = 32, threshold = 1.0 },
			SunRays = { intensity = 0.12, spread = 0.4 },
			Clouds = { cover = 0.65, density = 0.6, color = rgb(210, 120, 100) },
		},
		Noche = {
			label = "Noche de forjas encendidas",
			Lighting = {
				brightness = 0.9,
				clockTime = 22.5,
				geographicLatitude = 20,
				ambient = rgb(44, 34, 38),
				outdoorAmbient = rgb(78, 70, 90),
				colorShiftTop = rgb(140, 140, 180),
				colorShiftBottom = rgb(130, 48, 24),
				environmentDiffuseScale = 0.4,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.35,
				exposureCompensation = 0.3,
			},
			Atmosphere = {
				density = 0.35,
				offset = 0.12,
				color = rgb(110, 70, 70),
				decay = rgb(36, 26, 40),
				glare = 0,
				haze = 1.6,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.08, saturation = -0.04, tintColor = rgb(240, 226, 230) },
			Bloom = { intensity = 0.6, size = 36, threshold = 0.95 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.55, density = 0.55, color = rgb(90, 64, 64) },
		},
	},
	terrain = {
		ground("Basalt", "MAT_CumbreBrasa_Colada", "#3A3638", "Coladas frías y laderas del volcán"),
		ground(
			"CrackedLava",
			"MAT_CumbreBrasa_LavaDomada",
			"#5A3A30",
			"Lava domesticada (las grietas brillan con la textura)"
		),
		ground("Asphalt", "MAT_CumbreBrasa_Ceniza", "#5E5856", "Ceniza fina en caminos y patios"),
		ground("Brick", "MAT_CumbreBrasa_AdobeHorno", "#9C5A3C", "Montículos de adobe de los hornos"),
	},
	water = { color = rgb(96, 120, 110), transparency = 0.5, reflectance = 0.2, waveSize = 0.05, waveSpeed = 4 },
	fogColor = rgb(222, 144, 96),
	sample = {
		plotSize = { 120, 120 },
		landmark = {
			id = "WD_CumbreBrasa_FraguaMayor_A",
			name = "Fragua Mayor",
			description = "Horno de barro escalonado dentro de un cono volcánico, chimenea de cobre y escudo de comal en la boca",
			size = { 40, 48, 40 },
			position = { 0, 0, -28 },
			visibleFrom = 160,
		},
		path = { { 0, 0, 56 }, { 0, 0, 30 }, { 28, 2, 10 }, { 12, 6, -4 }, { 0, 8, -10 } },
		budget = { terrainFills = 34, parts = 420, lights = 6, emitters = 4, particlesPerSecond = 60 },
	},
}

-- ---------------------------------------------------------------------------
-- Meseta Fulgor · tormentas, torres de cobre y talleres · Rayo, Artificio y Metal · Fulgorón
-- ---------------------------------------------------------------------------
ById.MesetaFulgor = {
	id = "MesetaFulgor",
	name = "Meseta Fulgor",
	status = "PROPUESTA",
	elements = { "Rayo", "Artificio", "Metal" },
	guardian = "Fulgorón, el Tigre del Trueno",
	defaultMoment = "Tarde",
	palette = {
		sw("azulTaller", "#4682CF", "Pigmento", "Esmalte de los talleres y señales"),
		sw("amarilloMaquina", "#E3C04A", "Pigmento", "Pintura de máquinas, franjas de aviso"),
		sw("cobre", "#B87A50", "Pigmento", "Torres y bobinas de cobre"),
		sw("patina", "#6FA08E", "Pigmento", "Pátina verde en los huecos del cobre"),
		sw("grisTormenta", "#6C7380", "Pigmento", "Roca y cielo bajo la tormenta"),
		sw("grisHierro", "#3E434D", "Pigmento", "Hierro, sombras de talleres"),
		sw("estrato", "#9C8A72", "Pigmento", "Estratos de la meseta"),
		sw("maderaMolino", "#7E6650", "Pigmento", "Aspas de molino y bancos de taller"),
		sw("azulArco", "#7FB8FF", "Emisivo", "Arcos eléctricos, bobinas cargadas"),
		sw("amarilloRayo", "#FFE36B", "Emisivo", "Rayo y puntas encendidas"),
		sw("blancoDestello", "#F4F8FF", "Emisivo", "Destello del relámpago (≤ 0,1 s)"),
	},
	presets = {
		Tarde = {
			label = "Tormenta de tarde (perpetua)",
			Lighting = {
				brightness = 1.6,
				clockTime = 15.2,
				geographicLatitude = 30,
				ambient = rgb(58, 62, 72),
				outdoorAmbient = rgb(122, 128, 142),
				colorShiftTop = rgb(210, 214, 226),
				colorShiftBottom = rgb(60, 66, 84),
				environmentDiffuseScale = 0.7,
				environmentSpecularScale = 0.8,
				shadowSoftness = 0.6, -- cielo cubierto: sombras difusas
				exposureCompensation = 0.1,
			},
			Atmosphere = {
				density = 0.36,
				offset = 0.05,
				color = rgb(150, 160, 176),
				decay = rgb(68, 76, 100),
				glare = 0,
				haze = 2.0,
			},
			ColorCorrection = { brightness = 0, contrast = 0.1, saturation = -0.05, tintColor = rgb(236, 242, 255) },
			Bloom = { intensity = 0.6, size = 24, threshold = 1.1 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.88, density = 0.8, color = rgb(120, 126, 140) },
		},
		Crepusculo = {
			label = "Claro de tormenta al ponerse el sol",
			Lighting = {
				brightness = 1.3,
				clockTime = 17.6,
				geographicLatitude = 30,
				ambient = rgb(54, 52, 70),
				outdoorAmbient = rgb(106, 104, 130),
				colorShiftTop = rgb(230, 170, 120),
				colorShiftBottom = rgb(56, 60, 96),
				environmentDiffuseScale = 0.6,
				environmentSpecularScale = 0.8,
				shadowSoftness = 0.55,
				exposureCompensation = 0.15,
			},
			Atmosphere = {
				density = 0.37,
				offset = 0.1,
				color = rgb(170, 140, 130),
				decay = rgb(60, 60, 96),
				glare = 0.4,
				haze = 2.2,
			},
			ColorCorrection = { brightness = 0, contrast = 0.1, saturation = -0.04, tintColor = rgb(250, 236, 232) },
			Bloom = { intensity = 0.6, size = 26, threshold = 1.0 },
			SunRays = { intensity = 0.06, spread = 0.3 },
			Clouds = { cover = 0.85, density = 0.8, color = rgb(150, 120, 120) },
		},
		Noche = {
			label = "Noche eléctrica",
			Lighting = {
				brightness = 0.9,
				clockTime = 23.5,
				geographicLatitude = 30,
				ambient = rgb(34, 38, 54),
				outdoorAmbient = rgb(66, 76, 104),
				colorShiftTop = rgb(140, 160, 210),
				colorShiftBottom = rgb(30, 36, 60),
				environmentDiffuseScale = 0.45,
				environmentSpecularScale = 0.7,
				shadowSoftness = 0.5,
				exposureCompensation = 0.35,
			},
			Atmosphere = {
				density = 0.34,
				offset = 0.06,
				color = rgb(70, 80, 110),
				decay = rgb(26, 30, 52),
				glare = 0,
				haze = 1.6,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.09, saturation = -0.05, tintColor = rgb(226, 234, 255) },
			Bloom = { intensity = 0.6, size = 30, threshold = 0.95 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.85, density = 0.75, color = rgb(64, 70, 92) },
		},
	},
	terrain = {
		ground("Sandstone", "MAT_MesetaFulgor_Estrato", "#968470", "Estratos y cantiles de la meseta"),
		ground("Concrete", "MAT_MesetaFulgor_Caliche", "#8E8A82", "Costra pisada alrededor de los talleres"),
		ground("Glacier", "MAT_MesetaFulgor_Fulgurita", "#8C9AA8", "Placas vítreas de fulgurita donde cae el rayo"),
	},
	water = { color = rgb(84, 100, 112), transparency = 0.4, reflectance = 0.45, waveSize = 0.15, waveSpeed = 14 },
	fogColor = rgb(150, 160, 176),
	sample = {
		plotSize = { 120, 120 },
		landmark = {
			id = "WD_MesetaFulgor_TorreBobina_A",
			name = "Torre Bobina",
			description = "Torre de cobre con bobinas apiladas, pararrayos y un molino de aspas que gira al cargarse",
			size = { 28, 64, 16 },
			position = { 20, 0, -30 },
			visibleFrom = 200,
		},
		path = { { -40, 0, 56 }, { -30, 4, 22 }, { -10, 8, 0 }, { 10, 10, -14 }, { 20, 10, -22 } },
		budget = { terrainFills = 28, parts = 450, lights = 5, emitters = 3, particlesPerSecond = 40 },
	},
}

-- ---------------------------------------------------------------------------
-- Velo Astral · noche y cielos · Luz, Sombra, Mente y Astral · Noctelia
-- ---------------------------------------------------------------------------
ById.VeloAstral = {
	id = "VeloAstral",
	name = "Velo Astral",
	status = "PROPUESTA",
	elements = { "Luz", "Sombra", "Mente", "Astral" },
	guardian = "Noctelia, la Medusa del Velo",
	defaultMoment = "Noche",
	palette = {
		sw("azulProfundo", "#1E2A5A", "Pigmento", "Cielo y nubes en sombra"),
		sw("morado", "#5A3C8C", "Pigmento", "Nubes de noche, telas"),
		sw("indigo", "#2C2450", "Pigmento", "Sombras"),
		sw("turquesaAstral", "#3FA6B0", "Pigmento", "Telas y constelaciones apagadas"),
		sw("plata", "#C4C8D6", "Pigmento", "Postes, hilos, bordes de faroles"),
		sw("lavandaNube", "#9C98C8", "Pigmento", "Nube pisable iluminada"),
		sw("aurora", "#6FF0D2", "Emisivo", "Aurora (verde turquesa)"),
		sw("auroraVioleta", "#B48CFF", "Emisivo", "Aurora (violeta)"),
		sw("estrella", "#FFF4D6", "Emisivo", "Estrellas pisables"),
		sw("farol", "#FFC977", "Emisivo", "Faroles flotantes: el único cálido del Velo"),
	},
	presets = {
		Tarde = {
			label = "Hora azul",
			Lighting = {
				brightness = 1.6,
				clockTime = 18.4,
				geographicLatitude = 35,
				ambient = rgb(46, 46, 80),
				outdoorAmbient = rgb(92, 96, 146),
				colorShiftTop = rgb(180, 190, 240),
				colorShiftBottom = rgb(70, 54, 120),
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.4,
				exposureCompensation = 0.2,
			},
			Atmosphere = {
				density = 0.31,
				offset = 0.2,
				color = rgb(110, 112, 180),
				decay = rgb(40, 36, 90),
				glare = 0,
				haze = 1.2,
			},
			ColorCorrection = { brightness = 0, contrast = 0.07, saturation = 0, tintColor = rgb(232, 232, 255) },
			Bloom = { intensity = 0.55, size = 34, threshold = 1.0 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.4, density = 0.45, color = rgb(150, 150, 200) },
		},
		Crepusculo = {
			label = "Noche de aurora",
			Lighting = {
				brightness = 1.3,
				clockTime = 20.5,
				geographicLatitude = 35,
				ambient = rgb(40, 46, 76),
				outdoorAmbient = rgb(74, 100, 132),
				colorShiftTop = rgb(150, 220, 210),
				colorShiftBottom = rgb(70, 50, 120),
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.4,
				exposureCompensation = 0.3,
			},
			Atmosphere = {
				density = 0.31,
				offset = 0.22,
				color = rgb(80, 120, 150),
				decay = rgb(30, 30, 80),
				glare = 0,
				haze = 1.1,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.07, saturation = 0.02, tintColor = rgb(226, 246, 255) },
			Bloom = { intensity = 0.6, size = 36, threshold = 0.95 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.38, density = 0.42, color = rgb(110, 130, 170) },
		},
		Noche = {
			label = "Noche profunda (por defecto)",
			Lighting = {
				brightness = 1.4,
				clockTime = 0,
				geographicLatitude = 35,
				ambient = rgb(40, 36, 70),
				outdoorAmbient = rgb(72, 74, 122),
				colorShiftTop = rgb(170, 190, 240),
				colorShiftBottom = rgb(60, 40, 100),
				environmentDiffuseScale = 0.5,
				environmentSpecularScale = 0.6,
				shadowSoftness = 0.4,
				exposureCompensation = 0.4,
			},
			Atmosphere = {
				density = 0.3,
				offset = 0.25,
				color = rgb(90, 90, 160),
				decay = rgb(30, 26, 70),
				glare = 0,
				haze = 1.0,
			},
			ColorCorrection = { brightness = 0.02, contrast = 0.08, saturation = 0, tintColor = rgb(230, 228, 255) },
			Bloom = { intensity = 0.6, size = 36, threshold = 0.95 },
			SunRays = { intensity = 0, spread = 0.3 },
			Clouds = { cover = 0.35, density = 0.4, color = rgb(100, 96, 150) },
		},
	},
	terrain = {
		ground("Snow", "MAT_VeloAstral_Nube", "#B8B6DA", "Nubes pisables (cima de las islas)"),
		ground("Ice", "MAT_VeloAstral_Escarcha", "#9FB4D8", "Escarcha estelar en bordes y puentes"),
		ground("Rock", "MAT_VeloAstral_RocaIsla", "#4A4668", "Base de las islas flotantes"),
	},
	water = { color = rgb(34, 44, 92), transparency = 0.3, reflectance = 0.8, waveSize = 0.02, waveSpeed = 2 },
	fogColor = rgb(90, 90, 160),
	sample = {
		plotSize = { 120, 120 },
		landmark = {
			id = "WD_VeloAstral_TelarNoctelia_A",
			name = "Telar de Noctelia",
			description = "Marco de plata flotante del que cuelgan hilos de aurora; Noctelia lo teje al restaurarse",
			size = { 44, 40, 10 },
			position = { 0, 12, -24 },
			visibleFrom = 180,
		},
		path = { { 0, 0, 56 }, { -20, 4, 24 }, { -10, 8, 4 }, { 14, 8, -4 }, { 0, 12, -18 } },
		budget = { terrainFills = 24, parts = 320, lights = 6, emitters = 3, particlesPerSecond = 45 },
	},
}

local Order: { BiomeId } = { "ValleCopal", "MareaCoralina", "CumbreBrasa", "MesetaFulgor", "VeloAstral" }

local Moments: { MomentId } = { "Tarde", "Crepusculo", "Noche" }

-- Transiciones entre preajustes (docs/LIGHTING_DIRECTION.md §5). TweenService con estas curvas.
local Transitions = {
	easingStyle = "Sine",
	easingDirection = "InOut",
	momentSeconds = 8, -- Tarde → Crepúsculo → Noche
	zoneSeconds = 3, -- entrar en otro bioma por su puerta
	combatInSeconds = 0.8,
	combatOutSeconds = 1.2,
	bossPhaseSeconds = 1.2, -- igual que BattleController.dimLights hoy
	restoreSeconds = 5, -- un Ser Sagrado restaurado devuelve el color al bioma
}

-- Modificadores que se suman al preajuste activo (docs/LIGHTING_DIRECTION.md §7).
local Modifiers = {
	-- Combate: un poco más de contraste y el aura al 60 % (Biblia p. 26).
	Combate = { contrastAdd = 0.02, saturationAdd = -0.02, bloomIntensityScale = 0.8, auraScale = 0.6 },
	-- Fase 2 de Copalia (faroles apagados): oscurece sin perder la lectura de los combatientes.
	JefeFase2 = {
		brightness = -0.12,
		saturation = -0.15,
		contrastAdd = 0.03,
		tintColor = rgb(190, 196, 235),
		rimLightBrightness = 0.8,
		rimLightRange = 10,
	},
	-- Bioma opacado: gris con memoria del color (Genesis §4.1, regla 5).
	Opacado = {
		brightness = -0.05,
		saturation = -0.55,
		tintColor = rgb(214, 214, 220),
		atmosphereColor = rgb(150, 150, 160),
	},
	-- Relámpago de la Meseta Fulgor. Nunca más de 3 destellos por segundo (fotosensibilidad).
	Rayo = {
		brightnessAdd = 1.2,
		exposureAdd = 0.4,
		colorShiftTop = rgb(230, 240, 255),
		durationSeconds = 0.08,
		intervalSeconds = { 8, 20 },
		maxFlashesPerSecond = 3,
	},
	-- Cinemáticas: único uso de DepthOfField, con desenfoque mínimo.
	Cinematica = { farIntensity = 0.12, focusDistance = 18, inFocusRadius = 14, nearIntensity = 0 },
}

return Freeze.deep({
	Technology = "Future", -- se fija en el lugar, no por script (docs/LIGHTING_DIRECTION.md §2)
	Order = Order,
	Moments = Moments,
	ById = ById,
	Transitions = Transitions,
	Modifiers = Modifiers,
})
