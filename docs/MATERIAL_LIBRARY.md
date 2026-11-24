# NEXORA · Biblioteca de materiales

**Estado:** documento hijo de `ART_BIBLE_GENESIS.md` §5. Lo desarrolla y no lo contradice. Todo lo que pasa del nivel 1 (más abajo) es **PROPUESTA**: hoy no existe ninguna `MaterialVariant` ni ninguna `SurfaceAppearance` cargada en el juego (§7).

**Fuentes:**
- `ART_BIBLE_GENESIS.md` §4 (color y tope de saturación), §5 (tabla de materiales y regla del neón) y §6 (rareza);
- `docs/art/PRODUCTION_SPECS.md` §3.3 (rugosidad y metalicidad de criaturas);
- `CREATURE_DESIGN_PIPELINE.md` §2.3 (mapas de los modelos v01);
- lo construido: `Config/Ambience.luau` (paleta y colores de terreno) y `Server/World/*`.

**Datos:** el reparto de terreno por bioma vive en `Config/BiomeArt.luau` (`terrain`) y lo valida `tests/Unit/BiomeArt.spec.luau`.

**Cómo leer las cifras:**
- **Color base:** tres hex (sombra · medio · luz). Ningún pigmento pasa del **70 % de saturación HSV** (Genesis §4.1, regla 3). Los emisivos sí pueden.
- **Rugosidad y metalicidad:** de 0 a 1, como en `SurfaceAppearance`.
- **Intensidad del normal:** de 0 a 1, la fuerza con la que se hornea el relieve (0,2 suave, 0,5 media, 0,8 fuerte). Ni `SurfaceAppearance` ni `MaterialVariant` tienen un control de fuerza del normal (verificar): la intensidad va **dentro del mapa** al hornearlo.
- **«Verificar»:** dato de la plataforma Roblox que se confirma en la documentación oficial antes de producir.

> La lista del encargo nombra 15 materiales (cobre y latón aparte del metal). Están los 15.

---

## 1. Los tres niveles de construcción en Roblox

De más barato a más caro (Genesis §5). Un material siempre tiene nivel 1; los niveles 2 y 3 lo mejoran donde la cámara se acerca.

| Nivel | Qué es | Dónde se usa | Coste |
|---|---|---|---|
| **1 · `Enum.Material` + color** | Material nativo con un color de la paleta | Todo el blockout actual, el mundo lejano y la gama baja | Casi nulo |
| **2 · `MaterialVariant`** | Texturas PBR propias sobre un material base. Vive en `MaterialService` | Terreno y Parts del mundo que se pisan o se ven de cerca | 4 texturas por variante en memoria |
| **3 · `SurfaceAppearance`** | Mapas PBR de una `MeshPart` concreta (sus UV) | Criaturas, Seres Sagrados, landmarks y props hero | 4 texturas por malla |

### 1.1. `MaterialVariant` (verificar nombres y límites)
- **Propiedades:** `BaseMaterial`, `ColorMap`, `NormalMap`, `RoughnessMap`, `MetalnessMap`, `StudsPerTile`, `Pattern` (`Regular` o `Organic`) y `CustomPhysicalProperties`.
- **En una Part:** `BasePart.MaterialVariant = "MAT_…"` (por nombre).
- **En el terreno:** solo de forma **global**, con la propiedad de reemplazo de `MaterialService` (por ejemplo `MaterialService.GrassName = "MAT_ValleCopal_Pasto"`).
  - Ese reemplazo cambia **también** todas las Parts de ese material sin variante propia. El mundo tiene hoy 563 Parts de `Slate`: si algún día se reemplaza `Slate`, esas Parts cambian con él.
- **Texturas:** cuadradas y repetibles (*tileables*). 1024² como máximo (verificar), 512² para móvil.
- **`Pattern = Organic`:** rompe la repetición en suelos y rocas. `Regular` para ladrillo, losas y azulejo.
- **`StudsPerTile`:** cuántos studs cubre una repetición de la textura. Se fija para que un detalle reconocible (una losa, una veta) tenga su tamaño real junto al jugador de 5 studs.

### 1.2. `SurfaceAppearance` (verificar)
- **Mapas:** `ColorMap` (sRGB, con la **oclusión horneada**: no hay canal de AO), `NormalMap` (espacio tangente, convención OpenGL, verde arriba), `RoughnessMap` y `MetalnessMap` (grises). Así se hornean los modelos v01 (`CREATURE_DESIGN_PIPELINE.md` §2.3).
- **`AlphaMode`:** `Overlay` por defecto. `Transparency` solo si el recorte es imprescindible, porque obliga a ordenar transparencias.
- **`Color`:** tinte global; lo usa el Opaco (`CREATURE_DESIGN_PIPELINE.md` §5).
- **Resolución:** 1024² en juego, 512² en LOD1 (`CREATURE_3D_ASSETS.md`). La subida a 2048² choca con el límite de Roblox (contradicción 16 de `DESIGN_DECISIONS.md`).
- **Emisivo:** pendiente de Studio (D-036). Si `SurfaceAppearance` no lo ofrece, se usa una malla fina `Neon` generada con la misma máscara.
- **Por script:** los mapas no se cambian en tiempo de ejecución (verificar). Las variantes (Opaco, Vetas) se preparan como instancias `SA_*` y se clona la que toca (`PRODUCTION_SPECS.md` §9.4).

### 1.3. Reglas que valen para todos los materiales
- **Neón** (Genesis §5): ninguna pieza `Neon` del mundo mide más de **1,5 studs** de grosor. El resplandor lo dan `PointLight` y el bloom.
  - El mundo lo cumple: 60 piezas, la más gruesa de 1,40 (medido en el sandbox, `PERFORMANCE_BUDGET.md` §8).
- **Sombras:** nunca negras puras. El valor más oscuro de un pigmento es ~8 % (`#141214`).
- **Opaco** (Genesis §4.1, regla 5): el mismo material desaturado al 15 % y con −10 % de valor; conserva una veta del color original.

---

## 2. Fichas de material

Cada ficha: lectura · valores PBR · Roblox en tres niveles · respuesta a la luz · móvil · errores típicos. Los nombres siguen §6.

### 2.1. Copal · `MAT_Global_Copal_Pulido` y `MAT_Global_Copal_Mate`
**Lectura:** resina ámbar, cálida y translúcida, con burbujas atrapadas. Tiene **dos acabados**:
- **pulido:** faroles, corazón del Gran Nexo, escalonados de la plaza; deja ver la luz de dentro;
- **mate:** la base del Común en criaturas (Biblia p. 26).

| PBR | Pulido | Mate |
|---|---|---|
| Color base | `#B97A2E` · `#E8A848` · `#F6D9A6` | `#A87A44` · `#D9A662` · `#EBCB98` |
| Rugosidad | 0,20–0,30 (Genesis: 0,25) | 0,60–0,80 (`PRODUCTION_SPECS` §3.3) |
| Metalicidad | 0 | 0 |
| Normal | 0,2 (burbujas y vetas) | 0,4 (huella de lija y de gubia) |

**Roblox:**
1. **Pieza pequeña (≤ 4 studs):** `Glass` con `Transparency` 0,2–0,35 y color `#E8A848`, más un núcleo `Neon` de ≤ 1,5 y una `PointLight` (rango ≤ 12, `Brightness` 0,6–1,0, color `#FFC460`, `Shadows = false`). Así es hoy el corazón del Gran Nexo (`WORLD_BUILDING.md` §4.1). **Superficie grande:** `SmoothPlastic` opaco `#E8A848`.
2. **`MaterialVariant`:** sobre `SmoothPlastic`; `StudsPerTile` 4, `Organic`, 512². El `ColorMap` lleva burbujas y un degradado de dentro a fuera (centro claro, borde oscuro).
3. **`SurfaceAppearance`:** `ColorMap` 1024² con el falso brillo interior pintado; rugosidad 0,25; emisivo solo en los surcos.

**Luz:** se lee a contraluz. Su calidez viene del centro claro pintado, no de saturar el color. Con bloom de umbral ≥ 0,9, solo el núcleo emisivo resplandece.

**Móvil:** `SmoothPlastic` opaco + núcleo `Neon`. Sin `PointLight` más allá de 60 studs (LOD de Genesis §9).

**Errores:**
- copal todo en `Neon`: parece plástico encendido;
- `Glass` en superficies grandes: sobredibujo y fallos de orden;
- tan amarillo que se confunde con oro metálico;
- saturado por encima del 70 % (`#FFA000`).

### 2.2. Barro cocido · `MAT_Global_BarroCocido_A`
**Lectura:** terracota con volumen, poros, marcas de mano y bordes más claros por el roce. Cántaros, tejas, adobe rojo, hornos.

| PBR | Valor |
|---|---|
| Color base | `#8A4A30` · `#B06240` · `#D9926A` (familia Barro de Genesis §4.2) |
| Rugosidad | 0,70–0,85 (Genesis: 0,75) |
| Metalicidad | 0 |
| Normal | 0,5 (poros, huellas de dedos, estrías de torno) |

**Roblox:**
1. `Brick` en muros de adobe rojo; `ClayRoofTiles` en tejas (ya lo usa el mundo, 18 piezas); `Sand` en cántaros y macetas (grano fino). Color `#B06240`.
2. **`MaterialVariant`:** sobre `Sand`; `StudsPerTile` 6, `Organic`, 512². Mancha de cocción irregular en el `ColorMap`.
3. **`SurfaceAppearance`:** en el Recolector (cántaro del lote) y en props hero: estrías de torno horneadas en el normal.

**Luz:** difusa, sin brillo; el volumen sale del normal y de la oclusión horneada. Con la tarde, el barro se calienta hacia `#D9926A` en la cara del sol.

**Móvil:** `Sand` o `Brick` con color; no le hace falta variante para leerse.

**Errores:**
- naranja de plástico (`SmoothPlastic`) sin textura;
- repetición visible en muros largos (`StudsPerTile` pequeño);
- brillo especular alto (parece esmaltado).

### 2.3. Barro negro bruñido · `MAT_Global_BarroNegro_Brunido`
**Lectura:** cerámica negra de Oaxaca con brillo satinado de pulido a piedra y vetas mates donde no se bruñó. Es la piel de Xolumi.

| PBR | Valor |
|---|---|
| Color base | `#141214` · `#2A2628` · `#4A4446`; nunca `#000000` |
| Rugosidad | 0,25–0,35 en lo bruñido (Genesis: 0,3); 0,55–0,65 en las vetas mates |
| Metalicidad | 0 |
| Normal | 0,25 (trazos del bruñido, moteado) |

**Roblox:**
1. `SmoothPlastic` `#2A2628` con `Reflectance` 0,15 (Genesis §5).
2. **`MaterialVariant`:** sobre `SmoothPlastic`; `StudsPerTile` 4. El `RoughnessMap` alterna franjas de 0,25 y 0,55 como trazos de bruñido.
3. **`SurfaceAppearance`:** el de Xolumi y Xolossus (`CREATURE_3D_ASSETS.md` §3), con las vetas de oro de reparación del Tallado.

**Luz:** se lee **por el brillo especular**: necesita `EnvironmentSpecularScale` ≥ 0,4 y un cielo que reflejar. En sombra plena desaparece, así que lleva luz de contorno (ColorShift_Bottom jade) o un fondo más claro.

**Móvil:** `SmoothPlastic` + `Reflectance` 0,1.

**Errores:**
- negro puro: se pierde la forma;
- demasiado brillante: parece vinilo;
- Opaco de Xolumi invisible contra fondos oscuros: el Opaco sube el valor, no lo baja más.

### 2.4. Piedra · `MAT_Global_Piedra_Tallada` y variantes de bioma
**Lectura:** mineral con bordes gastados, estratos y juntas. Plazas, muros, grecas, estelas.

| PBR | Valor |
|---|---|
| Color base | `#6E6252` · `#9A8C78` · `#C4B6A0` (familia Piedra; `Ambience.Palette.stone`) |
| Rugosidad | 0,80–0,90 (Genesis: 0,85); 0,55–0,75 en mosaico de criaturas |
| Metalicidad | 0 |
| Normal | 0,8 (fuerte: juntas, cincel, grietas) |

**Roblox:**
1. `Slate` (plaza y muros: 563 Parts hoy), `Limestone` (claras), `Basalt` (oscuras), `Cobblestone` (calzadas). En terreno: `Slate`, `Rock` y `Basalt`.
2. **`MaterialVariant`:** `MAT_Global_Piedra_Tallada` sobre `Slate`; `StudsPerTile` 8; `Regular` para sillares y `Organic` para roca natural; 1024².
3. **`SurfaceAppearance`:** estelas y piezas de greca en relieve, con la oclusión horneada.

**Luz:** el relieve se lee con sol rasante; `ShadowSoftness` ≤ 0,3 mantiene el borde de las juntas.

**Móvil:** `Slate` con color.

**Errores:**
- gris uniforme sin variación de valor;
- repetición visible (`StudsPerTile` demasiado pequeño);
- grecas pintadas planas: Genesis §1 pide los rasgos en geometría real, o al menos en un normal fuerte.

### 2.5. Obsidiana · `MAT_Global_Obsidiana`
**Lectura:** negro vítreo con fracturas en concha y filos que brillan. Obsidárion, Magmacrán, el pico de Navajazul.

| PBR | Valor |
|---|---|
| Color base | `#0E0C12` · `#1E1A22` · `#3A3444`, con reflejo violeta o pardo en los filos |
| Rugosidad | 0,05–0,12 (Genesis: 0,1) |
| Metalicidad | 0 |
| Normal | 0,15 (ondas concoideas) |

**Roblox:**
1. `Glass` `#1E1A22` con `Transparency` 0, o `SmoothPlastic` con `Reflectance` 0,2–0,25.
2. **`MaterialVariant`:** sobre `SmoothPlastic`; `StudsPerTile` 3. Remolinos concoideos en el `RoughnessMap`.
3. **`SurfaceAppearance`:** rugosidad 0,08–0,12; un leve reflejo violeta pintado en los filos del `ColorMap`.

**Luz:** solo se lee por los brillos de sus facetas: necesita **facetas reales** en la malla (aristas vivas) y una luz principal. El bloom no debe tocarla (umbral ≥ 0,9).

**Móvil:** `SmoothPlastic` `#1E1A22` + `Reflectance` 0,2.

**Errores:**
- formas redondeadas (parece plástico);
- negro puro;
- filos en `Neon` (lectura de ciencia ficción).

### 2.6. Cerámica vidriada · `MAT_Global_CeramicaVidriada_Azulejo`
**Lectura:** esmalte con reflejo nítido sobre barro, con motivos pintados; borde con grosor visible. Azulejo, vajilla, Faroibex (porcelana vidriada).

| PBR | Valor |
|---|---|
| Color base | blanco `#EDE6D6`, azul `#2F5D8C`, jade `#3E967A`, copal `#E8A848` |
| Rugosidad | 0,12–0,18 (Genesis: 0,15) |
| Metalicidad | 0 |
| Normal | 0,1 (esmalte liso; craquelado opcional a 0,2) |

**Roblox:**
1. `SmoothPlastic` + `Reflectance` 0,2 (Genesis §5). Muros de azulejo: `CeramicTiles` (verificar).
2. **`MaterialVariant`:** sobre `SmoothPlastic` o `CeramicTiles`; `StudsPerTile` 2 (azulejo de 2 × 2 studs), `Regular`, 512².
3. **`SurfaceAppearance`:** motivos originales pintados en el `ColorMap`, rugosidad 0,15.

**Luz:** reflejo nítido del cielo; el color queda vivo bajo el esmalte, pero respeta el tope del 70 %.

**Móvil:** `SmoothPlastic` + `Reflectance` 0,1.

**Errores:**
- todo brillante (solo brilla lo esmaltado);
- `Reflectance` > 0,3 (espejo);
- copiar patrones reconocibles de talleres concretos.

### 2.7. Metal (hierro y hojalata) · `MAT_Global_Hojalata_Repujada`
**Lectura:** placas con repujado, remaches y bordes vivos; hierro oscuro en herrería y hojalata clara en faroles y techos.

| PBR | Valor |
|---|---|
| Color base | `#5E626A` · `#969AA0` · `#C9CCD0` |
| Rugosidad | 0,25 en el relieve pulido; 0,45–0,55 en los huecos con suciedad |
| Metalicidad | 1 (0 en la suciedad de los huecos) |
| Normal | 0,6 (repujado, remaches) |

**Roblox:**
1. `Metal` (95 Parts en el mundo), `DiamondPlate` (pisos de taller), `Foil` (hojalata brillante), `CorrodedMetal` (solo para el Opaco).
2. **`MaterialVariant`:** sobre `Metal`; `StudsPerTile` 4, `Regular`, 1024².
3. **`SurfaceAppearance`:** metalicidad 1 con suciedad 0 en los huecos; oclusión en el `ColorMap`.

**Luz:** un metal **sin entorno que reflejar se ve negro**: `EnvironmentSpecularScale` ≥ 0,5 (en Meseta Fulgor 0,8, `Config/BiomeArt`).

**Móvil:** `Metal` nativo.

**Errores:**
- rugosidad 0 (cromado);
- óxido rojo intenso (lectura de terror): la corrosión es gris verdosa y solo en el Opaco.

### 2.8. Cobre · `MAT_Global_Cobre_Martillado`
**Lectura:** reflejo cálido y martillado con **pátina verde en los huecos**. Calderos de la Cumbre, torres y bobinas de la Meseta, el anillo del Portal de Arenas.

| PBR | Cobre | Pátina |
|---|---|---|
| Color base | `#7A4A30` · `#B8734A` · `#E0A27A` | `#5E9C8A` · `#6FA08E` |
| Rugosidad | 0,30–0,45 (Genesis: 0,35) | 0,75–0,85 |
| Metalicidad | 1 | 0 |
| Normal | 0,5 (martillado) | 0,3 |

**Roblox:**
1. `Metal` `#B8734A`; piezas de pátina en `CorrodedMetal` `#6FA08E`.
2. **`MaterialVariant`:** sobre `Metal`; `StudsPerTile` 3, `Organic`. El `MetalnessMap` vale 1 en el cobre y 0 en la pátina.
3. **`SurfaceAppearance`:** igual, con la pátina solo en los huecos de la oclusión.

**Luz:** bajo un cielo de tormenta solo brilla si hay especular; por eso Meseta Fulgor sube `EnvironmentSpecularScale` a 0,8.

**Móvil:** `Metal` con color.

**Errores:**
- metalicidad 0 (parece plástico naranja);
- pátina por todas partes (parece una ruina);
- `#D2691E` (86 % de saturación).

### 2.9. Latón · `MAT_Global_Laton_Grabado`
**Lectura:** amarillo metálico más verdoso y menos saturado que el oro. Engranes de Artificio, herrajes del Gabinete, catalejos del Mirador.

| PBR | Valor |
|---|---|
| Color base | `#7A6232` · `#BEA05A` · `#E6D08E` (`Ambience.Palette.brass` `#C49648` en el mundo) |
| Rugosidad | 0,30 pulido · 0,45 gastado |
| Metalicidad | 1 |
| Normal | 0,3 (grabado) |

**Roblox:**
1. `Metal` `#BEA05A`; `Foil` en herrajes pequeños y brillantes.
2. **`MaterialVariant`:** sobre `Metal`; `StudsPerTile` 2.
3. **`SurfaceAppearance`:** metalicidad 1, grabado en el normal.

**Oro** (cicatriz y filetes del Legendario): `Foil` o `Metal` `#D4AF5A`, rugosidad 0,15–0,30, metalicidad 1. En un **Común** el dorado es **pigmento mate** (metalicidad ≤ 0,2, rugosidad ≥ 0,45), según la propuesta de `PRODUCTION_SPECS.md` §3.3 (contradicción 14).

**Errores:** latón y oro con el mismo color: el latón es más verde y más mate.

### 2.10. Cristal · `MAT_Global_Cristal`
**Lectura:** vitral, porcelana translúcida, geodas y fulgurita. **Refracción falsa** (Genesis §5): borde claro, centro oscuro y un destello.

| PBR | Valor |
|---|---|
| Color base | claro `#DDE8EE`, ámbar `#E8C27A`, violeta `#8E78C8` |
| Rugosidad | 0,03–0,08 (Genesis: 0,05) |
| Metalicidad | 0 |
| Normal | 0,1 (las facetas van en la geometría, no en el normal) |

**Roblox:**
1. `Glass` con `Transparency` 0,3–0,5 en piezas pequeñas. El falso borde se hace con dos piezas anidadas: una exterior de `Glass` y un núcleo más oscuro. El vitral de las puertas de los biomas ya es así.
2. **`MaterialVariant`:** poco útil para el vidrio (verificar si una variante sobre `Glass` conserva su efecto). Se prefieren los niveles 1 y 3.
3. **`SurfaceAppearance`:** cristal **opaco pintado como vidrio** (`PRODUCTION_SPECS.md` §3.3). La transparencia real solo si la validación de rendimiento lo permite.

**Luz:** el destello lo da un `Highlight` sutil solo en piezas hero (Roblox dibuja como mucho 31; el pool de VFX reserva 12, `VFX_SYSTEM.md` §7) o una chispa de 1–2 partículas/s.

**Móvil:** cristal opaco pintado; sin transparencia.

**Errores:**
- volúmenes transparentes grandes (orden de transparencias, sobredibujo);
- `Highlight` en muchas piezas;
- refracción de arcoíris (Genesis §1: sin arcoíris).

### 2.11. Agua · propiedades de `Terrain` por bioma
**Lectura:** movimiento, orilla y reflejo. Cada bioma tiene su agua en `Config/BiomeArt.water`. La del Valle es la de `Ambience.Terrain.water`.

| PBR (equivalente) | Valor |
|---|---|
| Color base | Valle `#3A8A78` (58, 138, 120) · Marea `#389E9C` · Cumbre `#60786E` (termal) · Meseta `#546470` · Velo `#222C5C` |
| Rugosidad | — (lo controlan `WaterReflectance` y `WaterWaveSize`) |
| Metalicidad | — |
| Normal | `WaterWaveSize` 0,02–0,15 |

**Roblox:**
1. Agua de **terreno**: `WaterColor`, `WaterTransparency`, `WaterReflectance`, `WaterWaveSize` y `WaterWaveSpeed`. Son **globales del lugar** (§5.3). Las Parts no tienen material de agua: una fuente pequeña es `Glass` con una `Texture` que se desplaza.
2. **Orilla:** banda de `Mud`/`Sand` de 4,5 studs (así la hace `RiverBuilder`) y espuma pintada en una franja más clara del material de la orilla (variante).
3. **Hero:** la cascada y los cenotes llevan partículas de bruma (12/s en la cascada del Valle) y láminas de agua a mano.

**Luz:** el reflejo muestra el cielo y la atmósfera. Una transparencia alta (0,78 en la Marea) deja ver el fondo del cenote.

**Ojo con la rejilla:** el terreno es de **vóxeles de 4 studs**. El agua y las orillas se alinean a esa rejilla; un relleno de menos de 4 studs se aproxima.

**Móvil:** `WaterWaveSize` ≤ 0,1. En calidad baja Roblox ya simplifica el reflejo (verificar).

**Errores:**
- cian puro (`#00FFFF`);
- olas de más de 0,3 en un río (parece mar con tormenta);
- agua sin orilla, con un borde recto.

### 2.12. Hojas · variantes de terreno y follaje
**Lectura:** masas de follaje facetado, translúcidas a contraluz, con tres valores (luz, medio, sombra).

| PBR | Valor |
|---|---|
| Color base | `#3B6E44` · `#56965C` · `#9CC36A` (familia Hoja; `Ambience.Palette.leaf*`) |
| Rugosidad | 0,55–0,65 (Genesis: 0,6) |
| Metalicidad | 0 |
| Normal | 0,3 (nervaduras y masas) |

**Roblox:**
1. **Terreno:** `Grass` con `Terrain.Decoration` (briznas animadas; solo `Grass` las tiene) y `LeafyGrass`. **Copas:** Parts de `LeafyGrass` o `Grass` (486 y 207 en el mundo).
2. **`MaterialVariant`:** `MAT_ValleCopal_Pasto` y `MAT_ValleCopal_Sotobosque` (§5); `StudsPerTile` 10, `Organic`, 1024².
3. **`SurfaceAppearance`:** solo en copas hero. Se prefieren masas sólidas a tarjetas con alfa (`AlphaMode = Transparency` cuesta).

**Luz:** el contraluz sale de `ColorShift_Top` cálido (propuesta L-2 de `LIGHTING_DIRECTION.md`), no de saturar el verde.

**Móvil:** sin variante; `Decoration` se reduce sola en calidad baja (verificar).

**Errores:**
- verde neón (`#00FF00`);
- un solo tono plano;
- cada hoja como una Part (las plantillas clonadas de `FloraBuilder` resuelven esto).

### 2.13. Madera · `MAT_Global_Madera_Tallada` y `MAT_Global_Madera_Tablon`
**Lectura:** veta, bordes redondeados y marcas de gubia. Vigas, puestos, puentes, canoas, el Gabinete.

| PBR | Valor |
|---|---|
| Color base | `#5A3E2C` · `#8C6442` · `#B48A62`; corteza `#60463A` (`Ambience.Palette.bark`) |
| Rugosidad | 0,65–0,75 (Genesis: 0,7) |
| Metalicidad | 0 |
| Normal | 0,5 (veta); 0,6 con marcas de gubia |

**Roblox:**
1. `Wood` (vigas y troncos: 834 Parts, el material más usado del mundo) y `WoodPlanks` (pisos, muelles, puentes: 100).
2. **`MaterialVariant`:** `MAT_Global_Madera_Tallada` sobre `Wood` (`StudsPerTile` 4, `Regular`) y `MAT_Global_Madera_Tablon` sobre `WoodPlanks` (`StudsPerTile` 6).
3. **`SurfaceAppearance`:** tronco del Gran Nexo y Gabinete, con la gubia horneada.

**Luz:** se calienta con la tarde; los biseles atrapan el brillo.

**Móvil:** `Wood` nativo.

**Errores:**
- veta estirada o enorme (`StudsPerTile` sin ajustar a la escala);
- aristas vivas (Genesis: bordes redondeados);
- madera naranja saturada.

### 2.14. Luminosos · `Neon` + luces locales
**Lectura:** la luz sale **de dentro** de un surco, de un núcleo o de una boca (horno, farol, corazón); nunca de una superficie entera (Genesis §1 y §5).

| PBR | Valor |
|---|---|
| Color | los de tipo `Emisivo` de cada paleta de `Config/BiomeArt` (copal `#FFC460`, lava `#FF7A2E`, arco `#7FB8FF`, aurora `#6FF0D2`…) |
| Rugosidad / metalicidad / normal | — |

**Roblox:**
1. `Neon` de ≤ 1,5 studs de grosor (`Transparency` 0,2–0,5 lo suaviza) + `PointLight` con rango ≤ 12, `Brightness` 0,5–1,5 y `Shadows = false`. Reglas de las luces: `LIGHTING_DIRECTION.md` §6.
2. **`MaterialVariant`:** no emite luz (verificar); no se usa para luminosos.
3. **`SurfaceAppearance`:** máscara emisiva (D-036, pendiente). Si no existe, malla `Glow` en `Neon`.

**Luz:** con bloom de umbral 1,4 (Valle), el `Neon` resplandece y los pigmentos no; por eso el umbral nunca baja de 0,9.

**Móvil:** `Neon` sin `PointLight` más allá de 60 studs; en calidad Low el pool de VFX ya no crea luces (`Config/VFX.Quality.Low.lights = false`).

**Errores:**
- losas de neón;
- `PointLight` con sombras;
- rangos que se solapan (dos luces a menos de 8 studs se funden en una);
- emisivo en un Común fuera de surcos.

### 2.15. Superficies astrales · `MAT_VeloAstral_*` y `MAT_Global_Astral`
**Lectura:** profundidad de noche con puntos de luz: el disco de Mitlaxis, las constelaciones pisables y los velos del Velo Astral.

| PBR | Valor |
|---|---|
| Color base | `#1E2A5A` · `#2C2450` · `#5A3C8C`; estrellas `#FFF4D6`, aurora `#6FF0D2` (emisivos) |
| Rugosidad | 0,4 (terciopelo de noche); 0,1 en el vidrio de las constelaciones |
| Metalicidad | 0 (plata de los bordes: 1) |
| Normal | 0,1 |

**Roblox:**
1. `ForceField` (brillo animado y barato) con tinte `#3A4A8C` para velos; constelaciones de `Glass` oscuro con estrellas `Neon` de ≤ 0,4 studs; `Beam` sin textura (solo degradado) para las líneas y las auroras.
2. **`MaterialVariant`:** las del terreno del Velo (`MAT_VeloAstral_Nube`, `MAT_VeloAstral_Escarcha`; §5).
3. **`SurfaceAppearance`:** `ColorMap` 1024² con campo de estrellas (disco de Mitlaxis, Genesis §5) y, opcional, una `Texture` que se desplaza despacio (`OffsetStudsU`) como paralaje. Requiere una textura subida: pendiente.

**Luz:** una superficie astral debe leerse **en silueta contra el cielo**: lleva un borde de plata o un valor más claro que el fondo.

**Móvil:** `ForceField` y `Beam` son baratos. Las estrellas se agrupan en una sola malla, no en cientos de Parts.

**Errores:**
- nebulosa de arcoíris (prohibido);
- estrellas como Parts sueltas;
- `ForceField` en el suelo que se pisa (ruido visual);
- signos zodiacales o religiosos.

---

## 3. Materiales por rareza (Genesis §6, Biblia p. 26)

| Rareza | Materiales (número) | De esta biblioteca | Acabado en Roblox |
|---|---|---|---|
| Común | 1 · copal mate | Copal mate (§2.1) | `SurfaceAppearance` mate, rugosidad 0,6–0,8; sin emisivo fuera de los surcos del Tallado |
| Raro | 2 · + pigmento brillante | + pigmento de rugosidad 0,35–0,5 | Bordes con brillo (rugosidad baja en aristas) |
| Épico | 3 · + metal o translúcido | + cobre o latón (§2.8–2.9) o cristal/copal pulido (§2.10, §2.1) | Emisivo animado en surcos (`Config/VFX`: las piezas `Neon` laten) |
| Legendario | 4 · oro, vidrio, obsidiana, luz | + oro (§2.9), obsidiana (§2.5), cristal, luminosos | Filetes dorados metálicos (metalicidad 1, rugosidad 0,15–0,3) |
| Único | Shader propio | Paleta propia + superficie astral o iridiscente | Roblox no tiene shaders propios: «shader propio» = `SurfaceAppearance` propia + `Beam` con degradado que se desplaza (el halo de `VFX_SYSTEM.md` §4) + `Highlight` (propuesta M-3) |
| Misterio | Geometría imposible | Cualquiera, limitada y saturada | No es un material: piezas desfasadas y damero (`Config/VFX`) |

---

## 4. Respuesta a la luz: resumen

| Material | Qué tiene que hacer la luz | Ajuste en `Lighting` que lo favorece |
|---|---|---|
| Copal, cerámica, barro negro | Un brillo especular limpio | `EnvironmentSpecularScale` 0,5–0,75 |
| Metal, cobre, latón | Reflejar el entorno | `EnvironmentSpecularScale` ≥ 0,5 (Meseta 0,8) |
| Piedra, barro cocido, madera | Mostrar el relieve | Sol a 25–35°, `ShadowSoftness` ≤ 0,3 |
| Hojas | Contraluz cálido | `ColorShift_Top` cálido |
| Obsidiana, cristal | Destellos en facetas | Luz principal con dirección; bloom con umbral ≥ 0,9 |
| Luminosos, astral | Destacar en la sombra | `ExposureCompensation` +0,3–0,4 de noche, bloom 0,6 |

---

## 5. Plan de variantes de terreno por bioma

### 5.1. La restricción
`Terrain:SetMaterialColor` y el reemplazo de `MaterialService` son **globales del lugar**: un material base de terreno solo puede tener **un color y una variante** en todo el mapa. Por eso cada material base pertenece a un bioma o se comparte con un único aspecto. `BiomeArt.spec` lo comprueba, y comprueba también que cada material que hoy pinta `Ambience` tenga sitio en el reparto.

### 5.2. Reparto (`Config/BiomeArt.terrain`)

| Material base | Dueño | Variante | Color | Uso |
|---|---|---|---|---|
| `Grass` | Valle | `MAT_ValleCopal_Pasto` | `#689854` (Ambience) | Praderas con `Decoration` |
| `LeafyGrass` | Valle | `MAT_ValleCopal_Sotobosque` | `#4E804A` (Ambience) | Lotes, bancales, bajo los árboles |
| `Ground` | Valle | `MAT_ValleCopal_TierraCamino` | `#9E7A58` (Ambience) | Caminos y bancales |
| `Slate` | Valle | `MAT_ValleCopal_MuroTerraza` | `#70685C` (Ambience) | Muros de las terrazas |
| `Mud` | Compartido | `MAT_Global_Lodo` | `#6C523E` (Ambience) | Orillas del Valle; manglar de la Marea |
| `Sand` | Compartido | `MAT_Global_Arena` | `#CCB890` (Ambience) | Bancos del río; playas de la Marea |
| `Rock` | Compartido | `MAT_Global_Roca` | `#80786E` (Ambience) | Afloramientos y cascada; islas del Velo |
| `Basalt` | Compartido | `MAT_Global_Basalto` | `#54525C` (Ambience) | Linde y afloramientos; coladas de la Cumbre |
| `Limestone` | Marea | `MAT_MareaCoralina_CalizaCenote` | `#BDB39A` | Paredes y bóvedas del cenote |
| `Salt` | Marea | `MAT_MareaCoralina_Coral` | `#C98A78` | Roca de coral (el coral vivo son mallas) |
| `Pavement` | Marea | `MAT_MareaCoralina_LosaSumergida` | `#8A9690` | Losas de las ruinas sumergidas |
| `CrackedLava` | Cumbre | `MAT_CumbreBrasa_LavaDomada` | `#5A3A30` | Lava domesticada (las grietas brillan con la textura: verificar con el tinte) |
| `Asphalt` | Cumbre | `MAT_CumbreBrasa_Ceniza` | `#5E5856` | Ceniza fina en caminos y patios |
| `Brick` | Cumbre | `MAT_CumbreBrasa_AdobeHorno` | `#9C5A3C` | Montículos de adobe de los hornos |
| `Sandstone` | Meseta | `MAT_MesetaFulgor_Estrato` | `#968470` | Estratos y cantiles |
| `Concrete` | Meseta | `MAT_MesetaFulgor_Caliche` | `#8E8A82` | Costra pisada de los talleres |
| `Glacier` | Meseta | `MAT_MesetaFulgor_Fulgurita` | `#8C9AA8` | Placas vítreas de fulgurita |
| `Snow` | Velo | `MAT_VeloAstral_Nube` | `#B8B6DA` | Nubes pisables |
| `Ice` | Velo | `MAT_VeloAstral_Escarcha` | `#9FB4D8` | Escarcha estelar en bordes y puentes |
| `Cobblestone`, `WoodPlanks` | Libres | — | — | Reserva |

### 5.3. Lo que no se puede repartir
- **El agua** (`WaterColor` y demás) y **la luz** son una por lugar. En un mismo lugar, el cliente cambia el aspecto al entrar en un bioma (`LIGHTING_DIRECTION.md` §5). Hay que verificar en Studio que `Terrain.WaterColor` y `SetMaterialColor` hechos en el cliente se ven sin replicarse.
- **Alternativa limpia:** un lugar de Roblox por bioma (propuesta M-2). Cada lugar tiene su terreno, sus variantes y su luz, y la memoria de un teléfono solo carga un bioma.

### 5.4. Especificación de las variantes de terreno (propuesta)
| Variante | `StudsPerTile` | `Pattern` | Mapas | Nota |
|---|---|---|---|---|
| Pasto, sotobosque, arena, lodo, nube | 10–12 | `Organic` | 1024² color, normal y rugosidad | Sin `MetalnessMap` (0) |
| Tierra de camino, ceniza, caliche | 8 | `Organic` | 1024² | Huella de pisadas en el normal (0,4) |
| Roca, basalto, caliza, estrato, coral | 12–16 | `Organic` | 1024² | Normal fuerte (0,8) |
| Losas, muro de terraza, adobe de horno | 6–8 | `Regular` | 1024² | Juntas que encajen con los 4 studs de la rejilla |
| Lava domada, fulgurita, escarcha | 8 | `Organic` | 1024² | El brillo de la lava no es emisivo real: lo acompañan `Neon` ≤ 1,5 y una `PointLight` |

---

## 6. Convención de nombres `MAT_…`

Sigue Genesis §12 (`<Categoría>_<Bioma|Especie>_<Pieza>_<Variante>_v<NN>`):

| Qué | Forma | Ejemplo |
|---|---|---|
| Instancia `MaterialVariant` (el nombre que se escribe en `BasePart.MaterialVariant` y en `MaterialService`) | `MAT_<Ámbito>_<Material>[_<Variante>]` | `MAT_ValleCopal_Pasto`, `MAT_Global_Cobre_Martillado` |
| Texturas | `T_MAT_<Ámbito>_<Material>[_<Variante>]_<Color\|Normal\|Rough\|Metal>_v<NN>.png` | `T_MAT_ValleCopal_Pasto_Color_v01.png` |
| `SurfaceAppearance` de criatura | `SA_<Base\|Opaco\|Veta2…>` dentro del modelo | `SA_Opaco` (`PRODUCTION_SPECS.md` §9.4) |

- **Ámbito:** `Global` o el id del bioma (`ValleCopal`, `MareaCoralina`, `CumbreBrasa`, `MesetaFulgor`, `VeloAstral`, `TorreDelNexo`).
- **La versión no va en el nombre de la instancia** (propuesta M-4). Va en sus atributos `ArtVersion` y `AssetStatus` y en los archivos de textura. Así subir de `v01` a `v02` no obliga a renombrar cada Part.

---

## 7. Estado: qué existe y qué es propuesta

| Nivel | Existe hoy en el juego | Propuesta |
|---|---|---|
| 1 · `Enum.Material` + color | **Todo el mundo y los blockouts.** Parts del valle (sandbox): `Wood` 834, `SmoothPlastic` 629, `Slate` 563, `LeafyGrass` 486, `Grass` 207, `Fabric` 161, `WoodPlanks` 100, `Metal` 95, `Neon` 60, `Glass` 47, `ClayRoofTiles` 18, `Basalt` 15, `Plaster` 12, `Ground` 12. Terreno: `Grass`, `LeafyGrass`, `Ground`, `Slate`, `Mud`, `Sand`, `Rock`, `Basalt` y agua, con color de `Ambience.Terrain.materials` | Colores por bioma de `Config/BiomeArt` |
| 2 · `MaterialVariant` | **Ninguna.** No hay texturas subidas | Las 19 variantes de terreno de §5.2 y las globales de §2 |
| 3 · `SurfaceAppearance` | **Ninguna en Roblox.** Los seis modelos v01 tienen sus mapas PNG en `assets/Creatures/Initials/*/textures/` (`Proposal`, sin importar ni aprobar) | Importación según `CREATURE_DESIGN_PIPELINE.md` §6 |

Ningún `rbxassetid` existe ni se inventa.

---

## 8. Decisiones propuestas

No están registradas en `DESIGN_DECISIONS.md` (este equipo no puede editarlo).

| # | Propuesta | Motivo |
|---|---|---|
| M-1 | El copal tiene dos acabados: **pulido** (rugosidad 0,25, Genesis §5) y **mate** (0,6–0,8, base del Común en `PRODUCTION_SPECS.md`) | Las dos fuentes dan cifras distintas para «copal»; en realidad describen dos usos |
| M-2 | Un lugar de Roblox por bioma (o, si sigue un solo lugar, el reparto de §5.2 más el cambio de agua y luz en el cliente) | El terreno, el agua y la luz son globales del lugar; además, un teléfono solo cargaría un bioma |
| M-3 | El «shader propio» del Único se interpreta como `SurfaceAppearance` propia + `Beam` con degradado + `Highlight` | Roblox no permite shaders propios |
| M-4 | Las instancias `MAT_…` no llevan `_vNN`: la versión va en atributos y en los archivos | Un cambio de versión no obliga a renombrar cientos de Parts |
| M-5 | No reemplazar `Slate` con `MaterialService` mientras las 563 Parts de piedra no lleven su propia variante | El reemplazo global cambiaría también la plaza y la Torre |
