# NEXORA · Monster Sanctuaries

Juego original de fantasía, colección, cuidado, evolución y combate táctico para **Roblox**.
Empiezas con un huevo, cuidas a tu **Brote**, desarrollas su Vínculo, lo entrenas y lo **tallas** en una
forma imponente que sigue siendo él. *Tierno al nacer. Imponente al tallarse.*

Este repositorio contiene la **Fase 1 (vertical slice)** construida según la Biblia de NEXORA y el
prompt maestro *Project Genesis*.

## Qué hay
| Parte | Dónde | Estado |
|---|---|---|
| Proyecto Roblox (Luau `--!strict`, Rojo) | `src/` | Completo para la Fase 1; pendiente de validar en Studio |
| Datos de la Biblia (50 especies, 12 elementos, 72 ataques…) | `src/ReplicatedStorage/Shared/Config` | ✅ |
| Pruebas (unitarias e integración, Lune) | `tests/` | ✅ 78 pruebas |
| Vista previa web jugable (mismas reglas y motor) | `tools/web-preview/dist/NEXORA_Preview.html` | ✅ |
| Documentación | `docs/`, `CLAUDE.md` | ✅ |

## Probarlo ya (sin Roblox)
Abre `tools/web-preview/dist/NEXORA_Preview.html` en un navegador con internet (carga Three.js desde
jsDelivr). Es el vertical slice completo con modelos provisionales: intro, tres huevos, eclosión,
acompañante, Lote Hogar, comida, Vínculo, combate contra Opacos, recompensas y Tallado. El progreso se
guarda en el navegador (simula la reconexión). El modo de prueba XP ×10 se apaga en el menú del árbol.

## Llevarlo a Roblox Studio
```bash
rokit install            # rojo, lune, stylua, selene (versiones fijadas)
rojo serve               # y en Studio: plugin de Rojo → Connect
```
Activa *Enable Studio Access to API Services* (usa el almacén de **pruebas**) y sigue
`tests/Playtest/STUDIO_PLAYTEST.md`.

## Desarrollo
```bash
./scripts/check.sh               # formato, lint, pruebas, rojo build, vista previa y paridad
lune run tests/runner Battle     # solo las pruebas cuyo archivo contiene "Battle"
lune run tools/web-preview/build # regenera la vista previa desde la config Luau
```
Reglas de trabajo: `CLAUDE.md`. Arquitectura: `docs/TECHNICAL_ARCHITECTURE.md`.

## Documentos
- `docs/DESIGN_DECISIONS.md` · definido / provisional / pendiente / mejora, contradicciones de la Biblia
- `docs/GAME_DESIGN.md` · bucle, primeros 15 minutos, sistemas y números
- `docs/MVP_SCOPE.md` · alcance y criterios de aceptación de la Fase 1
- `docs/TECHNICAL_ARCHITECTURE.md` · capas, datos, red, seguridad, persistencia, rendimiento
- `docs/ART_DIRECTION.md` y `docs/art/STARTERS_REDESIGN.md` · identidad visual y rediseño de los iniciales
- `docs/MONETIZATION_STRATEGY.md` · economía y monetización futura responsable
- `docs/ROADMAP.md` · hecho, siguiente bloque, riesgos

Todos los personajes son diseños originales. Los modelos actuales son blockouts provisionales.
