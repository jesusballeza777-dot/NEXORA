# NEXORA · Hoja de ruta

| Fase | Resultado | Estado |
|---|---|---|
| 0 · Auditoría | Repo, Biblia, herramientas, Studio/MCP, riesgos | ✅ Hecha (21 nov 2026) |
| 1 · Vertical slice | Núcleo jugable: Valle, 3 iniciales provisionales, eclosión, acompañante, lote, cuidado, XP, PvE, recompensa, guardado | 🟡 Código completo y probado fuera de Studio; falta validación en Roblox Studio |
| 2 · Content beta | Colección (Álbum, Bestiario), huevos e incubadora, cofres ganados jugando, Tablón de Encargos, santuario ampliado, Acto I completo con Copalia, Códice | 🟡 Código del servidor y del cliente de Roblox completo y probado fuera de Studio (rama `phase-2/content-beta`); vista previa web jugable y probada en Chromium; logros (perfil v3); falta Studio |
| 3 · World Forge | Biblia visual, seis iniciales en 3D (propuesta), Valle Copal y Torre del Nexo nuevos, VFX por elemento y rareza, animación y seguimiento, combate visual, estructura de audio, guías de materiales, luz, biomas y rendimiento | 🟡 Producido y probado fuera de Studio (`docs/PHASE_3_IMPLEMENTATION.md`); falta la aprobación del estilo, la importación en Studio y la medición en el móvil |
| 4 · Social y competitivo | Arenas 1v1 y 2v2, clasificaciones, temporadas, intercambio, visitas, tienda (Genesis F3 §20) y retención: eventos, personalización, cosméticos deterministas | ⬜ |
| 5 · Expansión | Crianza, biomas, actos y guardianes, torneos, posible suscripción | ⬜ |

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

## Hecho en la Fase 2 (Content beta) — ver `docs/PHASE_2_IMPLEMENTATION.md`
- **Bloque A:**
  - auditoría (`docs/PHASE_2_BASELINE_AUDIT.md`), etiqueta `phase-1-stable` y respaldo del lugar compilado;
  - perfil v2 con migración probada;
  - **corrección crítica:** el motor no sustituía al monstruo caído en equipos de 2–3;
  - cola FIFO en el gateway.
- **Bloques B–F:** colección y Bestiario (lore de las 50 fichas), huevos e incubadora de 5 ranuras, cofres (catálogo de 6 con contenido fijo, D-024), Tablón de Encargos, decoración y vitrina, Acto I (16 etapas, estrellas, tesoros, rescates, secretas, raíces, Copalia en dos fases), Códice.
- **Logros** (D-033): 7 logros con Gemas, cofres, un huevo y títulos fijos; progreso calculado en el servidor; perfil v3 con migración probada.
- **Cliente Roblox:** 17 pantallas nuevas (con Logros), ceremonias (eclosión, Tallado, cofres, resultado de etapa), menú rápido, estaciones activas, combate con relevos y jefe, lotes con decoración, vitrina e incubadora animada.
- **Calidad:**
  - 151 pruebas Lune, incluido el Acto I completo de punta a punta y una prueba de humo que monta todas las pantallas con clases reales de Roblox;
  - paridad de combate 225/225 y de perfil 3/3 (Luau ↔ JS);
  - vista previa web de la Fase 2 probada con Playwright en escritorio y móvil;
  - catálogo generado (`docs/CONTENT_CATALOG.md`);
  - paquete de arte (`docs/art/`).

## Hecho en la Fase 3 (World Forge) — ver `docs/PHASE_3_IMPLEMENTATION.md`
- **Auditoría y dirección de arte:**
  - auditoría visual con capturas «antes»;
  - `ART_BIBLE_GENESIS.md`;
  - guías de materiales, luz, biomas, audio y rendimiento.
- **Criaturas:**
  - escultor procedural `tools/sculpt` (D-039);
  - seis iniciales v01 con UV, mapas PBR, LOD y esqueleto, dentro del presupuesto de la Biblia;
  - tres propuestas visuales (D-038);
  - ocho entregables por especie.
- **Integración:**
  - `MeshCreature` usa el modelo importado en Studio y, si no lo hay, el blockout (D-040);
  - la vista previa web muestra los iniciales en 3D con huesos.
- **Mundo:**
  - Valle Copal sobre terreno, con río que serpentea, cascada, chinampas, mercado y taller;
  - Gran Nexo de hebras, siete estaciones con identidad y Gabinete que Camina;
  - lotes y vida ambiental;
  - muestras de los cuatro biomas (si la fusión final las incluye).
- **VFX y animación:**
  - 12 elementos y 6 rarezas con presupuesto;
  - secuencias de ataque, impactos y cámara;
  - evolución;
  - animador por familia;
  - seguimiento con máquina de estados;
  - señales de audio sin IDs.
- **Calidad:**
  - 258 pruebas Lune;
  - recorrido móvil de la vista previa 48/48;
  - el agua del río de la vista previa vuelve a verse.

## Siguiente bloque (orden recomendado)
0. **Decidir el estilo visual (D-038)** y aprobar o corregir los seis modelos. Sin eso no se producen más especies.
1. **Validar en Roblox Studio** con `tests/Playtest/STUDIO_PLAYTEST.md` (conectar Roblox Studio MCP si es posible) y corregir lo que aparezca en la primera ejecución.
2. **Efectos de combate en Roblox**: partículas por elemento, destellos de golpe y de Golpe Nexo (la vista previa ya los tiene).
3. **Aprobar el rediseño de los iniciales** (`docs/art/STARTERS_REDESIGN.md`) y responder P1, P2, P4, P11 y P93.
4. **Cinemática de eclosión y de Tallado en Roblox** (la vista previa ya las tiene; en Roblox hay tarjeta pero no animación 3D).
5. **Pulido de la Linde de las Chinampas**: escenario de combate con cámara dedicada, efectos por elemento, sonido.
6. **Medición en dispositivo móvil de gama baja**: memoria, draw calls, 8 monstruos a 30 fps.

## Problemas conocidos y riesgos
| # | Tipo | Descripción | Acción |
|---|---|---|---|
| R1 | Validación | Los servicios y el cliente de Roblox nunca se han ejecutado en Studio (no hay Studio ni MCP en este entorno). Ya se construyen el mundo y las criaturas con la API real de `@lune/roblox`, pero red, física, interfaz y guardado pueden fallar en la primera ejecución. | Checklist de Studio + revisión independiente del código |
| R2 | Tipos | `luau-analyze` no pudo compilarse aquí; el modo `--!strict` no se ha verificado con el analizador. | Abrir en Studio o ejecutar luau-lsp con `rojo sourcemap` |
| R3 | Balance | Xolumi tarda casi el doble en vencer al primer Opaco (D-008 / B-005). | Revisar con arte y sonido; posible Opaco de Fuego menos defensivo |
| R4 | Arte | Todos los modelos son blockouts. | Pipeline de arte (Fase 2) |
| R11 | Arte | Los modelos 3D v01 son propuestas procedurales, sin revisión humana ni importación en Studio. | D-038, `STUDIO_PLAYTEST.md` F3 |
| R12 | Uso | El límite de uso de la cuenta (5 horas) detuvo a los agentes varias veces durante la Fase 3. | Trabajar con un agente a la vez |
| R5 | Repositorio | ✅ Resuelto: la rama `phase-2/content-beta` se sube a GitHub. | — |
| R6 | Fuente | Falta la Biblia v5 completa en `docs/reference/`. | Incorporarla y repasar `DESIGN_DECISIONS.md` |
| R7 | Producto | 93 preguntas abiertas de la v5.1 (ninguna bloquea la Fase 1). | Priorizar las de la tabla de `DESIGN_DECISIONS.md` §4 |
| R8 | Cofres | Faltan las tablas de probabilidad de la Biblia v5: los cofres usan contenido fijo (D-024). | Incorporar la v5 o aprobar tablas; el validador las comprueba |
| R9 | Balance | Copalia, las etapas y los retos son propuestas simuladas (D-026, D-027), no probadas con jugadores. | Playtest controlado y analítica de abandono por etapa |
| R10 | Arte | Zunzi, Pabilo, Lumbro, Dientón y Copalia usan blockouts con arquetipos prestados. | Conceptos aprobados (`docs/art/`) |
