# NEXORA · Biblia visual Genesis (Fase 3)

**Estado:** documento rector de la Fase 3. Las reglas de aquí mandan sobre cualquier activo, escena o efecto nuevo.
Lo que no aparece en la Biblia original se marca como **PROPUESTA** y espera aprobación humana (`DESIGN_DECISIONS.md`, D-034 en adelante).

**Fuentes:**
- Biblia compacta: p. 6–18 (mundo), 19–29 (arte, evolución, cartas, rareza), 31 (elementos), 48–51 (iniciales) y 116–120 (interfaz y producción).
- `docs/ART_DIRECTION.md` (Fases 1 y 2).
- `docs/art/*` (dosieres de los iniciales).

**Documentos hijos:**
- `MATERIAL_LIBRARY.md`
- `LIGHTING_DIRECTION.md`
- `BIOME_ART_BIBLE.md`
- `AUDIO_DIRECTION.md`
- `PERFORMANCE_BUDGET.md`
- `CREATURE_DESIGN_PIPELINE.md`
- `ANIMATION_SYSTEM.md`
- `VFX_SYSTEM.md`
- `WORLD_BUILDING.md`

---

## 1. La idea en una frase

> **Realismo estilizado artesanal:** criaturas orgánicas con anatomía creíble y proporciones atractivas, hechas de materiales que se reconocen (barro bruñido, piedra tallada, copal translúcido, cobre, papel, cerámica), en lugares con aire, agua y luz, y con efectos que cuentan el elemento de cada uno.

La Biblia lo llama estilo **«Copal Nexo»**: el lenguaje de formas del alebrije oaxaqueño (quimeras, curvas en S, espirales, lóbulos de llama), **sin colores de arcoíris** (p. 119).

| Sí | No |
|---|---|
| Volumen, peso, apoyo en el suelo | Figuras de esferas y cilindros sin transición |
| Rasgos firma en geometría real | Rasgos solo pintados en la textura |
| Relieve tono sobre tono; emisivo solo dentro de los surcos | Neón en toda la superficie |
| Un color dominante por especie y un acento del elemento | Arcoíris, saturación al máximo |
| Ojos con párpado, brillo y dirección de mirada | Ojos de botón sin expresión |
| Terreno con desniveles, orillas, caminos y bordes naturales | Suelo plano con objetos sembrados al azar |
| Luz con dirección, contraste y bruma | Iluminación uniforme y plana |
| Efectos detrás o alrededor de la silueta | Auras que tapan la cara |
| Referencias culturales como inspiración | Deidades, símbolos sagrados, siluetas de franquicias |

---

## 2. Escala del mundo (studs de Roblox)

El jugador (R15) mide unos **5 studs**. Todo lo demás se lee en relación con él.

| Elemento | Altura (studs) | Nota |
|---|---|---|
| Brote | 1,2 – 2,4 de alto y ≤ 3,2 de largo | Llega a la rodilla o a la cadera del jugador; se lee como «cría». Las familias bajas (anfibio, reptil) se leen por el largo |
| Tallado Común–Épico | ×1,4–×1,7 del Brote → 2,6 – 4,0 | Llega al pecho; nunca tapa la cámara de seguimiento |

**Cómo se mide el ×1,4–×1,7** (aclaración de la Fase 3, D-034):
- se usa la media geométrica de la caja envolvente del Tallado frente a la del Brote;
- los rasgos firma (cola-látigo, corona de branquias, anillos, disco) quedan dentro, así que se admite hasta ×1,95;
- la altura sola no sirve para criaturas largas y bajas como Ascuacho;
- lo comprueba `tests/Unit/CreatureAssets.spec.luau`.
| Tallado Legendario/Único | 4 – 6 | Presencia, pero cabe en un hábitat de 4 lugares |
| Ser Sagrado (jefe) | 14 – 22 | Se ve desde la entrada del bioma; tapa el cielo, no al jugador |
| Puesto de mercado | 8 – 10 | Escala humana: toldo a 7 studs |
| Estación de la Torre | 12 – 20 | Se reconoce a 80 studs por su silueta |
| Gran Nexo | 90 – 120 | El landmark: visible desde cualquier punto del valle |
| Camino principal | 8 – 12 de ancho | Dos jugadores con acompañante caminan juntos |

---

## 3. Lenguaje de formas

### 3.1. Criaturas
- **Fórmula** (p. 22): animal (silueta y movimiento) + mito (lo extraordinario) + oficio u objeto (material y textura) + elemento (color y efecto). Tres fuentes como mínimo; una frase y una silueta.
- **Anatomía primero.**
  - La criatura parte del animal real: hocico de tlacuache, cabeza ancha de ajolote, patas columnares de tortuga.
  - El oficio aparece en las piezas que el animal ya tiene: la bolsa es el horno, el caparazón es la fortaleza de grecas, la piel es barro negro.
  - No se pegan objetos.
- **Familias anatómicas** (cada una con su propio cuerpo, sin plantillas compartidas): cuadrúpedo ágil, cuadrúpedo pesado, anfibio, reptil acorazado, ave, insecto, serpiente, flotante, bípedo, objeto vivo. `CREATURE_DESIGN_PIPELINE.md` define el esqueleto de cada familia.
- **Curvas:**
  - S y C en lomos, cuellos y colas;
  - espirales en colas, cuernos y branquias;
  - lóbulos de llama en orejas, aletas y crestas.
  - Las rectas quedan para la arquitectura y los oficios (rejilla, grecas, anillos).
- **Tres masas:** cabeza, torso y rasgo firma. La silueta en negro a 64 px debe distinguir las tres.

### 3.2. Brote → Tallado (las ocho reglas, p. 20)
| Regla | Brote | Tallado |
|---|---|---|
| Tamaño | 1 | ×1,4–×1,7; la cabeza baja del 40–45 % de la altura al 25–30 % |
| Postura | Sentada, centro de gravedad atrás | Acecho, guardia o vuelo; peso adelante |
| Mirada | Ojo grande y redondo (28–32 % del ancho de la cara), dos brillos | Ojo almendrado, iris del elemento, pupila rasgada, ceja marcada |
| Arma natural | Ninguna o insinuada | Colmillos, garras, cuernos o aguijón según el animal |
| Rompe la silueta | Un rasgo pequeño | Una pieza grande que se reconoce en negro |
| Talla y emisivo | Superficie lisa | Relieve tono sobre tono con luz dentro de los surcos |
| Aura | 80 % del tamaño y la mitad de partículas | Completa según la rareza |
| Mismo monstruo | — | Conserva la cara, el color base y el rasgo firma |

Ferocidad heroica (p. 21 y pregunta 2): **feroz, no aterrador**. Sin sangre, heridas ni ojos rojos inyectados. Público de 9 a 16 años.

### 3.3. Arquitectura
- **Base:**
  - adobe, piedra y madera;
  - techos de teja o de palma;
  - cornisas escalonadas con greca;
  - vanos en arco rebajado.
- **Oficios visibles:** hornos, telares, mostradores, toldos y papel picado.
- **Orgánico + construido:** las raíces del Gran Nexo atraviesan la piedra; los techos tienen musgo; los caminos se gastan donde más se pisa.
- **Siluetas con remate:** cada estación tiene un remate reconocible (cúpula, torreta, arco, chimenea, mástil) que se lee desde lejos.

---

## 4. Color

### 4.1. Reglas
1. **Una familia de color por especie** y un acento del elemento (p. 119). El número de colores sube con la rareza (§6).
2. **Valores antes que tonos.** Cada criatura y cada escena se leen en escala de grises:
   - criatura: cuerpo en valor medio, cara más clara o con contraste local, rasgo firma con el máximo contraste;
   - escena: primer plano oscuro, plano medio en valor medio, fondo claro y desaturado por la bruma.
3. **Saturación con tope.** Los pigmentos de superficie no pasan del 70 % de saturación (HSV). Por encima, solo los emisivos y los acentos del elemento.
4. **Calor del valle.** Las luces son cálidas (copal) y las sombras, frías (jade azulado). Nunca sombras negras puras.
5. **Opaco = gris con memoria del color:** desaturado al 15 %, valor −10 %, con una veta del color original que reaparece al restaurarlo.

### 4.2. Paletas maestras
| Familia | Colores (hex) | Uso |
|---|---|---|
| Copal | `#E8A848` · `#FFC460` · `#F6D9A6` | Luz cálida, emisivos del valle, interfaz |
| Jade | `#3E967A` · `#2F6E5C` · `#8FD1B9` | Agua del valle, sombras frías, acentos de cuidado |
| Barro | `#B06240` · `#8A4A30` · `#D9926A` | Adobe, cerámica roja, tejas |
| Piedra | `#C4B6A0` · `#9A8C78` · `#6E6252` | Plazas, muros, grecas |
| Corteza | `#60463A` · `#3F2E26` · `#8A6A54` | Gran Nexo, vigas, troncos |
| Hoja | `#56965C` · `#3B6E44` · `#9CC36A` | Vegetación del valle |
| Cacao | `#2A1C15` · `#3A271D` · `#4D3427` | Interfaz, sombras de la arquitectura |

Los colores de elemento están en `Config/Elements.color`. Las paletas de bioma, en `BIOME_ART_BIBLE.md`.

---

## 5. Materiales (resumen; el detalle está en `MATERIAL_LIBRARY.md`)

Cada material responde a la luz de un modo propio. En Roblox se construye con una de estas opciones, de la más barata a la más cara:
1. `Enum.Material` nativo con un color de la paleta.
2. `MaterialVariant` (PBR por material para el terreno y las Parts del mundo).
3. `SurfaceAppearance` (mapas PBR de una malla: ColorMap, NormalMap, RoughnessMap, MetalnessMap).

| Material | Lectura | Roblox (mundo) | Roblox (criaturas) |
|---|---|---|---|
| Copal | Cálido, translúcido, con burbujas atrapadas | `Glass`/`SmoothPlastic` + `PointLight` interior tenue | Rugosidad 0,25; emisivo en surcos |
| Barro cocido | Volumen, poros, marcas de mano | `Slate`/`Sand` con variante | Rugosidad 0,75 |
| Barro negro bruñido | Negro con brillo satinado de pulido | `SmoothPlastic` oscuro + reflectancia 0,15 | Rugosidad 0,3 con vetas mates |
| Piedra | Mineral, bordes gastados, estratos | `Slate`/`Basalt`/`Limestone` | Rugosidad 0,85; normal fuerte |
| Obsidiana | Negro vítreo, filos con brillo | `Glass` negro | Rugosidad 0,1, metálico 0 |
| Cerámica vidriada | Esmalte con reflejo nítido | `SmoothPlastic` + reflectancia | Rugosidad 0,15 |
| Cobre / latón | Reflejo cálido, pátina verde en huecos | `Metal`/`DiamondPlate` | Metálico 1, rugosidad 0,35 |
| Oro (cicatriz) | Hilos brillantes sobre una base mate | `Foil`/`Metal` | Metálico 1, rugosidad 0,2 |
| Cristal | Refracción falsa (borde claro, centro oscuro) + destello | `Glass` + `Highlight` sutil | Rugosidad 0,05 |
| Agua | Movimiento, orilla, reflejo | `Terrain.Water` (color, reflectancia, ondas) | — |
| Hoja / pétalo | Translúcido a contraluz | `LeafyGrass`/`Grass` + `Decoration` | Rugosidad 0,6 |
| Madera | Veta, bordes redondeados | `Wood`/`WoodPlanks` | Rugosidad 0,7 |
| Pelaje | Masas, no pelos sueltos | — | Rugosidad 0,9; mechones en geometría |
| Papel picado | Fino, translúcido, se mueve | `SmoothPlastic` con transparencia 0,1 | — |
| Luminoso | La luz sale de dentro de un surco o de un núcleo | `Neon` solo en piezas pequeñas | Mapa emisivo → `Neon` fino o `PointLight` |
| Astral | Profundidad nocturna con estrellas | `Neon` oscuro + partículas | Textura de cielo con estrellas |

**Regla del neón:** en el mundo, ninguna pieza `Neon` mide más de 1,5 studs de grosor; el resplandor lo dan `PointLight`, `SurfaceLight` y el bloom.

---

## 6. La rareza se ve sin leer (p. 26)

| | Común | Raro | Épico | Legendario | Único | Misterio |
|---|---|---|---|---|---|---|
| Materiales | 1 · copal mate | 2 · + pigmento brillante | 3 · + metal o translúcido | 4 · oro, vidrio, obsidiana, luz | Shader propio | Geometría imposible |
| Colores | 2–3 | 3–4 | 4–5 | 5–6 | Paleta propia | Limitada y saturada |
| Acabado | Mate | Bordes con brillo | Emisivo en surcos | Filetes dorados | Iridiscencia | Damero, piezas desfasadas |
| Efecto | Ninguno | Destello en bordes + luz de contorno al atacar | Emisivo animado + partículas en órbita | Aura dorada, rayos y piezas flotantes | Halo iridiscente + entrada animada | Cajones desfasados + efecto de cámara |
| Emisores (Tallado) | 0 | 1 (solo al atacar) | 1–2 | 2–3 | Hasta 3 | Propios |
| Presentación | Carta lisa | Carta azul | Carta violeta con esquinas + giro | Carta de oro + rayos | Carta iridiscente + firma sonora | Carta punteada + glitch de cámara |

**Más reglas:**
- **Brote:** el aura mide el 80 % y lleva la mitad de partículas.
- **Combate:** el aura baja al 60 %.
- **La cara nunca se tapa:** las partículas nacen detrás del plano de la cara (Z local < 0) o en la órbita exterior.
- **Tasa máxima:** 20 partículas/s por emisor.

---

## 7. Luz y atmósfera (resumen; el detalle está en `LIGHTING_DIRECTION.md`)

- **Una dirección dominante por escena.** En el valle, sol de tarde a unos 30° de altura que corta en diagonal la plaza y deja la cara del Gran Nexo en contraluz parcial.
- **Profundidad:**
  - `Atmosphere` con densidad moderada (0,3–0,38) y bruma del color del bioma;
  - los planos lejanos se aclaran y se enfrían;
  - nada de niebla que oculte objetivos a menos de 120 studs.
- **Postproceso con mesura:**
  - bloom ligero (intensidad ≤ 0,6, umbral ≥ 0,9);
  - `ColorCorrection` con +0,05 a +0,1 de contraste y saturación cercana a 0;
  - `SunRays` sutiles;
  - **sin** `DepthOfField` en juego (solo en cinemáticas y con un desenfoque mínimo).
- **Emisivos con presupuesto:** faroles y vetas usan `PointLight` de rango ≤ 12 con sombras desactivadas; se apagan por distancia (§9).
- **Noche y atardecer:** la Fase 3 define las tres paletas de luz (tarde, crepúsculo y noche) y las transiciones; el juego mantiene la tarde dorada por defecto (D-035, PROPUESTA).

---

## 8. Movimiento y efectos (resumen; el detalle está en `ANIMATION_SYSTEM.md` y `VFX_SYSTEM.md`)

- **Personalidad en el movimiento:**
  - Kuachi es curioso e inquieto (olfatea, cola en espiral);
  - Xolumi es calmado y anfibio (ondulación, branquias que laten);
  - Teselo es pesado y estable (inercia, apoyos firmes, se esconde para defenderse).
- **Secuencia de ataque:** preparación → anticipación → ejecución → impacto → reacción → recuperación. Ningún ataque supera 1,6 s; el Golpe Nexo dura como mucho 3,5 s y se puede saltar.
- **Cada elemento tiene su forma de partícula y su movimiento** (no solo su color). Fuego sube y se apaga, agua cae y salpica, tierra rebota y se asienta, aire gira, rayo salta, luz irradia, sombra se arrastra, mente pulsa en anillos, astral orbita, flora brota, metal destella y artificio engrana.
- **Legibilidad:** un efecto nunca tapa al objetivo más de 0,3 s, y el impacto se lee en una imagen congelada.

---

## 9. Nivel de detalle y rendimiento (detalle en `PERFORMANCE_BUDGET.md`)

- **Objetivo de la Biblia:** 8 monstruos con aura en pantalla a 30 fps en el teléfono base. Se mide; no se supone.
- **LOD por distancia** (studs a la cámara):
  - de 0 a 60, completo;
  - de 60 a 140, sin partículas ni luces y con animación a la mitad de frecuencia;
  - más allá de 140, una sola masa con el color dominante o nada.
- **Terreno antes que Parts** para el paisaje. Parts y mallas para arquitectura y props.
- **Instancias repetidas** (árboles, rocas, flores) como plantillas clonadas, con variación de escala y rotación determinista (semilla fija).

---

## 10. Originalidad y cultura

- **Inspiración, nunca copia** (p. 17–18):
  - sin deidades (Xólotl, Quetzalcóatl, Itzpapálotl, Camazotz…);
  - sin símbolos sagrados convertidos en monstruos;
  - sin siluetas de franquicias (tortuga con cañones o con árbol en el caparazón, anfibio azul con burbujas, roedor eléctrico de mejillas rojas, zorro de fuego de varias colas…).
- **Grecas, barro negro, papel picado y alebrijes** son oficios vivos: se usan con respeto, como material y patrón, nunca como chiste.
- **Prueba de parecido:** cada diseño se compara con criaturas conocidas del género antes de aprobarse (`PHASE_3_VISUAL_QA.md`).

---

## 11. Estados de un activo y aprobación

| Estado | Significado | Quién lo cambia |
|---|---|---|
| `Blockout` | Piezas primitivas para probar escala y jugabilidad | Código |
| `Proposal` | Propuesta visual hecha con herramientas reales (escultor procedural, render) | Claude |
| `InReview` | Pasó la QA técnica y espera la revisión artística | Claude |
| `Approved` | Aprobado por una persona del equipo | **Solo humanos** |
| `Final` | Importado en Roblox Studio, validado en un dispositivo y con ID real | Humanos + Studio |
| `Obsolete` | Sustituido; se conserva para comparar | Claude, con registro |

Ningún activo pasa a `Approved` ni a `Final` sin una persona. Los IDs de Roblox (`rbxassetid://`) solo se escriben cuando existen de verdad.

## 12. Convención de nombres

`<Categoría>_<Bioma|Especie>_<Pieza>_<Variante>_v<NN>`, por ejemplo:
- `CR_Kuachi_Brote_v01`
- `CR_Xolossus_Tallado_LOD1_v01`
- `WD_ValleCopal_PuestoMercado_A_v02`
- `VFX_Fuego_Chispazo_Impacto_v01`

Prefijos:

| Prefijo | Tipo |
|---|---|
| `CR` | Criatura |
| `SG` | Ser Sagrado |
| `WD` | Mundo |
| `PR` | Prop |
| `VFX` | Efecto |
| `AN` | Animación |
| `SFX` | Sonido |
| `MUS` | Música |
| `MAT` | Material |
| `UI` | Interfaz |

Los activos viven en `assets/` (estructura en `CREATURE_3D_ASSETS.md`) con un `asset.json` de metadatos por activo.
