# NEXORA · Informe de pruebas de la Fase 2

Rama `phase-2/content-beta`. Este informe recoge **solo** lo que se ejecutó de verdad. Lo que no se pudo ejecutar está en §7, marcado como no ejecutado.

## 1. Resumen
| Qué | Dónde se ejecutó | Resultado |
|---|---|---|
| `./scripts/check.sh` completo | Contenedor Linux (Lune 0.11.1, Rojo 7.7.1, Node) | ✅ En verde |
| Pruebas Lune (unitarias, integración, humo de interfaz) | Lune + arnés `VirtualGame` + `@lune/roblox` | ✅ **151/151** en 11 archivos |
| Paridad de combate Luau ↔ JS | `tools/web-preview/parity.mjs` | ✅ **225/225** combates idénticos (incluye equipos de 3 y Copalia) |
| Paridad de perfil Luau ↔ JS | `tools/web-preview/profile-parity.mjs` | ✅ 3/3 recorridos idénticos, 149 pasos con logros y migración 1→3 (ver §4) |
| Simulación del jefe | `tools/sim/boss` | Equilibrio propuesto documentado (D-027) |
| Simulación de multiplicadores | `tools/sim/elements` → `docs/BALANCE_ELEMENTS.md` | Genesis frente a la Biblia, comparados |
| Vista previa web en navegador (Playwright) | Chromium sin interfaz (SwiftShader), escritorio y móvil | ✅ Ver §6 |
| Roblox Studio | — | ⛔ No ejecutado (sin Studio ni MCP en el entorno) |

## 2. Pruebas Lune por archivo
| Archivo | Casos | Qué cubre |
|---|---|---|
| `Unit/Phase2Config.spec` | 17 | Tiempos de incubación de la Biblia; 5 ranuras con sus precios; los 6 cofres sin azar; el validador detecta la tabla incompleta (36 %), duplicados y faltantes; el tablón paga de 150 a 250 Monedas; el Acto I tiene 3×4 etapas, secretas y jefe con premios en los rangos de la Biblia; los acertijos tienen solución; retos variados; Pesadilla desactivada; lore de las 50 especies; presupuesto 128 de Copalia; **logros** con premio fijo y metas alcanzables en el Acto I |
| `Integration/Phase2Flow.spec` | 17 | Migración 1→2 de un perfil de la Fase 1; huevo con especie fijada que sigue incubándose al **cambiar de servidor** (`ProfileStore` + `MemoryBackend`); eclosión sin pérdidas con el Vivero lleno; ranuras; cofres con contenido fijado, abiertos una sola vez, sin pérdidas sin espacio y sin acceso entre cuentas; rotación del tablón por día y Cofre de Madera por los tres diarios; **Acto I completo hasta Copalia**; 3 estrellas → Oro y secreta; repetición al 25 % y resultado no aplicable dos veces; rescate con tirada reproducible (~10 %); decoración, vitrina, Vivero y equipo; **logros** (eclosión → premio una sola vez, vista con progreso) y **migración 2→3** que entrega una vez los logros ya cumplidos |
| `Unit/BattleEngine.spec` | 25 (+bucles) | Fase 1 + relevo al caer un monstruo (regresión del bug), límite de turnos por equipo, raíces que curan y se cortan, fases de Copalia (−20 % de precisión), equilibrio del jefe en rangos |
| `Unit/ClientUI.spec` | 2 | **Humo de interfaz de Roblox sin Studio:** monta las 17 pantallas de la Fase 2 (incluida Logros) con clases reales de `@lune/roblox` y vistas reales del servidor pasadas por JSON (perfil nuevo y avanzado). Montarlas no envía solicitudes. |
| `Unit/World.spec` | 9 | Mundo con la API real de Roblox, prompts con manejador (incluidas las estaciones nuevas), presupuesto de partes/luces/emisores, flora, criaturas (incluidos los nuevos blockouts y Copalia) |
| `Integration/Phase1Flow.spec`, `Unit/{Config,Progression,Guard,Contract,Adapters}.spec` | 68 (+bucles) | Fase 1 sin regresiones |

## 3. Criterios de aceptación → prueba
| Criterio (Genesis F2 §24) | Prueba |
|---|---|
| Catálogo de 50 especies con fichas | `Phase2Config` (lore 50/50), `docs/CONTENT_CATALOG.md` generado |
| Descubrimientos, Álbum, siluetas, Brote/Tallado | `Phase2Flow` (Bestiario nivel ≥ 2 de los Opacos vencidos), `ClientUI` (Álbum por bioma y forma) |
| Huevos predeterminados, temporizador persistente, reconexión, eclosión | `Phase2Flow` (cambio de servidor a mitad de incubación) |
| XP, niveles, evolución por rareza, Vínculo | `Progression.spec` (Fase 1, sin cambios) |
| Cofres configurables, probabilidades verificadas, una sola vez, historial | `Phase2Config` (validador), `Phase2Flow` (apertura única, historial vía `HistoryRules`) |
| 3 diarias + 1 semanal, seguimiento real, reinicios | `Phase2Flow` (rotación y eventos de `Actions`) |
| Hábitats, decoración inicial | `Phase1Flow` (producción), `Phase2Flow` (decoración y vitrina) |
| Tres regiones, 12 etapas, estrellas, Tesoro, Rescate, secretas, Copalia, Cofre Nexo, Códice | `Phase2Flow` (acto completo) + `BattleEngine.spec` (fases) |
| Seguridad del servidor | `Guard`, `Contract` (toda acción tiene manejador y está en el contrato), `Phase2Flow` (propiedad entre cuentas) |

## 4. Paridad entre Luau y JS
- **Combate:** 225 combates sembrados de referencia, 175 de la Fase 1 y 50 nuevos (equipos de 3 con raíces, y Copalia contra 3 Tallados). Los eventos, el daño y el ganador son idénticos.
- **Perfil:** recorridos guionizados ejecutados por las reglas Luau reales y por `domain.js` de la vista previa, comparando el perfil resultante. Detalle en el informe de la vista previa (§6).

## 5. Simulaciones de equilibrio
| Simulación | Resultado |
|---|---|
| Copalia (nivel de combate 10, VID ×0,9) contra el equipo típico al nivel 15 | 56 % de victorias (70 % un nivel más) |
| Copalia contra 3 Tallados (nv 15/14/14) | 98 % |
| Primer ajuste (VID ×2,6, nivel 15) | **0 %**: corregido antes de integrar |
| Ventaja elemental, Genesis frente a la Biblia | Ventaja/neutro/desventaja: 79/51/21 % frente a 91/51/9 % |
| Iniciales solos en el Acto I (Genesis) | Kuachi 66 %, Xolumi 61 %, Teselo 88 % (con la Biblia, Xolumi cae al 45 %) |

## 6. Vista previa web
Playwright con Chromium sin interfaz (GPU por software), sobre `tools/web-preview/dist/NEXORA_Preview.html`. La vista previa usa la misma configuración exportada y el port JS con paridad comprobada.

| Recorrido | Escritorio 1280×720 | Móvil 390×844 táctil |
|---|---|---|
| Tutorial completo, primer combate y reclamo | ✅ | ✅ |
| Cofre de Madera → huevo → incubadora → eclosión | ✅ | ✅ |
| Encargo reclamado | ✅ | ✅ |
| Acto I: regiones 1–3, etapa de 3 rivales, Tesoro, Rescate | ✅ | ✅ |
| Copalia: fase 2 vista, restaurada | ✅ | ✅ |
| Decoración, Tallado con ceremonia, estaciones del mundo (Criadero, Tablón, Repisa, Mirador) | ✅ | ✅ |
| Recargar la página conserva el perfil | ✅ | ✅ |
| Guardado web de la Fase 1 migrado sin pérdidas | ⚠️ no terminó: el último `page.goto` agotó el tiempo tras ~24 min de recorrido | ✅ (48 comprobaciones, 0 errores de consola) |
| **Logros:** eclosión → aviso → «Reclamar premio» → +10 Gemas y Cofre de Madera; insignia en el menú | ✅ 0 errores | ✅ 0 errores |
| **Migración en el navegador:** guardado web v1 → perfil v3 (Monedas, monstruo y estrellas intactos); perfil v2 con un Tallado → v3 con «Primer Tallado» y su título pendientes al entrar | — | ✅ 0 errores |

- El recorrido largo se hizo con el perfil v2; los logros y la v3 se comprobaron después con los dos recorridos cortos de las últimas filas. El recorrido largo completo no se repitió tras añadir los logros.
- La migración de un guardado de la Fase 1 en escritorio se comprobó con la prueba corta de migración (mismo código, misma página).

## 7. No ejecutado o bloqueado
- **Roblox Studio** (servicios, red, física, interfaz real, `DataStore`, Team Test con varios jugadores): ⛔. Lista en `tests/Playtest/STUDIO_PLAYTEST.md` (F2-1 a F2-18).
- **Dispositivo móvil real y MicroProfiler:** ⛔.
- **Analizador de tipos `luau-analyze`:** no compiló en este entorno (R2). El modo `--!strict` no está verificado con el analizador.
- **Datos de jugadores:** no hay. La retención D1/D7/D30 y el abandono por etapa no están disponibles.

## 8. Errores encontrados y corregidos en la Fase 2
| Error | Causa | Arreglo | Prueba |
|---|---|---|---|
| Con equipos de 2 o 3, el combate se atascaba al caer el activo | El motor no traía al siguiente monstruo | `bringInNext` (Luau y JS) | `BattleEngine.spec` "entra el siguiente" |
| La ficha de un monstruo de huevo fallaría | Se asumía talento y firma en toda especie | Ficha condicional + lore | `ClientUI.spec` (ficha de Zunzi) |
| Las etapas del mapa romperían el mundo (Roblox y web) | Sin marcador físico en la Linde | Solo las etapas con marcador tienen Opaco en el mundo; los combates usan la Linde de su región | `ClientUI.spec`, e2e web |
| Estrellas sin datos del combate | `BattleService` no pasaba el resumen | `BattleEngine.summary` | `Phase2Flow` |
| Espera activa en el gateway | Bucle `task.wait(0.05)` | Cola FIFO de hilos | Revisión de código (necesita Studio para la prueba real) |
| Copalia imposible (0 %) | VID ×2,6 contra un solo monstruo en campo | Nivel 10 y VID ×0,9 (simulado) | `BattleEngine.spec` "reto ganable" |
