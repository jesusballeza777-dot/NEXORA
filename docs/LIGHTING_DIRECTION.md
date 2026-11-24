# NEXORA · Dirección de luz

**Estado:** documento hijo de `ART_BIBLE_GENESIS.md` §7. Lo desarrolla y no lo contradice.
- **Lo que existe:** la tarde dorada del Valle, en `Config/Ambience.luau`. La aplica `Server/World/TerrainBuilder` y la describe `WORLD_BUILDING.md` §3.
- **Lo que es PROPUESTA:** el resto de este documento:
  - los preajustes de crepúsculo y noche (D-035: el juego mantiene la tarde por defecto);
  - los preajustes de los otros cuatro biomas;
  - los modificadores y las transiciones;
  - cuatro valores nuevos para la tarde del Valle (§9).

**Datos:** `Config/BiomeArt.luau` (`presets`, `Transitions` y `Modifiers`). Las tablas de §4 se generaron a partir de ese archivo: si cambian los datos, se regeneran. `tests/Unit/BiomeArt.spec.luau` valida los rangos.

---

## 1. Principios (Genesis §7, con números)

| Regla | Valor | Dónde se comprueba |
|---|---|---|
| Una dirección dominante por escena | Sol de tarde a ~30° de altura en el Valle | §3 |
| Profundidad con bruma del color del bioma | `Atmosphere.Density` 0,30–0,38 | `BiomeArt.spec` |
| Nada de niebla que oculte objetivos a menos de 120 studs | `Atmosphere.Offset` ≥ 0,05; prueba visual a 120 studs (§8) | Studio |
| Bloom ligero | `Intensity` ≤ 0,6 y `Threshold` ≥ 0,9 | `BiomeArt.spec` |
| Corrección de color con mesura | `Contrast` +0,05…+0,10; `Saturation` entre −0,1 y +0,1 | `BiomeArt.spec` |
| `SunRays` sutiles | `Intensity` ≤ 0,15 | `BiomeArt.spec` |
| Sin `DepthOfField` en juego | Solo en cinemáticas, con desenfoque mínimo (§7.3) | Revisión de código |
| Luces cálidas, sombras frías y nunca negras | `ColorShift_Top` cálido; `OutdoorAmbient` y `ColorShift_Bottom` fríos; ninguna zona de juego por debajo del 10 % de valor (§8) | Prueba en grises |
| Emisivos con presupuesto | `PointLight` con rango ≤ 12 y sin sombras; apagadas más allá de 60 studs | `World.spec` (rango ≤ 12, ≤ 24 luces) |

---

## 2. Cómo se aplica en Roblox

### 2.1. Quién manda en cada propiedad
- **Servidor:** fija la luz base del lugar al construir el mundo.
  - `TerrainBuilder` aplica hoy `Config/Ambience`.
  - Pone `Lighting.Technology = Future` dentro de un `pcall`, porque esa propiedad puede no admitir escritura por script (verificar).
- **Cliente:** todo lo que cambia durante el juego (bioma, momento, combate, jefe, ceremonia) lo hace el cliente **en local**. `Lighting` y sus efectos no se replican desde el cliente.
- **Un solo dueño (propuesta L-5):** un controlador de cliente `LightingDirector` aplica el preajuste más los modificadores y es el único que interpola.
  - Hoy hay tres escritores sueltos: `BattleController.dimLights` (crea `NexoBattleDim`), `Ceremony` (sube el bloom +1,5) y `EvolutionVFXController` (destello del bloom).
  - Si dos interpolan la misma propiedad, gana el último y la otra se queda a medias.

### 2.2. `Technology`
- **`Future` en todos los biomas.** Da las luces locales con brillo especular, que el copal, el cobre y la cerámica necesitan.
- **Propuesta L-6:** fijarla en el lugar, en `default.project.json`, con `"Lighting": { "$properties": { "Technology": "Future" } }`, en vez de un `pcall` en tiempo de ejecución.
- En dispositivos modestos Roblox baja la calidad de iluminación por sí mismo (verificar). Por eso ninguna lectura de juego puede depender de una sombra.

### 2.3. Cielo (`Sky`)
- **Hoy:** el cielo por defecto. No hay skybox propio porque no existe ninguna textura subida, y no se inventa ningún id.
- **Sin texturas**, `Sky` ya permite:
  - `StarCount`: 3 000 en el Valle de noche y 5 000 en el Velo (verificar el máximo);
  - `MoonAngularSize` (Velo 15) y `SunAngularSize` (Cumbre 25, sol grande del atardecer);
  - `CelestialBodiesShown = true`.
- **Pendiente de producción:** skybox de nubes del Velo y de la tormenta de la Meseta (`docs/art`, sin ids).

---

## 3. Altura del sol

Cálculo aproximado (equinoccio): `altura ≈ asin(cos(latitud) · cos(15° · (ClockTime − 12)))`. Roblox puede aplicar otra fecha, así que **se verifica en Studio** de dos formas:
- en la barra de comandos: `print(math.deg(math.asin(game.Lighting:GetSunDirection().Y)))`;
- con un poste de 5 studs, midiendo su sombra.

| Preajuste | `ClockTime` | Latitud | Altura aprox. | Sombra de un poste de 5 studs |
|---|---|---|---|---|
| Valle · Tarde (Ambience) | 15,9 | 23 | 28,7° | 9,1 studs |
| Valle · Crepúsculo | 17,6 | 23 | 5,5° | 52 |
| Marea · Tarde | 14,6 | 18 | 47,7° | 4,6 (luz que entra en el agua) |
| Cumbre · Tarde | 17,2 | 20 | 11,3° | 25 (atardecer naranja) |
| Meseta · Tarde | 15,2 | 30 | 35,4° | 7,0 (bajo nubes: sombra difusa) |
| Crepúsculos (Marea, Cumbre, Meseta) | 17,6 | 18–30 | 5–6° | 50–55 |
| Velo · Hora azul | 18,4 | 35 | −4,9° | El sol ya se puso |

La sombra del crepúsculo mide más de 50 studs: es el momento de los faroles, no el de leer el terreno por las sombras.

---

## 4. Preajustes por bioma y momento

Los colores van en RGB 0–255. `Technology = Future` en todos.
- **Tarde del Valle:** son los valores de `Config/Ambience`, salvo los marcados en §9 (propuestas L-1 a L-3).
- **Lo demás es PROPUESTA.**

### 4.1. Valle Copal
| Propiedad | Tarde · Tarde dorada (por defecto, Config/Ambience) | Crepúsculo · Crepúsculo: faroles encendidos | Noche · Noche de luna: el copal guía |
|---|---|---|---|
| `Lighting.Brightness` | 2,5 | 1,8 | 1,2 |
| `Lighting.ClockTime` | 15,9 | 17,6 | 22 |
| `Lighting.GeographicLatitude` | 23 | 23 | 23 |
| `Lighting.Ambient` | 62, 70, 74 | 56, 52, 64 | 42, 46, 62 |
| `Lighting.OutdoorAmbient` | 128, 134, 132 | 112, 108, 132 | 82, 96, 124 |
| `Lighting.ColorShift_Top` | 236, 200, 150 | 255, 160, 104 | 150, 170, 210 |
| `Lighting.ColorShift_Bottom` | 50, 80, 82 | 56, 64, 100 | 30, 40, 64 |
| `Lighting.EnvironmentDiffuseScale` | 0,55 | 0,5 | 0,4 |
| `Lighting.EnvironmentSpecularScale` | 0,5 | 0,55 | 0,4 |
| `Lighting.ShadowSoftness` | 0,25 | 0,3 | 0,35 |
| `Lighting.ExposureCompensation` | 0 | 0,1 | 0,3 |
| `Atmosphere.Density` | 0,34 | 0,35 | 0,33 |
| `Atmosphere.Offset` | 0,1 | 0,18 | 0,1 |
| `Atmosphere.Color` | 232, 200, 166 | 236, 164, 124 | 92, 110, 150 |
| `Atmosphere.Decay` | 128, 140, 150 | 96, 92, 136 | 40, 48, 80 |
| `Atmosphere.Glare` | 0,3 | 1 | 0 |
| `Atmosphere.Haze` | 1,6 | 2 | 1,2 |
| `Clouds.Cover` | 0,5 | 0,6 | 0,4 |
| `Clouds.Density` | 0,5 | 0,5 | 0,4 |
| `Clouds.Color` | 255, 238, 226 | 244, 196, 178 | 118, 128, 160 |
| `Bloom.Intensity` | 0,5 | 0,6 | 0,6 |
| `Bloom.Size` | 26 | 32 | 34 |
| `Bloom.Threshold` | 1,4 | 1,2 | 1 |
| `SunRays.Intensity` | 0,05 | 0,1 | 0 |
| `SunRays.Spread` | 0,6 | 0,4 | 0,3 |
| `ColorCorrection.Brightness` | 0 | 0 | 0,02 |
| `ColorCorrection.Contrast` | 0,08 | 0,08 | 0,06 |
| `ColorCorrection.Saturation` | 0,04 | 0 | -0,05 |
| `ColorCorrection.TintColor` | 255, 246, 234 | 255, 238, 228 | 226, 232, 255 |

### 4.2. Marea Coralina
| Propiedad | Tarde · Mediodía tardío: la luz entra en el agua | Crepúsculo · Crepúsculo coral | Noche · Noche bioluminiscente |
|---|---|---|---|
| `Lighting.Brightness` | 2,6 | 1,8 | 1,1 |
| `Lighting.ClockTime` | 14,6 | 17,6 | 23 |
| `Lighting.GeographicLatitude` | 18 | 18 | 18 |
| `Lighting.Ambient` | 52, 66, 72 | 56, 50, 70 | 30, 44, 64 |
| `Lighting.OutdoorAmbient` | 112, 140, 150 | 108, 100, 140 | 60, 92, 120 |
| `Lighting.ColorShift_Top` | 240, 226, 200 | 255, 168, 140 | 130, 176, 210 |
| `Lighting.ColorShift_Bottom` | 40, 92, 104 | 48, 56, 110 | 24, 48, 70 |
| `Lighting.EnvironmentDiffuseScale` | 0,6 | 0,5 | 0,4 |
| `Lighting.EnvironmentSpecularScale` | 0,75 | 0,7 | 0,6 |
| `Lighting.ShadowSoftness` | 0,3 | 0,3 | 0,35 |
| `Lighting.ExposureCompensation` | 0 | 0,1 | 0,35 |
| `Atmosphere.Density` | 0,33 | 0,35 | 0,32 |
| `Atmosphere.Offset` | 0,08 | 0,16 | 0,1 |
| `Atmosphere.Color` | 172, 212, 216 | 234, 166, 150 | 60, 104, 140 |
| `Atmosphere.Decay` | 78, 108, 150 | 72, 66, 128 | 22, 38, 70 |
| `Atmosphere.Glare` | 0,5 | 0,9 | 0 |
| `Atmosphere.Haze` | 1,8 | 2 | 1,2 |
| `Clouds.Cover` | 0,42 | 0,55 | 0,35 |
| `Clouds.Density` | 0,45 | 0,5 | 0,4 |
| `Clouds.Color` | 246, 250, 255 | 240, 186, 186 | 90, 120, 150 |
| `Bloom.Intensity` | 0,5 | 0,55 | 0,6 |
| `Bloom.Size` | 30 | 32 | 36 |
| `Bloom.Threshold` | 1,3 | 1,2 | 0,95 |
| `SunRays.Intensity` | 0,1 | 0,1 | 0 |
| `SunRays.Spread` | 0,5 | 0,4 | 0,3 |
| `ColorCorrection.Brightness` | 0 | 0 | 0,02 |
| `ColorCorrection.Contrast` | 0,06 | 0,08 | 0,07 |
| `ColorCorrection.Saturation` | 0,02 | 0 | -0,03 |
| `ColorCorrection.TintColor` | 240, 252, 255 | 255, 240, 240 | 220, 240, 255 |

### 4.3. Cumbre Brasa
| Propiedad | Tarde · Atardecer naranja (Biblia p. 9) | Crepúsculo · Crepúsculo de fragua | Noche · Noche de forjas encendidas |
|---|---|---|---|
| `Lighting.Brightness` | 2,2 | 1,6 | 0,9 |
| `Lighting.ClockTime` | 17,2 | 17,6 | 22,5 |
| `Lighting.GeographicLatitude` | 20 | 20 | 20 |
| `Lighting.Ambient` | 60, 50, 52 | 58, 42, 46 | 44, 34, 38 |
| `Lighting.OutdoorAmbient` | 110, 98, 104 | 100, 80, 92 | 78, 70, 90 |
| `Lighting.ColorShift_Top` | 255, 172, 112 | 255, 130, 80 | 140, 140, 180 |
| `Lighting.ColorShift_Bottom` | 120, 52, 32 | 140, 50, 28 | 130, 48, 24 |
| `Lighting.EnvironmentDiffuseScale` | 0,5 | 0,45 | 0,4 |
| `Lighting.EnvironmentSpecularScale` | 0,65 | 0,6 | 0,6 |
| `Lighting.ShadowSoftness` | 0,25 | 0,3 | 0,35 |
| `Lighting.ExposureCompensation` | 0 | 0,15 | 0,3 |
| `Atmosphere.Density` | 0,37 | 0,38 | 0,35 |
| `Atmosphere.Offset` | 0,15 | 0,2 | 0,12 |
| `Atmosphere.Color` | 222, 144, 96 | 214, 110, 78 | 110, 70, 70 |
| `Atmosphere.Decay` | 92, 62, 64 | 70, 44, 56 | 36, 26, 40 |
| `Atmosphere.Glare` | 0,8 | 1,2 | 0 |
| `Atmosphere.Haze` | 2,4 | 2,6 | 1,6 |
| `Clouds.Cover` | 0,6 | 0,65 | 0,55 |
| `Clouds.Density` | 0,6 | 0,6 | 0,55 |
| `Clouds.Color` | 230, 170, 140 | 210, 120, 100 | 90, 64, 64 |
| `Bloom.Intensity` | 0,55 | 0,6 | 0,6 |
| `Bloom.Size` | 30 | 32 | 36 |
| `Bloom.Threshold` | 1,2 | 1 | 0,95 |
| `SunRays.Intensity` | 0,12 | 0,12 | 0 |
| `SunRays.Spread` | 0,5 | 0,4 | 0,3 |
| `ColorCorrection.Brightness` | 0 | 0 | 0,02 |
| `ColorCorrection.Contrast` | 0,09 | 0,09 | 0,08 |
| `ColorCorrection.Saturation` | 0 | -0,02 | -0,04 |
| `ColorCorrection.TintColor` | 255, 236, 220 | 255, 228, 214 | 240, 226, 230 |

### 4.4. Meseta Fulgor
| Propiedad | Tarde · Tormenta de tarde (perpetua) | Crepúsculo · Claro de tormenta al ponerse el sol | Noche · Noche eléctrica |
|---|---|---|---|
| `Lighting.Brightness` | 1,6 | 1,3 | 0,9 |
| `Lighting.ClockTime` | 15,2 | 17,6 | 23,5 |
| `Lighting.GeographicLatitude` | 30 | 30 | 30 |
| `Lighting.Ambient` | 58, 62, 72 | 54, 52, 70 | 34, 38, 54 |
| `Lighting.OutdoorAmbient` | 122, 128, 142 | 106, 104, 130 | 66, 76, 104 |
| `Lighting.ColorShift_Top` | 210, 214, 226 | 230, 170, 120 | 140, 160, 210 |
| `Lighting.ColorShift_Bottom` | 60, 66, 84 | 56, 60, 96 | 30, 36, 60 |
| `Lighting.EnvironmentDiffuseScale` | 0,7 | 0,6 | 0,45 |
| `Lighting.EnvironmentSpecularScale` | 0,8 | 0,8 | 0,7 |
| `Lighting.ShadowSoftness` | 0,6 | 0,55 | 0,5 |
| `Lighting.ExposureCompensation` | 0,1 | 0,15 | 0,35 |
| `Atmosphere.Density` | 0,36 | 0,37 | 0,34 |
| `Atmosphere.Offset` | 0,05 | 0,1 | 0,06 |
| `Atmosphere.Color` | 150, 160, 176 | 170, 140, 130 | 70, 80, 110 |
| `Atmosphere.Decay` | 68, 76, 100 | 60, 60, 96 | 26, 30, 52 |
| `Atmosphere.Glare` | 0 | 0,4 | 0 |
| `Atmosphere.Haze` | 2 | 2,2 | 1,6 |
| `Clouds.Cover` | 0,88 | 0,85 | 0,85 |
| `Clouds.Density` | 0,8 | 0,8 | 0,75 |
| `Clouds.Color` | 120, 126, 140 | 150, 120, 120 | 64, 70, 92 |
| `Bloom.Intensity` | 0,6 | 0,6 | 0,6 |
| `Bloom.Size` | 24 | 26 | 30 |
| `Bloom.Threshold` | 1,1 | 1 | 0,95 |
| `SunRays.Intensity` | 0 | 0,06 | 0 |
| `SunRays.Spread` | 0,3 | 0,3 | 0,3 |
| `ColorCorrection.Brightness` | 0 | 0 | 0,02 |
| `ColorCorrection.Contrast` | 0,1 | 0,1 | 0,09 |
| `ColorCorrection.Saturation` | -0,05 | -0,04 | -0,05 |
| `ColorCorrection.TintColor` | 236, 242, 255 | 250, 236, 232 | 226, 234, 255 |

### 4.5. Velo Astral
| Propiedad | Tarde · Hora azul | Crepúsculo · Noche de aurora | Noche · Noche profunda (por defecto) |
|---|---|---|---|
| `Lighting.Brightness` | 1,6 | 1,3 | 1,4 |
| `Lighting.ClockTime` | 18,4 | 20,5 | 0 |
| `Lighting.GeographicLatitude` | 35 | 35 | 35 |
| `Lighting.Ambient` | 46, 46, 80 | 40, 46, 76 | 40, 36, 70 |
| `Lighting.OutdoorAmbient` | 92, 96, 146 | 74, 100, 132 | 72, 74, 122 |
| `Lighting.ColorShift_Top` | 180, 190, 240 | 150, 220, 210 | 170, 190, 240 |
| `Lighting.ColorShift_Bottom` | 70, 54, 120 | 70, 50, 120 | 60, 40, 100 |
| `Lighting.EnvironmentDiffuseScale` | 0,5 | 0,5 | 0,5 |
| `Lighting.EnvironmentSpecularScale` | 0,6 | 0,6 | 0,6 |
| `Lighting.ShadowSoftness` | 0,4 | 0,4 | 0,4 |
| `Lighting.ExposureCompensation` | 0,2 | 0,3 | 0,4 |
| `Atmosphere.Density` | 0,31 | 0,31 | 0,3 |
| `Atmosphere.Offset` | 0,2 | 0,22 | 0,25 |
| `Atmosphere.Color` | 110, 112, 180 | 80, 120, 150 | 90, 90, 160 |
| `Atmosphere.Decay` | 40, 36, 90 | 30, 30, 80 | 30, 26, 70 |
| `Atmosphere.Glare` | 0 | 0 | 0 |
| `Atmosphere.Haze` | 1,2 | 1,1 | 1 |
| `Clouds.Cover` | 0,4 | 0,38 | 0,35 |
| `Clouds.Density` | 0,45 | 0,42 | 0,4 |
| `Clouds.Color` | 150, 150, 200 | 110, 130, 170 | 100, 96, 150 |
| `Bloom.Intensity` | 0,55 | 0,6 | 0,6 |
| `Bloom.Size` | 34 | 36 | 36 |
| `Bloom.Threshold` | 1 | 0,95 | 0,95 |
| `SunRays.Intensity` | 0 | 0 | 0 |
| `SunRays.Spread` | 0,3 | 0,3 | 0,3 |
| `ColorCorrection.Brightness` | 0 | 0,02 | 0,02 |
| `ColorCorrection.Contrast` | 0,07 | 0,07 | 0,08 |
| `ColorCorrection.Saturation` | 0 | 0,02 | 0 |
| `ColorCorrection.TintColor` | 232, 232, 255 | 226, 246, 255 | 230, 228, 255 |

### 4.6. Qué significa cada momento en cada bioma

| Bioma | Tarde | Crepúsculo | Noche | Por defecto |
|---|---|---|---|---|
| Valle Copal | Tarde dorada | Faroles encendidos | Luna; el copal guía | Tarde (D-035) |
| Marea Coralina | Luz alta que entra en el agua | Crepúsculo coral | Bioluminiscencia | Tarde |
| Cumbre Brasa | Atardecer naranja (Biblia p. 9) | Crepúsculo de fragua | Forjas encendidas | Tarde |
| Meseta Fulgor | Tormenta de tarde (perpetua, Biblia p. 10) | Claro de tormenta | Noche eléctrica | Tarde |
| Velo Astral | Hora azul | Aurora | Noche profunda (Biblia p. 9) | Noche |

---

## 5. Transiciones (`BiomeArt.Transitions`)

| Cambio | Duración | Curva | Qué se interpola | Qué salta |
|---|---|---|---|---|
| Momento (tarde → crepúsculo → noche) | 8 s | `Sine` `InOut` | Todo lo numérico y `Color3` de `Lighting`, `Atmosphere`, `Clouds`, `Bloom`, `SunRays` y `ColorCorrection` | Nada |
| Bioma (al cruzar su puerta) | 3 s | `Sine` `InOut` | Lo mismo, salvo `ClockTime` | `ClockTime`, colores de terreno, agua, `Sky` y `SoundService.AmbientReverb`: saltan a mitad de la transición, tapados por un descenso de `ColorCorrection.Brightness` −0,06 durante 0,4 s |
| Entrar en combate | 0,8 s (igual que el viaje de cámara de `BattleController`) | `Quad` `Out` | Modificador `Combate` | — |
| Salir del combate | 1,2 s | `Sine` `InOut` | Vuelta al preajuste | — |
| Fase 2 del jefe | 1,2 s (como `dimLights` hoy) | `Sine` `InOut` | Modificador `JefeFase2` | Los faroles se apagan uno a uno en ese tiempo |
| Restauración de un Ser Sagrado | 5 s | `Sine` `InOut` | Del modificador `Opacado` al preajuste | — |

**Reglas:**
- **`ClockTime` siempre avanza.** De 17,6 a 22 se interpola hacia delante. De la noche a la tarde se pasa por la medianoche (22 → 24 ≡ 0 → 15,9), nunca hacia atrás.
- **No se interpolan más de 3 horas de `ClockTime` en menos de 3 s:** el sol barre el cielo y marea.
- **`SetMaterialColor` y el agua no se interpolan** (no son propiedades). Cambian de golpe, detrás del descenso de brillo.
- **Ciclo de día:** si se aprueba (pregunta 27: «Día y noche visual»; D-035), la propuesta es un ciclo de 24 min reales: 14 min de tarde, 3 de crepúsculo, 6 de noche y 1 de amanecer. El amanecer reutiliza el crepúsculo con `ClockTime` 6,4. Hoy queda **desactivado**.

---

## 6. Emisivos y luces locales

| Regla | Valor |
|---|---|
| Grosor máximo del `Neon` | 1,5 studs (Genesis §5). Hoy: 60 piezas, la más gruesa de 1,40 |
| `PointLight` | Rango ≤ 12, `Brightness` 0,5–1,5, `Shadows = false`. Hoy: 19 luces de rango 8–12, ninguna con sombra |
| `SpotLight` / `SurfaceLight` | Solo para bocas de horno, portales y túneles de luz: rango ≤ 12, `Angle` ≤ 70, sin sombras |
| Luces por escena | ≤ 24 en el lugar (`World.spec`); ≤ 6 a menos de 60 studs de la cámara (propuesta) |
| Distancia | Encendidas hasta 60 studs; de 60 a 140 solo el `Neon`; más allá, nada (Genesis §9). Histéresis de 6 studs, como `Config/VFX.LOD` |
| Separación | Dos luces a menos de 8 studs se funden en una |
| Color | Solo colores de tipo `Emisivo` de la paleta del bioma (copal `#FFC460` en el Valle). Blanco puro solo en el destello del rayo |
| Noche | La misma `Brightness`; la noche se compensa con `ExposureCompensation` (+0,3 a +0,4), no subiendo cada luz |
| Criaturas | Ninguna luz en el aura de un Común. El pool de VFX limita las luces de efectos a 8, con rango ≤ 12 y sin sombras, y en calidad Low no crea luces (`Config/VFX.Quality`) |

---

## 7. Combate, jefe y cinemáticas

### 7.1. Combate (`Modifiers.Combate`)
- **Ajustes:** `Contrast` +0,02, `Saturation` −0,02 y bloom ×0,8 sobre el preajuste del lugar. El aura baja al 60 % (Biblia p. 26; `Config/VFX.Budget.battleIntensity`).
- **Lo que no cambia:** ni la hora ni la dirección del sol. El jugador reconoce el sitio donde combate.
- **Encuadre:** la cámara de combate (`Config/VFX.Camera.follow`) deja el sol de lado o detrás del jugador para que las caras de los monstruos queden iluminadas. Si el escenario obliga a mirar al sol, `SunRays` baja a 0 durante el combate.

### 7.2. Jefe: fase 2 de Copalia (faroles apagados, −20 % de precisión)
Hay que oscurecer **sin perder la lectura**.

| | Hoy (`BattleController.dimLights`) | Propuesta (`Modifiers.JefeFase2`) |
|---|---|---|
| `ColorCorrection.Brightness` | −0,18 | −0,12 |
| `Saturation` | −0,25 | −0,15 |
| `Contrast` | sin cambio | +0,03 |
| `TintColor` | (170, 180, 230) | (190, 196, 235) |
| Luz de lectura | ninguna | Una `PointLight` por combatiente: `Brightness` 0,8, rango 10, sin sombras. Cálida (`#FFE6C0`) en el bando del jugador, fría (`#C8D0FF`) en el rival |
| Faroles del escenario | sin cambio | Se apagan uno a uno en 1,2 s (el relato de la fase) |
| Al terminar | `Destroy` inmediato del efecto | Vuelta interpolada en 1,2 s |

**Prueba de lectura:** en grises (§8), cada combatiente separado del fondo por ≥ 20 puntos de valor (escala 0–100) durante la fase 2.
- **Otros jefes:** el mismo patrón, con el color de su bioma.
  - Noctelia «teje la noche»: tinte (180, 176, 235).
  - Obsidárion, en la erupción: `ColorShift_Bottom` sube a (160, 60, 30) durante 1 s.
  - Fulgorón usa el modificador `Rayo` en cada rugido.

### 7.3. Cinemáticas (`Modifiers.Cinematica`)
- **Único uso de `DepthOfField`:** `FarIntensity` 0,12, `FocusDistance` 18, `InFocusRadius` 14, `NearIntensity` 0. Se crea al empezar la cinemática y se destruye al terminar o al saltarla.
- **Destellos:**
  - `Ceremony` sube hoy el bloom +1,5 (de 0,5 a 2,0) durante 1,2 s. Como excepción de cinemática es aceptable, pero se propone +0,8 durante 0,9 s (L-7).
  - Con movimiento reducido, `EvolutionVFXController` ya cambia el destello por uno suave sin bloom.
- **Fotosensibilidad:** nunca más de **3 destellos por segundo** (`Modifiers.Rayo.maxFlashesPerSecond = 3`). Un destello dura ≤ 0,1 s.

---

## 8. Prueba en grises (lectura de valores)

Genesis §4.1, regla 2: valores antes que tonos.

1. **Montaje.** En Studio, con el juego en marcha, se añade en `Lighting` un `ColorCorrectionEffect` llamado `QA_Grises` con `Saturation = -1`. Es solo de prueba: no se guarda en el lugar. Con la barra de comandos:
   ```lua
   local g = Instance.new("ColorCorrectionEffect"); g.Name = "QA_Grises"; g.Saturation = -1; g.Parent = game.Lighting
   ```
2. **Capturas.** Una por cada cámara estándar: llegada (spawn), aérea, lote y combate. Para el Valle sirven las vistas de `WORLD_BUILDING.md` §10. Se repite con cada momento (tarde, crepúsculo y noche).
3. **Medida.** Valor medio (L*) de cada plano sobre la captura, con cualquier editor de imagen:

| Plano | Valor objetivo | Si falla |
|---|---|---|
| Primer plano | 15–35 | Más oscuro: oclusión, materiales más oscuros |
| Plano medio (donde se juega) | 40–60 | Ajustar `OutdoorAmbient` o el color del suelo |
| Fondo (bruma) | 65–85 | Subir `Atmosphere.Haze` o aclarar `Atmosphere.Color` |
| Criatura frente al suelo | ≥ 20 puntos de diferencia | Aclarar la cara o el rasgo firma (Genesis §4.1) |
| Cualquier zona de juego de noche | ≥ 10 | Subir `ExposureCompensation` (nunca negro puro) |

4. **Distancia.** Un objetivo de 5 studs a 120 studs de la cámara tiene que distinguirse (Genesis §7). Si no se distingue, sube `Atmosphere.Offset` o baja `Density` dentro de su rango.
5. **Atajo.** Entrecerrar los ojos ante la captura: si el camino y el landmark desaparecen, la escena no se lee.

---

## 9. Comparación con `Config/Ambience.luau` y cambios propuestos

`Ambience` ya cumple casi todo Genesis §7. El equipo de mundo:
- movió la hora a 15,9 (W-5);
- enfrió `Ambient`;
- bajó el bloom a 0,5 con umbral 1,4;
- dejó la saturación en +0,04.

| Propiedad | Hoy (`Ambience`) | Propuesta (`BiomeArt.ValleCopal.presets.Tarde`) | Motivo |
|---|---|---|---|
| `ClockTime` | 15,9 | = | Sol a ~29° (§3) |
| `Brightness` | 2,5 | = | |
| `Ambient` | (62, 70, 74) | = | Ya es jade azulado |
| `OutdoorAmbient` | (138, 128, 120) | **(128, 134, 132)** · L-1 | Al aire libre la sombra la llena `OutdoorAmbient`. Hoy es pardo cálido; Genesis §4.1 (regla 4) pide sombras frías |
| `ColorShift_Top` / `_Bottom` | sin asignar (0, 0, 0) | **(236, 200, 150) / (50, 80, 82)** · L-2 | Cara al sol cálida y contraluz frío; da el contraluz de las hojas (`MATERIAL_LIBRARY.md` §2.12) |
| `ExposureCompensation` | sin asignar (0) | 0 | Se declara para que la noche pueda subirla |
| `Atmosphere.Density` / `Offset` | 0,34 / 0,1 | = | |
| `Atmosphere.Color` | (232, 200, 166) | = | |
| `Atmosphere.Decay` | (150, 120, 130) | **(128, 140, 150)** · L-3 | «Los planos lejanos se aclaran y se enfrían» (Genesis §7); hoy es malva cálido |
| `Glare` / `Haze` | 0,3 / 1,6 | = | |
| `Bloom` | 0,5 · 26 · 1,4 | = | |
| `SunRays` | 0,05 · 0,6 | = | |
| `Grade` (`ColorCorrection`) | sat. +0,04 · contraste +0,08 · tinte (255, 246, 234) | = | |
| `Clouds` | 0,5 · 0,5 · (255, 238, 226) | = | |

**Cómo aplicarlo:** si se aprueban L-1 a L-3, se cambian esos cuatro valores **en `Config/Ambience`**, porque es lo que lee el mundo. `BiomeArt` los toma de ahí.

---

## 10. Errores a evitar

- **Niebla como solución de rendimiento:** `Density` > 0,38 esconde los objetivos y aplana la escena.
- **Noche negra:** se compensa con `ExposureCompensation` y con un `OutdoorAmbient` azul, no subiendo todas las luces.
- **Bloom con umbral bajo (< 0,9):** la piedra clara y el papel picado empiezan a brillar.
- **Saturación global positiva alta** (Fase 1: +0,1): empuja los pigmentos por encima del 70 %.
- **Varios scripts interpolando `Lighting`:** se pisan (§2.1).
- **Sombras como lectura de juego:** en gama baja pueden desaparecer.
- **`SunRays` mirando al sol en combate:** quema la cara del rival.
- **`DepthOfField` en juego:** en un teléfono emborrona los prompts y los objetivos.
- **Destellos rápidos:** más de 3 por segundo es un riesgo de fotosensibilidad.
- **Interpolar `ClockTime` hacia atrás o muchas horas de golpe.**

---

## 11. Decisiones propuestas

No están registradas en `DESIGN_DECISIONS.md` (este equipo no puede editarlo).

| # | Propuesta | Motivo |
|---|---|---|
| L-1 | `Ambience.Lighting.outdoorAmbient` = (128, 134, 132) | Sombras frías al aire libre (Genesis §4.1, regla 4) |
| L-2 | `ColorShift_Top` (236, 200, 150) y `ColorShift_Bottom` (50, 80, 82) en el Valle | Luz cálida y contraluz frío; contraluz de las hojas |
| L-3 | `Ambience.Atmosphere.decay` = (128, 140, 150) | Lo lejano se enfría (Genesis §7) |
| L-4 | Crepúsculo y noche de los cinco biomas como preajustes (`BiomeArt`), sin ciclo activo | Desarrolla D-035 sin decidir la pregunta 27 |
| L-5 | Un único `LightingDirector` en el cliente aplica los preajustes, modificadores y transiciones | Hoy tres scripts tocan `Lighting` por su cuenta |
| L-6 | `Technology = Future` fijada en `default.project.json` | No depender de un `pcall` en tiempo de ejecución |
| L-7 | Fase 2 de Copalia con el modificador `JefeFase2` (§7.2) y el destello de `Ceremony` en +0,8 durante 0,9 s | Oscurecer sin perder la lectura; destellos más suaves |
