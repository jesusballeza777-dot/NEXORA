# NEXORA · Dirección de audio

**Estado:** **no hay ningún audio en el juego.**
- Las 128 señales de `Config/AudioCues.luau` tienen `assetId = nil` y `status = "Pending"`.
- `Client/Audio/SoundController` no reproduce nada hasta que una persona apruebe un audio real y escriba su id (`VFX_SYSTEM.md` §9).
- Todo lo de este documento es **dirección y especificación pendiente de producción**. No se inventan ids de Roblox.

**Fuentes:**
- Biblia p. 9 («cada bioma tiene paleta, **música**, monstruos nativos y un guardián»);
- Biblia p. 26: el Único lleva «firma sonora»;
- Biblia p. 109: guion sonoro de la introducción;
- pregunta 85: «Texto + sonidos», sin voces;
- `ART_BIBLE_GENESIS.md` §8 (movimiento por elemento y tiempos de ataque);
- los dosieres de Kuachi, Xolumi y Teselo (`docs/art/dossiers/`);
- `BIOME_ART_BIBLE.md` (biomas).

**Datos:** los ids, volúmenes, alcances y variaciones de tono de §9 salen de `Config/AudioCues`. El catálogo se generó a partir de ese archivo y cubre sus 128 señales, ni una más ni una menos.

---

## 1. Identidad sonora

> **NEXORA suena a taller:** madera, barro, metal, cristal y tela tocados a mano, con la luz del copal convertida en campanas.

- **Instrumentación de oficios** (inspirada en oficios y sonidos del mundo, nunca copiada):
  - marimba y percusión de madera (talla);
  - ocarinas y vasijas de barro (alfarería);
  - campanas y yunques de cobre y latón (herrería);
  - copas y campanas de cristal (vitral);
  - sonajas de semillas de huaje (Hercuerno);
  - cajas de música y engranes (Artificio);
  - arpa y flauta de carrizo;
  - tela de rebozo como percusión suave.
- **El motivo del Nexo** (propuesta A-1): un motivo de 4 notas en contorno ascendente (salto, paso y vuelta) que nace del guion de la introducción (Biblia p. 109):
  - «sonido de madera y un latido» (la gubia y el corazón);
  - «flauta y percusión suave»;
  - «seis golpes graves» (los Seres Sagrados);
  - «campanas y arpa» (los huevos);
  - «golpe final y tema principal».
  - Cada bioma lo reorquesta. La victoria (`SFX_Combat_Victory`) y los logros (`SFX_UI_Achievement`) lo citan.
- **El Opacamiento suena a «silencio y viento»** (Biblia p. 109, plano 4). En un bioma o una zona opacada:
  - se apagan la fauna y la música;
  - queda solo el viento, con un filtro de paso bajo a 1,2 kHz.
  - Al restaurar, las capas vuelven en orden: viento → agua → fauna → música.
- **Reglas:**
  - **Sin palabras:** «Texto + sonidos» (pregunta 85). Las criaturas vocalizan; el Gabinete «habla por cajones» con sonidos de madera, cada cajón con su timbre.
  - **Feroz, no aterrador** (Biblia p. 21): sin gritos, sin dolor explícito, sin sustos con picos de volumen.
  - **Nadie muere:** la derrota es «descansa»; el Opaco vencido se restaura.
  - **Nada de sonidos de apuesta:** sin tragamonedas ni «casi lo consigues». Un cofre suena igual tenga lo que tenga (hoy su contenido es fijo, D-024).
  - **Pensado para el altavoz del teléfono:** lo que el jugador necesita oír vive entre 300 Hz y 6 kHz. Lo grave (los «golpes graves») lleva armónicos por encima de 150 Hz.

---

## 2. Mezcla

Las seis categorías de `AudioCues` (`Ambient`, `Music`, `Creature`, `Combat`, `UI` y `World`) se convierten en `SoundGroup` (propuesta A-2). Hoy `SoundController` aplica su volumen con `CategoryVolume`, que vale 1 en todas.

| `SoundGroup` | Volumen propuesto | Contenido | Ducking |
|---|---|---|---|
| `Master` | 1 | Padre de todos | — |
| `Music` | 0,6 | `MUS_*` | −6 dB en las ceremonias (eclosión, Tallado) y −4 dB en el Golpe Nexo |
| `Ambient` | 0,7 | `AMB_*` | Baja a 0,35 en 0,8 s al empezar un combate (igual que la cámara) |
| `Combat` | 0,9 | `SFX_<Elemento>_*` y `SFX_Combat_*` | — |
| `Creature` | 0,8 | `SFX_CR_*` | −3 dB durante el combate, salvo el ataque en curso |
| `UI` | 0,7 | `SFX_UI_*` | No se agacha nunca |
| `World` | 0,7 | Interactivos del mundo (ids nuevos en §10) | — |

- **Ajustes del jugador:** deslizadores de Música, Efectos y Ambiente, y un «Silenciar todo» (`SoundController.setCategoryVolume`).
  - Igual que los ajustes de efectos (D-042, VFX-P5), duran solo la sesión.
  - Guardarlos exige un remote en `Contract` y una migración del perfil: es una decisión aparte.
- **Reverberación:** `SoundService.AmbientReverb` por bioma (verificar los nombres de `Enum.ReverbType`). Es global y la cambia el cliente al entrar en el bioma, a mitad de la transición (`LIGHTING_DIRECTION.md` §5).

| Bioma | Reverberación |
|---|---|
| Valle | `Plain`; `StoneCorridor` bajo el basamento de la Torre |
| Marea | `Cave` en el cenote; `UnderWater` si el jugador se sumerge |
| Cumbre | `Mountains` |
| Meseta | `Quarry` |
| Velo | `ConcertHall` |

---

## 3. Por bioma: música y paisaje sonoro

**Música:** cuatro estados por bioma con los ids reales.
- `Explore` (exploración);
- `Battle` (combate);
- `Boss` (jefe);
- `Victory`: victoria y, tras el jefe, **restauración** (el encargo la llama así; el catálogo usa `Victory`).

**Transiciones:**
- **Exploración → combate:** fundido de 0,8 s, con el mismo tempo y tonalidad para que encaje. Si hace falta, `TimePosition` alineada al compás.
- **Combate → victoria:** corte con la pieza de victoria (6–10 s) y vuelta a la exploración.
- **Fase 2 del jefe:** entra una capa nueva.
  - Con Copalia (faroles apagados), la música se queda en percusión y un bordón, con un filtro de paso bajo, para acompañar la oscuridad.

**Paisaje sonoro:** las seis capas del encargo (viento, agua, vegetación, fauna, arquitectura e interactivos) se reparten en las capas reales de `AudioCues.AmbientLayers`.
- `Base` es 2D y suena en todo el bioma.
- Las demás capas son 3D (alcance de 120 studs) y nacen de emisores colocados en el mundo.
- Los interactivos son sonidos de un solo disparo de la categoría `World` (§10).

### 3.1. Valle Copal
- **Música:** marimba, flauta de carrizo, ocarina, arpa, sonajas de huaje y tambor de piel. 92–100 BPM, mayor o mixolidio.
  - `Boss`: Copalia con arpa y raíces (madera grave).
  - `Victory`: los diez faroles encendiéndose como campanas.
- **Capas:**

| Capa del encargo | Id | Contenido y dónde nace |
|---|---|---|
| Viento + vegetación | `AMB_ValleCopal_Base` | Brisa en el pasto y hojas de ahuejote (2D) |
| Agua | `AMB_ValleCopal_Water` | Río (emisores cada ~40 studs del cauce), cascada (más fuerte) y lago |
| Fauna | `AMB_ValleCopal_Fauna` | Aves en las copas y chicharras de tarde; ranas al crepúsculo, en las chinampas |
| Arquitectura + interactivos | `AMB_ValleCopal_Market` | Calle del mercado: comal, telar, cántaros y murmullo sin palabras |

- **Opacado (la Linde):** solo `Base`, filtrada.

### 3.2. Marea Coralina
- **Música:** vasijas de agua percutidas, copas de cristal, arpa y flauta. 70–80 BPM, dórico o lidio. `Boss`: Marejadra, con copas que cambian de nota en la fase 2 (la marea cambia al rival).
- **Capas:** `AMB_MareaCoralina_Base` (brisa y manglar) · `_Waves` (olas en el arrecife; gotas y eco en el cenote: agua y arquitectura) · `_Fauna` (aves marinas, peces que saltan, cangrejos).

### 3.3. Cumbre Brasa
- **Música:** yunques y martillos en ritmo, fuelles, campanas de cobre y latón, tambores de barro, guitarra grave. 104–116 BPM, menor armónico (heroico, no oscuro). `Boss`: Obsidárion, con un martillo en cada tiempo fuerte; en la fase 2 (erupción) entran los fuelles.
- **Capas:** `AMB_CumbreBrasa_Base` (retumbo del volcán con armónicos y hornos: arquitectura) · `_Lava` (canales: burbujeo y crepitar) · `_Wind` (viento caliente con ceniza).

### 3.4. Meseta Fulgor
- **Música:** cajas de música, metalófono, engranes como percusión, cuerdas tensadas y timbales de tormenta. 120–132 BPM, lidio. `Boss`: Fulgorón, con un rugido en cada cambio de frase.
- **Capas:** `AMB_MesetaFulgor_Base` (cables, molinos y talleres) · `_Storm` (trueno lejano, lluvia en ráfagas) · `_Wind` (viento que silba en las estructuras).
- **Sincronía del rayo:** el trueno se dispara 0,3–1,5 s después del destello de `Modifiers.Rayo`, según la distancia.

### 3.5. Velo Astral
- **Música:** campanas de cristal, arpa, coro sin palabras, cuerdas en armónicos y tela. 60–68 BPM con rubato, lidio o pentatónica. `Boss`: Noctelia; en la fase 2 («teje la noche») el coro se queda en una sola nota tejida.
- **Capas:** `AMB_VeloAstral_Base` (fondo etéreo y tela) · `_Wind` (viento entre nubes) · `_Stars` (tintineo de estrellas y faroles cercanos: interactivos).

### 3.6. Torre del Nexo
- **Capas:** `AMB_TorreDelNexo_Base` (madera que cruje y el latido muy bajo del corazón, sincronizado con `AmbientMotion.heart`) · `_Echo` (eco del basamento y campana de la Repisa).
- **Música:** `MUS_TorreDelNexo_*`. El combate final reúne los instrumentos de los cinco biomas.

---

## 4. Criaturas

### 4.1. Los tres iniciales
Personalidad (Genesis §8 y dosieres):
- **Kuachi:** curioso e inquieto.
- **Xolumi:** calmado y anfibio.
- **Teselo:** pesado y estable.

Las descripciones de cada acción están en el catálogo (§9.3). Aquí, cómo se construye cada voz:

| | Kuachi → Ascuacho | Xolumi → Xolossus | Teselo → Mitlaxis |
|---|---|---|---|
| Voz | Nasal y aguda: olfateos, trinos, bufidos | Húmeda y redonda: gorgoteos, arrullos | Grave y lenta: gruñidos, respiración |
| Capa de material | Brasa y barro de horno (la bolsa) | Barro negro (tic cerámico) y agua | Piedra y teselas (clac) |
| Pasos (`Move`) | Acolchados y rápidos; la cola roza | Chapoteo y ondulación | Pisada pesada con micro-temblor |
| `Happy` | Se hace el muerto de broma: golpe blando y saltito | Risa gorgoteante y chorrito | «Pop» al meterse en el caparazón |
| `Special` | Puerta de horno | Ola y cántaro | Muro de adobe |
| `Evolve` | La brasa se vuelve rugido de horno | El barro se agrieta y se sella en oro | Los anillos se alinean en campanas |

**Brote frente a Tallado:**
- **Mismos archivos, distinta forma:** el Tallado reproduce la misma señal con `PlaybackSpeed` 0,8 (−4 semitonos) y suma una capa de cuerpo. Así se conserva «el mismo monstruo» (regla 8).
- **Los ids son de especie:** `SFX_CR_kuachi_*` sirve para Kuachi y para Ascuacho.
- **Si el Tallado necesita su propio archivo:** se propone el sufijo de forma (A-3), no un id nuevo por nombre.

**Tiempos** (Genesis §8 y `Config/VFX.Budget`):
- `Attack` ≤ 1,2 s dentro de una secuencia de ≤ 1,6 s;
- el Golpe Nexo, ≤ 3,5 s;
- `Idle` suena cada 8–14 s, nunca en bucle.

### 4.2. Regla general por familia (Genesis §3.1)

| Familia | Pasos | Registro de voz | Capa propia |
|---|---|---|---|
| Cuadrúpedo ágil | Ligeros y rápidos | Medio-agudo | Pelaje y cola |
| Cuadrúpedo pesado | Golpes con armónicos | Grave | Peso: el suelo vibra |
| Anfibio | Húmedos | Medio, redondo | Agua |
| Reptil acorazado | Pesados, lentos | Grave | Caparazón (piedra o cerámica) |
| Ave | Sin pasos al volar; aleteo | Agudo, trinos | Plumas |
| Insecto | Clics de quitina | Agudo, zumbido corto (nunca en bucle continuo) | Élitros |
| Serpiente | Deslizar de escamas | Siseo | Escamas |
| Flotante | Ninguno | Etéreo, tonal | Tela o aire |
| Bípedo | Pares de pasos | Según su tamaño | Ropa u oficio |
| Objeto vivo | El sonido del objeto (cántaro, juguete de cuerda, farol) | Hecho con el objeto | El oficio que representa |

**Para todas las familias:**
- la capa del elemento se suma en cada ataque;
- variación de tono ±8 % (`AudioCues`);
- 3–4 variantes por señal frecuente (pasos, `Idle`).

---

## 5. Combate

| Momento | Qué suena | Señales |
|---|---|---|
| Preparación (entrada) | Fundido de la música de exploración a la de combate en 0,8 s, con el viaje de cámara; la capa `Ambient` baja a 0,35 | `MUS_<Bioma>_Battle` |
| Anticipación del ataque | La voz de la criatura y el lanzamiento del elemento | `SFX_CR_<especie>_Attack` / `_Special` · `SFX_<Elemento>_Cast` |
| Viaje | Bucle corto que se corta al impactar | `SFX_<Elemento>_Travel` |
| Impacto | Golpe base y elemento, a la vez; el crítico añade 60 ms de silencio antes del golpe | `SFX_Combat_Hit` / `_Crit` · `SFX_<Elemento>_Impact` |
| Reacción | Voz del herido, corta | `SFX_CR_<especie>_Hurt` |
| Escudo, curación, reflejo | Capas de cerámica, marimba y metal | `SFX_Combat_Shield` / `_Heal` / `_Reflect` |
| Estados | Un disparo por turno, no en bucle | `SFX_Combat_Burn` / `_Paralyze` / `_Stun` |
| Savia llena | Aviso de que el Golpe Nexo está listo | `SFX_Combat_NexoCharge` |
| Golpe Nexo | La música baja −4 dB; la secuencia (≤ 3,5 s) se puede saltar y el audio se corta con un fundido de 0,15 s | Las mismas señales del elemento, más grandes |
| Victoria | Motivo del Nexo y después la pieza de victoria | `SFX_Combat_Victory` · `MUS_<Bioma>_Victory` · `SFX_CR_<especie>_Victory` |
| Derrota | «Descansa»: cálido y breve; nunca de castigo | `SFX_Combat_Defeat` |

**Combate rápido o saltado:**
- se oye solo el impacto final y el resultado;
- nunca se encadenan todas las señales en el mismo fotograma.

---

## 6. Interfaz

La interfaz suena a **madera y latón del Gabinete**: cajones que se abren y se cierran, y marimba para confirmar.
- **Señales:** `SFX_UI_Tap`, `Open`, `Close`, `Confirm`, `Back`, `Error`, `Toast`, `Reward`, `Achievement`, `Hatch`, `Evolve` y `LevelUp` (§9.6).
- **Reglas:**
  - toda señal de interfaz dura ≤ 0,4 s, salvo las ceremonias;
  - `Error` es un golpe sordo, nunca un zumbador;
  - ninguna señal empuja a comprar.
- **Rareza:** la «firma sonora» del Único (Biblia p. 26) y las presentaciones por rareza no tienen id todavía: propuesta A-4 (§10).

---

## 7. Especificaciones técnicas en Roblox

### 7.1. `Sound` o la API de audio nueva
- **Hoy:** `SoundController` usa **`Sound`**, con:
  - `PlaybackSpeed` para la variación de tono;
  - `RollOffMode = InverseTapered` y `RollOffMinDistance = 6`;
  - `RollOffMaxDistance` de cada señal;
  - pool de 16 voces con robo de la más antigua.
  - Es la API estable y la que basta para la beta.
- **API nueva:** `AudioPlayer` (reproduce un recurso), `AudioEmitter` (fuente en el mundo), `AudioListener` (oído en la cámara o el personaje), `AudioDeviceOutput` y `Wire` para conectarlos, más efectos como `AudioFader`, `AudioEqualizer`, `AudioReverb`, `AudioCompressor` y `AudioFilter`.
  - Permite mezclas por grafo y curvas de distancia propias.
  - **Hay que verificar su estado actual en la documentación oficial (Creator Hub) antes de adoptarla.**
  - Propuesta A-5: seguir con `Sound` en la beta y evaluar la API nueva para el filtro del Opacamiento y el ducking.

### 7.2. Distancias (`RollOffMode` y alcance)

| Señales | Tipo | Mín. | Máx. (`AudioCues`) | Por qué |
|---|---|---|---|---|
| `SFX_<Elemento>_*`, `SFX_Combat_*` | 3D | 6 | 90 | La arena se oye entera; un combate lejano en el mundo no |
| `SFX_CR_*` (salvo `Evolve`) | 3D | 6 | 60 | Coincide con el LOD de criaturas (Genesis §9: más allá de 60, sin partículas ni luces) |
| `SFX_CR_*_Evolve` | 2D | — | — | Ceremonia en interfaz |
| `AMB_*_Base` | 2D | — | — | Fondo del bioma |
| Otras capas `AMB_*` | 3D | 6 (16 propuesto para cascada y fragua) | 120 | Fuentes de zona |
| `MUS_*`, `SFX_UI_*` | 2D | — | — | Sin posición |

- `SoundService.DistanceFactor`: 3,33 (valor por defecto).
- `DopplerScale = 0`: sin desafinar al moverse.
- `RolloffScale = 1`.

### 7.3. Volúmenes y loudness (propuesta)
- **Rango:** `Sound.Volume` y `SoundGroup.Volume` van de 0 a 10. El catálogo usa 0,35–0,8 por señal y los grupos de §2 multiplican.
- **Normalización:** cada archivo se normaliza **antes de subirlo**, para que el volumen de la señal sea una decisión de mezcla y no una corrección.

| Tipo | Objetivo | Pico real |
|---|---|---|
| Música | −18 LUFS integrados | ≤ −1 dBTP |
| Ambiente `Base` | −26 LUFS integrados | ≤ −3 dBTP |
| Capas de ambiente | −24 LUFS integrados | ≤ −3 dBTP |
| Combate y criaturas | −16 a −18 LUFS a corto plazo (3 s) | ≤ −1 dBTP |
| Interfaz | −20 LUFS a corto plazo | ≤ −3 dBTP |

**Prueba de mezcla:** en el altavoz de un teléfono y con auriculares. La voz de la criatura se entiende por encima de la música de combate.

### 7.4. Formato, duración y subida (verificar)
- **Formatos:** `.ogg` (Vorbis, calidad 5–6, ~160 kb/s) o `.mp3`. Verificar si Roblox acepta hoy otros formatos.
  - **Los bucles van en `.ogg`:** el `.mp3` añade relleno del codificador al principio y al final, y el bucle se oye cortado.
- **Canales y muestreo:** 44,1 o 48 kHz. Mono para todo lo 3D (criaturas, combate y capas de zona); estéreo para la música y `AMB_*_Base`.
- **Duraciones objetivo:** columna «Duración» de §9.
  - Bucles de música de 60–150 s; de ambiente, 45–90 s.
  - Efectos ≤ 1,5 s salvo las ceremonias.
  - Bucles con el inicio y el final en un cruce por cero.
- **Límites de subida conocidos a la fecha (verificar en la documentación vigente):** duración ≤ 7 min por archivo, tamaño ≤ 20 MB y una cuota mensual de subidas que depende de la verificación de la cuenta.
  - Los permisos de uso del audio en la experiencia también se comprueban al subir.
- **Carga:**
  - `ContentProvider:PreloadAsync` de las señales del combate durante el viaje de cámara (0,8 s);
  - la música se carga al entrar en el bioma, nunca en el primer golpe.

### 7.5. Voces simultáneas

| Grupo | Voces |
|---|---|
| Música (2 durante el fundido) | 1–2 |
| Ambiente: `Base` + hasta 3 capas 3D | 1–4 |
| Combate | ≤ 6 |
| Criaturas | ≤ 4 (las más cercanas) |
| Interfaz | ≤ 2 |

- **Total ≤ 16**, el `maxVoices` de `SoundController`.
- El pool de VFX reserva 24 `Sound` (`VFX_SYSTEM.md` §7), con margen para la ceremonia.
- Con las voces agotadas, se roba la más antigua que no esté en bucle (comportamiento actual).

---

## 8. Licencias

- **Solo audio original** hecho para NEXORA, o audio con **licencia verificada por escrito** que permita su uso en una experiencia de Roblox con fines comerciales.
- **Nada de música protegida:** ni canciones conocidas, ni «arreglos» de temas de otras obras, ni muestras sin licencia.
  - La inspiración en oficios y tradiciones es de timbre y técnica, nunca de melodías concretas.
  - Los instrumentos con uso ceremonial se tratan con respeto: como timbre, nunca en un contexto de burla ni imitando un rito.
- **Biblioteca de audio de Roblox:** si se usa algún recurso suyo, se verifica su licencia vigente y se anota.
- **Registro por archivo** (propuesta A-6, junto al `asset.json` de `CREATURE_3D_ASSETS.md`): autor, fecha, herramienta, licencia, archivo fuente y, cuando exista, el id real de Roblox.
- **Ningún gasto ni compra** de audio sin autorización explícita (CLAUDE.md).

---

## 9. Catálogo de señales (`Config/AudioCues`)

**Columnas:**
- **Tipo · alcance:** sale de `rollOffMaxDistance` (2D = sin posición).
- **Vol.** y **Tono ±:** los valores de `AudioCues`.
- **Duración:** el objetivo de producción.
- **Estado:** todas están **pendientes de producción**, sin id de Roblox.

### 9.1. Elementos (`SFX_<Elemento>_<Fase>`, 39)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `SFX_Agua_Cast` | Cántaro que se vuelca: gorgoteo e inhalación | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Agua_Travel` | Chorro continuo con burbujeo | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Agua_Impact` | Salpicadura; las gotas caen después | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Fuego_Cast` | Fuelle y brasa que se aviva | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Fuego_Travel` | Llama que ruge y sube de tono | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Fuego_Impact` | Estallido de brasas que chisporrotea y se apaga | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Aire_Cast` | Papalote: tela que se tensa | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Aire_Travel` | Silbido en remolino que gira en estéreo | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Aire_Impact` | Ráfaga seca con plumas | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Tierra_Cast` | Piedra que se arranca, grava | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Tierra_Travel` | Piedras que ruedan, retumbo | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Tierra_Impact` | Golpe sordo; la grava rebota 2–3 veces y se asienta | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Metal_Cast` | Hojalata que se dobla, remache | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Metal_Travel` | Filo que corta el aire, zumbido metálico | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Metal_Impact` | Martillo sobre yunque, resonancia corta | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Flora_Cast` | Vainas que crujen, hojas | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Flora_Travel` | Tallos que se estiran, crujido verde | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Flora_Impact` | Brote que revienta y sonaja de semillas de huaje | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Rayo_Cast` | Bobina que se carga, chicharra que sube | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Rayo_Travel` | Chasquidos que saltan de un punto a otro | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Rayo_Impact` | Trueno seco y corto con zumbido de 0,3 s | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Artificio_Cast` | Llave de cuerda, trinquete | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Artificio_Travel` | Engranes y rehilete que giran | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Artificio_Impact` | Muelle que se suelta y clic de caja de música | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Luz_Cast` | Copa de cristal frotada que sube | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Luz_Travel` | Campanillas de porcelana | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Luz_Impact` | Acorde de vidrio brillante, sin agudos estridentes | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Sombra_Cast` | Rebozo que se despliega | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Sombra_Travel` | Susurro de tela y niebla, filtrado | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Sombra_Impact` | Golpe acolchado y tela que se cierra; sin sustos | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Mente_Cast` | Resonancia de caracola al oído | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Mente_Travel` | Pulsos en anillo (trémolo) | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Mente_Impact` | Gota grave de tinta y anillos que se abren | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Astral_Cast` | Metalófono en arpegio ascendente | 3D · 90 | no | 0,7 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Astral_Travel` | Tintineo que orbita en estéreo | 3D · 90 | no | 0,7 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Astral_Impact` | Meteorito pequeño y suave con destellos de campana | 3D · 90 | no | 0,7 | 0,06 | ≤ 1,0 s con cola | Pendiente |
| `SFX_Eco_Cast` | Inhalación y movimiento del cuerpo | 3D · 90 | no | 0,6 | 0,06 | ≤ 0,6 s | Pendiente |
| `SFX_Eco_Travel` | Barrido de aire neutro | 3D · 90 | no | 0,6 | 0,06 | 0,4–1,0 s, cortable | Pendiente |
| `SFX_Eco_Impact` | Golpe físico seco de madera y tela | 3D · 90 | no | 0,6 | 0,06 | ≤ 1,0 s con cola | Pendiente |

### 9.2. Eventos de combate (`SFX_Combat_<Evento>`, 11)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `SFX_Combat_Hit` | Golpe base de madera y tela; se suma al Impact del elemento | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,4 s | Pendiente |
| `SFX_Combat_Crit` | 60 ms de silencio y luego golpe con campanilla de cobre aguda | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,6 s | Pendiente |
| `SFX_Combat_Shield` | Domo de cerámica y copal que se cierra: campana grave y brillo | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,8 s | Pendiente |
| `SFX_Combat_Heal` | Marimba en arpegio ascendente (3 notas) y respiración | 3D · 90 | no | 0,7 | 0,05 | ≤ 1,0 s | Pendiente |
| `SFX_Combat_Burn` | Chisporroteo corto en cada turno (no en bucle) | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,6 s | Pendiente |
| `SFX_Combat_Paralyze` | Chasquido eléctrico y zumbido que se corta | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,7 s | Pendiente |
| `SFX_Combat_Stun` | Sonaja que gira | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,8 s | Pendiente |
| `SFX_Combat_Reflect` | Ping metálico y el ataque devuelto al revés | 3D · 90 | no | 0,7 | 0,05 | ≤ 0,7 s | Pendiente |
| `SFX_Combat_Victory` | Motivo del Nexo (4 notas) en modo mayor | 3D · 90 | no | 0,8 | 0 | 1,5–2,0 s | Pendiente |
| `SFX_Combat_Defeat` | «Descansa»: marimba que baja 3 notas y resuelve en un acorde cálido; nunca triste ni de terror | 3D · 90 | no | 0,8 | 0 | 1,5–2,0 s | Pendiente |
| `SFX_Combat_NexoCharge` | Savia llena: sonaja y flauta de carrizo que crecen | 3D · 90 | no | 0,7 | 0,05 | ≤ 1,5 s | Pendiente |

### 9.3. Iniciales (`SFX_CR_<especie>_<acción>`, 24)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `SFX_CR_kuachi_Idle` | 2–3 olfateos y crepitar de brasa en la bolsa; cada 8–14 s | 3D · 60 | no | 0,6 | 0,08 | 0,6–1,2 s | Pendiente |
| `SFX_CR_kuachi_Move` | Pasos acolchados ligeros y roce de la cola (4 variantes) | 3D · 60 | no | 0,6 | 0,08 | 0,15–0,3 s por paso | Pendiente |
| `SFX_CR_kuachi_Happy` | Chillido-risa, «se hace el muerto» (golpe blando) y saltito | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |
| `SFX_CR_kuachi_Hurt` | Gañido corto y siseo de brasa; sin dolor explícito | 3D · 60 | no | 0,6 | 0,08 | ≤ 0,5 s | Pendiente |
| `SFX_CR_kuachi_Attack` | Bufido, zarpazo y chispa, encima de SFX_Fuego_* | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,2 s | Pendiente |
| `SFX_CR_kuachi_Special` | Puerta de horno de barro que se abre (clonc) y ráfaga | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,6 s | Pendiente |
| `SFX_CR_kuachi_Evolve` | Crepitar que crece → rugido de horno → gruñido del Tallado (−4 semitonos) | 2D | no | 0,6 | 0 | ≤ 2,0 s | Pendiente |
| `SFX_CR_kuachi_Victory` | Trino pícaro, latigazo de cola y chispa | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |
| `SFX_CR_xolumi_Idle` | Aleteo de branquias, 1–2 burbujas como mucho y zumbido suave | 3D · 60 | no | 0,6 | 0,08 | 0,6–1,2 s | Pendiente |
| `SFX_CR_xolumi_Move` | Chapoteo húmedo y ondulación del cuerpo | 3D · 60 | no | 0,6 | 0,08 | 0,15–0,3 s por paso | Pendiente |
| `SFX_CR_xolumi_Happy` | Risa gorgoteante y chorrito de agua | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |
| `SFX_CR_xolumi_Hurt` | «Glup» ahogado y tic de cerámica | 3D · 60 | no | 0,6 | 0,08 | ≤ 0,5 s | Pendiente |
| `SFX_CR_xolumi_Attack` | Chorro siseante, encima de SFX_Agua_* | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,2 s | Pendiente |
| `SFX_CR_xolumi_Special` | Ola que crece y resonancia de cántaro de barro | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,6 s | Pendiente |
| `SFX_CR_xolumi_Evolve` | Barro que se agrieta → sellado de oro (campanilla) → bramido con agua | 2D | no | 0,6 | 0 | ≤ 2,0 s | Pendiente |
| `SFX_CR_xolumi_Victory` | Abanico de branquias («frrr») y arrullo | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |
| `SFX_CR_teselo_Idle` | Teselas que se acomodan (clac) y respiración lenta | 3D · 60 | no | 0,6 | 0,08 | 0,6–1,2 s | Pendiente |
| `SFX_CR_teselo_Move` | Pisada pesada con armónicos (no subgraves) y traqueteo de teselas | 3D · 60 | no | 0,6 | 0,08 | 0,15–0,3 s por paso | Pendiente |
| `SFX_CR_teselo_Happy` | «Pop» hueco al meterse en el caparazón y clic de piedra | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |
| `SFX_CR_teselo_Hurt` | Gruñido bajo y teselas que vibran | 3D · 60 | no | 0,6 | 0,08 | ≤ 0,5 s | Pendiente |
| `SFX_CR_teselo_Attack` | Pisotón y polvo, encima de SFX_Tierra_* | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,2 s | Pendiente |
| `SFX_CR_teselo_Special` | Muro de adobe que se alza (piedra que raspa) | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,6 s | Pendiente |
| `SFX_CR_teselo_Evolve` | Piedra que muele subiendo → anillos que se alinean (campanas en quintas) → zumbido y estrellas | 2D | no | 0,6 | 0 | ≤ 2,0 s | Pendiente |
| `SFX_CR_teselo_Victory` | «Pop» del caparazón (Brote) · anillos que giran con un tintineo (Tallado) | 3D · 60 | no | 0,6 | 0,08 | ≤ 1,8 s | Pendiente |

### 9.4. Ambiente (`AMB_<Bioma>_<Capa>`, 18)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `AMB_CumbreBrasa_Base` | Retumbo del volcán (con armónicos) y hornos encendidos (arquitectura) | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_CumbreBrasa_Lava` | Burbujeo y crepitar de los canales de lava | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_CumbreBrasa_Wind` | Viento caliente con ceniza | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MareaCoralina_Base` | Brisa marina y hojas del manglar (viento y vegetación) | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MareaCoralina_Waves` | Olas en el arrecife, gotas y eco en el cenote (agua y arquitectura) | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MareaCoralina_Fauna` | Aves marinas lejanas, peces que saltan, cangrejos en las raíces | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MesetaFulgor_Base` | Zumbido de cables, molinos y engranes de taller (arquitectura) | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MesetaFulgor_Storm` | Trueno lejano y lluvia en ráfagas | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_MesetaFulgor_Wind` | Viento constante que silba en las estructuras | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_TorreDelNexo_Base` | Madera que cruje y latido muy bajo del corazón | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_TorreDelNexo_Echo` | Eco del basamento y campana de la Repisa | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_ValleCopal_Base` | Viento suave en el pasto y hojas de ahuejote (capas: viento y vegetación) | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_ValleCopal_Water` | Río, cascada y lago de las chinampas (capa: agua) | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_ValleCopal_Fauna` | Aves y chicharras de tarde; ranas al crepúsculo (capa: fauna) | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_ValleCopal_Market` | Oficios: comal, telar, cántaros y murmullo sin palabras (capas: arquitectura e interactivos) | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_VeloAstral_Base` | Fondo etéreo: coro sin palabras muy bajo y tela | 2D | sí | 0,5 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_VeloAstral_Wind` | Viento alto entre nubes | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |
| `AMB_VeloAstral_Stars` | Tintineo de estrellas y faroles cercanos | 3D · 120 | sí | 0,35 | 0 | 45–90 s en bucle sin corte | Pendiente |

### 9.5. Música (`MUS_<Bioma>_<Estado>`, 24)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `MUS_CumbreBrasa_Explore` | Exploración: Yunques y martillos en ritmo, fuelles, campanas de cobre y latón, tambores de barro, guitarra grave. 104–116 BPM, Menor armónico (heroico, no oscuro). Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_CumbreBrasa_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_CumbreBrasa_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_CumbreBrasa_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |
| `MUS_MareaCoralina_Explore` | Exploración: Vasijas de agua percutidas, copas de cristal frotadas, arpa y flauta. 70–80 BPM, Dórico / lidio. Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_MareaCoralina_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_MareaCoralina_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_MareaCoralina_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |
| `MUS_MesetaFulgor_Explore` | Exploración: Cajas de música, metalófono, engranes como percusión, cuerdas tensadas, timbales de tormenta. 120–132 BPM, Lidio. Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_MesetaFulgor_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_MesetaFulgor_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_MesetaFulgor_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |
| `MUS_TorreDelNexo_Explore` | Exploración: El motivo del Nexo con todos los instrumentos de los biomas, más madera tallada (gubia) y el latido. 84–92 BPM, Mayor. Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_TorreDelNexo_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_TorreDelNexo_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_TorreDelNexo_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |
| `MUS_ValleCopal_Explore` | Exploración: Marimba, flauta de carrizo, ocarina de barro, arpa, sonajas de huaje y tambor de piel suave. 92–100 BPM, Mayor / mixolidio. Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_ValleCopal_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_ValleCopal_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_ValleCopal_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |
| `MUS_VeloAstral_Explore` | Exploración: Campanas de cristal, arpa, coro sin palabras, cuerdas en armónicos, tela como percusión. 60–68 (rubato) BPM, Lidio / pentatónica. Capas que entran por cercanía | 2D | sí | 0,45 | 0 | 90–150 s en bucle | Pendiente |
| `MUS_VeloAstral_Battle` | Combate: misma tonalidad y tempo +10 %; percusión al frente | 2D | sí | 0,45 | 0 | 60–90 s en bucle | Pendiente |
| `MUS_VeloAstral_Boss` | Jefe: tema del guardián (el motivo del bioma invertido); la fase 2 añade una capa | 2D | sí | 0,45 | 0 | 90–120 s en bucle | Pendiente |
| `MUS_VeloAstral_Victory` | Victoria; tras un jefe, es la restauración: el motivo completo y vuelve Explore con todas sus capas | 2D | no | 0,45 | 0 | 6–10 s | Pendiente |

### 9.6. Interfaz (`SFX_UI_<Acción>`, 12)

| Id | Qué suena | Tipo · alcance (studs) | Bucle | Vol. | Tono ± | Duración | Estado |
|---|---|---|---|---|---|---|---|
| `SFX_UI_Tap` | Toque de madera corto | 2D | no | 0,5 | 0 | ≤ 0,1 s | Pendiente |
| `SFX_UI_Open` | Cajón que se abre (madera y latón) | 2D | no | 0,5 | 0 | ≤ 0,3 s | Pendiente |
| `SFX_UI_Close` | Cajón que se cierra, más grave | 2D | no | 0,5 | 0 | ≤ 0,3 s | Pendiente |
| `SFX_UI_Confirm` | Dos notas de marimba hacia arriba | 2D | no | 0,5 | 0 | ≤ 0,4 s | Pendiente |
| `SFX_UI_Back` | Una nota de marimba hacia abajo | 2D | no | 0,5 | 0 | ≤ 0,2 s | Pendiente |
| `SFX_UI_Error` | Golpe sordo de madera, sin zumbador | 2D | no | 0,5 | 0 | ≤ 0,3 s | Pendiente |
| `SFX_UI_Toast` | Campanilla suave de aviso | 2D | no | 0,5 | 0 | ≤ 0,4 s | Pendiente |
| `SFX_UI_Reward` | Monedas de cobre que caen en un cántaro | 2D | no | 0,5 | 0 | ≤ 0,8 s | Pendiente |
| `SFX_UI_Achievement` | El motivo del Nexo en 3 notas de campana | 2D | no | 0,5 | 0 | ≤ 1,2 s | Pendiente |
| `SFX_UI_Hatch` | Cáscara de copal que cruje y latido que se abre | 2D | no | 0,5 | 0 | ≤ 1,5 s | Pendiente |
| `SFX_UI_Evolve` | Revelación del Tallado, acompaña EvolutionVFXController | 2D | no | 0,5 | 0 | ≤ 4,5 s | Pendiente |
| `SFX_UI_LevelUp` | Arpegio de marimba y sonaja | 2D | no | 0,5 | 0 | ≤ 1,0 s | Pendiente |

---

## 10. Señales propuestas que aún no están en el catálogo

**No existen en `AudioCues`.** Si se aprueban, el equipo de audio las añade con la misma convención:
- `SFX_World_<Objeto>` (la categoría `World` ya existe y no tiene señales): fuelle, yunque, palanca, caracola, estrella-paso, farol que se suelta, compuerta de lava, pararrayos y cajón del Gabinete.
- `SFX_UI_CardReveal` y `SFX_UI_CardRevealUnico`: presentación de la carta por rareza; la segunda es la «firma sonora» del Único (Biblia p. 26). A-4.
- `MUS_<Bioma>_Restore`, solo si `Victory` no basta como pieza de restauración.
- Sufijo de forma para los Tallados que necesiten archivo propio: `SFX_CR_kuachi_Attack_Tallado`. A-3.

---

## 11. Decisiones propuestas

No están registradas en `DESIGN_DECISIONS.md` (este equipo no puede editarlo).

| # | Propuesta | Motivo |
|---|---|---|
| A-1 | Motivo del Nexo de 4 notas, reorquestado por bioma, a partir del guion sonoro de la introducción | Identidad reconocible, y la Biblia ya da sus timbres |
| A-2 | Un `SoundGroup` por categoría de `AudioCues`, con los volúmenes y el ducking de §2 | Hoy solo hay multiplicadores en `CategoryVolume` |
| A-3 | El Tallado reutiliza las señales de su especie con −4 semitonos y una capa de cuerpo; si necesita archivo propio, sufijo `_Tallado` | Conserva «el mismo monstruo» y evita duplicar ids |
| A-4 | Señales de presentación de carta por rareza, con la firma sonora del Único | La Biblia la pide (p. 26) y el catálogo no la tiene |
| A-5 | `Sound` en la beta; la API de audio nueva se evalúa después, tras verificar su estado | Estabilidad; es lo que usa `SoundController` |
| A-6 | Registro de licencia y procedencia por archivo de audio | Solo audio original o con licencia verificada |
| A-7 | El Opacamiento como «silencio y viento» con filtro de paso bajo, y la restauración devolviendo las capas en orden | Biblia p. 109, plano 4; restaurar, no destruir |
