# NEXORA · Control de calidad visual de la Fase 3

**Regla:** un activo no se aprueba porque se pueda importar (`ART_BIBLE_GENESIS.md` §11).

**Columnas:**
- **Resultado:** lo que se comprobó de verdad.
- **Evidencia:** el archivo o la prueba que lo respalda.
- **Pendiente:** lo que necesita Studio, un dispositivo o una persona.

**Símbolos:**
- ✅ comprobado aquí;
- ◐ comprobado en parte;
- ⛔ no ejecutable en este entorno;
- 👤 decisión humana.

## 1. Criaturas: los seis iniciales v01

| # | Prueba | Resultado | Evidencia | Pendiente |
|---|---|---|---|---|
| 1 | **Silueta** | ✅ Las seis se distinguen en negro a 64 px de perfil y en 3/4. Rasgos firma visibles en la mancha: cola en espiral, cola-látigo en S sobre el lomo, branquias en abanico, corona de volutas y seis patas, domo de teselas, fortaleza con anillos y disco | `docs/phase3/creatures/*-silhouettes.jpg` | 👤 Elegir entre las opciones A/B/C de `STARTERS_REDESIGN.md` (solo la A está esculpida) |
| 2 | **Anatomía** | ✅ Tres familias con esqueletos distintos (cuadrúpedo ágil, anfibio, reptil acorazado). Codos abiertos en Xolossus, patas columnares en las tortugas, manos de cinco dedos y pulgar trasero en Kuachi | Hojas de giro, `asset.json → bones` | Pesos pintados a mano (artista técnico) |
| 3 | **Proporciones** | ✅ Brote con cabeza grande; Tallado ×1,57 a ×1,89 con cabeza proporcionalmente menor y el peso hacia delante | `tests/Unit/CreatureAssets.spec.luau`, hojas de giro | — |
| 4 | **Materiales** | ✅ Cada criatura tiene materiales propios, horneados en mapas PBR: pelaje mate, barro cocido, hierro, barro negro bruñido, oro de reparación, teselas pulidas, piedra tallada, jade y cielo con estrellas | Renders del GLB final, `textures/` | ⛔ Respuesta a la luz real de Roblox (`SurfaceAppearance`) |
| 5 | **Expresión** | ✅ Seis expresiones por forma (neutral, desafío, ataque, victoria, cansado, cariño) con párpados, inclinación de la almendra, ceja, boca, orejas y branquias en **geometría**. Ferocidad sin horror: sin sangre ni ojos inyectados | `docs/phase3/creatures/*-expressions.jpg` | En el juego aún no se cambia de expresión: hace falta un *blendshape* o una malla por expresión (D-037) |
| 6 | **Animación** | ◐ Rig probado: ciclo de paso procedural sobre el GLB sin roturas visibles. En la vista previa web los iniciales respiran, miran, mueven la cola y caminan con sus huesos | `*-rig-walk.jpg`, vista previa web | ⛔ Animaciones de Roblox (`CreatureAnimator`) sobre los modelos importados |
| 7 | **Iluminación** | ◐ Lectura correcta con luz de tarde (clave cálida, relleno frío, contraluz) y con la luz del valle de la vista previa web | Renders y vista previa web | ⛔ Luz `Future` de Roblox |
| 8 | **Escala** | ✅ Junto a un avatar de 5 studs: Brotes a la rodilla o la cadera, Tallados a la cintura o el pecho | `docs/phase3/creatures/scale-lineup.jpg` | — |
| 9 | **Rendimiento** | ◐ Triángulos dentro del presupuesto de la Biblia (LOD0 y LOD1). Texturas: 4 mapas de 1024² por criatura (≈ 5,3 MB sin comprimir en GPU) | `CREATURE_3D_ASSETS.md`, prueba Lune | ⛔ 8 criaturas a 30 fps en el teléfono base; memoria real con la compresión de Roblox |
| 10 | **Integración** | ◐ Vista previa web: carga en < 1 s, eclosión, acompañante, Álbum y combate con los modelos nuevos, sin errores de consola. Roblox: `MeshCreature` y el registro están listos, pero no hay modelo importado | Prueba de humo con Playwright, `MeshCreature.luau` | ⛔ Importación en Studio (`CREATURE_DESIGN_PIPELINE.md` §6) |
| — | **Originalidad** | ◐ Revisión propia frente a patrones conocidos del género: la tortuga no lleva árbol ni cañones; el anfibio no es azul ni lleva burbujas; el marsupial de fuego no tiene cola-antorcha | Hojas de giro | 👤 Prueba de parecido del equipo |
| — | **Cultura** | ◐ Referencias como material y oficio (barro negro, kintsugi, grecas de Mitla, comal), sin deidades ni símbolos sagrados | `docs/art/dossiers/` | 👤 Revisión cultural |

## 2. Mundo

Valle Copal, Gran Nexo, estaciones y lotes: ver `WORLD_BUILDING.md` y las capturas «antes/después» de `docs/phase3/world/`.

**Pruebas por bioma:**
- composición;
- identidad cromática;
- profundidad;
- lectura de landmarks;
- iluminación;
- atmósfera;
- sonido;
- rendimiento;
- navegación.

Los resultados de cada una se apuntan junto a las capturas.

## 3. Efectos

Ver `VFX_SYSTEM.md`. Las pruebas automáticas cubren:
- presupuesto de emisores por rareza;
- tasa máxima;
- 60 % en combate;
- 80 %/50 % en el Brote;
- reutilización del pool y limpieza;
- duraciones de las secuencias de ataque.

**Pendiente en Studio:**
- claridad;
- legibilidad;
- intensidad;
- sincronización;
- compatibilidad móvil.

## 4. Lo que solo puede cerrar una persona o Studio

1. **Aprobar la dirección visual A** (Artesanal orgánico) frente a B y C (`proposals-*.jpg`).
2. **Aprobar o corregir los seis modelos:** pasan de `Proposal` a `Approved`.
3. **Importarlos en Studio** y validar la escala, la luz y el rendimiento en el teléfono base (`STUDIO_PLAYTEST.md`, sección F3).
4. **Producir el audio original:** los cues están definidos, pero no hay ningún archivo.
