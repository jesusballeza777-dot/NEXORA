# NEXORA · Presupuesto de rendimiento

**Estado:** documento hijo de `ART_BIBLE_GENESIS.md` §9.
- **Lo que viene de otra fuente:** los presupuestos por activo son de la Biblia (p. 120). Los topes del mundo y de los efectos son los que **ya comprueban las pruebas** (`World.spec`, `Config/VFX`).
- **Lo demás es PROPUESTA** y es un objetivo que hay que medir.
- **La verdad, primero (§8):** no hay ninguna medición en un dispositivo. Solo hay conteos del sandbox de Lune (`tools/roblox-preview`) y medidas de los modelos v01.

**Objetivo de la Biblia** (p. 120): **8 monstruos con aura en pantalla a 30 fps en el teléfono base** antes de aprobar un Legendario. Se mide; no se supone (Genesis §9).

---

## 1. Niveles de dispositivo

| Nivel | Referencia (propuesta) | Objetivo | Mínimo | Calidad de VFX inicial |
|---|---|---|---|---|
| **Teléfono base** | Teléfono de gama baja de hace 4–5 años, 3 GB de RAM | **30 fps** sostenidos | Percentil 1 de fotogramas ≥ 25 fps; ningún tirón > 100 ms | `Low` |
| **Teléfono medio** | Gama media de hace 2–3 años, 4–6 GB | 60 fps | 45 fps | `Medium` (por defecto en `Config/VFX`) |
| **PC** | Gráfica integrada reciente, 1080p | 60 fps | 50 fps | `High` |

- Roblox limita a 60 fps por defecto (verificar si el jugador puede subirlo). Ningún presupuesto cuenta con pasar de 60.
- **Memoria del cliente** (propuesta, `Developer Console` → Memory): ≤ 1,2 GB en el teléfono base y ≤ 1,6 GB en el medio. Por encima, los móviles modestos cierran la app.
- **Calidad inicial de VFX:** se lee de `UserSettings().GameSettings.SavedQualityLevel` (1–3 → `Low`, 4–7 → `Medium`, 8–10 → `High`; `VFX_SYSTEM.md` §7, verificar en Studio).

---

## 2. Presupuestos por escena

| Escena | Partes | Terreno | Luces | Emisores | Partículas/s | Triángulos de criaturas en pantalla | Memoria de texturas | `SurfaceAppearance` distintas |
|---|---|---|---|---|---|---|---|---|
| **Valle entero** (el lugar) | < 4 000 (`World.spec`) | Suelo de 840 × 840; 533 rellenos al arrancar | ≤ 24, rango ≤ 12, sin sombras (`World.spec`); ≤ 6 a menos de 60 studs | ≤ 10, ≤ 20/s cada uno (`World.spec`) | ≤ 60 de ambiente | ≤ 52 000 (8 Tallados Común–Épico × 6 500) | ≤ 150 MB | ≤ 16 |
| **Muestra de bioma** (120 × 120) | ≤ 500 (`BiomeArt.sample`: 320–450) | 24–34 rellenos | ≤ 6 | ≤ 4 | ≤ 60 | Igual que el Valle | ≤ 150 MB | ≤ 16 |
| **Combate** (1–3 por lado, D-022) | La escena del lugar + efectos | — | + ≤ 8 de efectos (pool) | Pool: hasta 160 `ParticleEmitter` (`VFX_SYSTEM.md` §7) | Aura al 60 % (`Config/VFX.Budget.battleIntensity`) | ≤ 39 000 (6 × 6 500) | ≤ 150 MB | ≤ 12 |
| **Jefe** | Igual que combate | — | Igual + luz de lectura por combatiente (`LIGHTING_DIRECTION.md` §7.2) | Ser Sagrado: 3 emisores (Biblia p. 120) | ≤ 300 | ≤ 47 000 (Ser Sagrado ≤ 14 000 + hasta 5 monstruos × 6 500: 3 del jugador y 2 aliados del jefe) | ≤ 150 MB (una 2048² se bajaría a 1024²; contradicción 16) | ≤ 8 |
| **Prueba de los 8 monstruos** (santuario o lote) | La del Valle | — | Igual que el Valle | 8 × 3 (peor caso: Legendario) | ≤ 480 (8 × 3 × 20) | ≤ 72 000 (8 × 9 000) | ≤ 150 MB | ≤ 8 |
| **Álbum** (`ViewportFrame`) | — | — | Sin luces ni partículas (no se dibujan en un `ViewportFrame`) | — | — | Retratos visibles; ≤ 2 nuevos por fotograma (Fase 2) | Igual que la escena | Las del modelo |

**Más límites que ya están en el código** (`Config/VFX`, `VFX_SYSTEM.md` §7):
- **Efectos vivos:** ≤ 64; ≤ 48 actualizados por fotograma.
- **Efectos a la vez por calidad:** `Low` 10, `Medium` 20, `High` 32.
- **Pool por clase:** `Highlight` ≤ 12 (Roblox dibuja como mucho 31), `Beam` ≤ 96, `Trail` ≤ 24 y `Sound` ≤ 24.
- **Vida ambiental:** 520 piezas movidas por fotograma, con un solo `BulkMoveTo` (`WORLD_BUILDING.md` §8).
- **Voces de sonido:** ≤ 16 (`SoundController.maxVoices`; `AUDIO_DIRECTION.md` §7.5).

**Memoria de texturas (estimación que se tiene que medir):**
- **Mapa 1024² con mipmaps:** ~5,3 MB sin comprimir y ~1–1,5 MB comprimido en la GPU.
- **`SurfaceAppearance` con 4 mapas:** ~4–6 MB.
- **Total estimado:** 16 formas de criatura (~64–96 MB) más las 19 variantes de terreno de `MATERIAL_LIBRARY.md` §5 (~57–85 MB con 3 mapas de 1024²) suman ~120–180 MB, así que **pueden pasar del techo de 150 MB**.
- **En el teléfono base,** las variantes de terreno van a 512² (~15–21 MB; propuesta P-4).

---

## 3. Presupuestos por activo

**Biblia p. 120**, con lo medido en los modelos v01 (`CREATURE_3D_ASSETS.md` §2; `Proposal`, sin importar en Roblox):

| Categoría | Triángulos (Biblia) | Textura | Huesos | Emisores de aura | v01 medido (LOD0 / LOD1 · huesos) |
|---|---|---|---|---|---|
| Brote | 2 500–4 000 | 1024² | ≤ 18 | 0–1 (Raro+) | Kuachi 3 757 / 1 687 · 12 · Xolumi 3 758 / 1 692 · 9 · Teselo 3 754 / 1 688 · 8 |
| Tallado Común–Épico | 4 000–6 500 | 1024² | ≤ 30 | 0–2 | Ascuacho 6 108 / 2 748 · 19 · Xolossus 6 104 / 2 744 · 14 · Mitlaxis 6 108 / 4 028 · 12 |
| Tallado Legendario/Único | 6 500–9 000 | 1024² (2048² cinemática) | ≤ 40 | 2–3 | — |
| Ser Sagrado (jefe) | 9 000–14 000 | 2048² | ≤ 50 | 3 | — |
| Huevo | 600–1 200 | 512² | 0–3 | 0–1 | — |
| Cofre | 1 000–2 000 | 512² | 1 (tapa) | 0–1 | — |

**Mundo** (propuesta; hoy todo son Parts nativas):

| Activo | Tope |
|---|---|
| Prop pequeño (cántaro, farol, canasta) | ≤ 500 triángulos o ≤ 6 Parts · textura 256²–512² |
| Puesto o casa | ≤ 4 000 triángulos o ≤ 60 Parts |
| Estación de la Torre | ≤ 8 000 triángulos o ≤ 120 Parts (hoy 427 Parts para las 7 estaciones, el basamento y las puertas) |
| Landmark de bioma | ≤ 20 000 triángulos o ≤ 150 Parts (`BIOME_ART_BIBLE.md`, muestras: 90–140) |
| Árbol de plantilla | ≤ 1 500 triángulos o ≤ 15 Parts; se clona |
| Gran Nexo | ≤ 30 000 triángulos o ≤ 300 Parts (hoy 260) |

**Reglas de la Biblia que acompañan a los activos:**
- ≤ 20 partículas/s por emisor (p. 26);
- aura al 60 % en combate;
- Brote al 80 % de tamaño y con la mitad de partículas;
- aura = `ParticleEmitter` + `Beam` + `Highlight`, nunca geometría extra (p. 120).

---

## 4. Distancias de LOD

| Distancia a la cámara | Criaturas (Genesis §9; `Config/VFX.LOD`) | Mundo | Sonido |
|---|---|---|---|
| 0–60 | Malla LOD0, aura completa, animación completa | Luces encendidas | Voces de criatura (alcance 60) |
| 60–140 | Malla LOD1, sin partículas ni luces, animación a la mitad (`reducedAnimationRate = 0.5`) | Solo `Neon`, sin `PointLight` | Combate hasta 90; capas de ambiente hasta 120 |
| > 140 | Oculta; el acompañante solo avanza su seguimiento 4 veces por segundo | Siluetas y bruma | Solo `AMB_*_Base` |

- **Histéresis:** 6 studs (`Config/VFX.LOD.hysteresis`).
- **Vida ambiental** (`WORLD_BUILDING.md` §8): cada tipo tiene su propio LOD.
  - Faroles y banderas: 60 / 140.
  - Aves: 120 / 320.
  - Peces: 60 / 140.
  - Mariposas: 50 / 110.
  - Corazón: 90 / 220.
  - Gabinete: 120 / 260.
- **Mallas importadas:** `RenderFidelity = Automatic` (`PRODUCTION_SPECS.md` §9.3), más el cambio LOD0 → LOD1 a 60 studs hecho en el cliente.
  - El LOD1 de Mitlaxis (4 028 triángulos) se queda alto por los anillos: si el perfilado lo pide, se quitan las marcas del astrolabio (`CREATURE_3D_ASSETS.md` §2).

---

## 5. Streaming

- **Hoy:** `Workspace.StreamingEnabled = false` (D-019, `default.project.json`). El Valle es un solo lugar y todo se carga al entrar.
  - Todos los prompts pasan por un único `ProximityPromptService.PromptTriggered`, así que reactivar el streaming no los rompe.
- **Cuándo cambiar:** cuando lleguen los biomas, o antes si la memoria del teléfono base pasa de 1,2 GB con el Valle solo (propuesta P-2).

| Propiedad | Propuesta (verificar nombres y valores por defecto) |
|---|---|
| `Workspace.StreamingEnabled` | `true` |
| `StreamingMinRadius` | 96 (el LOD de criaturas llega a 140 y las luces a 60) |
| `StreamingTargetRadius` | 512 en móvil |
| `StreamOutBehavior` | `Opportunistic` |
| `StreamingIntegrityMode` | `MinimumRadiusPause`: el jugador espera antes que caer en un hueco |

**`Model.ModelStreamingMode`:**

| Modo | Para qué |
|---|---|
| `Atomic` | Estaciones, lotes y el Gabinete: el prompt llega con sus piezas |
| `Persistent` | El Gran Nexo, el landmark que se ve desde todo el valle |
| `PersistentPerPlayer` | El lote del propio jugador |

- `Model.LevelOfDetail = StreamingMesh` para las lomas y los landmarks lejanos (verificar).
- **Con un lugar por bioma** (`MATERIAL_LIBRARY.md`, propuesta M-2), cada lugar tiene su propio streaming y la memoria del teléfono solo carga un bioma.
- **Criaturas:** nunca se cargan las 50 especies para mostrar tres (Biblia §Rendimiento).
  - Los modelos importados viven en `ReplicatedStorage.CreatureModels` (`MeshCreature`).
  - Con más de ~16 especies con arte, pasan a cargarse bajo demanda (`PRODUCTION_SPECS.md` §9.4).

---

## 6. Calidad adaptativa

- **Hoy:** `Config/VFX.Quality` aplica los niveles `Low`, `Medium` y `High` desde la calidad gráfica guardada del jugador, y `GuiService.ReducedMotionEnabled` suaviza los destellos.
- **La vista previa web** ya hace algo parecido: si no sostiene ~28 fps, apaga el posproceso (`tools/web-preview/src/game.js`).
- **Propuesta P-3:** un monitor de fps en el cliente que **solo baja o sube el arte, nunca el juego**.
  - **Medida:** media del tiempo de fotograma en ventanas de 5 s.
  - **Bajar un nivel:** si la media queda por debajo de 27 fps durante 5 s.
  - **Subir un nivel:** si pasa de 50 fps durante 20 s, sin superar el nivel inicial.
  - Como mucho un cambio cada 20 s.

| Nivel | VFX | Vida ambiental | Mundo | Criaturas |
|---|---|---|---|---|
| Alto | `High` | 520 piezas por fotograma | Luces hasta 60 studs; todos los emisores de ambiente | LOD por defecto |
| Medio | `Medium` | 520 | Luces hasta 60 | LOD por defecto |
| Bajo | `Low` (sin luces, haces ni estelas) | 260 | Luces hasta 40; emisores de ambiente a la mitad; sin `SunRays` | Animación a la mitad desde 30 studs |

**Lo que nunca cambia:** prompts, interfaz, cifras del combate, contorno de las criaturas y la lectura del jefe (`LIGHTING_DIRECTION.md` §7.2).

---

## 7. Procedimiento de medición en Studio

1. **Preparar.** `rojo build` y `rojo serve` con el plugin de Rojo, y la lista de `tests/Playtest/STUDIO_PLAYTEST.md`.
   - En Studio, calidad gráfica al mínimo (ajustes de renderizado de Studio, verificar la ruta) para la primera pasada.
2. **Emulación de dispositivo** (Test → Device). Comprueba resolución, zona segura, tamaños táctiles (≥ 48 px) y texto (≥ 14 px).
   - **No emula el rendimiento:** una cifra de fps tomada en el emulador no vale como medida del teléfono.
3. **`MicroProfiler`** (verificar el atajo: Ctrl+F6 en el cliente, Ctrl+Alt+F6 en Studio):
   - capturar 5 s en reposo, 5 s caminando por la plaza y 5 s en combate;
   - mirar el tiempo de render, el de scripts (el `Heartbeat` de `AmbientLifeController` y el paso de `VFXRuntime`) y los picos.
4. **`Developer Console`** (F9):
   - *Memory*: total, texturas, mallas, partículas, sonido y vóxeles de terreno;
   - *Scripts*: actividad por script;
   - *Network*: replicación.
   - Las estadísticas en pantalla (Shift+F1 a F5, verificar) dan draw calls y triángulos.
5. **En un dispositivo real.** Con el teléfono base y la app de Roblox, en una sesión de prueba de Studio o en un lugar de pruebas privado.
   - **Publicarlo requiere la autorización del usuario** (CLAUDE.md).
   - Se anotan el modelo, el sistema, la versión de Roblox, la calidad gráfica y la fecha.
6. **Prueba de los 8 monstruos** (Biblia p. 120):
   - **Montaje:** 8 Tallados en un lote, con aura completa del peor caso (Legendario/Único: 2–3 emisores a 20/s), la vida ambiental encendida y la cámara a la distancia por defecto.
     - Hace falta un comando de desarrollo solo en Studio para crearlos: propuesta P-5, que pasaría por `RemoteGateway` con `devOnly`.
   - **Pasa si,** durante 60 s, la media es ≥ 30 fps, el tiempo de fotograma del percentil 99 es ≤ 40 ms y no hay tirones de más de 100 ms.
   - **Memoria:** crece menos del 5 % en 5 min.
   - **Repetir en combate:** 6 monstruos al 60 % de aura y un Golpe Nexo.
7. **Terreno.** El tiempo del servidor en construir los 533 rellenos al arrancar (marca de tiempo antes y después en `TerrainBuilder`) y la memoria de vóxeles.

---

## 8. Medido hasta ahora (sin dispositivo)

**No hay ninguna medición de fps, memoria, draw calls ni tiempo de carga** en Studio ni en un dispositivo. Este entorno no tiene Roblox Studio. Lo que sigue son **conteos** del código real en el sandbox de Lune y **medidas de archivos**.

**Salida de `lune run tools/roblox-preview/build`** (24 nov 2026, tras fusionar la rama principal):
```
Blockouts de Roblox: 39 criaturas, mundo con 3216 partes y 533 rellenos de terreno → build/roblox-preview/
```

| Qué | Medido | Tope | Fuente |
|---|---|---|---|
| Partes del mundo | 3 240 (3 216 visibles) | < 4 000 | Sandbox; `WORLD_BUILDING.md` §9 |
| Rellenos de terreno | 533 (160 `FillBall`, 333 `FillCylinder`, 40 `FillBlock`) | — | `roblox-preview`; `WORLD_BUILDING.md` §9 |
| `PointLight` | 19, rango 8–12, ninguna con sombras | ≤ 24, rango ≤ 12 | Sandbox |
| `ParticleEmitter` del mundo | 7; 42 partículas/s en total, como mucho 12/s cada uno | ≤ 10, ≤ 20/s | Sandbox |
| Piezas `Neon` | 60, la más gruesa de 1,40 studs | ≤ 1,5 | Sandbox |
| `ProximityPrompt` | 44 | — | Sandbox |
| Variantes de criatura (blockout) | 39 (13 especies × Brote, Opaco y Tallado) | — | `roblox-preview` |
| Piezas por forma (blockout) | Brote 18–40 (media 23,9) · Tallado 14–38 (media 21,0) | — | Sandbox |
| Modelos 3D v01 | Triángulos de §3; texturas 1024² (LOD0) y 512² (LOD1); 3,9–6,1 MB en disco; versión web 406–660 KB | Biblia p. 120 ✅ | `CREATURE_3D_ASSETS.md` §2 (sin importar en Roblox) |
| fps, memoria, draw calls, tiempo de terreno | **No medido** | §1–§2 | Requiere Studio y dispositivo |

**Cómo se contaron** las luces, los emisores, el `Neon`, los prompts y las piezas: con un script de un solo uso que no está en el repositorio (propuesta P-1). Recorre lo que construyen `ValleBuilder` y `CreatureBuilder` en `tests/lib/RobloxSandbox`:
```lua
local box = RobloxSandbox.new()
local built = box.load("ServerScriptService.Server.World.ValleBuilder").build()
for _, d in ipairs(built.root:GetDescendants()) do
	-- BasePart, Light (Range, Shadows), ParticleEmitter (Rate), ProximityPrompt, Material == Neon
end
```

---

## 9. Decisiones propuestas

No están registradas en `DESIGN_DECISIONS.md` (este equipo no puede editarlo).

| # | Propuesta | Motivo |
|---|---|---|
| P-1 | `tools/roblox-preview/build` imprime también las luces, los emisores, las partículas/s, el `Neon` y las piezas por criatura | Que la tabla de §8 salga de una herramienta del repositorio y no de un script suelto |
| P-2 | Activar el streaming (§5) cuando lleguen los biomas, o antes si la memoria del teléfono base pasa de 1,2 GB | D-019 pide revisarlo «cuando el mundo crezca»: el Valle ya pasó de 835 a 3 240 partes |
| P-3 | Calidad adaptativa por fps que solo toca el arte (§6) | El teléfono base no tiene margen; el juego no debe cambiar con la calidad |
| P-4 | Variantes de terreno a 512² en el teléfono base y techo de 150 MB de texturas | 19 variantes y 16 formas de criatura llenan el presupuesto a 1024² |
| P-5 | Un comando de desarrollo, solo en Studio, que crea 8 Tallados con aura para la prueba de la Biblia | Sin él la prueba no se puede repetir igual |
| P-6 | Objetivos por nivel de dispositivo (§1) y memoria ≤ 1,2 / 1,6 GB | La Biblia fija 30 fps en el teléfono base, pero no los otros niveles ni la memoria |
