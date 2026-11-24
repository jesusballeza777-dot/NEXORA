# NEXORA · Pipeline de diseño y producción de criaturas (Fase 3)

**Reglas visuales:** `ART_BIBLE_GENESIS.md`.
**Activos producidos:** `CREATURE_3D_ASSETS.md`.

## 1. Qué herramientas hay de verdad

| Herramienta prevista | Papel | ¿Disponible en este entorno? | Qué se hizo en su lugar |
|---|---|---|---|
| Gemini | Exploración 2D, referencias, bocetos | ⛔ No conectado | Prompts listos en `docs/art/GEMINI_PROMPTS.md` (Fase 2) |
| Meshy | Mallas image-to-3D a partir de conceptos aprobados | ⛔ No conectado (y cada gasto de créditos requiere aprobación) | Especificaciones en `docs/art/MESHY_SPECS.md` |
| Blender | Retopología, UV, horneado, rig | ⛔ No instalado | **Escultor procedural propio** (`tools/sculpt`, abajo) |
| Roblox Studio | Importación, materiales, rig, animación, validación | ⛔ No hay Studio ni MCP | Lista de importación y prueba en §6 y en `STUDIO_PLAYTEST.md` |
| **`tools/sculpt` (Python)** | Esculpido por campos de distancia → malla → UV → PBR → rig → GLB/OBJ | ✅ | Los 6 modelos iniciales v01 |

**Lo que NO se afirma:**
- Los modelos no vienen de Meshy, Gemini ni Blender.
- No se han importado en Roblox.
- No están aprobados.

Son **propuestas 3D reales** (mallas con UV, texturas y esqueleto) que se pueden abrir en cualquier visor glTF o importar en Studio.

## 2. El escultor `tools/sculpt`

### 2.1. Idea
Cada criatura se describe como **anatomía**, no como malla. Es una lista de piezas con campo de distancia (SDF):
- elipsoides, conos redondeados, tubos de Bézier, toros, cilindros y losas;
- se unen con **mezcla suave**, que forma hombros, cuello, codos y transiciones sin costuras;
- otras piezas **tallan**: boca, surcos, rejilla, grecas, párpados.

Cada pieza lleva un **material** y un **hueso**. Los detalles finos son desplazamientos del campo, se hornean al mapa de normales y no gastan triángulos:
- masas de pelaje;
- juntas de teselas;
- grecas de Mitla;
- vetas de oro.

### 2.2. Etapas
| # | Etapa | Implementación | Salida |
|---|---|---|---|
| 1 | Anatomía | `species/<especie>.py` (`brote()`, `tallado()`, `EXPRESSIONS`) | Escena SDF |
| 2 | Malla de alta | Rejilla de 0,011–0,018 studs → marching cubes (scikit-image), orientación por gradiente, solo la isla principal | 150 000–450 000 triángulos |
| 3 | Malla de juego | Simplificación cuádrica (fast-simplification) al presupuesto de la Biblia | LOD0 y LOD1 (45 %) |
| 4 | Normales | Gradiente del SDF en cada vértice (suaves y exactas) | — |
| 5 | UV | xatlas (islas sin solape, padding de 4 px) | Atlas único |
| 6 | Horneado | Cada texel se proyecta sobre la superficie del SDF y se evalúan material, normal de alta y oclusión | Mapas de 1024² (LOD0) y 512² (LOD1) |
| 7 | Rig | Huesos por especie; pesos según la cercanía a las piezas de cada hueso (los 4 mayores) | Piel en el GLB |
| 8 | Exportación | GLB (PBR + tangentes + piel), OBJ + MTL y PNG sueltos para `SurfaceAppearance` | `assets/Creatures/Initials/<Nombre>/` |
| 9 | Revisión | Visor three.js con luz de tarde (`viewer.html`, `render.cjs`): 3/4, giro, cabeza, silueta a 64 px, poses de rig | Hojas en `docs/phase3/creatures/` |

### 2.3. Mapas y convenciones
- **Unidades:** studs; Y arriba; la criatura mira hacia +Z (como `CFrame.LookVector` hacia −Z en Roblox, así que al importar se gira 180° en Y; ver §6).
- **ColorMap (sRGB):** color base con la **oclusión horneada**, porque `SurfaceAppearance` no tiene mapa de AO.
- **NormalMap:** espacio tangente con **convención OpenGL** (verde arriba), la de glTF y la de Roblox. El GLB incluye tangentes coherentes con el horneado.
- **RoughnessMap** y **MetalnessMap** en escala de grises. En el GLB van empaquetados en ORM: G = rugosidad, B = metalicidad.
- **EmissiveMask (máscara emisiva):** solo dentro de los surcos (brasas, ojos de Tallado, estrellas). Tiene dos vías en Roblox (pendientes de decidir en Studio, D-036):
  1. propiedades emisivas de `SurfaceAppearance`, si la versión vigente las ofrece (verificar en la documentación oficial);
  2. si no, una malla fina `Neon` aparte generada con la misma máscara.

### 2.4. Cómo se usa
```
pip install -r tools/sculpt/requirements.txt
python3 tools/sculpt/build.py preview kuachi tallado [expresión]   # vista rápida con color por vértice
python3 tools/sculpt/build.py asset kuachi tallado                 # activo completo
python3 tools/sculpt/build.py all                                  # los seis iniciales
node tools/sculpt/render.cjs jobs.json                             # renders de revisión (Playwright)
```
Estilos de la propuesta visual: `SCULPT_STYLE=juguete|facetado` (ver §4).

## 3. Los ocho entregables por especie (Biblia p. 118)

| # | Entregable | Cómo se produjo | Estado |
|---|---|---|---|
| 1 | Tres siluetas en negro a 64 px | Las tres opciones A/B/C están descritas en `docs/art/STARTERS_REDESIGN.md`. Se esculpió la recomendada (A) y se probó su silueta a 64 px. Las B y C no se esculpieron. | ◐ La A, probada; las B y C, solo descritas |
| 2 | Brote 3/4 frontal | Render del GLB final | ✅ |
| 3 | Tallado 3/4 frontal | Render del GLB final | ✅ |
| 4 | Cabeza del Tallado en 3 vistas | Render del GLB final (frente, perfil y 3/4) | ✅ |
| 5 | Hoja de giro de ambas formas | Render: frente, perfil, espalda y 3/4 | ✅ |
| 6 | Seis expresiones por forma | Parámetros de expresión del escultor (párpados, inclinación, ceja, boca, orejas y branquias), renderizados en primer plano | ✅ en escultura de revisión |
| 7 | Paleta y materiales | Dosieres de `docs/art/dossiers/` + mapas horneados | ✅ |
| 8 | Carta coleccionable final | Render sobre el fondo del bioma con marco de rareza Común | ✅ maqueta (el marco final es una imagen de la interfaz) |

La comparativa Brote/Tallado está en la hoja de cada especie.

## 4. Tres propuestas visuales y la recomendación

Misma anatomía y distinto acabado, para decidir la dirección **antes** de producir 47 especies más:

| Propuesta | Qué es | Ventajas | Riesgos |
|---|---|---|---|
| **A · Artesanal orgánico** (recomendada) | Relieve horneado (pelaje en masas, teselas, grecas, vetas de oro), materiales distintos por zona (mate, bruñido, metal), oclusión y emisivo solo en surcos | Cumple la Biblia visual: volumen, materiales reconocibles, rareza escalable. Se lee a 64 px. Coste igual que las otras en triángulos | Exige disciplina de paleta para no ensuciar; los mapas suben la memoria (1024² por criatura) |
| B · Juguete de cerámica | Sin relieve, brillo alto y color más saturado | Muy legible en móvil, barato | Plástico y genérico: es justo lo que el responsable pidió evitar («todo parece plástico»). La rareza pierde el escalón de materiales |
| C · Talla facetada | Malla de 1 400–2 200 triángulos con caras planas y paleta posterizada (como talla o papel) | Barato, con carácter artesanal | Rígido y «prototipo»; pelaje, branquias y humo pierden suavidad; choca con «anatomía creíble» |

**Recomendación:** **A**, con dos condiciones:
1. Revisión humana de la paleta en Studio con la luz real.
2. Prueba de memoria con 8 criaturas en pantalla (`PERFORMANCE_BUDGET.md`).

La B queda como LOD lejano barato y la C se descarta para criaturas (podría servir en props de papel picado). Las imágenes comparativas están en `docs/phase3/creatures/proposals-*.jpg`.

## 5. Control de calidad por criatura (`PHASE_3_VISUAL_QA.md`)

Silueta · anatomía · proporciones · materiales · expresión · animación · iluminación · escala · rendimiento · integración. Cada prueba indica si se ejecutó, con qué evidencia, y qué queda para Studio.

## 6. Importación en Roblox Studio (lista para cuando haya Studio)

1. **Importar.** `File → Import 3D` con `CR_<Nombre>_<Forma>_v01.glb`. Si el importador no acepta la piel del GLB, usar el OBJ (estático) y rigear en Studio.
2. **Comprobar la escala.** En studs: el GLB ya está en studs y el importador puede reescalar, así que hay que comprobar la altura frente a `asset.json → lods.LOD0.sizeStuds`.
3. **Orientación.** La criatura mira hacia +Z; girar 180° en Y para que mire a `LookVector`.
4. **`SurfaceAppearance`.** `ColorMap`, `NormalMap`, `RoughnessMap` y `MetalnessMap` con los PNG de `textures/`. `AlphaMode = Overlay`.
5. **Rig.** Si llegan los huesos (`Bone`), comprobar sus nombres con `asset.json → bones`. El `CreatureAnimator` (`ANIMATION_SYSTEM.md`) los usa por nombre.
6. **LOD.** `RenderFidelity = Automatic` para LOD0. Sustituir por LOD1 más allá de 60 studs si el perfilado lo pide.
7. **Registrar el ID.** Escribir el `rbxassetid` real en `Config/CreatureAssets.luau` (`meshAsset` y `textures`). Solo entonces el `CreatureBuilder` usa la malla en lugar del blockout.
8. **Probar.** Escala junto a un avatar de 5 studs, aura, Opaco (tinte gris con `SurfaceAppearance.Color`), retrato del Álbum, 8 criaturas a 30 fps en el teléfono base.
