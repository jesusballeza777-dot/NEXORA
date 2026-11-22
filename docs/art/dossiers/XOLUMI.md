# Dossier de producción · Xolumi → Xolossus

> ## Estado: pendiente de aprobación humana
> Rediseño propuesto v0.1 · 21 nov 2026. Parte de `docs/art/STARTERS_REDESIGN.md`, opción A «Dragón de
> río». Nada de este dossier está aprobado. El modelo actual del juego es un **blockout**
> (`Config/Visuals.luau → xolumi`, arquetipo `Axolotl`, `assetStatus = "Blockout"`). No existe concepto 2D
> ni malla generada. Cifras con «(Biblia p. N)»: de la Biblia; el resto es **propuesta**.

---

## 1. Identidad

- **Historia en una frase:** un ajolote de barro negro que se repara con oro cada vez que se rompe y que,
  al tallarse, se yergue como un dragón de río (`STARTERS_REDESIGN.md`).
- **Núcleo que no se toca (Biblia §02):** ajolote + tema de transformarse para no desaparecer (**sin
  representar ninguna deidad**) + barro negro de Oaxaca; branquias y regeneración.
- **Rasgo firma** (`Visuals.signatureFeature`): branquias plumosas turquesa y barro negro bruñido.
- **Carácter (propuesta):** tranquilo, paciente, cuidador; sonríe siempre.
- **Huevo inicial:** idéntico a los otros dos; al acercarse late en color **barro** (Biblia p. 27).

## 2. Datos de la Biblia

| Campo | Valor | Biblia |
|---|---|---|
| Número · id | 2 · `xolumi` | p. 52 |
| Brote → Tallado | Xolumi → Xolossus (v4: Xolumi → Atlaxolotl) | p. 28 |
| Rareza | Común · presupuesto 100 · coste 2 (Brote 1) · Tallado a nivel 12 · incubación 5 min | p. 35, 43, 115, 89 |
| Elemento | Agua · vence a Fuego y Metal · pierde contra Flora y Rayo | p. 48 |
| Rol · familia · bioma | Soporte · Anfibio · Valle Copal | p. 50 |
| Talento | **Regeneración:** recupera 6 % de VID al final de cada turno en el que no recibió daño | p. 50 |
| Firma | **Cicatriz Dorada:** especial · 0 · 2 Savia; cura 25 % y gana +15 % DEF 2 turnos | p. 50 |
| Golpe Nexo | **Diluvio de Cántaros:** 120 · 3 Savia; limpia los efectos negativos del equipo (nivel 20, en Tallado) | p. 50, 115 |
| Repertorio | Chorro (40) · Ola Corta (35) · Burbuja Fría (35) · Marea Lenta (65) · Manantial (cura 30 %) | p. 50 |
| Atributos Brote → Tallado nv 50 | VID 17→24 · ATQ 10→14 · DEF 13→19 · ESE 19→27 · VEL 11→16 | p. 50 |
| Mezcla mítica | Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la deidad) + barro negro de Oaxaca | p. 17 |
| Procedencia | Ajolote · barro negro de Oaxaca · reparación dorada de cerámica · México | p. 50 |
| Claves 2D | Seis patas y cabeza ancha · branquias de humo · negro bruñido con oro | p. 50 |
| Brote (Biblia) | Cabeza ancha y sonrisa tranquila; tres pares de branquias plumosas turquesa; piel negra pulida como cerámica de San Bartolo Coyotepec | p. 50 |
| Tallado (Biblia) | Ajolote colosal de seis patas, erguido como un dragón de río; branquias de humo de copal, cicatrices doradas y boca con colmillos pequeños | p. 20, 50 |
| Primer Opaco | Opaco de Fuego (en el slice: Comalú Brote nv 1, `valle_r1_e1`) | p. 48 |

## 3. Hoja de diseño · Brote (Xolumi)

**Silueta:** cabeza muy ancha y plana, sonrisa tranquila, tres pares de branquias plumosas a los lados de la
cabeza, cuerpo corto de cuatro patas y cola corta con aleta. Criatura horizontal: su tamaño de referencia
es el largo.

| Proporción (propuesta salvo cita) | Valor |
|---|---|
| Tamaño de referencia | 2,5 studs de largo sin cola |
| Cabeza | 55 % del largo cabeza + cuerpo (`STARTERS_REDESIGN.md`); ancho = 1,3 × el largo de la cabeza |
| Altura | 1 cabeza (hasta lo alto de las branquias, 1,3 cabezas) |
| Cola | 0,9 cabezas con aleta |
| Branquias | 3 por lado, la central la más larga (0,6 cabezas) |
| Patas | cuatro, cortitas, 0,35 cabezas |

**Ojos (decisión a revisar):** `STARTERS_REDESIGN.md` pide «ojos pequeños y separados (rasgo real del
ajolote) pero brillantes», y la Biblia pide en todo Brote ojos grandes y redondos con dos brillos (p. 20–21).
Propuesta de conciliación: ojos **redondos, con dos brillos y en el límite inferior del tamaño del Brote**
(28 % del ancho de la cara, `PRODUCTION_SPECS.md` §4), colocados muy separados en los bordes de la cabeza
ancha. Así parecen pequeños por la anchura de la cabeza sin dejar de cumplir la regla. Requiere decisión
humana.

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Barro negro bruñido | `#22242A` | 65 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Vientre | `#3A3E48` | 15 % | `Visuals` (propuesta) |
| Branquias turquesa | `#40CEC4` | 15 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Puntas de las branquias (emisivo) | `#6EECDC` | ≤ 5 % | `Visuals` (propuesta) |
| Esclerótica · ojo · brillos | `#FAFAF6` · `#0E0E10` · `#FFFFFF` | — | `Visuals` |
| Boca sobre cuerpo oscuro · rubor | `#EC96A0` · `#FF929E` | — | `Visuals.Face` |

Familias: negro neutro + turquesa = **2**.

**Materiales:** cerámica bruñida (rugosidad 0,15–0,30) con brillo especular alto; branquias mates y
aterciopeladas (0,6) con la pluma en el normal. Sin metal.

**Cara:** sonrisa ancha y tranquila en `#EC96A0`, rubor pequeño bajo los ojos, sin ceja, sin dientes visibles.

## 4. Hoja de diseño · Tallado (Xolossus)

**Silueta:** seis patas, torso erguido 30°, cabeza alta y una corona de branquias de humo de copal que se
eleva: seis patas + corona = silueta única (`STARTERS_REDESIGN.md`).

| Proporción (propuesta salvo cita) | Valor |
|---|---|
| Escala | ×1,6 del Brote (`Visuals`; rango ×1,4–×1,7, Biblia p. 20) |
| Altura hasta la coronilla | 3 cabezas (con la corona de branquias, 4) |
| Largo cabeza + cuerpo | 4,5 cabezas; cola 2 cabezas con aleta dorada |
| Patas | seis; las delanteras más largas para sostener el torso erguido |
| Ojos | almendrados, largo = 20 % del ancho de la cara, en el mismo sitio que en el Brote |
| Arma natural | colmillos pequeños en la misma sonrisa ancha (Biblia p. 20) |

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Barro negro bruñido | `#16181E` | 60 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Vientre | `#282A32` | 15 % | `Visuals` (propuesta) |
| Branquias de humo de copal | `#40CEC4` → `#78F0E2` (borde emisivo) | 12 % | `Visuals` (propuesta) |
| Oro de reparación: vetas y aleta | `#D6AA4A` | 8 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Luz en los surcos más hondos (emisivo) | `#78F0E2` | ≤ 5 % | `Visuals` (propuesta) |
| Iris · esclerótica | `#46C8E6` · `#F0ECDC` | — | `Visuals` (propuesta; Agua `#40AAD6`) |

Familias: negro + turquesa + oro = **3**.

**Materiales:** cerámica bruñida; vetas de **oro de reparación** que siguen las líneas del barro como una
pieza reparada, **nunca como heridas**. En un Común el oro va como pigmento dorado mate (metal ≤ 0,2),
pendiente de decisión (`PRODUCTION_SPECS.md` §3.3). Branquias de humo como volutas de geometría con
degradado; **sin partículas** (Común = 0 emisores).

**Diferenciación con Cantagólem** (también con grietas de oro, Biblia p. 55): Xolossus es barro **negro**
bruñido con vetas de oro **curvas y orgánicas**; Cantagólem es barro **rojo** de mercado con grecas blancas y
grietas de oro **angulosas**. Nunca compartir silueta de vasija (opción B descartada en `STARTERS_REDESIGN.md`).

## 5. Lo que persiste entre formas

- [ ] Cabeza ancha y plana con la misma sonrisa y los ojos en los bordes.
- [ ] Tres pares de branquias turquesa en el mismo arranque (plumosas → humo de copal).
- [ ] Barro negro bruñido como color base en ambas formas.
- [ ] Cola con aleta (lisa → con aleta dorada).
- [ ] Prueba de pareja a 128 px.

Cambios de etapa (`STARTERS_REDESIGN.md`): cuatro patas → seis · horizontal → erguido · branquias plumosas
→ humo de copal · barro liso → barro con cicatrices doradas · sonrisa → colmillos pequeños con la misma cara.

## 6. Hoja de giro

- [ ] Brote y Tallado en frente, perfil, espalda y 3/4, a la misma escala, rejilla en cabezas.
- [ ] Cabeza del Tallado en tres vistas con la mirada feroz.
- [ ] Vista cenital del Brote para fijar el ancho de la cabeza y la separación de los ojos.
- [ ] Perfil del Tallado: ángulo del torso (30°) y apoyo de las seis patas.
- [ ] Mapa de las vetas doradas (dónde nacen y por dónde corren) en las cuatro vistas.
- [ ] Versión plana, versión con materiales y pose de unión neutra.

## 7. Hoja de expresiones (seis por forma)

| Expresión | Brote | Tallado | Controles del rig |
|---|---|---|---|
| Neutral | Sonriente | Sonrisa serena, mirada alta | `Lids` |
| Calma | Ojos entrecerrados | Ojos entrecerrados, branquias lentas | `Lids`, `Gill` |
| Desafío | Branquias erizadas | Branquias de humo abiertas en corona | `Gill`, `Brow` (Tallado) |
| Ataque | Boca abierta | Boca abierta con colmillos | `Jaw` |
| Victoria | Branquias en abanico | Corona en abanico y cabeza alta | `Gill`, `Neck` |
| Cansado | Se recuesta en el suelo | Se recuesta sobre las seis patas | `Spine`, `Lids` |

Fuente: `STARTERS_REDESIGN.md`. Nunca llanto ni dolor explícito.

## 8. Animaciones

Topes de la Biblia: ataques ≤ 2,5 s; Golpe Nexo ≤ 4 s (p. 40). Resto: propuesta.

| Clip | Forma | Duración | Notas de acción y tiempo |
|---|---|---|---|
| `Idle` | B · T | 3,0 s | Las branquias ondulan al ritmo de la respiración (desfase de 0,15 s entre pares); parpadeo lento |
| `IdleFidget` | B · T | 3,0 s | Bosteza con la boca ancha y sacude las branquias |
| `Walk` · `Run` | B · T | 0,7/0,9 s · 0,45/0,55 s | Ondulación lateral de todo el cuerpo, como si nadara en tierra |
| `Happy` | B · T | 1,5 s | Se ríe y suelta un chorrito de agua hacia arriba. `STARTERS_REDESIGN.md` propone burbujas: limitarlas a 2–3 para no acercarse al patrón «anfibio con burbujas» |
| `Eat` | B · T | 2,0 s | Bocado rápido de ajolote (succión) |
| `Sleep` | B · T | 4,0 s | Tumbado, branquias quietas, emisivo al 30 % |
| `BattleIdle` | B · T | 2,0 s | Branquias medio erizadas; el Tallado erguido |
| `AttackBasic` | B · T | ≤ 1,2 s, impacto a 0,4 s | Chorro (desde la boca); Ola Corta (golpe de cola que levanta agua); Burbuja Fría |
| `AttackSpecial` | B · T | ≤ 2,0 s | Marea Lenta (marea alrededor del rival); Manantial (brota agua bajo el aliado) |
| `AttackSignature` | B · T | ≤ 2,5 s | Cicatriz Dorada: Tallado, las vetas brillan y se cierran; Brote, líneas turquesa tenues que se alisan |
| `GolpeNexo` | T | ≤ 4,0 s | Diluvio de Cántaros: se alza sobre las patas traseras, la corona de humo sube y caen chorros de agua con forma de cántaro sobre el equipo |
| `Hit` | B · T | 0,5 s | Retrocede y cierra las branquias |
| `RestEnter` · `Rest` | B · T | 1,5 s · 4 s | Se recuesta con la barbilla en el suelo, ojos cerrados, respira |
| `Victory` | B · T | 1,8 s | Branquias en abanico; el Tallado alza la cabeza |
| `Hatch` | B | 1,5 s | Asoma la cabeza ancha y sacude las branquias |
| `EvolveAnticipation` · `EvolveReveal` | B · T | 1,5 s · 2,0 s | El barro se agrieta en líneas de luz → se yergue, brotan dos patas más y las grietas se sellan en oro (P12) |
| `Restore` | B · T | 1,8 s | Las branquias recuperan primero el turquesa y luego vuelve el brillo del barro |

**Talento Regeneración:** al final de un turno sin daño, destello turquesa breve en las branquias (efecto de
combate, no aura).

## 9. Carta

| Elemento | Valor |
|---|---|
| Fondo | Valle Copal en hora dorada con el río y las chinampas en segundo plano (láminas p. 50) |
| Marco y gema | Común, liso, `#D6C8B0`; gema arriba a la izquierda |
| Icono de elemento | Agua, arriba a la derecha |
| Pedestal | Disco de luz en `#40AAD6` al 40 % (propuesta) |
| Aura | Ninguna (Común) |
| Pose · encuadre | Brote de 3/4 con la cabeza hacia cámara, 55 % de la altura · Tallado erguido de 3/4 con la corona de branquias dentro del área segura, 65 % de la altura |
| Lectura | El negro bruñido necesita contraluz cálido del fondo para separar la silueta |
| Álbum | Silueta oscura con el número 2 |

## 10. Variante Opaco

| Zona | Normal | Opaco (propuesta, `PRODUCTION_SPECS.md` §6) |
|---|---|---|
| Barro Brote · Tallado | `#22242A` · `#16181E` | `#363638` · `#2D2D2F` |
| Branquias Brote | `#40CEC4` (puntas `#6EECDC`) | `#90A1A1` (`#ACBCBB`), **sin emisión** |
| Oro del Tallado | `#D6AA4A` | `#A8A399` |
| Iris del Tallado | `#46C8E6` | `#92A1A6`, con pupila y un brillo |

- El negro bruñido pierde el brillo: rugosidad + 0,2 en `SA_Opaco` (propuesta), para que se lea mate y
  apagado. Branquias caídas, sin luz. Niebla `#9696A0` a los pies.
- Restauración: vuelve primero el turquesa de las branquias (rasgo firma), luego el bruñido.

## 11. Especificación técnica

| Concepto | Brote | Tallado |
|---|---|---|
| Triángulos (Biblia p. 120) · objetivo | 2 500–4 000 · 3 000–3 600 | 4 000–6 500 · 5 000–6 000 |
| Textura | 1024² | 1024² |
| MeshParts | `Body` + `Glow` (puntas de branquias) | `Body` + `Glow` (bordes del humo y surcos hondos) |
| Emisores de aura | 0 (Común) | 0 |
| Huesos (máx. 18 / 30, Biblia p. 120) | **18:** `Root`, `Pelvis`, `Spine`, `Head`, `Jaw`, `Lids`, `Gill_L1`–`L3`, `Gill_R1`–`R3`, `Leg_FL`, `Leg_FR`, `Leg_BL`, `Leg_BR`, `Tail_01`, `Tail_02` | **30:** `Root`, `Pelvis`, `Spine_01`–`03`, `Neck`, `Head`, `Jaw`, `Lids`, `Brow_L`, `Brow_R`, `Gill_L1`–`L3`, `Gill_R1`–`R3`, `Leg_FL_01/02`, `Leg_FR_01/02`, `Leg_ML`, `Leg_MR`, `Leg_BL_01/02`, `Leg_BR_01/02`, `Tail_01`–`Tail_03` |
| Anexos | Comunes de `PRODUCTION_SPECS.md` §7; `FX_Signature` en `Head` (centro de las branquias) | Igual |

Un solo hueso `Lids` porque Xolumi no guiña. El Tallado agota los 30 huesos: cualquier añadido exige quitar otro.

## 12. Originalidad y revisión cultural

- Sin parecido con el patrón «anfibio azul con burbujas»: cuerpo negro, burbujas solo como acento.
- Sin ninguna referencia a la deidad del mito: ni nombre, ni atributos, ni iconografía; solo el tema de
  transformarse para no desaparecer (Biblia p. 17, 18).
- Barro negro de San Bartolo Coyotepec: revisar con fuentes el acabado bruñido y citar la procedencia en
  la ficha. La reparación dorada se presenta como oficio, sin nombres de técnicas de otras culturas.

## 13. Lista de aceptación

**2D**
- [ ] Tres siluetas a 64 px y elección registrada.
- [ ] Brote 3/4, Tallado 3/4 con el Brote como referencia y cabeza del Tallado en tres vistas.
- [ ] Hojas de giro, 6 expresiones por forma, paleta y materiales, carta.
- [ ] Decisión registrada sobre el tamaño de los ojos del Brote (§3).
- [ ] Decisión registrada sobre el dorado en un Común (`PRODUCTION_SPECS.md` §3.3).
- [ ] Prueba de pareja, de parecido y diferenciación con Cantagólem superadas.
- [ ] Revisión cultural firmada.

**3D**
- [ ] Seis patas con espaciado correcto y torso a 30°.
- [ ] Cara legible con la luz del Valle pese al negro bruñido; boca `#EC96A0` visible.
- [ ] Triángulos, huesos y texturas dentro de §11; clips de §8 dentro de sus topes.
- [ ] Opaco ↔ restaurado reversible.
- [ ] Lista de `PRODUCTION_SPECS.md` §11 completa; `Visuals.xolumi` aprobado con `modelAsset` real; `./scripts/check.sh` en verde.

## 14. Registro de aprobación

| Fecha | Estado | Versión de la hoja | Aprueba | Observaciones |
|---|---|---|---|---|
| 2026-11-21 | Rediseño propuesto — pendiente de aprobación | v0.1 (este dossier) | — | Sin revisión humana todavía |
