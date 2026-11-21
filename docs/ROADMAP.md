# NEXORA · Hoja de ruta

| Fase | Resultado | Estado |
|---|---|---|
| 0 · Auditoría | Repo, Biblia, herramientas, Studio/MCP, riesgos | ✅ Hecha (21 nov 2026) |
| 1 · Vertical slice | Núcleo jugable: Valle, 3 iniciales provisionales, eclosión, acompañante, lote, cuidado, XP, PvE, recompensa, guardado | 🟡 Código completo y probado fuera de Studio; falta validación en Roblox Studio |
| 2 · Primer lanzamiento | Más especies aprobadas, Tallados finales, álbum, incubadora, misiones, cofres ganados jugando, Acto I completo | ⬜ |
| 3 · Retención | Visitas, exhibiciones, eventos configurables, personalización, cosméticos deterministas | ⬜ |
| 4 · Expansión | Crianza, biomas/actos/guardianes, PvP, temporadas, torneos, posible suscripción | ⬜ |

## Hecho en el bloque 1 (Genesis)
- Auditoría: repositorio vacío; Biblia compacta leída completa (46 p.); Biblia v5 de 127 p. no está en el repo; Roblox Studio MCP **no conectado**; herramientas compiladas desde crates.io: Rojo 7.7.1, Lune 0.11.1, StyLua 2.6.0, Selene 0.31.0.
- Documentos: `CLAUDE.md`, `README.md`, `DESIGN_DECISIONS.md` (18 decisiones, 11 contradicciones), `GAME_DESIGN.md`, `TECHNICAL_ARCHITECTURE.md`, `MVP_SCOPE.md`, `ART_DIRECTION.md`, `art/STARTERS_REDESIGN.md`, `MONETIZATION_STRATEGY.md`.
- Configuración de la Biblia en datos: 50 especies, 12 elementos, 72 ataques + 8 firmas, 8 talentos, rarezas, roles, progresión, combate, economía, santuario, encuentros, recompensas, onboarding, analítica, visuales y mundo.
- Dominio puro: motor de combate determinista, IA, progresión, Vínculo, Tallado; reglas de servidor y casos de uso; perfil versionado con migraciones; persistencia con bloqueo de sesión.
- Servidor Roblox: gateway de remotes validado, datos, mundo procedural de Valle Copal, juego, combate, analítica, modo de desarrollador.
- Cliente Roblox: red, estado, HUD, modales, acompañantes para todos los jugadores, Opacos, combate presentado, retratos 3D.
- Calidad: 78 pruebas Lune, Selene sin errores, `rojo build` OK, paridad Luau↔JS 175/175.
- Vista previa web jugable publicada (misma config y motor) y probada en Chromium de escritorio y móvil.

## Siguiente bloque (orden recomendado)
1. **Validar en Roblox Studio** con `tests/Playtest/STUDIO_PLAYTEST.md` (conectar Roblox Studio MCP si es posible) y corregir lo que aparezca en la primera ejecución. Revisar el informe de la revisión independiente del código Roblox.
2. **Aprobar el rediseño de los iniciales** (`docs/art/STARTERS_REDESIGN.md`) y responder P1, P2, P4, P11 y P93.
3. **Cinemática de eclosión y de Tallado en Roblox** (la vista previa ya las tiene; en Roblox hay tarjeta pero no animación 3D).
4. **Pulido de la Linde de las Chinampas**: escenario de combate con cámara dedicada, efectos por elemento, sonido.
5. **Medición en dispositivo móvil de gama baja**: memoria, draw calls, 8 monstruos a 30 fps.
6. Fase 2: incubadora (tiempos y aceleración solo de tiempo), Tablón de Encargos (3 diarios + 1 semanal), Repisa de Cofres ganados, Álbum del Nexo, región 2 del Acto I y Copalia.

## Problemas conocidos y riesgos
| # | Tipo | Descripción | Acción |
|---|---|---|---|
| R1 | Validación | El código de servicios y cliente de Roblox nunca se ha ejecutado en Studio (no hay Studio ni MCP en este entorno). Pueden aparecer errores de API en la primera ejecución. | Checklist de Studio + revisión independiente del código |
| R2 | Tipos | `luau-analyze` no pudo compilarse aquí; el modo `--!strict` no se ha verificado con el analizador. | Abrir en Studio o ejecutar luau-lsp con `rojo sourcemap` |
| R3 | Balance | Xolumi tarda casi el doble en vencer al primer Opaco (D-008 / B-005). | Revisar con arte y sonido; posible Opaco de Fuego menos defensivo |
| R4 | Arte | Todos los modelos son blockouts. | Pipeline de arte (Fase 2) |
| R5 | Repositorio | El push a GitHub fue rechazado: la app de Claude no tiene acceso a `jesusballeza777-dot/NEXORA`. | Conectar GitHub e instalar la app; luego subir la rama |
| R6 | Fuente | Falta la Biblia v5 completa en `docs/reference/`. | Incorporarla y repasar `DESIGN_DECISIONS.md` |
| R7 | Producto | 93 preguntas abiertas de la v5.1 (ninguna bloquea la Fase 1). | Priorizar las de la tabla de `DESIGN_DECISIONS.md` §4 |
