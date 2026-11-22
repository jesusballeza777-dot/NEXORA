# Prompts de concepto 2D (Gemini)

> **Estado: prompt propuesto — no ejecutado.** Ningún prompt de este archivo se ha enviado a Gemini ni a
> otra herramienta, y este paquete no contiene ninguna imagen generada. Toda salida futura es un
> **candidato** que entra como «Concepto» y necesita revisión humana (`README.md` §3). Ejecutar un prompt
> puede consumir créditos: requiere autorización del usuario.

Base: el prompt base v5 de la Biblia (p. 119) y las reglas de las p. 20–26. Los prompts van en inglés para
el modelo; cada plantilla tiene su versión en español para la revisión del equipo. Los colores en
hexadecimal que no aparecen en la Biblia son **propuesta** (`Config/Visuals.luau`, `Config/Elements.luau`).

---

## 1. Reglas de uso

1. **Una cosa a la vez** (Biblia p. 119): primero las siluetas, luego el Brote, luego el Tallado con el
   Brote aprobado como referencia obligatoria. Nunca especie, evolución y variante en una misma imagen.
2. Pedir siempre la **cabeza del Tallado en tres vistas** con la mirada feroz antes del cuerpo completo
   (Biblia p. 21).
3. Ninguna salida se usa como referencia de otra especie ni se presenta como arte del juego.
4. **Prueba de parecido** con franquicias y **revisión cultural** antes de aprobar (Biblia p. 119).
5. Registro obligatorio de cada ejecución:

| Fecha | Especie · forma | Plantilla y versión | Herramienta y versión | Semilla o ajustes | Quién ejecuta | Archivo de salida | Estado |
|---|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — | — |

**Nota sobre el prompt base de la Biblia:** pide «Oaxacan alebrije shape language», mientras que la
dirección de arte (Biblia §02 y `ART_DIRECTION.md`) prohíbe los alebrijes literales. Este archivo conserva
el lenguaje de formas (curvas en S, espirales, lóbulos de llama) y prohíbe el alebrije literal y la talla
de madera literal, como `STARTERS_REDESIGN.md`.

---

## 2. Bloques comunes

### 2.1 `[STYLE]`
```
Original creature concept for the Roblox game NEXORA. Style "Copal Nexo": handcrafted, organic fantasy.
Shape language of S-curves, spirals and flame lobes, used only as shape language: NOT a literal alebrije,
NOT a wooden carving. Rich crafted materials (copal resin, burnished ceramic, stone mosaic, embossed tin,
glass, textiles). Controlled palette: one color family plus one accent, NOT rainbow colors. Alive,
expressive, heroic and kid-friendly (ages 9-16). Stylized design ready for a mobile 3D game: clear primary
shapes, few parts, readable as a black silhouette at 64 px.
```
*ES:* criatura original para NEXORA, estilo «Copal Nexo»: fantasía artesanal y orgánica; curvas en S,
espirales y lóbulos de llama solo como lenguaje de formas; materiales de oficio; paleta controlada; viva,
expresiva, heroica y apta para 9–16 años; formas claras, pocas piezas, legible a 64 px.

### 2.2 `[NEGATIVE]`
```
Avoid: resemblance to any existing franchise creature; deities, gods, saints, religious or sacred symbols,
altars, pre-Hispanic deity masks or glyphs; skulls, blood, wounds, injury-like scars, bloodshot or glowing
red eyes, crying, gore, horror; rainbow or neon-overload palettes; photorealism; text, letters, logos,
watermarks, card frames or UI; human clothing; extra characters; cropped body; busy background.
```
*ES:* sin parecido con franquicias; sin deidades, santos ni símbolos sagrados; sin calaveras, sangre,
heridas, ojos rojos ni llanto; sin arcoíris; sin fotorrealismo; sin texto, logotipos ni marcos; sin ropa
humana; un solo personaje, cuerpo completo, fondo limpio.

Añadir siempre los patrones del género que hay que evitar (`STARTERS_REDESIGN.md`): «no tortoise with a
tree or cannons on its shell, no blue amphibian blowing bubbles, no rodent with electric cheeks».

### 2.3 Aura por rareza (Biblia p. 26)
| Rareza | Tallado | Brote (80 % del tamaño, mitad de partículas) |
|---|---|---|
| Común | `no aura, no particles` | `no aura` |
| Raro | `subtle sparkles along the edges and a soft rim light` | `a few faint edge sparkles` |
| Épico | `animated emissive glow and small particles orbiting the body` | `a small, faint orbit of particles` |
| Legendario | `golden aura with light rays and small floating pieces behind the body` | `a small golden glow behind the body, no rays` |
| Único | `its own iridescent halo and unique palette` | `a faint iridescent halo` |

Siempre: `the aura stays behind and around the silhouette; eyes and signature trait stay clean`.

### 2.4 Iris del Tallado por elemento (propuesta, `Config/Elements.luau`)
`Fuego` ember-orange `#EC7032` · `Agua` water-blue `#40AAD6` · `Tierra` earthy amber `#B8844C` · `Aire`
pale sky-blue `#AAD6E2` · `Flora` leaf-green `#68B058` · `Luz` warm pale gold `#FAE296` · `Artificio`
brass tan `#C48C5C`. En especies de varios elementos manda el primero de la configuración.

---

## 3. Plantillas

### 3.1 Siluetas (entregable 1)
*ES:* tres siluetas negras distintas de [NOMBRE] (Brote y Tallado lado a lado), legibles a 64 px; varía la
pieza que rompe la silueta, no el animal.
```
[STYLE]
Three different design options for [NAME] ([ELEMENTS], [RARITY]), each shown as a pair of solid black
silhouettes: BABY form (left) and EVOLVED form (right, 1.5x bigger). Animal: [ANIMAL]. Signature trait:
[SIGNATURE]. Vary the big silhouette-breaking feature between options; keep the animal recognizable.
Pure black shapes on white, no interior detail, readable at 64 px.
[NEGATIVE]
```

### 3.2 Brote (entregable 2)
*ES:* [NOMBRE] Brote, [ELEMENTOS], [RAREZA], [ROL]. Mezcla mítica: [ANIMAL] + [MITO, solo inspiración] +
[OFICIO]. Pequeño, tierno y sencillo; ojos grandes y redondos con dos brillos; superficie lisa; pocas piezas;
una silueta clara. [DESCRIPCIÓN DEL BROTE EN LA BIBLIA]. Rasgo firma visible. Paleta: [FAMILIA] + acento.
Aura reducida de su rareza. Cuerpo completo en 3/4 frontal, fondo liso.
```
[STYLE]
Species: [NAME], BABY form ("Brote"). Elements: [ELEMENTS]. Rarity: [RARITY]. Role: [ROLE].
Mythic mix: [ANIMAL] + [MYTH, as inspiration only] + [CRAFT/OBJECT].
Small, cute and simple; big round eyes with two white highlights; smooth surface; few parts; one clear
silhouette. [BROTE DESCRIPTION]. Signature trait clearly visible: [SIGNATURE].
Palette: [COLOR FAMILY] with [ACCENT] accent. [BROTE AURA].
Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 3.3 Tallado (entregable 3, con el Brote aprobado adjunto)
*ES:* el mismo monstruo crecido ×1,4–×1,7, imponente pero apto para niños: ojo almendrado con iris del
elemento y pupila rasgada, ceja marcada, arma natural, una pieza grande que rompe la silueta, relieve tono
sobre tono con luz solo en los surcos y aura de su rareza. Conserva cara, color base y rasgo firma del
Brote adjunto.
```
[STYLE]
Use the attached approved BABY image as the mandatory reference: this is the SAME creature, evolved.
Species: [NAME] ("Tallado", evolved form of [BROTE NAME]). Elements: [ELEMENTS]. Rarity: [RARITY].
Grown about 1.5x, imposing and fierce but kid-friendly: [POSTURE] posture with the weight forward;
almond eyes with [IRIS COLOR] iris, slit pupil, one highlight and a strong brow; natural weapons:
[WEAPON]; one big silhouette-breaking feature: [FEATURE]; tone-on-tone carved relief with light only
inside the grooves; [TALLADO AURA]. [TALLADO DESCRIPTION].
Keep the same face layout, the same base color and the same signature trait ([SIGNATURE]) as the baby.
Single color family [PALETTE]. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 3.4 Cabeza del Tallado en tres vistas (entregable 4)
```
[STYLE]
Head study of [NAME] (evolved form), same design as the attached reference: front, side and 3/4 views
in one row, same scale, neutral-focused expression with the fierce gaze (almond eyes, [IRIS COLOR] iris,
slit pupil, strong brow). Plain light background, no body below the neck.
[NEGATIVE]
```

### 3.5 Opaco (variante de un diseño ya aprobado)
*ES:* el mismo monstruo en estado Opaco: colores desaturados a gris conservando luces y sombras, tinte gris
frío, luces del cuerpo apagadas, ojos tenues pero presentes, niebla gris a los pies, cabeza algo baja.
Apagado, no muerto: nada de zombi, heridas ni ojos rojos. Segunda imagen: mitad restaurado.
```
[STYLE]
The SAME creature [NAME] ([FORM]) as in the attached approved image, in its "Opaco" state:
colors desaturated toward cool grey while keeping the light and shadow values; body lights and
emissive grooves switched off; eyes dim but alive (pupil and one small highlight kept); soft grey mist
(#9696A0) around the feet; head slightly lowered, calm. It is dimmed and sleepy-looking, NOT dead,
NOT a zombie, NOT scary: no cracks like wounds, no drooping skin, no glowing red eyes.
Second image: the moment of restoration, color flowing back from [SIGNATURE] outward while the mist
turns into warm copal sparks (#E8A848). Same pose and camera in both images, plain background.
[NEGATIVE]
```

### 3.6 Arte de carta (fondo o ilustración promocional)
En el juego la carta es un ViewportFrame con el modelo 3D (Biblia p. 25). Esta plantilla sirve para el
fondo de bioma y para piezas de marketing; el marco, la gema, los iconos y el texto se añaden en el juego.
```
[STYLE]
Collectible card illustration, landscape 4:3. [NAME] ([FORM]) stands in the center on a soft disc of
light (pedestal). Background: [BIOME BACKGROUND], low detail behind the head. [RARITY AURA] behind the
creature, never over the face. Leave the top-left and top-right corners empty for UI and a clean band
at the bottom. NO frame, NO text, NO icons.
[NEGATIVE]
```
Para el fondo solo, sustituir la criatura por «empty pedestal, no creature».

`[BIOME BACKGROUND]` (Biblia p. 9–11; hora dorada del Valle en `ART_DIRECTION.md` §4):
- **Valle Copal:** `golden-hour valley with rivers, chinampas, workshops and markets around a great twisted Nexo tree; papel picado garland along the top; soft hills; warm amber haze`.
- **Cumbre Brasa:** `volcanoes, clay ovens, smithies and embossed tin; orange sunset and tamed lava rivers`.
- **Marea Coralina:** `coral reefs, mangroves and cenotes linked by tunnels of light; caves with jellyfish and sunken ruins`.
- **Meseta Fulgor:** `plateau under perpetual storms, copper towers, windmills and automaton workshops charged by lightning`.
- **Velo Astral:** `night clouds, floating lanterns, auroras and constellations you can walk on`.
- **Torre del Nexo:** `inside the great Nexo tree-tower, warm copal lanterns and carved roots`.

---

## 4. Prompts de los 14 nativos del Valle Copal

Datos tomados de la Biblia (mezcla mítica p. 17–18; fichas p. 49–74). Sustituir `[STYLE]` y `[NEGATIVE]`
por los bloques de §2 tal cual. Las líneas «Dirección» son **propuesta**; todo lo demás viene de la Biblia.
**Estado de cada prompt: propuesto — no ejecutado.**

### 4.1 Kuachi → Ascuacho · #1 · Fuego · Común · Atacante
**Biblia (p. 17, 24, 49):** tlacuache que robó el fuego (relato mazateco) + horno de comal. Brote:
pequeño, hocico largo, orejas redondas, cola pelada enroscada con punta chamuscada, bolsa que brilla como
horno tibio. Tallado: tlacuache de acecho, largo y bajo; bolsa-horno con rejilla al rojo; cola-látigo de
ceniza con anillos encendidos; mirada de ladrón astuto; colmillos. Claves 2D: silueta baja y alargada ·
bolsa-horno brillante · gris ceniza con brasa naranja.
**Dirección:** opción A de `STARTERS_REDESIGN.md`; detalle en `dossiers/KUACHI.md`.
```
[STYLE]
Species: Kuachi, BABY form. Element: Fire. Rarity: Common. Role: Attacker.
Mythic mix: opossum + the opossum who stole fire for everyone (Mazatec folk tale, inspiration only) +
clay comal oven. Small pear-shaped opossum with a long snout and big round ears; bare pinkish tail
curled upward in a spiral with a singed ember tip; the belly pouch glows like a warm little oven.
Big round eyes with two highlights. Palette: warm opossum grey (#9E8A7A) and cream, ember-orange accent
(#FF9640) only on the pouch and tail tip. No aura. Full body, 3/4 front view, plain light background.
[NEGATIVE] No flaming tail torch.
```
```
[STYLE]
Use the attached approved Kuachi image as mandatory reference. Species: Ascuacho, evolved Kuachi.
Fire, Common. Long, low stalking opossum, body 2.2x longer than tall, head forward; almond eyes with
ember-orange iris (#EC7032), slit pupil, strong brow, the sly look of a clever thief; small fangs and
visible front claws. The pouch is now a clay oven with a red-hot grill. Silhouette-breaking feature:
an ash whip-tail in an S curve with glowing ember rings, rising above the back. Tone-on-tone relief
with ember light only inside the grooves. No aura. Same face, ash-grey base color and ember tail as
the baby. Palette: ash grey (#625A58) and charcoal, ember accent (#FF6820).
Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 4.2 Xolumi → Xolossus · #2 · Agua · Común · Soporte
**Biblia (p. 17, 20, 50):** ajolote y el mito del que se transforma para no desaparecer (solo el tema,
sin la deidad) + barro negro de Oaxaca. Brote: cabeza ancha, sonrisa tranquila, tres pares de branquias
plumosas turquesa, piel negra pulida como la cerámica de San Bartolo Coyotepec. Tallado: ajolote colosal
de seis patas, erguido como un dragón de río; branquias de humo de copal; cicatrices doradas; boca con
colmillos pequeños. Claves 2D: seis patas y cabeza ancha · branquias de humo · negro bruñido con oro.
**Dirección:** opción A de `STARTERS_REDESIGN.md`; el oro sigue líneas de reparación de cerámica, nunca
heridas; diferenciar de Cantagólem (`dossiers/XOLUMI.md`).
```
[STYLE]
Species: Xolumi, BABY form. Element: Water. Rarity: Common. Role: Support.
Mythic mix: axolotl + the theme of transforming in order not to disappear (no deity, theme only) +
Oaxacan black burnished clay. Very wide flat head with a calm smile; three pairs of feathery turquoise
gills (#40CEC4); short body with four stubby legs; skin of glossy black burnished ceramic (#22242A);
big round eyes set wide on the head, each with two highlights; pink mouth line. No aura.
Full body, 3/4 front view, plain light background.
[NEGATIVE] No bubbles, no water spray.
```
```
[STYLE]
Use the attached approved Xolumi image as mandatory reference. Species: Xolossus, evolved Xolumi.
Water, Common. Colossal axolotl with SIX legs, torso raised about 30 degrees like a river dragon, head
held high; almond eyes with water-blue iris (#40AAD6), slit pupil, strong brow; small fangs in the same
wide smile. Silhouette-breaking feature: the three pairs of gills rise as a crown of turquoise copal
smoke. Black burnished ceramic body (#16181E) crossed by golden repair seams (#D6AA4A) that follow the
clay like mended pottery, never like wounds; tail with a golden fin; turquoise light only inside the
deepest grooves. No aura. Same face, black base color and turquoise gills as the baby.
Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 4.3 Teselo → Mitlaxis · #3 · Tierra · Común · Defensor
**Biblia (p. 17, 51):** tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla.
Brote: caparazón alto de teselas pulidas, patas columnares, cara curiosa; sin vegetación ni picos.
Tallado: tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que giran; sobre el
lomo flota un disco de cielo nocturno. Claves 2D: domo escalonado · anillos dorados · piedra ocre y jade.
**Dirección:** opción A de `STARTERS_REDESIGN.md`. La Biblia no fija el arma natural: propuesta, pico
córneo y uñas de piedra en las patas-columna (`dossiers/TESELO.md`). Grecas originales, no copiadas.
```
[STYLE]
Species: Teselo, BABY form. Element: Earth. Rarity: Common. Role: Defender.
Mythic mix: desert tortoise + the turtle that holds up the sky (Chinese echo, inspiration only) +
stone fret (greca) mosaic. Tall dome shell made of polished stone tesserae with an original step-fret
pattern in ochre (#9C8462), cream and jade (#3E967A); short column-like legs; small curious head
peeking out; big round eyes with two highlights. No plants, no spikes on the shell. No aura.
Full body, 3/4 front view, plain light background.
[NEGATIVE] No tree, no rocks or cannons on the shell.
```
```
[STYLE]
Use the attached approved Teselo image as mandatory reference. Species: Mitlaxis, evolved Teselo.
Earth, Common. Tortoise-fortress: the shell rises in three stepped stone terraces with original
step-fret relief in ochre and jade; two golden-ochre astrolabe rings (#ECC460, painted, not polished
metal) orbit the shell; silhouette-breaking feature: a disc of night sky with tiny stars (#1C2446)
floating above the back. Guard posture planted on column legs with stone claws, horny beak; almond eyes
with earthy amber iris (#B8844C), slit pupil, strong brow. Tone-on-tone relief with warm light only in
the grooves. No aura. Same face, ochre base color and fret mosaic as the baby.
Full body, 3/4 front view, plain light background.
[NEGATIVE] No plants on the shell.
```

### 4.4 Barrock → Cantagólem · #6 · Tierra · Común · Soporte
**Biblia (p. 17, 55):** gólem de barro del folclore europeo + cántaro de mercado. Vasija que el Tallador
olvidó junto al río y despertó llena de agua de lluvia. Brote: jarrito panzón con asa-oreja, tapita de
sombrero y patas de piedra. Tallado: cántaro-gólem de brazos de barro, puños de piedra y grietas reparadas
en oro; vierte agua curativa por el pico como un guerrero-fuente. Claves 2D: vasija con brazos · grietas de
oro · barro con grecas blancas.
**Dirección:** barro rojo de mercado, nunca negro (no confundir con Xolumi); grietas de oro angulosas de
alfarería.
```
[STYLE]
Species: Barrock, BABY form. Element: Earth. Rarity: Common. Role: Support. Animated object.
Mythic mix: clay golem (European folklore, inspiration only) + market water jar. A chubby little clay
jar with one handle shaped like an ear, a small lid worn like a hat and stubby stone feet; face on the
belly of the jar; big round eyes with two highlights. Red-brown market clay with white fret patterns.
No aura. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```
```
[STYLE]
Use the attached approved Barrock image as mandatory reference. Species: Cantagólem, evolved Barrock.
Earth, Common. A jar-golem with strong clay arms and stone fists (natural weapons); cracks mended with
gold seams; it pours healing water from the jar's spout like a fountain-warrior. Guard posture; almond
eyes with earthy amber iris, slit pupil, strong brow. Silhouette-breaking feature: the big clay arms and
the raised spout. Tone-on-tone relief with light only in the grooves. No aura. Same face, red-brown clay
and white frets as the baby. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 4.5 Zunzi → Navajazul · #8 · Aire · Común · Veloz
**Biblia (p. 17, 24, 56):** colibríes guerreros mexicas (solo el concepto, sin la deidad) + navaja de
obsidiana. Colibrí que se mantiene inmóvil en el aire y zumba como un trompo. Brote: bolita de plumas con
pico corto y alas en abanico. Tallado: colibrí de plumas de obsidiana con pico-navaja y cola en tijera;
zumba tan rápido que deja estelas cortantes; mirada de guerrero. Claves 2D: pico-navaja · alas en abanico ·
azul cobalto iridiscente.
**Dirección:** en un Común la iridiscencia va pintada en el color, sin efectos (Biblia p. 26). Sin
tocados, escudos ni símbolos mexicas.
```
[STYLE]
Species: Zunzi, BABY form. Element: Air. Rarity: Common. Role: Fast.
Mythic mix: hummingbird + the idea of warrior hummingbirds (concept only, no deity) + obsidian blade.
A round little ball of feathers with a short beak and fan-shaped wings, hovering still like a spinning
top; big round eyes with two highlights. Cobalt blue with a painted iridescent sheen. No aura.
Full body, 3/4 front view, plain light background.
[NEGATIVE] No headdress, no shield, no pre-Hispanic symbols.
```
```
[STYLE]
Use the attached approved Zunzi image as mandatory reference. Species: Navajazul, evolved Zunzi.
Air, Common. Hummingbird with obsidian-black feathers and a razor beak of obsidian (natural weapon);
silhouette-breaking feature: a scissor tail and wide fan wings; it hums so fast it leaves cutting
streaks. Warrior gaze: almond eyes with pale sky-blue iris (#AAD6E2), slit pupil, strong brow.
Cobalt-blue iridescence painted in the feathers, no glow effects. No aura. Same face and cobalt base
as the baby. Full body, 3/4 front view, plain light background.
[NEGATIVE] No headdress, no shield, no pre-Hispanic symbols.
```

### 4.6 Vainas → Hercuerno · #10 · Flora · Común · Control
**Biblia (p. 17, 57):** escarabajo hércules + vaina de huaje + sonaja. Escarabajo que vive dentro de una
vaina de semillas y siembra por donde pasa. Brote: escarabajo redondo con élitros de vaina y antenas de
brote. Tallado: escarabajo gigante con cuerno doble de semilla, élitros-vaina que se abren como escudos y
sonido de sonaja al cargar. Claves 2D: cuerno frontal enorme · élitros de vaina · verde y ámbar.
```
[STYLE]
Species: Vainas, BABY form. Element: Flora. Rarity: Common. Role: Control.
Mythic mix: hercules beetle + huaje seed pod + rattle. A round little beetle whose wing cases are a
green seed pod; antennae shaped like sprouts; big round eyes with two highlights. Green with an amber
accent. No aura. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```
```
[STYLE]
Use the attached approved Vainas image as mandatory reference. Species: Hercuerno, evolved Vainas.
Flora, Common. Giant beetle with a huge double seed horn (natural weapon and silhouette-breaking
feature); pod-shaped wing cases that open like shields; seeds inside rattle when it charges. Almond
eyes with leaf-green iris (#68B058), slit pupil, strong brow. Tone-on-tone relief with light only in
the grooves. No aura. Same face, green base and pod shell as the baby. Green and amber.
Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 4.7 Pabilo → Candelux · #17 · Luz · Común · Soporte
**Biblia (p. 17, 60):** codorniz + cirio de procesión + farol. Codorniz con copete en forma de llama de
vela que alumbra el camino. Brote: ave redonda de patitas cortas y copete de luz. Tallado: gallinácea de
guerra con corona de velas, espolones de cera dura y un farol que nunca se apaga. Claves 2D: ave redonda
con corona de velas · espolones · crema y oro.
**Dirección:** revisión cultural: velas y farol como objetos de oficio, sin iconografía religiosa.
```
[STYLE]
Species: Pabilo, BABY form. Element: Light. Rarity: Common. Role: Support.
Mythic mix: quail + tall candle + lantern. A round little quail with short legs and a crest shaped like
a small candle flame that lights the way; big round eyes with two highlights. Cream with a soft gold
accent. No aura. Full body, 3/4 front view, plain light background.
[NEGATIVE] No religious objects, no processions, no crosses.
```
```
[STYLE]
Use the attached approved Pabilo image as mandatory reference. Species: Candelux, evolved Pabilo.
Light, Common. A war fowl with a crown of candles (silhouette-breaking feature), spurs of hardened wax
(natural weapon) and a lantern that never goes out. Almond eyes with warm pale gold iris (#FAE296), slit
pupil, strong brow. Tone-on-tone relief with light only in the grooves. No aura. Same face, cream base
and flame crest as the baby. Cream and gold. Full body, 3/4 front view, plain light background.
[NEGATIVE] No religious objects, no processions, no crosses.
```

### 4.8 Lumbro → Faroibex · #22 · Luz · Raro · Soporte
**Biblia (p. 17, 63):** íbice de montaña + faro + porcelana vidriada. Cabra montés de porcelana que guía a
los perdidos con su cuerno. Brote: cabrita de pelaje blanco con un cuernito de luz. Tallado: cabra montés
de porcelana con cuernos-faro curvos que proyectan haces de luz. Claves 2D: cuernos largos y curvos ·
pezuñas de cobre · blanco porcelana y oro.
```
[STYLE]
Species: Lumbro, BABY form. Element: Light. Rarity: Rare. Role: Support.
Mythic mix: mountain ibex + lighthouse + glazed porcelain. A little goat kid with white fur and one tiny
glowing horn; big round eyes with two highlights. Porcelain white with a gold accent.
A few faint edge sparkles. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```
```
[STYLE]
Use the attached approved Lumbro image as mandatory reference. Species: Faroibex, evolved Lumbro.
Light, Rare. A mountain ibex of glazed porcelain with long curved lighthouse horns that project beams of
light (natural weapon and silhouette-breaking feature) and copper hooves. Almond eyes with warm pale gold
iris (#FAE296), slit pupil, strong brow. Tone-on-tone relief with light only in the grooves. Subtle
sparkles along the edges and a soft rim light. Same face, porcelain-white base and glowing horn as the
baby. White porcelain and gold. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```

### 4.9 Dientón → Castorre · #25 · Flora · Tierra · Raro · Defensor
**Biblia (p. 17, 23, 64):** castor constructor (eco canadiense) + chinampa de Xochimilco + torre de troncos.
Levanta diques-jardín en los canales del Valle. Brote: castorcito de dientes naranjas que roe ramitas de
copal y carga una hoja. Tallado: castor arquitecto con torre-dique de troncos y jardín flotante en el lomo,
cola de remo blindada y dientes de hacha. Claves 2D: lomo-dique de troncos · cola de remo · café madera y
verde.
**Dirección:** el jardín es una chinampa sobre troncos, no un árbol en el lomo (distinguir de Teselo y de
los patrones del género).
```
[STYLE]
Species: Dienton, BABY form. Elements: Flora and Earth. Rarity: Rare. Role: Defender.
Mythic mix: builder beaver (Canadian echo) + Xochimilco chinampa garden + log tower. A little beaver with
orange teeth gnawing a copal twig and carrying a leaf; big round eyes with two highlights. Wood brown
with a green accent. A few faint edge sparkles. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```
```
[STYLE]
Use the attached approved Dienton image as mandatory reference. Species: Castorre, evolved Dienton.
Flora/Earth, Rare. Architect beaver carrying a dam-tower of logs with a small floating chinampa garden on
its back (silhouette-breaking feature), an armored paddle tail and axe-like teeth (natural weapons).
Almond eyes with leaf-green iris (#68B058), slit pupil, strong brow. Tone-on-tone relief with light only
in the grooves. Subtle sparkles along the edges and a soft rim light. Same face, wood-brown base and
orange teeth as the baby. Full body, 3/4 front view, plain light background.
[NEGATIVE] No full tree growing on the back.
```

### 4.10 Garabato → Monomural · #30 · Artificio · Raro · Control
**Biblia (p. 18, 67):** monos artistas de los relatos mayas (inspiración, sin nombres) + muralismo. Mono
artesano que pinta lo que imagina y lo vuelve real por un instante. Brote: monito de cola enroscada con un
pincel tras la oreja. Tallado: mono de brazos largos con pinceles, flauta y paleta flotante; pinta trampas
en el aire. Claves 2D: cola espiral · pinceles · café y colores primarios.
**Dirección:** sin glifos, códices ni personajes nombrados; los colores primarios solo en la pintura.
```
[STYLE]
Species: Garabato, BABY form. Element: Artifice. Rarity: Rare. Role: Control.
Mythic mix: artist monkeys from old Maya tales (inspiration only, no names, no glyphs) + mural painting.
A little monkey with a spiral-curled tail and a paintbrush tucked behind its ear; big round eyes with two
highlights. Warm brown, with small dabs of primary-color paint as the accent. A few faint edge sparkles.
Full body, 3/4 front view, plain light background.
[NEGATIVE] No glyphs, no codex pages, no written symbols.
```
```
[STYLE]
Use the attached approved Garabato image as mandatory reference. Species: Monomural, evolved Garabato.
Artifice, Rare. Long-armed monkey holding brushes and a flute, with a floating paint palette
(silhouette-breaking feature together with the spiral tail); it paints traps in the air with glowing
strokes. Almond eyes with brass-tan iris (#C48C5C), slit pupil, strong brow. Tone-on-tone relief with
light only in the grooves. Subtle sparkles along the edges and a soft rim light. Same face, brown base and
spiral tail as the baby. Full body, 3/4 front view, plain light background.
[NEGATIVE] No glyphs, no codex pages, no written symbols.
```

### 4.11 Cempa → Cempasol · #33 · Fuego · Luz · Épico · Atacante
**Biblia (p. 18, 68):** venado + cempasúchil + brasa dorada. Venado cola blanca con astas florecidas de
cempasúchil que arden sin quemar. Brote: cervatillo con manchas de pétalo y botones naranjas en la frente.
Tallado: venado de astas florecidas que arden sin quemar y un sendero de pétalos de luz. Claves 2D: astas
de flores · porte alto · naranja y oro.
**Dirección:** revisión cultural: flor y brasa, sin ofrendas, altares ni calaveras.
```
[STYLE]
Species: Cempa, BABY form. Elements: Fire and Light. Rarity: Epic. Role: Attacker.
Mythic mix: white-tailed deer + marigold (cempasuchil) flower + golden ember. A fawn with petal-shaped
spots and two orange flower buds on its forehead; big round eyes with two highlights. Orange and gold.
A small, faint orbit of particles. Full body, 3/4 front view, plain light background.
[NEGATIVE] No altars, no offerings, no skulls.
```
```
[STYLE]
Use the attached approved Cempa image as mandatory reference. Species: Cempasol, evolved Cempa.
Fire/Light, Epic. Tall proud deer with antlers blooming with marigold flowers that burn without
consuming (natural weapon and silhouette-breaking feature); it leaves a path of glowing petals. Almond
eyes with ember-orange iris (#EC7032), slit pupil, strong brow. Tone-on-tone relief with light only in
the grooves. Animated emissive glow and small particles orbiting the body. Same face, petal spots and
orange base as the baby. Orange and gold. Full body, 3/4 front view, plain light background.
[NEGATIVE] No altars, no offerings, no skulls.
```

### 4.12 Guaca → Aráureo · #37 · Luz · Aire · Épico · Atacante
**Biblia (p. 18, 70):** guacamaya + vitral + sol tallado (eco sudamericano). Guacamaya de plumas de luz que
pinta el amanecer al volar. Brote: pichón con copete corto y plumas de colores suaves. Tallado: guacamaya
de alas-vitral extendidas y cola de serpentinas de luz. Claves 2D: alas abiertas · cola larga · oro y
colores de vitral.
**Dirección:** vidrio emplomado en las plumas (Papalumen usa papel picado); el sol tallado es un motivo
geométrico, nunca un rostro solar de deidad.
```
[STYLE]
Species: Guaca, BABY form. Elements: Light and Air. Rarity: Epic. Role: Attacker.
Mythic mix: macaw + stained glass + carved sun motif (South American echo). A macaw chick with a short
crest and softly colored feathers; big round eyes with two highlights. Gold with muted stained-glass
colors. A small, faint orbit of particles. Full body, 3/4 front view, plain light background.
[NEGATIVE] No sun-god face.
```
```
[STYLE]
Use the attached approved Guaca image as mandatory reference. Species: Araureo, evolved Guaca.
Light/Air, Epic. Macaw with wide-open stained-glass wings framed in gold lead lines (silhouette-breaking
feature), a long tail of light streamers and a strong hooked beak (natural weapon); a geometric carved-sun
motif on the chest. Almond eyes with warm pale gold iris (#FAE296), slit pupil, strong brow. Tone-on-tone
relief with light only in the grooves. Animated emissive glow and small particles orbiting the body. Same
face, crest and gold base as the baby. Full body, 3/4 front view, plain light background.
[NEGATIVE] No sun-god face, no paper wings.
```

### 4.13 Tizón → Tizonsierpe · #39 · Fuego · Flora · Épico · Soporte
**Biblia (p. 18, 71):** serpiente de fuego que protege los campos (eco tupí). Serpiente que protege el
bosque y devora los incendios en lugar de provocarlos. Brote: culebrita de brasa con hojitas en la cabeza.
Tallado: serpiente de ascuas con cresta de hojas; devora las llamas y deja brotes. Claves 2D: cuerpo en S ·
cresta de hojas · brasa y verde.
**Dirección:** cresta de hojas, nunca plumas (evitar la lectura de serpiente emplumada, Biblia p. 18).
```
[STYLE]
Species: Tizon, BABY form. Elements: Fire and Flora. Rarity: Epic. Role: Support.
Mythic mix: fire serpent that protects the fields (Tupi echo, inspiration only). A little ember-colored
snake with small leaves sprouting on its head; big round eyes with two highlights. Ember red-orange with
a leaf-green accent. A small, faint orbit of particles. Full body, 3/4 front view, plain light background.
[NEGATIVE] No feathers.
```
```
[STYLE]
Use the attached approved Tizon image as mandatory reference. Species: Tizonsierpe, evolved Tizon.
Fire/Flora, Epic. A serpent of glowing embers in a strong S-curve (silhouette-breaking feature) with a
crest of leaves; it swallows flames and leaves sprouts where it passes; small fangs. Almond eyes with
ember-orange iris (#EC7032), slit pupil, strong brow. Tone-on-tone relief with light only in the grooves.
Animated emissive glow and small particles orbiting the body. Same face, ember base and leaf crest as the
baby. Ember and green. Full body, 3/4 front view, plain light background.
[NEGATIVE] No feathers, no wings.
```

### 4.14 Lumbrela → Papalumen, el Vitral Vivo · #43 · Aire · Luz · Legendario · Soporte
**Biblia (p. 18, 74):** mariposa monarca (migración) + papel picado + linterna. La mariposa-linterna de
papel picado que guía la migración de los Brotes perdidos. Brote: oruga-linterna con dos alitas de papel
recién abiertas. Tallado: cuatro alas de papel picado translúcido que proyectan vitrales en el suelo;
cuerpo de linterna. Claves 2D: alas enormes caladas · cuerpo linterna · oro, cielo y naranja. Aura: dorada,
vitrales proyectados y fragmentos de papel flotando. Huevo: papel picado dorado sobre cristal.
**Dirección:** pieza de marketing (orden de producción 3). La Biblia no fija arma natural para una
mariposa de Soporte; propuesta: sin arma, antenas largas como mechas de linterna (requiere aprobación).
```
[STYLE]
Species: Lumbrela, BABY form. Elements: Air and Light. Rarity: Legendary. Role: Support.
Mythic mix: monarch butterfly (migration) + papel picado cut paper + lantern. A lantern-caterpillar with
two tiny paper wings that have just opened; big round eyes with two highlights. Gold, sky blue and
orange. A small golden glow behind the body, no rays. Full body, 3/4 front view, plain light background.
[NEGATIVE]
```
```
[STYLE]
Use the attached approved Lumbrela image as mandatory reference. Species: Papalumen, "the Living
Stained Glass", evolved Lumbrela. Air/Light, Legendary. A butterfly with a lantern body and four huge
wings of translucent cut paper (papel picado) whose cut-out patterns project stained-glass light onto the
ground (silhouette-breaking feature); long antennae like lantern wicks. Almond eyes with pale sky-blue
iris (#AAD6E2), slit pupil, strong brow. Golden aura with light rays, projected stained-glass patterns and
floating paper fragments behind the body. Same face, lantern glow and colors as the baby.
Gold, sky blue and orange. Full body, 3/4 front view, plain light background.
[NEGATIVE] No real monarch-butterfly photo, no glass wings.
```
