# NEXORA · Paquete de producción de arte (Fase 2)

> **Estado del paquete: propuesta v0.1 · 21 nov 2026.** Nada de esta carpeta es un diseño aprobado.
> Los prompts y especificaciones para herramientas externas están marcados **«propuesto — no ejecutado»**.
> Los modelos que hoy se ven en Roblox y en la vista previa web son **blockouts procedurales**.

Fuentes, por orden de autoridad (CLAUDE.md): instrucciones del usuario → `docs/DESIGN_DECISIONS.md` →
Biblia (`docs/reference/NEXORA_Biblia_Compacta_v1.0.pdf`, que transcribe la Biblia v5.0; las páginas
citadas como «Biblia p. N» son las de la fuente v5.0) → `docs/ART_DIRECTION.md` y la configuración
(`Shared/Config/Species.luau`, `Visuals.luau`, `Rarities.luau`, `Elements.luau`).

**Convención de cifras:** toda cifra con «(Biblia p. N)» viene de la Biblia. Toda cifra sin esa cita es
**propuesta** y lo indica en su tabla o en su línea. «Verificar» marca un límite de la plataforma Roblox
que se confirma en la documentación vigente antes de importar.

---

## 1. Índice

| Archivo | Contenido | Estado |
|---|---|---|
| [`STARTERS_REDESIGN.md`](STARTERS_REDESIGN.md) | Exploración de tres siluetas por inicial y opción recomendada | Propuesta (existente) |
| [`SPECIES_MATRIX.md`](SPECIES_MATRIX.md) | Las 50 especies: datos de configuración, estado de arte, prioridad de beta y notas | Propuesta |
| [`PRODUCTION_SPECS.md`](PRODUCTION_SPECS.md) | Presupuestos por forma y rareza, reglas Brote/Tallado, rareza visual, Opaco, rig, animación e importación en Roblox | Propuesta |
| [`GEMINI_PROMPTS.md`](GEMINI_PROMPTS.md) | Plantillas de concepto 2D (Brote, Tallado, Opaco, carta) y prompts de los 14 nativos del Valle Copal | Propuesto — no ejecutado |
| [`MESHY_SPECS.md`](MESHY_SPECS.md) | Imagen/texto a 3D, retopología, horneado y exportación hasta Roblox; notas de Kuachi, Xolumi y Teselo | Especificación — no ejecutado |
| [`dossiers/KUACHI.md`](dossiers/KUACHI.md) | Dossier de producción Kuachi → Ascuacho | Pendiente de aprobación humana |
| [`dossiers/XOLUMI.md`](dossiers/XOLUMI.md) | Dossier de producción Xolumi → Xolossus | Pendiente de aprobación humana |
| [`dossiers/TESELO.md`](dossiers/TESELO.md) | Dossier de producción Teselo → Mitlaxis | Pendiente de aprobación humana |

Orden de lectura para quien empieza: este archivo → `PRODUCTION_SPECS.md` → un dossier → `SPECIES_MATRIX.md`.

---

## 2. Reglas duras (no negociables)

1. **Ningún diseño se aprueba automáticamente.** Solo la dirección creativa humana aprueba. Ni Claude, ni
   una herramienta, ni una prueba técnica en verde equivalen a una aprobación.
2. **Nada generado por herramientas externas se da por producido.** Gemini, Meshy o cualquier otra
   herramienta solo producen *candidatos*. Este paquete no contiene ninguna imagen ni malla generada; sus
   prompts y especificaciones están «propuesto — no ejecutado». Cuando alguien los ejecute, el resultado
   entra en el estado **Concepto** con su registro (quién, cuándo, herramienta y versión, prompt usado).
3. **Los modelos actuales de Roblox son blockouts procedurales** construidos con primitivas por
   `Client/Creatures/CreatureBuilder.luau` y marcados `AssetStatus = "Blockout"` (`Config/Visuals.luau`).
   Prueban escala, lectura y jugabilidad; no son arte final ni referencia de diseño obligatoria.
4. **Nunca se inventan IDs de assets de Roblox.** Los IDs los asigna Roblox al subir un archivo. Ningún
   documento, prompt ni archivo de configuración lleva un `rbxassetid://` que no venga de una subida real
   y validada.
5. **Diseños originales.** Sin parecido con criaturas de franquicias existentes (prueba de parecido en
   cada aprobación 2D) y sin deidades reales ni símbolos sagrados. Excluidos expresamente (Biblia p. 18):
   Ogopogo, Wendigo, Thunderbird, Xolotl, Itzpapalotl, Quetzalcóatl, Camazotz y el Sankofa convertido en
   monstruo. Los mitos son inspiración de tema, nunca retrato de una figura.
6. **Ningún gasto sin autorización explícita del usuario:** créditos de Meshy o Gemini, Robux, compras de
   assets (CLAUDE.md). Cada generación 3D se aprueba antes de gastar (Biblia p. 120).
7. **Ferocidad heroica, no terror** (Biblia p. 21): sin sangre, heridas ni ojos rojos inyectados; nunca
   llanto ni dolor explícito. Público de 9 a 16 años. Nadie «muere»: un monstruo vencido *descansa*, un
   Opaco vencido *se restaura* (Biblia p. 112).
8. **Toda desviación de la Biblia se registra** en `docs/DESIGN_DECISIONS.md` con su justificación antes
   de aplicarse en arte o código.

---

## 3. Flujo de aprobación

Cada especie y cada forma (Brote y Tallado) avanza por estos estados. Solo se avanza con la puerta
cumplida; una corrección de identidad (cara, color base, rasgo firma, silueta) devuelve la especie a
**Revisión humana**.

```
Concepto → Revisión humana → Aprobado → Modelado → Rig → Animación → Importación → Validación en Studio
```

| # | Estado | Entra con | Sale con | Responsable | Puerta |
|---|---|---|---|---|---|
| 1 | **Concepto** | Ficha de la Biblia + dossier o fila de la matriz | Tres siluetas negras a 64 px → Brote 3/4 → Tallado 3/4 (Brote como referencia) → cabeza del Tallado en 3 vistas (Biblia p. 118–119) | Artista; Gemini solo como exploración | — |
| 2 | **Revisión humana** | Hojas del concepto | Prueba de silueta a 64 px, prueba de parecido con franquicias, revisión cultural y de procedencia (Biblia p. 119), hoja de giro, 6 expresiones por forma, paleta y materiales, carta | Dirección creativa + equipo | ✔ elección de silueta; ✔ comparativa Brote/Tallado |
| 3 | **Aprobado** | Paquete 2D completo (8 entregables, Biblia p. 118) | Firma de aprobación en el registro del dossier; estilo congelado tras el Lote A | Dirección creativa | ✔ **aprobación 2D** |
| 4 | **Modelado** | 2D aprobado + gasto de créditos aprobado | Malla base (imagen a 3D multivista o modelado manual) → retopología, UV, talla horneada a normales, LOD (Biblia p. 120) dentro del presupuesto | Técnico 3D; Meshy como apoyo | ✔ gasto de créditos |
| 5 | **Rig** | Malla limpia | Esqueleto propio (no R15), pesos ≤ 4 influencias, nombres de huesos y anexos según `PRODUCTION_SPECS.md` §7 | Técnico 3D | — |
| 6 | **Animación** | Rig | Juego de animaciones de la forma (`PRODUCTION_SPECS.md` §8) con los tiempos tope de la Biblia | Animación | — |
| 7 | **Importación** | FBX/GLB validado | Modelo en Studio con MeshPart, SurfaceAppearance, Animator y la estructura de carpetas de §9 | Claude + Studio | — |
| 8 | **Validación en Studio** | Modelo importado | Escala, materiales, aura, gama baja; **8 monstruos con aura a 30 fps en el teléfono base** antes de aprobar un Legendario (Biblia p. 120); `tests/Playtest/STUDIO_PLAYTEST.md` | QA + dirección creativa | ✔ **activo aprobado** |

Solo tras el paso 8, y en el mismo cambio:
- `Config/Visuals.luau`: `assetStatus = "Approved"` y `modelAsset` con la ruta del activo validado (ver
  `PRODUCTION_SPECS.md` §9.4);
- `tests/Unit/Config.spec.luau`: la prueba que exige `"Blockout"` en las especies del vertical slice se
  actualiza para aceptar el estado aprobado de esa especie;
- `docs/ROADMAP.md` y la fila de la especie en `SPECIES_MATRIX.md`.

**No se declara una validación en Studio que no se haya ejecutado** (CLAUDE.md).

### Vocabulario de estado de arte (columna «Estado de arte» de la matriz)
| Valor | Significado |
|---|---|
| `Blockout` | Existe blockout procedural jugable con arquetipo propio; no hay concepto 2D aprobado |
| `Blockout provisional (arquetipo prestado) — no es diseño` | La especie se juega en la beta con la forma de otro arquetipo solo para poder combatir. No es referencia de silueta, escala ni color (Zunzi, Pabilo, Lumbro, Dientón) |
| `Concepto pendiente` | No hay blockout ni concepto; la especie solo vive en el catálogo |
| `Rediseño propuesto — pendiente de aprobación` | Hay propuesta escrita (STARTERS_REDESIGN + dossier) esperando la revisión humana |
| `Concepto en revisión` · `Aprobado 2D` · `En modelado` · `En rig` · `En animación` · `Importado` · `Validado` | Estados 2 a 8 del flujo |

### Registro de cada aprobación
Cada dossier tiene una tabla «Registro de aprobación» (fecha, estado, versión de la hoja, quién aprueba,
observaciones). Una especie sin dossier registra su aprobación en la columna de notas de la matriz hasta
que se le abra uno.

---

## 4. Lotes y orden de producción (Biblia p. 118 y 120)

| Lote | Qué | Tiempo (Biblia p. 118) |
|---|---|---|
| A | Hoja de estilo y 3 iniciales (Brote, Tallado, cabeza feroz) | 3 semanas |
| B | Rediseños v5: Yetormenta, Castorre, Engrifo, Voltalope, Navajazul | 2 semanas |
| C | 11 especies restantes del Valle + Copalia | 4 semanas |
| D | Marea Coralina: 8 especies + Marejadra | 3 semanas |
| E | Cumbre Brasa: 8 especies + Obsidárion | 3 semanas |
| F | Meseta Fulgor: 7 especies + Fulgorón | 3 semanas |
| G | Velo Astral y Torre: 12 especies + Noctelia, Ánima y Nexum | 4 semanas |
| H | Guardianes Velados | Por temporada |

Orden de producción 3D (Biblia p. 120): 1) Kuachi, Xolumi y Teselo (Brote y Tallado) para validar el
pipeline → 2) moneda, gema, seis cofres, incubadora y huevos por rareza → 3) Papalumen y Nexum (marketing)
→ 4) resto del Valle Copal y Copalia → 5) Cumbre Brasa con Obsidárion; Velo Astral con Noctelia.
La prioridad de beta de la matriz sigue este orden y adelanta los Opacos del Acto I que ya usa el
vertical slice.

**Primer paso (Biblia p. 118):** Lote A. Cuando se apruebe, se congela el estilo y el resto de los lotes
avanza en paralelo.

---

## 5. Preguntas abiertas que bloquean o condicionan el arte

No se responden aquí (CLAUDE.md). Propuesta actual de la Biblia entre paréntesis.

| Pregunta | Tema | Efecto en este paquete |
|---|---|---|
| P1 | Ternura del Brote («como están») | Proporciones del Brote en los dossiers |
| P2 | Ferocidad del Tallado («heroicos con mirada feroz») | Expresiones y poses del Tallado |
| P4 | Especies que no convencen (—) | Puede reabrir filas de la matriz |
| P6 | Rediseños Yetormenta, Castorre, Engrifo («sí») | Lote B |
| P9 | Variantes de Veta por especie: 3 o 5 («3») | Número de juegos de color por especie (`PRODUCTION_SPECS.md` §5.4) |
| P10 | Accesorios en combate o solo en santuario («en ambos») | Anexos de accesorios en el rig |
| P11 | 3D «juguete de vinilo» o «talla pintada» («talla pintada») | Acabado de materiales (`PRODUCTION_SPECS.md` §3.3) |
| P12 | Despertar del Tallado: corto 5 s o cinemática 12 s («corta + cinemática en Legendarios») | Animación de evolución |
| P93 | Equipo y presupuesto de arte 2D (—) | Calendario real de los lotes |
