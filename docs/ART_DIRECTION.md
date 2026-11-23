# NEXORA · Dirección de arte

## 1. Identidad
**Fantasía artesanal y orgánica.** Criaturas vivas y expresivas con siluetas memorables, anatomía propia,
materiales ricos, colores controlados, luz cinematográfica y efectos elementales integrados en el cuerpo.
El copal, la cerámica, las grecas, la piedra, los textiles, los metales repujados, el vidrio y los
oficios son **lenguaje de materiales y de cultura visual**, no una obligación de tallar todo en madera.
"Tallado" es el nombre de la evolución en el mundo de NEXORA, no un estilo literal de escultura.

Evitar: diseños demasiado infantiles, monstruos sobrecargados de piezas y colores, alebrijes literales,
arcoíris, copias de franquicias, deidades y símbolos sagrados.

## 2. Reglas de la especie (p. 20–21)
| Brote | Tallado |
|---|---|
| Pequeño, tierno, anatomía sencilla pero propia, ojos grandes y redondos, pocas piezas, una silueta clara, aura reducida (80 % de tamaño, mitad de partículas) | ×1,4–×1,7 de tamaño, postura dominante o de acecho, ojo almendrado con iris del elemento y pupila rasgada, ceja marcada, arma natural, una pieza que rompe la silueta, relieve tono sobre tono con emisivo en los surcos, aura por rareza |

**Las 8 reglas de la evolución:** tamaño · postura · mirada · arma natural · rompe silueta · talla y emisivo · aura de rareza · **mismo monstruo** (cara, color base y rasgo firma se conservan). Ferocidad heroica, no terror: sin sangre, heridas ni ojos inyectados. Público de 9 a 16 años.

## 3. Rareza que se ve sin leer (p. 25–27)
| Rareza | Materiales | Colores | Efecto | Emisores |
|---|---|---|---|---|
| Común | copal mate | 2–3 | ninguno | 0 |
| Raro | + pigmento brillante | 3–4 | destellos en bordes | 1 |
| Épico | + metal o vidrio | 4–5 | emisivo animado | 1–2 |
| Legendario | oro, obsidiana, luz | 5–6 | aura dorada y rayos | 2–3 |
| Único | shader propio | paleta propia | halo iridiscente | 3 |
| Misterio | geometría imposible | limitada | damero, cajones desfasados | efectos de cámara |
El aura vive detrás de la silueta; ojos y rasgo firma siempre limpios. En combate el aura baja al 60 %.

**Cartas:** gema de rareza arriba a la izquierda, iconos de elemento arriba a la derecha, fondo del
bioma, pedestal de luz, marco por rareza (liso, azul, violeta con esquinas, oro, iridiscente, punteado).
En Roblox la carta es un `ViewportFrame` con el modelo 3D sobre el fondo del bioma (implementado).

## 4. Valle Copal (escenario del slice)
- **Hora dorada** permanente en el prototipo: sol bajo y cálido, atmósfera con bruma ámbar, sombras suaves, bloom ligero.
- **Ancla visual:** el Gran Nexo, árbol de tronco retorcido con raíces que abrazan la plaza, copa de follaje facetado y faroles de copal; su corazón late (menú físico).
- **Plaza:** piedra clara con anillos de greca y escalonados de copal; papel picado alto (no tapa la cámara).
- **Paleta del valle:** copal `#E8A848`, piedra `#C4B6A0`, jade `#3E967A`, barro `#B06240`, hoja `#56965C`, corteza `#60463A`, papel picado (rosa, ámbar, azul, violeta, verde) solo en acentos.
- **Composición:** spawn mirando al árbol; río con chinampas separando la plaza de los lotes; la Linde (combate) al oeste en niebla gris; las puertas selladas de los biomas detrás del árbol como promesa.
- Todo el escenario actual es **blockout** (`AssetStatus = "Blockout"`) con composición, iluminación y profundidad trabajadas.
- **En Roblox** el ambiente vive en `Shared/Config/Ambience.luau`:
  - luz de tarde (`Future`), atmósfera ámbar, bloom, rayos de sol y corrección de color;
  - pasto animado (`Terrain.Decoration`), nubes, agua con reflejo;
  - 64 matas de flores, árboles, rocas y arbustos en el perímetro (semilla fija, fuera de zonas de juego);
  - juncos y rocas de basalto en la Linde, y una sola fuente de motas de copal.
- **Caras de los Brotes:** ojos grandes con dos brillos, rubor y sonrisa (rosada sobre cuerpos muy oscuros como Xolumi). Los Tallados conservan ojos rasgados y ceño. Mitlaxis lleva un disco de cielo con estrellas y borde de oro.
- Revisión sin Studio: `lune run tools/roblox-preview/build` genera la galería de criaturas y el valle a partir del código real de Roblox.

## 5. Interfaz
Paneles cacao translúcidos con borde de copal y motivo de greca; botones de copal con relieve; jade para
acciones de cuidado; tipografía Fredoka (títulos) y Nunito (texto). Información visual antes que texto:
iconos de elemento, corazones de Vínculo, puntos de Savia, barras con número. Botones ≥ 48 px.

## 6. Pipeline de personajes (p. 118–120 + Genesis §5.3)
| # | Paso | Responsable / herramienta | Puerta de aprobación |
|---|---|---|---|
| 1 | Investigación de concepto y procedencia cultural | Equipo + ficha de la Biblia | — |
| 2 | Tres siluetas negras legibles a 64 px | Gemini (exploración) + artista | — |
| 3 | Elegir silueta | Dirección creativa | ✔ |
| 4 | Brote 3/4 frontal | Gemini + artista | — |
| 5 | Tallado 3/4 frontal (Brote como referencia obligatoria) | Gemini + artista | — |
| 6 | Comparativa Brote/Tallado y cabeza del Tallado en 3 vistas | Artista | ✔ |
| 7 | Seis expresiones por forma | Artista | — |
| 8 | Hojas de giro (frente, perfil, espalda, 3/4) | Artista | — |
| 9 | Paleta y materiales | Artista | — |
| 10 | Concepto de animación | Animación | — |
| 11 | Revisión de originalidad (parecido con franquicias) y cultural | Equipo | ✔ aprobación 2D |
| 12 | Malla 3D (image-to-3D multivista; aprobar cada gasto de créditos) | Meshy + Claude | ✔ gasto |
| 13 | Retopología, UV, talla horneada a mapa de normales, rig, LOD | Técnico 3D | — |
| 14 | Importación en Roblox Studio | Claude + Studio | — |
| 15 | Optimización y pruebas (escala, materiales, aura, gama baja, 8 monstruos a 30 fps) | QA | ✔ activo aprobado |

Ninguna imagen ni malla automática es un activo terminado. No se inventan IDs de Roblox; cuando un
modelo se apruebe, `Config/Visuals` pasará `assetStatus` a `Approved` con su `modelAsset` real.

**Presupuestos por activo:** Brote 2 500–4 000 tris · Tallado Común–Épico 4 000–6 500 · Legendario/Único 6 500–9 000 · Ser Sagrado 9 000–14 000 · huevo 600–1 200 · cofre 1 000–2 000; texturas 1024² (2048² para cinemáticas y jefes).

**Orden de producción:** iniciales (Brote y Tallado) para validar el pipeline → moneda, gema, cofres,
incubadora y huevos → Papalumen y Nexum (marketing) → resto del Valle y Copalia → Cumbre y Velo.

Rediseño de los tres iniciales: `docs/art/STARTERS_REDESIGN.md`.

Paquete de producción de la Fase 2: ver `docs/art/README.md`.

## 7. Fase 2: arquitectura visual en el juego
- **Brote y Tallado:** una sola especie (`SpeciesDefinition`) y dos representaciones con paleta, escala, ojos y piezas propias (`Config/Visuals.brote/tallado` → `CreatureBuilder`). El Tallado conserva cara, color base y rasgo firma. La evolución es una ceremonia (`UI/Ceremony.evolve`: aviso → giro → destello real de la luz → revelación → cambios de atributos), no un cambio de escala.
- **Rareza:**
  - marco y gema en las cartas (`Rarities.frameColor`);
  - aura de partículas por rareza: ninguna en Comunes y como mucho un emisor en el Brote (p. 120); se apaga mientras el monstruo está opacado.
- **Elementos:** iconos de color por elemento en el Álbum, el Bestiario y el combate (`Elements.color`).
- **Opacos:** variante desaturada hacia gris (`setOpaco`), niebla de partículas en la Linde y recuperación del color animada al vencerlos. Nunca muertos ni terroríficos.
- **Vetas y accesorios:** el modelo de datos ya los tiene (`PetTraits.veta`, linaje). Su representación visual espera arte aprobado; no se inventan.
- **Cartas** (`ViewportFrame`): fondo por bioma, marco y gema por rareza, iconos de elemento, pedestal y modelo 3D. El Álbum solo crea los retratos visibles.
- **Incubadora del lote:** pedestal de copal, huevo flotante, dos anillos giratorios, haz de luz del color de la rareza y grietas de luz al 25/50/75 %.
- **Blockouts provisionales:**
  - Zunzi, Pabilo, Lumbro y Dientón usan arquetipos prestados;
  - Copalia, una garza de composición (patas de raíz, alas de hoja con faroles);
  - ninguno es diseño aprobado (`docs/art/SPECIES_MATRIX.md`).
- **Revisión sin Studio:** `lune run tools/roblox-preview/build` genera la galería con todas las variantes (Brote, Opaco y Tallado).
