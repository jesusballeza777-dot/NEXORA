# Especificaciones de producción · criaturas

> **Estado: propuesta v0.1 · 21 nov 2026 — pendiente de aprobación humana.**
> Cifras con «(Biblia p. N)»: de la Biblia v5.0. Cifras sin esa cita: **propuesta**. «Verificar»: límite de
> Roblox que se confirma en la documentación vigente antes de importar. Nada de esto describe un activo
> existente: los modelos actuales son blockouts (`AssetStatus = "Blockout"`).

Índice: 1 Escala · 2 Presupuestos · 3 Brote y Tallado · 4 Cara y expresiones · 5 Rareza · 6 Opaco ·
7 Rig · 8 Animación · 9 Importación en Roblox · 10 Carta · 11 Validación en Studio

---

## 1. Escala, orientación y unidades

| Concepto | Valor | Fuente |
|---|---|---|
| Unidad de trabajo | 1 unidad de Blender = 1 stud | propuesta |
| Tamaño del Brote: dimensión mayor del cuerpo sin cola ni rasgo firma (altura en criaturas erguidas, largo en horizontales como Xolumi) | 2,5 studs ± 0,3 | propuesta (≈ blockouts actuales) |
| Tamaño del Tallado | caja envolvente del cuerpo del Brote × `talladoScale`, rango ×1,4–×1,7 | Biblia p. 20 |
| `talladoScale` por especie | Kuachi 1,55 · Xolumi 1,6 · Teselo 1,5 (resto en `Config/Visuals.luau`) | propuesta |
| Referencia con el jugador | avatar R15 ≈ 5 studs: el Brote llega a la cadera | propuesta |
| Frente de la criatura | **+Z local** (convención del código: «la criatura mira a su +Z local», `WorldController`) | código actual |
| Arriba | +Y | Roblox |
| Pivote | en el suelo (Y = 0), bajo el centro de masa; la raíz del modelo se coloca a la altura del terreno | código actual |

Si se adopta la convención −Z de Roblox (`LookVector`), se cambia en `CreatureBuilder`/`WorldController`
en el mismo cambio; nunca se compensa rotando el activo dentro de Studio.

**Blockouts como referencia:** los 8 blockouts propios sirven de referencia de escala y lectura. Los
**blockouts provisionales con arquetipo prestado** de la beta (Zunzi, Pabilo, Lumbro, Dientón) **no son
diseño**: no se usan como referencia de silueta, proporción, escala ni color. Su concepto parte de la
ficha de la Biblia (`GEMINI_PROMPTS.md` §4).

---

## 2. Presupuestos

### 2.1 Por activo (Biblia p. 120, p. 26)
| Categoría | Triángulos | Textura | Huesos | Emisores de aura |
|---|---|---|---|---|
| Brote (cualquier rareza) | 2 500–4 000 | 1024² | ≤ 18 | 0–1 (Raro+) |
| Tallado Común–Épico | 4 000–6 500 | 1024² | ≤ 30 | 0–2 |
| Tallado Legendario/Único | 6 500–9 000 | 1024² (2048² cinemática) | ≤ 40 | 2–3 |
| Ser Sagrado (jefe) | 9 000–14 000 | 2048² | ≤ 50 | 3 |
| Huevo | 600–1 200 | 512² | 0–3 | 0–1 |
| Cofre | 1 000–2 000 | 512² | 1 (tapa) | 0–1 |

Reglas de la Biblia que acompañan la tabla: cada ParticleEmitter con tasa máxima de **20 partículas/s**
(p. 26); en combate el aura baja al **60 %** (p. 26, 120); el Brote muestra el aura de su rareza al **80 %
del tamaño y con la mitad de partículas** (p. 26); **8 monstruos con aura a 30 fps en el teléfono base**
antes de aprobar un Legendario (p. 120). Aura = ParticleEmitter + Beam + Highlight, nunca geometría extra
(p. 120).

### 2.2 Desglose por pieza (propuesta)
| Pieza | Parte del presupuesto de triángulos | Textura | Notas |
|---|---|---|---|
| `Body` (MeshPart con piel) | 80–90 % | SurfaceAppearance 1024² | Incluye cara y ojos |
| `Glow` (MeshPart con piel, opcional) | ≤ 10 % | sin textura, `Material = Neon` | Surcos emisivos, bolsa, puntas. Solo si el emisivo no va en la SurfaceAppearance |
| Piezas rígidas del rasgo firma (anillos, disco) | ≤ 15 % | comparte el atlas de `Body` | Preferible dentro de `Body`, pesadas al 100 % en huesos propios que gira un script (§7); MeshPart aparte solo si hace falta |

Máximo **3 MeshParts por forma** (≤ 3 llamadas de dibujo más el aura). Brote y Tallado tienen juegos de
textura propios. Densidad de texel uniforme; la cara recibe el doble de densidad que el resto.

### 2.3 Límites de la plataforma (verificar)
| Límite | Valor conocido | Consecuencia |
|---|---|---|
| Triángulos por MeshPart | 20 000 | Todos los presupuestos caben en una malla |
| Textura subida | se reduce a 1024 × 1024 | 2048² solo para render fuera del motor (marketing, cinemática); en juego, 1024² |
| Influencias por vértice | 4 | Pesos normalizados a ≤ 4 huesos |
| Transformación de huesos | CFrame (posición y rotación), sin escala | Expresiones por rotación/traslación, nunca escalando huesos |
| Highlight simultáneos | 31 por cliente | Highlight solo en Legendario+ y en primeros planos; el aura se apoya en partículas y Beam |
| ViewportFrame | no dibuja partículas, Beam ni luces | El aura de la carta es una capa 2D (§10) |

---

## 3. Brote y Tallado: la misma identidad

### 3.1 Las ocho reglas de la evolución (Biblia p. 20) traducidas a producción
| Regla | Brote | Tallado | Cómo se produce |
|---|---|---|---|
| 1 Tamaño | Referencia | ×1,4–×1,7; la cabeza baja de proporción y el cuerpo gana peso | Mismo sistema de proporciones; se reajusta, no se escala sin más |
| 2 Postura | De cría, sentado | Acecho, guardia o vuelo; el peso hacia delante | La postura se define en la pose de Idle, no en la pose de unión del rig |
| 3 Mirada | Ojos grandes y redondos, dos brillos | Ojo almendrado, iris del elemento, pupila rasgada, brillo, ceja marcada (p. 21) | Mismas cuencas; la mirada feroz es textura + variante de la misma geometría de ceja (p. 119) |
| 4 Arma natural | No visible | Colmillos, garras, cuernos, aguijones o pico-navaja según el animal | Pieza de la malla, dentro del presupuesto |
| 5 Rompe la silueta | Una sola silueta clara, pocas piezas | Una pieza grande que se reconoce en negro (anillos, astas, torre, hélice, cajones) | Comprobar a 64 px en negro |
| 6 Talla y emisivo | Superficie lisa («smooth surface», prompt base p. 119) | Relieve tono sobre tono, luz solo dentro de los surcos | Talla horneada a mapa de normales (p. 119); emisivo limitado a los surcos |
| 7 Aura de rareza | 80 % tamaño, mitad de partículas | Aura completa; 60 % en combate | §5.5 |
| 8 Mismo monstruo | — | Cara, color base y rasgo firma se conservan: se reconoce al Brote | §3.2 |

### 3.2 Qué debe persistir (criterios medibles, propuesta)
- **Cara:** misma colocación de ojos respecto a la cabeza (separación y altura ± 10 %), mismo tipo de hocico
  o boca, mismas orejas/branquias/cresta; el Tallado puede afilarlas pero no cambiarlas de sitio.
- **Color base:** mismo tono (H) ± 15°; el Tallado puede bajar el valor hasta un 30 % y subir la saturación
  de los acentos. El color base cubre ≥ 50 % de la superficie visible en ambas formas.
- **Rasgo firma** (`signatureFeature` en `Config/Visuals.luau`): presente en ambas formas y en la misma zona
  del cuerpo; en el Tallado crece hasta ser la pieza que rompe la silueta o se conserva intacto.
- **Prueba de pareja:** Brote y Tallado en miniatura a 128 px junto a otras parejas; 4 de 5 personas ajenas
  al proyecto los emparejan.

### 3.3 Materiales y acabado
El acabado global depende de **P11** («talla pintada», propuesta de la Biblia, o «juguete de vinilo»).
Recordatorio de la dirección de arte: «Tallado» es el nombre de la evolución, no una obligación de tallar
todo en madera (`ART_DIRECTION.md` §1). Valores de SurfaceAppearance (propuesta):

| Material del mundo | Rugosidad | Metal | Notas |
|---|---|---|---|
| Copal mate (base Común) | 0,60–0,80 | 0 | Material de referencia del Común (Biblia p. 26) |
| Pelaje pintado | 0,70–0,90 | 0 | Mechones como masas talladas en el normal, no fibras |
| Cerámica bruñida | 0,15–0,30 | 0 | Barro negro de Xolumi |
| Piedra y mosaico | 0,55–0,75 | 0 | Teselas con juntas en el normal |
| Jade pulido | 0,25–0,40 | 0 | |
| Pigmento brillante (Raro+) | 0,35–0,50 | 0 | |
| Metal (Épico+) | 0,25–0,45 | 1 | |
| Oro (Legendario+) | 0,15–0,30 | 1 | |
| Vidrio o translúcido (Épico+) | 0,05–0,20 | 0 | Opaco pintado como vidrio; transparencia real solo si la validación de rendimiento lo permite |

- **Talla pintada:** normal de relieve intenso con marcas de gubia, bloques de color pintados, rugosidad alta.
- **Vinilo:** normal suave, rugosidad 0,30–0,45, colores planos. El cambio es global, nunca por especie.
- **Dorado en un Común** (oro de reparación de Xolossus, anillos de Mitlaxis): la Biblia reserva el metal
  para Épico en adelante (p. 26). Propuesta: en un Común el dorado es **pigmento dorado mate** (metal ≤ 0,2,
  rugosidad ≥ 0,45), sin reflejo especular de metal pulido. Requiere decisión humana y, si se aprueba,
  entrada en `DESIGN_DECISIONS.md`.

---

## 4. Cara, ojos y expresiones

| Elemento | Brote | Tallado | Fuente |
|---|---|---|---|
| Ojo | Grande y redondo, dos brillos (uno grande arriba, uno pequeño abajo) | Almendrado, iris del elemento, pupila rasgada, un brillo | Biblia p. 20–21; `ART_DIRECTION.md` §4 |
| Tamaño del ojo | diámetro = 28–32 % del ancho de la cara | largo = 20–24 % del ancho de la cara | propuesta |
| Ceja | No | Marcada, geometría compartida con variantes de textura | Biblia p. 21, 119 |
| Rubor y boca | Rubor `#FF929E`; boca `#281816`, o `#EC96A0` sobre cuerpos muy oscuros | Sin rubor; colmillos pequeños permitidos | `Visuals.Face` (propuesta) |
| Esclerótica | `#FAFAF6` | Crema del color de la especie | `Visuals.Face` (propuesta) |

**Iris del Tallado por elemento** (`Config/Elements.luau`, propuesta para arte; en especies de dos o tres
elementos manda el primero de la lista de configuración):

| Agua | Fuego | Aire | Tierra | Metal | Flora |
|---|---|---|---|---|---|
| `#40AAD6` | `#EC7032` | `#AAD6E2` | `#B8844C` | `#A4ACB8` | `#68B058` |
| **Rayo** | **Artificio** | **Luz** | **Sombra** | **Mente** | **Astral** |
| `#F4CE3C` | `#C48C5C` | `#FAE296` | `#6E54A0` | `#D678BE` | `#6078D6` |

**Expresiones:** seis por forma (entregable 6, Biblia p. 118). Las del Tallado parten de la Biblia (p. 21):
neutral concentrado, desafío, ataque (boca abierta y colmillos), victoria (sonrisa ladeada), cansado, más
una propia de la especie. Las del Brote (propuesta): neutral curioso, feliz, ataque, victoria, cansado,
cariño. **Nunca** llanto ni dolor explícito (p. 21).

**Controles de cara en el rig** (propuesta): `Jaw`, párpados (`Lid_L`/`Lid_R`, o un solo `Lids` si la
especie no guiña), `Brow_L`/`Brow_R` (solo Tallado), orejas, branquias o mejillas. Parpadeo de 0,15 s cada
3–6 s al azar. Si una expresión necesita cambiar la forma de la boca (sonrisa ladeada), se valida en Studio
una pieza `MouthCard` con `Decal` intercambiable; si no funciona, se resuelve con `Jaw` + inclinación de cabeza.

---

## 5. Lenguaje visual de la rareza

### 5.1 Complejidad por rareza (Biblia p. 26)
| Rareza | Materiales | Colores | Efecto | En Roblox |
|---|---|---|---|---|
| Común | 1 · copal mate | 2–3 | Ninguno | 0 emisores |
| Raro | 2 · copal + pigmento brillante | 3–4 | Destellos en bordes y luz de contorno | 1 emisor al atacar |
| Épico | 3 · añade metal o translúcido | 4–5 | Emisivo animado y partículas en órbita | 1 emisor permanente |
| Legendario | 4 · oro, vidrio, obsidiana, luz | 5–6 | Aura dorada, rayos y piezas flotantes | 2 emisores + haz |
| Único | Shader propio | Paleta propia | Halo iridiscente y entrada animada | 3 emisores + firma sonora |
| Misterio | Geometría imposible | Limitada y saturada | Damero flotante, cajones desfasados | Efectos de cámara |

Presupuesto técnico (p. 26): Común 0 · Raro 1 · Épico 1–2 · Legendario 2–3 · Único 3 ParticleEmitters.
`Config/Rarities.luau → auraEmitters` guarda el máximo.

**Cómo se cuentan los colores (propuesta):** por familias de tono. Claros y oscuros del mismo tono cuentan
como uno; ojos, rubor, boca y emisivo de surcos no cuentan. Ejemplo: Kuachi Brote = gris cálido (pelaje,
vientre, patas) + rosa (cola) + brasa = 3.

### 5.2 Marco y gema de la carta (Biblia p. 25)
| Rareza | Marco (Biblia) | Color de marco y gema (`Visuals.RarityFrames`, propuesta) |
|---|---|---|
| Común | Liso | `#D6C8B0` |
| Raro | Azul | `#488CE6` |
| Épico | Violeta con esquinas | `#9C60DE` |
| Legendario | Oro | `#ECB840` |
| Único | Iridiscente | `#8CE6DC` (base del degradado) |
| Misterio | Punteado imposible | `#3C3C3C` |

Gema de rareza arriba a la izquierda; iconos de elemento (uno a tres) arriba a la derecha. Completar un
bioma da un marco especial. El marco y la gema son imágenes reutilizables por rareza (p. 25).

### 5.3 Surcos emisivos («vetas de luz») por rareza (propuesta, derivada de p. 26)
| Rareza | Surcos del Tallado | Brote |
|---|---|---|
| Común | Emisivo de baja intensidad, solo en surcos y rasgo firma; como mucho una variación de ± 10 % sincronizada con la respiración del rasgo firma | Solo el rasgo firma (p. ej. la bolsa tibia de Kuachi), con la misma respiración |
| Raro | Igual + filo claro pintado en el ColorMap (lectura de «luz de contorno») | Igual |
| Épico | Emisivo animado en todo el cuerpo: pulso de 2,5 s | Pulso de 4 s |
| Legendario | Surcos dorados; aura con rayos | Surcos dorados sin rayos |
| Único | Paleta propia: juego de texturas exclusivo, sin compartir colores con su elemento | Igual |
| Misterio | Según el concepto de Nexum | — |

### 5.4 Veta (variante de color) y Veta Dorada (Biblia p. 88)
- **Veta:** variante de color o material del catálogo de cada especie; solo estética. Número por especie
  pendiente de **P9** (propuesta de la Biblia: 3). Producción: un ColorMap por Veta y por forma, con los
  mismos UV, normal y rugosidad. La Veta de un individuo se mantiene al tallarse, así que cada Veta tiene
  versión Brote y Tallado.
- Las Vetas no rompen la regla 8: cambian tono o material dentro de la familia de color de la especie y
  nunca tocan ojos, rasgo firma ni emisivo del elemento (propuesta).
- **Veta Dorada (1 %):** mutación cosmética brillante, sin atributos, no se vende con Gemas. Producción:
  ColorMap dorado + MetalnessMap propio. **No usa emisores de aura** para que no se confunda con un
  Legendario (propuesta).

### 5.5 Aura en Roblox
- Composición: ParticleEmitter + Beam + Highlight según la rareza; nunca geometría extra (p. 120).
- Vive detrás o alrededor de la silueta; ojos y rasgo firma siempre limpios (p. 26).
- Anexos: `FX_Aura` (centro de masa) y `FX_Ground` (suelo). `LightEmission` ≤ 0,5 para no lavar la paleta
  (propuesta).
- Combate: intensidad al 60 % (p. 26). Brote: 80 % del tamaño, mitad de partículas (p. 26).
- **Común = 0 emisores** (p. 26): los efectos del rasgo firma de un Común (humo de branquias, brasas,
  estrellas del disco) se hacen con geometría, emisivo y animación de huesos, nunca con ParticleEmitter.
  Las partículas de un ataque (`FX_Mouth`, `FX_Hit`) son efectos de combate del elemento, no aura
  (propuesta).
- **Brote de rareza alta:** la tabla de la p. 120 limita el Brote a 0–1 emisores, pero el aura reducida de
  un Legendario o Único tendría 2–3. Propuesta: el Brote usa como máximo 1 emisor (el más característico
  de su rareza, a media tasa) y nunca Beam ni Highlight. Requiere decisión humana.

---

## 6. Variante Opaco

**Fuente:** «Restaurar, no destruir: al vencer, la niebla gris se disipa y el monstruo recupera su color.
Nadie muere en NEXORA» (Biblia p. 112). Los Seres Sagrados opacados pierden su luz y su color: raíces que se
secan, faroles que se apagan, coral que se blanquea (p. 13–15). Configuración actual: `Visuals.Opaco`
(tinte `#808086`, desaturación 0,85, niebla `#9696A0`) y `CreatureBuilder.setOpaco`.

| Aspecto | Opaco | Fuente |
|---|---|---|
| Geometría | La misma malla y el mismo rig; el Opaco es un juego de texturas + efectos, nunca un modelo aparte | propuesta |
| ColorMap | Saturación × 0,15 conservando la luminancia; tinte frío `#808086` al 20 % | propuesta (desaturación 0,85 de `Visuals`) |
| Emisivo | Apagado: surcos, brasas y luces del rasgo firma pasan al gris de su color desaturado | Biblia p. 13–15 (luces que se apagan) |
| Ojos | Conservan forma, pupila y **un** brillo pequeño; iris desaturado. Nunca vacíos, totalmente negros, sin pupila ni rojos | propuesta + Biblia p. 21 |
| Niebla | ParticleEmitter en `FX_Ground`, color `#9696A0`, ≤ 20 partículas/s, transparencia 0,5–0,8, tamaño 1–2 studs (Brote). Es efecto de estado, no aura de rareza; sí cuenta en la prueba de rendimiento | color: `Visuals`; tasa: Biblia p. 26; resto propuesta |
| Postura | Misma anatomía; Idle al 70 % de velocidad; cabeza 5–10° más baja | propuesta |
| Prohibido | Grietas que parezcan heridas, venas, ojos inyectados, calaveras, babas, piel caída, miembros rotos | Biblia p. 21 |

**Transición de restauración (1,8 s, propuesta).** Reversible: el estado es un solo parámetro 0–1, como
`setOpaco`. La misma secuencia al revés sirve para el Opacamiento de la introducción (p. 109).

| Tiempo | Qué ocurre |
|---|---|
| 0,0–0,4 s | Estremecimiento; la niebla se espesa y sube |
| 0,4–1,0 s | La niebla gira hacia arriba y se convierte en motas cálidas de copal (`#E8A848`, paleta del Valle); el color vuelve desde el rasgo firma hacia el resto del cuerpo |
| 1,0–1,4 s | Los surcos se encienden; los ojos se abren con sus brillos |
| 1,4–1,8 s | Sacudida y pose feliz |

**En Roblox:** las texturas de una SurfaceAppearance no se cambian por script en tiempo de ejecución
(verificar). Se guardan `SA_Base` y `SA_Opaco` en el modelo y se intercambian a los 0,7 s bajo un destello de
`Highlight` cálido (`FillTransparency` 0,4 → 1). Si la versión vigente permite tintar la SurfaceAppearance
por script, se valida un fundido en lugar del intercambio.

---

## 7. Rig

| Requisito | Valor | Fuente |
|---|---|---|
| Tipo | Esqueleto propio por especie y forma, independiente de R15; sin Humanoid; `AnimationController` + `Animator` | propuesta |
| Huesos | Instancias `Bone` dentro del MeshPart con piel | Roblox |
| Presupuesto | Brote ≤ 18 · Tallado Común–Épico ≤ 30 · Legendario/Único ≤ 40 · Ser Sagrado ≤ 50 (incluye `Root`) | Biblia p. 120 |
| Raíz | Hueso `Root` en el origen (suelo, bajo el centro de masa), sin rotación, escala 1; todo cuelga de él | propuesta |
| Movimiento | Sin root motion: las animaciones de locomoción son en el sitio; el código desplaza la raíz | propuesta (coincide con `CreatureBuilder.update`) |
| Pose de unión | Neutra y simétrica, boca cerrada, ojos abiertos, cola y branquias en reposo; no hace falta pose en T | propuesta |
| Transformaciones | Aplicadas antes de exportar (escala 1, rotación 0) | propuesta |
| Pesos | ≤ 4 influencias por vértice, normalizados; piezas rígidas (caparazón, anillos, rejilla) al 100 % en un hueso | Roblox (verificar) + propuesta |
| Articulaciones | ≥ 3 bucles de aristas por articulación que dobla | propuesta |
| Brote y Tallado | Rigs separados (la anatomía cambia: Xolumi pasa de 4 a 6 patas) con nombres compartidos | propuesta |

**Nombres de huesos** (identificadores en inglés, CLAUDE.md; propuesta):
- Tronco: `Root`, `Pelvis`, `Spine_01…`, `Neck_01…`, `Head`.
- Cara: `Jaw`, `Lid_L`, `Lid_R` (o `Lids`), `Brow_L`, `Brow_R`, `Ear_L`, `Ear_R`, `Cheek_L`, `Cheek_R`.
- Patas: `Leg_<lado><n>_<índice>` con lado FL/FR (delanteras), ML/MR (medias), BL/BR (traseras):
  `Leg_FL_01`, `Leg_FL_02`. Si la pata tiene un solo hueso, sin índice: `Leg_FL`.
- Cadenas: `Tail_01…`, `Gill_L1…`, `Gill_R1…`.
- Rasgo firma: nombre descriptivo (`Pouch`, `Ring_Outer`, `Disc`). Los huesos que deben girar sin parar (anillos) **no se animan en ningún clip**: un script cliente escribe su `Bone.Transform`, como hacen hoy los blockouts con `SpinY`/`SpinZ`.
- Misma convención en todas las especies para que mirar al jugador, parpadear y respirar se apliquen por nombre.

**Anexos** (en Roblox `Bone` hereda de `Attachment`, así que efectos y accesorios cuelgan del hueso y siguen
la animación; propuesta):

| Anexo | Dónde | Uso |
|---|---|---|
| `FX_Aura` | Centro de masa | Aura de rareza |
| `FX_Ground` | Suelo, bajo el centro | Niebla Opaco, polvo al caminar, pedestal |
| `FX_Mouth` | Boca | Chorros, humo, aliento |
| `FX_Signature` | Rasgo firma | Brasas, anillos, branquias |
| `FX_Hit` | Pecho | Impactos recibidos |
| `ACC_Head`, `ACC_Neck`, `ACC_Back`, `ACC_Face` | Cabeza, cuello, lomo, cara | Accesorios: sombrero, listón, collar, alas de papel, máscaras (Biblia p. 92–95); visibles en combate y santuario según P10 |
| `CAM_Portrait` | Centro del encuadre | Cámara de la carta |
| `UI_Overhead` | Sobre la cabeza | Nombre y barra de vida |

---

## 8. Animación

**Tiempos de la Biblia (p. 40):** ningún ataque dura más de **2,5 s** en pantalla; el Golpe Nexo puede
durar **4 s** y se puede saltar tras verlo una vez; cada turno reserva **6–8 s** de animación. El Golpe Nexo
se desbloquea a nivel 20 y solo en Tallado (p. 115). El Despertar del Tallado depende de **P12** (propuesta
de la Biblia: corto de 5 s; cinemática de 12 s solo en Legendarios).

| Clip | Brote | Tallado | Bucle | Duración (propuesta salvo cita) | Prioridad Roblox | Notas |
|---|:-:|:-:|:-:|---|---|---|
| `Idle` | ✔ | ✔ | ✔ | 3,0 s | Idle | Respiración y rasgo firma vivo |
| `IdleFidget` | ✔ | ✔ | — | 2–4 s | Idle | Gesto propio cada 8–15 s |
| `Walk` | ✔ | ✔ | ✔ | 0,7 s (Brote) · 0,9 s (Tallado) | Movement | En el sitio |
| `Run` | ✔ | ✔ | ✔ | 0,45 s · 0,55 s | Movement | Al seguir al jugador a distancia |
| `Happy` | ✔ | ✔ | — | 1,5 s | Action | Jugar y acariciar |
| `Eat` | ✔ | ✔ | — | 2,0 s | Action | Comedero |
| `SleepEnter` · `Sleep` · `SleepExit` | ✔ | ✔ | `Sleep` | 1 s · 4 s · 1 s | Idle / Action | Hábitat |
| `BattleIdle` | ✔ | ✔ | ✔ | 2,0 s | Idle | Guardia; el Brote también combate |
| `AttackBasic` | ✔ | ✔ | — | ≤ 1,2 s, impacto a 0,4–0,5 s | Action | Tope 2,5 s (Biblia p. 40) |
| `AttackSpecial` | ✔ | ✔ | — | ≤ 2,0 s | Action | Tope 2,5 s (Biblia p. 40) |
| `AttackSignature` | ✔ | ✔ | — | ≤ 2,5 s | Action2 | Tope de la Biblia (p. 40) |
| `GolpeNexo` | — | ✔ | — | ≤ 4,0 s (Biblia p. 40) | Action3 | Se puede saltar tras verlo una vez |
| `Hit` | ✔ | ✔ | — | 0,5 s | Action2 | Retroceso, sin gesto de dolor |
| `RestEnter` · `Rest` | ✔ | ✔ | `Rest` | 1,5 s · 4 s | Action3 | Sustituye al «desmayo»: se acurruca o se sienta, ojos cerrados, respiración visible. Nunca flácido, boca arriba ni con ojos en X |
| `Victory` | ✔ | ✔ | — | 1,5–2,0 s | Action | Sonrisa ladeada en el Tallado (Biblia p. 21) |
| `Hatch` | ✔ | — | — | 1,5 s | Action4 | Sale del huevo en espiral de virutas (Biblia p. 89) |
| `EvolveAnticipation` | ✔ | — | — | 1,5 s | Action4 | Primera mitad del Despertar (P12) |
| `EvolveReveal` | — | ✔ | — | 2,0 s | Action4 | Pose heroica; con efectos, Despertar corto ≤ 5 s (P12) |
| `Restore` | ✔ | ✔ | — | 1,8 s | Action4 | §6 |
| `CardPose` | ✔ | ✔ | pose | 1 fotograma | — | Pose fija para la carta |

El Idle del Opaco reutiliza `Idle` al 70 % de velocidad; no es un clip aparte.

- Se anima a 30 fps (propuesta).
- **Marcadores** (`KeyframeMarker`): `Impact`, `FxStart`, `FxEnd`, `Footstep_L`, `Footstep_R`. Solo
  sincronizan lo visual: el daño y el resultado los decide el servidor (CLAUDE.md).
- Las animaciones no mueven `Root` en XZ.
- Los ataques arrancan desde `BattleIdle` y vuelven a él.

---

## 9. Importación en Roblox

### 9.1 Exportación (Blender)
- **Formato:** FBX binario con malla y armadura, o glTF/GLB. OBJ solo para objetos estáticos sin rig.
- Transformaciones aplicadas; 1 unidad = 1 stud; solo huesos de deformación; sin huesos hoja; triangulado en
  Blender para controlar la topología final; normales exportadas.
- Un objeto de malla por MeshPart (`Body`, `Glow`, piezas rígidas), con esos nombres. Si `Glow` lleva piel,
  sale en el mismo archivo y con el mismo esqueleto que `Body` (comprobar en Studio que se liga a los mismos
  huesos).
- **Orientación:** el preajuste de ejes se fija una vez con un objeto de prueba (una flecha) importado en
  Studio hasta que la cabeza quede en +Z local; se guarda como preajuste `NEXORA_Roblox` y no se toca por especie.

### 9.2 Importación (Studio)
- Las criaturas entran por el **Importador 3D** de Studio (malla con huesos). El Avatar Importer y la
  configuración de avatares están pensados para personajes R15 y **no** se usan con criaturas.
- En la vista previa del importador se confirman triángulos, huesos detectados, escala, orientación y
  materiales. Cualquier error se corrige en Blender y se reexporta; no se arregla a mano en Studio.
- Texturas: ColorMap, NormalMap (espacio tangente; convención de canal verde a verificar), RoughnessMap y
  MetalnessMap, 1024². La oclusión ambiental se hornea dentro del ColorMap (SurfaceAppearance no tiene canal
  de oclusión). Si la versión vigente de SurfaceAppearance ofrece mapa emisivo (verificar), se prefiere a la
  pieza `Glow`.

### 9.3 Propiedades
| Instancia | Propiedad | Valor |
|---|---|---|
| `Body`, `Glow`, piezas rígidas | `Anchored` | `true`: el cliente mueve la raíz, como con los blockouts |
| | `CanCollide`, `CanQuery`, `CanTouch` | `false` (igual que los blockouts) |
| | `CastShadow` | `true` en `Body`; `false` en `Glow` |
| | `RenderFidelity` | `Automatic` (LOD automático de Roblox) |
| | `CollisionFidelity` | `Box` (no colisionan) |
| | `DoubleSided` | `false` |
| | `Massless` | `true` |
| `Glow` | `Material` · `Color` | `Neon` · color emisivo de la paleta |
| `RootPart` | Part 1×1×1 invisible en el origen | `Transparency = 1`, `Anchored`, sin colisión; `PrimaryPart` del modelo de la forma |
| Modelo de la especie | Atributos | `SpeciesId`, `ArtVersion` (semver), `AssetStatus = "Approved"`, `SourceDossier` |

**LOD:** Roblox no importa LOD manuales para MeshPart (verificar). El paso «LOD» de la Biblia (p. 120) se
cumple comprobando `RenderFidelity = Automatic` a 30, 60 y 120 studs: si el rasgo firma se pierde, se
remodela con menos piezas y más grandes.

### 9.4 Estructura, nombres y `modelAsset`
```
ReplicatedStorage
└─ Assets
   └─ Creatures
      └─ kuachi (Model)                    SpeciesId, ArtVersion, AssetStatus = "Approved"
         ├─ Brote (Model, PrimaryPart = RootPart)
         │  ├─ RootPart (Part invisible)
         │  ├─ Body (MeshPart) ── SA_Base (SurfaceAppearance) ── Root (Bone) → Pelvis → …
         │  ├─ Glow (MeshPart, Neon)       opcional
         │  ├─ AnimationController ── Animator
         │  └─ Variants (Folder) ── SA_Opaco · SA_Veta2 · SA_Veta3 · SA_VetaDorada
         ├─ Tallado (Model)                misma estructura
         └─ Animations (Folder)
            ├─ Brote (Folder) ── Idle · Walk · … (Animation)
            └─ Tallado (Folder) ── … · GolpeNexo
```
- En el repositorio (propuesta): `src/ReplicatedStorage/Assets/Creatures/<id>.rbxm`. Rojo lo sincroniza
  como `ReplicatedStorage.Assets.Creatures.<id>`. El `.rbxm` lo guarda Studio tras la importación: los
  IDs de malla, textura y animación que contiene son los que asignó Roblox al subir, nunca escritos a mano.
- `Config/Visuals.luau`: `assetStatus = "Approved"` y `modelAsset = "Creatures/<id>"` (ruta relativa a
  `ReplicatedStorage.Assets`). `CreatureBuilder` resolverá la ruta por segmentos con `FindFirstChild` y, si
  falta, volverá al blockout. Es un cambio de código pendiente y lleva prueba en `tests/Unit`.
- **Carga diferida** (pendiente de decisión técnica): hoy `StreamingEnabled = false` y ReplicatedStorage se
  replica entero al entrar. Basta para la beta (≤ 16 especies con arte). Con más, los modelos pasan a
  ServerStorage y se clonan al cliente bajo demanda («no cargar las 50 especies para mostrar tres», Biblia §
  Rendimiento).

**Nombres de archivo** (propuesta): `NX_<id>_<Forma>_v###.blend` · `NX_<id>_<Forma>_v###.fbx` ·
`T_<id>_<Forma>_<Color|Normal|Rough|Metal>.png` · variantes `T_<id>_<Forma>_Color_Opaco.png`,
`_Color_Veta2.png` · animaciones `A_<id>_<Forma>_<Clip>`. `<id>` es el id de configuración (`kuachi`).

---

## 10. Carta

**Anatomía (Biblia p. 25):** gema de rareza arriba a la izquierda; iconos de elemento arriba a la derecha;
fondo del bioma de origen; pedestal de luz; aura detrás y alrededor, que crece con la rareza; marco por
rareza. Cada especie tiene dos cartas: la del Brote usa el mismo marco con el aura reducida. En Roblox, la
carta es un `ViewportFrame` con el modelo sobre una imagen del bioma; marco y gema son imágenes
reutilizables por rareza.

| Capa (fondo → frente) | Qué | Propuesta técnica |
|---|---|---|
| 1 Fondo | Bioma de origen | Imagen 1024 × 768, poco detalle detrás de la cabeza |
| 2 Aura | Según la rareza (§5.1) | **Imagen 2D animada** (rotación, `UIGradient`): el ViewportFrame no dibuja partículas (verificar) |
| 3 Pedestal | Disco de luz bajo los pies | Imagen; color del elemento principal |
| 4 Criatura | Modelo en `CardPose` | ViewportFrame; cámara 3/4 a −35° de giro y FOV 34, como `CreatureBuilder.portrait` |
| 5 Marco | Por rareza (§5.2) | Imagen 9-slice |
| 6 Gema e iconos | Arriba a izquierda y derecha | Imágenes reutilizables |
| 7 Nombre y número | Abajo | Fredoka/Nunito (`ART_DIRECTION.md` §5) |

- **Encuadre (propuesta):** formato 4:3 horizontal en el Álbum, como las láminas de la p. 25; retrato
  cuadrado en fichas (hoy, 160 × 160). La criatura ocupa el 60–70 % de la altura (Tallado) o el 50–60 %
  (Brote); los ojos en el tercio superior; ni el aura ni los iconos tapan la cara ni el rasgo firma.
- **Fondo del Valle Copal:** hora dorada, guirnalda de papel picado en la franja superior, lomas suaves y
  sol con espiral (láminas p. 49–51); paleta del Valle (`ART_DIRECTION.md` §4).
- **Álbum:** las cartas que faltan son una silueta oscura con el número (p. 25). Se generan con el mismo
  ViewportFrame y el modelo en negro.

---

## 11. Validación en Studio (lista para el paso 8)

- [ ] Escala: Brote 2,5 ± 0,3 studs en su dimensión mayor; Tallado = Brote × `talladoScale` ± 5 %.
- [ ] Frente en +Z local; pivote en el suelo; sin flotar ni hundirse en `Idle` y `Walk`.
- [ ] Triángulos, huesos y tamaño de textura dentro de §2.
- [ ] Materiales correctos con la luz del Valle (`Ambience.luau`) y dentro del ViewportFrame.
- [ ] Emisivo solo en surcos y rasgo firma; ojos y rasgo firma libres de aura.
- [ ] Aura según la rareza; 60 % en combate; Brote al 80 % y con la mitad de partículas.
- [ ] Opaco ↔ restaurado reversible; ninguna lectura de muerte ni de terror.
- [ ] Todos los clips de §8 dentro de sus topes; marcadores `Impact` presentes.
- [ ] Silueta reconocible a 64 px y con LOD automático a 60 studs.
- [ ] 8 monstruos con aura a 30 fps en el teléfono base (obligatoria antes de aprobar un Legendario, Biblia p. 120).
- [ ] Calidad gráfica mínima sin perder el rasgo firma.
- [ ] Accesorios en `ACC_*` sin atravesar la malla en `Idle` y `Walk`.
- [ ] Salida de Studio sin errores; `./scripts/check.sh` en verde tras actualizar `Visuals` y las pruebas.
- [ ] Prueba de `tests/Playtest/STUDIO_PLAYTEST.md` ejecutada y anotada; no se marca lo que no se ejecutó.
