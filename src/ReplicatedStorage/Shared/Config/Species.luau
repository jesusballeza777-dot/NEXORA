--!strict
-- SpeciesDefinition: datos compartidos de cada especie (nunca datos individuales).
-- Fuente: Tabla maestra (Biblia v5.0 p. 52–53) y fichas (p. 49–81).
-- Los atributos son los del Tallado a nivel 50; el Brote usa el 70 % (Config/Progression).
--
-- Estado de producción ("status"):
--   "VerticalSlice" -> jugable en Fase 1 (tiene talento, firma, visual blockout)
--   "Catalog"       -> datos de catálogo conservados para el Álbum y fases futuras

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type StatBlock = { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number }

export type SpeciesDef = {
	id: string,
	number: number,
	broteName: string,
	talladoName: string,
	epithet: string?,
	rarity: string,
	elements: { string },
	role: string,
	family: string,
	biome: string,
	stats: StatBlock,
	status: "VerticalSlice" | "Catalog",
	-- Solo especies jugables en la Fase 1:
	talent: string?,
	signature: string?,
	mythicMix: string?,
	concept: string?,
	broteDescription: string?,
	talladoDescription: string?,
	provenance: string?,
}

local Species: { [string]: SpeciesDef } = {}
local Order: { string } = {}

local function S(
	number: number,
	id: string,
	brote: string,
	tallado: string,
	rarity: string,
	elements: { string },
	role: string,
	family: string,
	biome: string,
	vid: number,
	atq: number,
	def: number,
	ese: number,
	vel: number
)
	assert(Species[id] == nil, "Especie duplicada: " .. id)
	Species[id] = {
		id = id,
		number = number,
		broteName = brote,
		talladoName = tallado,
		rarity = rarity,
		elements = elements,
		role = role,
		family = family,
		biome = biome,
		stats = { VID = vid, ATQ = atq, DEF = def, ESE = ese, VEL = vel },
		status = "Catalog",
	}
	table.insert(Order, id)
end

-- # · id · Brote · Tallado · rareza · elementos · rol · familia · bioma · VID ATQ DEF ESE VEL
-- stylua: ignore start
S(1, "kuachi", "Kuachi", "Ascuacho", "Comun", { "Fuego" }, "Atacante", "Cuadrúpedo", "ValleCopal", 19, 29, 14, 18, 20)
S(2, "xolumi", "Xolumi", "Xolossus", "Comun", { "Agua" }, "Soporte", "Anfibio", "ValleCopal", 24, 14, 19, 27, 16)
S(3, "teselo", "Teselo", "Mitlaxis", "Comun", { "Tierra" }, "Defensor", "Reptil", "ValleCopal", 25, 17, 28, 15, 15)
S(4, "comalu", "Comalú", "Magmadillo", "Comun", { "Fuego" }, "Defensor", "Cuadrúpedo", "CumbreBrasa", 26, 16, 29, 15, 14)
S(5, "rillip", "Rillip", "Mantaraz", "Comun", { "Agua" }, "Veloz", "Acuático", "MareaCoralina", 16, 23, 14, 18, 29)
S(6, "barrock", "Barrock", "Cantagólem", "Comun", { "Tierra" }, "Soporte", "Objeto animado", "ValleCopal", 24, 14, 20, 27, 15)
S(7, "yek", "Yek", "Yetormenta", "Comun", { "Aire" }, "Soporte", "Bípedo", "VeloAstral", 23, 13, 19, 28, 17)
S(8, "zunzi", "Zunzi", "Navajazul", "Comun", { "Aire" }, "Veloz", "Ave", "ValleCopal", 16, 22, 14, 18, 30)
S(9, "agavo", "Agavo", "Quiotazo", "Comun", { "Flora" }, "Defensor", "Planta", "CumbreBrasa", 26, 16, 29, 15, 14)
S(10, "vainas", "Vainas", "Hercuerno", "Comun", { "Flora" }, "Control", "Insecto", "ValleCopal", 19, 15, 19, 26, 21)
S(11, "zizi", "Zizi", "Chicharrayo", "Comun", { "Rayo" }, "Veloz", "Insecto", "MesetaFulgor", 16, 23, 14, 18, 29)
S(12, "tinco", "Tinco", "Coatitán", "Comun", { "Metal" }, "Atacante", "Cuadrúpedo", "CumbreBrasa", 18, 28, 15, 17, 22)
S(13, "cuerdo", "Cuerdo", "Turbinón", "Comun", { "Artificio" }, "Control", "Constructo", "MesetaFulgor", 19, 15, 18, 27, 21)
S(14, "okto", "Okto", "Krakensa", "Comun", { "Mente" }, "Control", "Acuático", "MareaCoralina", 19, 14, 18, 27, 22)
S(15, "murk", "Murk", "Lunatajo", "Comun", { "Sombra" }, "Veloz", "Volador", "VeloAstral", 16, 23, 14, 17, 30)
S(16, "bruma", "Bruma", "Fatuoscuro", "Comun", { "Sombra" }, "Soporte", "Fantasmal", "MareaCoralina", 24, 13, 19, 28, 16)
S(17, "pabilo", "Pabilo", "Candelux", "Comun", { "Luz" }, "Soporte", "Ave", "ValleCopal", 24, 13, 19, 28, 16)
S(18, "lunk", "Lunk", "Batraluna", "Comun", { "Astral" }, "Defensor", "Anfibio", "VeloAstral", 26, 16, 29, 15, 14)
S(19, "brinco", "Brinco", "Voltalope", "Raro", { "Aire", "Rayo" }, "Veloz", "Cuadrúpedo", "MesetaFulgor", 18, 26, 14, 19, 31)
S(20, "chispon", "Chispón", "Fulminave", "Raro", { "Rayo", "Metal" }, "Atacante", "Ave", "MesetaFulgor", 21, 30, 16, 18, 23)
S(21, "kroa", "Kroa", "Corvidúo", "Raro", { "Mente", "Sombra" }, "Control", "Ave", "VeloAstral", 21, 16, 19, 29, 23)
S(22, "lumbro", "Lumbro", "Faroibex", "Raro", { "Luz" }, "Soporte", "Cuadrúpedo", "ValleCopal", 26, 14, 21, 30, 17)
S(23, "picoso", "Picoso", "Magmacrán", "Raro", { "Fuego", "Tierra" }, "Atacante", "Arácnido", "CumbreBrasa", 21, 30, 17, 18, 22)
S(24, "kunko", "Kunko", "Alamar", "Raro", { "Agua", "Aire" }, "Veloz", "Acuático → Ave", "MareaCoralina", 18, 25, 15, 19, 31)
S(25, "dienton", "Dientón", "Castorre", "Raro", { "Flora", "Tierra" }, "Defensor", "Cuadrúpedo", "ValleCopal", 28, 18, 31, 16, 15)
S(26, "cotorro", "Cotorro", "Lorapiente", "Raro", { "Agua", "Flora" }, "Control", "Serpentino", "MareaCoralina", 21, 16, 19, 29, 23)
S(27, "medu", "Medu", "Cometaura", "Raro", { "Astral" }, "Soporte", "Astral", "MareaCoralina", 26, 14, 21, 30, 17)
S(28, "remache", "Remache", "Mechalata", "Raro", { "Artificio", "Metal" }, "Defensor", "Constructo", "MesetaFulgor", 28, 18, 31, 16, 15)
S(29, "linterno", "Linterno", "Farolánima", "Raro", { "Luz", "Sombra" }, "Soporte", "Fantasmal", "VeloAstral", 26, 14, 21, 30, 17)
S(30, "garabato", "Garabato", "Monomural", "Raro", { "Artificio" }, "Control", "Primate", "ValleCopal", 21, 16, 18, 29, 24)
S(31, "zanco", "Zanco", "Grullacandil", "Raro", { "Fuego" }, "Atacante", "Ave", "CumbreBrasa", 20, 30, 16, 20, 22)
S(32, "ovillo", "Ovillo", "Aracnógrafa", "Raro", { "Mente", "Artificio" }, "Control", "Arácnido", "VeloAstral", 21, 15, 19, 29, 24)
S(33, "cempa", "Cempa", "Cempasol", "Epico", { "Fuego", "Luz" }, "Atacante", "Cuadrúpedo", "ValleCopal", 22, 32, 16, 22, 24)
S(34, "cenoti", "Cenoti", "Leviacielo", "Epico", { "Agua", "Astral" }, "Control", "Acuático", "MareaCoralina", 22, 16, 21, 31, 26)
S(35, "pelon", "Pelón", "Zopilatón", "Epico", { "Aire", "Metal" }, "Defensor", "Ave", "CumbreBrasa", 30, 19, 33, 18, 16)
S(36, "chaquiro", "Chaquiro", "Fulgurila", "Epico", { "Tierra", "Rayo" }, "Bruto", "Cuadrúpedo", "MesetaFulgor", 28, 30, 24, 14, 20)
S(37, "guaca", "Guaca", "Aráureo", "Epico", { "Luz", "Aire" }, "Atacante", "Ave", "ValleCopal", 22, 32, 16, 22, 24)
S(38, "brujo", "Brujo", "Brujalada", "Epico", { "Sombra", "Mente" }, "Control", "Insecto", "VeloAstral", 22, 16, 21, 31, 26)
S(39, "tizon", "Tizón", "Tizonsierpe", "Epico", { "Fuego", "Flora" }, "Soporte", "Serpentino", "ValleCopal", 28, 15, 22, 32, 19)
S(40, "tuerco", "Tuerco", "Engrifo", "Epico", { "Aire", "Artificio" }, "Veloz", "Quimera", "MesetaFulgor", 19, 27, 16, 20, 34)
S(41, "boreal", "Boreal", "Auroribú", "Epico", { "Luz", "Astral" }, "Soporte", "Cuadrúpedo", "VeloAstral", 28, 15, 22, 32, 19)
S(42, "hilacho", "Hilacho", "Titeránima", "Epico", { "Sombra", "Artificio" }, "Control", "Fantasmal", "VeloAstral", 22, 17, 20, 31, 26)
S(43, "lumbrela", "Lumbrela", "Papalumen", "Legendario", { "Aire", "Luz" }, "Soporte", "Insecto", "ValleCopal", 29, 16, 24, 34, 21)
S(44, "geoda", "Geoda", "Gemaboa", "Legendario", { "Tierra", "Metal" }, "Defensor", "Serpentino", "CumbreBrasa", 32, 19, 36, 19, 18)
S(45, "nebulo", "Nébulo", "Astrocorcel", "Legendario", { "Aire", "Astral" }, "Veloz", "Cuadrúpedo", "VeloAstral", 20, 28, 17, 22, 37)
S(46, "bisi", "Bisi", "Gemitrueno", "Legendario", { "Agua", "Rayo" }, "Atacante", "Serpentino", "MareaCoralina", 24, 34, 18, 22, 26)
S(47, "petardo", "Petardo", "Pirotoro", "Legendario", { "Fuego", "Artificio", "Luz" }, "Atacante", "Cuadrúpedo", "CumbreBrasa", 24, 34, 19, 21, 26)
S(48, "mediluna", "Mediluna", "Eclipsor", "Unico", { "Luz", "Sombra", "Astral" }, "Control", "Cuadrúpedo", "VeloAstral", 25, 19, 23, 34, 27)
S(49, "nacar", "Nácar", "Aetherion", "Unico", { "Agua", "Astral", "Mente" }, "Soporte", "Acuático", "VeloAstral", 30, 17, 25, 35, 21)
S(50, "nex", "Nex", "Nexum", "Misterio", {}, "Adaptativo", "Objeto animado", "TorreDelNexo", 24, 24, 24, 24, 24)
-- stylua: ignore end

-- Epítetos de Legendarios, Únicos y Misterio (p. 29)
Species.lumbrela.epithet = "el Vitral Vivo"
Species.geoda.epithet = "la Guardiana de Vetas"
Species.nebulo.epithet = "el Ocho Vientos"
Species.bisi.epithet = "Serpiente de Dos Mareas"
Species.petardo.epithet = "el Castillo de Feria"
Species.mediluna.epithet = "el Gato de Dos Cielos"
Species.nacar.epithet = "la Ballena Cartógrafa"
Species.nex.epithet = "el Gabinete que Camina"

-- ============ Especies jugables en el vertical slice ============
local function slice(id: string, details: { [string]: any })
	local s = Species[id] :: any
	assert(s, "Especie desconocida " .. id)
	s.status = "VerticalSlice"
	for k, v in pairs(details) do
		s[k] = v
	end
end

slice("kuachi", {
	talent = "BolsaDeBrasas",
	signature = "LatigoDeCeniza",
	mythicMix = "El tlacuache que robó el fuego (relato mazateco) + horno de comal.",
	concept = "El tlacuache que, según el relato, robó el fuego para los demás y lo cargó en la cola.",
	broteDescription = "Pequeño, de hocico largo y orejas redondas; cola pelada y enroscada con la punta chamuscada; la bolsa del vientre brilla como un horno tibio.",
	talladoDescription = "Tlacuache de acecho, largo y bajo; la bolsa es un horno con rejilla al rojo y la cola un látigo de ceniza con anillos encendidos. Mirada de ladrón astuto.",
	provenance = "Tlacuache · horno de barro de comal · relato mazateco del robo del fuego · México",
})
slice("xolumi", {
	talent = "Regeneracion",
	signature = "CicatrizDorada",
	mythicMix = "Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la deidad) + barro negro de Oaxaca.",
	concept = "Ajolote de barro negro bruñido que se regenera. Su tema es transformarse para no desaparecer.",
	broteDescription = "Cabeza ancha y sonrisa tranquila; tres pares de branquias plumosas turquesa; piel negra pulida como cerámica de San Bartolo Coyotepec.",
	talladoDescription = "Ajolote colosal de seis patas, erguido como un dragón de río; branquias de humo de copal, cicatrices doradas y boca con colmillos pequeños.",
	provenance = "Ajolote · barro negro de Oaxaca · reparación dorada de cerámica · México",
})
slice("teselo", {
	talent = "CaparazonDeGrecas",
	signature = "AstrolabioDePiedra",
	mythicMix = "Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla.",
	concept = "Tortuga terrestre con caparazón de grecas, como los mosaicos de piedra de Mitla.",
	broteDescription = "Caparazón alto de teselas pulidas, patas columnares y cara curiosa; sin vegetación ni picos.",
	talladoDescription = "Tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que giran; sobre el lomo flota un disco de cielo nocturno.",
	provenance = "Tortuga del desierto · mosaico de grecas de Mitla · tortuga que sostiene el cielo (eco chino de Ao) · México + Eco chino",
})
slice("comalu", {
	talent = "ComalTibio",
	signature = "RodadaDeBrasa",
	mythicMix = "Salamandra de fuego del folclore europeo + armadillo + comal.",
	concept = "Armadillo cuyo caparazón es un comal de barro siempre tibio.",
	broteDescription = "Bola de bandas de barro con orejitas; se enrolla al asustarse.",
	talladoDescription = "Armadillo-tanque de placas de comal con costuras de magma y un cuerno de basalto.",
})
slice("barrock", {
	talent = "BarroFresco",
	signature = "VertidoDelCantaro",
	mythicMix = "Gólem de barro del folclore europeo + cántaro de mercado.",
	concept = "Una vasija de barro que el Tallador olvidó junto al río y que despertó llena de agua de lluvia.",
	broteDescription = "Jarrito panzón con asa-oreja, tapita de sombrero y patas de piedra.",
	talladoDescription = "Cántaro-gólem de brazos de barro, puños de piedra y grietas reparadas en oro.",
})
slice("agavo", {
	talent = "PencaGruesa",
	signature = "Quiote",
	mythicMix = "Maguey y quiote + guardián de los campos.",
	concept = "Un maguey pequeño que aprendió a caminar sobre sus raíces.",
	broteDescription = "Roseta de hojas carnosas con cara en el centro y raíces-pies.",
	talladoDescription = "Agave colosal de pencas con espinas de jade y un quiote-lanza.",
})
slice("vainas", {
	talent = "Siembra",
	signature = "SonajaDeVainas",
	mythicMix = "Escarabajo hércules + vaina de huaje + sonaja.",
	concept = "Escarabajo que vive dentro de una vaina de semillas y siembra por donde pasa.",
	broteDescription = "Escarabajo redondo con élitros de vaina y antenas de brote.",
	talladoDescription = "Escarabajo gigante con un cuerno doble de semilla y élitros-vaina que se abren como escudos.",
})
slice("zizi", {
	talent = "CantoEstatico",
	signature = "Tamborazo",
	mythicMix = "Cigarra de verano + tambor de feria + bobina de cobre.",
	concept = "Cigarra cuyo canto de verano acumula electricidad estática.",
	broteDescription = "Cuerpo verde-amarillo con alas transparentes cortas y ojos enormes.",
	talladoDescription = "Cigarra-tambor con alas de vidrio y nervaduras de cobre.",
})

local Biomes = {
	ValleCopal = { id = "ValleCopal", name = "Valle Copal", act = "Inicio · Acto I", status = "Definido" },
	MareaCoralina = { id = "MareaCoralina", name = "Marea Coralina", act = "Acto II", status = "Propuesta" },
	CumbreBrasa = { id = "CumbreBrasa", name = "Cumbre Brasa", act = "Acto III", status = "Definido" },
	MesetaFulgor = { id = "MesetaFulgor", name = "Meseta Fulgor", act = "Acto IV", status = "Propuesta" },
	VeloAstral = { id = "VeloAstral", name = "Velo Astral", act = "Acto V", status = "Definido" },
	TorreDelNexo = { id = "TorreDelNexo", name = "Torre del Nexo", act = "Final", status = "Definido" },
}

return Freeze.deep({
	ById = Species,
	Order = Order,
	Biomes = Biomes,
	Starters = { "kuachi", "xolumi", "teselo" },
})
