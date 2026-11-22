# NEXORA · Auditoría de la Fase 1 (línea base de la Fase 2)

Fecha: 21 nov 2026 · Commit auditado: `a06da4f` (etiqueta `phase-1-stable`) · Rama de trabajo: `phase-2/content-beta`.

## Cómo se auditó
- Revisión archivo por archivo de `src/`, `tests/`, `tools/` y `docs/`.
- `./scripts/check.sh` completo en el commit auditado, en verde:
  - StyLua sin cambios y Selene con 0 errores y 0 avisos.
  - **106 pruebas Lune OK**, `rojo build` OK.
  - Paridad de combate Luau↔JS: 175/175.
  - Mundo y criaturas construidos con la API real de `@lune/roblox`.
- **Roblox Studio MCP: no conectado.** En esta sesión no hay herramientas de Studio. Ningún servicio, script de cliente ni interfaz de Roblox se ha ejecutado en Studio. Todo lo que dice "validado" se refiere a Lune, Rojo o la vista previa web, nunca a Studio.

## Leyenda
| Estado | Significado |
|---|---|
| ✅ Completado y validado | Implementado y cubierto por pruebas que se ejecutaron aquí |
| 🟡 Implementado, necesita mejoras | Funciona, pero tiene deudas que la Fase 2 debe resolver |
| 🟠 Parcial | Solo una parte del alcance requerido |
| ⬜ No implementado | No existe |
| 🔴 Defectuoso | Tiene un error demostrable |
| ⛔ Bloqueado | No se puede validar o completar en este entorno |

## Resultado por sistema

| Sistema | Estado | Archivos reales | Pruebas | Hallazgos |
|---|---|---|---|---|
| Estructura del proyecto | ✅ | `default.project.json`, `src/*`, `rokit.toml`, `scripts/check.sh` | `rojo build` OK | Capas limpias: Config → Domain puro → Services → Client. Sin globales. |
| Configuración de la Biblia | 🟡 | `Shared/Config/*.luau` | `Config.spec` | Las 50 especies tienen atributos, rareza, elementos, rol, familia y bioma. Solo 8 tienen talento, firma y descripción. Falta el lore de las fichas (descripción, mezcla mítica, anatomía). **Acción B:** `Config/SpeciesLore`. |
| Comunicación cliente-servidor | 🟡 | `Shared/Net/Contract.luau`, `Services/RemoteGateway.luau`, `Client/Net.luau`, `Client/PushBuffer.luau` | `Contract.spec`, `Guard.spec`, `Adapters.spec` | Valida tipos, frecuencia, secuencia, proximidad y devOnly. **Deuda:** la serialización por jugador espera con un bucle `task.wait(0.05)`, que es una espera arbitraria. **Acción A:** cola de hilos. |
| Persistencia | ✅ | `Persistence/ProfileStore.luau`, `MemoryBackend.luau`, `RobloxBackend.luau`, `Services/PlayerDataService.luau` | `Phase1Flow.spec` (bloqueo, robo caducado, reintentos, perfil corrupto, migración) | Bloqueo de sesión sobre `UpdateAsync`; almacén de pruebas en Studio. El guardado real en DataStore está ⛔ sin probar en Studio. |
| Esquema de datos | 🟡 | `Domain/ProfileSchema.luau`, `Shared/Types.luau` | `Phase1Flow.spec` | Versión 1, sin migraciones reales. No hay secciones para colección, huevos, incubadoras, cofres, misiones, estrellas, Códice ni decoración. **Acción A:** esquema v2 con migración 1→2 probada. |
| Monstruos (`PetInstance`) | ✅ | `Domain/PetRules.luau` | `Progression.spec`, `Phase1Flow.spec` | Id `U<userId>-<serial>` monótono, procedencia, rasgos y linaje preparados. Falta la fecha de descubrimiento en la colección (B). |
| Acompañamiento | 🟡 | `Client/Controllers/WorldController.luau`, `Services/WorldService.luau` | ⛔ Studio | Seguimiento suave y reaparición. Solo validado en la vista web. |
| Alimentación, XP y Vínculo | ✅ | `PetRules`, `Shared/Domain/Leveling.luau`, `Config/Progression`, `Config/Economy` | `Progression.spec` | Curva 40·L^1,5, tope 50, umbrales de Vínculo y Tallado por rareza correctos (12/15/18/20/22/25). |
| Tallado | 🟠 | `PetRules.evolve`, `Client/UI/Modals.luau` | `Progression.spec` | La regla es correcta. En Roblox solo hay una tarjeta, sin ceremonia (anuncio, luz, revelación). **Acción C.** |
| Combate PvE (motor) | 🔴 | `Shared/Domain/Battle/BattleEngine.luau`, `BattleAI.luau` | `BattleEngine.spec`, paridad 175/175 | Correcto en 1 contra 1. **Defecto latente:** con equipos de 2 o 3, si cae el monstruo activo no entra el siguiente, y el combate se arrastra hasta el límite de turnos. No hay reglas de bioma ni fases de jefe. **Acción A (corrección crítica) y F.** |
| Encuentros (Linde) | 🟠 | `Config/Encounters.luau`, `Domain/EncounterRules.luau`, `Services/BattleService.luau` | `Phase1Flow.spec` | Existen 3 etapas de la Región 1 del Acto I, con repetición al 25 % y tope de 10 al día. Faltan 9 etapas, las secretas, el jefe, las estrellas y los retos. **Acción F.** |
| Recompensas | ✅ | `Domain/RewardRules.luau`, `Config/Rewards.luau` | `Phase1Flow.spec` (una sola reclamación, sobrevive a la desconexión) | Base válida para cofres: pendiente → reclamada, libro mayor de 500 entradas. |
| Huevos e incubadora | ⬜ | (decorado del lote en `ValleBuilder`) | — | Solo existe la pieza visual del lote. **Acción C.** |
| Cofres | ⬜ | — | — | La Biblia compacta no incluye las tablas completas: solo "Madera: Común 30 %, Raro 6 %; Oro: Épico 15 %". **Acción D** (ver D-024). |
| Misiones (Tablón) | ⬜ | (puesto "Próximamente" en el mundo) | — | **Acción D.** |
| Santuario | 🟠 | `Domain/SanctuaryRules.luau`, `Config/Sanctuary.luau` | `Phase1Flow.spec` | Funcionan 1 hábitat con 4 lugares, producción, XP pasiva y bono nativo. Faltan la vitrina (configurada, sin lógica), la decoración y la ampliación del Vivero. **Acción E.** |
| Álbum, Bestiario y Códice | ⬜ | (rejilla de siluetas solo en la vista web) | — | **Acciones B y G.** |
| Interfaz Roblox | 🟡 | `Client/UI/{Kit,Hud,Modals}.luau`, `Controllers/BattleController.luau` | ⛔ Studio | Pensada para móvil primero (objetivos ≥ 48 px). No se ha visto en un dispositivo. |
| Mundo | ✅ | `Server/World/ValleBuilder.luau`, `FloraLayout.luau`, `Config/World`, `Config/Ambience` | `World.spec` (API real de Roblox, cada prompt con manejador, presupuestos) | 835 partes (< 1 500), ≤ 12 luces, ≤ 8 emisores. |
| Interacciones (prompts) | ✅ | `WorldController` (un despachador de `ProximityPromptService`) | `World.spec` | — |
| Seguridad | 🟡 | `RemoteGateway`, `DevGate`, `Guard` | `Guard.spec`, `Adapters.spec`, `Contract.spec` | El servidor decide todo y las acciones de desarrollador son solo de Studio. Pendiente: proximidad redundante en `Battle.Start` cuando la aventura se abre desde el mapa (F). |
| Analítica | 🟡 | `Services/AnalyticsTracker.luau`, `Util/AnalyticsFields.luau`, `Config/Analytics` | `Adapters.spec` | Hay embudo de onboarding y 11 eventos. Faltan los 21 eventos de la Fase 2. **Acción H.** |
| Rendimiento | 🟡 | `CreatureBuilder` (BulkMoveTo, recorte a 140 studs), `ValleBuilder` | `World.spec` (presupuestos) | Sin medición en dispositivo: ⛔. El Álbum deberá cargar modelos bajo demanda. |
| Vista previa web | ✅ | `tools/web-preview/*` | Playwright de escritorio y móvil (sesión anterior), paridad de combate | Las reglas de perfil están duplicadas en JS (`game.js`) sin prueba de paridad. **Acción H:** paridad por escenarios. |
| Conexión Roblox Studio MCP | ⛔ | — | — | No disponible en este entorno. |

## Errores críticos y su orden de corrección
1. **Motor de combate sin sustitución** (🔴): bloquea los combates de 1 a 3 rivales y el equipo de 3 contra el jefe. Se corrige en el Bloque A, antes de ampliar la aventura, con prueba de regresión y paridad JS.
2. **Esquema sin espacio para la Fase 2** (🟡): migración 1→2 en el Bloque A, antes de cualquier sistema que guarde datos nuevos.
3. **Espera activa en `RemoteGateway`** (🟡): cola de hilos en el Bloque A.

## Lo que se conserva sin cambios
Persistencia, contrato y gateway (salvo la cola), reglas de mascotas y recompensas, mundo, ambiente, analítica base y la vista previa. No se reconstruye nada que funcione; los identificadores de especies, encuentros (`valle_r1_e1..e3`) y perfiles se mantienen.

## Respaldo
- Etiqueta Git `phase-1-stable` en `a06da4f`.
- Lugar compilado de la Fase 1: `build/backup/NEXORA_phase1.rbxlx` (en `build/`, fuera de Git; se regenera con `git checkout phase-1-stable && rojo build`).
- Paquete Git completo (`NEXORA.bundle`) entregado al usuario, porque el push a GitHub está bloqueado por permisos.
