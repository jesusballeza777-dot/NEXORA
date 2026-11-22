# Matriz de especies · estado de arte y prioridad

> **Estado: propuesta v0.1 · 21 nov 2026.** Datos de especie tomados de `src/ReplicatedStorage/Shared/Config/Species.luau`
> (tabla maestra, Biblia p. 52–53; fichas p. 49–81) sin modificaciones. Las columnas **Estado de arte**,
> **Prioridad beta** y **Notas** son de este paquete. La prioridad es **propuesta**.

## Cómo leer la matriz

- **Bioma** es el bioma de origen (`biome` en la configuración), que define el fondo de la carta y el bono
  nativo. Un Opaco puede aparecer fuera de su bioma (DESIGN_DECISIONS, contradicción 10).
- **Estado de arte** usa el vocabulario de `README.md` §3. Hay 8 blockouts propios (`Config/Visuals.luau`:
  los 8 del vertical slice). La beta añade **blockouts provisionales con arquetipo prestado** para Zunzi,
  Pabilo, Lumbro y Dientón como rivales del Acto I: usan la forma de otra especie solo para poder jugar y
  **no son diseño** ni referencia de silueta, escala o color. Las otras 38 especies no tienen
  representación visual.
- **Elementos** vacíos = Nexum, sin elemento propio (Eco, Biblia p. 44).

### Prioridad beta (propuesta)
| Nivel | Criterio | Especies | Entregable mínimo para la beta |
|---|---|---|---|
| **P0** | Lote A: validan el pipeline y congelan el estilo (Biblia p. 118, 120) | Kuachi, Xolumi, Teselo | Brote y Tallado completos + Opaco de ambas formas |
| **P1** | Rivales del Acto I en la beta: los del vertical slice (`Config/Encounters.luau`) y los cuatro con blockout provisional | Agavo, Comalú, Zizi, Barrock, Vainas · Zunzi, Pabilo, Lumbro, Dientón | Brote + variante Opaco del Brote; Tallado y su Opaco en cuanto los rivales lleguen a nivel de Tallado |
| **P2** | Pieza de marketing del Valle (orden de producción 3, Biblia p. 120) | Lumbrela → Papalumen | Brote, Tallado, carta y aura Legendaria |
| **P3** | Resto de nativos del Valle Copal (Lote C) | Garabato, Cempa, Guaca, Tizón | Brote y Tallado |
| **Posbeta** | Resto del catálogo, por lote de bioma (D–G) | 33 especies | Según su lote |

Recuentos de control: 50 especies · 18 Comunes, 14 Raros, 10 Épicos, 5 Legendarios, 2 Únicos, 1 Misterio
(Biblia p. 9/42) · Valle Copal 14, Cumbre Brasa 8, Marea Coralina 8, Meseta Fulgor 7, Velo Astral 12,
Torre del Nexo 1 (Biblia p. 10). Coinciden con `Species.luau`.

## Las 50 especies

| # | id | Brote | Tallado | Rareza | Elementos | Bioma | Rol | Familia | Estado de arte | Prioridad beta | Notas |
|---:|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `kuachi` | Kuachi | Ascuacho | Común | Fuego | Valle Copal | Atacante | Cuadrúpedo | Blockout · **Rediseño propuesto — pendiente de aprobación** | **P0** · Lote A | Inicial · Lote A · dossier [`KUACHI.md`](dossiers/KUACHI.md) · primer Opaco: de Flora (Biblia p. 48) |
| 2 | `xolumi` | Xolumi | Xolossus | Común | Agua | Valle Copal | Soporte | Anfibio | Blockout · **Rediseño propuesto — pendiente de aprobación** | **P0** · Lote A | Inicial · Lote A · dossier [`XOLUMI.md`](dossiers/XOLUMI.md) · primer Opaco: de Fuego · comparte «oro de reparación» con Cantagólem: diferenciar (ver dossier) |
| 3 | `teselo` | Teselo | Mitlaxis | Común | Tierra | Valle Copal | Defensor | Reptil | Blockout · **Rediseño propuesto — pendiente de aprobación** | **P0** · Lote A | Inicial · Lote A · dossier [`TESELO.md`](dossiers/TESELO.md) · primer Opaco: de Rayo · sin vegetación en el caparazón (Biblia p. 51) |
| 4 | `comalu` | Comalú | Magmadillo | Común | Fuego | Cumbre Brasa | Defensor | Cuadrúpedo | Blockout | **P1** · Acto I (beta) | Opaco (Brote, nv 1) del primer combate si el inicial es Xolumi (`valle_r1_e1`) · nativo de Cumbre |
| 5 | `rillip` | Rillip | Mantaraz | Común | Agua | Marea Coralina | Veloz | Acuático | Concepto pendiente | Posbeta · Lote D | — |
| 6 | `barrock` | Barrock | Cantagólem | Común | Tierra | Valle Copal | Soporte | Objeto animado | Blockout | **P1** · Acto I (beta) | Opaco del Canal (`valle_r1_e2`, Brote nv 4) · Opaco menor del Acto I (Biblia p. 112) · no compartir silueta de vasija con Xolumi |
| 7 | `yek` | Yek | Yetormenta | Común | Aire | Velo Astral | Soporte | Bípedo | Concepto pendiente | Posbeta · Lote G | Lote B: rediseño v5 (yeti; P6) |
| 8 | `zunzi` | Zunzi | Navajazul | Común | Aire | Valle Copal | Veloz | Ave | **Blockout provisional (arquetipo prestado) — no es diseño** | **P1** · Acto I (beta) | Rival del Acto I en la beta · Opaco menor del Acto I (Biblia p. 112) · Lote B: rediseño v5 (pico-navaja) · colibríes guerreros solo como concepto, sin deidad · «azul cobalto iridiscente» en un Común: iridiscencia pintada, sin shader ni emisor |
| 9 | `agavo` | Agavo | Quiotazo | Común | Flora | Cumbre Brasa | Defensor | Planta | Blockout | **P1** · Acto I (beta) | Opaco (Brote, nv 1) del primer combate si el inicial es Kuachi (`valle_r1_e1`) · Opaco menor del Acto I (Biblia p. 112) · nativo de Cumbre |
| 10 | `vainas` | Vainas | Hercuerno | Común | Flora | Valle Copal | Control | Insecto | Blockout | **P1** · Acto I (beta) | Élite «Opaco de la Vaina» (`valle_r1_e3`, Brote nv 7, modificador Coraza) · Opaco menor del Acto I (Biblia p. 112) |
| 11 | `zizi` | Zizi | Chicharrayo | Común | Rayo | Meseta Fulgor | Veloz | Insecto | Blockout | **P1** · Acto I (beta) | Opaco (Brote, nv 1) del primer combate si el inicial es Teselo (`valle_r1_e1`) · nativo de Meseta |
| 12 | `tinco` | Tinco | Coatitán | Común | Metal | Cumbre Brasa | Atacante | Cuadrúpedo | Concepto pendiente | Posbeta · Lote E | Ejemplo de Común en la lámina de rarezas (Biblia p. 26) y de mirada (p. 21) |
| 13 | `cuerdo` | Cuerdo | Turbinón | Común | Artificio | Meseta Fulgor | Control | Constructo | Concepto pendiente | Posbeta · Lote F | — |
| 14 | `okto` | Okto | Krakensa | Común | Mente | Marea Coralina | Control | Acuático | Concepto pendiente | Posbeta · Lote D | Kraken solo como concepto (Biblia p. 17) |
| 15 | `murk` | Murk | Lunatajo | Común | Sombra | Velo Astral | Veloz | Volador | Concepto pendiente | Posbeta · Lote G | — |
| 16 | `bruma` | Bruma | Fatuoscuro | Común | Sombra | Marea Coralina | Soporte | Fantasmal | Concepto pendiente | Posbeta · Lote D | — |
| 17 | `pabilo` | Pabilo | Candelux | Común | Luz | Valle Copal | Soporte | Ave | **Blockout provisional (arquetipo prestado) — no es diseño** | **P1** · Acto I (beta) | Rival del Acto I en la beta · Opaco menor del Acto I (Biblia p. 112) · revisión cultural: «cirio de procesión» sin iconografía religiosa |
| 18 | `lunk` | Lunk | Batraluna | Común | Astral | Velo Astral | Defensor | Anfibio | Concepto pendiente | Posbeta · Lote G | Eco chino (sapo de la luna) |
| 19 | `brinco` | Brinco | Voltalope | Raro | Aire · Rayo | Meseta Fulgor | Veloz | Cuadrúpedo | Concepto pendiente | Posbeta · Lote F | Lote B: rediseño v5 (chacalope) |
| 20 | `chispon` | Chispón | Fulminave | Raro | Rayo · Metal | Meseta Fulgor | Atacante | Ave | Concepto pendiente | Posbeta · Lote F | — |
| 21 | `kroa` | Kroa | Corvidúo | Raro | Mente · Sombra | Velo Astral | Control | Ave | Concepto pendiente | Posbeta · Lote G | Eco nórdico (cuervos del pensamiento y la memoria): sin deidad |
| 22 | `lumbro` | Lumbro | Faroibex | Raro | Luz | Valle Copal | Soporte | Cuadrúpedo | **Blockout provisional (arquetipo prestado) — no es diseño** | **P1** · Acto I (beta) | Rival del Acto I en la beta · Opaco menor del Acto I (Biblia p. 112) · primer Raro del Valle: destellos de borde y 1 emisor al atacar |
| 23 | `picoso` | Picoso | Magmacrán | Raro | Fuego · Tierra | Cumbre Brasa | Atacante | Arácnido | Concepto pendiente | Posbeta · Lote E | Ejemplo de mirada (Biblia p. 21) |
| 24 | `kunko` | Kunko | Alamar | Raro | Agua · Aire | Marea Coralina | Veloz | Acuático → Ave | Concepto pendiente | Posbeta · Lote D | Cambia de medio al tallarse (pez → ave): conserva cara y color base aunque cambie la silueta |
| 25 | `dienton` | Dientón | Castorre | Raro | Flora · Tierra | Valle Copal | Defensor | Cuadrúpedo | **Blockout provisional (arquetipo prestado) — no es diseño** | **P1** · Acto I (beta) | Rival del Acto I en la beta · Lote B: rediseño v5 (castor arquitecto) · jardín en el lomo: distinguir de Teselo (sin vegetación) |
| 26 | `cotorro` | Cotorro | Lorapiente | Raro | Agua · Flora | Marea Coralina | Control | Serpentino | Concepto pendiente | Posbeta · Lote D | — |
| 27 | `medu` | Medu | Cometaura | Raro | Astral | Marea Coralina | Soporte | Astral | Concepto pendiente | Posbeta · Lote D | — |
| 28 | `remache` | Remache | Mechalata | Raro | Artificio · Metal | Meseta Fulgor | Defensor | Constructo | Concepto pendiente | Posbeta · Lote F | — |
| 29 | `linterno` | Linterno | Farolánima | Raro | Luz · Sombra | Velo Astral | Soporte | Fantasmal | Concepto pendiente | Posbeta · Lote G | Sin referencias religiosas (Biblia p. 18) |
| 30 | `garabato` | Garabato | Monomural | Raro | Artificio | Valle Copal | Control | Primate | Concepto pendiente | **P3** · Valle | Monos artistas de relatos mayas como inspiración, sin nombres ni glifos (Biblia p. 18) |
| 31 | `zanco` | Zanco | Grullacandil | Raro | Fuego | Cumbre Brasa | Atacante | Ave | Concepto pendiente | Posbeta · Lote E | Ejemplo de Raro en la lámina de rarezas (Biblia p. 26) |
| 32 | `ovillo` | Ovillo | Aracnógrafa | Raro | Mente · Artificio | Velo Astral | Control | Arácnido | Concepto pendiente | Posbeta · Lote G | — |
| 33 | `cempa` | Cempa | Cempasol | Épico | Fuego · Luz | Valle Copal | Atacante | Cuadrúpedo | Concepto pendiente | **P3** · Valle | Huevo propio (Épico+) · revisión cultural: cempasúchil sin iconografía de ofrenda ni calaveras |
| 34 | `cenoti` | Cenoti | Leviacielo | Épico | Agua · Astral | Marea Coralina | Control | Acuático | Concepto pendiente | Posbeta · Lote D | Huevo propio (Épico+) |
| 35 | `pelon` | Pelón | Zopilatón | Épico | Aire · Metal | Cumbre Brasa | Defensor | Ave | Concepto pendiente | Posbeta · Lote E | Huevo propio (Épico+) |
| 36 | `chaquiro` | Chaquiro | Fulgurila | Épico | Tierra · Rayo | Meseta Fulgor | Bruto | Cuadrúpedo | Concepto pendiente | Posbeta · Lote F | Huevo propio (Épico+) |
| 37 | `guaca` | Guaca | Aráureo | Épico | Luz · Aire | Valle Copal | Atacante | Ave | Concepto pendiente | **P3** · Valle | Huevo propio (Épico+) · alas-vitral: diferenciar del papel picado de Papalumen · «sol tallado» sin rostro de deidad solar |
| 38 | `brujo` | Brujo | Brujalada | Épico | Sombra · Mente | Velo Astral | Control | Insecto | Concepto pendiente | Posbeta · Lote G | Huevo propio (Épico+) |
| 39 | `tizon` | Tizón | Tizonsierpe | Épico | Fuego · Flora | Valle Copal | Soporte | Serpentino | Concepto pendiente | **P3** · Valle | Huevo propio (Épico+) · serpiente sin plumas (evitar lectura de serpiente emplumada) |
| 40 | `tuerco` | Tuerco | Engrifo | Épico | Aire · Artificio | Meseta Fulgor | Veloz | Quimera | Concepto pendiente | Posbeta · Lote F | Lote B: rediseño v5 (grifo de cuerda) · ejemplo de Épico (Biblia p. 26) y de hoja de concepto (p. 119) · huevo propio |
| 41 | `boreal` | Boreal | Auroribú | Épico | Luz · Astral | Velo Astral | Soporte | Cuadrúpedo | Concepto pendiente | Posbeta · Lote G | Huevo propio (Épico+) |
| 42 | `hilacho` | Hilacho | Titeránima | Épico | Sombra · Artificio | Velo Astral | Control | Fantasmal | Concepto pendiente | Posbeta · Lote G | Huevo propio (Épico+) |
| 43 | `lumbrela` | Lumbrela | Papalumen | Legendario | Aire · Luz | Valle Copal | Soporte | Insecto | Concepto pendiente | **P2** · Marketing | «el Vitral Vivo» · pieza de marketing (orden de producción 3, Biblia p. 120) · huevo: papel picado dorado sobre cristal · aura: dorada, vitrales proyectados y fragmentos de papel (Biblia p. 74) |
| 44 | `geoda` | Geoda | Gemaboa | Legendario | Tierra · Metal | Cumbre Brasa | Defensor | Serpentino | Concepto pendiente | Posbeta · Lote E | «la Guardiana de Vetas» · ejemplo de Legendario (Biblia p. 26) |
| 45 | `nebulo` | Nébulo | Astrocorcel | Legendario | Aire · Astral | Velo Astral | Veloz | Cuadrúpedo | Concepto pendiente | Posbeta · Lote G | «el Ocho Vientos» · eco nórdico (corcel de ocho patas): sin deidad |
| 46 | `bisi` | Bisi | Gemitrueno | Legendario | Agua · Rayo | Marea Coralina | Atacante | Serpentino | Concepto pendiente | Posbeta · Lote D | «Serpiente de Dos Mareas» · eco andino |
| 47 | `petardo` | Petardo | Pirotoro | Legendario | Fuego · Artificio · Luz | Cumbre Brasa | Atacante | Cuadrúpedo | Concepto pendiente | Posbeta · Lote E | «el Castillo de Feria» |
| 48 | `mediluna` | Mediluna | Eclipsor | Único | Luz · Sombra · Astral | Velo Astral | Control | Cuadrúpedo | Concepto pendiente | Posbeta · Lote G | «el Gato de Dos Cielos» · shader propio (Único) |
| 49 | `nacar` | Nácar | Aetherion | Único | Agua · Astral · Mente | Velo Astral | Soporte | Acuático | Concepto pendiente | Posbeta · Lote G | «la Ballena Cartógrafa» · ejemplo de Único (Biblia p. 26) |
| 50 | `nex` | Nex | Nexum | Misterio | — (Eco) | Torre del Nexo | Adaptativo | Objeto animado | Concepto pendiente | Posbeta · Lote G | «el Gabinete que Camina» · geometría imposible y efectos de cámara (Biblia p. 26) · pieza de marketing (orden 3) |

## Vistas de trabajo

### Nativos del Valle Copal (14) · Biblia p. 9
Kuachi, Xolumi, Teselo, Barrock, Zunzi, Vainas, Pabilo, Lumbro, Dientón, Garabato, Cempa, Guaca, Tizón y
Lumbrela. Son los que llevan prompt en `GEMINI_PROMPTS.md` §4.

### Rivales del Acto I y variantes Opaco necesarias
| Especie | Dónde aparece | Forma y nivel | Variante Opaco necesaria |
|---|---|---|---|
| Agavo | `valle_r1_e1` (inicial Kuachi); Opaco de Quiotazo (Biblia p. 112) | Brote nv 1 (slice) · Tallado (Biblia) | Brote ya; Tallado después |
| Comalú | `valle_r1_e1` (inicial Xolumi) | Brote nv 1 | Brote |
| Zizi | `valle_r1_e1` (inicial Teselo) | Brote nv 1 | Brote |
| Barrock | `valle_r1_e2`; Opaco de Cantagólem (p. 112) | Brote nv 4 · Tallado | Brote ya; Tallado después |
| Vainas | `valle_r1_e3` (élite, Coraza); Opaco de Hercuerno (p. 112) | Brote nv 7 · Tallado | Brote ya; Tallado después |
| Zunzi | Rival de la beta (blockout provisional); Opaco de Navajazul (p. 112) | Brote (beta) · Tallado | Brote ya; Tallado después |
| Pabilo | Rival de la beta (blockout provisional); Opaco de Candelux (p. 112) | Brote (beta) · Tallado | Brote ya; Tallado después |
| Lumbro | Rival de la beta (blockout provisional); Opaco de Faroibex (p. 112) | Brote (beta) · Tallado | Brote ya; Tallado después |
| Dientón | Rival de la beta (blockout provisional) | Brote (beta) · Tallado | Brote ya; Tallado después |
| Copalia (Ser Sagrado, no está en las 50) | Jefe del Acto I | — | Opacada (Biblia p. 13) · presupuesto de Ser Sagrado |

La Biblia nombra a los Opacos menores del Acto I por su Tallado (p. 112), mientras que el slice usa
Brotes de nivel 1–7: por eso P1 pide primero el Opaco del Brote. Los niveles de los cuatro rivales con
blockout provisional los fija `Config/Encounters.luau` cuando se añadan. Nota de la Biblia: el Acto I
enfrenta «Opacos de Flora, Tierra y Aire» (p. 111), pero Candelux y Faroibex son de Luz (p. 112).

### Rediseños v5 (Lote B, Biblia p. 23–24)
Yetormenta (7), Navajazul (8), Voltalope (19), Castorre (25) y Engrifo (40). Mismo elemento y rareza;
ataques, Firmas y Talentos no cambian.

### Huevos propios (Épico en adelante, Biblia p. 27)
Cempa, Cenoti, Pelón, Chaquiro, Guaca, Brujo, Tizón, Tuerco, Boreal, Hilacho, Lumbrela, Geoda, Nébulo,
Bisi, Petardo, Mediluna, Nácar y Nex. Común y Raro usan el huevo de su elemento.
