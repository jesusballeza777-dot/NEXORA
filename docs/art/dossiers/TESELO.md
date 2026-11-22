# Dossier de producción · Teselo → Mitlaxis

> ## Estado: pendiente de aprobación humana
> Rediseño propuesto v0.1 · 21 nov 2026. Parte de `docs/art/STARTERS_REDESIGN.md`, opción A «Fortaleza
> celeste». Nada de este dossier está aprobado. El modelo actual del juego es un **blockout**
> (`Config/Visuals.luau → teselo`, arquetipo `Tortoise`, `assetStatus = "Blockout"`). No existe concepto 2D
> ni malla generada. Cifras con «(Biblia p. N)»: de la Biblia; el resto es **propuesta**.

---

## 1. Identidad

- **Historia en una frase:** una tortuga de mosaico de grecas que, al tallarse, se vuelve una fortaleza
  escalonada que sostiene un pedazo de cielo nocturno (`STARTERS_REDESIGN.md`).
- **Núcleo que no se toca (Biblia §02):** tortuga + eco del mito de la tortuga que sostiene el cielo +
  grecas de Mitla; caparazón-fortaleza y disco o anillos celestes.
- **Rasgo firma** (`Visuals.signatureFeature`): caparazón de grecas (teselas) que evoluciona a terrazas con
  disco de cielo.
- **Carácter (propuesta):** curioso, terco y protector; lento pero nunca se rinde.
- **Huevo inicial:** idéntico a los otros dos; al acercarse late en color **greca** (Biblia p. 27).

## 2. Datos de la Biblia

| Campo | Valor | Biblia |
|---|---|---|
| Número · id | 3 · `teselo` | p. 52 |
| Brote → Tallado | Teselo → Mitlaxis (v4: Teselín → Mitlaurum) | p. 28 |
| Rareza | Común · presupuesto 100 · coste 2 (Brote 1) · Tallado a nivel 12 · incubación 5 min | p. 35, 43, 115, 89 |
| Elemento | Tierra · vence a Rayo y Metal · pierde contra Aire y Astral | p. 48 |
| Rol · familia · bioma | Defensor · Reptil, tortuga terrestre · Valle Copal | p. 51 |
| Talento | **Caparazón de Grecas:** recibe −20 % de daño de los ataques básicos | p. 51 |
| Firma | **Astrolabio de Piedra:** especial · 60 · 2 Savia; +25 % DEF propia y −10 % VEL del rival 2 turnos | p. 51 |
| Golpe Nexo | **Corazón de Montaña:** 125 · 3 Savia; +30 % DEF al equipo 2 turnos (nivel 20, en Tallado) | p. 51, 115 |
| Repertorio | Pisotón (45) · Lanza de Barro (40) · Arena en los Ojos (30) · Muralla de Adobe (bloqueo) · Grieta (75) | p. 51 |
| Atributos Brote → Tallado nv 50 | VID 18→25 · ATQ 12→17 · DEF 20→28 · ESE 10→15 · VEL 10→15 | p. 51 |
| Mezcla mítica | Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla | p. 17 |
| Procedencia | Tortuga del desierto · mosaico de grecas de Mitla · tortuga que sostiene el cielo (eco chino de Ao) · México + eco chino | p. 51 |
| Claves 2D | Domo escalonado · anillos dorados · piedra ocre y jade | p. 51 |
| Brote (Biblia) | Caparazón alto de teselas pulidas, patas columnares y cara curiosa; **sin vegetación ni picos** | p. 51 |
| Tallado (Biblia) | Tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que giran; sobre el lomo flota un disco de cielo nocturno | p. 51 |
| Primer Opaco | Opaco de Rayo (en el slice: Zizi Brote nv 1, `valle_r1_e1`) | p. 48 |

## 3. Hoja de diseño · Brote (Teselo)

**Silueta:** caparazón alto en domo de teselas pulidas, patas como columnas cortas y una cabeza pequeña y
curiosa asomada. Nada vegetal ni picos en el caparazón.

| Proporción (propuesta salvo cita) | Valor |
|---|---|
| Tamaño de referencia | 2,5 studs de largo de caparazón |
| Altura total | 3 cabezas; el caparazón ocupa el 60 % (`STARTERS_REDESIGN.md`) |
| Largo del caparazón | 4 cabezas |
| Patas | columnas de 1 cabeza de alto y 0,6 de diámetro |
| Cuello | asoma 0,7 cabezas; se retrae casi entero |
| Ojos | redondos, 32 % del ancho de la cara (la cabeza es pequeña: ojos al máximo del rango) |

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Piedra ocre: piel y teselas base | `#9C8462` | 50 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Teselas crema | `#C4A87A` | 25 % | `Visuals` (propuesta) |
| Teselas de jade | `#3E967A` | 15 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Juntas del mosaico | `#786248` | 10 % | propuesta (ocre oscuro del Tallado) |
| Ojo · brillos | `#161412` · `#FFFFFF` | — | `Visuals` |
| Rubor · boca | `#FF929E` · `#281816` | — | `Visuals.Face` |

Familias: ocre (piedra, crema y juntas) + jade = **2**. El Brote no lleva emisivo: su rasgo firma es el
mosaico (propuesta).

**Materiales:** piedra pulida (rugosidad 0,55–0,65) con juntas en el normal; jade pulido (0,3); piel lisa.
**Grecas:** patrón **propio** del equipo inspirado en el escalonado de Mitla, no calcado de fotografías.

**Cara:** ojos grandes con dos brillos, pico pequeño y redondeado, rubor suave, sonrisa curiosa; sin ceja.

## 4. Hoja de diseño · Tallado (Mitlaxis)

**Silueta:** caparazón en tres terrazas escalonadas, como un basamento, rodeado por dos anillos de astrolabio
que giran, y un disco de cielo nocturno flotando sobre el lomo. El disco es la pieza que rompe la silueta;
nada vegetal en el caparazón (`STARTERS_REDESIGN.md`).

| Proporción (propuesta salvo cita) | Valor |
|---|---|
| Escala | ×1,5 del Brote (`Visuals`; rango ×1,4–×1,7, Biblia p. 20) |
| Altura hasta la cima del caparazón | 4 cabezas (la cabeza baja de proporción) |
| Terrazas | 3; cada una 0,8 de la anterior en planta |
| Anillos | exterior 1,3 × el largo del caparazón; interior 1,1 ×; inclinados ± 20° |
| Disco | diámetro 2,5 cabezas; flota 0,5 cabezas sobre la terraza alta (hueco visible en la silueta) |
| Patas | columnas de piedra con uñas de piedra |
| Arma natural | la Biblia no la fija. Propuesta: pico córneo y uñas de piedra en las patas-columna |
| Ojos | almendrados, largo = 22 % del ancho de la cara |

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Piedra ocre: piel y terrazas | `#786248` | 50 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Teselas claras | `#B09264` | 20 % | `Visuals` (propuesta) |
| Jade | `#348A70` | 15 % | `Visuals` (propuesta) |
| Anillos de astrolabio, ocre dorado | `#ECC460` | 8 % | `STARTERS_REDESIGN.md` (propuesta) |
| Disco de cielo nocturno | `#1C2446` | 5 % | `STARTERS_REDESIGN.md` (propuesta) |
| Estrellas del disco y surcos (emisivo) | `#F6D26E` | ≤ 3 % | `Visuals` (propuesta) |
| Iris · esclerótica | `#CE963C` · `#F6EEDC` | — | `Visuals` (propuesta; Tierra `#B8844C`) |

Familias: ocre (piedra, teselas y anillos ocre dorado) + jade + azul noche = **3**. Si los anillos se leyeran
como metal y no como ocre, serían 4 familias y metal en un Común, fuera de la regla de la Biblia (p. 26):
por eso van como **pigmento ocre dorado mate** (metal ≤ 0,2), pendiente de decisión (`PRODUCTION_SPECS.md` §3.3).

**Materiales:** piedra y mosaico (0,55–0,75) con grecas en relieve horneadas; jade (0,3); anillos de pigmento
dorado mate; disco con estrellas pintadas y máscara emisiva; luz cálida solo en los surcos de las terrazas.

**Cara y mirada:** la misma cara del Brote con el pico más marcado; ojo almendrado con iris ámbar, pupila
rasgada, un brillo y ceja de piedra marcada; mejillas que se inflan cuando se pone terco.

## 5. Lo que persiste entre formas

- [ ] Cabeza pequeña con pico redondeado y ojos en el mismo sitio.
- [ ] Piedra ocre como color base y mosaico de teselas ocre, crema y jade.
- [ ] Patas columnares.
- [ ] Caparazón de grecas (domo → terrazas) sin ningún elemento vegetal.
- [ ] Prueba de pareja a 128 px.

Cambios de etapa (`STARTERS_REDESIGN.md`): domo liso → terrazas · ojos redondos curiosos → almendrados con
iris ámbar · sin adornos → anillos y disco celeste · tamaño compacto → fortaleza ×1,5.

## 6. Hoja de giro

- [ ] Brote y Tallado en frente, perfil, espalda y 3/4, a la misma escala, rejilla en cabezas.
- [ ] Cabeza del Tallado en tres vistas con la mirada feroz.
- [ ] Vista cenital de ambos caparazones con el patrón de teselas completo (sirve de base para el mapa de altura).
- [ ] Perfil del Tallado: hueco entre la terraza alta y el disco; inclinación de los anillos.
- [ ] Pose con cabeza y patas retraídas (para «cansado» y la reacción de «pop»).
- [ ] Versión plana, versión con materiales y pose de unión neutra.

## 7. Hoja de expresiones (seis por forma)

| Expresión | Brote | Tallado | Controles del rig |
|---|---|---|---|
| Curioso | Cuello estirado, ojos muy abiertos | Mirada alta y atenta | `Neck`, `Lid` |
| Terco | Mejillas infladas | Mejillas infladas y ceño | `Cheek_L/R`, `Brow` (Tallado) |
| Desafío | Se planta con las patas abiertas | Se planta; los anillos se detienen | `Leg`, script de anillos |
| Ataque | Pisotón con boca abierta | Pisotón con el pico abierto | `Jaw`, `Leg` |
| Victoria | Salta en el sitio | Los anillos giran rápido | script de anillos |
| Cansado | Se esconde en el caparazón | Se esconde; el disco se apaga al 30 % | `Neck`, `Leg`, emisivo |

Fuente: `STARTERS_REDESIGN.md`. Nunca llanto ni dolor explícito.

## 8. Animaciones

Topes de la Biblia: ataques ≤ 2,5 s; Golpe Nexo ≤ 4 s (p. 40). Resto: propuesta.

**Anillos y disco:** `Ring_Outer`, `Ring_Inner` y `Disc` no se animan en ningún clip; un script cliente
los gira (exterior 1 vuelta cada 8 s, interior 1 cada 5 s en sentido contrario, disco 1 cada 20 s;
propuesta). Los clips solo envían marcadores (`RingsAlign`, `RingsFast`, `RingsStop`) que el script
interpreta.

| Clip | Forma | Duración | Notas de acción y tiempo |
|---|---|---|---|
| `Idle` | B · T | 3,0 s | Estira el cuello y mira alrededor; los anillos giran solos |
| `IdleFidget` | B · T | 4,0 s | Mete y saca la cabeza; parpadeo doble |
| `Walk` · `Run` | B · T | 0,9/1,1 s · 0,6/0,7 s | Pasos pesados con micro-temblor al apoyar; muy lento y estable. Teselo camina más lento que la norma por su VEL |
| `Happy` | B · T | 1,5 s | Se mete en el caparazón y asoma con un «pop» |
| `Eat` | B · T | 2,0 s | Mordiscos lentos con el pico |
| `Sleep` | B · T | 4,0 s | Retraído a medias; disco al 30 % |
| `BattleIdle` | B · T | 2,0 s | Plantado, cabeza baja y adelantada |
| `AttackBasic` | B · T | ≤ 1,2 s, impacto a 0,5 s | Pisotón; Lanza de Barro (escupe barro); Arena en los Ojos (patada lateral de arena) |
| `AttackSpecial` | B · T | ≤ 2,0 s | Muralla de Adobe (alza un muro de teselas delante); Grieta (pisotón que abre una grieta hacia el rival) |
| `AttackSignature` | B · T | ≤ 2,5 s | Astrolabio de Piedra: en el Tallado los anillos se alinean (`RingsAlign` a 0,8 s) y las grecas se encienden; en el Brote las teselas del domo se iluminan en anillo |
| `GolpeNexo` | T | ≤ 4,0 s | Corazón de Montaña: doble pisotón, las terrazas se iluminan de abajo arriba y el disco proyecta un domo de grecas sobre el equipo |
| `Hit` | B · T | 0,5 s | Encoge el cuello; con un básico, destello de las grecas (talento) |
| `RestEnter` · `Rest` | B · T | 1,5 s · 4 s | Se retrae en el caparazón, ojos cerrados asomando, respira |
| `Victory` | B · T | 1,8 s | Salto en el sitio (Brote) · `RingsFast` (Tallado) |
| `Hatch` | B | 1,5 s | El huevo se abre y asoma primero la cabeza |
| `EvolveAnticipation` · `EvolveReveal` | B · T | 1,5 s · 2,0 s | El domo se agrieta en terrazas → las terrazas suben, se forman los anillos y se enciende el disco (P12) |
| `Restore` | B · T | 1,8 s | Vuelve primero el color del mosaico (rasgo firma); al final se encienden el disco y los anillos |

## 9. Carta

| Elemento | Valor |
|---|---|
| Fondo | Valle Copal en hora dorada (láminas p. 51); el disco nocturno contrasta con el cielo ámbar |
| Marco y gema | Común, liso, `#D6C8B0`; gema arriba a la izquierda |
| Icono de elemento | Tierra, arriba a la derecha |
| Pedestal | Disco de luz en `#B8844C` al 40 % (propuesta) |
| Aura | Ninguna (Común) |
| Pose · encuadre | Brote de 3/4 con la cabeza asomada hacia cámara, 55 % de la altura · Tallado de 3/4 con el disco dentro del área segura, por debajo de la gema y los iconos, 70 % de la altura incluyendo el disco |
| Álbum | Silueta oscura con el número 3: el hueco del disco debe leerse en negro |

## 10. Variante Opaco

| Zona | Normal | Opaco (propuesta, `PRODUCTION_SPECS.md` §6) |
|---|---|---|
| Piedra Brote · Tallado | `#9C8462` · `#786248` | `#888583` · `#6D6A69` |
| Teselas crema Brote · Tallado | `#C4A87A` · `#B09264` | `#A5A29E` · `#95918D` |
| Jade Brote · Tallado | `#3E967A` · `#348A70` | `#737E7B` · `#6A7473` |
| Anillos | `#ECC460` | `#BCB7AC`, quietos |
| Disco · estrellas | `#1C2446` · `#F6D26E` (emisivo) | `#36373D` · sin estrellas |
| Iris del Tallado | `#CE963C` | `#9D968C`, con pupila y un brillo |

- Opaco: los anillos se detienen y el disco se apaga, sin estrellas (como Noctelia opacada, Biblia p. 15).
  Cabeza medio retraída; niebla `#9696A0` a los pies.
- Restauración: vuelve el color del mosaico, los anillos arrancan y al final se encienden las estrellas.

## 11. Especificación técnica

| Concepto | Brote | Tallado |
|---|---|---|
| Triángulos (Biblia p. 120) · objetivo | 2 500–4 000 · 3 000–3 600 | 4 000–6 500 · 5 000–6 000 (caparazón ≤ 40 %, anillos + disco ≤ 15 %) |
| Textura | 1024² | 1024² |
| MeshParts | `Body` | `Body` (con anillos y disco) + `Glow` (estrellas y surcos) |
| Emisores de aura | 0 (Común) | 0 |
| Huesos (máx. 18 / 30, Biblia p. 120) | **16:** `Root`, `Pelvis`, `Shell`, `Neck_01`, `Neck_02`, `Head`, `Jaw`, `Lid_L`, `Lid_R`, `Cheek_L`, `Cheek_R`, `Leg_FL`, `Leg_FR`, `Leg_BL`, `Leg_BR`, `Tail` | **25:** `Root`, `Pelvis`, `Shell`, `Neck_01`, `Neck_02`, `Head`, `Jaw`, `Lid_L`, `Lid_R`, `Brow_L`, `Brow_R`, `Cheek_L`, `Cheek_R`, `Leg_FL_01/02`, `Leg_FR_01/02`, `Leg_BL_01/02`, `Leg_BR_01/02`, `Tail`, `Ring_Outer`, `Ring_Inner`, `Disc` |
| Anexos | Comunes de `PRODUCTION_SPECS.md` §7; `FX_Signature` en `Shell` (cima) | `FX_Signature` en `Disc` |
| Pesos rígidos | Caparazón al 100 % en `Shell` | Caparazón en `Shell`; anillos y disco al 100 % en su hueso |

La retracción se hace trasladando `Neck_01`/`Neck_02` y rotando las patas hacia dentro; la abertura del
caparazón debe dejar sitio a la cabeza retraída sin que la atraviese.

## 12. Originalidad y revisión cultural

- Nada vegetal, ni árbol, ni rocas, ni estructuras tipo cañón sobre el caparazón (Biblia p. 51;
  `STARTERS_REDESIGN.md`). Prueba de parecido especialmente estricta: las tortugas con algo en el lomo son
  un patrón muy visto del género.
- El mito chino de Ao es eco de tema (sostener el cielo), sin iconografía china concreta.
- Grecas de Mitla: patrimonio arquitectónico, no símbolo sagrado; aun así se diseña un patrón propio y se
  revisa con fuentes antes de la aprobación 2D.

## 13. Lista de aceptación

**2D**
- [ ] Tres siluetas a 64 px y elección registrada; el disco se lee separado del caparazón.
- [ ] Brote 3/4, Tallado 3/4 con el Brote como referencia y cabeza del Tallado en tres vistas.
- [ ] Hojas de giro, 6 expresiones por forma, paleta y materiales, carta.
- [ ] Patrón de grecas propio aprobado.
- [ ] Decisión registrada sobre el arma natural (§4) y el dorado en un Común (`PRODUCTION_SPECS.md` §3.3).
- [ ] Prueba de pareja y de parecido superadas; revisión cultural firmada.

**3D**
- [ ] Anillos y disco girados por script sin conflicto con el `Animator`; alineación en la Firma.
- [ ] Retracción de cabeza y patas sin atravesar el caparazón.
- [ ] Triángulos, huesos y texturas dentro de §11; clips de §8 dentro de sus topes.
- [ ] Opaco ↔ restaurado reversible.
- [ ] Lista de `PRODUCTION_SPECS.md` §11 completa; `Visuals.teselo` aprobado con `modelAsset` real; `./scripts/check.sh` en verde.

## 14. Registro de aprobación

| Fecha | Estado | Versión de la hoja | Aprueba | Observaciones |
|---|---|---|---|---|
| 2026-11-21 | Rediseño propuesto — pendiente de aprobación | v0.1 (este dossier) | — | Sin revisión humana todavía |
