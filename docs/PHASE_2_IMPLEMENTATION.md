# NEXORA · Fase 2 — Content Beta & Retention Systems

Rama: `phase-2/content-beta` (desde `phase-1-stable`). Estado: **beta de contenido implementada y probada fuera de Studio**. La validación en Roblox Studio sigue pendiente (no hay Studio ni MCP en este entorno).

## 1. Plan ejecutable por bloques

| Bloque | Depende de | Criterios de aceptación | Estado |
|---|---|---|---|
| A · Estabilidad | — | Auditoría, rama, respaldo, perfil v2 con migración probada, correcciones críticas | ✅ `docs/PHASE_2_BASELINE_AUDIT.md`; sustitución en combate; cola del gateway; esquema v2 |
| B · Colección | A | Catálogo de 50 con lore, descubrimientos, Álbum con siluetas, Bestiario por niveles, Brote y Tallado diferenciados | ✅ dominio, pantallas Roblox y vista web |
| C · Evolución e incubación | A, B | Huevos con resultado fijado al obtenerlos, temporizadores del servidor, reconexión, eclosión, Tallado como ceremonia | ✅ |
| D · Recompensas y misiones | A, C | Seis cofres configurables, tablas validadas, una sola entrega, historial, tablón 3+1 con rotación del servidor | ✅ (cofres con contenido fijo, D-024; logros con premio fijo, D-033) |
| E · Santuario | A | Hábitats de 4 lugares, producción, decoración inicial validada, vitrina | ✅ |
| F · Aventura | A, C, D | 3 regiones, 12 etapas, estrellas, Opacos, Tesoro, Rescate, secretas, Copalia con dos fases, Cofre Nexo, Códice | ✅ |
| G · Narrativa y acabado | B–F | Códice, ceremonias, interfaz por pantalla, rendimiento | ✅ Códice y ceremonias; ⏳ sonido (sin activos aprobados) |
| H · QA y beta | todo | Pruebas, telemetría, balance, documentación | ✅ en Lune, vista web y Playwright; ⛔ Studio |

## 2. Registro de módulos

### Añadidos
| Módulo | Capa | Para qué |
|---|---|---|
| `Shared/Config/SpeciesLore.luau` | Config | Lore de las 50 fichas de la Biblia (`Pendiente` donde falta) |
| `Shared/Config/Guardians.luau` | Config | Seres Sagrados (Copalia), fases, equilibrio propuesto |
| `Shared/Config/Incubation.luau` | Config | Tiempos por rareza, 5 ranuras y sus desbloqueos |
| `Shared/Config/Chests.luau` | Config | 6 cofres, contenido fijo de la beta, tablas parciales de la Biblia, grupos de huevos |
| `Shared/Config/Quests.luau` | Config | Encargos diarios y semanales, reinicio |
| `Shared/Config/Codex.luau` | Config | Cartas del Códice del Acto I |
| `Shared/Config/Decor.luau` | Config | Objetos, espacios y plantillas de decoración |
| `Shared/Config/Ambience.luau` | Config | Ambiente visual del valle (bloque gráfico previo) |
| `Server/Domain/CollectionRules.luau` | Dominio | Álbum, Bestiario (niveles), progreso por bioma |
| `Server/Domain/EggRules.luau` | Dominio | Huevos, incubadora, eclosión, ranuras |
| `Server/Domain/ChestRules.luau` | Dominio | Validador de tablas, obtención con contenido fijado, apertura idempotente |
| `Server/Domain/QuestRules.luau` | Dominio | Rotación determinista, progreso por eventos, reclamación, bonus |
| `Server/Domain/DecorRules.luau` | Dominio | Decoración, plantillas, vitrina, ampliación del Vivero |
| `Server/Domain/HistoryRules.luau` | Dominio | Historial de obtenciones acotado |
| `Shared/Config/Achievements.luau` | Config | 7 logros con premio fijo (D-033) |
| `Server/Domain/AchievementRules.luau` | Dominio | Progreso calculado del perfil, marca y premio idempotente, vista |
| `Server/World/FloraLayout.luau` | Mundo | Reparto determinista de flora (bloque gráfico) |
| `Client/UI/Screens/{Collection,Breeding,Adventure,SanctuaryPlus}.luau` | Cliente | Pantallas de la Fase 2 |
| `Client/UI/Ceremony.luau`, `Client/UI/QuickMenu.luau` | Cliente | Eclosión, Tallado, cofres, resultado de etapa; accesos rápidos |
| `Client/Controllers/LotController.luau` | Cliente | Decoración, vitrina e incubadora animada en los lotes |
| `tests/lib/{RobloxSandbox,Play}.luau` | Pruebas | Clases reales de Roblox en Lune; utilidades de juego |
| `tests/Unit/{Phase2Config,ClientUI,World,Adapters}.spec.luau`, `tests/Integration/Phase2Flow.spec.luau` | Pruebas | Fase 2 |
| `tools/sim/{boss,species}.luau`, `tools/catalog/build.luau`, `tools/roblox-preview/*` | Herramientas | Equilibrio del jefe, catálogo generado, vistas de Roblox sin Studio |

### Modificados
| Módulo | Cambio |
|---|---|
| `Shared/Domain/Battle/BattleEngine.luau` (+ `tools/web-preview/src/engine.js`) | Sustitución, raíces, fases de Seres Sagrados, campo de precisión, `summary`, curación de equipo |
| `Shared/Config/Encounters.luau` | Acto I completo (16 etapas), regiones, actos, Pesadilla preparada |
| `Shared/Config/{Abilities,Visuals,World,Sanctuary,Analytics}.luau` | Bosque de Faroles, blockouts nuevos, estaciones activas, ampliación del Vivero, eventos |
| `Server/Domain/{Actions,EncounterRules,RewardRules,ProfileSchema,ProfileView}.luau` | Casos de uso de la Fase 2, perfil v2 → **v3 (logros)**, recompensas con cofres, huevos y decoración; `Actions.finish` evalúa los logros |
| `Server/Services/{GameplayService,BattleService,WorldService,RemoteGateway,PlayerDataService}.luau` | 13 acciones nuevas, resumen de combate, estado público del lote, cola FIFO, eventos de sesión |
| `Shared/Net/Contract.luau` | Acciones nuevas; `Battle.Start` sin proximidad (D-026) |
| `Client/Controllers/{BattleController,WorldController}.luau`, `Client/UI/Modals.luau`, `ClientBootstrap` | Combate multi-rival y jefe, estaciones, recompensas ampliadas, ficha segura, ceremonias |

### Pendientes (fuera de esta beta o bloqueados)
- Validación completa en **Roblox Studio** (⛔ entorno).
- **Tablas aleatorias de cofres** (faltan en la Biblia compacta, D-024).
- **Pesadilla** (preparada, desactivada hasta equilibrar Normal).
- **Sonido y música** (no hay activos aprobados; no se inventan IDs).
- **Arte final** de especies, Copalia, cofres e incubadora (`docs/art/`).
- **Visitas sociales e intercambio** (solo arquitectura: el estado público del lote ya incluye decoración y vitrina).
- **Monetización real** (prohibida en la beta).

## 3. Seguridad y multijugador
- Toda acción nueva pasa por `RemoteGateway`: tipos y rangos (`Guard`), frecuencia, secuencia, cola FIFO por jugador y proximidad en las acciones del lote.
- Cada operación actúa solo sobre el perfil de quien la pide; los ids de huevos y cofres son por cuenta (`E<userId>-n`, `C<userId>-n`). Una prueba verifica que un jugador no puede abrir el cofre de otro.
- Idempotencia:
  - el contenido de los cofres y la especie de los huevos se fijan al obtenerlos;
  - abrir borra el cofre antes de entregar;
  - las recompensas de etapa usan `battle:<id>` y `treasure:<id>:<n>`;
  - los encargos se reclaman una sola vez;
  - una eclosión sin espacio no consume el huevo.

## 4. Analítica y retención (Genesis F2 §20)
- **Eventos** (`Config/Analytics`):
  - colección: `species_discovered`, `pet_evolved`;
  - huevos: `egg_obtained`, `incubation_started`, `incubation_completed`, `egg_hatched`;
  - cofres: `chest_obtained`, `chest_opened`;
  - encargos: `quest_started`, `quest_completed`, `quest_claimed`;
  - aventura: `adventure_stage_started`, `adventure_stage_completed`, `stage_star_earned`, `opaco_restored`, `guardian_battle_started`, `guardian_defeated`;
  - otros: `codex_entry_unlocked`, `sanctuary_updated`, `session_started`, `session_ended`.
- **Hitos únicos** con segundos desde la creación de la cuenta: `second_creature`, `first_hatch`, `first_evolution`, `first_stage_completed`.
- **Retención D1/D7/D30:** se calculará en Creator Analytics (cohortes por día de `session_started`). **No hay datos reales:** el juego no se ha publicado. Ningún indicador de retención, abandono por etapa o duración de sesión está disponible todavía, y no se presenta ninguna cifra inventada.
- **Abandono por etapa:** `adventure_stage_started` frente a `adventure_stage_completed`, por id de etapa.

## 5. Rendimiento
- **Álbum:** retratos 3D solo de cartas visibles y descubiertas, como mucho 2 por fotograma; nunca los 50 a la vez.
- **Mundo:** 835 partes, ≤ 12 luces y ≤ 8 emisores (`World.spec`). La decoración y la incubadora se construyen en el cliente, sin colisión ni consultas.
- **Combate:** el modelo se sustituye al cambiar de monstruo (nunca hay más de 2 en escena).
- **Pendiente:** medición en un móvil modesto con Studio y MicroProfiler (⛔).

## 6. Cómo probarlo
- `./scripts/check.sh`: formato, lint, pruebas Lune (Fase 1 y 2), `rojo build`, vista previa web, paridad de combate y de perfil, vistas de Roblox.
- Vista previa web: `tools/web-preview/dist/NEXORA_Preview.html` (y el Artifact publicado).
- Roblox Studio: `rojo serve` y `tests/Playtest/STUDIO_PLAYTEST.md` (sección Fase 2).
