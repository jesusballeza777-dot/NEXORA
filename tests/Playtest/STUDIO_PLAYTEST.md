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
| Huir para cultivar XP | Empezar y "Huir" 3 veces | ni XP ni recompensa; "Huir" vuelve a funcionar si el servidor rechaza | ☐ |
| Cerrar el servidor | Studio: Stop con el jugador dentro | consola sin "Guardado final fallido"; al volver, datos intactos | ☐ |
| Prompts tras recargar | Play varias veces seguidas | huevos, árbol, Despensa, lote y Opacos responden siempre | ☐ |
| Primer perfil | Play con red lenta (Studio: Network → Incoming Replication Lag 1 s) | HUD y objetivo aparecen sin quedarse en "Cargando" | ☐ |
| Apodo con símbolos | Nombrar "<b>Ñu🌶️</b>" (≥ 16 caracteres) | se ve literal (sin negrita) y recortado sin caracteres rotos | ☐ |
| Comandos de prueba | En un servidor publicado, `InvokeServer("Dev.GrantCoins", n, 100)` | `Forbidden` | ☐ |

## Móvil y rendimiento
| Prueba | Esperado | ✔ |
|---|---|---|
| Emulador de dispositivo (teléfono y tableta) | HUD legible, botones ≥ 48 px, joystick y salto no tapan la interfaz | ☐ |
| Mando (consola) | ProximityPrompts y botones accesibles | ☐ |
| MicroProfiler con 6 jugadores (Team Test) | Sin picos por los acompañantes; criaturas lejanas no se animan | ☐ |
| Dispositivo de gama baja | 30 fps con 8 monstruos en pantalla | ☐ |

Registrar los resultados (y los errores encontrados con su causa y arreglo) en `docs/ROADMAP.md`.

## Fase 2 · Content beta (validar en Studio)
Marca cada punto solo si lo ejecutaste. Usa el almacén de pruebas y `Dev.GrantXp` (Studio) para acelerar niveles.

| # | Prueba | Esperado | ✔ |
|---|---|---|---|
| F2-1 | Entrar con un perfil de la Fase 1 | Migración a la v2 sin pérdidas; el Álbum muestra el inicial y los Opacos vencidos | ☐ |
| F2-2 | Menú del Gran Nexo (botón 🌳) | Accesos rápidos: Aventura, Álbum, Criadero, Cofres, Encargos, Códice, Santuario, Decorar, Vitrina, Árbol, Historial | ☐ |
| F2-3 | Estaciones físicas (Criadero, Tablón, Repisa de Cofres, Mirador) | Cada una abre su pantalla | ☐ |
| F2-4 | Álbum: desplazarse por un bioma | Retratos 3D solo de cartas visibles y descubiertas; sin tirones en móvil | ☐ |
| F2-5 | Bestiario de una especie vista, restaurada y tallada | Revela más información en cada nivel | ☐ |
| F2-6 | Abrir un Cofre de Madera | Contenido visible antes de abrir; animación; Monedas y huevo en el inventario; segundo toque no duplica | ☐ |
| F2-7 | Incubar un huevo y salir 6 min | Al volver, listo para eclosionar; ceremonia y carta | ☐ |
| F2-8 | Incubadora del lote | Huevo flotante, dos anillos, haz de luz y grietas al 25/50/75 % | ☐ |
| F2-9 | Tablón: completar 3 diarios | Reclamar da Monedas y, el tercero, un Cofre de Madera | ☐ |
| F2-10 | Mapa del Acto I | Regiones con su color, nodos bloqueados/abiertos/estrellas, secretas "?" | ☐ |
| F2-11 | Etapa con 3 Opacos | Entra el siguiente al caer uno; contador de equipo | ☐ |
| F2-12 | Opaco con 🌿 raíces | Se cura al final del turno; un golpe eficaz muestra "¡Raíces cortadas!" | ☐ |
| F2-13 | Tesoro | Respuesta incorrecta permite reintentar; correcta da Plata y estrellas | ☐ |
| F2-14 | Copalia | Entrada con cámara, fase 2 al 50 % (escenario más oscuro, −20 % precisión), restauración y Cofre Nexo | ☐ |
| F2-15 | Tallar un monstruo | Ceremonia: aviso, giro, destello, revelación y cambios de atributos | ☐ |
| F2-16 | Decorar el lote y elegir vitrina | Objetos visibles para otros jugadores en Team Test | ☐ |
| F2-17 | Dos jugadores en Team Test | Cada uno ve sus cofres, huevos y encargos; nadie puede abrir lo del otro | ☐ |
| F2-18 | MicroProfiler en móvil emulado | Sin picos al abrir el Álbum ni en el combate contra Copalia | ☐ |
| F2-19 | Eclosionar el primer huevo y abrir Logros | Aviso «Logro: Primer latido»; la insignia aparece en el menú; reclamar da 10 Gemas y un Cofre de Madera una sola vez | ☐ |
| F2-20 | Entrar con un perfil v2 guardado en el DataStore de pruebas | Se migra a v3 sin pérdidas; los logros ya cumplidos llegan con su premio una vez | ☐ |
