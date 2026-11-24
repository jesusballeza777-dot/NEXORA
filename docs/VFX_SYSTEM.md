# NEXORA · Sistema de efectos visuales (VFX)

**Estado:** implementado en código y probado en Lune con clases reales de `@lune/roblox`. **No se ha visto en Roblox Studio** (no hay Studio en este entorno): el aspecto real, las texturas del motor y el rendimiento en el teléfono base quedan por verificar (§10).

**Fuentes:**
- Biblia compacta: p. 26 (aura por rareza), p. 31 (los doce elementos), p. 36–38 (ataques por elemento), p. 120 (presupuestos).
- `ART_BIBLE_GENESIS.md`: §6 (rareza), §8 (movimiento y efectos) y §9 (LOD).

**Documento hermano:** `ANIMATION_SYSTEM.md`.

---

## 1. Reglas que el sistema garantiza (con prueba)

| Regla | Dónde se aplica | Prueba |
|---|---|---|
| Común 0 emisores · Raro 1 solo al atacar + contorno · Épico 1–2 · Legendario 2–3 + haz · Único hasta 3 · Misterio propios | `VFXPlan.aura`, `AuraController` | `VFXConfig.spec`, `VFXAura.spec` (todas las rarezas × 12 elementos × Brote/Tallado × 3 calidades) |
| Tasa ≤ 20 partículas/s por emisor, también tras los multiplicadores y en pulsos | `ParticleStyles.rate` | `VFXConfig.spec`, `VFXAura.spec`, `CombatVFX.spec` |
| Brote: aura al 80 % de tamaño y con la mitad de partículas | `VFX.Budget.broteSize/broteRate` | `VFXAura.spec` |
| Combate: el aura baja al 60 % | `VFX.Budget.battleIntensity` (= `Combat.AuraBattleIntensity`) | `VFXAura.spec` |
| La cara nunca queda tapada | Anclajes detrás del cuerpo (Z < 0), detrás de la cabeza o en la órbita exterior, que no emite al pasar por delante; el aura nunca emite hacia delante; `ZOffset` negativo | `VFXAura.spec` (5 especies × 2 formas × 12 elementos) |
| Un efecto no tapa al objetivo más de 0,3 s | Los impactos sobre el objetivo duran ≤ 0,3 s o salen a ≥ 6 studs/s; contornos ≤ 0,3 s | `VFXConfig.spec` |
| Ningún ataque supera 1,6 s; Golpe Nexo ≤ 3,5 s; todo se puede saltar | `VFX.Sequences`, `CombatVFXController.skip` | `VFXConfig.spec`, `CombatVFX.spec` |
| Sacudida de cámara ≤ 0,3 studs; con movimiento reducido no se mueve | `CameraDirector` | `CombatVFX.spec` |
| Pool: reutiliza instancias y lo devuelve todo | `VFXPool` | `VFXAura.spec`, `CombatVFX.spec` |
| Sin hilos sueltos | Un solo `VFXRuntime.step` por frame con presupuesto y temporizadores cancelables | `VFXConfig.spec` (reloj falso) |
| Solo texturas del motor; ningún `rbxassetid` | `VFX.Textures` | `VFXConfig.spec` |

---

## 2. Arquitectura

```
Shared/Config/VFX.luau            datos congelados: estilos, 12 perfiles, rareza, impactos,
                                  secuencias, calidad, LOD, cámara, evolución
Shared/Config/AudioCues.luau      señales de sonido (estructura, sin audio)
Client/VFX/
  VFXPlan            PURO: presupuesto del aura, LOD con histéresis, calidad, tipo de
                     secuencia, línea de tiempo, impacto por evento del servidor
  VFXRuntime         PURO: un paso por frame, presupuesto por frame, temporizadores cancelables
  VFXPool            reutiliza emisores, attachments, beams, trails, luces, highlights,
                     volúmenes y sonidos; límites por clase; limpieza por dueño
  VFXContext         pool, runtime y ancla invisible en el origen (compartidos)
  VFXSettings        calidad, movimiento reducido y combate rápido (sesión)
  ParticleStyles     aplica un estilo de datos a un ParticleEmitter (todas las propiedades)
  BeamShapes         anillos de dos Beam y haces
  RarityEffects      contorno (Highlight), haz, halo iridiscente y emisivo animado
  AuraController     aura de rareza por criatura (presupuesto, órbitas, LOD, opacado)
  ElementalVFXController  lanzamiento, viaje e impacto de cada elemento
  ImpactVFXController     biblioteca de impactos
  CameraDirector          cámara de combate
  CombatVFXController     secuencia de seis fases de una jugada
  EvolutionVFXController  secuencia del Tallado en la ceremonia
Client/Audio/SoundController      reproduce señales con audio aprobado (hoy ninguna)
Client/UI/Screens/EffectsSettings ajustes del jugador (menú rápido → ✨ Efectos)
```

**Quién los usa:**
- `WorldController` pone aura a acompañantes, hábitats y Opacos.
- `BattleController` reproduce una secuencia por jugada, con aura al 60 %, cámara y botón ⏩.
- `Ceremony.evolve` usa `EvolutionVFXController`.
- `ClientBootstrap` conecta el runtime a `RenderStepped` una vez y registra la actualización de todas las auras.

**Ciclo de vida:**
1. `AuraController.attach` envuelve el `destroy` de la criatura: destruirla devuelve antes todo al pool.
2. Los efectos de combate tienen como dueño su secuencia: `skip()` cancela sus efectos y suelta sus instancias.
3. Un emisor de brote vuelve al pool cuando su última partícula muere (no se corta el efecto).

**El aura sale de `CreatureBuilder`:** el emisor provisional que creaba el constructor se retira al adjuntar el aura. `CreatureBuilder` solo añade nombres y el atributo `Bone` a sus piezas.

---

## 3. Los doce elementos

La identidad viene de la forma y el movimiento: tamaño en el tiempo, velocidad, aceleración, arrastre, `SpreadAngle`, orientación, órbitas, `Beam`/`Trail`, `Highlight` y luz. Solo hay cuatro texturas del motor.

| Elemento | Movimiento | Aura (en orden de prioridad) | Lanzamiento | Viaje | Impacto |
|---|---|---|---|---|---|
| Agua | Cae y salpica | Burbujas que suben y se frenan · gotas que caen por gravedad, estiradas · niebla marina baja | Gotas + anillo vertical | Haz curvo que ondula (corriente) con gotas | Salpicadura en abanico que cae + onda en el suelo + luz breve |
| Fuego | Sube y se apaga | Brasas con aceleración positiva · lenguas de llama que giran y encogen · humo de copal sin luz propia | Chispazo de chispas estiradas + luz | Proyectil en arco con estela de llama y Trail | Fragmentos incandescentes que caen + bocanada de humo + luz |
| Aire | Gira | Hélice (punto en órbita que sube) · hojas que planean de lado · plumas que bajan meciéndose | Ráfaga de rayas rapidísimas + anillo | Espiral con estela | Remolino a los pies + hojas + anillo de suelo |
| Tierra | Rebota y se asienta | Polvo a ras de suelo · guijarros que saltan y caen · grecas de luz que se encienden a saltos | Fragmentos del suelo + anillo octogonal | Onda por el suelo que levanta polvo cada 0,08 s («a saltos») | Fragmentos con mucha gravedad + polvo + anillo de choque + líneas de greca; la sacudida más fuerte |
| Metal | Destella | Reflejos que crecen y se apagan en el borde · pulso mecánico a ritmo fijo (cada 0,5 s) · chispas de esmeril | Chispas + anillo hexagonal | Proyectil recto que gira con estela fina | Esmeril rápido + destello grande de 0,2 s + anillo hexagonal + contorno blanco |
| Flora | Brota | Esporas que flotan · pétalos planos que caen girando · semillas en arco | Semillas + brotes que salen del suelo + anillo | Raíces: haz bajo que crece por el suelo con brotes | Pétalos, esporas y brotes desde los pies |
| Rayo | Salta | Destellos de 0,1 s que cambian de sitio · descargas que se frenan en seco | Chispas radiales + luz fuerte de 0,08 s | Arco en zigzag de 5 tramos que se redibuja 20 veces/s | Descarga radial + rayas largas de 0,1 s + luz + contorno |
| Artificio | Engrana | Piezas que giran a ritmo constante en una órbita que avanza a saltos · resortes que laten · planetas de cuerda | Resortes + anillo octogonal que gira a saltos | Proyectil que gira con dos satélites | Piezas que saltan y caen + resortes + anillo octogonal |
| Luz | Irradia | Destellos que nacen en una esfera y se alejan · rayos finos radiales · halo (punto que recorre un disco detrás de la cabeza) | Destellos + luz cálida + anillo | Haz recto y rápido con rayos | Estallido radial + luz + contorno blanco |
| Sombra | Se arrastra | Humo denso sin luz · niebla que repta hacia atrás · fragmentos oscuros planos por el suelo | Bocanada a los pies + el atacante se ensombrece | Por el suelo, lento y serpenteante, dejando fragmentos | Fragmentos y humo a los pies + el objetivo se ensombrece 0,2 s |
| Mente | Pulsa en anillos | Cáscara de puntos que se abre a la vez cada 0,8 s · espiral · ondas concéntricas a ras de suelo | Pulso + dos anillos escalonados | Ondas sucesivas a lo largo del camino | Choque mental + tres anillos concéntricos escalonados + contorno rosado |
| Astral | Orbita | Estrellas quietas que parpadean · satélite en órbita inclinada · polvo cósmico | Estrellas + constelación que se dibuja | Cometa que orbita la línea de tiro con estela | Estallido de estrellas + anillo inclinado + constelación |

Hay además un perfil **Eco** para ataques sin elemento.

**Paleta:**
- `primary` es `Config/Elements.color`.
- `secondary`, `accent` y `dark` son propios del perfil.
- Pigmentos con saturación contenida; los acentos emisivos pueden subir (Genesis §4).

---

## 4. Rareza (p. 26 y 120)

| Rareza | Low · Medium · High (emisores en Tallado) | Capas | Además |
|---|---|---|---|
| Común | 0 · 0 · 0 | — | La rareza se lee en la carta |
| Raro | 1 · 1 · 1, **solo al atacar** | 1.º estilo del elemento | Contorno (Highlight) al atacar |
| Épico | 1 · 2 · 2 | Elemento + órbita de rareza | Emisivo animado (las piezas Neon laten); contorno al atacar |
| Legendario | 2 · 2 · 3 | Motas doradas · rayos dorados · piezas flotantes | Haz vertical detrás de la espalda (Beam); contorno al atacar |
| Único | 1 · 2 · 3 | Iridiscente · elemento · órbita | Halo iridiscente detrás de la cabeza (anillo de dos Beam cuyo degradado se desplaza) |
| Misterio | 1 · 2 · 2 (propios) | Damero que aparece a saltos · cajones que se desplazan a saltos | «Glitch» de cámara en presentaciones |

**Reglas del aura:**
- **Brote:**
  - como mucho **1** emisor (p. 120);
  - 80 % de tamaño y 50 % de partículas;
  - sin haz ni halo.
- **Combate:** tasa y brillo al 60 %; el número de emisores no cambia.
- **Opacado:** sin aura. Vuelve al restaurarse.

**Colocación:**
- En un `Attachment`, Roblox emite desde un **punto** (la forma del emisor solo actúa en una `BasePart`). Por eso el aura usa dispersión y órbitas, no formas.
- Las órbitas horizontales tienen un radio de al menos 1,15 × el radio del cuerpo, compensado por la inclinación, y **no emiten en el sector frontal (±60°)**.
- El halo recorre un disco vertical detrás de la cabeza.
- Los volúmenes invisibles (`Part` transparentes del pool) solo se usan en efectos de combate, nunca en el aura: la Biblia pide «nunca geometría extra» en el aura.

---

## 5. Secuencias de ataque

Fases: preparación → anticipación → ejecución → impacto → reacción → recuperación. Duraciones en segundos.

| Tipo | Prep. | Antic. | Ejec. | Impacto | Reac. | Recup. | **Total** | Golpe en | Cámara |
|---|---|---|---|---|---|---|---|---|---|
| Básico | 0,10 | 0,18 | 0,24 | 0,12 | 0,22 | 0,22 | **1,08** | 0,52 | Acercamiento → enfoque |
| Especial (y Firma) | 0,16 | 0,28 | 0,32 | 0,14 | 0,28 | 0,30 | **1,48** | 0,76 | Acercamiento → enfoque |
| Golpe Nexo | 0,40 | 0,75 | 0,80 | 0,35 | 0,55 | 0,45 | **3,30** | 1,95 | Giro + acercamiento, escena oscurecida, luz |
| Curación | 0,12 | 0,20 | 0,30 | 0,18 | 0,30 | 0,20 | **1,30** | 0,62 | Enfoque (sobre sí mismo) |
| Escudo | 0,12 | 0,18 | 0,28 | 0,18 | 0,24 | 0,20 | **1,20** | 0,58 | Enfoque (sobre sí mismo; Teselo se resguarda) |
| Estado | 0,12 | 0,20 | 0,28 | 0,14 | 0,24 | 0,20 | **1,18** | 0,60 | Enfoque |

**Qué pasa en cada fase:**
- **Preparación:** pose del animador (Attack, Special, Nexo) y aura «atacando» (el Raro enciende su emisor y su contorno).
- **Anticipación:** lanzamiento del elemento y acercamiento de cámara.
- **Ejecución:**
  - viaje del elemento (tiempo = distancia / velocidad del elemento, dentro de la fase);
  - embestida (2,6 studs en básicos; 40 % con movimiento reducido).
- **Impacto:**
  - impactos por evento del servidor (`VFXPlan.impactsFor`);
  - pausa de impacto de 0,03–0,08 s (la imagen se congela un instante);
  - sacudida ≤ 0,3 studs y reacción del objetivo;
  - en ese momento `BattleController` muestra las cifras.
- **Recuperación:** se apaga el aura de ataque y la escena vuelve a su luz.

**Tipo de secuencia de cada jugada (`VFXPlan.sequenceKind`):**
- `Nexo` → Golpe Nexo.
- Con poder: básico o especial.
- Sin poder: curación si cura; escudo si protege (escudo, bloqueo, reflejo, esquiva); estado en el resto.

**Combate rápido:** todas las fases al 60 %.

**Saltar:** el botón ⏩ (y la opción de combate rápido) terminan la secuencia al instante. El impacto se pinta una vez, las cifras salen y todo vuelve al pool.

**La Biblia permite más:**
- p. 38: ataques de hasta 2,5 s y Golpe Nexo de 4 s.
- Genesis §8 lo baja a 1,6 s y 3,5 s; se usa el límite de Genesis, que cumple ambos.
- La Biblia dice que el Nexo «se puede saltar tras verlo una vez»; aquí se puede saltar siempre (instrucción del encargo).

---

## 6. Biblioteca de impactos

| Impacto | Cuándo | Qué se ve | Sacudida | Pausa | Reacción |
|---|---|---|---|---|---|
| Físico | Daño de jugada de contacto o sin elemento | Estallido claro de 0,25 s + polvo a los pies + contorno | 0,18 | 0,05 | Hurt |
| Elemental | Daño de jugada con elemento y sin contacto | Impacto del perfil del elemento | 0,15 × fuerza del elemento | 0,04 | Hurt |
| Escudo | Escudo, bloqueo, absorción, guardia | Chispas por una esfera + anillo hexagonal + contorno jade | 0,08 | — | Special (guardia) |
| Curación | Curación, regeneración, raíces | Motas verdes desde los pies + anillo + contorno | — | — | Happy |
| Quemadura | Estado o daño por turno | Brasas desde los pies + contorno naranja | 0,05 | — | Hurt |
| Parálisis | Estado | Chispas que se frenan en seco + arcos que saltan | 0,10 | 0,03 | Stun |
| Aturdido | Aturdir, dormir, confundir, no poder actuar | Estrellas que giran **encima** de la cabeza | 0,05 | — | Stun |
| Reflejo | Reflejo o guardia de reflejo | Destellos que rebotan hacia el atacante + anillo | 0,12 | 0,03 | Special |
| Crítico | Daño crítico (se suma al físico o elemental) | Estrella de rayas doradas + luz + contorno | **0,30** | 0,08 | Hurt |
| Victoria | Restauración del Opaco y fin de combate ganado | Fuente de motas de copal + anillo + luz | — | — | Victory |

---

## 7. Calidad, LOD y presupuesto

| Calidad | Tasa | Brotes | Beams | Luces | Trails | Efectos a la vez |
|---|---|---|---|---|---|---|
| Low | × 0,5 | × 0,5 | no | no | no | 10 |
| Medium (por defecto) | × 0,75 | × 0,75 | sí | no | sí | 20 |
| High | × 1 | × 1 | sí | sí | sí | 32 |

- **Calidad inicial:**
  - se lee de `UserSettings().GameSettings.SavedQualityLevel`: 1–3 → Low, 4–7 → Medium, 8–10 → High;
  - el movimiento reducido se lee de `GuiService.ReducedMotionEnabled`;
  - las dos lecturas van con `pcall`; **hay que verificarlas en Studio**.
- **LOD por distancia a la cámara (Genesis §9), con histéresis de 6 studs:**
  - 0–60: completo;
  - 60–140: sin partículas ni luces, animación a la mitad;
  - más de 140: el modelo se oculta y el acompañante solo avanza su seguimiento 4 veces por segundo, sin rayos.
- **Límites del pool por clase:**
  - `ParticleEmitter` 160, `Attachment` 240, `Beam` 96;
  - `Trail` 24, `PointLight` 8 (rango ≤ 12, sin sombras);
  - `Highlight` 12 (Roblox dibuja como mucho 31), `Part` (volúmenes) 48, `Sound` 24.
  - Si se agotan, el efecto se omite sin error.
- **Runtime:**
  - hasta 48 efectos actualizados por frame (el resto recibe el tiempo acumulado al frame siguiente);
  - 64 efectos vivos como máximo; uno nuevo por encima se rechaza y se limpia.
- **Objetivo de la Biblia:** 8 monstruos con aura a 30 fps en el teléfono base. **No medido** (requiere Studio y dispositivo).

---

## 8. Evolución (Tallado)

`EvolutionVFXController` dura 4,45 s y se puede saltar tocando.

1. **Preparación (0,6 s):** el Brote se agacha y tiembla con la pose de Nexo del animador; la cámara del retrato se acerca.
2. **Energía (1,0 s):** 14 chispas 2D del color del elemento convergen hacia el Brote, que se tiñe.
3. **Transición de materiales (0,9 s):** el Brote se oscurece hasta la silueta (60 %) y luego brilla en Neon con el color del elemento.
4. **Luz (0,35 s):**
   - destello blanco a pantalla completa y destello del Bloom del mundo;
   - con movimiento reducido, un destello suave sin Bloom.
5. **Revelación (0,8 s):**
   - el Brote desaparece y aparece el **Tallado, que es otro modelo**, brillando;
   - el Tallado crece del 80 % al 100 % y recupera sus colores y materiales.
6. **Presentación (0,8 s):** giro y pose de victoria; en Misterio, «glitch» de cámara.

**Dentro de un `ViewportFrame`** no hay partículas ni luces: todo se hace con color, material, transparencia, cámara y piezas 2D. `Ceremony.evolve` conserva su aviso, las cifras de cambio y «Toca para continuar».

---

## 9. Sonido (estructura)

`Config/AudioCues` tiene 128 señales, **todas con `assetId = nil` y `status = "Pending"`**:

| Grupo | Señales |
|---|---|
| Elementos | `SFX_<Elemento>_<Fase>`: Cast, Travel e Impact de los 12 elementos y de Eco |
| Combate | `SFX_Combat_<Evento>`: Hit, Crit, Shield, Heal, Burn, Paralyze, Stun, Reflect, Victory, Defeat y NexoCharge |
| Iniciales | `SFX_CR_<especie>_<acción>` de kuachi, xolumi y teselo: Idle, Move, Happy, Hurt, Attack, Special, Evolve y Victory |
| Ambiente | `AMB_<Bioma>_<Capa>`: capas por bioma (propuesta) |
| Música | `MUS_<Bioma>_<Estado>`: Explore, Battle, Boss y Victory |
| Interfaz | `SFX_UI_<Acción>` |

**`SoundController`:**
- solo reproduce señales con `assetId`;
- sonido espacial con `RollOffMaxDistance` y `InverseTapered`;
- variación de tono con `PlaybackSpeed`;
- pool de voces con robo de la más antigua;
- volumen por categoría.

Se llama en las fases del combate, la victoria y la derrota, la eclosión, el Tallado y la reacción del acompañante. **Hoy no suena nada.**

---

## 10. Qué falta verificar en Studio

1. **Texturas del motor:** que `rbxasset://textures/particles/sparkles_main.dds`, `fire_main.dds`, `fire_sparks_main.dds` y `smoke_main.dds` cargan en el cliente publicado. Si alguna falla, cambiar la clave en `VFX.Textures`, nunca por un ID inventado.
2. **Aspecto real de cada elemento** a la distancia de la cámara de combate y del acompañante: escala de partículas, `Squash`, `Orientation = VelocityParallel`, colores con el Bloom y la luz de tarde.
3. **Anillos de dos Beam:**
   - el signo de `CurveSize1`;
   - que se lean como círculo con `FaceCamera`;
   - el aspecto poligonal de los anillos de 6 y 8 segmentos.
4. **Emisión desde un `Attachment`** (punto) frente a `Shape` en volúmenes; `ZOffset` negativo detrás de la criatura.
5. **Highlight:**
   - el límite de 31 simultáneos con varios jugadores;
   - el contorno del Raro al atacar;
   - el ensombrecido de Sombra.
6. **Cámara:**
   - la transición desde la cámara del jugador;
   - la presentación de Copalia;
   - el giro del Golpe Nexo;
   - que nada tape a los combatientes;
   - la opción de movimiento reducido.
7. **`GuiService.ReducedMotionEnabled` y `UserSettings().GameSettings.SavedQualityLevel`** (lectura con `pcall`).
8. **Rendimiento:**
   - 8 monstruos con aura a 30 fps en el teléfono base;
   - coste de `BulkMoveTo` + auras con 12 jugadores;
   - picos del Golpe Nexo en calidad alta.
9. **Ceremonia:** aspecto del oscurecido, el brillo y la revelación dentro del `ViewportFrame`.
10. **Combate completo con el servidor:**
    - orden de cifras y textos;
    - botón ⏩;
    - cambio de monstruo a media secuencia;
    - restauración del Opaco.

    En Lune solo se prueba que `BattleController` carga e inicializa; sus secuencias se prueban por separado.

Las pruebas ejecutadas están en `tests/Unit/VFXConfig.spec.luau`, `VFXAura.spec.luau`, `CombatVFX.spec.luau` y `Audio.spec.luau`.

---

## 11. Decisiones propuestas

Pendientes de aprobación humana; no están en `DESIGN_DECISIONS.md`.

- **VFX-P1 · Aura del Brote:**
  - se aplica el máximo de 1 emisor (p. 120) **y además** el 80 %/50 % (p. 26);
  - resuelve provisionalmente la contradicción 15 de `DESIGN_DECISIONS.md`;
  - alternativa: el mismo número de emisores que el Tallado con la mitad de tasa.
- **VFX-P2 · Raro al atacar:** «1 emisor al atacar» se interpreta como el primer estilo del aura de su elemento + contorno (Highlight) solo durante la secuencia. En reposo, un Raro no tiene efectos (su rareza se lee en la carta).
- **VFX-P3 · Emisores por calidad gráfica** (tabla §4): Legendario 2 en Low/Medium y 3 en High; Épico 1 en Low.
- **VFX-P4 · Límites de duración:** se usan los de Genesis (1,6 s y 3,5 s), más estrictos que los de la Biblia (2,5 s y 4 s). El Golpe Nexo se puede saltar siempre, no solo tras verlo una vez.
- **VFX-P5 · Ajustes de efectos solo de sesión:**
  - calidad, movimiento reducido y combate rápido no se guardan en el perfil;
  - guardarlos exige un remote en `Contract` + `RemoteGateway`, una sección del perfil, subir `ProfileSchema.CURRENT_VERSION` y una migración.
- **VFX-P6 · Evolución corta (4,45 s) para todas las rarezas:**
  - la pregunta 12 de la Biblia («corta o cinemática») sigue abierta;
  - su propuesta actual es «corta + cinemática en Legendarios»;
  - `VFX.Evolution.cinematic` queda vacío a la espera de respuesta.
- **VFX-P7 · Capas de ambiente por bioma** (`AudioCues.AmbientLayers`) y estados de música: estructura propuesta, sin audio.
- **VFX-P8 · Paletas secundarias de los elementos** (`secondary`, `accent` y `dark`): las elige este sistema; el color principal es el de `Config/Elements`.
