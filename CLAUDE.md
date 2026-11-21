# CLAUDE.md · Reglas de desarrollo de NEXORA

Juego de colección, cuidado, evolución, santuario, aventura y combate táctico para Roblox.
Este archivo manda en todas las sesiones futuras. Léelo antes de tocar código.

## Fuentes de verdad
1. Instrucciones del usuario en la conversación.
2. `docs/DESIGN_DECISIONS.md` (qué es definido, provisional, pendiente o mejora; contradicciones).
3. La Biblia en `docs/reference/` (identidad del producto). **No conviertas una propuesta o una pregunta de la Biblia en una decisión aprobada.** Si cambias algo respecto a la Biblia, regístralo en `DESIGN_DECISIONS.md` con su justificación.
4. `docs/TECHNICAL_ARCHITECTURE.md` y `docs/MVP_SCOPE.md`.

## Principios innegociables
- **El servidor decide.** Monedas, Gemas, inventario, propiedad, eclosiones, XP, Vínculo, daño, resultados y recompensas se calculan en el servidor. El cliente solo envía intenciones; nunca cantidades.
- **Todo remote pasa por `RemoteGateway`** y se declara en `Shared/Net/Contract.luau` (tipos, rangos, frecuencia, proximidad, devOnly). Sin excepciones.
- **Datos de diseño en `Shared/Config`**, congelados con `Freeze.deep`. Nada de números de diseño en la lógica ni en la interfaz.
- **Especie ≠ instancia.** `SpeciesDefinition` (Config/Species) es compartida; `PetInstance` vive en el perfil con id único `U<userId>-<serial>`.
- **Persistencia segura:** solo `ProfileStore` (bloqueo de sesión sobre `UpdateAsync`). Nunca `SetAsync`. Cambiar la forma del perfil = subir `ProfileSchema.CURRENT_VERSION` + migración + prueba.
- **Idempotencia:** toda concesión usa un id único (`battle:<id>`, `onboarding:gift`…) y pasa por `RewardRules` (pendiente → reclamada una vez, con procedencia).
- **Pruebas destructivas nunca contra producción.** Studio usa `NEXORA_Profiles_TEST_v1` (Config/Dev).
- **Diversión antes que monetización.** Sin pay-to-win, sin cofres/huevos aleatorios pagados, sin potenciadores de suerte, sin temporizadores engañosos. Ninguna venta real hasta que el usuario lo autorice y se revise la política vigente de Roblox.
- **Arte:** los modelos actuales son blockouts (`AssetStatus = "Blockout"`). No fijes diseños de personaje sin aprobación humana. No inventes IDs de assets de Roblox. No afirmes haber generado activos con herramientas a las que no tienes acceso.
- **Propiedad intelectual:** diseños originales; no copiar siluetas, caras ni identidades de franquicias existentes ni deidades o símbolos sagrados.

## Arquitectura en una línea por capa
- `src/ReplicatedStorage/Shared/Config` · datos (Biblia → configuración).
- `src/ReplicatedStorage/Shared/Domain` · lógica pura compartida (combate, progresión, elementos, Rng).
- `src/ServerScriptService/Server/Domain` · reglas puras del servidor sobre el perfil (`Actions` es la API de casos de uso).
- `src/ServerScriptService/Server/Persistence` · `ProfileStore` + backends (Roblox y memoria).
- `src/ServerScriptService/Server/Services` · adaptadores de Roblox (remotes, datos, mundo, combate, analítica).
- `src/StarterPlayer/StarterPlayerScripts/Client` · red, estado, UI, controladores, criaturas.
- `tools/web-preview` · vista previa web jugable (misma config exportada; motor JS con paridad comprobada).

Requiere con `require(script.Parent.X)` (instancias), nunca con cadenas: así el código corre igual en Studio y en el arnés de Lune.
La lógica pura no puede usar APIs de motor (`task`, `Instance`, `workspace`…): recibe `now`, `Rng` y dependencias por parámetro.

## Flujo de trabajo
- Herramientas fijadas en `rokit.toml` (rojo, lune, stylua, selene).
- Antes de cada commit: `./scripts/check.sh` (StyLua, Selene, pruebas Lune, `rojo build`, vista previa y paridad Luau↔JS). Todo debe quedar en verde.
- Nueva regla o sistema ⇒ prueba en `tests/Unit` o `tests/Integration`. Bug encontrado ⇒ prueba que lo reproduce y luego el arreglo. Corrige causas, no síntomas.
- Si cambias `Shared/Domain/Battle` o la config que usa, reconstruye la vista previa: `lune run tools/web-preview/build && node tools/web-preview/parity.mjs`. Si la paridad falla, el port `tools/web-preview/src/engine.js` debe actualizarse en el mismo cambio.
- Studio: `rojo serve` + plugin de Rojo; validar con `tests/Playtest/STUDIO_PLAYTEST.md`. **No declares una prueba exitosa si no la ejecutaste.** Si Roblox Studio MCP está conectado, úsalo para inspeccionar el árbol, la consola y hacer playtests.
- Mantén `docs/ROADMAP.md` (hecho, pendiente, problemas) al día al cerrar cada bloque.

## Estilo
- `--!strict` en todos los archivos Luau. Tipos exportados para datos compartidos.
- Comentarios y textos de juego en español; identificadores en inglés salvo términos del mundo (Savia, Tallado, Opaco, VID/ATQ/DEF/ESE/VEL).
- Sin scripts gigantes ni globales; responsabilidades acotadas; sin esperas arbitrarias para sincronizar.
- Interfaz móvil primero: objetivos táctiles ≥ 48 px, texto ≥ 14 px, una sola ventana de tutorial a la vez.

## Lo que no se hace sin autorización explícita
Publicar el juego, gastar Robux o créditos de herramientas, activar productos de desarrollador o suscripciones, escribir en el DataStore de producción, borrar datos, o tomar decisiones de las 93 preguntas abiertas en nombre del equipo.
