# NEXORA · Informe de pruebas de la Fase 3

Rama `claude/nexora-genesis-setup-ml0pwo`. Este informe recoge **solo** lo que se ejecutó de verdad. Lo que no se pudo ejecutar está en §6.

## 1. Resumen

| Qué | Dónde se ejecutó | Resultado |
|---|---|---|
| `./scripts/check.sh` completo | Contenedor Linux (Lune 0.11.1, Rojo 7.7.1, Node 22, Python 3) | ✅ En verde |
| Pruebas Lune | Lune + arnés `VirtualGame` + clases reales de `@lune/roblox` | ✅ **258/258** en 21 archivos (151 al cerrar la Fase 2) |
| Paridad de combate Luau ↔ JS | `tools/web-preview/parity.mjs` | ✅ 225/225 |
| Paridad de perfil Luau ↔ JS | `tools/web-preview/profile-parity.mjs` | ✅ 3/3 recorridos |
| Mundo de Roblox construido con el código real | `tools/roblox-preview` | ✅ 3 216 partes · 533 rellenos de terreno · 39 criaturas |
| Activos 3D de los iniciales | `tools/sculpt` + `CreatureAssets.spec` | ✅ 6 modelos dentro del presupuesto de la Biblia |
| Vista previa web en navegador (Playwright, Chromium con GPU por software) | Recorrido completo en móvil 390×844 con los modelos 3D | ✅ 48/48 comprobaciones, 0 errores de consola |
| Roblox Studio, dispositivo móvil real, fps, memoria, audio | — | ⛔ No ejecutado (ver §6) |

## 2. Pruebas nuevas de la Fase 3

| Archivo | Casos | Qué cubre |
|---|---|---|
| `Unit/CreatureAssets.spec` | 5 | Los seis activos existen. Sus archivos (GLB, LOD1, OBJ, mapas) coinciden con `asset.json`. Triángulos y huesos dentro del presupuesto. Escala Brote → Tallado (D-034). Nadie se aprueba solo y no hay IDs inventados. |
| `Unit/MeshIntegration.spec` | 2 | Sin modelo importado se usa el blockout. Con modelo (simulado con `MeshPart`, `SurfaceAppearance` y `Bone` reales), la criatura usa la malla, el Opaco tiñe `SurfaceAppearance` y el animador usa los huesos. |
| `Unit/World.spec` (ampliada) | 22 | Presupuesto del valle (< 4 000 partes, luces de rango ≤ 12 y sin sombras, emisores ≤ 20/s, neón ≤ 1,5 studs). Siete estaciones con su prompt y manejador. El Gabinete etiquetado. El río con agua de terreno. Nada bloquea el spawn. |
| `Unit/AmbientLife.spec` | 11 | Funciones de paso puras de la vida ambiental (faroles, aves, peces, corazón del Nexo, recorrido del Gabinete) y LOD por distancia |
| `Unit/VFXConfig.spec` | 22 | Los 12 elementos y las 6 rarezas con presupuesto de la Biblia (Común 0, Raro 1 al atacar, Épico 1–2, Legendario 2–3, Único hasta 3). Tasa ≤ 20/s. Secuencias ≤ 1,6 s y Golpe Nexo ≤ 3,5 s. Calidades y LOD. |
| `Unit/VFXAura.spec` | 11 | Auras montadas con clases reales: presupuesto por rareza × elemento × forma × calidad, 60 % en combate, 80 %/50 % en el Brote, cara libre, reutilización del pool y limpieza al destruir |
| `Unit/CombatVFX.spec` | 9 | Secuencias con reloj falso (fases y duraciones), saltar, sacudida ≤ 0,3 studs, movimiento reducido |
| `Unit/CreatureAnimation.spec` | 14 | Máquina de estados por velocidad con histéresis, personalidad de los iniciales, animador sobre Parts y sobre `Bone.Transform` |
| `Unit/FollowSteering.spec` | 8 | Acompañante a 4–6 studs, sin oscilación, no atraviesa al jugador, teletransporte solo a > 60 studs, rodea un obstáculo |
| `Unit/Audio.spec` | 4 | Catálogo de señales con la convención de ids, todas sin `assetId` (no se inventan) y `SoundController` mudo sin audio |
| `Unit/BiomeArt.spec` | 8 | Cinco biomas, rangos de luz y atmósfera, saturación de pigmentos ≤ 70 %, terreno compartido coherente con `Config/Ambience` |

## 3. Activos 3D (medidos)

Ver `CREATURE_3D_ASSETS.md` §2:
- **Triángulos LOD0:** Brotes 3 754–3 758 (presupuesto 2 500–4 000) y Tallados 6 104–6 108 (4 000–6 500).
- **Huesos:** de 8 a 19 (máximo 18 en Brote y 30 en Tallado).
- **Escala:** ×1,57 (Ascuacho), ×1,81 (Xolossus) y ×1,89 (Mitlaxis).
- **Revisión visual:** hojas de giro, cabezas, seis expresiones por forma, siluetas a 64 px, prueba del esqueleto y escala con un avatar de 5 studs, en `docs/phase3/creatures/`.

## 4. Vista previa web (navegador)

| Recorrido | Resultado |
|---|---|
| Carga con los seis GLB embebidos (4,7 MB) | ✅ < 1 s en escritorio |
| Eclosión, acompañante en el mundo y Álbum con los modelos 3D (prueba de humo, escritorio) | ✅ 0 errores |
| Recorrido completo de la Fase 2 en móvil con los modelos 3D: tutorial, cofre, huevo, eclosión, encargos, Acto I, Copalia en fase 2, decoración, Tallado con ceremonia, estaciones, recarga, migración de un guardado web v1 a v3 | ✅ 48/48, 0 errores de consola |
| Río de la vista previa | ❗ Fallo encontrado y corregido: el agua no se veía desde arriba porque la cinta tenía las caras hacia abajo. Ya estaba así en la Fase 2. Comprobado con capturas tras el arreglo. |

## 5. Errores encontrados y corregidos en la Fase 3

| Error | Causa | Arreglo | Prueba |
|---|---|---|---|
| Escalones en la superficie de las esculturas (cuello) | El atajo de la esfera envolvente no cubría el mayor radio de mezcla de las piezas posteriores | El margen incluye el mayor `k` de la criatura | Comparación de campos (< 0,001 studs) |
| Malla vista «del revés» | Orientación de las caras del marching cubes | Se orienta automáticamente según el gradiente del campo | Renders |
| Colores lavados en la vista rápida | Color por vértice en sRGB, pero glTF espera lineal | Conversión sRGB → lineal | Renders |
| Encuadre roto de los GLB con piel | La caja se medía con los huesos sin actualizar | `updateMatrixWorld` + `skeleton.update()` antes de medir | Renders |
| Agua invisible en la vista previa web | Cinta con las caras hacia abajo | Orden de los vértices invertido | Capturas del río |
| `Model:PivotTo` no existe en el arnés | Limitación de `@lune/roblox` | Desfases respecto a la pieza primaria (también válido en Roblox) | `MeshIntegration.spec` |
| La regla ×1,4–×1,7 fallaba en criaturas largas | Medida por la dimensión mayor | Media geométrica de la caja (D-034) | `CreatureAssets.spec` |

## 6. No ejecutado o bloqueado

- **Roblox Studio** (no hay Studio ni MCP): importación de los GLB, `SurfaceAppearance`, emisivo (D-036), luz `Future` real, terreno y agua reales, `ProximityPrompt`, red, Team Test con varios jugadores. La lista completa es `tests/Playtest/STUDIO_PLAYTEST.md` F3-1 … F3-10 (y F2-1 … F2-20).
- **Rendimiento real:** no hay medidas de fps, memoria ni llamadas de dibujo. La prueba de la Biblia (8 monstruos con aura a 30 fps en el teléfono base) sigue pendiente. Presupuestos y procedimiento en `PERFORMANCE_BUDGET.md`.
- **`WorldController` y `BattleController` completos:** en Lune solo se prueban sus piezas puras y la carga. El seguimiento real en el valle (rampas, puentes, varios jugadores) y el combate completo con el servidor no se han visto funcionar.
- **Texturas de partículas del motor** (`rbxasset://textures/particles/*`): no se ha comprobado que carguen en un cliente publicado.
- **Audio:** no hay ningún archivo. Las señales están definidas y el controlador no suena.
- **Gemini, Meshy y Blender:** no disponibles. Los modelos se hicieron con `tools/sculpt` (D-039).
- **Analizador `luau-analyze`:** sigue sin compilar aquí (R2).
