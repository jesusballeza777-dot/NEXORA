# Dossier de producción · Kuachi → Ascuacho

> ## Estado: pendiente de aprobación humana
> Rediseño propuesto v0.1 · 21 nov 2026. Parte de `docs/art/STARTERS_REDESIGN.md`, opción A
> «El ladrón de brasas». Nada de este dossier está aprobado. El modelo actual del juego es un **blockout**
> (`Config/Visuals.luau → kuachi`, arquetipo `Opossum`, `assetStatus = "Blockout"`). No existe concepto 2D
> ni malla generada. Cifras con «(Biblia p. N)»: de la Biblia; el resto es **propuesta**.

---

## 1. Identidad

- **Historia en una frase:** el tlacuache que robó el fuego para todos y lo lleva guardado en su bolsa,
  que de mayor se convierte en un horno de comal (`STARTERS_REDESIGN.md`).
- **Núcleo que no se toca (Biblia §02):** tlacuache del relato mazateco que roba el fuego + horno de comal;
  bolsa-horno y cola ligada a la brasa y la ceniza.
- **Rasgo firma** (`Visuals.signatureFeature`): bolsa-horno encendida y cola de ceniza con punta de brasa.
- **Carácter (propuesta):** curioso, pícaro y generoso: roba, pero para repartir. Nunca cruel.
- **Huevo inicial:** idéntico a los otros dos (copal liso con espiral); al acercarse late en color
  **brasa** (Biblia p. 27).

## 2. Datos de la Biblia

| Campo | Valor | Biblia |
|---|---|---|
| Número · id | 1 · `kuachi` | p. 52 |
| Brote → Tallado | Kuachi → Ascuacho (v4: Kuachi → Tlecuach) | p. 28 |
| Rareza | Común · presupuesto 100 · coste 2 (Brote 1) · Tallado a nivel 12 · incubación 5 min | p. 35, 43, 115, 89 |
| Elemento | Fuego · vence a Flora y Sombra · pierde contra Agua y Mente | p. 48 |
| Rol · familia · bioma | Atacante · Cuadrúpedo, marsupial · Valle Copal | p. 49 |
| Talento | **Bolsa de Brasas:** al entrar en combate guarda 1 de Savia extra (máx. 1 por combate) | p. 49 |
| Firma | **Látigo de Ceniza:** especial · 65 · 2 Savia; 40 % de quemadura; si el rival ya arde, +20 % de daño | p. 49 |
| Golpe Nexo | **Fogata del Tallador:** 120 · 3 Savia; en 2v2 golpea a ambos rivales al 75 % (nivel 20, en Tallado) | p. 49, 115 |
| Repertorio | Chispazo (40) · Zarpa de Brasa (45) · Humo de Copal (30) · Comal Ardiente (70) · Muro de Ascuas (escudo) | p. 49 |
| Atributos Brote → Tallado nv 50 | VID 13→19 · ATQ 20→29 · DEF 10→14 · ESE 13→18 · VEL 14→20 | p. 49 |
| Mezcla mítica | El tlacuache que robó el fuego (relato mazateco) + horno de comal | p. 17 |
| Procedencia | Tlacuache · horno de barro de comal · relato mazateco del robo del fuego · México | p. 49 |
| Claves 2D | Silueta baja y alargada · bolsa-horno brillante · gris ceniza con brasa naranja | p. 49 |
| Brote (Biblia) | Pequeño, de hocico largo y orejas redondas; cola pelada y enroscada con la punta chamuscada; la bolsa del vientre brilla como un horno tibio | p. 49 |
| Tallado (Biblia) | Tlacuache de acecho, largo y bajo; la bolsa es un horno con rejilla al rojo y la cola un látigo de ceniza con anillos encendidos. Mirada de ladrón astuto | p. 49 |
| Rediseño v5 | Tallado con mirada feroz, colmillos y bolsa-horno al rojo | p. 24 |
| Primer Opaco | Opaco de Flora (en el slice: Agavo Brote nv 1, `valle_r1_e1`) | p. 48 |

## 3. Hoja de diseño · Brote (Kuachi)

**Silueta:** pera baja sentada, hocico largo, orejas redondas grandes y cola pelada que se enrosca en
espiral hacia arriba con la punta chamuscada: la espiral es la firma reconocible desde lejos.

| Proporción (propuesta) | Valor |
|---|---|
| Tamaño de referencia | 2,5 studs de alto, sentado |
| Altura total | 2,2 cabezas (cabeza = 45 % de la altura, `STARTERS_REDESIGN.md`) |
| Largo del cuerpo sin cola | 2 cabezas |
| Cola desenroscada | 2,5 cabezas; enroscada llega a la altura de las orejas |
| Orejas | diámetro 0,45 cabezas, redondas, separadas |
| Ojos | 30 % del ancho de la cara (`STARTERS_REDESIGN.md`), dos brillos |
| Patas | cortas, 0,5 cabezas |

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Pelaje base, gris tlacuache cálido | `#9E8A7A` | 55 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Vientre, cara y hocico, crema | `#DECCB8` | 20 % | `Visuals` (propuesta) |
| Patas, orejas por fuera, nariz | `#5C4E46` | 10 % | `Visuals` (propuesta) |
| Cola pelada e interior de las orejas, rosado | `#D6B0AA` | 10 % | blockout (propuesta) |
| Brasa: bolsa y punta de la cola (emisivo) | `#FF963C` | ≤ 5 % | `Visuals` (propuesta) |
| Ojo · brillos | `#181412` · `#FFFFFF` | — | `Visuals` |
| Rubor · boca | `#FF929E` · `#281816` | — | `Visuals.Face` |

Familias de color: gris cálido + rosa + brasa = **3** (Común 2–3, Biblia p. 26).

**Materiales:** pelaje pintado mate (rugosidad 0,75–0,85); piel de cola y orejas lisa (0,55); bolsa de
barro tibio (0,6) con emisivo interior. Sin metal.

**Cara:** ojos grandes y redondos con dos brillos, separados el 55 % del ancho de la cara; rubor suave bajo
los ojos (no círculos saturados en las mejillas); sonrisa pequeña en «v»; hocico largo con nariz oscura; sin
ceja; dientes no visibles en reposo.

## 4. Hoja de diseño · Tallado (Ascuacho)

**Silueta:** tlacuache de acecho largo y bajo, cuerpo 2,2 veces más largo que alto, cabeza adelantada y cola-
látigo en S con anillos encendidos que sobresale por encima del lomo: es la pieza que rompe la silueta.

| Proporción (propuesta salvo cita) | Valor |
|---|---|
| Escala | ×1,55 del Brote (`Visuals`; rango ×1,4–×1,7, Biblia p. 20) |
| Altura a la cruz | 3 cabezas (la cabeza baja de proporción) |
| Largo sin cola | 6,5 cabezas (2,2 × la altura, `STARTERS_REDESIGN.md`) |
| Cola | 6 cabezas, en S, con 5 anillos de brasa |
| Orejas | misma forma redonda, proporcionalmente menores y echadas atrás |
| Ojos | almendrados, largo = 22 % del ancho de la cara |
| Arma natural | colmillos pequeños (Biblia p. 24) y garras delanteras visibles |

| Zona | Hex | Superficie | Fuente |
|---|---|---|---|
| Pelaje ceniza | `#625A58` | 55 % | `STARTERS_REDESIGN.md` / `Visuals` (propuesta) |
| Vientre carbón | `#403836` | 20 % | `Visuals` (propuesta) |
| Patas, garras, máscara | `#2C2624` | 10 % | `Visuals` (propuesta) |
| Cola de ceniza | `#46403E` | 8 % | blockout (propuesta) |
| Brasa: rejilla, anillos, surcos (emisivo) | `#FF681E` | ≤ 7 % | `Visuals` (propuesta) |
| Iris · esclerótica | `#FF7828` · `#FAECD6` | — | `Visuals` (propuesta; Fuego `#EC7032`) |

Familias: gris ceniza + brasa = **2**. El tono del pelaje se mantiene (Brote ≈ 27°, Tallado ≈ 12°: dentro de
± 15°, `PRODUCTION_SPECS.md` §3.2) y baja de valor.

**Materiales:** pelaje pintado mate; la bolsa se convierte en **horno de barro de comal** (rugosidad 0,7)
con una rejilla al rojo; talla tono sobre tono en el lomo con brasa solo en los surcos; cola de ceniza con
anillos emisivos. Sin metal (Común).

**Cara y mirada:** la misma cara del Brote afilada: ojo almendrado con iris brasa, pupila rasgada, un brillo,
ceja marcada; «mirada de ladrón astuto» (Biblia p. 49); sonrisa de lado en lugar de la «v».

## 5. Lo que persiste entre formas

- [ ] Hocico largo con nariz oscura y orejas redondas en el mismo sitio.
- [ ] Gris tlacuache como color base (más oscuro en el Tallado) y vientre más claro u oscuro que el lomo, nunca de otro tono.
- [ ] Bolsa en el vientre que brilla (tibia → horno al rojo).
- [ ] Cola ligada a la brasa (punta chamuscada → anillos encendidos).
- [ ] Prueba de pareja a 128 px (`PRODUCTION_SPECS.md` §3.2).

Cambios de etapa (`STARTERS_REDESIGN.md`): sentado → acecho · ojos redondos → almendrados con iris naranja ·
bolsa tibia → horno con rejilla · cola rosada → látigo de ceniza con anillos · sin aura (Común), solo el
brillo de la brasa.

## 6. Hoja de giro

- [ ] Brote y Tallado en frente, perfil, espalda y 3/4 (Biblia p. 118), a la misma escala, con rejilla en cabezas.
- [ ] Cabeza del Tallado en tres vistas con la mirada feroz, antes del cuerpo completo (Biblia p. 21).
- [ ] Perfil: la cola entera visible y la línea del lomo; espalda: arranque de la cola y separación de los anillos.
- [ ] 3/4: bolsa visible y lectura de la rejilla.
- [ ] Versión plana (solo color) y versión con materiales; zonas emisivas marcadas.
- [ ] Pose de unión para el rig (neutra, simétrica, boca cerrada, cola en reposo) además de la pose de carácter.

## 7. Hoja de expresiones (seis por forma)

| Expresión | Brote | Tallado | Controles del rig |
|---|---|---|---|
| Neutral | Curioso, orejas al frente | Concentrado, orejas atrás | `Lid`, `Ear` |
| Desafío | Orejas atrás, sonrisa de lado | Orejas pegadas, labio levantado | `Ear`, `Jaw`, `Brow` (Tallado) |
| Ataque | Boca abierta, dientecitos | Boca abierta, colmillos | `Jaw` |
| Victoria | Guiño de ladrón | Guiño y sonrisa ladeada (Biblia p. 21) | `Lid_L`/`Lid_R`, `Jaw` |
| Cansado | Cola caída, brasa más tenue | Igual, rejilla menos encendida | `Tail`, emisivo −50 % |
| Cariño | Se acurruca enroscando la cola | Igual, con la cabeza apoyada | `Spine`, `Tail` |

Fuente: `STARTERS_REDESIGN.md`. Nunca llanto ni dolor explícito (Biblia p. 21).

## 8. Animaciones

Topes de la Biblia: ataques ≤ 2,5 s; Golpe Nexo ≤ 4 s (p. 40). Resto: propuesta (`PRODUCTION_SPECS.md` §8).

| Clip | Forma | Duración | Notas de acción y tiempo |
|---|---|---|---|
| `Idle` | B · T | 3,0 s | Olfatea el aire; la brasa respira (± 10 %) con el pecho |
| `IdleFidget` | B · T | 3,5 s | Se rasca una oreja y huele el suelo. Con rama en el santuario: se cuelga de la cola (gesto de tlacuache) |
| `Walk` · `Run` | B · T | 0,7/0,9 s · 0,45/0,55 s | Trote bajo; la cola hace de contrapeso con medio ciclo de retraso |
| `Happy` | B · T | 1,8 s | «Se hace el muerto» de broma: se deja caer de lado, abre un ojo y se levanta de un salto. Sin ojos en X ni lengua fuera; **requiere aprobación** por su cercanía a la regla de «nadie muere» |
| `Eat` | B · T | 2,0 s | Sujeta la comida con las patas delanteras; la bolsa brilla al tragar |
| `Sleep` | B · T | 4,0 s | Enroscado con la cola alrededor; brasa al 30 % |
| `BattleIdle` | B · T | 2,0 s | Agachado, cola alzada en S balanceándose |
| `AttackBasic` | B · T | ≤ 1,2 s, impacto a 0,45 s | Zarpa de Brasa (zarpazo con chispas); Chispazo (sacudida de cola); Humo de Copal (soplo de humo desde la bolsa) |
| `AttackSpecial` | B · T | ≤ 2,0 s | Comal Ardiente (abre la bolsa y lanza un disco de brasa); Muro de Ascuas (barrido de cola en arco que levanta ascuas) |
| `AttackSignature` | B · T | ≤ 2,5 s, impacto a 1,1 s | Látigo de Ceniza: giro de cadera y latigazo de cola en S; los anillos se encienden en secuencia |
| `GolpeNexo` | T | ≤ 4,0 s | Fogata del Tallador: la rejilla se pone al rojo, salta y estampa la cola, que abre una fogata en espiral; en 2v2 la espiral se parte hacia los dos rivales |
| `Hit` | B · T | 0,5 s | Retrocede con las orejas atrás |
| `RestEnter` · `Rest` | B · T | 1,5 s · 4 s | Se sienta y se enrosca, ojos cerrados, brasa al 20 %; respira |
| `Victory` | B · T | 1,8 s | Guiño de ladrón y cola en espiral alzada |
| `Hatch` | B | 1,5 s | Sale del huevo con la cola primero |
| `EvolveAnticipation` · `EvolveReveal` | B · T | 1,5 s · 2,0 s | La bolsa brilla y la cola se enciende → se estira largo y bajo, la cola chasquea y los anillos se encienden uno a uno (P12) |
| `Restore` | B · T | 1,8 s | La punta de la cola se enciende primero, luego la bolsa y después vuelve el color |

## 9. Carta

| Elemento | Valor |
|---|---|
| Fondo | Valle Copal en hora dorada: guirnalda de papel picado arriba, lomas, sol con espiral (láminas p. 49) |
| Marco y gema | Común, liso, `#D6C8B0` (`Visuals.RarityFrames`); gema arriba a la izquierda |
| Icono de elemento | Fuego, arriba a la derecha |
| Pedestal | Disco de luz en `#EC7032` al 40 % de opacidad (propuesta) |
| Aura | Ninguna (Común); solo el brillo propio de bolsa y cola |
| Pose · encuadre | Brote sentado en 3/4 mirando a cámara, cola en espiral dentro del área segura, 55 % de la altura · Tallado de acecho en 3/4, cabeza hacia cámara y cola en S sobre el lomo, ocupando el 80 % del ancho |
| Álbum | Silueta oscura con el número 1 cuando falta |

## 10. Variante Opaco

| Zona | Normal | Opaco (propuesta, fórmula de `PRODUCTION_SPECS.md` §6) |
|---|---|---|
| Pelaje Brote · Tallado | `#9E8A7A` · `#625A58` | `#8D8B8A` · `#646364` |
| Vientre Brote · Tallado | `#DECCB8` · `#403836` | `#C1BFBE` · `#494849` |
| Cola Brote | `#D6B0AA` | `#B2AEAE` |
| Brasa Brote · Tallado | `#FF963C` · `#FF681E` (Neon) | `#ADA096` · `#98867E`, **sin emisión** |
| Iris del Tallado | `#FF7828` | `#9F8F86`, con pupila y un brillo |

- La bolsa y la cola quedan frías, como ceniza apagada. Niebla `#9696A0` a los pies. Orejas algo caídas;
  Idle al 70 %.
- Restauración: se enciende primero la punta de la cola (rasgo firma), luego la bolsa; el color vuelve
  desde la cola hacia la cabeza.

## 11. Especificación técnica

| Concepto | Brote | Tallado |
|---|---|---|
| Triángulos (Biblia p. 120) · objetivo | 2 500–4 000 · 3 000–3 600 | 4 000–6 500 · 5 000–6 000 |
| Textura | 1024² (Biblia p. 120) | 1024² |
| MeshParts | `Body` + `Glow` (bolsa y punta de cola) | `Body` + `Glow` (rejilla, anillos, surcos) |
| Emisores de aura | 0 (Común, Biblia p. 26) | 0 |
| Huesos (máx. 18 / 30, Biblia p. 120) | **18:** `Root`, `Pelvis`, `Spine`, `Neck`, `Head`, `Jaw`, `Ear_L`, `Ear_R`, `Lid_L`, `Lid_R`, `Leg_FL`, `Leg_FR`, `Leg_BL`, `Leg_BR`, `Tail_01`–`Tail_04` | **29:** `Root`, `Pelvis`, `Spine_01`–`03`, `Neck`, `Head`, `Jaw`, `Ear_L`, `Ear_R`, `Lid_L`, `Lid_R`, `Brow_L`, `Brow_R`, `Leg_FL_01/02`, `Leg_FR_01/02`, `Leg_BL_01/02`, `Leg_BR_01/02`, `Tail_01`–`Tail_07` |
| Anexos | Comunes de `PRODUCTION_SPECS.md` §7; `FX_Signature` en `Tail_04`; `FX_Pouch` en `Spine` | `FX_Signature` en `Tail_07`; `FX_Pouch` en `Spine_01` |
| Pesos rígidos | — | Rejilla del horno al 100 % en `Spine_01` |

Los párpados son independientes porque la victoria es un guiño. La bolsa no lleva hueso: respira con `Spine`.

## 12. Originalidad y revisión cultural

- Evitar la cola-antorcha alta con llama en la punta (opción C descartada, riesgo de parecido).
- Evitar el patrón «roedor con mejillas de color»: rubor suave y pequeño.
- Relato mazateco: contrastar la versión con fuentes antes de la aprobación 2D; usar solo el tema (robar
  el fuego para todos). Comal y horno como objetos de oficio, sin objetos rituales.

## 13. Lista de aceptación

**2D (estado «Aprobado»)**
- [ ] Tres siluetas a 64 px y elección registrada.
- [ ] Brote 3/4, Tallado 3/4 con el Brote como referencia y cabeza del Tallado en tres vistas.
- [ ] Hojas de giro, 6 expresiones por forma, paleta y materiales, carta (8 entregables, Biblia p. 118).
- [ ] Prueba de pareja y prueba de parecido superadas.
- [ ] Revisión cultural firmada.
- [ ] Colores: Brote ≤ 3 familias, Tallado ≤ 3 familias; sin metal.

**3D (estado «Validado»)**
- [ ] Triángulos, huesos y texturas dentro de §11.
- [ ] Todos los clips de §8 dentro de sus topes; marcador `Impact` en cada ataque.
- [ ] Opaco ↔ restaurado reversible, sin lectura de muerte.
- [ ] Lista de `PRODUCTION_SPECS.md` §11 completa en Studio.
- [ ] `Visuals.kuachi`: `assetStatus = "Approved"` y `modelAsset` real; pruebas y `./scripts/check.sh` en verde.

## 14. Registro de aprobación

| Fecha | Estado | Versión de la hoja | Aprueba | Observaciones |
|---|---|---|---|---|
| 2026-11-21 | Rediseño propuesto — pendiente de aprobación | v0.1 (este dossier) | — | Sin revisión humana todavía |
