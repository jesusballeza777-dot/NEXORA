# NEXORA · Construcción del mundo (Valle Copal, Gran Nexo y Torre del Nexo)

**Estado:** Fase 3, bloque de mundo. Todo sigue en `AssetStatus = "Blockout"`: piezas nativas de Roblox y terreno, con composición, materiales y luz de la Biblia visual Genesis. **No hay nada aprobado** (Genesis §11): este documento describe una propuesta que espera revisión humana.

**Fuentes:**
- `docs/ART_BIBLE_GENESIS.md` (escala, paletas, materiales, luz, presupuesto);
- `docs/ART_DIRECTION.md` §4;
- Biblia compacta p. 6–12 (mundo, Valle Copal, lotes, biomas, Torre del Nexo, Gabinete que Camina).

**Código:**
- `src/ReplicatedStorage/Shared/Config/Landscape.luau`: datos del paisaje.
- `Config/World.luau`: posiciones de juego.
- `Config/Ambience.luau`: luz, paleta y flora.
- `src/ServerScriptService/Server/World/*`: constructores.
- `Client/Controllers/AmbientLifeController.luau` y `AmbientMotion.luau`: vida ambiental.

---

## 1. Idea y lectura del valle

> Valle Copal es un cuenco habitado: en el centro, un árbol antiguo que es a la vez templo y menú; alrededor, la gente que lo cuida (plaza, oficios, chinampas, casas); en el borde, lo que se pierde (la Linde gris) y lo que se promete (las puertas selladas).

Cada región cuenta una parte de esa historia:

| Región | Historia que cuenta | Cómo se ve |
|---|---|---|
| Plaza del Nexo (centro) | Llegada y fiesta: aquí empieza todo | Piedra clara, greca, papel picado alto, estela, faroles |
| Torre del Nexo (norte) | Lo sagrado y lo antiguo: el árbol sostiene el valle | Gran Nexo de hebras, raíces que levantan las losas, siete estaciones |
| Puertas de los biomas (norte, al pie de la loma) | La promesa: el mundo sigue más allá | Cuatro portales sellados con vitral y glifo del elemento |
| Barrio de los Oficios (este) | El trabajo cotidiano | Calle de mercado con cinco puestos y el taller del barro y el telar |
| Río y Lago de las Chinampas (sur y oeste) | El agua que alimenta | Río que serpentea desde la cascada, chinampas con ahuejotes, canoas |
| Lotes Hogar (sur) | La casa del jugador | Cercas, caminos de piedra, hábitat con pedestales de copal |
| La Linde (oeste) | El valle pierde el color | Suelo gris, basalto, juncos secos, árboles opacados, estela caída |
| Terrazas (noreste) | La tierra trabajada | Bancales con muro de piedra, milpa y magueyes |

---

## 2. Plano del valle

Coordenadas en studs (X este, Z sur, Y arriba). El valle jugable está a **Y = 0** y plano; el relieve empieza fuera de las zonas de juego (lo comprueba `World.spec`).

```
                       N  (Z negativa)
          Lomas del norte (cima ~70)       Terrazas (178, −98)
     Puertas: (−46,−96) (−16,−108) (16,−108) (46,−96)
          Repisa (0,−82)        Mirador (26,−64)
   Criadero (−30,−60)    GRAN NEXO (0,−36)    Portal de Arenas (38,−28)
   Despensa (−34,−20)   ── calzada del Gabinete r = 27 ──
 Linde ── E3 (−122,−56)      huevos (±9,−6) (0,−9)
 (oeste)  E2 (−104,−20)
          E1 (−78,10)   Tablón (−40,6)  PLAZA (0,8) r 30  Círculo (40,6)  Mercado x 50–124 · Taller (138,15)
                                   spawn (0,34)
 Lago de las           ~~~~ río (14 puntos de control, ancho 18) ~~~~ puente (0,64) ~~ puente (104,62) ~~ cascada (180,46)
 Chinampas (−140,60)
          Lotes Hogar: (−96 · −48 · 0 · 48 · 96 · 144, 112), 44 × 44
                       Lomas del sur (cima ~55)
                       S  (Z positiva)
```

| Elemento | Dónde | Notas |
|---|---|---|
| Suelo | Bloque de 840 × 840, superficie a Y = 0 | `Landscape.Ground` |
| Colinas del cuenco | 27 bolas en 4 grupos + anillo exterior | Cima 50–90; 99 lomas satélite con semilla (`Landform.lumps`) rompen la silueta de domo |
| Afloramientos | 12 (roca y basalto) | Calculados sobre la superficie de las colinas |
| Terrazas | Centro (178, −98), 6 anillos de 9 de ancho y 4 de alto | Muro de `Slate` + tierra `Ground`/`LeafyGrass` alternas |
| Río | `World.River.points` (de −168 a 176), ancho 18 | Agua a Y = −1,2, fondo a −5, orilla de barro de 4,5 |
| Cascada | Macizo de roca (186–218, 16–76), canal a Y = 16–19,5 | Saliente en (184,5; 15,5), lámina de agua hasta la poza (170, 48) |
| Lago de las Chinampas | 5 círculos de agua alrededor de (−140, 60) | 4 islas de 18–24 × 10, embarcadero en (−101, 38) |
| Caminos de tierra | 10 polilíneas (`Landscape.Paths`), 5–10 de ancho | Plaza → puente → lotes; calle del mercado; Linde; embarcadero; Puertas; terrazas |
| Mercado | 5 puestos en la calle (50–124, 18) | El taller remata la calle en (138, 15) |

**El río se movió.** `World.River.points` pasó de 5 puntos casi rectos a 14 que serpentean (amplitud ±7, longitud de onda ~52). Mantiene los dos puentes sobre el cauce, deja la orilla norte a más de 8 studs del spawn y la sur fuera de los lotes. La vista previa web dibuja su río con estos mismos puntos (ver §9).

---

## 3. Composición y recorrido de la mirada

**Desde el spawn** (mira al norte, al Gran Nexo):
1. **Primer plano oscuro:** la estela de greca a la izquierda, las bancas y las macetas.
2. **Plano medio:** la plaza clara lleva al corazón de copal, en el eje.
3. **Marco:** dos cuerdas de papel picado cruzan a 15 studs de alto, perpendiculares a la mirada, como un proscenio. El Tablón y el Portal de Arenas cierran los lados.
4. **Fondo claro:** el tronco se abre en la copa; detrás, las puertas de los biomas y las lomas en bruma.

`World.spec` comprueba que ninguna pieza opaca ni el terreno tapan la línea del spawn al corazón.

**Recorrido:** spawn → corazón (prompt del menú) → calzada del Gabinete → estaciones.
- Cada estación tiene un remate que se lee de lejos: cúpula, mástil, cresta, espadaña o pérgola.
- Desde la plaza salen tres caminos con una meta visible: el puente principal (lotes), la calle del mercado (el humo del horno al fondo) y la Linde (la niebla gris).

**Valores (Genesis §4):** la paleta del valle va de la piedra clara (plaza) al verde medio (praderas) y al verde frío desaturado (lomas en bruma).
- Los acentos saturados (papel picado, toldos, cempasúchil) son pequeños y no pasan del 70 % de saturación.
- El neón solo aparece en surcos y núcleos de 1,5 studs o menos.

**Luz:**
- Tarde a las 15:54 (`clockTime = 15.9`): el sol queda a unos 30°.
- Atmósfera con densidad 0,34, bloom 0,5 con umbral 1,4, contraste +0,08 y saturación +0,04.
- Sombras frías: `Ambient` jade azulado.

---

## 4. Landmarks

### 4.1. Gran Nexo (`GranNexoBuilder`, ~105 studs)
Es una estructura viva y sagrada, no un árbol cualquiera.

- **Tronco:** cinco hebras de cilindros girados por segmentos (0,95 vueltas, ocho segmentos por hebra) alrededor de un alma central.
- **Vetas de copal:** neón de 0,5 de grosor metido en tres surcos entre hebras.
- **Corazón:** un hueco al frente (hacia el spawn), enmarcado por un arco de corteza.
  - Por dentro, copal translúcido (`Glass`) con un núcleo de neón de 1,4, una luz (rango 12) y chispas (6/s).
  - Lleva la etiqueta `AmbientHeart` y conserva el prompt `NexoMenu`.
- **Raíces:** ocho raíces (el frente queda libre) que arquean sobre el basamento y se hunden antes de la calzada del Gabinete. Las losas que pisan se levantan e inclinan (`TorreBuilder.basamento`).
- **Copa en tres capas:**
  - capa baja de verde hondo y jade;
  - capa media de verde hoja, con «puentes» de follaje entre ramas;
  - corona de verde claro, hasta Y ≈ 105.
- **Faroles:** diez de copal colgando de las ramas, seis de ellos con luz. Oscilan con `AmbientSway`.

### 4.2. Torre del Nexo (`TorreBuilder`)
- **Basamento:** dos anillos de losas (r 10,5–19).
- **Calzada del Gabinete:** anillo de losas (r 20–33) con borde de greca; se omite donde ya hay plaza.
- **Estaciones:** cada prompt `Station` queda **sobre la posición de `Config/World`**, la que valida el servidor. La arquitectura se construye detrás, hacia fuera (`Landscape.Torre.stations[id].outward`), para dejar libre la calzada.

| Estación | Identidad | Remate | Estado |
|---|---|---|---|
| Criadero | Vivero de adobe con cúpula de copal translúcido, dos cúpulas menores e incubadoras visibles a través del copal | Linterna de copal con aguja de latón (~15) | Abre la pantalla |
| Tablón de Encargos | Tablero tallado con marco de greca, papeles clavados, cuerdas cruzadas y tejadito | Mástil con banderola y papel picado (~17) | Abre la pantalla |
| Portal de Arenas | Arco de piedra con dintel de greca y anillo vertical de 16 dovelas de cobre; sellado con disco de piedra, trancas y cerrojo de copal | Cresta escalonada con brasero apagado (~26) | Sellado: el prompt «Mirar» avisa «se abrirá más adelante» (Fase 4) |
| Círculo de Encuentro | Anfiteatro de dos gradas en arco abierto hacia la plaza, escenario con greca | Mástil con tres banderolas y farol (~15) | Sellado (aviso) |
| Repisa de Cofres | Nicho de piedra con arco rebajado, fondo oscuro, tres estantes y cinco cofres de tres tamaños | Cornisa escalonada con greca y espadaña con campana (~23) | Abre la pantalla |
| Mirador de Biomas | Terraza de 5 de alto con escalera lateral, barandal, dos catalejos de latón hacia las puertas y mesa de mapas | Pérgola con tejadito y mástil (~18) | Abre la pantalla |
| Despensa del Gabinete | Puesto de adobe con estantes de cántaros, costales, mostrador con paño jade, toldo y letrero | Farol de copal (~8); el remate real es el Gabinete que descansa delante | Abre la tienda |

**Puertas de los biomas:**
- jambas escalonadas, dintel con greca y vitral del color del elemento (`Elements`);
- sello de piedra con glifo: ola (Marea), llama (Cumbre), rayo (Fulgor) o estrella de ocho puntas (Velo);
- una enredadera y el rótulo «… · sellado».

---

## 5. El Gabinete que Camina (`GabineteBuilder` + `AmbientLifeController`)

**Concepto:** un Nexum anciano, gabinete de curiosidades vivo. Toma la inspiración de las máquinas místicas de Remedios Varo y de las escaleras imposibles, sin copiar ninguna obra. No es un cofre con cajones: es un mueble que se volvió animal.

**Anatomía** (~105 partes, ~26 de alto):
- **Cuerpo:** gabinete alto de 8 × 12 × 6 en corteza oscura, con el vientre a 8 studs del suelo.
- **Seis patas articuladas:** cadera, muslo, rodilla de latón, tibia y pie.
  - La rodilla queda por encima del cuerpo, como un insecto zancudo.
  - Los pies se abren a ±9,4 studs.
- **Cajones de cinco tamaños** al frente, cada uno con tirador de latón.
- **Costillas:** cinco cajones largos por costado que se abultan hacia el centro.
- **Boca:** el cajón ancho, entreabierto, con luz cálida dentro. «Habla por cajones» (Biblia p. 12).
- **Ojos-farol:** dos faroles de copal sobre tallos, con párpado de madera y luz (rango 9).
- **Escalera de caracol** de 14 peldaños en la espalda, hasta el tejadito.
- **Tejadito** a dos aguas de teja, con un remate de copal.

**Recorrido** (lo hace el cliente; el servidor solo construye y etiqueta `GabineteWalk`):
- **Descanso:** 34 s frente a su Despensa, mirando hacia fuera, hacia los compradores.
- **Giros:** 3 s para girar a la tangente al salir y otros 3 s al volver.
- **Vuelta:** una vuelta completa en sentido antihorario a 2,2 studs/s por un círculo de radio 27 alrededor del árbol, con arranque y frenada suaves. Ciclo total de ~113 s.
- **Paso:** marcha trípode (patas 1-4-5 contra 2-3-6) ligada a la distancia recorrida (3,2 studs por ciclo), así que las patas no patinan. El cuerpo sube y baja 0,3 studs.
- **Tiempo común:** se usa `Workspace:GetServerTimeNow()`, así que todos los jugadores lo ven en el mismo sitio.

**Convivencia con el juego:**
- Todas sus piezas van sin colisión ni consultas: no empuja, no tapa prompts ni rayos del acompañante.
- La calzada (r 16,9–37,1 entre 2 y 27 studs de alto) queda libre de piezas de la Torre, la plaza y el árbol (`World.spec`).
- Los huevos iniciales (cima < 8) pasan bajo su vientre.
- El prompt de la tienda sigue fijo en la Despensa; así el servidor valida la proximidad igual que antes.

---

## 6. Barrio de los Oficios, río y chinampas

**Mercado** (`OficiosBuilder`): cinco puestos distintos bajo toldos de tela inclinados hacia la calle, con faldón a franjas.

| Puesto | Mercancía | Toldo |
|---|---|---|
| Cántaros | Alfarería en dos niveles y tinajas | Barro claro |
| Frutas | Canastas con fruta | Jade |
| Comal | Fogón de piedra, comal, brasa con luz, tortillas y ollas | Copal |
| Canastas | Canastas colgantes y rebozos doblados | Violeta apagado |
| Flores | Cubetas de cempasúchil y velas de copal | Rosa |

- Dos cuerdas de papel picado y un farol cruzan la calle.
- **Taller:** casa de adobe con vigas salientes y puerta en arco rebajado.
  - Horno de barro con boca encendida (luz) y humo (4/s).
  - Telar de pedal bajo un cobertizo.
  - Cántaros secándose y leña.

**Río y lago** (`RiverBuilder`, terreno en `Landform`):
- **Terreno en pasadas:** orillas de barro → vaciado con `Air` → agua → bancos de arena en las curvas interiores → islas de chinampa.
- **Puentes:** dos de madera en arco (subida de 3; 12 tablones siguiendo la curva), perpendiculares al cauce, con barandal y estribos de piedra.
- **Chinampas:**
  - tres surcos por isla, con hortalizas (una de las islas, con cempasúchil);
  - ahuejotes en los bordes largos;
  - un embarcadero de tablones y tres canoas que se mecen (`AmbientSway`, `bob`).
- **En el agua y las orillas:**
  - cempasúchil y hojas a la deriva en el río;
  - nenúfares en las orillas tranquilas del lago;
  - juncos y tules en las orillas.
- **Pie de la cascada:** espuma, tres chorros claros sobre la lámina y bruma (12/s).

---

## 7. Lotes Hogar (`LotsBuilder`)

La base es terreno (`LeafyGrass` al ras; antes era una Part). Encima:

- **Cerca y portón:** cerca baja de madera con el portón al norte, hacia el camino de los lotes.
- **Caminos:** caminos de piedra del portón al hábitat, la vitrina, el recolector y la incubadora.
- **Hábitat:** borde de piedra, musgo y cuatro pedestales de piedra con tapa de copal, cuya cima queda a **1,9 studs** (ahí los coloca `WorldController`). Comedero tallado con raciones en el centro.
- **Recolector de Monedas:** un **cántaro de barro** con franja de greca, monedas en la boca y otras derramadas al pie.
- **Vitrina:** tres pedestales (cima a 2,2) con respaldo tallado y tejadito.
- **Detalles:** dos faroles en el portón, macetas de cempasúchil y el letrero del dueño fuera de la cerca.

**Se conservan los nombres** que usan el servidor y el cliente: `Lot<i>`, `LotIndex`, `Ground`, `Habitat/Slot<n>` + `SlotPrompt`, `Collector` + `CollectPrompt`, `IncubatorRing`, `Incubator` y `Sign` + `OwnerLabel`. Las posiciones salen de `World.Lots` sin cambios.

---

## 8. Vida ambiental (Bloque J)

**Pura:** `AmbientMotion.luau`. Recibe el tiempo y la configuración y devuelve números; se prueba en Lune.

| Función | Qué devuelve |
|---|---|
| `lodTier(distancia, lod)` | `full`, `half` u `off` (Genesis §9) |
| `schedule(agentes, fotograma, presupuesto)` | Qué agentes se animan en este fotograma: turno rotativo, los de media frecuencia en fotogramas alternos y un tope de piezas |
| `gabinete(t, ruta, ángulo)` y `leg(fase, trípode, camina)` | La pose del Gabinete y de cada pata |
| `heart(t)` | Latido lub-dub: escala y brillo |
| `sway(t, semilla)` y `bob(t, semilla)` | Oscilación de faroles y banderas; balanceo de canoas |
| `bird(t, i, bandada)` | Vuelo en círculo con planeos y aleteo |
| `fish(t, cfg)` | Salto en arco de 1,1 s cada 9–14 s |
| `butterfly(t, i, grupo)` | Vuelo errático (Lissajous) |

**Cliente:** `AmbientLifeController.luau`.
- Lo conecta `ClientBootstrap` igual que los demás controladores.
- Un **único** `Heartbeat`, sin bucles por instancia.
- Etiquetas: `AmbientSway` (37), `AmbientHeart` (1), `GabineteWalk` (1), `AmbientBirds` (2), `AmbientFish` (4) y `AmbientButterflies` (3).
- **Presupuesto:** 520 piezas por fotograma. El Gabinete (105) puede pasar solo si hace falta, para no congelarse.
- **Niveles de detalle:** se recalculan cada 0,5 s según la distancia a la cámara.

**LOD por tipo** (completo / media frecuencia):

| Tipo | Completo hasta | Media frecuencia hasta |
|---|---|---|
| Faroles y banderas | 60 | 140 |
| Aves | 120 | 320 |
| Peces | 60 | 140 |
| Mariposas | 50 | 110 |
| Corazón | 90 | 220 |
| Gabinete | 120 | 260 |

- Más allá, nada se anima.
- Todas las piezas se mueven con un solo `Workspace:BulkMoveTo` por fotograma.
- El latido ya no lo hace `WorldController` (antes era un `Tween` de tamaño).

---

## 9. Presupuesto medido

Medido con el `ValleBuilder` real en el sandbox de Lune (`lune run tools/roblox-preview/build` y el conteo de `World.spec`):

| Concepto | Medido | Tope (`World.spec`) |
|---|---|---|
| Partes (todas) | **3 240** (3 216 visibles) | < 4 000 |
| — Flora (árboles, arbustos, milpa, juncos, flores) | 1 028 | |
| — Lotes (6) | 606 | |
| — Torre: basamento, calzada, 7 estaciones y 4 puertas | 427 | |
| — Gran Nexo | 260 | |
| — Oficios (mercado y taller) | 218 | |
| — Plaza / Río / Gabinete / Linde / Fauna / Huevos | 205 / 190 / 105 / 102 / 71 / 27 | |
| `PointLight` | **19**, rango ≤ 12, sin sombras | ≤ 24 |
| `ParticleEmitter` | **7**, tasa máxima 12/s | ≤ 10 y ≤ 20/s cada uno |
| Neón | Todas las piezas de 1,5 studs o menos de grosor | ≤ 1,5 (Genesis §5) |
| Rellenos de terreno | **533** (160 `FillBall`, 333 `FillCylinder`, 40 `FillBlock`) | — |
| Árboles | 79 en la flora (25 ahuejotes, 12 de ellos en las chinampas; 26 sabinos; 23 copales; 3 colorines y 2 opacados), más 3 opacados de la Linde | — |
| Agentes de vida ambiental | 48 | — |

**Justificación del nuevo tope de partes (antes < 1 500, ahora < 4 000):**
- El encargo pide un valle con oficios, siete estaciones, lotes amueblados y vegetación variada.
- El paisaje ya es terreno, y la flora y la fauna son decoración sin colisión ni consultas.
- La vegetación se clona desde plantillas.
- Lo animado se limita por distancia y por presupuesto de fotograma.

**Lo pendiente de medir:**
- el coste real en Roblox (draw calls, memoria de terreno y tiempo de los 533 rellenos al arrancar);
- el FPS en el teléfono base (Genesis §9: 30 fps con 8 monstruos con aura).

---

## 10. Qué se verificó y qué no

**Verificado (sin Studio):**
- `./scripts/check.sh` en verde: StyLua, Selene, 175 pruebas de Lune, `rojo build`, vista previa web, paridades y vista de blockouts.
- `World.spec`:
  - clases y propiedades reales (`@lune/roblox`) y presupuesto;
  - las siete estaciones con su prompt sobre la posición de juego;
  - el Gran Nexo entre 90 y 120 studs y el corazón etiquetado;
  - el Gabinete etiquetado, con seis patas y sin colisión, y la calzada libre;
  - el spawn despejado y la línea de mirada al corazón;
  - el agua de terreno en el río, el lago y la poza, y el río serpenteando;
  - las zonas de juego planas y secas;
  - la flora determinista, variada y fuera de las zonas de juego;
  - las piezas de juego de los lotes.
- `AmbientLife.spec`:
  - funciones de paso puras (LOD, presupuesto, ruta y velocidad del Gabinete, trípode, latido, oscilación, peces, aves y mariposas);
  - el controlador sobre el valle real: etiquetas, presupuesto por fotograma, nada lejos, el Gabinete camina y el corazón late.
- **Vista previa** `build/roblox-preview/World.html`, que dibuja el mundo construido por el `ValleBuilder` real:
  - el terreno se rasteriza en un mapa de alturas: vaciado con `Air`, agua y materiales con su color de `Terrain`;
  - las cuñas se dibujan como en Roblox, con la pendiente hacia −Z;
  - las luces aparecen como halos y las partículas, como nubes aproximadas;
  - vistas nuevas: `nexo`, `torre`, `gabinete`, `market`, `chinampas`, `cascada` y `mirador`.
- **Capturas** en `docs/phase3/world/`:
  - `before-{spawn,aerial,lots,linde}.jpg`;
  - `after-{spawn,aerial,lots,linde,nexo,torre,gabinete,market,chinampas,cascada,mirador}.jpg`.

**No verificado (requiere Roblox Studio):**
- **Terreno:** el aspecto real del terreno de vóxeles (4 studs) y sus texturas.
- **Cascada:** la lámina vertical de agua de terreno puede verse como un bloque de agua, sin caída ni espuma real.
- **Agua de los bordes:** el agua parcial en los bordes (shorelines).
- **Cuñas:** la orientación de `WedgePart` y `FillWedge` se tomó de la documentación y no se ha visto en Studio.
- **Rendimiento:** draw calls, memoria y el tiempo de construcción del terreno al arrancar el servidor.
- **Animación:** `BulkMoveTo` y el paso del Gabinete en un dispositivo real; que el `Size` animado del corazón no cause tirones.
- **Prompts:** su legibilidad y el radio de los prompts en la arquitectura nueva.
- **Luz:** la vista previa aproxima sol, bruma y bloom.

**Lo que no se ve bien todavía (honesto):**
- Las colinas siguen leyéndose suaves y algo redondeadas en la vista previa; el suavizado del rasterizado exagera el efecto.
- El acantilado de la cascada es un bloque de roca con rocas encima. En la vista previa su cara se tiñe con el barro de la poza. Le falta modelado (estratos, salientes) y la caída de agua es sencilla.
- Desde la llegada, la copa del Nexo queda cortada por arriba: es lo esperado con un landmark de ~105 studs y la cámara a la altura del jugador.
- La Linde todavía es bastante verde fuera de los claros. Podría perder más color con manchas grises extra o con un `ColorCorrection` local al entrar (pendiente).
- Las cercas de los lotes, vistas de lejos, son líneas finas.
- Las vitrinas vistas desde el sur muestran el respaldo liso.

---

## 11. Decisiones propuestas (requieren aprobación)

Ninguna se ha registrado en `DESIGN_DECISIONS.md` (este bloque no puede editarlo). Propuesta para el integrador:

| # | Propuesta | Motivo |
|---|---|---|
| W-1 | Mover el río a 14 puntos que serpentean (`World.River.points`), conservando los puentes | Pedido de «río que serpentea». La vista previa web hereda el trazado (se reconstruye en `check.sh`), pero no se revisó en el navegador: sus chinampas tienen posiciones fijas |
| W-2 | Subir el tope de partes del valle de 1 500 a 4 000 (§9) | Densidad pedida por el encargo con presupuesto controlado |
| W-3 | Portal de Arenas y Círculo de Encuentro con prompt «Mirar» que solo avisa «se abrirá más adelante» | El encargo pide las 7 estaciones con prompt; no se abre ninguna función nueva |
| W-4 | Gabinete que Camina: recorrido de ~113 s (34 s de descanso y una vuelta a 2,2 studs/s), radio 27; la tienda se sigue usando en el mostrador fijo de la Despensa | El servidor no tiene que seguir al Gabinete para validar la proximidad. Alternativa: prompt sobre el Gabinete con validación por `AmbientMotion.gabinete` en el servidor |
| W-5 | Hora del valle a las 15:54 (`clockTime 15.9`, sol a ~30°) en lugar de las 16:36 | Genesis §7 pide el sol de tarde a unos 30° |
| W-6 | Saturación de pigmentos del mundo (flores, papel picado, toldos) bajada al 70 % HSV | Genesis §4.1 regla 3 |
| W-7 | Diseño del Gabinete (§5) como dirección de arte para el modelo final de Nexum anciano | No fija el diseño: es un blockout; necesita aprobación humana y la prueba de parecido (Genesis §10) |
| W-8 | Especies de flora del valle: ahuejote, copal, sabino, colorín y opacado | Identidad mexicana sin símbolos sagrados; falta la revisión cultural |
