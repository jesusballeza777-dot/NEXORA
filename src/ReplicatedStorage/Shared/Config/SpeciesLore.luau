--!strict
-- SpeciesLore: lore y datos de producción de cada especie, tomados de las fichas de la Biblia.
-- Fuente: docs/reference/NEXORA_Biblia_Compacta_v1.0.pdf, Apéndice A, fichas de especie
-- (Biblia compacta p. 19–28, que transcriben las p. 48–81 de la fuente v5.0). Otras páginas
-- citadas: p. 4 (los tres iniciales), p. 12 (el Gabinete que Camina), p. 20 (tabla maestra),
-- p. 32–35 (ritmo de progreso, especie dentro del huevo, primeros 15 minutos, progresión).
--
-- Reglas de este archivo:
--   * Texto copiado de la Biblia con limpieza mínima (guiones de corte de línea y saltos).
--     No se inventa ni se embellece nada. Si la Biblia no da un campo para una especie,
--     el valor es exactamente "Pendiente".
--   * "—" en linaje es lo que la ficha dice literalmente (ninguna receta de linaje la produce).
--   * page = página de la Biblia compacta donde empieza la ficha; el comentario de cada
--     entrada indica también la página de la fuente v5.0.
--   * cost incluye el nivel de Tallado porque la ficha los da en la misma línea
--     («Coste: 2 (Brote 1) · Tallado: nivel 12»).
--   * incubation incluye la descripción del huevo cuando la ficha la da (Legendario en adelante).
--   * distinctiveTrait = «Claves 2D» de la ficha (+ aura propia desde Legendario).
--   * Las tres fichas de los iniciales (p. 19) no traen Obtención, Linaje, Coste ni Incubación:
--     obtención sale de p. 4 y p. 33; coste de la tabla maestra (p. 20) y del Tallado de un
--     inicial a nivel 12 (p. 32); linaje e incubación quedan "Pendiente".
-- Estos textos son referencia de diseño y lore; los datos de combate viven en Species,
-- Talents y Abilities.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type LoreDef = {
	id: string,
	page: number?,
	concept: string,
	broteLook: string,
	talladoLook: string,
	mythicMix: string,
	anatomy: string,
	distinctiveTrait: string,
	behavior: string,
	habitat: string,
	obtention: string,
	lineage: string,
	cost: string,
	incubation: string,
	talentText: string,
	signatureText: string,
}

local PENDIENTE = "Pendiente"

-- Textos de obtención que la Biblia repite por rareza.
local OBT_INICIAL =
	"Elección gratuita entre tres huevos de copal idénticos en la introducción; tras eclosionar se muestra que los otros dos iniciales se pueden conseguir después, y entran al grupo de Comunes de los huevos de cofre."
local OBT_COMUN = "Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza."
local OBT_RARO = "Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes."
local OBT_EPICO = "Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos Raros."
local OBT_LEGENDARIO =
	"Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos Épicos (4 %)."
local OBT_UNICO = "Cofre Nexo o historia (Acto III). Uno por cuenta."

-- Coste en equipo y nivel de Tallado por rareza, tal como aparecen en las fichas.
local COSTE_COMUN = "2 (Brote 1) · Tallado: nivel 12"
local COSTE_RARO = "3 (Brote 2) · Tallado: nivel 15"
local COSTE_EPICO = "4 (Brote 3) · Tallado: nivel 18"
local COSTE_LEGENDARIO = "5 (Brote 4) · Tallado: nivel 20"
local COSTE_UNICO = "6 (Brote 5) · Tallado: nivel 22"

local Lore: { [string]: LoreDef } = {}

local function add(def: LoreDef)
	assert(Lore[def.id] == nil, "Lore duplicado: " .. def.id)
	Lore[def.id] = def
end

-- ===================== Iniciales (Comunes) =====================

-- 01 Kuachi → Ascuacho · Biblia compacta p. 19 (fuente p. 49)
add({
	id = "kuachi",
	page = 19,
	concept = "El tlacuache que, según el relato, robó el fuego para los demás y lo cargó en la cola. Inicial de Fuego.",
	broteLook = "Pequeño, de hocico largo y orejas redondas; cola pelada y enroscada con la punta chamuscada; la bolsa del vientre brilla como un horno tibio.",
	talladoLook = "Tlacuache de acecho, largo y bajo; la bolsa es un horno con rejilla al rojo y la cola un látigo de ceniza con anillos encendidos. Mirada de ladrón astuto.",
	mythicMix = "El tlacuache que robó el fuego (relato mazateco) + horno de comal.",
	anatomy = "Cuadrúpedo · marsupial.",
	distinctiveTrait = "Silueta baja y alargada · bolsa-horno brillante · gris ceniza con brasa naranja.",
	behavior = "El Tallado es de acecho, con mirada de ladrón astuto.",
	habitat = "Valle Copal",
	obtention = OBT_INICIAL,
	lineage = PENDIENTE,
	cost = COSTE_COMUN,
	incubation = PENDIENTE,
	talentText = "Bolsa de Brasas. Al entrar en combate guarda 1 de Savia extra (máx. 1 por combate).",
	signatureText = "Látigo de Ceniza. Especial · 65 · 2 Savia. 40 % de quemadura; si el rival ya arde, +20 % de daño.",
})

-- 02 Xolumi → Xolossus · Biblia compacta p. 19 (fuente p. 50)
add({
	id = "xolumi",
	page = 19,
	concept = "Ajolote de barro negro bruñido que se regenera. Su tema es transformarse para no desaparecer. Inicial de Agua.",
	broteLook = "Cabeza ancha y sonrisa tranquila; tres pares de branquias plumosas turquesa; piel negra pulida como cerámica de San Bartolo Coyotepec.",
	talladoLook = "Ajolote colosal de seis patas, erguido como un dragón de río; branquias de humo de copal, cicatrices doradas y boca con colmillos pequeños.",
	mythicMix = "Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la deidad) + barro negro de Oaxaca.",
	anatomy = "Anfibio · ajolote; el Tallado tiene seis patas.",
	distinctiveTrait = "Seis patas y cabeza ancha · branquias de humo · negro bruñido con oro.",
	behavior = "Se regenera; el Brote tiene una sonrisa tranquila.",
	habitat = "Valle Copal",
	obtention = OBT_INICIAL,
	lineage = PENDIENTE,
	cost = COSTE_COMUN,
	incubation = PENDIENTE,
	talentText = "Regeneración. Recupera 6 % de VID al final de cada turno en el que no recibió daño.",
	signatureText = "Cicatriz Dorada. Especial · 0 · 2 Savia. Cura 25 % y gana +15 % DEF 2 turnos.",
})

-- 03 Teselo → Mitlaxis · Biblia compacta p. 19 (fuente p. 51)
add({
	id = "teselo",
	page = 19,
	concept = "Tortuga terrestre con caparazón de grecas, como los mosaicos de piedra de Mitla. Inicial de Tierra.",
	broteLook = "Caparazón alto de teselas pulidas, patas columnares y cara curiosa; sin vegetación ni picos.",
	talladoLook = "Tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que giran; sobre el lomo flota un disco de cielo nocturno.",
	mythicMix = "Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla.",
	anatomy = "Reptil · tortuga terrestre.",
	distinctiveTrait = "Domo escalonado · anillos dorados · piedra ocre y jade.",
	behavior = "El Brote tiene cara curiosa.",
	habitat = "Valle Copal",
	obtention = OBT_INICIAL,
	lineage = PENDIENTE,
	cost = COSTE_COMUN,
	incubation = PENDIENTE,
	talentText = "Caparazón de Grecas. Recibe −20 % de daño de los ataques básicos.",
	signatureText = "Astrolabio de Piedra. Especial · 60 · 2 Savia. +25 % DEF propia y −10 % VEL del rival 2 turnos.",
})

-- ===================== Comunes =====================

-- 04 Comalú → Magmadillo · Biblia compacta p. 20 (fuente p. 54)
add({
	id = "comalu",
	page = 20,
	concept = "Armadillo cuyo caparazón es un comal de barro siempre tibio.",
	broteLook = "Bola de bandas de barro con orejitas; se enrolla al asustarse.",
	talladoLook = "Armadillo-tanque de placas de comal con costuras de magma y un cuerno de basalto; al rodar deja un surco ardiente.",
	mythicMix = "Salamandra de fuego del folclore europeo + armadillo + comal.",
	anatomy = "Cuadrúpedo · acorazado.",
	distinctiveTrait = "Bola acorazada · costuras de lava · barro rojo y negro.",
	behavior = "El Brote se enrolla al asustarse; el Tallado deja un surco ardiente al rodar.",
	habitat = "Cumbre Brasa",
	obtention = OBT_COMUN,
	lineage = "Kuachi + Teselo (10 %)",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Comal Tibio. Los rivales que lo golpean con contacto tienen 15 % de quemarse.",
	signatureText = "Rodada de Brasa. Especial · 70 · 2 Savia. Después gana +10 % DEF 2 turnos.",
})

-- 05 Rillip → Mantaraz · Biblia compacta p. 20 (fuente p. 54)
add({
	id = "rillip",
	page = 20,
	concept = "Raya de río que vuela bajo el agua como un listón.",
	broteLook = "Disco liso con cola corta; salta fuera del agua para jugar.",
	talladoLook = "Manta de alas enormes con borde de cuchilla y cola-látigo con aguijón luminoso; corta la corriente como un planeador.",
	mythicMix = "Mantarraya + listón de feria + estela de cometa marino.",
	anatomy = "Acuático · raya.",
	distinctiveTrait = "Rombo de alas · cola-látigo · turquesa y blanco espuma.",
	behavior = "El Brote salta fuera del agua para jugar; el Tallado corta la corriente como un planeador.",
	habitat = "Marea Coralina",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Corriente a Favor. +10 % VEL si actúa primero en el turno.",
	signatureText = "Listón de Agua. Especial · 65 · 2 Savia. Prioridad +1.",
})

-- 06 Barrock → Cantagólem · Biblia compacta p. 21 (fuente p. 55)
add({
	id = "barrock",
	page = 21,
	concept = "Una vasija de barro que el Tallador olvidó junto al río y que despertó llena de agua de lluvia.",
	broteLook = "Jarrito panzón con asa-oreja, tapita de sombrero y patas de piedra.",
	talladoLook = "Cántaro-gólem de brazos de barro, puños de piedra y grietas reparadas en oro; vierte agua curativa por el pico como un guerrero-fuente.",
	mythicMix = "Gólem de barro del folclore europeo + cántaro de mercado.",
	anatomy = "Objeto animado · vasija.",
	distinctiveTrait = "Vasija con brazos · grietas de oro · barro con grecas blancas.",
	behavior = "El Tallado vierte agua curativa por el pico como un guerrero-fuente.",
	habitat = "Valle Copal",
	obtention = OBT_COMUN,
	lineage = "Teselo + Xolumi (10 %)",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Barro Fresco. Sus curaciones curan 15 % más.",
	signatureText = "Vertido del Cántaro. Especial · 0 · 2 Savia. Cura 20 % al aliado o a sí mismo y quita 1 estado.",
})

-- 07 Yek → Yetormenta · Biblia compacta p. 21 (fuente p. 55)
add({
	id = "yek",
	page = 21,
	concept = "Una cría de yeti hecha de nube que baja de las cumbres con la primera tormenta.",
	broteLook = "Bola de pelo blanco con cuernitos y patas cortas; a veces flota como una nube.",
	talladoLook = "Yeti bípedo de pelaje de nube de tormenta, cuernos en espiral de viento y brazos larguísimos; ruge ventiscas.",
	mythicMix = "Yeti de las montañas (folclore himalayo) + nube de tormenta + cuernos de borrego cimarrón.",
	anatomy = "Bípedo · yeti.",
	distinctiveTrait = "Bípedo peludo y alto · cuernos espiral · blanco nube y azul tormenta.",
	behavior = "El Brote a veces flota como una nube; el Tallado ruge ventiscas.",
	habitat = "Velo Astral",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Sombra Fresca. El aliado en 2v2 recibe −10 % de daño de Fuego.",
	signatureText = "Llovizna. Especial · 40 · 2 Savia. Cura 15 % al equipo.",
})

-- 08 Zunzi → Navajazul · Biblia compacta p. 21 (fuente p. 56)
add({
	id = "zunzi",
	page = 21,
	concept = "Colibrí que se mantiene inmóvil en el aire y zumba como un trompo.",
	broteLook = "Bolita de plumas con pico corto y alas en abanico.",
	talladoLook = "Colibrí de plumas de obsidiana con pico-navaja y cola en tijera; zumba tan rápido que deja estelas cortantes.",
	mythicMix = "Colibríes guerreros mexicas (solo el concepto, sin la deidad) + navaja de obsidiana.",
	anatomy = "Ave · colibrí.",
	distinctiveTrait = "Pico-navaja · alas en abanico · azul cobalto iridiscente.",
	behavior = "Se mantiene inmóvil en el aire y zumba como un trompo; el Tallado tiene mirada de guerrero (p. 14).",
	habitat = "Valle Copal",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Vuelo Estático. +10 % evasión mientras no cambie de monstruo.",
	signatureText = "Zumbido de Trompo. Especial · 60 · 2 Savia. Golpea dos veces si actúa primero.",
})

-- 09 Agavo → Quiotazo · Biblia compacta p. 21 (fuente p. 56)
add({
	id = "agavo",
	page = 21,
	concept = "Un maguey pequeño que aprendió a caminar sobre sus raíces.",
	broteLook = "Roseta de hojas carnosas con cara en el centro y raíces-pies.",
	talladoLook = "Agave colosal de pencas con espinas de jade y un quiote-lanza que se alza como bandera de batalla.",
	mythicMix = "Maguey y quiote + guardián de los campos.",
	anatomy = "Planta · agave.",
	distinctiveTrait = "Roseta de pencas · quiote-lanza · verde agave con espinas jade.",
	behavior = "Aprendió a caminar sobre sus raíces.",
	habitat = "Cumbre Brasa",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Penca Gruesa. +15 % DEF contra Agua y Rayo.",
	signatureText = "Quiote. Especial · 70 · 2 Savia. Si el rival lo golpeó el turno anterior, +25 %.",
})

-- 10 Vainas → Hercuerno · Biblia compacta p. 21 (fuente p. 57)
add({
	id = "vainas",
	page = 21,
	concept = "Escarabajo que vive dentro de una vaina de semillas y siembra por donde pasa.",
	broteLook = "Escarabajo redondo con élitros de vaina y antenas de brote.",
	talladoLook = "Escarabajo gigante con un cuerno doble de semilla, élitros-vaina que se abren como escudos y sonido de sonaja al cargar.",
	mythicMix = "Escarabajo hércules + vaina de huaje + sonaja.",
	anatomy = "Insecto · escarabajo.",
	distinctiveTrait = "Cuerno frontal enorme · élitros de vaina · verde y ámbar.",
	behavior = "Siembra por donde pasa; el Tallado suena como sonaja al cargar.",
	habitat = "Valle Copal",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Siembra. Cada vez que usa un especial deja una semilla: el siguiente aliado que entra cura 8 %.",
	signatureText = "Sonaja de Vainas. Especial · 50 · 2 Savia. 35 % de adormecer.",
})

-- 11 Zizi → Chicharrayo · Biblia compacta p. 21 (fuente p. 57)
add({
	id = "zizi",
	page = 21,
	concept = "Cigarra cuyo canto de verano acumula electricidad estática.",
	broteLook = "Cuerpo verde-amarillo con alas transparentes cortas y ojos enormes.",
	talladoLook = "Cigarra-tambor con alas de vidrio y nervaduras de cobre; su abdomen retumba en descargas.",
	mythicMix = "Cigarra de verano + tambor de feria + bobina de cobre.",
	anatomy = "Insecto · cigarra.",
	distinctiveTrait = "Alas de vidrio · abdomen-tambor · amarillo y cobre.",
	behavior = "Su canto de verano acumula electricidad estática; el abdomen del Tallado retumba en descargas.",
	habitat = "Meseta Fulgor",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Canto Estático. Sus ataques básicos tienen +10 % de parálisis.",
	signatureText = "Tamborazo. Especial · 70 · 2 Savia. 25 % de robar 1 de Savia.",
})

-- 12 Tinco → Coatitán · Biblia compacta p. 22 (fuente p. 58)
add({
	id = "tinco",
	page = 22,
	concept = "Coatí curioso que se cubre con láminas de hojalata repujada.",
	broteLook = "Hocico largo, cola anillada hacia arriba y una placa de lata en el lomo.",
	talladoLook = "Coatí armado con placas repujadas, garras de herrería y cola anillada de eslabones; ágil y peleonero.",
	mythicMix = "Coatí + armadura de hojalata repujada.",
	anatomy = "Cuadrúpedo · coatí.",
	distinctiveTrait = "Hocico largo y cola anillada · placas de lata · gris plata y rojo.",
	behavior = "Curioso; el Tallado es ágil y peleonero.",
	habitat = "Cumbre Brasa",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Curioso. +15 % de crítico contra rivales que acaban de entrar al campo.",
	signatureText = "Garra Repujada. Especial · 70 · 2 Savia. −15 % DEF del rival 2 turnos.",
})

-- 13 Cuerdo → Turbinón · Biblia compacta p. 22 (fuente p. 58)
add({
	id = "cuerdo",
	page = 22,
	concept = "Juguete de hojalata con rehilete en la cabeza que cobró vida en una feria.",
	broteLook = "Cuerpo de lata redondo, llave de cuerda en la espalda y un rehilete pequeño.",
	talladoLook = "Autómata industrial de tres turbinas-rehilete, piernas de resorte y llave gigante; sopla vendavales mecánicos.",
	mythicMix = "Juguete de cuerda de feria + turbina industrial.",
	anatomy = "Constructo · juguete de cuerda.",
	distinctiveTrait = "Cilindro de lata · tres turbinas · cobre, verde y turquesa.",
	behavior = "El Tallado sopla vendavales mecánicos.",
	habitat = "Meseta Fulgor",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Cuerda Larga. Cada 3 turnos su siguiente ataque tiene prioridad +1.",
	signatureText = "Rehiletazo. Especial · 55 · 2 Savia. 30 % de confundir.",
})

-- 14 Okto → Krakensa · Biblia compacta p. 22 (fuente p. 59)
add({
	id = "okto",
	page = 22,
	concept = "Pulpo que escribe con tinta de sueños dentro de una caracola.",
	broteLook = "Cabeza grande y ocho bracitos enroscados en espiral.",
	talladoLook = "Pulpo colosal de brazos larguísimos con ventosas luminosas y sigilos que hipnotizan; emerge de una caracola.",
	mythicMix = "Kraken del folclore nórdico (solo el concepto) + caracola + tinta de sueño.",
	anatomy = "Acuático · pulpo.",
	distinctiveTrait = "Cabeza-bulbo y 8 brazos · ventosas luminosas · violeta y rosa.",
	behavior = "Escribe con tinta de sueños; el Tallado emerge de una caracola y sus sigilos hipnotizan.",
	habitat = "Marea Coralina",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Tinta de Sueño. Sus estados de confusión duran 1 turno más.",
	signatureText = "Mancha de Tinta. Especial · 55 · 2 Savia. −20 % precisión del rival 2 turnos.",
})

-- 15 Murk → Lunatajo · Biblia compacta p. 22 (fuente p. 59)
add({
	id = "murk",
	page = 22,
	concept = "Murciélago magueyero de alas como papel amate.",
	broteLook = "Orejas enormes y alas plegadas como una capa.",
	talladoLook = "Murciélago de alas de amate con bordes en forma de hoz lunar; cae en picada en silencio.",
	mythicMix = "Murciélago magueyero + luna creciente como hoz.",
	anatomy = "Volador · murciélago.",
	distinctiveTrait = "Alas de hoz · orejas enormes · índigo y plata.",
	behavior = "El Tallado cae en picada en silencio.",
	habitat = "Velo Astral",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Vuelo Silencioso. Su primer ataque del combate no puede esquivarse.",
	signatureText = "Picada Nocturna. Especial · 70 · 2 Savia. +20 % si el rival tiene menos VEL.",
})

-- 16 Bruma → Fatuoscuro · Biblia compacta p. 22 (fuente p. 60)
add({
	id = "bruma",
	page = 22,
	concept = "Niebla de cenote que tomó forma de gota y se esconde detrás de los demás.",
	broteLook = "Gota de niebla con ojitos de luz y borde ondulado.",
	talladoLook = "Velo de niebla en capas con fuegos fatuos azules que flotan a su alrededor y engañan al rival.",
	mythicMix = "Fuego fatuo del folclore europeo + niebla de cenote.",
	anatomy = "Fantasmal · niebla.",
	distinctiveTrait = "Gota de niebla · luces fatuas · violeta humo y azul.",
	behavior = "Se esconde detrás de los demás; los fuegos fatuos del Tallado engañan al rival.",
	habitat = "Marea Coralina",
	obtention = OBT_COMUN,
	lineage = "Murk + Xolumi (10 %)",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Cortina de Niebla. El aliado en 2v2 gana +10 % evasión.",
	signatureText = "Abrazo de Bruma. Especial · 0 · 2 Savia. Cura 20 % y el rival pierde 1 de Savia.",
})

-- 17 Pabilo → Candelux · Biblia compacta p. 22 (fuente p. 60)
add({
	id = "pabilo",
	page = 22,
	concept = "Codorniz con un copete en forma de llama de vela que alumbra el camino.",
	broteLook = "Ave redonda de patitas cortas y copete de luz.",
	talladoLook = "Gallinácea de guerra con corona de velas, espolones de cera dura y un farol que nunca se apaga.",
	mythicMix = "Codorniz + cirio de procesión + farol.",
	anatomy = "Ave · codorniz.",
	distinctiveTrait = "Ave redonda con corona de velas · espolones · crema y oro.",
	behavior = "Su copete alumbra el camino.",
	habitat = "Valle Copal",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Luz de Camino. +10 % precisión a todo el equipo.",
	signatureText = "Pabilo. Especial · 0 · 2 Savia. Cura 20 % al aliado y +10 % ESE.",
})

-- 18 Lunk → Batraluna · Biblia compacta p. 22 (fuente p. 61)
add({
	id = "lunk",
	page = 22,
	concept = "Sapo que guarda una pequeña luna sobre la espalda, como en el cuento del sapo lunar.",
	broteLook = "Sapo ancho y redondo con manchas de cráter y una lunita flotando.",
	talladoLook = "Sapo enorme de piel de piedra volcánica con una luna que gira a su alrededor como un satélite.",
	mythicMix = "Sapo de la luna (eco chino) + cráteres + metate volcánico.",
	anatomy = "Anfibio · sapo.",
	distinctiveTrait = "Sapo ancho · luna en órbita · azul noche y gris cráter.",
	behavior = PENDIENTE,
	habitat = "Velo Astral",
	obtention = OBT_COMUN,
	lineage = "—",
	cost = COSTE_COMUN,
	incubation = "5 min",
	talentText = "Gravedad Baja. Inmune a la reducción de VEL.",
	signatureText = "Fase Lunar. Especial · 60 · 2 Savia. +20 % DEF; si es de noche en el juego, +20 % ESE.",
})

-- ===================== Raros =====================

-- 19 Brinco → Voltalope · Biblia compacta p. 23 (fuente p. 61)
add({
	id = "brinco",
	page = 23,
	concept = "Liebre bromista que corre más rápido que el trueno que provoca.",
	broteLook = "Orejas largas con puntas de chispa y patas traseras enormes.",
	talladoLook = "Liebre de patas de resorte con astas de rayo bifurcadas; aparece y desaparece en zigzag.",
	mythicMix = "Chacalope del folclore norteamericano (liebre con astas) + liebre embaucadora africana.",
	anatomy = "Cuadrúpedo · liebre.",
	distinctiveTrait = "Orejas y astas · patas traseras grandes · azul cielo y amarillo.",
	behavior = "Bromista; corre más rápido que el trueno que provoca y el Tallado aparece y desaparece en zigzag.",
	habitat = "Meseta Fulgor",
	obtention = OBT_RARO,
	lineage = "Zunzi + Zizi (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Broma Pesada. Al entrar en combate, el rival pierde 1 de Savia.",
	signatureText = "Zigzag. Especial · 70 · 2 Savia. Prioridad +1; 20 % de parálisis.",
})

-- 20 Chispón → Fulminave · Biblia compacta p. 23 (fuente p. 62)
add({
	id = "chispon",
	page = 23,
	concept = "Ave de tormenta cuyo trueno nace del batir de las alas.",
	broteLook = "Pollito de plumas grises con puntas metálicas que chispean.",
	talladoLook = "Ave rapaz de envergadura gigante con plumas-pararrayos de acero; cada aletazo es un trueno.",
	mythicMix = "Ave de tormenta cuyo trueno sale de las alas (eco africano) + pararrayos.",
	anatomy = "Ave · ave de tormenta.",
	distinctiveTrait = "Alas abiertas con plumas de acero · cresta · amarillo y gris.",
	behavior = "Cada aletazo del Tallado es un trueno.",
	habitat = "Meseta Fulgor",
	obtention = OBT_RARO,
	lineage = "Zizi + Tinco (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Aletazo. Sus ataques de Rayo hacen +10 % a rivales de Agua y Aire.",
	signatureText = "Trueno de Alas. Especial · 75 · 2 Savia. En 2v2 alcanza al segundo rival al 40 %.",
})

-- 21 Kroa → Corvidúo · Biblia compacta p. 23 (fuente p. 62)
add({
	id = "kroa",
	page = 23,
	concept = "Dos cuervos que son una sola criatura: uno piensa y el otro recuerda.",
	broteLook = "Dos polluelos de cuervo que nunca se separan.",
	talladoLook = "Dos cuervos grandes de plumas de obsidiana que vuelan en espejo; uno ve el pasado y otro el futuro.",
	mythicMix = "Los cuervos del pensamiento y la memoria (eco nórdico) + espejo de obsidiana.",
	anatomy = "Ave · pareja.",
	distinctiveTrait = "Dos aves en espejo · ojos de color distinto · negro violeta.",
	behavior = "Los dos nunca se separan y vuelan en espejo: uno piensa y el otro recuerda.",
	habitat = "Velo Astral",
	obtention = OBT_RARO,
	lineage = "Okto + Murk (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Pensamiento y Memoria. Ve qué tipo de acción eligió el rival (básico, especial o cambio) antes de resolver.",
	signatureText = "Picotazo Doble. Especial · 2 × 35 · 2 Savia. El segundo impacto confunde 25 %.",
})

-- 22 Lumbro → Faroibex · Biblia compacta p. 23 (fuente p. 63)
add({
	id = "lumbro",
	page = 23,
	concept = "Cabra montés de porcelana vidriada que guía a los perdidos con su cuerno.",
	broteLook = "Cabrita de pelaje blanco con un cuernito de luz.",
	talladoLook = "Cabra montés de porcelana con cuernos-faro curvos que proyectan haces de luz.",
	mythicMix = "Íbice de montaña + faro + porcelana vidriada.",
	anatomy = "Cuadrúpedo · cabra.",
	distinctiveTrait = "Cuernos largos y curvos · pezuñas de cobre · blanco porcelana y oro.",
	behavior = "Guía a los perdidos con su cuerno.",
	habitat = "Valle Copal",
	obtention = OBT_RARO,
	lineage = "Pabilo + Teselo (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Faro. En 2v2, el aliado gana +10 % DEF.",
	signatureText = "Haz del Faro. Especial · 60 · 2 Savia. Cura 15 % al aliado y ciega al rival 20 %.",
})

-- 23 Picoso → Magmacrán · Biblia compacta p. 23 (fuente p. 63)
add({
	id = "picoso",
	page = 23,
	concept = "Alacrán de obsidiana con grietas de magma.",
	broteLook = "Alacrán pequeño y redondo con tenazas grandes y cola enroscada.",
	talladoLook = "Alacrán blindado de obsidiana con grietas de magma, tenazas de basalto y aguijón de vidrio volcánico.",
	mythicMix = "Alacrán + obsidiana + flujo de lava.",
	anatomy = "Arácnido · alacrán.",
	distinctiveTrait = "Cola en arco con aguijón · tenazas grandes · negro y lava.",
	behavior = PENDIENTE,
	habitat = "Cumbre Brasa",
	obtention = OBT_RARO,
	lineage = "Comalú + Barrock (8 %) · Zanco + Dientón (10 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Aguijón Ardiente. Su Firma quema siempre a rivales de Flora.",
	signatureText = "Aguijón de Obsidiana. Especial · 75 · 2 Savia. 30 % de quemadura.",
})

-- 24 Kunko → Alamar · Biblia compacta p. 23 (fuente p. 64)
add({
	id = "kunko",
	page = 23,
	concept = "Un pez que, al tallarse, se convierte en ave: su evolución cambia de medio.",
	broteLook = "Pececito plateado con aletas largas como alas.",
	talladoLook = "Ave marina de alas-aleta escamadas y cola de pez; cambia de medio al tallarse.",
	mythicMix = "El pez Kun que se vuelve el ave Peng (eco chino).",
	anatomy = "Acuático → Ave.",
	distinctiveTrait = "Alas-aleta · cola de pez · azul marino y espuma.",
	behavior = PENDIENTE,
	habitat = "Marea Coralina",
	obtention = OBT_RARO,
	lineage = "Rillip + Yek (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Cambio de Medio. Al tallarse conserva su Firma de pez y gana +10 % VEL.",
	signatureText = "Salto de Espuma. Especial · 70 · 2 Savia. +15 % evasión 1 turno.",
})

-- 25 Dientón → Castorre · Biblia compacta p. 23 (fuente p. 64)
add({
	id = "dienton",
	page = 23,
	concept = "Castor constructor que levanta diques-jardín en los canales del Valle.",
	broteLook = "Castorcito de dientes naranjas que roe ramitas de copal y carga una hoja.",
	talladoLook = "Castor arquitecto con una torre-dique de troncos y jardín flotante en el lomo, cola de remo blindada y dientes de hacha.",
	mythicMix = "Castor constructor (eco canadiense) + chinampa de Xochimilco + torre de troncos.",
	anatomy = "Cuadrúpedo · castor.",
	distinctiveTrait = "Lomo-dique de troncos · cola de remo · café madera y verde.",
	behavior = "Levanta diques-jardín en los canales; el Brote roe ramitas de copal y carga una hoja.",
	habitat = "Valle Copal",
	obtention = OBT_RARO,
	lineage = "Vainas + Teselo (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Huerto. Cura 5 % al final de cada turno.",
	signatureText = "Embestida de Chinampa. Especial · 70 · 2 Savia. +10 % DEF 2 turnos.",
})

-- 26 Cotorro → Lorapiente · Biblia compacta p. 24 (fuente p. 65)
add({
	id = "cotorro",
	page = 24,
	concept = "Serpiente de humedal con cabeza de loro que protege los manglares.",
	broteLook = "Culebrita verde con pico curvo y plumitas rojas.",
	talladoLook = "Serpiente larga de escamas-hoja con gran cresta de plumas rojas y pico curvo; imita voces.",
	mythicMix = "Serpiente de humedal con cabeza de loro (eco guaraní) + manglar.",
	anatomy = "Serpentino · cabeza de loro.",
	distinctiveTrait = "Cuerpo en S · pico de loro · verde y rojo.",
	behavior = "Protege los manglares; el Tallado imita voces.",
	habitat = "Marea Coralina",
	obtention = OBT_RARO,
	lineage = "Xolumi + Agavo (8 %) · Dientón + Kunko (10 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Imitación. Una vez por combate repite el último básico del rival.",
	signatureText = "Grito de Manglar. Especial · 55 · 2 Savia. 35 % de confundir.",
})

-- 27 Medu → Cometaura · Biblia compacta p. 24 (fuente p. 65)
add({
	id = "medu",
	page = 24,
	concept = "Medusa del cielo nocturno con cola de cometa.",
	broteLook = "Campana pequeña translúcida con tres tentáculos de estrella.",
	talladoLook = "Medusa enorme con constelaciones dentro y cola de cometa de cinco tentáculos.",
	mythicMix = "Medusa + cometa + farol de papel de china.",
	anatomy = "Astral · medusa-cometa.",
	distinctiveTrait = "Campana translúcida · cola de cometa · índigo y cian.",
	behavior = PENDIENTE,
	habitat = "Marea Coralina",
	obtention = OBT_RARO,
	lineage = "Lunk + Bruma (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Estela. El aliado que entra al campo gana +15 % ESE 2 turnos.",
	signatureText = "Cola de Cometa. Especial · 60 · 2 Savia. Cura 15 % al equipo.",
})

-- 28 Remache → Mechalata · Biblia compacta p. 24 (fuente p. 66)
add({
	id = "remache",
	page = 24,
	concept = "Autómata bípedo de hojalata que repara a los demás en el taller.",
	broteLook = "Muñeco de lata con cabeza-linterna y bracitos de pinza.",
	talladoLook = "Mecha industrial de lámina repujada, cabeza-linterna, martillo-brazo y corazón de engranes a la vista.",
	mythicMix = "Hojalatero + robot industrial de fábrica.",
	anatomy = "Constructo · bípedo.",
	distinctiveTrait = "Bípedo cuadrado · cabeza-linterna · lata y latón.",
	behavior = "Repara a los demás en el taller.",
	habitat = "Meseta Fulgor",
	obtention = OBT_RARO,
	lineage = "Cuerdo + Tinco (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Taller. Al cambiar, el monstruo que entra recupera 10 %.",
	signatureText = "Martillazo Repujado. Especial · 75 · 2 Savia. Rompe escudos.",
})

-- 29 Linterno → Farolánima · Biblia compacta p. 24 (fuente p. 66)
add({
	id = "linterno",
	page = 24,
	concept = "Ánima que vive dentro de un farol de papel y acompaña a los que caminan de noche.",
	broteLook = "Farolito de papel con carita y un velo corto.",
	talladoLook = "Farol alto de papel calado con velo de sombra y pétalos de luz que orbitan.",
	mythicMix = "Farol de papel calado + ánima de los caminos (sin referencias religiosas).",
	anatomy = "Fantasmal · farol.",
	distinctiveTrait = "Farol vertical · velo · naranja papel y violeta.",
	behavior = "Acompaña a los que caminan de noche.",
	habitat = "Velo Astral",
	obtention = OBT_RARO,
	lineage = "Pabilo + Bruma (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Camino de Pétalos. Si un aliado cae, el siguiente entra con 10 % de escudo.",
	signatureText = "Luz de Ánima. Especial · 50 · 2 Savia. Cura 15 % y ciega 20 %.",
})

-- 30 Garabato → Monomural · Biblia compacta p. 24 (fuente p. 67)
add({
	id = "garabato",
	page = 24,
	concept = "Mono artesano que pinta lo que imagina y lo vuelve real por un instante.",
	broteLook = "Monito de cola enroscada con un pincel tras la oreja.",
	talladoLook = "Mono de brazos largos con pinceles, flauta y paleta flotante; pinta trampas en el aire.",
	mythicMix = "Monos artistas de los relatos mayas (inspiración, sin nombres) + muralismo.",
	anatomy = "Primate.",
	distinctiveTrait = "Cola espiral · pinceles · café y colores primarios.",
	behavior = "Pinta lo que imagina y lo vuelve real por un instante; el Tallado pinta trampas en el aire.",
	habitat = "Valle Copal",
	obtention = OBT_RARO,
	lineage = "Cuerdo + Kuachi (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Boceto. El primer especial que usa cada combate cuesta 1 de Savia menos.",
	signatureText = "Trazo Vivo. Especial · 50 · 2 Savia. El rival no puede cambiar 2 turnos.",
})

-- 31 Zanco → Grullacandil · Biblia compacta p. 24 (fuente p. 67)
add({
	id = "zanco",
	page = 24,
	concept = "Grulla de una sola pata que guarda una lámpara de aceite en el pecho.",
	broteLook = "Polluelo zancudo de plumas de brasa que se balancea en una pata.",
	talladoLook = "Grulla alta de cuello en S, plumas de ascua y un candil de barro encendido en el pecho.",
	mythicMix = "Ave de una pata ligada al fuego (eco chino) + candil.",
	anatomy = "Ave · grulla de una pata.",
	distinctiveTrait = "Una pata · cuello en S · rojo brasa y negro.",
	behavior = "El Brote se balancea en una pata.",
	habitat = "Cumbre Brasa",
	obtention = OBT_RARO,
	lineage = "Comalú + Zunzi (8 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Equilibrio. Inmune al aturdimiento.",
	signatureText = "Picotazo de Candil. Especial · 75 · 2 Savia. 25 % de quemadura.",
})

-- 32 Ovillo → Aracnógrafa · Biblia compacta p. 25 (fuente p. 68)
add({
	id = "ovillo",
	page = 25,
	concept = "Araña tejedora que hila mapas de los caminos del Nexo.",
	broteLook = "Arañita redonda con patas cortas y un ovillo de hilo dorado.",
	talladoLook = "Araña cartógrafa con un mapa bordado en el abdomen y una red-mapa de hilos dorados a su espalda.",
	mythicMix = "Araña tejedora de los cuentos (eco africano) + telar de cintura + mapa.",
	anatomy = "Arácnido · tejedora.",
	distinctiveTrait = "Abdomen grande · red dorada · violeta y oro.",
	behavior = "Hila mapas de los caminos del Nexo.",
	habitat = "Velo Astral",
	obtention = OBT_RARO,
	lineage = "Okto + Cuerdo (8 %) · Garabato + Kroa (10 %)",
	cost = COSTE_RARO,
	incubation = "20 min",
	talentText = "Red de Caminos. Los rivales no pueden huir del combate ni cambiar sin perder 1 de Savia.",
	signatureText = "Telaraña-Mapa. Especial · 45 · 2 Savia. −25 % VEL del rival 3 turnos.",
})

-- ===================== Épicos =====================

-- 33 Cempa → Cempasol · Biblia compacta p. 25 (fuente p. 68)
add({
	id = "cempa",
	page = 25,
	concept = "Venado cola blanca con astas florecidas de cempasúchil que arden sin quemar.",
	broteLook = "Cervatillo con manchas de pétalo y botones naranjas en la frente.",
	talladoLook = "Venado de astas florecidas que arden sin quemar y un sendero de pétalos de luz.",
	mythicMix = "Venado + cempasúchil + brasa dorada.",
	anatomy = "Cuadrúpedo · venado.",
	distinctiveTrait = "Astas de flores · porte alto · naranja y oro.",
	behavior = PENDIENTE,
	habitat = "Valle Copal",
	obtention = OBT_EPICO,
	lineage = "Zanco + Lumbro (6 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Sendero de Pétalos. Al derrotar a un rival, cura 15 %.",
	signatureText = "Corona Ardiente. Especial · 80 · 2 Savia. 30 % de quemadura; +10 % de daño de Luz 2 turnos.",
})

-- 34 Cenoti → Leviacielo · Biblia compacta p. 25 (fuente p. 69)
add({
	id = "cenoti",
	page = 25,
	concept = "Pez ciego de cenote que lleva el cielo estrellado dentro del cuerpo.",
	broteLook = "Pez pálido con una ventanita de estrellas en el costado.",
	talladoLook = "Pez colosal de cristal con una noche completa dentro y aletas como velas; nada en el aire.",
	mythicMix = "Leviatán (concepto de monstruo marino) + pez ciego de cenote + cielo estrellado.",
	anatomy = "Acuático · pez de cenote.",
	distinctiveTrait = "Cuerpo de cristal con estrellas · aletas-vela · turquesa y noche.",
	behavior = "El Tallado nada en el aire.",
	habitat = "Marea Coralina",
	obtention = OBT_EPICO,
	lineage = "Kunko + Medu (6 %) · Cotorro + Boreal (10 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Sin Ojos. Inmune a la ceguera y a la reducción de precisión.",
	signatureText = "Reflejo del Cenote. Especial · 70 · 2 Savia. −20 % VEL del rival y +10 % evasión propia.",
})

-- 35 Pelón → Zopilatón · Biblia compacta p. 25 (fuente p. 69)
add({
	id = "pelon",
	page = 25,
	concept = "Zopilote rey con alas de hojalata repujada que limpia los campos tras la tormenta.",
	broteLook = "Polluelo pelón de cabeza dorada y plumón gris.",
	talladoLook = "Zopilote rey de alas de lámina repujada como veletas, cabeza dorada y garras de herrero.",
	mythicMix = "Zopilote rey + hojalata repujada + veleta.",
	anatomy = "Ave · zopilote.",
	distinctiveTrait = "Alas abiertas de lámina · cabeza dorada · gris y oro.",
	behavior = "Limpia los campos tras la tormenta.",
	habitat = "Cumbre Brasa",
	obtention = OBT_EPICO,
	lineage = "Chispón + Kunko (6 %) · Remache + Guaca (10 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Carroñero. Cuando un monstruo cae en el campo, gana +15 % ATQ 2 turnos.",
	signatureText = "Ala Veleta. Especial · 70 · 2 Savia. Escudo del 15 % al aliado.",
})

-- 36 Chaquiro → Fulgurila · Biblia compacta p. 25 (fuente p. 70)
add({
	id = "chaquiro",
	page = 25,
	concept = "Monstruo de Gila con cuentas de fulgurita, el vidrio que nace cuando el rayo cae en la arena.",
	broteLook = "Lagartito de cuentas naranjas y negras, cola gorda.",
	talladoLook = "Lagarto de cuentas de vidrio de rayo con cristales que se cargan en el lomo.",
	mythicMix = "Monstruo de Gila + fulgurita + chaquira.",
	anatomy = "Cuadrúpedo · lagarto.",
	distinctiveTrait = "Cuerpo bajo · cristales dorsales · naranja, negro y amarillo.",
	behavior = PENDIENTE,
	habitat = "Meseta Fulgor",
	obtention = OBT_EPICO,
	lineage = "Picoso + Brinco (6 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Reserva. Guarda grasa en la cola: la primera vez que bajaría de 25 % de VID, recupera 15 %.",
	signatureText = "Mordida Fulgurita. Especial · 80 · 2 Savia. 25 % de parálisis.",
})

-- 37 Guaca → Aráureo · Biblia compacta p. 25 (fuente p. 70)
add({
	id = "guaca",
	page = 25,
	concept = "Guacamaya de plumas de luz que pinta el amanecer al volar.",
	broteLook = "Pichón de guacamaya con copete corto y plumas de colores suaves.",
	talladoLook = "Guacamaya de alas-vitral extendidas y cola de serpentinas de luz.",
	mythicMix = "Guacamaya + vitral + sol tallado.",
	anatomy = "Ave · guacamaya.",
	distinctiveTrait = "Alas abiertas · cola larga · oro y colores de vitral.",
	behavior = "Pinta el amanecer al volar.",
	habitat = "Valle Copal",
	obtention = OBT_EPICO,
	lineage = "Lumbro + Brinco (6 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Plumaje Solar. Sus ataques de Luz tienen +10 % de crítico.",
	signatureText = "Barrido de Alba. Especial · 80 · 2 Savia. En 2v2 golpea a ambos rivales al 70 %.",
})

-- 38 Brujo → Brujalada · Biblia compacta p. 25 (fuente p. 71)
add({
	id = "brujo",
	page = 25,
	concept = "Palomilla nocturna cuyas alas cuentan sueños a quien las mira.",
	broteLook = "Palomilla peluda de antenas plumosas.",
	talladoLook = "Polilla enorme con ojos pintados en las alas y polvo de sueño en órbita.",
	mythicMix = "Palomilla nocturna + rebozo bordado + luna.",
	anatomy = "Insecto · palomilla.",
	distinctiveTrait = "Cuatro alas con ojos · antenas plumosas · índigo y violeta.",
	behavior = "Sus alas cuentan sueños a quien las mira.",
	habitat = "Velo Astral",
	obtention = OBT_EPICO,
	lineage = "Kroa + Linterno (6 %) · Ovillo + Hilacho (10 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Polvo de Sueño. +15 % de probabilidad de dormir y confundir.",
	signatureText = "Ojos de Ala. Especial · 60 · 2 Savia. 40 % de dormir.",
})

-- 39 Tizón → Tizonsierpe · Biblia compacta p. 26 (fuente p. 71)
add({
	id = "tizon",
	page = 26,
	concept = "Serpiente de fuego que protege el bosque: devora los incendios en lugar de provocarlos.",
	broteLook = "Culebrita de brasa con hojitas en la cabeza.",
	talladoLook = "Serpiente de ascuas con cresta de hojas; devora las llamas y deja brotes.",
	mythicMix = "Serpiente de fuego que protege los campos (eco tupí).",
	anatomy = "Serpentino.",
	distinctiveTrait = "Cuerpo en S · cresta de hojas · brasa y verde.",
	behavior = "Protege el bosque: devora los incendios en lugar de provocarlos y el Tallado deja brotes.",
	habitat = "Valle Copal",
	obtention = OBT_EPICO,
	lineage = "Cotorro + Zanco (6 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Guardabosque. Inmune a la quemadura; absorbe quemaduras del aliado.",
	signatureText = "Brote de Ceniza. Especial · 0 · 2 Savia. Cura 25 % al aliado y le quita la quemadura.",
})

-- 40 Tuerco → Engrifo · Biblia compacta p. 26 (fuente p. 72)
add({
	id = "tuerco",
	page = 26,
	concept = "Un grifo de latón que el Tallador armó con piezas de relojes y que aprendió a volar solo.",
	broteLook = "Cachorro de grifo de latón con alitas de hojalata y una llave de cuerda en la espalda.",
	talladoLook = "Grifo mecánico de latón: cabeza de águila, cuerpo de felino, alas de plumas-engrane y hélice en la cola.",
	mythicMix = "Grifo de la mitología griega y medieval + relojería + aviación antigua.",
	anatomy = "Quimera · grifo mecánico.",
	distinctiveTrait = "Cabeza de águila y alas de engranes · hélice · latón y cobre.",
	behavior = "Aprendió a volar solo.",
	habitat = "Meseta Fulgor",
	obtention = OBT_EPICO,
	lineage = "Garabato + Kunko (6 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Viento en Popa. +20 % VEL el primer turno.",
	signatureText = "Remada Celeste. Especial · 70 · 2 Savia. Golpea primero si tiene más VEL que el rival.",
})

-- 41 Boreal → Auroribú · Biblia compacta p. 26 (fuente p. 72)
add({
	id = "boreal",
	page = 26,
	concept = "Caribú del norte con astas hechas de aurora boreal.",
	broteLook = "Cervatillo de pelaje espeso con astas cortas de luz.",
	talladoLook = "Caribú con astas enormes de aurora que ondulan y aliento de estrellas.",
	mythicMix = "Caribú del norte + aurora boreal (eco canadiense).",
	anatomy = "Cuadrúpedo · caribú.",
	distinctiveTrait = "Astas de aurora · porte alto · crema, verde y violeta.",
	behavior = PENDIENTE,
	habitat = "Velo Astral",
	obtention = OBT_EPICO,
	lineage = "Lumbro + Medu (6 %) · Guaca + Cenoti (10 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Noche Polar. En 2v2 el aliado gana +15 % ESE.",
	signatureText = "Velo de Aurora. Especial · 0 · 2 Savia. Escudo del 20 % al equipo.",
})

-- 42 Hilacho → Titeránima · Biblia compacta p. 26 (fuente p. 73)
add({
	id = "hilacho",
	page = 26,
	concept = "Ánima que mueve una marioneta de madera desde unos hilos que nadie ve.",
	broteLook = "Titerito de madera con cara pintada y hilos sueltos.",
	talladoLook = "Marioneta alta articulada con cruceta flotante y velo de sombra; mueve los hilos del rival.",
	mythicMix = "Marioneta de hilo + teatro de títeres europeo.",
	anatomy = "Fantasmal · marioneta.",
	distinctiveTrait = "Cruceta e hilos · juntas de madera · madera y violeta.",
	behavior = "El Tallado mueve los hilos del rival.",
	habitat = "Velo Astral",
	obtention = OBT_EPICO,
	lineage = "Linterno + Remache (6 %) · Brujo + Tuerco (10 %)",
	cost = COSTE_EPICO,
	incubation = "2 h",
	talentText = "Hilos. Una vez por combate obliga al rival a repetir su acción anterior.",
	signatureText = "Tirón de Hilos. Especial · 60 · 2 Savia. El rival no puede usar especiales 1 turno.",
})

-- ===================== Legendarios =====================

-- 43 Lumbrela → Papalumen, el Vitral Vivo · Biblia compacta p. 26 (fuente p. 74)
add({
	id = "lumbrela",
	page = 26,
	concept = "La mariposa-linterna de papel picado que guía la migración de los Brotes perdidos.",
	broteLook = "Oruga-linterna con dos alitas de papel recién abiertas.",
	talladoLook = "Cuatro alas de papel picado translúcido que proyectan vitrales en el suelo; cuerpo de linterna.",
	mythicMix = "Mariposa monarca (migración) + papel picado + linterna.",
	anatomy = "Insecto · mariposa-linterna.",
	distinctiveTrait = "Alas enormes caladas · cuerpo linterna · oro, cielo y naranja. Aura dorada, vitrales proyectados y fragmentos de papel flotando.",
	behavior = "Guía la migración de los Brotes perdidos.",
	habitat = "Valle Copal",
	obtention = OBT_LEGENDARIO,
	lineage = "Guaca + Brujo (4 %) · Guaca + Nébulo (10 %)",
	cost = COSTE_LEGENDARIO,
	incubation = "8 h · Huevo legendario: papel picado dorado sobre cristal.",
	talentText = "Migración. En 2v2 el aliado gana +15 % VEL y ESE.",
	signatureText = "Vitral de Alas. Especial · 0 · 2 Savia. Refleja 30 % de especiales al equipo 2 turnos.",
})

-- 44 Geoda → Gemaboa, la Guardiana de Vetas · Biblia compacta p. 27 (fuente p. 75)
add({
	id = "geoda",
	page = 27,
	concept = "Serpiente gigante con colmillos de cristal que guarda las vetas de la montaña.",
	broteLook = "Culebrita de escamas de roca con dos colmillitos de cuarzo.",
	talladoLook = "Serpiente colosal con colmillos de cristal como de elefante y escamas de geoda.",
	mythicMix = "Serpiente que guarda diamantes (eco sudafricano) + geoda.",
	anatomy = "Serpentino · colmillos.",
	distinctiveTrait = "Cuerpo enorme en S · colmillos de cristal · piedra y cuarzo. Aura dorada con cristales flotantes.",
	behavior = "Guarda las vetas de la montaña.",
	habitat = "Cumbre Brasa",
	obtention = OBT_LEGENDARIO,
	lineage = "Chaquiro + Pelón (4 %)",
	cost = COSTE_LEGENDARIO,
	incubation = "8 h · Huevo legendario: geoda abierta con vetas de oro.",
	talentText = "Veta Madre. +10 % DEF por cada aliado de Tierra o Metal (máx. +20 %).",
	signatureText = "Colmillo de Cuarzo. Especial · 85 · 2 Savia. Rompe escudos y −15 % DEF del rival.",
})

-- 45 Nébulo → Astrocorcel, el Ocho Vientos · Biblia compacta p. 27 (fuente p. 76)
add({
	id = "nebulo",
	page = 27,
	concept = "Corcel cuyas patas se desdoblan al galopar: parece tener ocho cuando corre entre estrellas.",
	broteLook = "Potrillo de crin de nube y pezuñas de estrella.",
	talladoLook = "Corcel de crin de galaxia; al galopar aparecen patas-eco translúcidas.",
	mythicMix = "El corcel de ocho patas (eco nórdico) + constelación.",
	anatomy = "Cuadrúpedo · corcel.",
	distinctiveTrait = "Caballo alto · patas-eco · azul noche y plata. Aura dorada y patas-eco luminosas.",
	behavior = "Corre entre estrellas; al galopar sus patas se desdoblan.",
	habitat = "Velo Astral",
	obtention = OBT_LEGENDARIO,
	lineage = "Boreal + Tuerco (4 %) · Boreal + Lumbrela (10 %)",
	cost = COSTE_LEGENDARIO,
	incubation = "8 h · Huevo legendario: noche con ocho estrellas doradas.",
	talentText = "Ocho Vientos. Su VEL no puede reducirse; +10 % evasión.",
	signatureText = "Galope Estelar. Especial · 80 · 2 Savia. Prioridad +1.",
})

-- 46 Bisi → Gemitrueno, Serpiente de Dos Mareas · Biblia compacta p. 27 (fuente p. 77)
add({
	id = "bisi",
	page = 27,
	concept = "Serpiente alada de dos cabezas: una trae la lluvia y la otra el trueno.",
	broteLook = "Culebrita de dos cabecitas que discuten todo el tiempo.",
	talladoLook = "Serpiente alada de dos cabezas, una de agua y otra de rayo, con alas de nube.",
	mythicMix = "Serpiente alada de dos cabezas (eco andino) + nube de tormenta.",
	anatomy = "Serpentino · dos cabezas.",
	distinctiveTrait = "Dos cabezas · alas de nube · turquesa y amarillo. Aura dorada con lluvia y chispas.",
	behavior = "Las dos cabecitas del Brote discuten todo el tiempo; una cabeza trae la lluvia y la otra el trueno.",
	habitat = "Marea Coralina",
	obtention = OBT_LEGENDARIO,
	lineage = "Cenoti + Chaquiro (4 %)",
	cost = COSTE_LEGENDARIO,
	incubation = "8 h · Huevo legendario: dos yemas, azul y dorada.",
	talentText = "Dos Mareas. Cada turno alterna: +15 % a Agua o +15 % a Rayo.",
	signatureText = "Doble Mordida. Especial · 2 × 45 · 2 Savia. Un impacto de Agua y otro de Rayo.",
})

-- 47 Petardo → Pirotoro, el Castillo de Feria · Biblia compacta p. 27 (fuente p. 78)
add({
	id = "petardo",
	page = 27,
	concept = "El toro de fiesta: un armazón de carrizo cargado de cohetes que estalla en luces.",
	broteLook = "Becerrito de carrizo con un rehilete en el lomo.",
	talladoLook = "Toro monumental de carrizo con castillo de rehiletes encendidos sobre el lomo.",
	mythicMix = "Torito de pirotecnia de feria + castillo de fuegos.",
	anatomy = "Cuadrúpedo · toro de feria.",
	distinctiveTrait = "Toro con castillo en el lomo · chispas · rojo, oro y papel de colores. Aura dorada, chispas de colores y rehiletes flotantes.",
	behavior = PENDIENTE,
	habitat = "Cumbre Brasa",
	obtention = OBT_LEGENDARIO,
	lineage = "Cempa + Hilacho (4 %)",
	cost = COSTE_LEGENDARIO,
	incubation = "8 h · Huevo legendario: papel de colores sobre carrizo dorado.",
	talentText = "Castillo. Cada ataque que recibe carga 1 cohete (máx. 3); su Golpe Nexo hace +10 % por cohete.",
	signatureText = "Embestida de Cohetes. Especial · 85 · 2 Savia. 30 % de quemadura.",
})

-- ===================== Únicos =====================

-- 48 Mediluna → Eclipsor, el Gato de Dos Cielos · Biblia compacta p. 27 (fuente p. 79)
add({
	id = "mediluna",
	page = 27,
	concept = "Un felino partido en dos cielos: la mitad es día y la otra mitad es noche.",
	broteLook = "Gatito de pelaje perlado con media cara índigo.",
	talladoLook = "Felino flotante partido en día y noche, con corona de eclipse.",
	mythicMix = "Felino + eclipse + velo perlado e índigo.",
	anatomy = "Cuadrúpedo · felino.",
	distinctiveTrait = "Felino con anillo · mitad perla, mitad índigo. Colores propios: oro e índigo partidos, halo iridiscente y corona de eclipse.",
	behavior = PENDIENTE,
	habitat = "Velo Astral",
	obtention = OBT_UNICO,
	lineage = "—",
	cost = COSTE_UNICO,
	incubation = "24 h · Huevo único: mitad perla, mitad índigo, con un anillo dorado.",
	talentText = "Dos Cielos. Al entrar elige Día (+20 % curación) o Noche (+20 % daño de Sombra).",
	signatureText = "Corona del Eclipse. Especial · 80 · 2 Savia. Anula 1 mejora del rival.",
})

-- 49 Nácar → Aetherion, la Ballena Cartógrafa · Biblia compacta p. 28 (fuente p. 80)
add({
	id = "nacar",
	page = 28,
	concept = "Ballena gris que nada por el cielo nocturno dibujando mapas de estrellas.",
	broteLook = "Ballenato que flota con una brújula de nácar en la frente.",
	talladoLook = "Ballena colosal que nada en el cielo con un mapa estelar grabado en el lomo.",
	mythicMix = "Ballena gris + mapa celeste + brújula.",
	anatomy = "Acuático · ballena del cielo.",
	distinctiveTrait = "Ballena flotante · mapa en el lomo · nácar y aurora. Colores propios: nácar y aurora, halo iridiscente.",
	behavior = "Nada por el cielo nocturno dibujando mapas de estrellas.",
	habitat = "Velo Astral",
	obtention = OBT_UNICO,
	lineage = "—",
	cost = COSTE_UNICO,
	incubation = "24 h · Huevo único: nácar con un mapa estelar grabado.",
	talentText = "Canto Cartógrafo. Al entrar revela las debilidades del rival y da +10 % de daño al equipo contra ellas.",
	signatureText = "Canto Profundo. Especial · 60 · 2 Savia. Cura 20 % al equipo y duerme 20 %.",
})

-- ===================== Misterio =====================

-- 50 Nex → Nexum, el Gabinete que Camina · Biblia compacta p. 28 (fuente p. 81)
-- Aviso: la ficha da «Final del Acto III («La Primera Talla»)», pero p. 12 hace que el Ánima
-- del Nexo (jefe del Final) entregue el Huevo del Gabinete y p. 32 dice «Final de la historia».
add({
	id = "nex",
	page = 28,
	concept = "La última talla del Tallador: un gabinete de curiosidades que camina, guarda y devuelve.",
	broteLook = "Cofre vertical de copal con un solo ojo-cerradura, tres patas distintas (tlacuache, grulla y engrane) y un halo de triángulo imposible.",
	talladoLook = "El gabinete se abre en abanico de cajones-bioma; por la cerradura se ve una escalera que sube y baja a la vez.",
	mythicMix = "Gabinete de curiosidades + máquinas místicas de Remedios Varo + escaleras imposibles.",
	anatomy = "Objeto animado · gabinete.",
	distinctiveTrait = "Rectángulo vertical · cajones en abanico · copal, latón y violeta. Aura: geometría imposible, damero flotante y cajones desfasados.",
	behavior = "Camina, guarda y devuelve. El Gabinete anciano, adulto de la especie, es ceremonioso, coleccionista y bromista; habla por cajones y nunca miente sobre lo que hay dentro (p. 12).",
	habitat = "Torre del Nexo",
	obtention = "Final del Acto III («La Primera Talla»). Uno por cuenta.",
	lineage = "—",
	cost = "5 (Brote 4) · Tallado: nivel 25",
	incubation = "72 h · Huevo del Gabinete: copal con cajoncitos y cerradura.",
	talentText = "Eco. En cada combate adopta un elemento neutral frente al rival.",
	signatureText = "Cajón que Guarda. Especial · 0 · 2 Savia. Guarda el siguiente especial que reciba (lo bloquea).",
})

return Freeze.deep({
	ById = Lore,
})
