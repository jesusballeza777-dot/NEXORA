# NEXORA · Sistema de animación

**Estado:** animación procedural implementada y probada en Lune con clases reales (blockout de Parts y un modelo de prueba con `Bone`). **No se ha visto en Roblox Studio.** Los modelos importados con esqueleto (`assets/Creatures/Initials/*`, estado *Proposal*) aún no están en el lugar.

**Fuentes:**
- `ART_BIBLE_GENESIS.md` §3.1 (familias anatómicas), §8 (personalidad en el movimiento) y §9 (animación a la mitad entre 60 y 140 studs).
- Dosieres de `docs/art/dossiers/`.
- Huesos de `assets/Creatures/Initials/*/asset.json`.

**Documento hermano:** `VFX_SYSTEM.md`.

---

## 1. Piezas

```
Shared/Config/CreatureMotion.luau     familias, personalidad, estados, umbrales, seguimiento
Shared/Domain/FollowSteering.luau     PURO: seguimiento del acompañante
Client/Creatures/CreatureRig.luau     huesos lógicos y anclajes (blockout o modelo con Bone)
Client/Animation/MotionStateMachine   PURO: 21 estados con prioridad e histéresis
Client/Animation/CreatureAnimator     poses procedurales → Parts (BulkMoveTo) o Bone.Transform
```

**Quién lo usa:**
- **`WorldController`:** acompañantes de todos los jugadores, hábitats y Opacos.
- **`BattleController`:** combatientes; poses de ataque, daño, aturdido, victoria y cansancio.
- **`EvolutionVFXController`:** el Brote se agacha y el Tallado posa, dentro del `ViewportFrame`.

---

## 2. Huesos: el mismo animador para el blockout y para la malla

Los nombres son los de `asset.json`:

| Grupo | Huesos |
|---|---|
| Comunes | `root`, `spine` (o `body`), `chest`, `neck`, `head`, `jaw` |
| Patas | `legF_L/R`, `legB_L/R` y `legM_L/R` (Xolossus) |
| Pies | `pawF_*`, `pawB_*` |
| Cola | `tail1` … `tail5` |
| Mitlaxis | `ringA`, `ringB`, `skyDisc` |

**Convención de los activos:**
- Y arriba, la criatura mira a +Z;
- **+X es su izquierda** (`_L`).

**Huesos que solo existen en el blockout:**
- `gill_L/R` (branquias de Xolumi/Xolossus);
- `wing_L/R` (alas de los arquetipos prestados).

**Blockout de Parts:**
- `CreatureBuilder` solo pone a cada pieza su nombre y el atributo `Bone`. Es el cambio mínimo; no se toca la geometría.
- `CreatureRig.fromParts` agrupa las piezas por hueso y calcula cada articulación con la geometría:
  - patas: parte alta;
  - cabeza: entre la cabeza y su padre;
  - cuello: pieza más baja;
  - cola: primer tramo;
  - branquias y alas: pieza más cercana al cuerpo.
- Resuelve los padres en el mismo orden que el modelo (`head → neck → chest → spine`).
- La cola del blockout se reparte en `tail1..tail5` por orden.

**Modelo importado:** `CreatureRig.fromBones(model)` busca instancias `Bone` por nombre y calcula su reposo componiendo `CFrame` (sin `WorldPosition`).

**Animador:**
- Cada frame calcula un **delta por hueso** alrededor de su articulación y el movimiento del cuerpo entero.
- **Parts:** el mundo de cada hueso es `padre · T(pivote) · delta · T(−pivote)`, y todas las piezas se mueven con un solo `workspace:BulkMoveTo` (o con `CFrame` directo dentro de un `ViewportFrame`).
- **Malla:** `Bone.Transform = delta` por nombre y `Model:PivotTo(cuerpo)`.

### Cómo se conectarán los rigs reales

1. Importar el GLB en Studio (`CREATURE_DESIGN_PIPELINE.md` §6). El importador crea `MeshPart` con piel y `Bone` hijos de la pieza raíz.
2. Guardar el `Model` en `ReplicatedStorage.CreatureModels` con el id del activo. `MeshCreature.build` lo clona (D-040).
3. Comprobar en el Explorer que los `Bone` se llaman como en `asset.json`. El animador los encuentra por nombre.
4. Crear el animador con `CreatureAnimator.new({ model = modelo, speciesId = id, form = forma, scale = escala }, { mesh = true })`.
5. **Supuesto a verificar:**
   - los huesos importados tienen orientación de reposo alineada con el modelo, así que el delta se aplica tal cual como `Transform`;
   - si el importador rota los huesos, hay que convertir el delta al espacio del hueso: `rest:Inverse() * delta * rest`.
6. **Animaciones hechas a mano** (`AnimationController` + `Animator` + `Animation` con un id real, cuando existan y se aprueben):
   - pueden convivir con las procedurales;
   - el animador procedural deja de escribir `Transform` en los huesos que la pista anime;
   - queda pendiente de diseñar cuando haya pistas.
7. **`Motor6D`:** si en vez de piel llegan piezas rígidas unidas, el mismo delta va a `Motor6D.Transform`. El rig se construiría leyendo los `Motor6D` por el nombre de su `Part1`. Adaptación pequeña en `CreatureRig`, no hecha porque no hay modelos así.

**Pendiente de la integración (no es de este equipo):**
- `CreatureBuilder.build` todavía no usa `MeshCreature`;
- cuando lo haga, `WorldController` y `BattleController` deberán crear el animador con `mesh = true` para esas criaturas.

---

## 3. Familias anatómicas (`CreatureMotion.Families`)

| Familia | Forma de andar | Rasgos del movimiento |
|---|---|---|
| Cuadrúpedo ágil | Trote: diagonales a la vez | Rebote marcado al correr; cabeza rápida; cola viva; inclinación en los giros |
| Cuadrúpedo pesado | Paso: una pata cada vez, apoyos largos | El cuerpo se hunde en cada apoyo; cabeza lenta; poca inclinación |
| Anfibio | Patas abiertas | Ondulación del cuerpo y de la cola; branquias que laten; la cabeza compensa la ondulación |
| Reptil acorazado | Paso muy lento, apoyos firmes | Casi sin rebote; se resguarda en el caparazón para defenderse |
| Ave | Saltitos con las dos patas | Cabeza muy rápida; alas al moverse o saltar; acicalarse |
| Flotante | Flota a media altura | Vaivén vertical; se inclina hacia donde va; alas rápidas; giro completo como reposo |
| Bípedo | Zancada alterna | Balanceo; rebote moderado |

**Común a todas:**
- respiración (torso arriba y abajo, pecho que se abre);
- mirada y giro de cabeza hacia un objetivo, con límites de giro y de inclinación;
- cola en onda que se propaga por los tramos;
- ciclo de pasos cuya frecuencia sigue a la velocidad;
- inclinación hacia dentro en los giros (velocidad × ritmo de giro);
- frenada (el cuerpo se echa atrás);
- salto con simulación vertical propia: el acompañante da su saltito cuando el dueño salta;
- caída al bajar un escalón de más de 0,5 studs;
- aterrizaje (aplastamiento breve).

**Familia de cada especie (`FamilyBySpecies`, PROPUESTA):**
- Cuadrúpedo → ágil, salvo Defensores y Brutos, que van como pesados (Comalú, Dientón, Chaquiro).
- Anfibio y Serpentino → anfibio.
- Reptil → acorazado.
- Ave, Volador y «Acuático → Ave» → ave.
- Insecto, Fantasmal, Acuático y Astral → flotante.
- Bípedo, Primate, Constructo y Objeto animado → bípedo.
- Planta → pesado; Arácnido y Quimera → ágil.
- Copalia → ave.

---

## 4. Personalidad de los tres iniciales (`CreatureMotion.Species`)

| | Kuachi | Xolumi | Teselo |
|---|---|---|---|
| Familia | Cuadrúpedo ágil | Anfibio | Reptil acorazado |
| Carácter | Curioso, rápido, inquieto | Calmado | Pesado y estable |
| Tempo | ×1,2 | ×0,8 | ×0,75 |
| Reposo variado cada | 3–6 s: olfatear (cabeza que tiembla a 7 Hz), mirar alrededor, rizar la cola | 9–16 s: branquias que laten fuerte, descansar, mirar | 12–22 s: mirar, meterse en el caparazón |
| Rasgo | Cola en **espiral** (giro y cabeceo desfasados en cada tramo) | Ondulación ×0,25; branquias a 0,5 Hz | Apoyos firmes (hundimiento ×0,07) |
| Al jugar | A veces **se hace el muerto** (35 %): se tumba de lado, aguanta y se levanta | — | — |
| Al paseo | Arranca rápido (inercia 0,8) | **Pausas**: se para 0,8–1,6 s cada 4–8 s si no se queda atrás | Inercia 1,8: acelera y frena despacio |
| Al defenderse o avisar | Se agacha | Se agacha | **Se resguarda**: cabeza y patas dentro del caparazón |

El resto de especies toma los valores de su familia.

---

## 5. Máquina de estados (`MotionStateMachine`, pura)

**Estados (21):** Idle, IdleAlt, Walk, Run, Turn, Stop, Jump, Fall, Land, Interact, Eat, Happy, Curious, Warn, Hurt, Stun, Victory, Defeat, Attack, Special y Nexo.

**Prioridad**, de mayor a menor:
1. **fijado** (`hold`: Stun mientras dura, Defeat, Victory, Warn del Opaco);
2. **un solo uso** (`trigger`: Attack, Special, Nexo, Hurt, Happy, Eat, Interact, Curious, Warn);
3. **aire** (Jump, Fall, Land);
4. **locomoción**.

**Histéresis:**

| Transición | Entra | Sale |
|---|---|---|
| Andar | > 0,6 studs/s | < 0,3 studs/s |
| Correr | > velocidad de carrera de la familia | < 85 % de esa velocidad |
| Girar en el sitio | > 1,6 rad/s | < 0,8 rad/s |

- **Frenada:** solo si iba a más de 4 studs/s.
- **Aterrizaje:** solo tras más de 0,15 s en el aire.

**Reposo variado (IdleAlt):** a intervalos aleatorios **deterministas** (Rng con semilla), con las variantes de la personalidad.

**Pruebas:**
- la secuencia Idle → Walk → Run → Walk → Stop → Idle;
- sin cambios de estado con ruido alrededor de los umbrales;
- salto, caída y aterrizaje;
- variantes;
- «hacerse el muerto» solo en Kuachi;
- estados fijados y de un solo uso;
- los 21 estados son alcanzables.

---

## 6. Seguimiento del acompañante (`FollowSteering`, puro)

**Máquina propia:**
- **Idle:** descansa en su sitio.
- **Follow.**
- **CatchUp:** corre si queda a más de 14 studs; vuelve a seguir por debajo de 8.
- **Teleport:** solo por encima de 60 studs.

**Comportamiento:**
- **Sitio:** 4,4 studs detrás y 2,6 a un lado (≈ 5,1 studs). Cambia de lado solo si queda claramente al otro (1,5 studs de histéresis), así no cruza por delante en cada giro.
- **Velocidad:**
  - velocidad estimada del jugador + corrección proporcional;
  - la estimación es asimétrica: acompaña despacio al arrancar y reacciona al instante cuando el jugador frena;
  - máximo 22 studs/s (el jugador anda a 16) y 28 cuando corre.
  - **Aceleración** limitada a 34/inercia.
  - **Frenada** limitada a 90/inercia; ×3 («frenada de confort») si va hacia el jugador por debajo de 4,5 studs.
- **Giro:** como mucho 7 rad/s. Si mira al lado contrario, primero gira y luego acelera.
- **Jugador:**
  - si el camino al sitio cruza su radio personal (2,6 studs), lo rodea por la tangente;
  - como garantía, nunca termina un paso dentro de ese radio.
- **Obstáculos (raycast inyectado):**
  - un rayo hacia donde va y «bigotes» a ±35° y ±70°, 8 veces por segundo;
  - mantiene el lado de esquiva 0,5 s;
  - nunca avanza más allá de un impacto.
  - En el juego el rayo es horizontal a 1,2 studs del suelo y solo cuenta paredes (normal con |Y| < 0,6).
- **Varios jugadores:**
  - `WorldController` mantiene un acompañante por jugador con estado público;
  - lejos de la cámara (> 140 studs) se oculta y avanza 4 pasos por segundo sin rayos ni animación.

**Pruebas (`FollowSteering.spec`):**
- distancia entre 4 y 6 studs andando y parado;
- sin cambios de signo de la velocidad en línea recta (0 en X, ≤ 2 laterales);
- quieto sin temblar con el jugador oscilando;
- aceleración y giro dentro de sus límites;
- nunca entra en el radio del jugador aunque este camine hacia él o su sitio quede al otro lado;
- teletransporte solo por encima de 60 studs;
- rodea un muro simulado y llega a su sitio.

---

## 7. Combate y evolución

**Combate:**
- La secuencia de cada jugada (`VFX_SYSTEM.md` §5) dispara en el atacante `Attack` (básico), `Special` (especial, curación, estado; variante `Guard` en escudos: Teselo se resguarda) o `Nexo`.
- En quien recibe el impacto, su reacción: `Hurt`, `Stun`, `Special` (escudo o reflejo), `Happy` (curación) o `Victory`.
- Tras cada turno, los estados del servidor fijan la postura:
  - aturdido, paralizado o dormido → `Stun`;
  - sin fuerzas → `Defeat` («cansado», nunca dramático).
- Al restaurar al Opaco: `Happy`. Al ganar: `Victory`.
- Los dos combatientes se miran.
- La embestida la da la secuencia.

**Evolución:** dentro del `ViewportFrame`, el Brote toma la pose de carga del `Nexo` durante la preparación y la energía; el Tallado posa con `Victory` al presentarse.

---

## 8. LOD y coste

- **De 0 a 60 studs de la cámara:** cada frame.
- **De 60 a 140:** un frame de cada dos, sin aura (prueba incluida).
- **Más de 140:** nada; el modelo se oculta.
- **Por criatura y frame:**
  - un `CFrame` por hueso (≤ 25) y uno por pieza;
  - una sola llamada a `BulkMoveTo`;
  - las listas se reutilizan entre frames.
- **Medición pendiente en Studio:** 8 monstruos a 30 fps en el teléfono base (Biblia p. 120).

---

## 9. Qué falta y qué verificar en Studio

1. **Aspecto real:**
   - amplitudes de paso, cola, cabeza y respiración en cada familia;
   - que los blockouts no se «rompan» al girar piezas alrededor de los pivotes calculados (sobre todo las colas encadenadas y las cabezas de los arquetipos genéricos).
2. **Seguimiento en el Valle real:**
   - rampas y escalones (el rayo de pared ignora pendientes con |normal.Y| ≥ 0,6);
   - puentes, agua y el radio con varios jugadores.
3. **Modelos importados:**
   - orientación de reposo de los `Bone`;
   - nombres;
   - escala con `Model:ScaleTo`;
   - piel y deformación con los deltas;
   - `PivotTo` por frame frente a anclar la raíz.
4. **Pausas de Xolumi y «hacerse el muerto» de Kuachi:** que se lean y no molesten al jugar.
5. **Opacos en guardia al acercarse** (16 studs) y presentación de Copalia.
6. **Faltan:**
   - pistas de animación hechas a mano (`AN_…`, ninguna aprobada);
   - mezcla con las procedurales;
   - las familias insecto, serpiente y objeto vivo, que la Biblia visual nombra y aquí se asimilan a otras (§3);
   - comer y acariciar en el santuario (los estados existen, falta llamarlos desde las interacciones).

---

## 10. Decisiones propuestas

Pendientes de aprobación humana; no están en `DESIGN_DECISIONS.md`.

- **AN-P1 · Familia de movimiento por especie:** la tabla `FamilyBySpecies` de §3, incluidos los Cuadrúpedos Defensores y Brutos como pesados.
- **AN-P2 · Personalidad de los iniciales:** las cifras de §4 (tempo, intervalos, 35 % de «hacerse el muerto», pausas de Xolumi). La Biblia y Genesis describen el carácter, no los números.
- **AN-P3 · Distancia del acompañante:** sitio a ≈ 5,1 studs (4,4 detrás y 2,6 a un lado) y radio personal de 2,6. El encargo pide 4–6.
- **AN-P4 · El acompañante salta cuando salta su dueño.** Es solo visual.
- **AN-P5 · Los Opacos se ponen en guardia** cuando el jugador se acerca a menos de 16 studs.
- **AN-P6 · Nombres de huesos solo del blockout:** `gill_L/R` y `wing_L/R`. Si los modelos futuros tienen branquias o alas con hueso, conviene usar estos nombres en `asset.json`.
