# NEXORA · Auditoría visual de la Fase 3 (estado al terminar la Fase 2)

**Fecha:** 24 nov 2026. **Rama:** `claude/nexora-genesis-setup-ml0pwo`, sobre la Fase 2 (`29c2914`).

## 0. Cómo se hizo (y qué no se pudo hacer)

| Fuente de evidencia | Herramienta | ¿Ejecutada? |
|---|---|---|
| Criaturas de Roblox construidas con el `CreatureBuilder` real | `tools/roblox-preview` (clases de `@lune/roblox` → three.js) | ✅ |
| Valle Copal de Roblox construido con el `ValleBuilder` real | `tools/roblox-preview` (vistas llegada, aérea, lotes y Linde) | ✅ |
| Vista previa web (motor JS con paridad) | Playwright, recorrido completo de la Fase 2 | ✅ (capturas de la Fase 2) |
| Roblox Studio: Workspace, Lighting, consola, MicroProfiler, capturas reales | Roblox Studio MCP | ⛔ No hay Studio ni MCP en este entorno |

**Consecuencias:**
- La luz, el agua, el pasto, las partículas y las sombras de Roblox que se ven aquí son **aproximadas**. La geometría, los colores, los materiales y la composición sí son los reales del código.
- Ninguna afirmación de esta auditoría sustituye la revisión en Studio. La lista F2-1 … F2-20 y la nueva F3 (`tests/Playtest/STUDIO_PLAYTEST.md`) quedan pendientes.

## 1. Evidencia «antes»

| Captura | Qué muestra |
|---|---|
| `docs/phase3/audit/before-roblox-creatures.jpg` | Galería de las 39 variantes (Brote, Opaco y Tallado) del `CreatureBuilder` |
| `docs/phase3/audit/before-roblox-world-spawn.jpg` | Llegada: Gran Nexo, plaza, huevos de copal y estaciones |
| `docs/phase3/audit/before-roblox-world-aerial.jpg` | Vista aérea del valle: río recto, lotes y colinas |
| `docs/phase3/audit/before-roblox-world-lots.jpg` | Lotes Hogar y hábitats |
| `docs/phase3/audit/before-roblox-world-linde.jpg` | La Linde de las Chinampas (combate) |
| `docs/phase3/audit/before-web-battle.jpg`, `before-web-boss.jpg`, `before-web-lot.jpg`, `before-web-tallado.jpg` | Vista previa web: combate, Copalia, lote y ceremonia de Tallado |

## 2. Diagnóstico

### 2.1. Criaturas
- **Todas son blockouts de Parts:** esferas, cilindros y bloques soldados (`Client/Creatures/CreatureBuilder.luau`, 9 arquetipos en `Config/Visuals`). Las 13 especies con modelo comparten esos 9 cuerpos. Zunzi, Pabilo, Lumbro y Dientón usan arquetipos prestados (D-031).
- **Volumen y anatomía:**
  - las piezas no se funden: se ven las costuras entre esferas y cilindros;
  - no hay hombros, caderas, codos ni dedos;
  - las patas son cilindros rectos.
- **Rasgos firma:**
  - algunos son geometría correcta (disco de Mitlaxis, cántaro de Barrock);
  - otros son demasiado simples para leerse (bolsa-horno de Kuachi, branquias de Xolumi).
- **Ojos:** esferas con dos brillos, simpáticos pero sin párpados ni ceja. El Tallado no gana la mirada almendrada que pide la Biblia (p. 21), salvo un ceño plano.
- **Materiales:** un solo material liso por pieza (`SmoothPlastic`/`Neon`), sin relieve, sin rugosidad y sin texturas PBR. Todas las criaturas reaccionan igual a la luz.
- **Rareza:** solo aparece como marco de carta y aura de partículas. Los materiales no cambian con la rareza.
- **Opacos:** desaturados de forma correcta (se conserva la lectura).

### 2.2. Mundo (Valle Copal)
- **Terreno:** un plano con 14 rellenos (`FillBlock`/`FillBall`). Las colinas son domos perfectos y no hay terrazas, orillas, caminos ni desniveles jugables.
- **Río:** un canal recto de bordes rectos, sin meandros, cascada, orillas ni vegetación acuática.
- **Gran Nexo:**
  - tronco de cilindros apilados, raíces planas y copa de esferas;
  - es el landmark correcto por escala y posición, pero se lee como «árbol genérico»;
  - sin vetas, faroles integrados ni latido visible.
- **Estaciones:** cajas de color sobre peanas, todas con la misma silueta. El Gabinete que Camina no existe como criatura. Sus siete funciones se distinguen por el color, no por la arquitectura.
- **Lotes:** cuadrados planos con anillos y discos de copal; sin vida ni integración con el terreno.
- **Vida ambiental:** pasto animado y motas de copal (`Config/Ambience`). No hay aves, peces, insectos ni NPC.
- **Luz:** tarde dorada (`Future`), atmósfera ámbar y bloom. Es correcta como base, pero sin contrastes locales ni luces de interiores.

### 2.3. VFX y combate
- **Aura de rareza:** una sola textura de partículas para todo, con color por rareza (`CreatureBuilder`). Ningún elemento tiene identidad propia.
- **Combate de Roblox:**
  - números flotantes, un destello y un tono de luz;
  - no hay secuencia de ataque (preparación → impacto → reacción);
  - no hay impactos por tipo ni cámara de combate.
- **Vista previa web:** partículas por elemento (fuego, agua, etc.) y destellos de Golpe Nexo. Es mejor que Roblox, pero sigue en el mismo estilo de blockout.

### 2.4. Audio
**No hay ningún sonido** en el proyecto: ni `Sound`, ni IDs, ni música. Es correcto según la regla de no inventar IDs, pero el mundo se siente vacío.

### 2.5. Animación
- Las criaturas de Roblox se mueven con `CFrame` (bote vertical y giro), sin esqueleto ni ciclo de pasos.
- El seguimiento del acompañante usa interpolación simple: no hay máquina de estados, ni evitación de obstáculos, ni distancia mínima garantizada.

## 3. Clasificación de activos

**Estados:**
- **Aprobado:** sirve tal cual.
- **Reutilizable con mejoras:** la base vale, pero hay que mejorarla.
- **Requiere rediseño:** hay que rehacerlo.
- **Placeholder:** marcador temporal.
- **Obsoleto:** se sustituirá.
- **Pendiente de producción:** todavía no existe.

**Sin aprobado humano:** ningún activo pasa a «Aprobado» sin una persona (`ART_BIBLE_GENESIS.md` §11). «Aprobado» abajo significa solo «aprobado técnicamente como base».

| Activo | Ruta real | Estado | Motivo |
|---|---|---|---|
| Blockouts de los 6 iniciales (Kuachi, Ascuacho, Xolumi, Xolossus, Teselo, Mitlaxis) | `Client/Creatures/CreatureBuilder.luau` + `Config/Visuals.luau` | **Placeholder** → sustituir | Sin volumen ni anatomía. Ver los modelos nuevos en `assets/Creatures/Initials/` |
| Blockouts del resto de especies (7) y de Copalia | ídem | **Placeholder** | Se rehacen tras aprobar el estilo de los iniciales (Bloque B) |
| Arquetipos prestados (Zunzi, Pabilo, Lumbro, Dientón) | `Config/Visuals.luau` | **Placeholder** (D-031) | Sin diseño propio |
| Retratos 3D de las cartas (`ViewportFrame`) | `CreatureBuilder.portrait` | **Reutilizable con mejoras** | El sistema vale; cambia el modelo que se muestra |
| Opaco (desaturación) | `CreatureBuilder.setOpaco` | **Aprobado (técnico)** | La lectura funciona; con las mallas nuevas pasará a `SurfaceAppearance.Color` |
| Terreno del valle | `Server/World/ValleBuilder.luau` (`buildTerrain`) | **Requiere rediseño** | Plano, domos perfectos |
| Río y chinampas | `ValleBuilder` (`buildTerrain`, `buildDecor`) | **Requiere rediseño** | Canal recto |
| Gran Nexo | `ValleBuilder.buildTree` | **Requiere rediseño** | Árbol genérico; debe ser una estructura viva y sagrada |
| Plaza de copal y huevos iniciales | `ValleBuilder.buildPlaza`, `buildEggs` | **Reutilizable con mejoras** | La composición es buena; los materiales y el relieve no |
| Estaciones de la Torre (7) | `ValleBuilder.buildStations` | **Requiere rediseño** | Siete cajas iguales |
| Gabinete que Camina | — | **Pendiente de producción** | No existe como criatura |
| Lotes y hábitats | `ValleBuilder.buildLots`, `Client/Controllers/LotController.luau` | **Reutilizable con mejoras** | La mecánica y la colocación valen; el escenario no |
| Incubadora animada del lote | `LotController` | **Reutilizable con mejoras** | Funciona; falta material de copal y luz |
| Flora y dispersión (`FloraLayout`) | `Server/World/FloraLayout.luau` | **Reutilizable con mejoras** | Determinista y con presupuesto; las especies de árbol son genéricas |
| Ambiente (luz, atmósfera, bloom, pasto) | `Config/Ambience.luau` | **Reutilizable con mejoras** | Buena base; falta dirección de luz por zona y momentos del día |
| La Linde (combate) | `ValleBuilder.buildEncounters` | **Reutilizable con mejoras** | Composición correcta; falta escenario de combate |
| Aura de rareza | `CreatureBuilder` (1 emisor) | **Obsoleto** → sustituir por `Config/VFX` y `AuraController` | Una sola textura para todo |
| Efectos de combate de Roblox | `Client/Controllers/BattleController.luau` | **Requiere rediseño** | Sin secuencias, impactos ni cámara |
| Ceremonia de Tallado (Roblox) | `Client/UI/Ceremony.luau` | **Reutilizable con mejoras** | Tarjeta y luz; falta la transformación 3D |
| Seguimiento del acompañante | `Client/Controllers/WorldController.luau` | **Requiere rediseño** | Sin máquina de estados ni evitación |
| Sonido y música | — | **Pendiente de producción** | Nada existe; sin IDs inventados |
| Interfaz (paneles cacao, Fredoka y Nunito) | `Client/UI/*` | **Aprobado (técnico)** | Coherente con la Biblia visual |
| Vista previa web (three.js) | `tools/web-preview` | **Reutilizable con mejoras** | Mejor que Roblox en efectos; puede mostrar los modelos nuevos |

## 4. Prioridades que salen de la auditoría

1. Criaturas con volumen, anatomía y materiales: los 6 iniciales, con pipeline reproducible (Bloques B y C).
2. Valle Copal con terreno, agua, Gran Nexo vivo y estaciones con identidad (Bloques F y G).
3. VFX por elemento y rareza, secuencias de combate y cámara (Bloques E e I).
4. Seguimiento natural y animación por familia (Bloque D).
5. Estructura de audio con huecos para audio original (Bloque J).
6. Validación en Studio y medición en móvil (Bloque K), **bloqueada en este entorno**.
