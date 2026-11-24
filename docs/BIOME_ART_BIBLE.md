# NEXORA · Biblia de arte de los biomas

**Estado:** documento hijo de `ART_BIBLE_GENESIS.md`. Lo desarrolla y no lo contradice.
- **Valle Copal:** existe en Roblox como blockout trabajado (`WORLD_BUILDING.md`). Este documento lo describe y propone su evolución.
- **Marea Coralina, Cumbre Brasa, Meseta Fulgor y Velo Astral:** son **PROPUESTA**. No hay nada construido de ellos, salvo sus puertas selladas en la Torre del Nexo (`TorreBuilder`: ola, llama, rayo y estrella de ocho puntas).
- Marea Coralina y Meseta Fulgor son, además, biomas propuestos por la propia Biblia (pregunta 18).

**Fuentes:**
- Biblia p. 6–10 (mapa, biomas, nativos), p. 13–15 (Seres Sagrados) y p. 113 (jefes y fases);
- identidad, paleta y elementos de cada bioma: fijados por el responsable de producto en el encargo de la Fase 3;
- `Config/BiomeArt.luau`: paleta, luz, terreno, agua, niebla y datos de las muestras;
- `Config/AudioCues.luau`: capas de ambiente y música.

**Documentos hermanos:**
- `LIGHTING_DIRECTION.md` §4 (preajustes);
- `MATERIAL_LIBRARY.md` §2 y §5 (materiales y terreno);
- `AUDIO_DIRECTION.md` (sonido);
- `PERFORMANCE_BUDGET.md` (presupuestos).

---

## 0. Reglas comunes

- **Un bioma se reconoce sin leer** por cuatro cosas:
  - su **silueta de horizonte** (cuenco, arrecife, cono, meseta, islas);
  - su **color dominante** (§x.2);
  - su **luz** (§x.7);
  - su **material firma** (copal, coral, barro al fuego, cobre, nube).
- **Paletas:**
  - pigmentos ≤ 70 % de saturación;
  - emisivos aparte;
  - un color dominante y dos de apoyo por bioma (Genesis §4.1).
- **Escala** (Genesis §2):
  - el jugador mide 5 studs;
  - caminos de 8–12;
  - un Ser Sagrado mide 14–22;
  - un landmark de bioma mide **30–64 studs**: entre una estación (12–20) y el Gran Nexo (90–120). Se reconoce desde la entrada de su muestra.
- **Terreno antes que Parts** en el paisaje; Parts y mallas para arquitectura y props; instancias repetidas como plantillas clonadas con semilla fija (Genesis §9).
- **Restaurar, no destruir** (Biblia p. 112): un bioma **opacado** usa el modificador `Opacado` de `BiomeArt` (saturación −0,55, tinte gris cálido; Genesis §4.1, regla 5). Al restaurar a su guardián, el color vuelve en 5 s.
- **Originalidad** (Genesis §10):
  - sin deidades, templos reales copiados ni símbolos sagrados;
  - sin siluetas de franquicias.
  - Cada bioma lista además sus formas prohibidas propias.
- **Moodboards:** descritos con palabras, sin imágenes con derechos. Son referencias de forma, material y luz; ninguna obra concreta.

---

## 1. Valle Copal · el centro

**Identidad (producto):**
- **Tema:** naturaleza, copal, ríos, chinampas, mercados y centro del mundo.
- **Colores:** verdes cálidos, jade, beige, ocres y turquesa.
- **Elementos:** Flora, Tierra y Aire. **Guardiana:** Copalia, la Garza de Raíces.
- **Nativos con bono** (Biblia p. 9): Ascuacho, Xolossus, Mitlaxis, Cantagólem, Navajazul, Hercuerno, Candelux y Faroibex, entre otros.

### 1.1. Moodboard
1. Chinampas con ahuejotes alineados en la orilla, reflejados en agua quieta.
2. Calle de mercado con toldos de manta inclinados, varas de carrizo y faldones a franjas.
3. Cerámica roja apilada al sol, con bocas oscuras y polvo de barro.
4. Papel picado a contraluz de tarde: las sombras recortadas en el suelo.
5. Muros de piedra con grecas escalonadas en relieve (lenguaje de Mitla), sin copiar ningún edificio.
6. Un árbol antiguo de tronco trenzado cuyas raíces levantan las losas.
7. Faroles de copal translúcido colgando de las ramas, con un núcleo cálido.
8. Bancales de milpa y magueyes en una ladera, con muros de piedra seca.
9. Canoas de madera mecidas junto a un embarcadero de tablones.
10. Bruma ámbar de tarde que aclara las lomas lejanas hasta un verde frío.

### 1.2. Paleta, terreno y agua (`BiomeArt.ValleCopal`; los colores salen de `Config/Ambience`)
| Color | Hex | RGB | Tipo | Sat. | Función |
|---|---|---|---|---|---|
| copal | `#E8A848` | 232, 168, 72 | Pigmento | 69 % | Copal: escalonados de la plaza, toldos, interfaz |
| copalLuz | `#FFC460` | 255, 196, 96 | Emisivo | 62 % | Faroles, corazón del Gran Nexo, vetas de luz |
| jade | `#3E967A` | 62, 150, 122 | Pigmento | 59 % | Agua de chinampa, azulejo, acciones de cuidado |
| jadeSombra | `#2F6E5C` | 47, 110, 92 | Pigmento | 57 % | Sombra fría de referencia (Ambient y ColorShift_Bottom) |
| turquesa | `#4FA9A3` | 79, 169, 163 | Pigmento | 53 % | Cintas, azulejos y vitral de la puerta de la Marea |
| hoja | `#56965C` | 86, 150, 92 | Pigmento | 43 % | Copas y praderas |
| hojaProfunda | `#3B6E44` | 59, 110, 68 | Pigmento | 46 % | Copas en sombra, sotobosque |
| piedra | `#C4B6A0` | 196, 182, 160 | Pigmento | 18 % | Piedra clara de la plaza |
| adobe | `#D6AA80` | 214, 170, 128 | Pigmento | 40 % | Adobe encalado de casas y talleres |
| ocre | `#C08A44` | 192, 138, 68 | Pigmento | 65 % | Petates, tejas viejas, costales |
| barro | `#B06240` | 176, 98, 64 | Pigmento | 64 % | Cerámica roja, tejas |
| corteza | `#60463A` | 96, 70, 58 | Pigmento | 40 % | Gran Nexo, vigas, troncos |
| cacao | `#3A271D` | 58, 39, 29 | Pigmento | 50 % | Sombra de la arquitectura, interiores |
| cempasuchil | `#EC9848` | 236, 152, 72 | Pigmento | 69 % | Cempasúchil (bajo el tope de saturación) |
| bugambilia | `#D6548C` | 214, 84, 140 | Pigmento | 61 % | Bugambilias y papel picado |

| Material base | MaterialVariant | Hex | Sat. | Uso |
|---|---|---|---|---|
| `Grass` | `MAT_ValleCopal_Pasto` | `#689854` | 45 % | Praderas con Terrain.Decoration |
| `LeafyGrass` | `MAT_ValleCopal_Sotobosque` | `#4E804A` | 42 % | Base de los lotes, bancales, bajo los árboles |
| `Ground` | `MAT_ValleCopal_TierraCamino` | `#9E7A58` | 44 % | Caminos (Landscape.Paths) y bancales |
| `Slate` | `MAT_ValleCopal_MuroTerraza` | `#70685C` | 18 % | Muros de las terrazas |
| `Mud` | `MAT_Global_Lodo` | `#6C523E` | 43 % | Orillas del río y chinampas; manglar de la Marea |
| `Sand` | `MAT_Global_Arena` | `#CCB890` | 29 % | Bancos del río; playas de la Marea |
| `Rock` | `MAT_Global_Roca` | `#80786E` | 14 % | Afloramientos y cascada; base de las islas del Velo |
| `Basalt` | `MAT_Global_Basalto` | `#54525C` | 11 % | Linde y afloramientos; coladas de la Cumbre |

Agua: `WaterColor` (58, 138, 120) · `WaterTransparency` 0,55 · `WaterReflectance` 0,25 · `WaterWaveSize` 0,06 · `WaterWaveSpeed` 6. Niebla (color de `Atmosphere` en Tarde): (232, 200, 166).

### 1.3. Materiales
- **Firma:** copal pulido en faroles, en el corazón del Nexo y en las cúpulas del Criadero.
- **Base:** piedra clara (`Slate`), adobe (`Plaster`), madera (`Wood`), tejas (`ClayRoofTiles`), telas de toldo (`Fabric`) y barro cocido.
- **Variantes propuestas** (`MATERIAL_LIBRARY.md` §5.2): `MAT_ValleCopal_Pasto`, `_Sotobosque`, `_TierraCamino`, `_MuroTerraza` y las globales de lodo, arena, roca y basalto.

### 1.4. Arquitectura
Lo construido (`WORLD_BUILDING.md` §4–7):
- adobe y piedra, techos de teja, cornisas escalonadas con greca y vanos en arco rebajado;
- cada estación con su remate visible a 80 studs: cúpula, mástil, cresta, espadaña o pérgola;
- el Gran Nexo (~105 studs) como ancla.

### 1.5. Vegetación
Ahuejote, copal, sabino y colorín, más árboles opacados en la Linde (W-8). También arbustos, bugambilia, magueyes, milpa, juncos y tules, nenúfares y cempasúchil (`Ambience.Flora`, `FloraBuilder`).

### 1.6. Terreno
Cuenco con lomas de 50–90 studs alrededor de un llano jugable plano a Y = 0. Río que serpentea (14 puntos), lago de las chinampas, cascada al este y terrazas al noreste (`Landscape`, `Landform`).

### 1.7. Iluminación
`LIGHTING_DIRECTION.md` §4.1. La tarde dorada (15,9) es la de `Ambience` (D-035).

### 1.8. Atmósfera y clima
- Bruma ámbar con densidad 0,34.
- Nubes al 50 %.
- Clima: sin lluvia en la beta. La propuesta es una llovizna de tarde como evento visual (pregunta 87: eventos de mundo semanales).

### 1.9. Partículas (lo construido)
Siete emisores, 42 partículas/s en total (medido, `PERFORMANCE_BUDGET.md` §8):
- motas de copal sobre la plaza (8/s);
- chispas del corazón (6/s);
- humo del horno (4/s);
- bruma de la cascada (12/s);
- niebla de los tres Opacos de la Linde.

### 1.10. Sonido
- **Ambiente:** `AMB_ValleCopal_Base`, `_Water`, `_Fauna` y `_Market`.
- **Música:** `MUS_ValleCopal_Explore`, `_Battle`, `_Boss` y `_Victory`.
- Detalle en `AUDIO_DIRECTION.md` §3.1.

### 1.11. Elementos interactivos
El corazón del Nexo (menú), las siete estaciones, los huevos iniciales, los lotes (hábitat, recolector, incubadora, vitrina), el Gabinete que Camina y los tres Opacos de la Linde.

### 1.12. Monumentos
- el Gran Nexo;
- la estela de greca de la plaza (y su gemela caída en la Linde);
- las cuatro puertas de los biomas.

### 1.13. Tres lugares de interés
1. **Plaza del Nexo:** llegada, papel picado en proscenio y el corazón en el eje.
2. **Río y Lago de las Chinampas:** puentes en arco, canoas y cempasúchil a la deriva.
3. **La Linde:** el valle pierde el color; basalto, juncos secos y una estela caída.

### 1.14. Guardiana y restauración
**Copalia** (Biblia p. 13): garza colosal con patas de raíces y alas tejidas de hojas y faroles.

| Opacada | Restaurada |
|---|---|
| Las raíces se secan, los faroles se apagan, el valle pierde el color | Modificador `Opacado` → preajuste en 5 s |

Al restaurarla:
- se encienden uno a uno los diez faroles del Gran Nexo;
- la Linde recupera el verde, por manchas, del borde al centro;
- los árboles opacados brotan.
- Efecto de juego: hábitats del Valle con +10 % de XP.

**Fase 2 del combate:** `LIGHTING_DIRECTION.md` §7.2.

### 1.15. Formas que NO deben aparecer
- calendarios de piedra o pirámides reconocibles copiadas;
- serpientes emplumadas;
- altares u ofrendas religiosas;
- calaveras como decoración;
- cruces;
- el «árbol de la vida» de cerámica como objeto ritual.

### 1.16. Prueba de reconocimiento
> Se reconoce sin leer el nombre porque un árbol de copal de 100 studs domina un cuenco verde y cálido, con agua jade, papel picado y bruma ámbar.

---

## 2. Marea Coralina · arrecifes y cenotes

**Identidad (producto):**
- **Tema:** arrecifes, manglares, cenotes, túneles de luz, cuevas y ruinas sumergidas.
- **Colores:** turquesa, coral, azules profundos y violeta.
- **Elementos:** Agua, Mente y Astral. **Guardián:** Marejadra, el Hipocampo de Coral.
- **Nativos** (Biblia p. 9): Mantaraz, Krakensa, Fatuoscuro, Alamar, Lorapiente, Cometaura, Leviacielo y Gemitrueno.

### 2.1. Moodboard
1. Manglar de raíces zancudas sobre agua turquesa somera.
2. Boca de cenote en roca caliza, con un haz de luz vertical que cae al agua.
3. Arrecife de corales de cuerno y abanicos con peces de colores apagados.
4. Columnas genéricas caídas bajo el agua, cubiertas de coral (ninguna ruina real).
5. Muelles de pescadores de madera gris, con redes tendidas y boyas de calabaza.
6. Medusas como faroles de papel de china flotando en una cueva.
7. Conchas de nácar y caracolas con espirales (Mente).
8. Túnel de luz: una grieta en la roca por la que entra el sol y forma bandas.
9. Reflejo de las estrellas en el agua quieta del cenote de noche (Astral).
10. Espuma blanca en la orilla del arrecife, sobre arena clara.

### 2.2. Paleta, terreno y agua (`BiomeArt.MareaCoralina`)
| Color | Hex | RGB | Tipo | Sat. | Función |
|---|---|---|---|---|---|
| turquesa | `#38A8A6` | 56, 168, 166 | Pigmento | 67 % | Agua somera, azulejo, color que define el bioma |
| turquesaClara | `#8FD3C8` | 143, 211, 200 | Pigmento | 32 % | Espuma, arena mojada, reflejos |
| coral | `#E07A5F` | 224, 122, 95 | Pigmento | 58 % | Coral vivo, acentos cálidos |
| coralClaro | `#F2B8A2` | 242, 184, 162 | Pigmento | 33 % | Coral a contraluz, conchas |
| azulProfundo | `#28507A` | 40, 80, 122 | Pigmento | 67 % | Fondo del cenote, agua profunda |
| azulNoche | `#1C3352` | 28, 51, 82 | Pigmento | 66 % | Cuevas y sombras sumergidas |
| violeta | `#6E5A9E` | 110, 90, 158 | Pigmento | 43 % | Medusas y perlas en sombra (Mente) |
| arena | `#E3D3B0` | 227, 211, 176 | Pigmento | 22 % | Arena de arrecife |
| caliza | `#BFB59E` | 191, 181, 158 | Pigmento | 17 % | Paredes del cenote y ruinas |
| mangle | `#5C6B3E` | 92, 107, 62 | Pigmento | 42 % | Raíces y copas del manglar |
| perla | `#DDF4F0` | 221, 244, 240 | Emisivo | 9 % | Perlas de Marejadra encendidas |
| bioluz | `#5FE3D0` | 95, 227, 208 | Emisivo | 58 % | Medusas y túneles de luz |

| Material base | MaterialVariant | Hex | Sat. | Uso |
|---|---|---|---|---|
| `Sand` | `MAT_Global_Arena` | `#CCB890` | 29 % | Playas y bancos de arena del arrecife |
| `Mud` | `MAT_Global_Lodo` | `#6C523E` | 43 % | Fango del manglar |
| `Limestone` | `MAT_MareaCoralina_CalizaCenote` | `#BDB39A` | 19 % | Paredes y bóvedas del cenote |
| `Salt` | `MAT_MareaCoralina_Coral` | `#C98A78` | 40 % | Roca de coral (desaturada; el coral vivo son mallas) |
| `Pavement` | `MAT_MareaCoralina_LosaSumergida` | `#8A9690` | 8 % | Losas de las ruinas sumergidas |

Agua: `WaterColor` (56, 158, 156) · `WaterTransparency` 0,78 · `WaterReflectance` 0,35 · `WaterWaveSize` 0,12 · `WaterWaveSpeed` 8. Niebla (color de `Atmosphere` en Tarde): (172, 212, 216).

### 2.3. Materiales
- **Firma:** coral (`Salt` + mallas pintadas), caliza (`Limestone`), cerámica vidriada (azulejo de agua) y nácar (cristal opaco pintado).
- **Apoyo:** madera gris de muelle (`WoodPlanks`) y cuerda.

### 2.4. Arquitectura
Casas palafito de madera con techos de palma, sobre pilotes en el manglar. Columnas y escalinatas sumergidas de piedra genérica, con grecas de ola, nunca de un templo real. Arcos de coral crecidos como arquitectura viva.

### 2.5. Vegetación (o equivalente)
Mangle con raíces zancudas, pastos marinos que ondulan, coral de cuerno, abanicos de coral, esponjas en tubo y algas en cinta. El coral es la «vegetación» del bioma.

### 2.6. Terreno
Bancos de arena que bajan en escalones a una laguna somera de 2–4 studs y a cenotes profundos de 12–20. Islotes de caliza y manglar. El agua cubre el 40–50 % de la superficie.

### 2.7. Iluminación
`LIGHTING_DIRECTION.md` §4.2: sol alto (47°) para que la luz entre en el agua; noche bioluminiscente.

### 2.8. Atmósfera y clima
- Bruma clara turquesa (0,33).
- Sin tormentas.
- Marea alta como evento semanal (pregunta 87): el agua sube 2 studs.

### 2.9. Partículas
- burbujas que suben del cenote (10/s);
- motas de luz en el túnel (15/s);
- luciérnagas del manglar al anochecer (15/s);
- espuma de la orilla: textura del material, sin emisor.

### 2.10. Sonido
- **Ambiente:** `AMB_MareaCoralina_Base`, `_Waves` y `_Fauna`.
- **Música:** `MUS_MareaCoralina_*`.
- Detalle en `AUDIO_DIRECTION.md` §3.2.

### 2.11. Elementos interactivos
Perlas que se encienden al acercarse (Mente), medusas-farol que se pueden seguir, corrientes que empujan una canoa y caracolas que suenan al tocarlas.

### 2.12. Monumentos
- el **Arco de Marejadra** (landmark de la muestra);
- el Gran Cenote;
- la Escalinata Sumergida.

### 2.13. Tres lugares de interés
1. **Cenote de la Corona:** el arco y el haz de luz.
2. **Manglar de los Pescadores:** palafitos y muelle.
3. **Túnel de Luz:** la grieta que conecta el cenote con el arrecife abierto.

### 2.14. Guardián y restauración
**Marejadra** (Biblia p. 13): hipocampo colosal con crin de coral vivo y una corona de perlas que guardan las memorias del mar.

| Opacado | Restaurado |
|---|---|
| El coral se blanquea y las perlas se apagan. El coral del bioma pasa a `#C9C4BA`, el agua pierde transparencia (0,78 → 0,5) y desaparecen las medusas | El coral vuelve de las raíces del arco hacia fuera, las perlas se encienden y regresan los peces. Efecto de juego: lotes de la Marea con +10 % de XP |

### 2.15. Formas que NO deben aparecer
- tridentes y dioses marinos;
- sirenas o hipocampos de franquicias;
- Atlántida con columnas griegas reconocibles;
- máscaras de deidades de la lluvia en los cenotes;
- calaveras de pirata;
- anfibios azules con burbujas (Genesis §10).

### 2.16. Prueba de reconocimiento
> Se reconoce sin leer el nombre porque el suelo es agua turquesa clara con coral de color coral, la luz cae en columnas dentro de un cenote de caliza y todo brilla en violeta de noche.

### 2.17. Muestra ambiental (120 × 120)

```
            N (Z −60)
  ┌──────────────────────────────┐
  │≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈▓▓▓T▓▓▓▓│  T  salida del túnel de luz (36, −6, −44)
  │≈≈≈≈≈≈≈╭───ARCO───╮≈≈≈≈▓▓▓▓▓▓│  ▓  caliza
  │≈≈≈≈≈≈≈│  cenote  │≈≈≈≈≈≈≈≈≈≈│  Arco de Marejadra (0, 0, −30), 36 × 30 × 14
  │♣♣≈≈≈≈≈╰──────────╯≈≈≈≈≈≈≈≈≈≈│  cenote Ø 40, fondo −16
  │♣♣♣♣ M · · · · ·  ░░░░≈≈≈≈≈≈≈│  M  mirador (−20, 0, −4) · ░ ruinas sumergidas
  │♣♣♣♣════ muelle ══ ░░░░≈≈≈≈≈≈│  ♣  manglar
  │♣♣♣ ·   ≈≈ arrecife ≈≈≈≈≈≈≈≈≈│
  │♣♣  ·    :::::: arena :::::  │
  │      ·  :::::::::::::::::   │
  │        ·::::::: E ::::::    │  E  entrada (0, 0, 56)
  └──────────────────────────────┘
            S (Z +60)
```

**Recorrido** (`BiomeArt.MareaCoralina.sample.path`): entrada (0, 0, 56) → manglar (−30, 0, 22) → mirador (−20, 0, −4) → borde del cenote (0, 0, −10) → bajo el arco, 6 studs más abajo (0, −6, −30) → salida del túnel (36, −6, −44). El arco se ve desde la entrada (a 86 studs; se reconoce a 120).

**Presupuesto:** 30 rellenos · 380 partes · 5 luces · 3 emisores · 40 partículas/s.

| Concepto | Desglose |
|---|---|
| Rellenos de terreno (30) | Base de arena 120 × 8 × 120 (1) · paredes del cenote en caliza (8) · vaciado del cenote con `Air` (1) · agua del cenote y de la laguna (3) · roca de coral `Salt` (10) · losas sumergidas `Pavement` (3) · fango del manglar `Mud` (4) |
| Partes (380) | Arco de Marejadra 90 · ruinas sumergidas 70 · muelle y mirador 60 · manglar (raíces y copas, plantillas) 80 · coral suelto 50 · medusas-farol 15 · varios 15 |
| Luces (5) | 3 perlas del arco (`PointLight` 10) · 1 `SurfaceLight` en el túnel (12) · 1 medusa-farol del muelle (8) |
| Emisores (3) | Burbujas del cenote 10/s · motas del túnel 15/s · luciérnagas del manglar 15/s |

---

## 3. Cumbre Brasa · volcanes y forjas

**Identidad (producto):**
- **Tema:** volcanes, hornos de barro, herrerías, hojalata, forjas y lava domesticada.
- **Colores:** naranja, cobre, rojo volcánico, piedra oscura y oro cálido.
- **Elementos:** Fuego, Metal y Tierra. **Guardián:** Obsidárion, el Coloso de la Fragua.
- **Nativos** (Biblia p. 9): Magmadillo, Quiotazo, Coatitán, Magmacrán, Grullacandil, Zopilatón, Gemaboa y Pirotoro.
- **«Atardeceres naranjas y ríos de lava domesticada»** (Biblia p. 9).

### 3.1. Moodboard
1. Hornos de barro en cúpula con boca en arco y el interior al rojo.
2. Comales de barro sobre fogones de piedra, con humo blanco.
3. Herrería con yunque, fuelle de cuero y herramientas colgadas.
4. Hojalata repujada en faroles, marcos y techos que brillan al atardecer.
5. Volcán joven de laderas negras, con coladas en terrazas.
6. Canales de lava encauzados con piedra como acequias, con puentes encima.
7. Chimeneas de cobre con remates martillados y pátina verde.
8. Cerros de ceniza gris con caminos en zigzag.
9. Vetas de obsidiana brillante en paredes de basalto.
10. Atardecer naranja en el que el humo se vuelve rosa.

### 3.2. Paleta, terreno y agua (`BiomeArt.CumbreBrasa`)
| Color | Hex | RGB | Tipo | Sat. | Función |
|---|---|---|---|---|---|
| naranjaHorno | `#D68A48` | 214, 138, 72 | Pigmento | 66 % | Barro cocido al fuego, toldos de herrería |
| cobre | `#B8734A` | 184, 115, 74 | Pigmento | 60 % | Cobre martillado, calderos, canales |
| rojoVolcanico | `#9A4232` | 154, 66, 50 | Pigmento | 68 % | Roca volcánica oxidada, tejas de forja |
| piedraOscura | `#3E3A3C` | 62, 58, 60 | Pigmento | 6 % | Basalto, muros de forja |
| ceniza | `#7A7270` | 122, 114, 112 | Pigmento | 8 % | Ceniza, caminos, Opaco |
| oroCalido | `#D9A64E` | 217, 166, 78 | Pigmento | 64 % | Remates de latón y oro cálido |
| hojalata | `#A8A39A` | 168, 163, 154 | Pigmento | 8 % | Hojalata repujada de faroles y techos |
| barroHorno | `#A65A3A` | 166, 90, 58 | Pigmento | 65 % | Hornos de barro |
| obsidiana | `#1E1A22` | 30, 26, 34 | Pigmento | 24 % | Obsidiana de Obsidárion y de los filos |
| lava | `#FF7A2E` | 255, 122, 46 | Emisivo | 82 % | Lava domesticada y bocas de horno |
| brasa | `#FFB347` | 255, 179, 71 | Emisivo | 72 % | Brasas y chispas |

| Material base | MaterialVariant | Hex | Sat. | Uso |
|---|---|---|---|---|
| `Basalt` | `MAT_Global_Basalto` | `#54525C` | 11 % | Coladas frías y laderas del volcán |
| `CrackedLava` | `MAT_CumbreBrasa_LavaDomada` | `#5A3A30` | 47 % | Lava domesticada (las grietas brillan con la textura) |
| `Asphalt` | `MAT_CumbreBrasa_Ceniza` | `#5E5856` | 9 % | Ceniza fina en caminos y patios |
| `Brick` | `MAT_CumbreBrasa_AdobeHorno` | `#9C5A3C` | 62 % | Montículos de adobe de los hornos |

Agua: `WaterColor` (96, 120, 110) · `WaterTransparency` 0,5 · `WaterReflectance` 0,2 · `WaterWaveSize` 0,05 · `WaterWaveSpeed` 4. Niebla (color de `Atmosphere` en Tarde): (222, 144, 96).

### 3.3. Materiales
- **Firma:** barro al fuego, cobre martillado y basalto con vetas de obsidiana.
- **Apoyo:** hojalata repujada, latón, adobe de horno (`Brick`) y lava (`CrackedLava` + `Neon` ≤ 1,5 + `PointLight`).

### 3.4. Arquitectura
- Talleres de adobe rojo y piedra oscura, con techos de lámina repujada.
- Hornos en cúpula de varios tamaños.
- Chimeneas de cobre como remates: la silueta del bioma son las chimeneas humeando.
- Puentes de piedra con barandal de hierro.

### 3.5. Vegetación (o equivalente)
Escasa y resistente: magueyes y nopales de un verde gris, pastos secos dorados y árboles quemados que rebrotan. Lo «vivo» del bioma es el fuego domesticado: hornos, braseros y canales.

### 3.6. Terreno
Cono volcánico de 50–70 studs con terrazas de basalto. Coladas frías en lenguas. Canales de lava de 4–6 studs de ancho, siempre con borde de piedra y cruzables por puentes (nunca un suelo de lava que se pisa). Caminos de ceniza.

### 3.7. Iluminación
`LIGHTING_DIRECTION.md` §4.3. El sol bajo (11°) y `ColorShift_Bottom` rojo simulan el rebote de la lava desde abajo.

### 3.8. Atmósfera y clima
- Bruma densa de ceniza (0,37) con glare.
- Lluvia de ceniza fina como evento.
- Nunca humo que tape el camino.

### 3.9. Partículas
- chispas de la fragua (20/s, el tope);
- humo de chimenea (10/s);
- brasas sobre los canales (15/s);
- vapor de las aguas termales (15/s).

### 3.10. Sonido
- **Ambiente:** `AMB_CumbreBrasa_Base`, `_Lava` y `_Wind`.
- **Música:** `MUS_CumbreBrasa_*`.
- Detalle en `AUDIO_DIRECTION.md` §3.3.

### 3.11. Elementos interactivos
Fuelles que avivan un horno al pisarlos, yunques que suenan, compuertas de lava que cambian el cauce y braseros que se encienden al pasar.

### 3.12. Monumentos
- la **Fragua Mayor** (landmark de la muestra);
- el Escudo de Comal en la ladera;
- el Puente de los Herreros.

### 3.13. Tres lugares de interés
1. **Fragua Mayor:** horno-volcán con chimenea de cobre.
2. **Calle de los Hojalateros:** faroles y espejos de lata al atardecer.
3. **Terrazas de Lava:** canales en cascada con puentes.

### 3.14. Guardián y restauración
**Obsidárion** (Biblia p. 14): coloso bípedo de obsidiana con un corazón de fragua y un escudo de comal.

| Opacado | Restaurado |
|---|---|
| La fragua se enfría y la obsidiana se cubre de ceniza gris. Los canales pasan a `CrackedLava` sin luz, se apagan las `PointLight` y cesan chispas y humo | Los canales se encienden de arriba abajo, la Fragua Mayor vuelve a humear y los hornos se encienden en cadena. Efecto de juego: mejora de hábitat de nivel 5 |

### 3.15. Formas que NO deben aparecer
- torres oscuras de fantasía épica reconocibles;
- dioses herreros clásicos;
- cuernos y alas demoníacas;
- calaveras en las forjas;
- lava como trampa mortal;
- zorros de fuego de varias colas (Genesis §10).

### 3.16. Prueba de reconocimiento
> Se reconoce sin leer el nombre porque un cono negro con chimeneas de cobre humeantes se recorta contra un cielo naranja, y en el suelo corren canales de lava entre piedra oscura.

### 3.17. Muestra ambiental (120 × 120)

```
            N (Z −60)
  ┌──────────────────────────────┐
  │▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲│  ▲  ladera del cono (basalto)
  │▲▲▲▲▲▲▲  ╔═FRAGUA═╗ ▲▲▲▲▲▲▲▲▲│  Fragua Mayor (0, 0, −28), 40 × 48 × 40
  │▲▲▲▲▲▲   ║ MAYOR  ║   ▲▲▲▲▲▲▲│  boca de la fragua (0, 8, −10)
  │▲▲▲▲     ╚════════╝     ▲▲▲▲▲│
  │▲▲   ≈≈≈≈≈≈ terraza ≈≈≈≈ H ▲▲│  H  herrería (28, 2, 10) · ≈ canal de lava
  │▲  ~~termal~~  · ·  ≈≈≈≈≈   ▲│
  │   ≈≈≈≈≈≈≈≈≈═PUENTE═≈≈≈≈≈≈   │  puente (0, 0, 30)
  │   ceniza · · · · · ceniza   │
  │        · · · · ·            │
  │            E                │  E  entrada (0, 0, 56)
  └──────────────────────────────┘
            S (Z +60)
```

**Recorrido:** entrada (0, 0, 56) → puente sobre el canal (0, 0, 30) → herrería (28, 2, 10) → terraza del horno (12, 6, −4) → boca de la fragua (0, 8, −10). La chimenea se ve desde la entrada (se reconoce a 160 studs).

**Presupuesto:** 34 rellenos · 420 partes · 6 luces · 4 emisores · 60 partículas/s.

| Concepto | Desglose |
|---|---|
| Rellenos de terreno (34) | Base de basalto (1) · cono (4) · terrazas (8) · canal de lava `CrackedLava` (6) · caminos de ceniza `Asphalt` (8) · montículos de adobe `Brick` (4) · agua termal (2) · vaciado de la boca con `Air` (1) |
| Partes (420) | Fragua Mayor 140 · dos herrerías 110 · puentes y barandales 40 · props (yunques, comales, faroles de lata) 80 · tiras de `Neon` del canal (≤ 1,5) 20 · rocas 30 |
| Luces (6) | Boca de la fragua (`PointLight` 12, `Brightness` 1,5) · 2 faroles de hojalata (8) · 2 hornos pequeños (8) · canal bajo el puente (12) |
| Emisores (4) | Chispas de la fragua 20/s · humo de la chimenea 10/s · brasas del canal 15/s · vapor termal 15/s |

---

## 4. Meseta Fulgor · tormentas y autómatas

**Identidad (producto):**
- **Tema:** tormentas perpetuas, torres de cobre, molinos y talleres de autómatas que se cargan con los rayos.
- **Colores:** azul eléctrico, amarillo, cobre, gris de tormenta y destellos blancos.
- **Elementos:** Rayo, Artificio y Metal. **Guardián:** Fulgorón, el Tigre del Trueno.
- **Nativos** (Biblia p. 10): Chicharrayo, Turbinón, Voltalope, Fulminave, Mechalata, Fulgurila y Engrifo.

### 4.1. Moodboard
1. Meseta de estratos ocres bajo nubes de tormenta bajas y permanentes.
2. Torres de cobre con bobinas apiladas y pararrayos en la punta.
3. Molinos de aspas de madera y lona, con ejes de latón.
4. Talleres de autómatas con poleas, engranes y correas a la vista.
5. Cables tendidos entre postes que zumban.
6. Placas vítreas de fulgurita donde cayó un rayo.
7. Juguetes de cuerda y rehiletes de lata gigantes como señales.
8. Charcos que reflejan el destello del relámpago.
9. Franjas amarillas de aviso pintadas en máquinas viejas.
10. Pasarelas de rejilla metálica sobre barrancos.

### 4.2. Paleta, terreno y agua (`BiomeArt.MesetaFulgor`)
| Color | Hex | RGB | Tipo | Sat. | Función |
|---|---|---|---|---|---|
| azulTaller | `#4682CF` | 70, 130, 207 | Pigmento | 66 % | Esmalte de los talleres y señales |
| amarilloMaquina | `#E3C04A` | 227, 192, 74 | Pigmento | 67 % | Pintura de máquinas, franjas de aviso |
| cobre | `#B87A50` | 184, 122, 80 | Pigmento | 57 % | Torres y bobinas de cobre |
| patina | `#6FA08E` | 111, 160, 142 | Pigmento | 31 % | Pátina verde en los huecos del cobre |
| grisTormenta | `#6C7380` | 108, 115, 128 | Pigmento | 16 % | Roca y cielo bajo la tormenta |
| grisHierro | `#3E434D` | 62, 67, 77 | Pigmento | 19 % | Hierro, sombras de talleres |
| estrato | `#9C8A72` | 156, 138, 114 | Pigmento | 27 % | Estratos de la meseta |
| maderaMolino | `#7E6650` | 126, 102, 80 | Pigmento | 37 % | Aspas de molino y bancos de taller |
| azulArco | `#7FB8FF` | 127, 184, 255 | Emisivo | 50 % | Arcos eléctricos, bobinas cargadas |
| amarilloRayo | `#FFE36B` | 255, 227, 107 | Emisivo | 58 % | Rayo y puntas encendidas |
| blancoDestello | `#F4F8FF` | 244, 248, 255 | Emisivo | 4 % | Destello del relámpago (≤ 0,1 s) |

| Material base | MaterialVariant | Hex | Sat. | Uso |
|---|---|---|---|---|
| `Sandstone` | `MAT_MesetaFulgor_Estrato` | `#968470` | 25 % | Estratos y cantiles de la meseta |
| `Concrete` | `MAT_MesetaFulgor_Caliche` | `#8E8A82` | 8 % | Costra pisada alrededor de los talleres |
| `Glacier` | `MAT_MesetaFulgor_Fulgurita` | `#8C9AA8` | 17 % | Placas vítreas de fulgurita donde cae el rayo |

Agua: `WaterColor` (84, 100, 112) · `WaterTransparency` 0,4 · `WaterReflectance` 0,45 · `WaterWaveSize` 0,15 · `WaterWaveSpeed` 14. Niebla (color de `Atmosphere` en Tarde): (150, 160, 176).

### 4.3. Materiales
- **Firma:** cobre con pátina, latón grabado y fulgurita (`Glacier` tinte gris azulado).
- **Apoyo:** madera de molino, lona (`Fabric`), hierro y esmalte de taller (`SmoothPlastic` + `Reflectance` 0,1).

### 4.4. Arquitectura
- Talleres de ladrillo y madera con techos de dientes de sierra (lucernarios).
- Torres de cobre como remates de silueta.
- Molinos sobre los cantiles.
- Pasarelas y grúas.
- Todo artesanal y de feria, nada de fábrica moderna.

### 4.5. Vegetación (o equivalente)
Pastos bajos plateados que se doblan con el viento, matorral espinoso y líquenes en los estratos. El equivalente vivo son los **autómatas**: estatuas-máquina que se encienden al cargarse.

### 4.6. Terreno
- Meseta en escalones de estratos de 4 studs (alineados con la rejilla de vóxeles), con cantiles de 20–30 studs.
- Rampas en zigzag.
- Llanos de caliche alrededor de los talleres.
- Charcos poco profundos.

### 4.7. Iluminación
`LIGHTING_DIRECTION.md` §4.4: cielo cubierto con sombras difusas (`ShadowSoftness` 0,6), especular alto para el cobre y destellos del modificador `Rayo`.

### 4.8. Atmósfera y clima
- Tormenta perpetua: nubes al 88 %.
- Relámpago cada 8–20 s, con el destello ≤ 0,1 s y nunca más de 3 por segundo.
- Viento constante.
- Lluvia solo en ráfagas, como evento (la Arena de Tormenta).

### 4.9. Partículas
- chispas de las bobinas (15/s);
- polvo levantado por el viento (10/s);
- polvo de las aspas del molino (15/s).
- **El rayo no es un emisor:** es un `Beam` en zigzag del estilo Rayo de `Config/VFX` y un destello de `Lighting`.

### 4.10. Sonido
- **Ambiente:** `AMB_MesetaFulgor_Base`, `_Storm` y `_Wind`.
- **Música:** `MUS_MesetaFulgor_*`.
- Detalle en `AUDIO_DIRECTION.md` §3.4.

### 4.11. Elementos interactivos
Pararrayos que se cargan, autómatas que dan un paso al recibir carga, molinos que giran más deprisa y palancas que tienden un puente.

### 4.12. Monumentos
- la **Torre Bobina** (landmark de la muestra);
- el Taller Mayor;
- el Campo de Fulguritas.

### 4.13. Tres lugares de interés
1. **Torre Bobina:** cobre, bobinas y molino.
2. **Taller de Autómatas:** poleas y autómatas parados.
3. **Campo de Fulguritas:** placas vítreas y charcos que reflejan el cielo.

### 4.14. Guardián y restauración
**Fulgorón** (Biblia p. 14): tigre de tormenta con bobinas de cobre en el lomo y rayas de relámpago; su rugido enciende las torres de la meseta.

| Opacado | Restaurado |
|---|---|
| Las bobinas se oxidan y la tormenta se vuelve ceniza. El cobre pasa a `CorrodedMetal` gris verdoso, la tormenta es gris sin rayos y los autómatas están quietos | Un rugido: el primer rayo cae en la Torre Bobina y la carga salta de torre en torre; los autómatas arrancan. Efecto de juego: Arena de Tormenta (evento semanal) |

### 4.15. Formas que NO deben aparecer
- martillos de dioses del trueno;
- bobinas con marcas comerciales;
- roedores eléctricos de mejillas rojas (Genesis §10);
- robots de franquicias;
- fábricas modernas;
- calaveras electrocutadas.

### 4.16. Prueba de reconocimiento
> Se reconoce sin leer el nombre porque torres de cobre se recortan contra un cielo gris de tormenta permanente, un relámpago las enciende cada pocos segundos y hay molinos y engranes por todas partes.

### 4.17. Muestra ambiental (120 × 120)

```
            N (Z −60)
  ┌──────────────────────────────┐
  │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│  ▒  cantil de estratos (+20)
  │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ╔TORRE╗▒▒▒▒│  Torre Bobina (20, 0, −30), 28 × 64 × 16
  │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ║BOBINA║▒▒▒│  base (20, 10, −22)
  │▒▒▒▒▒▒▒▒▒▒▒══pasarela══╝▒▒▒▒▒│  pasarela de cobre (10, 10, −14)
  │▒▒▒▒▒▒╔═TALLER═╗ ◇◇◇ ▒▒▒▒▒▒▒▒│  taller (−10, 8, 0) · ◇ fulguritas
  │▒▒▒▒▒▒╚════════╝ ◇◇  ▒▒▒▒▒▒▒▒│
  │▒▒▒▒/ rampa en zigzag ▒▒▒▒▒▒▒│  (−30, 4, 22)
  │▒▒/  ~charco~   caliche      │
  │ /       · · ·               │
  │E                            │  E  entrada (−40, 0, 56)
  └──────────────────────────────┘
            S (Z +60)
```

**Recorrido:** entrada (−40, 0, 56) → rampa en zigzag (−30, 4, 22) → taller (−10, 8, 0) → pasarela (10, 10, −14) → base de la torre (20, 10, −22). La torre de 64 studs se ve desde toda la parcela (se reconoce a 200).

**Presupuesto:** 28 rellenos · 450 partes · 5 luces · 3 emisores · 40 partículas/s.

| Concepto | Desglose |
|---|---|
| Rellenos de terreno (28) | Base de arenisca (1) · terrazas de estratos (10) · rampa (4) · patios de caliche `Concrete` (6) · fulgurita `Glacier` (5) · charcos (2) |
| Partes (450) | Torre Bobina con molino 130 · taller de autómatas 140 · pasarela y cables 60 · 3 autómatas (20 cada uno) 60 · props 60 |
| Luces (5) | Punta de la torre (`PointLight` 12, `#7FB8FF`) · 2 faroles del taller (8) · `SurfaceLight` en la puerta del taller (10) · núcleo de un autómata (6) |
| Emisores (3) | Chispas de la bobina 15/s · polvo 10/s · polvo del molino 15/s |
| Otros | 1 `Beam` de rayo (pool de VFX); destellos con `Modifiers.Rayo` |

---

## 5. Velo Astral · noche y cielos

**Identidad (producto):**
- **Tema:** nubes nocturnas, faroles flotantes, auroras y constelaciones que se pueden pisar.
- **Colores:** azul profundo, morado, turquesa, plata y colores astrales controlados.
- **Elementos:** Luz, Sombra, Mente y Astral. **Guardiana:** Noctelia, la Medusa del Velo.
- **Nativos** (Biblia p. 10): Yetormenta, Lunatajo, Batraluna, Corvidúo, Farolánima, Aracnógrafa, Brujalada y Auroribú.

### 5.1. Moodboard
1. Nubes de noche como algodón violeta, con bordes iluminados por la luna.
2. Faroles de papel flotando, atados con hilo de plata.
3. Auroras en cortinas lentas, verde turquesa y violeta.
4. Constelaciones de piedras-estrella unidas por hilos de luz, sobre las que se camina.
5. Islas flotantes de roca con raíces colgantes.
6. Bastidores de bordado y telares de cintura (rebozo), sin motivos religiosos.
7. Espejos de agua negra que reflejan el cielo.
8. Luna creciente grande en el horizonte.
9. Polvo estelar que cae despacio, como nieve.
10. Puentes de escarcha entre islas.

### 5.2. Paleta, terreno y agua (`BiomeArt.VeloAstral`)
| Color | Hex | RGB | Tipo | Sat. | Función |
|---|---|---|---|---|---|
| azulProfundo | `#1E2A5A` | 30, 42, 90 | Pigmento | 67 % | Cielo y nubes en sombra |
| morado | `#5A3C8C` | 90, 60, 140 | Pigmento | 57 % | Nubes de noche, telas |
| indigo | `#2C2450` | 44, 36, 80 | Pigmento | 55 % | Sombras |
| turquesaAstral | `#3FA6B0` | 63, 166, 176 | Pigmento | 64 % | Telas y constelaciones apagadas |
| plata | `#C4C8D6` | 196, 200, 214 | Pigmento | 8 % | Postes, hilos, bordes de faroles |
| lavandaNube | `#9C98C8` | 156, 152, 200 | Pigmento | 24 % | Nube pisable iluminada |
| aurora | `#6FF0D2` | 111, 240, 210 | Emisivo | 54 % | Aurora (verde turquesa) |
| auroraVioleta | `#B48CFF` | 180, 140, 255 | Emisivo | 45 % | Aurora (violeta) |
| estrella | `#FFF4D6` | 255, 244, 214 | Emisivo | 16 % | Estrellas pisables |
| farol | `#FFC977` | 255, 201, 119 | Emisivo | 53 % | Faroles flotantes: el único cálido del Velo |

| Material base | MaterialVariant | Hex | Sat. | Uso |
|---|---|---|---|---|
| `Snow` | `MAT_VeloAstral_Nube` | `#B8B6DA` | 17 % | Nubes pisables (cima de las islas) |
| `Ice` | `MAT_VeloAstral_Escarcha` | `#9FB4D8` | 26 % | Escarcha estelar en bordes y puentes |
| `Rock` | `MAT_Global_Roca` | `#80786E` | 14 % | Base de las islas flotantes (la luz de luna la enfría) |

Agua: `WaterColor` (34, 44, 92) · `WaterTransparency` 0,3 · `WaterReflectance` 0,8 · `WaterWaveSize` 0,02 · `WaterWaveSpeed` 2. Niebla (color de `Atmosphere` en Tarde): (90, 90, 160).

### 5.3. Materiales
- **Firma:** superficie astral (`MATERIAL_LIBRARY.md` §2.15), nube pisable (`Snow` tinte lavanda) y plata.
- **Apoyo:** papel de farol, tela de rebozo, escarcha (`Ice`) y roca de isla.

### 5.4. Arquitectura
- Bastidores y telares de plata.
- Muelles de faroles.
- Escalinatas que flotan peldaño a peldaño.
- Pabellones de tela tensada.
- Pocas piezas, muy legibles en silueta contra el cielo.

### 5.5. Vegetación (o equivalente)
Flores nocturnas de pétalo translúcido que se abren al pasar, hilos de musgo plateado colgando de las islas y hongos luminosos pequeños. El equivalente principal son las **constelaciones**.

### 5.6. Terreno
- Islas flotantes de 16–40 studs de diámetro.
- Cima de nube y base de roca.
- Separadas por saltos de ≤ 8 studs o unidas por puentes de escarcha y constelaciones.
- Un lago de estrellas en la isla central.
- Debajo, vacío con nubes lejanas.

### 5.7. Iluminación
`LIGHTING_DIRECTION.md` §4.5. Noche por defecto (`ClockTime` 0), `ExposureCompensation` +0,4, faroles cálidos como único acento cálido.

### 5.8. Atmósfera y clima
- Bruma azul violeta (0,30) con `Offset` alto, para que las islas lejanas se aclaren.
- Auroras con `Beam` sin textura.
- Lluvia de estrellas como evento.

### 5.9. Partículas
- polvo estelar del telar (15/s);
- chispas de los faroles (15/s);
- nube que se deshace en los bordes de las islas (15/s).

### 5.10. Sonido
- **Ambiente:** `AMB_VeloAstral_Base`, `_Wind` y `_Stars`.
- **Música:** `MUS_VeloAstral_*`.
- Detalle en `AUDIO_DIRECTION.md` §3.5.

### 5.11. Elementos interactivos
Estrellas-paso que se encienden al pisarlas (y forman la constelación), faroles que se sueltan y suben, hilos de aurora que se pulsan como cuerdas y espejos de agua que muestran la siguiente isla.

### 5.12. Monumentos
- el **Telar de Noctelia** (landmark de la muestra);
- el Muelle de Faroles;
- la Gran Constelación.

### 5.13. Tres lugares de interés
1. **Telar de Noctelia:** marco de plata y aurora.
2. **Puente de Constelaciones:** seis estrellas-paso.
3. **Muelle de Faroles:** faroles atados que tiran hacia arriba.

### 5.14. Guardiana y restauración
**Noctelia** (Biblia p. 15): medusa inmensa que flota sobre el Velo Astral y teje la noche con sus tentáculos.

| Opacada | Restaurada |
|---|---|
| Sus estrellas se apagan y el velo se rasga. Desaparecen las auroras, las estrellas-paso quedan grises (`Glass` sin `Neon`) y el telar queda roto, con hilos sueltos | Noctelia teje: los hilos de aurora se tienden del telar al cielo uno a uno y las estrellas se encienden en orden de constelación. Efecto de juego: modo de combate nocturno con eventos semanales |

### 5.15. Formas que NO deben aparecer
- signos del zodiaco;
- media luna con estrella;
- diosas lunares;
- ángeles y halos religiosos;
- medusas de franquicias;
- nebulosas de arcoíris (Genesis §1).

### 5.16. Prueba de reconocimiento
> Se reconoce sin leer el nombre porque es de noche, se camina sobre nubes violetas entre islas flotantes y faroles cálidos, y una aurora turquesa cuelga de un telar de plata.

### 5.17. Muestra ambiental (120 × 120)

```
            N (Z −60)
  ┌──────────────────────────────┐
  │   · ˚   ✦  ˚    · ✦   ˚  ·   │  vacío con nubes lejanas
  │      ╔══ TELAR ══╗    ˚      │  Telar de Noctelia (0, 12, −24), 44 × 40 × 10
  │  ˚   ║ ≋aurora≋  ║        ✦  │
  │      ╚═[isla central]═╝      │  isla central (0, 12, −18) · lago de estrellas
  │ ✦          ·  ·  (isla farol)│  (14, 8, −4)
  │     ✧ ✧ ✧ constelación       │  estrellas-paso (−20, 4, 24) → (−10, 8, 4)
  │   ✧      ✧                   │
  │  (isla de llegada)    ˚      │
  │        ═escarcha═            │
  │            E                 │  E  entrada (0, 0, 56)
  └──────────────────────────────┘
            S (Z +60)
```

**Recorrido:** isla de llegada (0, 0, 56) → constelación pisable (−20, 4, 24) → (−10, 8, 4) → isla del farol (14, 8, −4) → isla central bajo el telar (0, 12, −18). El telar flota 12 studs por encima del suelo de llegada (se reconoce a 180).

**Presupuesto:** 24 rellenos · 320 partes · 6 luces · 3 emisores · 45 partículas/s.

| Concepto | Desglose |
|---|---|
| Rellenos de terreno (24) | 5 islas con cima de nube `Snow` (10) · 5 bases de roca `Rock` (5) · 4 puentes de escarcha `Ice` (4) · lago de estrellas (1) · 4 nubes sueltas (4) |
| Partes (320) | Telar 90 · 12 faroles flotantes (4 cada uno) 48 · constelación pisable 40 · props de isla 80 · raíces colgantes 40 · varios 22 |
| Luces (6) | 4 faroles con `PointLight` (8); los otros 8 solo con `Neon` · centro del telar (12) · isla de llegada (10) |
| Emisores (3) | Polvo estelar del telar 15/s · chispas de los faroles 15/s · borde de nube 15/s |
| Otros | 14 `Beam` (8 de aurora y 6 de líneas de la constelación), sin textura |

---

## 6. Torre del Nexo (no es un bioma)

La Torre vive en el Valle (`TorreBuilder`). Su guardiana final es el **Ánima del Nexo, la Primera Talla** (Biblia p. 15): un cuerpo de raíces con gubias flotantes y un núcleo de luz.
- **Opacada:** el núcleo se vuelve gris y las gubias caen.
- **Restaurada:** las gubias vuelven a orbitar, el corazón del Gran Nexo late más fuerte y las cuatro puertas muestran su vitral encendido.
- **Efecto de juego:** entrega el Huevo del Gabinete (Nexum).
- **Escenario del combate final:** el basamento del Gran Nexo con la luz del preajuste Crepúsculo del Valle. Es la única pelea del juego al atardecer (propuesta BIO-4).
- **Audio:** `AMB_TorreDelNexo_Base` y `_Echo`; `MUS_TorreDelNexo_*`.

---

## 7. Decisiones propuestas

No están registradas en `DESIGN_DECISIONS.md` (este equipo no puede editarlo).

| # | Propuesta | Motivo |
|---|---|---|
| BIO-1 | Las identidades, paletas y landmarks de Marea Coralina y Meseta Fulgor de este documento, sujetas a la pregunta 18 (¿se confirman esos dos biomas?) | La Biblia los marca como propuesta; el arte no puede darlos por aprobados |
| BIO-2 | Landmarks de bioma de 30–64 studs: Arco de Marejadra, Fragua Mayor, Torre Bobina y Telar de Noctelia | Escala intermedia entre una estación (12–20) y el Gran Nexo (90–120) |
| BIO-3 | Cada restauración de un Ser Sagrado se ve en el bioma (§x.14), además de su efecto de juego | La Biblia describe el opacado de cada guardián; el bioma lo refleja |
| BIO-4 | El combate con el Ánima del Nexo con la luz de crepúsculo del Valle | Diferencia el final sin un bioma nuevo |
| BIO-5 | Las cuatro muestras de 120 × 120 con el presupuesto de `BiomeArt.sample`, más estricto que el del Valle | Validar cada bioma en el teléfono base antes de construirlo entero |
