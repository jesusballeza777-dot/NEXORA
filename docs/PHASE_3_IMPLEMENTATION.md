# NEXORA · Fase 3 — World Forge & Creature Evolution

**Rama:** `claude/nexora-genesis-setup-ml0pwo`, sobre la Fase 2.
**Entorno:**
- sin Roblox Studio ni MCP;
- sin Gemini, Meshy ni Blender;
- con Lune, Rojo, Python (numpy, scikit-image, xatlas) y Chromium con Playwright.

Todo lo que no se pudo ejecutar está marcado.

## 1. Equipo y coordinación

Como pide el encargo, hay subagentes independientes y un responsable central (el integrador) que revisa la coherencia y aprueba la integración. Todos trabajan con la misma ley visual, `ART_BIBLE_GENESIS.md`, escrita antes de arrancar a los agentes.

| Equipo | Alcance | Rama de trabajo |
|---|---|---|
| Integrador (dirección de arte, criaturas, escultor) | Biblia visual, auditoría, pipeline 3D, seis iniciales, propuestas, vista previa web, QA y documentos de cierre | `claude/nexora-genesis-setup-ml0pwo` |
| Mundo | Valle Copal, Gran Nexo, Torre y estaciones, Gabinete que Camina, lotes, vida ambiental, muestras de biomas | worktree del agente → fusión |
| VFX y animación | `Config/VFX`, auras por rareza y elemento, pool, combate visual, evolución, `CreatureAnimator`, seguimiento, estructura de audio | worktree del agente → fusión |
| Dirección de arte (documentos) | Biblioteca de materiales, luz, Biblia de biomas, audio, presupuesto de rendimiento, `Config/BiomeArt` | worktree del agente → fusión |

Los agentes se detuvieron una vez por el límite de uso de la cuenta (5 horas) y se reanudaron de uno en uno para no volver a agotarlo.

## 2. Bloques

| Bloque | Entrega | Estado |
|---|---|---|
| A · Auditoría y Biblia visual | `PHASE_3_VISUAL_AUDIT.md` (capturas «antes» reales), `ART_BIBLE_GENESIS.md` | ✅ (sin Studio: luz aproximada) |
| B · Prototipo visual de criaturas | Tres propuestas de acabado sobre los iniciales y recomendación (D-038) | ✅ propuesta · 👤 aprobación |
| C · Modelado 3D inicial | Seis modelos v01 con UV, PBR, LOD y esqueleto (`CREATURE_3D_ASSETS.md`) | ✅ propuesta · ⛔ importación en Studio |
| D · Animación | `CreatureAnimator`, estados y personalidad, seguimiento con máquina de estados; vista previa web con huesos | ⏳ ver `ANIMATION_SYSTEM.md` |
| E · VFX | 12 elementos, rarezas, auras, pool, evolución | ⏳ ver `VFX_SYSTEM.md` |
| F · Valle Copal | Terreno, agua, vegetación, oficios, Gran Nexo vivo | ⏳ ver `WORLD_BUILDING.md` |
| G · Lotes y estaciones | Siete estaciones con identidad, Gabinete que Camina, lotes | ⏳ ver `WORLD_BUILDING.md` |
| H · Biomas restantes | Biblia de biomas + muestras ambientales | ⏳ ver `BIOME_ART_BIBLE.md` |
| I · Combate visual | Secuencias de ataque, impactos, cámara | ⏳ ver `VFX_SYSTEM.md` |
| J · Sonido y cinemáticas | Dirección sonora, catálogo de cues sin IDs, cinemáticas que se pueden saltar | ⏳ ver `AUDIO_DIRECTION.md` |
| K · Integración y optimización | Pruebas, presupuesto, documentos | ⏳ ver `PHASE_3_TEST_REPORT.md` |

## 3. Registro de módulos (integrador)

| Módulo | Capa | Para qué |
|---|---|---|
| `tools/sculpt/{sdf,core,pipeline,build,registry,webpack,sheets}.py`, `species/*.py` | Herramienta | Escultor procedural, horneado PBR, rig, exportación, registro y hojas |
| `tools/sculpt/{viewer.html,render.cjs}` | Herramienta | Renders de revisión (luz de tarde, siluetas, poses de rig, escala con avatar) |
| `assets/Creatures/Initials/*` | Activos | Seis modelos v01 (GLB, OBJ, PNG, web y `asset.json`) |
| `Shared/Config/CreatureAssets.luau` | Config (generada) | Registro de activos 3D para el juego |
| `Client/Creatures/MeshCreature.luau` | Cliente | Usa el modelo importado en Studio si existe; si no, el blockout |
| `tests/Unit/CreatureAssets.spec.luau` | Pruebas | Archivos, presupuestos, escala, estados e IDs |
| `tools/web-preview` (`game.js`, `build.luau`) | Vista previa | Los iniciales con malla, texturas y huesos en la vista previa jugable |
