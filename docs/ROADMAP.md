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
- Documentos: `CLAUDE.md`, `README.md`, `DESIGN_DECISIONS.md` (21 decisiones, 11 contradicciones), `GAME_DESIGN.md`, `TECHNICAL_ARCHITECTURE.md`, `MVP_SCOPE.md`, `ART_DIRECTION.md`, `art/STARTERS_REDESIGN.md`, `MONETIZATION_STRATEGY.md`.
- Configuración de la Biblia en datos: 50 especies, 12 elementos, 72 ataques + 8 firmas, 8 talentos, rarezas, roles, progresión, combate, economía, santuario, encuentros, recompensas, onboarding, analítica, visuales y mundo.
- Dominio puro: motor de combate determinista, IA, progresión, Vínculo, Tallado; reglas de servidor y casos de uso; perfil versionado con migraciones; persistencia con bloqueo de sesión.
- Servidor Roblox: gateway de remotes validado, datos, mundo procedural de Valle Copal, juego, combate, analítica, modo de desarrollador.
- Cliente Roblox: red, estado, HUD, modales, acompañantes para todos los jugadores, Opacos, combate presentado, retratos 3D.
- Calidad: 97 pruebas Lune, Selene sin errores, `rojo build` OK, paridad Luau↔JS 175/175.
- Vista previa web jugable publicada (misma config y motor) y probada en Chromium de escritorio y móvil.
- **Pase gráfico de la vista previa:** cielo con degradado, bloom, pasto instanciado con viento, agua con sombreado, flores, papel picado, Gran Nexo con vetas brillantes, luciérnagas, criaturas con luz de contorno, contorno y parpadeo, partículas por elemento en combate y calidad adaptativa en móvil.
- **Revisión independiente del código Roblox (corregida):**
  - Prompts sin conectar con streaming → D-019 y un único despachador de `ProximityPromptService`.
  - Se podía perder el primer perfil enviado → `Client/PushBuffer` guarda los mensajes que llegan sin oyente, y la acción `Profile.Get` vuelve a pedir la vista.
  - Granjeo de XP huyendo → D-020.
  - Carrera al cerrar el servidor → `BindToClose` espera a las sesiones y a los guardados en curso; el bloqueo caduca a los 360 s en producción y a los 60 s en Studio.
  - Error al aplicar un resultado de combate → el jugador nunca queda "en combate".
  - Campos de `AnalyticsService` → claves `CustomField01..03` fijas (`Util/AnalyticsFields`), los números van al valor del evento.
  - Rechazos remotos → registro limitado a 5 por minuto y jugador, sin texto del cliente.
  - En combate, los números flotantes ya no se borran en cada turno, y "Huir" se reactiva si falla.
  - El acompañante ya no se apoya en el papel picado ni en los halos (`RespectCanCollide`).
  - Los Opacos restaurados recuperan su color en el mundo.
  - Apodos: se escapan en el texto enriquecido y se recortan por caracteres UTF-8.
  - Comandos de desarrollador → D-021; `Dev.ResetProfile` reinicia también el estado público y el cliente.
- **Pase gráfico en Roblox:**
  - Ambiente en datos (`Config/Ambience`): pasto animado, nubes, agua con reflejo, flores, árboles, rocas y arbustos del perímetro, juncos y basalto en la Linde, y motas de copal.
  - Caras de los Brotes con dos brillos, rubor y sonrisa.
  - Disco de cielo de Mitlaxis corregido: antes era un disco vertical gigante y el azul daba vueltas de campana.
  - Comprobado con la galería y la vista del valle generadas desde el código real (`tools/roblox-preview`) y con `World.spec` (la API de Roblox valida clases y propiedades). La luz real se verá en Studio.

## Siguiente bloque (orden recomendado)
1. **Validar en Roblox Studio** con `tests/Playtest/STUDIO_PLAYTEST.md` (conectar Roblox Studio MCP si es posible) y corregir lo que aparezca en la primera ejecución.
2. **Efectos de combate en Roblox**: partículas por elemento, destellos de golpe y de Golpe Nexo (la vista previa ya los tiene).
3. **Aprobar el rediseño de los iniciales** (`docs/art/STARTERS_REDESIGN.md`) y responder P1, P2, P4, P11 y P93.
4. **Cinemática de eclosión y de Tallado en Roblox** (la vista previa ya las tiene; en Roblox hay tarjeta pero no animación 3D).
5. **Pulido de la Linde de las Chinampas**: escenario de combate con cámara dedicada, efectos por elemento, sonido.
6. **Medición en dispositivo móvil de gama baja**: memoria, draw calls, 8 monstruos a 30 fps.
7. Fase 2: incubadora (tiempos y aceleración solo de tiempo), Tablón de Encargos (3 diarios + 1 semanal), Repisa de Cofres ganados, Álbum del Nexo, región 2 del Acto I y Copalia.

## Problemas conocidos y riesgos
| # | Tipo | Descripción | Acción |
|---|---|---|---|
| R1 | Validación | Los servicios y el cliente de Roblox nunca se han ejecutado en Studio (no hay Studio ni MCP en este entorno). Ya se construyen el mundo y las criaturas con la API real de `@lune/roblox`, pero red, física, interfaz y guardado pueden fallar en la primera ejecución. | Checklist de Studio + revisión independiente del código |
| R2 | Tipos | `luau-analyze` no pudo compilarse aquí; el modo `--!strict` no se ha verificado con el analizador. | Abrir en Studio o ejecutar luau-lsp con `rojo sourcemap` |
| R3 | Balance | Xolumi tarda casi el doble en vencer al primer Opaco (D-008 / B-005). | Revisar con arte y sonido; posible Opaco de Fuego menos defensivo |
| R4 | Arte | Todos los modelos son blockouts. | Pipeline de arte (Fase 2) |
| R5 | Repositorio | El push a GitHub fue rechazado: la app de Claude no tiene acceso a `jesusballeza777-dot/NEXORA`. | Conectar GitHub e instalar la app; luego subir la rama |
| R6 | Fuente | Falta la Biblia v5 completa en `docs/reference/`. | Incorporarla y repasar `DESIGN_DECISIONS.md` |
| R7 | Producto | 93 preguntas abiertas de la v5.1 (ninguna bloquea la Fase 1). | Priorizar las de la tabla de `DESIGN_DECISIONS.md` §4 |
