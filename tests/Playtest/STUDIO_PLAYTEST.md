# Validación en Roblox Studio (Fase 1)

Lo que no puede ejecutarse fuera de Roblox (servicios, mundo, cliente) se valida aquí. Marca cada
punto solo si lo **ejecutaste** y viste el resultado. Si Roblox Studio MCP está conectado, Claude puede
recorrer esta lista: inspeccionar el árbol, leer la consola y hacer playtests.

## Preparación
1. `rokit install` y `rojo serve` en la raíz del repo; en Studio, plugin de Rojo → Connect.
2. Game Settings → Security → **Enable Studio Access to API Services** (usa el almacén `NEXORA_Profiles_TEST_v1`; nunca el de producción). Si está desactivado, el juego usa memoria y lo avisa en la consola.
3. Output visible. Debe aparecer `[NEXORA][INFO][Bootstrap] Servidor listo … (almacén: StudioTestStore)` sin errores rojos.

## Recorrido de aceptación (cuenta nueva)
| # | Paso | Esperado | ✔ |
|---|---|---|---|
| 1 | Play | Aparece en la plaza mirando al Gran Nexo; intro con "Saltar" | ☐ |
| 2 | Saltar intro | HUD visible, objetivo "Elige tu huevo" | ☐ |
| 3 | Acercarse a los huevos | Late un color al acercarse; prompt "Elegir este huevo" | ☐ |
| 4 | Elegir (repetir con cada huevo en cuentas/perfiles nuevos) | Tarjeta de Kuachi / Xolumi / Teselo; nombre opcional | ☐ |
| 5 | "¡Vamos!" | El Brote aparece y sigue al jugador sin tirones; objetivo "Visita tu Lote Hogar" | ☐ |
| 6 | Llegar al lote | Regalo (100 Monedas, 3 Raciones), ventana del santuario | ☐ |
| 7 | Colocar y recoger | +50 Monedas; el lugar muestra al monstruo o la marca de paseo | ☐ |
| 8 | Ficha → Ración básica | +150 XP (×10 en Studio), sube a nivel 2+ | ☐ |
| 9 | Jugar | +1 Vínculo; el acompañante salta | ☐ |
| 10 | Ir a la Linde y "Restaurar" | Cámara de combate, tarjetas, botones con "▲ Eficaz" | ☐ |
| 11 | Combatir hasta el final | Daños, Savia, especiales; el Opaco recupera su color | ☐ |
| 12 | Reclamar | 200 Monedas, 10 Gemas, 2 Raciones de bioma, XP; objetivo "Explora el Valle Copal" | ☐ |
| 13 | Salir y volver a entrar | Mismo nivel, Monedas, monstruo y paso; sin intro ni eclosión repetidas | ☐ |
| 14 | Salir **antes** de reclamar y volver | La recompensa sigue pendiente en el menú del árbol | ☐ |
| 15 | Llegar a nivel 12 y 2 corazones | "✨ Tallar" en la ficha → forma Tallado | ☐ |

## Seguridad y robustez
| Prueba | Cómo | Esperado | ✔ |
|---|---|---|---|
| Remote con tipos erróneos | Barra de comandos del cliente: `game.ReplicatedStorage.NexoRemotes.NexoRequest:InvokeServer("Care.Feed", 999, 5, {})` | `{ok=false, err="Arg1NotString"}` | ☐ |
| Repetición | Repetir una solicitud con el mismo `seq` | `BadSequence` | ☐ |
| Spam | 20 solicitudes `Care.Play` seguidas | `RateLimited` | ☐ |
| A distancia | `Sanctuary.Collect` desde la plaza | `TooFar` | ☐ |
| Turno repetido | Enviar dos veces `Battle.Act` con el mismo turno | segundo `BadTurn` | ☐ |
| Dos servidores | Team Test con el mismo usuario en dos sesiones | la segunda no carga hasta liberar; sin duplicados | ☐ |
| Desconexión en combate | Cerrar durante un combate | sin resultado ni recompensa; al volver todo intacto | ☐ |

## Móvil y rendimiento
| Prueba | Esperado | ✔ |
|---|---|---|
| Emulador de dispositivo (teléfono y tableta) | HUD legible, botones ≥ 48 px, joystick y salto no tapan la interfaz | ☐ |
| Mando (consola) | ProximityPrompts y botones accesibles | ☐ |
| MicroProfiler con 6 jugadores (Team Test) | Sin picos por los acompañantes; criaturas lejanas no se animan | ☐ |
| Dispositivo de gama baja | 30 fps con 8 monstruos en pantalla | ☐ |

Registrar los resultados (y los errores encontrados con su causa y arreglo) en `docs/ROADMAP.md`.
