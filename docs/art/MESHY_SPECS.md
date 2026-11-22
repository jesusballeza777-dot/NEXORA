# Especificación de malla 3D asistida (Meshy → Blender → Roblox)

> **Estado: especificación — no ejecutado.** No se ha generado ninguna malla, no se ha gastado ningún
> crédito y no existe ningún activo 3D de criatura aparte de los blockouts procedurales
> (`AssetStatus = "Blockout"`). Cada generación necesita **aprobación previa del gasto de créditos**
> (Biblia p. 120) y autorización del usuario (CLAUDE.md). Las cifras sin cita a la Biblia son **propuesta**.
> Los nombres de los parámetros de Meshy cambian entre versiones: se describen por su función.

Referencias: presupuestos, rig, animación e importación en `PRODUCTION_SPECS.md` (§2, §7, §8, §9); diseño
por especie en `dossiers/`.

---

## 1. Cuándo se usa y cuándo no

| Caso | Uso | Fuente |
|---|---|---|
| Malla base de una forma con **2D aprobado** | Imagen a 3D multivista desde la hoja de giro aprobada | Biblia p. 120 («image-to-3D multivista; aprobar cada gasto de créditos») |
| Exploración de volumen antes del 2D | Texto a 3D solo como volumen de referencia para el artista; nunca entra en el activo final | propuesta |
| Piezas de superficie dura (anillos, disco, terrazas, rejillas) | **No**: se modelan a mano en Blender | propuesta |
| Rig automático de la herramienta | **No**: el rig es propio por especie (`PRODUCTION_SPECS.md` §7); los auto-rigs suelen estar pensados para bípedos humanoides | propuesta |
| Texturas generadas | Solo como base de color para repintar u hornear; nunca se importan tal cual | propuesta |
| Variante Opaco | **No** se genera: es un juego de texturas derivado (`PRODUCTION_SPECS.md` §6) | propuesta |

Ninguna malla automática es un activo terminado: todo pasa por limpieza, revisión y Roblox Studio
(Biblia p. 120).

---

## 2. Entradas para imagen a 3D

- Vistas de la **hoja de giro aprobada**: frente, perfil, espalda y 3/4 (entregable 5, Biblia p. 118), a la
  misma escala y en proyección lo más ortográfica posible.
- Versión **sin efectos**: sin aura, sin brillo emisivo, sin sombra en el suelo, sin fondo de bioma;
  iluminación plana.
- Pose de unión del rig: neutra, simétrica, boca cerrada, ojos abiertos, cola y branquias en reposo.
- Resolución ≥ 1024 px por vista; fondo liso de un color que no aparezca en la criatura (propuesta).
- Una generación por forma (Brote y Tallado por separado). Máximo **3 intentos por forma** sin pedir una
  nueva aprobación de gasto (propuesta).

## 3. Parámetros de generación (propuesta)

| Función | Valor | Motivo |
|---|---|---|
| Modo | Imagen a 3D con varias vistas | Fidelidad a la hoja aprobada |
| Topología | Cuadriláteros, si la versión lo ofrece | Facilita la retopología |
| Densidad | Alta (≈ 30 000–100 000 polígonos) | Es la malla «alta» para hornear; la final se retopologiza |
| Simetría | Activada | Las criaturas son simétricas salvo rasgos concretos |
| Texturas | PBR activado, máxima resolución | Base de color para repintar |
| Exportación | GLB o FBX | Ambos entran en Blender |

---

## 4. Topología objetivo (malla final)

| Forma | Triángulos (Biblia p. 120) | Objetivo de trabajo (propuesta) | Huesos (Biblia p. 120) |
|---|---|---|---|
| Brote | 2 500–4 000 | 3 000–3 600 (margen para accesorios) | ≤ 18 |
| Tallado Común–Épico | 4 000–6 500 | 5 000–6 000 | ≤ 30 |
| Tallado Legendario/Único | 6 500–9 000 | 7 500–8 500 | ≤ 40 |

Reparto orientativo (propuesta): cabeza y cara 30–35 % · cuerpo 30 % · extremidades 20 % · rasgo firma
15–20 %. Ojos como piezas separadas dentro de `Body` para que los párpados cierren por encima.

---

## 5. Retopología y limpieza (Blender)

- [ ] Importar la malla alta y escalar al tamaño objetivo (Brote 2,5 studs en su dimensión mayor; Tallado × `talladoScale`).
- [ ] Corregir a mano la anatomía contra la hoja de giro: proporciones, número de dedos y patas, simetría.
- [ ] Eliminar caras internas, piezas flotantes, agujeros y geometría no-manifold; unir vértices duplicados.
- [ ] Esculpir la **talla** del Tallado (relieve tono sobre tono, surcos) en la malla alta: se hornea, no se modela en la baja (Biblia p. 119).
- [ ] Retopología a mano o semiautomática hasta el objetivo de §4; cuadriláteros limpios antes de triangular.
- [ ] ≥ 3 bucles de aristas en cada articulación que dobla; bucles concéntricos alrededor de ojos y boca.
- [ ] Silueta: los perfiles visibles a 64 px conservan sus vértices (orejas, cola, rasgo firma); se reduce en zonas planas.
- [ ] Grosor mínimo de piezas finas (orejas, aletas, branquias) ≥ 0,06 studs: las caras son de una sola cara (`DoubleSided = false`).
- [ ] Ojos, dientes, garras y rejillas como piezas separadas dentro de `Body`; piezas rígidas como objetos aparte.
- [ ] Origen en el suelo bajo el centro de masa; frente hacia el eje que el preajuste `NEXORA_Roblox` lleva a +Z en Studio (`PRODUCTION_SPECS.md` §9.1).
- [ ] Transformaciones aplicadas; nombres de objeto `Body`, `Glow` y los de las piezas rígidas.
- [ ] Recuento final de triángulos dentro del presupuesto, anotado en el dossier.

## 6. UV y texturas

- Un solo canal UV en 0–1, sin solapes salvo mitades espejadas del cuerpo. **Cara, ojos y rasgo firma sin
  espejar** (guiños, asimetrías, detalles únicos).
- Densidad de texel uniforme; la cara con el doble de densidad; margen de 8 px a 1024² (propuesta).
- Mapas, 1024², PNG: `ColorMap` (sRGB, con oclusión multiplicada al 30–50 %), `NormalMap` (espacio
  tangente; convención del canal verde a verificar en Roblox), `RoughnessMap` y `MetalnessMap` (lineales).
- `ColorMap_Opaco`: derivado por fórmula (saturación × 0,15 conservando la luminancia + tinte `#808086` al
  20 %, `PRODUCTION_SPECS.md` §6), con acción o script reproducible; reutiliza normal, rugosidad y metal.
- Vetas (P9): un `ColorMap` por Veta y por forma, mismos UV.

## 7. Horneado

- **Alta:** malla de la herramienta + correcciones + talla esculpida (grecas, surcos, cicatrices doradas).
  **Baja:** retopología.
- Hornear: normal (espacio tangente), oclusión ambiental, curvatura (para el filo claro del Raro y el
  desgaste del pigmento) y una **máscara de surcos emisivos**.
- La máscara de surcos se usa para extraer las caras de la pieza `Glow` (Neon) o, si SurfaceAppearance
  ofrece emisivo en la versión vigente (verificar), como mapa emisivo.
- Revisar costuras y deformaciones de proyección en surcos y grecas; la talla debe leerse con la luz baja
  y cálida del Valle (`Ambience.luau`).

## 8. Rig, pesos y exportación

- Rig, nombres de huesos, anexos y pesos según `PRODUCTION_SPECS.md` §7 y la lista del dossier.
- Prueba de deformación antes de exportar: `Walk`, `AttackBasic`, `Rest` y las seis expresiones en
  bruto, sin pellizcos ni piezas rígidas dobladas.
- **FBX** (binario): malla + armadura seleccionadas, transformaciones aplicadas, escala 1 (1 unidad = 1
  stud), solo huesos de deformación, sin huesos hoja, sin animación en el archivo de malla. Preajuste fijo
  `NEXORA_Roblox`.
- **GLB** (glTF 2.0 binario) como alternativa con piel; mismas reglas.
- **OBJ** solo para objetos estáticos sin huesos; nunca para criaturas.
- Animaciones: o bien en el Animation Editor de Studio sobre el rig importado, o en Blender exportando un
  FBX por clip e importándolo en el Animation Editor (verificar la importación de animación FBX en la
  versión vigente). Nombres: `A_<id>_<Forma>_<Clip>`.

## 9. Flujo completo (cada paso deja constancia en el dossier)

| # | Paso | Salida | Puerta |
|---|---|---|---|
| 1 | Preparar vistas de la hoja de giro aprobada (§2) | 4 PNG sin efectos | 2D aprobado |
| 2 | Solicitar aprobación de gasto | Registro con número de intentos | ✔ gasto |
| 3 | Generar imagen a 3D (§3) | Malla alta GLB/FBX + texturas | — |
| 4 | Revisión de la malla alta contra el 2D | Aceptada o rechazada (cuenta como intento) | Dirección de arte |
| 5 | Limpieza y talla (§5) | `NX_<id>_<Forma>_high_v###.blend` | — |
| 6 | Retopología, UV y horneado (§5–7) | Malla baja + mapas 1024² + Opaco | — |
| 7 | Rig y pesos (§8) | `NX_<id>_<Forma>_v###.blend` | — |
| 8 | Exportación | `NX_<id>_<Forma>_v###.fbx` | — |
| 9 | Importador 3D de Studio | Modelo con la estructura de `PRODUCTION_SPECS.md` §9.4 | — |
| 10 | Animaciones | Clips de §8 de las especificaciones | — |
| 11 | Validación en Studio | Lista de `PRODUCTION_SPECS.md` §11 | ✔ activo aprobado |
| 12 | Integración | `Visuals.luau` (`Approved` + `modelAsset`), pruebas, `ROADMAP.md` | `./scripts/check.sh` en verde |

---

## 10. Notas por especie

### 10.1 Kuachi → Ascuacho
- **Con la herramienta:** cabeza y cuerpo (orgánicos) de ambas formas.
- **A mano:** la **cola**. Una cola pelada, fina y en espiral se degrada en imagen a 3D. Se modela como
  curva convertida en malla: Brote en media espiral de reposo sobre `Tail_01–04`, que la animación
  enrosca; Tallado en S sobre `Tail_01–07`, con los anillos de brasa como bucles propios y máscara emisiva.
- **Bolsa:** Brote, un óvalo hundido con máscara emisiva (brasa tibia). Tallado, una rejilla de barro de
  superficie dura modelada a mano, pesada al 100 % en `Spine_01`, con el brillo detrás en `Glow`.
- **Pelaje:** sin tarjetas de pelo; mechones como masas en el normal. Orejas con el grosor mínimo de §5.
- **Común = 0 emisores:** la brasa de la cola y la bolsa son emisivo (`Glow` en Neon), sin partículas.
- **Riesgo de parecido:** evitar la cola-antorcha alta (opción C descartada en `STARTERS_REDESIGN.md`).
- Detalle: `dossiers/KUACHI.md`.

### 10.2 Xolumi → Xolossus
- **Con la herramienta:** cabeza y cuerpo. La cabeza ancha y plana es el rasgo que más se deforma: revisar
  que la separación de los ojos coincida con la hoja.
- **A mano:** las **branquias** (3 por lado) como frondas de geometría maciza de pocos polígonos con la
  pluma en el normal; sin tarjetas con transparencia (orden de dibujo y coste). En el Tallado, las
  branquias de humo de copal son frondas en forma de voluta con degradado turquesa y emisivo en el borde;
  **sin partículas** (Común = 0 emisores).
- **Seis patas (Tallado):** la herramienta tiende a generar cuatro. Se genera el torso y se duplican y
  ajustan las patas medias (`Leg_ML`, `Leg_MR`) con el mismo espaciado lateral.
- **Material:** cerámica bruñida, rugosidad 0,15–0,30. Comprobar con la luz `Future` del Valle que el
  especular no se coma la cara; la esclerótica y la boca `#EC96A0` deben leerse sobre el negro.
- **Oro de reparación (Tallado):** surcos esculpidos en la alta, horneados; color dorado como pigmento
  mate en un Común (`PRODUCTION_SPECS.md` §3.3, pendiente de decisión). Las vetas siguen el barro como
  cerámica reparada, nunca como heridas.
- Detalle: `dossiers/XOLUMI.md`.

### 10.3 Teselo → Mitlaxis
- **Con la herramienta:** solo cabeza, cuello y patas (orgánicos).
- **A mano:** el **caparazón** (domo del Brote, tres terrazas del Tallado) como superficie dura en Blender.
  El relieve de grecas sale de un **patrón propio** de altura en mosaico diseñado por el equipo (no calcado de
  fotografías de Mitla) y se hornea al normal.
- **Anillos y disco:** dos toros y un disco aplanado modelados dentro de `Body`, pesados al 100 % en los
  huesos `Ring_Outer`, `Ring_Inner` y `Disc` (los gira un script; `PRODUCTION_SPECS.md` §7). El disco lleva el cielo con estrellas pintadas y máscara emisiva; separado del lomo
  por un hueco visible en la silueta. Sin partículas (Común = 0 emisores).
- **Reparto de triángulos (Tallado):** caparazón ≤ 40 %, anillos + disco ≤ 15 %.
- **Pesos:** caparazón al 100 % en `Shell`; patas-columna con uñas de piedra rígidas.
- **Riesgo de parecido:** nada vegetal ni estructuras tipo cañón o árbol sobre el caparazón (Biblia p. 51;
  `STARTERS_REDESIGN.md`).
- Detalle: `dossiers/TESELO.md`.

---

## 11. Registro de ejecuciones

| Fecha | Especie · forma | Gasto aprobado por | Intento | Herramienta y versión | Resultado | Decisión |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |
