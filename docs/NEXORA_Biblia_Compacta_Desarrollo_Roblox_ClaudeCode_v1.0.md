# NEXORA · Biblia compacta de desarrollo (Roblox / Claude Code) v1.0 — transcripción

> **Nota de transcripción.** Este archivo es una transcripción en Markdown de
> `docs/reference/NEXORA_Biblia_Compacta_v1.0.pdf` (46 páginas, fechada el 21 NOV 2026).
> **El PDF sigue siendo la fuente de verdad**; ante cualquier diferencia, manda el PDF.
>
> - Cada página del PDF tiene su encabezado `## Página N · Título`. En el Apéndice A cada bloque
>   conserva su referencia `Fuente PDF · página X` (página de la Biblia v5.0 original).
> - El Apéndice A del PDF ya viene «aplanado»: las tablas y las columnas de la v5.0 se imprimieron
>   como texto corrido e intercalado. Aquí se reconstruyen como tablas o listas cuando la estructura
>   se puede recuperar sin adivinar. Lo que no se puede recuperar se marca
>   **[ilegible en la extracción]** y, cuando ayuda, se copia el texto tal como sale.
> - Cuando un bloque cruza el salto de página, se transcribe completo bajo la página donde empieza y
>   se indica en qué página continúa.
> - Se omiten las cabeceras y pies repetidos de cada página («NEXORA · BIBLIA COMPACTA DE
>   DESARROLLO», «ROBLOX / CLAUDE CODE», «Fuente base: Biblia NEXORA v5.0 · 02 NOV 2026» y el número).
> - Números, porcentajes, nombres y estados (HECHO / PROPUESTA / PREGUNTA) se copian tal cual,
>   incluida la coma decimal de la fuente. No se resume ni se corrige el contenido.

---

## Página 1 · Portada

**NEXORA / MONSTER SANCTUARIES**

# BIBLIA COMPACTA DE DESARROLLO

La visión completa de NEXORA, reorganizada para construir un videojuego de Roblox con una base
técnica, visual y comercial escalable.

| FUENTE CONSERVADA | CAPA DE DESARROLLO |
|---|---|
| Biblia de Creación v5.0 · 127 páginas · 02 NOV 2026 | Project Genesis · decisiones de alcance y arquitectura para Roblox |

*Tierno al nacer. Imponente al tallarse.*

Documento de trabajo para Claude Code + Opus, Roblox Studio y el equipo creativo.

BIBLIA COMPACTA DE DESARROLLO · V1.0 · 21 NOV 2026

---

## Página 2 · Guía de lectura

### Una fuente, dos capas de decisión

Este documento reúne la especificación histórica de NEXORA v5.0 y las decisiones posteriores para
iniciar su desarrollo en Roblox. La distinción es deliberada: el apéndice conserva los datos
originales; la capa Genesis define qué construir primero y cómo organizarlo.

> **Regla crítica para Claude**
>
> No conviertas una propuesta o una pregunta de la Biblia en una decisión aprobada. No reequilibres,
> completes ni inventes sistemas sin registrar el cambio. Para la Fase 1, construye el vertical slice
> descrito en Genesis y deja el resto como contenido futuro.

### Contenido

| PARTE | CONTENIDO |
|---|---|
| 0 | Cómo usar y gobernar el documento |
| 1 | Esencia y pilares del producto |
| 2 | Dirección de arte y personajes |
| 3 | Mundo, biomas y lotes |
| 4 | MVP / vertical slice y roadmap |
| 5 | Arquitectura Roblox, datos y seguridad |
| 6 | Monetización, analítica y aceptación |
| A | Especificación v5.0 transcrita por página fuente |
| B | Láminas visuales compactas |

### Procedencia y compresión

Se eliminaron portada, índice, separadores de capítulo, encabezados/pies repetidos y dos páginas de
galería redundantes. Las especificaciones únicas de esas galerías quedan cubiertas por la tabla
maestra de especies y por las láminas visuales seleccionadas. El contenido textual único de las
páginas de especificación se conserva en el apéndice con su número de página original.

Fecha de referencia de la fuente: 2 de noviembre de 2026. Los datos económicos, de cumplimiento y de
balance se conservan como datos de la v5.0; deben revisarse antes de activar funciones comerciales o
publicar.

---

## Página 3 · 01 / Producto

### La esencia de NEXORA

NEXORA no es únicamente un simulador de mascotas. Es un juego de colección, cuidado, evolución,
santuario, aventura y combate táctico. El objeto emocional es la criatura: el jugador la descubre, la
cuida, la hace crecer, la transforma y la muestra.

### Cinco pilares

| PILAR | PROMESA PARA EL JUGADOR |
|---|---|
| Colección | Descubrir especies, rarezas, elementos, huevos, cartas y completar el Álbum del Nexo. |
| Transformación | El paso de Brote a Tallado debe ser una recompensa física y emocional, no solo una subida de nivel. |
| Santuario | Un hogar propio donde alojar, organizar y exhibir monstruos; a futuro, personalizar y recibir visitas. |
| Aventura | Explorar biomas, superar etapas y restaurar Opacos y Seres Sagrados. |
| Estrategia/social | Entrenar equipos y combatir; posteriormente, competir, visitar y participar en eventos. |

### Bucle central

> Eclosionar → Cuidar → Entrenar → Explorar → Competir → Criar
>
> Cada acción alimenta a los demás sistemas. Las sesiones objetivo de la Biblia: 5 minutos (actividad
> rápida), 20 minutos (partidas/encargo/crianza) y 60 minutos (capítulo de aventura/evento).

### Posicionamiento

NEXORA debe sentirse como un universo propio al que se quiere regresar. La colección y la progresión
son centrales; los escenarios y la monetización deben apoyar esa promesa, no sustituirla. Las
referencias a otros juegos describen patrones de género, nunca objetivos de copia.

---

## Página 4 · 02 / Dirección de arte

### Rediseñar, no reproducir

> **Estado de los personajes**
>
> Las imágenes de la Biblia v5.0 son bocetos/referencias preliminares. No son diseños finales, modelos
> 3D ni assets aprobados. La primera tarea visual consiste en desarrollar un lenguaje gráfico propio y
> rediseñar los tres iniciales conservando su identidad conceptual.

### Lenguaje visual

Fantasía artesanal y orgánica; criaturas expresivas con siluetas memorables, anatomía propia,
materiales ricos, paletas controladas e identidad elemental. Copal, cerámica, grecas, piedra,
textiles, metal, vidrio y oficios son fuentes de materiales/cultura visual. No convertir todo en tallas
de madera ni alebrijes literales. Las criaturas deben sentirse vivas y reconocibles en Roblox.

### Dos estados, una misma especie

| BROTE | TALLADO |
|---|---|
| Pequeño, tierno, expresivo; anatomía sencilla pero distintiva; ojos grandes y redondos; movimiento amigable; aura reducida. | Mayor presencia; escala orientativa ×1.4–×1.7; postura dominante o de acecho; ojos almendrados, iris elemental y pupila rasgada; ceja definida; arma natural; rasgo que rompe silueta; relieves/emisivos y aura por rareza. |
| Debe anticipar la especie, no ser una forma genérica. | Debe reconocerse como el mismo monstruo: preservar cara, color base y rasgo firma. Ferocidad heroica, no terror; sin sangre, heridas ni ojos inyectados. |

### Pipeline de aprobación

Ficha de especie → tres siluetas negras legibles a 64 px → Brote 3/4 frontal → Tallado 3/4 frontal →
cabeza del Tallado en tres vistas → hojas de giro → seis expresiones por forma → paleta/materiales →
carta final → revisión cultural y de originalidad → aprobación 2D → malla 3D, retopología/UV, rig, LOD,
animación e integración/validación en Roblox Studio.

### Herramientas del pipeline acordado

Gemini: bocetos y exploración 2D. Meshy + Claude: apoyo al modelado 3D, iteración y preparación.
Roblox Studio: integración y validación. Las salidas automáticas siempre requieren revisión humana.

### Los tres iniciales

| BROTE → TALLADO | ELEMENTO / ROL | IDENTIDAD A PRESERVAR |
|---|---|---|
| Kuachi → Ascuacho | Fuego / Atacante | Tlacuache del relato mazateco que roba el fuego + horno de comal; bolsa-horno y cola vinculada a brasas/ceniza. |
| Xolumi → Xolossus | Agua / Soporte | Ajolote + tema de transformación para no desaparecer (sin representar deidad) + barro negro de Oaxaca; branquias y regeneración. |
| Teselo → Mitlaxis | Tierra / Defensor | Tortuga + eco del mito de la tortuga que sostiene el cielo + grecas de Mitla; caparazón-fortaleza y disco/anillos celestes. |

### Elección inicial

Tres huevos de copal visualmente equivalentes; señales cromáticas sutiles de brasa, barro y greca. La
elección es emocional, no una comparación de estadísticas. Tras eclosionar, comunicar que los otros
dos iniciales se podrán conseguir después.

---

## Página 5 · 03 / Mundo

### El mundo completo y el primer espacio

La Biblia define un valle central con lotes y la Torre del Nexo, rodeado de biomas que se abren con la
historia. El mundo completo permanece como visión de largo plazo; la primera versión solo necesita un
Valle Copal convincente.

| BIOMA | IDENTIDAD | ACTO | ELEMENTOS NATIVOS | GUARDIÁN |
|---|---|---|---|---|
| Valle Copal | Centro, hogar, ríos, chinampas, mercados y Torre | Inicio/I | Flora, Tierra, Aire | Copalia |
| Marea Coralina | Arrecifes, manglares, cenotes y ruinas sumergidas | II | Agua, Mente, Astral | Marejadra |
| Cumbre Brasa | Volcanes, hornos, herrerías y lava domesticada | III | Fuego, Metal, Tierra | Obsidárion |
| Meseta Fulgor | Tormentas, cobre, molinos y autómatas | IV | Rayo, Artificio, Metal | Fulgorón |
| Velo Astral | Nubes nocturnas, faroles, auroras y constelaciones | V | Luz, Sombra, Mente, Astral | Noctelia |

### Estados y regla de origen

Marea Coralina y Meseta Fulgor están marcados como propuestas en la fuente. Todos los monstruos
pueden vivir en cualquier lote; los nativos obtienen +10 % Monedas y +10 % XP en su bioma de origen.

### Valle Copal / Torre del Nexo

Valle Copal es el primer hub: Lote Hogar, hábitats, inventario, vitrina, ríos/chinampas y acceso a la
Torre. La Torre concentra Criadero, Tablón de Encargos, Portal de Arenas, Círculo de Encuentro, Repisa
de Cofres, Gabinete que Camina y Mirador de Biomas. Las mismas estaciones deben ser accesibles desde UI
rápida; móvil: interacción simple con el Gran Nexo.

### Lotes

| LOTE | PRECIO | DESBLOQUEO | USO |
|---|---|---|---|
| Hogar | Gratis | Inicio | Inventario, 1 hábitat y vitrina |
| Valle | 2,500 Monedas | Capítulo 1 | 1 hábitat |
| Marea | 10,000 Monedas | Acto I completo | 1 hábitat; bono Agua |
| Cumbre | 40,000 Monedas | Acto II completo | 1 hábitat; bono Fuego/Metal |
| Fulgor | 150,000 Monedas | Acto III completo | 1 hábitat; bono Rayo/Artificio |
| Velo | 300,000 Monedas | Acto IV completo | 1 hábitat; bono Luz/Sombra/Mente/Astral |
| Exhibición | 600 Gemas o 400,000 Monedas | Nivel de cuenta 20 | Decorativo, no produce Monedas |

### Reglas de hogar

Un hábitat tiene cuatro slots. Inventario inicial de 40, ampliable en +10 por 5,000 Monedas hasta 100.
Los monstruos en inventario no producen ni entrenan. La vitrina del Lote Hogar muestra tres Tallados.
El lote de Exhibición no produce.

---

## Página 6 · 04 / Alcance

### Primero un vertical slice memorable

> **Objetivo de la Fase 1**
>
> Una pequeña porción real del juego, completa de principio a fin, con valor visual, sistemas
> conectados y datos persistentes. No construir cinco biomas, cincuenta modelos finales y todos los
> sistemas antes de comprobar que el bucle inicial es divertido.

### Dentro de Fase 1

| SISTEMA | ENTREGABLE DE LA FASE 1 |
|---|---|
| Mundo | Valle Copal compacto; spawn, Gran Nexo, accesos funcionales y Lote Hogar. |
| Onboarding | Introducción breve y salt-able; tres huevos iniciales equivalentes; selección intuitiva. |
| Eclosión | Eclosión funcional; crear PetInstance único; ficha/álbum básico. |
| Monstruo acompañante | Un acompañante; seguimiento suave; estados idle/move/reacción; recuperación si se pierde la referencia. |
| Santuario | Un lote y un hábitat; cuatro slots; inventario; colocar/retirar con validación de servidor. |
| Cuidado | Alimentación, XP, nivel, Vínculo y progreso legible. |
| Combate PvE | Primer combate 1v1 contra Opaco; selección de habilidad; daño servidor; resultado y recompensa. |
| Persistencia | Perfil versionado; guardado, reconexión y protección frente a duplicados. |
| Interfaz/analítica | UI mobile-first; eventos de onboarding y embudo de primer combate. |

### Fuera de Fase 1

Cinco biomas completos, 50 modelos finales, todos los actos/jefes, crianza y sus 42 recetas,
incubación completa, cofres aleatorios, PvP/2v2/torneos, trading, gremios, suscripción y compras Robux
reales. La arquitectura debe permitirlos, pero no hay que anticipar su implementación.

### Roadmap

| FASE | RESULTADO | CONTENIDO |
|---|---|---|
| 0 · Auditoría | Base lista | Repo, PDF, herramientas, Studio/MCP, Rojo/Git, riesgos y backup. |
| 1 · Vertical slice | Núcleo jugable | Valle, tres iniciales provisionales, eclosión, follow, lote, cuidado, XP, PvE, recompensa y guardado. |
| 2 · Primer lanzamiento | Juego publicable | Más especies aprobadas, Tallados, álbum, incubadora, misiones, cofres ganados jugando y primer acto. |
| 3 · Retención | Mundo vivo | Visitas, exhibiciones, eventos configurables, personalización y cosméticos deterministas. |
| 4 · Expansión | Universo completo | Crianza, biomas/actos/guardianes, PvP, temporadas, torneos y posible suscripción. |

---

## Página 7 · 05 / Ingeniería

### Arquitectura y disciplina técnica

Stack objetivo: Roblox Studio + Luau `--!strict`; Git para control de versiones; Rojo para
sincronización basada en archivos si procede; Roblox Studio MCP para inspeccionar, editar y probar el
lugar desde Claude Code. No declarar conexión o integración si no está realmente disponible.

### Capas

| CAPA | RESPONSABILIDAD |
|---|---|
| Core | Bootstrap, configuración, logging, dependencias y servicios comunes. |
| Gameplay | Pet, Inventory, Hatching, Progression, Bond, Battle y Rewards. |
| World | Spawn, Valle, lotes, hábitats, estaciones e interacciones. |
| Data | Perfiles, persistencia, sesión, migraciones y recuperación. |
| Client/UI | Controladores, interfaces, efectos y accesibilidad. |
| Analytics/LiveOps | Eventos, medición, configuración de eventos y recompensas futuras. |

### Datos de especie vs. criatura individual

SpeciesDefinition: SpeciesId, Brote, Tallado, rareza, elementos, rol, familia, bioma, stats,
habilidades, talento, firma, Golpe Nexo, rasgo firma, procedencia y configuración visual. PetInstance:
PetId único, SpeciesId, forma, nivel, XP, Vínculo, rasgos/linaje futuro, fecha y fuente de adquisición.
Nunca confundir definición compartida con propiedad individual.

### Seguridad y autoridad

El servidor es autoridad de moneda, inventario, posesión, huevos, eclosiones, evolución, XP, Vínculo,
daño, estados, resultados y recompensas. El cliente solicita; el servidor valida y decide. Cada Remote
valida tipo, ownership, parámetros, estado, proximidad, frecuencia y duplicados. No aceptar del cliente
estadísticas, daño ni recompensas.

### Persistencia

Perfil versionado: schemaVersion, Monedas/Gemas, mascotas, inventario, hábitats, progreso, tutorial,
desbloqueos, misiones y estados pendientes. Usar DataStoreService, UpdateAsync cuando corresponda,
retries controlados, autosave, cierre y sesión exclusiva para evitar escrituras concurrentes. Incluir
migraciones. Las pruebas destructivas usan almacenamiento separado de producción.

### Rendimiento

Mobile-first. Streaming/carga por zonas, carga diferida de modelos, no cargar las 50 especies para
mostrar tres, limitar partículas/animaciones, reutilizar geometría y validar memoria, triángulos,
replicación y un dispositivo móvil de gama baja. Los presupuestos técnicos exactos quedan en la fuente
p. 120 y se consideran objetivos que deben medirse.

---

## Página 8 · 06 / Negocio y validación

### Rentabilidad sostenible, no atajos

La monetización debe desarrollarse después de demostrar que el juego retiene jugadores. El modelo
comercial preferido es vender identidad y personalización, no superioridad competitiva.

### Productos futuros prioritarios

Auras, accesorios, efectos de evolución, animaciones, decoración, emotes, marcos, títulos y paquetes
temáticos de contenido fijo/visible. La suscripción mensual Círculo del Tallador se mantiene en la
Biblia como propuesta histórica, pero se pospone hasta que exista contenido suficiente y evidencia de
retención.

### Reglas económicas

Monedas: recurso habitual ganado jugando. Gemas: recurso premium separado. Progreso principal
disponible sin pagar. No pay-to-win, niveles permanentes vendidos ni ventajas competitivas decisivas.
Fase 1 sin compras reales, huevos/cajas aleatorios pagados, potenciadores de suerte ni intercambio. Las
propuestas originales de precios, cajas, Robux y pase siguen íntegramente en el apéndice, como
referencia histórica, no como configuración activada.

> **Cumplimiento antes de comercializar**
>
> La sección de políticas de la Biblia describe el estado que consideraba vigente el 2 nov 2026. No
> asumir que sigue vigente al lanzamiento. Verificar la documentación oficial vigente de Roblox en el
> momento de implementar Paid Random Items, PolicyService y MarketplaceService. No codificar listas
> estáticas de países/regiones.

### Analítica

Registrar onboarding_started, intro_skipped/completed, starter_egg_selected, hatch_completed,
pet_follow_started, habitat_opened, first_feed, first_bond_gain, first_battle_started/completed,
first_reward_claimed, tutorial_completed, session_end y data_save_status. Medir abandono por paso,
tiempo a primera recompensa, finalización, sesiones y retorno. Cuando haya tráfico suficiente, analizar
cohortes D1/D7/D30, DAU/WAU/MAU, duración de sesión y conversión. No inventar resultados ni metas.

### Aceptación de Fase 1

Cuenta nueva → elegir cada inicial → eclosionar → acompañante → consultar ficha/inventario → alimentar
→ ganar XP y Vínculo → usar lote y slots → jugar PvE → recibir recompensa calculada por servidor →
desconectar y reconectar sin pérdida ni duplicación. UI funcional móvil/PC; sin errores críticos
conocidos; documentación y siguiente tarea clara.

### Instrucciones operativas para Claude Code

Auditar antes de modificar; backup si existe proyecto; leer este documento; registrar discrepancias;
crear CLAUDE.md, README y docs de diseño/técnica/MVP/arte/monetización/roadmap; tomar decisiones no
bloqueantes de forma provisional; implementar en incrementos y probar cada flujo; usar subagentes solo
cuando sean independientes; no publicar ni gastar Robux ni alterar datos reales sin autorización;
reportar archivos, pruebas reales, resultados y limitaciones.

---

## Página 9 · 07 / Estado de la v5.0

### Qué cambió, qué se mantiene y qué requiere decisión

La Biblia v5.0 documenta una reconstrucción de los 50 monstruos y varias correcciones de consistencia.
Los estados HECHO / PROPUESTA / PREGUNTA se mantienen como en la fuente.

| TEMA | CAMBIO/ESTADO FUENTE |
|---|---|
| Arte y evolución | Brotes tiernos; Tallados imponentes con mirada feroz, colmillos, piezas que rompen silueta y aura. HECHO. |
| Mezcla mítica | Animal + mito/leyenda + oficio/objeto + elemento; elemento y rareza se conservan. HECHO. |
| Rediseños | Canoaviento→Engrifo; Nubarrón→Yetormenta; Chinampero→Castorre; astas de chacalope y pico-navaja. HECHO. |
| Nombres/cartas | 50 especies renombradas; sin diminutivos; cartas con fondo de bioma, pedestal y marco por rareza. HECHO. |
| Biomas | Valle Copal centro; Marea Coralina y Meseta Fulgor nuevos biomas. PROPUESTA. |
| Lotes | Lote Hogar, lote por bioma, exhibición, inventario y bono nativo. HECHO. |
| Cofres | Madera Común 30 % y Raro 6 %; Oro Épico 15 %; Diamante redistribuido; Platino excluido. HECHO. |
| Pase | Monedas/Gemas y cofres Plata/Oro alternados; 399–799 R$ y premio final sujetos a decisión. PREGUNTA. |
| Aventura | Seis actos diseñados; propuesta posterior de lanzamiento con dos actos y luego uno por temporada. |
| Multiplicadores | ×1.5/×0.75 mantenidos provisionalmente; simulación recomienda ×1.25/×0.85. PREGUNTA. |
| Divisiones/Misterio | Etapas de talla y tope 8 cofres/día. PROPUESTA. Nexum presupuesto 120/coste 5. PROPUESTA. |
| Torneo | 3v3 solo torneo individual, no por equipos. HECHO. |

### Inconsistencias corregidas en la fuente

Cofres del pase pasan a contenido fijo y visible; criadero centralizado en la Torre; 2v2 pasa a turnos
de 20 s + reserva de 45 s y límite 6 min; se reduce la propuesta del tope de cofres diarios; Nexum deja
de ser superior en presupuesto; reparto de catálogo corregido a 14·8·8·7·12; se corrigen nombres
diminutivos y siluetas repetidas; se advierte que ×1.5/×0.75 puede sobrevalorar ventaja elemental.

> **93 preguntas abiertas**
>
> La Biblia incluye 93 preguntas para v5.1 con una propuesta actual en cada una. No hay respuestas del
> usuario incorporadas en la fuente cargada. Se conserva íntegramente el cuestionario en el apéndice;
> Claude debe tratarlo como pendientes, no contestarlo en nombre del usuario.

---
## Página 10 · Apéndice A / Referencia íntegra

### Especificación textual de la Biblia v5.0

Transcripción compactada de páginas de contenido. Se preservan términos y valores originales; se
quitaron cabeceras/pies repetidos y páginas separadoras. Consultar el número de página original en
cada bloque.

### Fuente PDF · página 3 — La v5 en una página

Qué pediste en tus notas y qué se hizo. Lo marcado como «Propuesta» o «Pregunta» se resuelve con tus
respuestas al final del documento.

| TEMA | CAMBIO EN LA V5 | ESTADO |
|---|---|---|
| Arte de los monstruos | Brotes tiernos; Tallados imponentes con mirada feroz, colmillos, piezas que rompen la silueta y aura | HECHO |
| Mezcla mítica | Cada especie combina animal + leyenda o mito + oficio + elemento; elemento y rareza se conservan | HECHO |
| Rediseños | Canoaviento → Engrifo (grifo de cuerda) · Nubarrón → Yetormenta (yeti) · Chinampero → Castorre (castor) · astas de chacalope, pico-navaja | HECHO |
| Nombres | 50 especies renombradas: sin diminutivos, más juguetones, disruptivos y bilingües | HECHO |
| Cartas coleccionables | Fondo de bioma, pedestal y marco por rareza en todas las fichas | HECHO |
| Biomas | Valle Copal es el centro con lotes; nuevos Marea Coralina (agua) y Meseta Fulgor (rayo) | PROPUESTA |
| Lotes | Lote Hogar, un lote por bioma, lote de exhibición, inventario y bono nativo | HECHO |
| Cofres | Madera con Huevo Común 30 % y Raro 6 %; Oro con Épico 15 %; Diamante redistribuido; Platino sigue fuera | HECHO |
| Pase mensual | Gemas, Monedas y cofres de Plata y Oro alternados; precio 399–799 R$ (≈ US$5–10) | PREGUNTA |
| Recompensa final del pase | Huevo Épico cada mes + Legendario por racha de 3 meses | PREGUNTA |
| Incubadora | Se mantiene; el huevo ahora flota con anillos y haz de luz | HECHO |
| Modo aventura | Seis actos, regiones, etapas, estrellas, enemigos, jefes y recompensas | HECHO |
| Torre del Nexo | Concentra criadero, encargos, misiones diarias, círculo de encuentro y arenas | HECHO |
| Seres Sagrados | Se conservan y suman Marejadra y Fulgorón; tres Guardianes Velados para temporadas | HECHO |
| Introducción animada | Guion de 60 s en 8 planos | HECHO |
| Multiplicadores | Se mantienen ×1,5 / ×0,75 provisionalmente; simulación y recomendación ×1,25 / ×0,85 | PREGUNTA |
| Divisiones | Esbozo · Gubia · Relieve · Filigrana · Obra Maestra · Nexo Eterno; tope de 8 cofres al día | PROPUESTA |
| Misterio | Nexum como alternativa estratégica: presupuesto 120 y coste 5 | PROPUESTA |
| Torneo 3v3 | Solo torneos individuales | HECHO |

### Fuente PDF · página 4 — Lo que se mantiene y lo que se corrigió

Todo lo que tus notas no mencionan o dicen mantener queda igual que en la v4. Además se corrigieron
inconsistencias que aparecieron al revisar.

**SE MANTIENE IGUAL**

- ✓ Arena 1v1 con hasta 3 monstruos y Arena 2v2 con hasta 2 por jugador.
- ✓ Monedas como recurso habitual y Gemas como moneda premium.
- ✓ Incubación: 5 min · 20 min · 2 h · 8 h · 24 h · 72 h.
- ✓ Crianza: reglas por pareja, 42 recetas, techo de rareza, herencia y rasgos.
- ✓ Economía general, precios en Monedas y Gemas, paquetes de Robux y ritmo de progreso.
- ✓ Cofres Madera, Plata, Oro, Épico, Diamante y Nexo (sin Platino).
- ✓ Bucle: eclosionar, cuidar, entrenar, explorar, competir y criar.
- ✓ Sesiones de 5, 20 y 60 minutos.
- ✓ Ataques, Firmas, Talentos y Golpes Nexo de cada especie.
- ✓ Elemento y rareza de las 50 especies.
- ✓ Rueda de ventajas (provisional) y presupuesto de atributos.
- ✓ Seres Sagrados: Garza de Raíces, Coloso de la Fragua y Medusa del Velo.

**INCONSISTENCIAS CORREGIDAS**

| HALLAZGO | SOLUCIÓN V5 |
|---|---|
| Pase sin Monedas en la v4 | Tus notas ahora piden Monedas en el pase. Se incluyen; por eso todo lo aleatorio que se compra con Monedas pasa a tratarse como Paid Random Item (probabilidades + PolicyService). |
| Cofres del pase aleatorios | Una suscripción con cofres aleatorios es entera un Paid Random Item. En la v5 los cofres del pase tienen contenido fijo y visible. |
| Criadero en dos lugares | La v4 lo ponía en el santuario y en la Torre. Ahora solo en la Torre del Nexo. |
| 12 cofres de victoria al día | Los referentes dan 3–6. Se baja a 8 y se pregunta si 6. |
| 2v2 en 3–4,5 min con turnos de 25 s | Irreal con cuatro jugadores. Turno de 20 s + reserva de 45 s y límite de 6 min. |
| Misterio por encima de Legendarios | Presupuesto 128 y coste 6. Ahora 120 y coste 5: alternativa, no superior. |
| Velo Astral sobrecargado | 18 especies en un bioma. Con cinco biomas el reparto queda en 14 · 8 · 8 · 7 · 12. |
| Nombres con diminutivo | Catorce terminaban en -ín o -ito. Todos cambiados. |
| Siluetas repetidas | Nubarrón y Brumánima eran dos flotantes redondos. Nubarrón pasa a yeti bípedo. |
| Común con ventaja vence a Legendario | Con ×1,5 un Común con ventaja gana al 81 %. Se documenta y se pregunta. *(continúa en la p. 11)* |

---

## Página 11 · Mapa del mundo, Valle Copal, lotes y biomas

### Fuente PDF · página 6 — Mapa del mundo

Valle Copal es el corazón: ahí vive el jugador y está la Torre del Nexo. Cada bioma se abre con un acto
del modo aventura y tiene su propio lote, su guardián y sus monstruos nativos.

Rótulos del mapa: Velo Astral (Acto V · noche y cielos) · Torre del Nexo (Criadero · arenas ·
encargos) · Cumbre Brasa (Acto III · volcanes y forjas) · Valle Copal (Centro · lotes y Torre del Nexo)
· Marea Coralina (Acto II · arrecifes (propuesta)) · Meseta Fulgor (Acto IV · tormentas (propuesta)).

| BIOMA | PAPEL | SE ABRE EN | ELEMENTOS NATIVOS | GUARDIÁN |
|---|---|---|---|---|
| Valle Copal | Centro · hogar del jugador | Inicio · Acto I | Flora Tierra Aire | Copalia |
| Cumbre Brasa | Volcanes y forjas | Acto III | Fuego Metal Tierra | Obsidárion |
| Marea Coralina | Bioma acuático (propuesta) | Acto II | Agua Mente Astral | Marejadra |
| Meseta Fulgor | Bioma eléctrico (propuesta) | Acto IV | Rayo Artificio Metal | Fulgorón |
| Velo Astral | Noche y cielos | Acto V | Luz Sombra Mente Astral | Noctelia |

**CUALQUIER MONSTRUO, CUALQUIER BIOMA.** Todos los monstruos pueden vivir en cualquier lote. Los
nativos reciben +10 % de Monedas y +10 % de XP para monstruos en su bioma de origen.

### Fuente PDF · página 7 — Valle Copal: el centro

La zona central donde el jugador tiene su hogar: lotes, hábitats, inventario y espacio para colocar y
mostrar a sus monstruos. Desde aquí se viaja a los demás biomas.

Rótulos del plano: Lote Hogar (Inventario · hábitat · vitrina) · Portal a los lotes de bioma (Cumbre ·
Marea · Fulgor · Velo) · Torre del Nexo (Criadero · Encargos · Arenas · Círculo) · Lote del Valle (2.º
hábitat del Valle) · Plaza de Exhibición (Muestra tus Tallados).

| INVENTARIO (VIVERO) | COLOCAR MONSTRUOS | LO QUE HAY EN EL VALLE |
|---|---|---|
| Inventario de la Torre: 40 monstruos (no producen). +10 espacios por 5 000 Monedas, hasta 100. Los monstruos del inventario no producen ni entrenan; se pueden mover a un hábitat en cualquier momento. | 4 monstruos por hábitat. Arrastrar desde el inventario al hábitat. La vitrina del Lote Hogar muestra 3 Tallados a los visitantes. | Torre del Nexo y Gabinete que Camina. Mercado de comida y accesorios. Ríos y chinampas para paseos con tus monstruos. |

**NATIVOS DEL VALLE (14):** Ascuacho Xolossus Mitlaxis Cantagólem Navajazul Hercuerno Candelux
[el resto de la lista no aparece en la extracción]

### Fuente PDF · página 8 — Lotes y parcelas

Los lotes son los pedazos de tierra donde viven tus monstruos. Empiezas con el Lote Hogar en el Valle y
compras un lote por bioma conforme avanzas en la historia.

Esquema: Lote Hogar (Inicio) → Lote del Valle (Capítulo 1) → Marea (tras Acto I) → Cumbre (tras Acto
II) → Fulgor (tras Acto III) → Velo (tras Acto IV).

| LOTE | BIOMA | PRECIO | SE DESBLOQUEA | QUÉ TIENE |
|---|---|---|---|---|
| Lote Hogar | Valle Copal | Gratis | Inicio | Inventario, 1 hábitat y vitrina de exhibición |
| Lote del Valle | Valle Copal | 2 500 Monedas | Capítulo 1 | 1 hábitat |
| Lote de la Marea | Marea Coralina | 10 000 Monedas | Acto I completo | 1 hábitat · bono para Agua |
| Lote de la Cumbre | Cumbre Brasa | 40 000 Monedas | Acto II completo | 1 hábitat · bono para Fuego y Metal |
| Lote del Fulgor | Meseta Fulgor | 150 000 Monedas | Acto III completo | 1 hábitat · bono para Rayo y Artificio |
| Lote del Velo | Velo Astral | 300 000 Monedas | Acto IV completo | 1 hábitat · bono para Luz, Sombra, Mente y Astral |
| Lote de Exhibición | Cualquier bioma | 600 Gemas o 400 000 Monedas | Nivel de cuenta 20 | Decorativo: no produce Monedas |

**ANATOMÍA DE UN LOTE:** Hábitat · 4 lugares · Comedero · Decoración · Recolector de Monedas · bono
nativo +10 %.

**BONO NATIVO:** +10 % de Monedas y +10 % de XP para monstruos en su bioma de origen. Ejemplo: un
Magmadillo en el Lote de la Cumbre produce 10 % más.

**ECONOMÍA IGUAL QUE LA V4:** Los primeros cinco precios son los mismos de las parcelas de la v4
(gratis, 2 500, 10 000, 40 000 y 150 000); el Lote del Velo (300 000) es el sexto lote productivo y el
de Exhibición sigue sin producir Monedas. Cada lote de bioma se abre cuando empieza su acto.

**POR DECIDIR:** ¿Ampliar un lote a 2 hábitats? ¿Lotes de distinto tamaño? Ver preguntas al final.

### Fuente PDF · página 9 — Los cinco biomas (1/2)

Cada bioma tiene paleta, música, monstruos nativos y un guardián. Marea Coralina y Meseta Fulgor son
propuestas nuevas: se confirman en las preguntas.

**Valle Copal** — CENTRO · HOGAR DEL JUGADOR · INICIO · ACTO I
El corazón del mundo: ríos, chinampas, talleres y mercados alrededor de la Torre del Nexo. Aquí está el
Lote Hogar con inventario, hábitats y el lugar para mostrar a tus monstruos.
Nativos con bono: Comunes y Raros de Flora, Tierra y Aire · Elementos: Flora Tierra Aire ·
Guardián: Copalia, la Garza de Raíces.
Monstruos: Ascuacho Xolossus Mitlaxis Cantagólem Navajazul Hercuerno Candelux Faroibex.

**Cumbre Brasa** — VOLCANES Y FORJAS · ACTO III
Volcanes, hornos de barro, herrerías y hojalata. Atardeceres naranjas y ríos de lava domesticada.
Nativos con bono: Fuego y Metal · Elementos: Fuego Metal Tierra · Guardián: Obsidárion, el Coloso de
la Fragua.
Monstruos: Magmadillo Quiotazo Coatitán Magmacrán Grullacandil Zopilatón Gemaboa Pirotoro.

**Marea Coralina** — BIOMA ACUÁTICO (PROPUESTA) · ACTO II
Arrecifes de coral, manglares y cenotes conectados por túneles de luz. Cuevas con medusas y ruinas
sumergidas.
Nativos con bono: Agua · Elementos: Agua Mente Astral · Guardián: Marejadra, el Hipocampo de Coral.
Monstruos: Mantaraz Krakensa Fatuoscuro Alamar Lorapiente Cometaura Leviacielo Gemitrueno.

### Fuente PDF · página 10 — Los cinco biomas (2/2)

**Meseta Fulgor** — BIOMA ELÉCTRICO (PROPUESTA) · ACTO IV
Una meseta de tormentas perpetuas, torres de cobre, molinos y talleres de autómatas que se cargan con
cada rayo.
Nativos con bono: Rayo y Artificio · Elementos: Rayo Artificio Metal · Guardián: Fulgorón, el Tigre
del Trueno.
Monstruos: Chicharrayo Turbinón Voltalope Fulminave Mechalata Fulgurila Engrifo.

**Velo Astral** — NOCHE Y CIELOS · ACTO V
Nubes de noche, faroles flotantes, auroras y constelaciones que se pueden pisar.
Nativos con bono: Luz, Sombra, Mente y Astral · Elementos: Luz Sombra Mente Astral · Guardián:
Noctelia, la Medusa del Velo.
Monstruos: Yetormenta Lunatajo Batraluna Corvidúo Farolánima Aracnógrafa Brujalada Auroribú.

**REPARTO DEL CATÁLOGO** *(continúa en la p. 12)*: Valle Copal: 14 · Cumbre Brasa: 8 · Marea Coralina:
8 · Meseta Fulgor: 7 · Velo Astral: 12 · Torre del Nexo: 1 (Nexum).

---

## Página 12 · Torre del Nexo, Gabinete que Camina y Seres Sagrados

### Fuente PDF · página 11 — La Torre del Nexo: el árbol como menú

El Gran Nexo es el centro social y el menú principal. Cada función del juego es una estación física
alrededor del árbol, para que el menú se recorra caminando.

Estaciones del esquema: Criadero (Mezcla e incubadoras) · Tablón de Encargos (Misiones diarias) ·
Portal de Arenas (1v1 · 2v2) · Círculo de Encuentro (Amigos y social) · Repisa de Cofres (Abrir premios)
· Mirador de Biomas (Modo aventura) · Gabinete que Camina (Vitrina y cofres).

| ESTACIÓN | QUÉ SE HACE |
|---|---|
| Gabinete que Camina | Tienda: Vitrina de huevos de especie visible, accesorios y mostrador de cofres con probabilidades a la vista. |
| Repisa de Cofres | Cofres ganados en arena e historia; se abren al instante con animación por rareza. |
| Portal de Arenas | Arena 1v1, Arena 2v2 (con amigo o emparejamiento) y Arena Equilibrada. |
| Criadero | Mezcla de dos monstruos e incubadoras (1 a 5 ranuras). |
| Tablón de Encargos | 3 encargos diarios y 1 semanal; recompensas en Monedas y cofres de Madera o Plata. |
| Círculo de Encuentro | Lugar social: emotes, visitar santuarios de amigos y, en fase 2, intercambio de monstruos ganados jugando. |
| Mirador de Biomas | Entrada al modo aventura y a los eventos de bioma. |

**ACCESOS RÁPIDOS:** Las mismas estaciones están en un menú radial en pantalla para quien no quiera
caminar. En móvil, un toque en el tronco abre el menú.

### Fuente PDF · página 12 — El Gabinete que Camina

Un Nexum anciano que el Tallador dejó a cargo de guardar sus tallas. Camina alrededor del árbol y abre
sus cajones para vender.

**CAJONES DE LA TIENDA**

| CAJÓN | QUÉ VENDE | MONEDA |
|---|---|---|
| Vitrina | Huevos de especie visible: 3 Comunes al día, 2 Raros, 1 Épico y 1 Legendario por semana | Monedas o Gemas |
| Accesorios | Sombreros, rebozos, alas de papel, estelas y auras cosméticas | Monedas (básicos) o Gemas (premium) |
| Despensa | Raciones, Festines y Raciones Doradas | Monedas o Gemas |
| Cofres | Madera, Plata y Oro (Monedas); Oro, Épico, Diamante y Nexo (Gemas) | Ambas, con probabilidades visibles |
| Taller | Mejoras de hábitat, lotes y ranuras de incubadora | Monedas; el Lote de Exhibición y la 4.ª ranura también con Gemas |

El Gabinete anciano (tienda) es el adulto de la especie Nexum. El jugador recibe su propio Nexum al
final del Acto III.

**PERSONALIDAD:** Ceremonioso, coleccionista y bromista. Habla por cajones: cada cajón tiene su voz.
Nunca miente sobre lo que hay dentro.

**FRASES:**

- «Este cajón guarda un huevo de Agavo. Lo que ves es lo que te llevas.»
- «Mis cofres sí tienen sorpresa, así que te enseño los números antes.»
- «¿Otro cofre? Primero tu Vínculo; tus monstruos tienen hambre.»

**REGLA DEL CAJÓN ABIERTO:** Cada compra aleatoria abre primero un cajón con la lista completa de
premios y sus porcentajes, incluida la probabilidad de cada especie. Sin esa pantalla no hay botón de
compra.

**ROTACIÓN:** La Vitrina rota cada día a las 00:00 (hora del servidor) y es igual para todos los
jugadores; así se puede anunciar en redes qué Legendario está a la venta esa semana.

**EVITAR:** Ofertas con temporizador agresivo, «último aviso» o precios tachados falsos. El público es
joven.

### Fuente PDF · página 13 — Seres Sagrados del Nexo (1/3)

Seis guardianes originales, uno por bioma y uno en la Torre. Son jefes opacados del modo aventura; al
restaurarlos entran al Cofre Nexo. No representan seres sagrados de ninguna cultura real.

Etiquetas de elementos de las dos tarjetas, en el orden de la extracción: Flora · Agua · Agua · Mente ·
Luz · Luz [reparto por tarjeta ilegible en la extracción].

**Copalia, la Garza de Raíces** — Opacado · ACTO I · VALLE COPAL
Garza colosal cuyas patas son raíces y cuyas alas están tejidas de hojas y faroles. Guardiana del Valle
Copal.
Opacada: las raíces se secan, los faroles se apagan y el valle pierde el color.
Talento: Raíz Madre. Cura 6 % al equipo al final de cada turno. · Bosque de Faroles: Golpe Nexo · 120.
Cura 40 % al equipo.
Al restaurarlo: Al restaurarla, los hábitats del Valle producen +10 % de XP.

**Marejadra, el Hipocampo de Coral** — Opacado · ACTO II · MAREA CORALINA
Hipocampo colosal con crin de coral vivo y una corona de perlas que guardan las memorias del mar.
Opacado: el coral se blanquea y las perlas se apagan.
Talento: Marea de Memoria. Al inicio de cada turno, el aliado recupera 5 % de VID. · Arrecife Vivo:
Golpe Nexo · 120. Escudo del 25 % al equipo y cura 20 %.
Al restaurarlo: Al restaurarlo, los lotes de la Marea Coralina producen +10 % de XP.

### Fuente PDF · página 14 — Seres Sagrados del Nexo (2/3)

**Obsidárion, el Coloso de la Fragua** — Opacado · ACTO III · CUMBRE BRASA · Fuego · Tierra · Metal
Coloso bípedo de obsidiana con un corazón de fragua y un escudo de comal. Guardián de la Cumbre Brasa.
Opacado: la fragua se enfría y la obsidiana se cubre de ceniza gris.
Talento: Fragua Interior. Sus ataques de Metal y Fuego hacen +15 %. · Erupción de Obsidiana: Golpe
Nexo · 130. Golpea a todos los rivales.
Al restaurarlo: Al restaurarlo, se desbloquea la mejora de hábitat de nivel 5.

**Fulgorón, el Tigre del Trueno** — Opacado · ACTO IV · MESETA FULGOR · Rayo · Aire · Artificio
Tigre de tormenta con bobinas de cobre en el lomo y rayas de relámpago; su rugido enciende las torres
de la meseta.
Opacado: las bobinas se oxidan y la tormenta se vuelve ceniza.
Talento: Tormenta Cargada. Cada ataque de Rayo le da +1 de Savia la primera vez por combate. · Rugido
de Mil Rayos: Golpe Nexo · 130. Golpea a todos los rivales y paraliza 20 %.
Al restaurarlo: Al restaurarlo, se desbloquea la Arena de Tormenta (evento semanal).

### Fuente PDF · página 15 — Seres Sagrados del Nexo (3/3)

**Noctelia, la Medusa del Velo** — Opacado · ACTO V · VELO ASTRAL · Astral · Sombra · Mente
Medusa inmensa que flota sobre el Velo Astral y teje la noche con sus tentáculos.
Opacada: sus estrellas se apagan y el velo se rasga.
Talento: Telar de Noche. Los rivales empiezan con −1 de Savia. · Noche Tejida: Golpe Nexo · 120. Duerme
a los rivales 1 turno.
Al restaurarlo: Al restaurarla, se abre el modo de combate nocturno con eventos semanales.

**Ánima del Nexo, la Primera Talla** — Opacado · FINAL · TORRE DEL NEXO · Luz · Artificio · Astral
La primera figura que talló el Tallador: un cuerpo de raíces con gubias flotantes y un núcleo de luz.
Opacada: el núcleo se vuelve gris y las gubias caen.
Talento: Gubia Viva. Sus especiales cuestan 1 de Savia menos una vez por combate. · Última Talla: Golpe
Nexo · 125. Copia el Golpe Nexo del rival.
Al restaurarlo: Al restaurarla, entrega el Huevo del Gabinete (Nexum).

**UNA COPIA POR CUENTA** *(continúa en la p. 13)*: Rareza Único (presupuesto 128, coste 6). Al
restaurar cada uno se entrega 1 Cofre Nexo. No se crían.

---

## Página 13 · Guardianes Velados y mezcla mítica por especie

### Fuente PDF · página 16 — Guardianes Velados

Figuras misteriosas que se ven a lo lejos antes de aparecer. Se introducen poco a poco, una por
temporada, para mantener la curiosidad y el deseo de completar la colección.

| GUARDIÁN | TEMPORADA | DESCRIPCIÓN |
|---|---|---|
| El Cartógrafo Velado | TEMPORADA 1 · RAREZA POR REVELAR | Una figura con un mapa por capa que deja huellas de tinta en las arenas. |
| La Bordadora de Nubes | TEMPORADA 2 · RAREZA POR REVELAR | Una silueta alada que cose tormentas con aguja de rayo. |
| El Relojero sin Rostro | TEMPORADA 3 · RAREZA POR REVELAR | Un gigante de engranes que detiene el tiempo por un turno. |

1. **Avistamiento.** Dos semanas antes de la temporada, la silueta aparece en el horizonte del Valle y
   en la pantalla de carga.
2. **Rastro.** Eventos semanales dejan pistas (huellas, plumas, engranes) que se coleccionan en el
   Códice.
3. **Revelación.** Con la temporada se abre su capítulo especial; al vencerlo entra al juego.

**POR DEFINIR CONTIGO:** Si los Guardianes Velados serán Únicos (Cofre Nexo) o una rareza nueva de
temporada. Ver preguntas.

### Fuente PDF · páginas 17–18 — Mezcla mítica por especie (1/2 y 2/2)

La inspiración de cada monstruo: mitos, leyendas, bestias, oficios y animales de México y del mundo.
Siempre como inspiración, nunca como copia de una figura sagrada.

| # | BROTE → TALLADO | RAREZA | MEZCLA MÍTICA | ORIGEN |
|---|---|---|---|---|
| 1 | Kuachi → Ascuacho | COMÚN | El tlacuache que robó el fuego (relato mazateco) + horno de comal. | México |
| 2 | Xolumi → Xolossus | COMÚN | Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la deidad) + barro negro de Oaxaca. | México |
| 3 | Teselo → Mitlaxis | COMÚN | Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla. | México + Eco chino |
| 4 | Comalú → Magmadillo | COMÚN | Salamandra de fuego del folclore europeo + armadillo + comal. | México |
| 5 | Rillip → Mantaraz | COMÚN | Mantarraya + listón de feria + estela de cometa marino. | México |
| 6 | Barrock → Cantagólem | COMÚN | Gólem de barro del folclore europeo + cántaro de mercado. | México |
| 7 | Yek → Yetormenta | COMÚN | Yeti de las montañas (folclore himalayo) + nube de tormenta + cuernos de borrego cimarrón. | Eco himalayo |
| 8 | Zunzi → Navajazul | COMÚN | Colibríes guerreros mexicas (solo el concepto, sin la deidad) + navaja de obsidiana. | México |
| 9 | Agavo → Quiotazo | COMÚN | Maguey y quiote + guardián de los campos. | México |
| 10 | Vainas → Hercuerno | COMÚN | Escarabajo hércules + vaina de huaje + sonaja. | México |
| 11 | Zizi → Chicharrayo | COMÚN | Cigarra de verano + tambor de feria + bobina de cobre. | México |
| 12 | Tinco → Coatitán | COMÚN | Coatí + armadura de hojalata repujada. | México |
| 13 | Cuerdo → Turbinón | COMÚN | Juguete de cuerda de feria + turbina industrial. | México |
| 14 | Okto → Krakensa | COMÚN | Kraken del folclore nórdico (solo el concepto) + caracola + tinta de sueño. | México |
| 15 | Murk → Lunatajo | COMÚN | Murciélago magueyero + luna creciente como hoz. | México |
| 16 | Bruma → Fatuoscuro | COMÚN | Fuego fatuo del folclore europeo + niebla de cenote. | México |
| 17 | Pabilo → Candelux | COMÚN | Codorniz + cirio de procesión + farol. | México |
| 18 | Lunk → Batraluna | COMÚN | Sapo de la luna (eco chino) + cráteres + metate volcánico. | México + Eco chino |
| 19 | Brinco → Voltalope | RARO | Chacalope del folclore norteamericano (liebre con astas) + liebre embaucadora africana. | Eco africano |
| 20 | Chispón → Fulminave | RARO | Ave de tormenta cuyo trueno sale de las alas (eco africano) + pararrayos. | Eco africano |
| 21 | Kroa → Corvidúo | RARO | Los cuervos del pensamiento y la memoria (eco nórdico) + espejo de obsidiana. | Eco nórdico |
| 22 | Lumbro → Faroibex | RARO | Íbice de montaña + faro + porcelana vidriada. | Ecos del Nexo |
| 23 | Picoso → Magmacrán | RARO | Alacrán + obsidiana + flujo de lava. | México |
| 24 | Kunko → Alamar | RARO | El pez Kun que se vuelve el ave Peng (eco chino). | Eco chino |
| 25 | Dientón → Castorre | RARO | Castor constructor (eco canadiense) + chinampa de Xochimilco + torre de troncos. | Eco canadiense |
| 26 | Cotorro → Lorapiente | RARO | Serpiente de humedal con cabeza de loro (eco guaraní) + manglar. | Eco sudamericano |
| 27 | Medu → Cometaura | RARO | Medusa + cometa + farol de papel de china. | Ecos del Nexo |
| 28 | Remache → Mechalata | RARO | Hojalatero + robot industrial de fábrica. | México |
| 29 | Linterno → Farolánima | RARO | Farol de papel calado + ánima de los caminos (sin referencias religiosas). | México |
| 30 | Garabato → Monomural | RARO | Monos artistas de los relatos mayas (inspiración, sin nombres) + muralismo. | Mesoamérica |
| 31 | Zanco → Grullacandil | RARO | Ave de una pata ligada al fuego (eco chino) + candil. | Eco chino |
| 32 | Ovillo → Aracnógrafa | RARO | Araña tejedora de los cuentos (eco africano) + telar de cintura + mapa. | Eco africano |
| 33 | Cempa → Cempasol | ÉPICO | Venado + cempasúchil + brasa dorada. | México |
| 34 | Cenoti → Leviacielo | ÉPICO | Leviatán (concepto de monstruo marino) + pez ciego de cenote + cielo estrellado. | México |
| 35 | Pelón → Zopilatón | ÉPICO | Zopilote rey + hojalata repujada + veleta. | México |
| 36 | Chaquiro → Fulgurila | ÉPICO | Monstruo de Gila + fulgurita + chaquira. | México |
| 37 | Guaca → Aráureo | ÉPICO | Guacamaya + vitral + sol tallado. | Eco sudamericano |
| 38 | Brujo → Brujalada | ÉPICO | Palomilla nocturna + rebozo bordado + luna. | México |
| 39 | Tizón → Tizonsierpe | ÉPICO | Serpiente de fuego que protege los campos (eco tupí). | Eco sudamericano |
| 40 | Tuerco → Engrifo | ÉPICO | Grifo de la mitología griega y medieval + relojería + aviación antigua. | Eco europeo |
| 41 | Boreal → Auroribú | ÉPICO | Caribú del norte + aurora boreal (eco canadiense). | Eco canadiense |
| 42 | Hilacho → Titeránima | ÉPICO | Marioneta de hilo + teatro de títeres europeo. | Ecos del Nexo (Europa) |
| 43 | Lumbrela → Papalumen | LEGENDARIO | Mariposa monarca (migración) + papel picado + linterna. | México |
| 44 | Geoda → Gemaboa | LEGENDARIO | Serpiente que guarda diamantes (eco sudafricano) + geoda. | Eco africano |
| 45 | Nébulo → Astrocorcel | LEGENDARIO | El corcel de ocho patas (eco nórdico) + constelación. | Eco nórdico |
| 46 | Bisi → Gemitrueno | LEGENDARIO | Serpiente alada de dos cabezas (eco andino) + nube de tormenta. | Eco andino |
| 47 | Petardo → Pirotoro | LEGENDARIO | Torito de pirotecnia de feria + castillo de fuegos. | México |
| 48 | Mediluna → Eclipsor | ÚNICO | Felino + eclipse + velo perlado e índigo. | Ecos del Nexo |
| 49 | Nácar → Aetherion | ÚNICO | Ballena gris + mapa celeste + brújula. | Ecos del Nexo |
| 50 | Nex → Nexum | MISTERIO | Gabinete de curiosidades + máquinas místicas de Remedios Varo + escaleras imposibles. | Surrealismo en México |

*(Las filas 1–20 están en la columna izquierda de la p. 13; la fila 21 en adelante, en la derecha; la
fuente divide la tabla entre sus páginas 17 y 18 a partir de la fila 26.)*

**SIGUEN EXCLUIDOS:** Ogopogo, Wendigo, Thunderbird, deidades (Xolotl, Itzpapalotl, Quetzalcóatl,
Camazotz…) y símbolos sagrados como el Sankofa convertido en monstruo.

### Fuente PDF · página 20 — Tierno al nacer, imponente al tallarse

La esencia se mantiene: los Brotes son pequeños, tiernos y sencillos. La evolución es el premio: el
Tallado debe ser más fuerte, más agresivo y más extravagante, para que todos quieran verlo.

| EJEMPLO | TALLADO |
|---|---|
| Brote · Xolumi → Tallado · Xolossus | Ajolote colosal de seis patas, erguido como un dragón de río; branquias de humo de copal, cicatrices doradas y boca con colmillos pequeños. |
| Brote · Tuerco → Tallado · Engrifo | Grifo mecánico de latón: cabeza de águila, cuerpo de felino, alas de plumas-engrane y hélice en la cola. |
| Brote · Yek → Tallado · Yetormenta | Yeti bípedo de pelaje de nube de tormenta, cuernos en espiral de viento y brazos larguísimos; ruge ventiscas. |

*(Este bloque continúa en la p. 14.)*

**LAS OCHO REGLAS DE LA EVOLUCIÓN**

| # | REGLA | QUÉ SIGNIFICA |
|---|---|---|
| 1 | Tamaño | ×1,4 a ×1,7; la cabeza baja de proporción y el cuerpo gana peso. |
| 2 | Postura | De cría sentada a acecho, guardia o vuelo: el peso hacia delante. |
| 3 | Mirada | Ojo almendrado con brillo del elemento y ceja marcada (página siguiente). |
| 4 | Arma natural | Colmillos, garras, cuernos, aguijones o pico-navaja según el animal. |
| 5 | Rompe la silueta | Una pieza grande que se reconoce en negro: anillos, astas, torre de troncos, hélice, cajones. |
| 6 | Talla y emisivo | Relieve tono sobre tono con luz solo dentro de los surcos. |
| 7 | Aura de rareza | Se ve sin leer: brillo, emisivo, oro, iridiscencia o geometría imposible. |
| 8 | Mismo monstruo | Cara, color base y rasgo firma se conservan: se reconoce al Brote. |

---

## Página 14 · La mirada, la fórmula de mezcla, rediseños y cartas

### Fuente PDF · página 21 — La mirada del Tallado

El cambio que más se nota con menos trabajo: el Brote conserva ojos grandes y redondos; el Tallado gana
un ojo almendrado con iris del color de su elemento, pupila rasgada, brillo y una ceja que le da
carácter.

- **BROTE (IZQUIERDA) Y TALLADO (DERECHA) POR ELEMENTO:** Fuego · Agua · Rayo · Sombra.
- **EN EL MONSTRUO COMPLETO:** Kuachi → Ascuacho · Tinco → Coatitán · Picoso → Magmacrán · Nébulo →
  Astrocorcel.

| EXPRESIONES DEL TALLADO | FEROZ, NO ATERRADOR | PARA EL 2D |
|---|---|---|
| Neutral concentrado, desafío, ataque (boca abierta y colmillos), victoria (sonrisa ladeada), cansado. Nunca llanto ni dolor explícito. | Sin sangre, heridas ni ojos rojos inyectados. La ferocidad viene de la forma y la postura, no del horror. Público de 9 a 16 años. | Pedir siempre la cabeza del Tallado en tres vistas con la mirada feroz antes del cuerpo completo: es el rasgo que define si funciona. |

### Fuente PDF · página 22 — Fórmula de mezcla mítica

Animal + mito o leyenda + oficio u objeto + elemento. Tres fuentes como mínimo para que ninguna
criatura copie una figura existente, y una historia que se pueda contar en una frase.

> **Animal** (Silueta y movimiento) + **Mito o leyenda** (Lo extraordinario) + **Oficio u objeto**
> (Material y textura) + **Elemento** (Color y efecto) = **Monstruo NEXORA** (Una frase y una silueta)

| MONSTRUO | ANIMAL | MITO | OFICIO | ELEMENTO |
|---|---|---|---|---|
| Yetormenta | Yeti | Yeti del Himalaya | Nube de tormenta | Aire |
| Engrifo | Grifo + felino | Grifo griego y medieval | Relojería y aviación | Aire + Artificio |
| Castorre | Castor | Constructor de diques | Chinampa de Xochimilco | Flora + Tierra |
| Krakensa | Pulpo | Kraken nórdico | Caracola y tinta | Mente |
| Voltalope | Liebre | Chacalope norteamericano | Pararrayos | Aire + Rayo |
| Fatuoscuro | Niebla | Fuego fatuo europeo | Cenote | Sombra |

**FUENTES DEL MUNDO:** Mexicana y mesoamericana, nórdica, china, africana, europea, sudamericana,
canadiense e himalaya. Las referencias de la tabla «Mezcla mítica por especie» (Parte I) son el punto
de partida de cada concepto 2D.

### Fuente PDF · página 23 — Rediseños de la v5 (1/2)

Mismo elemento y misma rareza; nuevo concepto o nuevo carácter. Los ataques, Firmas y Talentos no
cambian.

| CAMBIO | ANTES | AHORA | MEZCLA MÍTICA |
|---|---|---|---|
| v4 · Nubi → Nubarrón ⇒ v5 · Yek → Yetormenta | Nube-tecolote redonda, demasiado parecida a otros flotantes. | Yeti de tormenta bípedo: silueta alta, brazos largos y cuernos en espiral. | Yeti de las montañas (folclore himalayo) + nube de tormenta + cuernos de borrego cimarrón. |
| v4 · Pecarín → Chinampero ⇒ v5 · Dientón → Castorre | Pecarí con jardín: poco reconocible. | Castor arquitecto: dientes, cola de remo y torre-dique de troncos. | Castor constructor (eco canadiense) + chinampa de Xochimilco + torre de troncos. |
| v4 · Canoíta → Canoaviento ⇒ v5 · Tuerco → Engrifo | Canoa voladora: poco atractiva como monstruo. | Grifo de cuerda: cabeza de águila, cuerpo felino, alas de engranes y hélice. | Grifo de la mitología griega y medieval + relojería + aviación antigua. |

### Fuente PDF · página 24 — Rediseños de la v5 (2/2)

| CAMBIO | ANTES | AHORA | MEZCLA MÍTICA |
|---|---|---|---|
| v4 · Tronito → Liebrayo ⇒ v5 · Brinco → Voltalope | Liebre eléctrica sin rasgo extraordinario. | Chacalope: astas de rayo bifurcadas y colmillos. | Chacalope del folclore norteamericano (liebre con astas) + liebre embaucadora africana. |
| v4 · Zunzi → Zunzéfiro ⇒ v5 · Zunzi → Navajazul | Colibrí tierno en ambas formas. | Pico-navaja de obsidiana y mirada de guerrero. | Colibríes guerreros mexicas (solo el concepto, sin la deidad) + navaja de obsidiana. |
| v4 · Kuachi → Tlecuach ⇒ v5 · Kuachi → Ascuacho | Tallado con ojos de Brote. | Mirada feroz, colmillos y bolsa-horno al rojo (aplica a los 50 Tallados). | El tlacuache que robó el fuego (relato mazateco) + horno de comal. |

### Fuente PDF · página 25 — Cartas coleccionables

Cada monstruo se presenta como una carta: así se ve en el álbum, en la tienda y al eclosionar. El marco
dice la rareza, el fondo el bioma, y la colección completa da ganas de llenar los huecos.

Marcos de muestra: COMÚN · RARO · ÉPICO · LEGENDARIO · ÚNICO · MISTERIO.

*(Este bloque continúa en la p. 15.)*

**ANATOMÍA DE LA CARTA**

| PARTE | REGLA |
|---|---|
| Gema de rareza | Arriba a la izquierda: color de la rareza. |
| Elementos | Arriba a la derecha: uno a tres íconos. |
| Fondo de bioma | El bioma de origen: Valle, Cumbre, Marea, Fulgor, Velo o Torre. |
| Pedestal | Disco de luz donde se para el monstruo. |
| Aura | Detrás y alrededor; crece con la rareza. |
| Marco | Liso (Común), azul (Raro), violeta con esquinas (Épico), oro (Legendario), iridiscente (Único) y punteado imposible (Misterio). |

**ÁLBUM DEL NEXO:** Pantalla de colección con las 50 cartas (y los Sagrados) en cuadrícula; las que
faltan se muestran como silueta oscura con el número. Completar un bioma da un marco especial.

**BROTE Y TALLADO:** Cada especie tiene dos cartas. La del Brote usa el mismo marco con el aura
reducida, para que la rareza se reconozca desde la eclosión.

**EN ROBLOX:** La carta es una interfaz 2D (ViewportFrame con el modelo 3D sobre una imagen de fondo
del bioma). El marco y la gema son imágenes reutilizables por rareza.

---
## Página 15 · Aura por rareza, huevos, nombres v5 y los doce elementos

*(Empieza con el final de «Cartas coleccionables», transcrito en la p. 14.)*

### Fuente PDF · página 26 — Aura y complejidad por rareza

La complejidad visual sube con la rareza: los Raros brillan, los Épicos tienen diseño propio desde el
huevo, los Legendarios un aura dorada, los Únicos colores propios y el Misterio una apariencia
imposible.

| | COMÚN (Coatitán) | RARO (Grullacandil) | ÉPICO (Engrifo) | LEGENDARIO (Gemaboa) | ÚNICO (Aetherion) | MISTERIO (Nexum) |
|---|---|---|---|---|---|---|
| Materiales | 1 · copal mate | 2 · copal + pigmento brillante | 3 · añade metal o translúcido | 4 · oro, vidrio, obsidiana, luz | Shader propio | Geometría imposible |
| Colores | 2–3 | 3–4 | 4–5 | 5–6 | Paleta propia | Limitada y saturada |
| Efecto | Ninguno | Destellos en bordes y luz de contorno | Emisivo animado y partículas en órbita | Aura dorada, rayos y piezas flotantes | Halo iridiscente y entrada animada | Damero flotante, cajones desfasados |
| Roblox | 0 emisores | 1 emisor al atacar | 1 emisor permanente | 2 emisores + haz | 3 emisores + firma sonora | Efectos de cámara |

**EL AURA NO TAPA LA CARA:** Las partículas y halos viven detrás o alrededor de la silueta. Ojos y
rasgo firma siempre limpios. En combate, el aura baja al 60 % de intensidad para no saturar la
pantalla.

**PRESUPUESTO TÉCNICO:** Común 0 · Raro 1 · Épico 1–2 · Legendario 2–3 · Único 3 ParticleEmitters, con
tasa máxima de 20 partículas/s cada uno. Probar con 8 monstruos en pantalla en el teléfono base.

**AURA EN EL BROTE:** El Brote ya muestra su rareza, pero con una versión reducida del aura (80 % del
tamaño y la mitad de partículas). Así el jugador reconoce un Épico desde que nace.

### Fuente PDF · página 27 — Huevos por rareza

El huevo anuncia la rareza antes de eclosionar. Común y Raro usan el huevo de su elemento; desde Épico,
cada especie tiene su propio huevo.

| COMÚN | RARO | ÉPICO | LEGENDARIO | ÚNICO | MISTERIO |
|---|---|---|---|---|---|
| 5 min de incubación | 20 min de incubación | 2 h de incubación | 8 h de incubación | 24 h de incubación | 72 h de incubación |

**HUEVOS PROPIOS (ÉPICO EN ADELANTE):** Cempa Cenoti Pelón Chaquiro Guaca Brujo Tizón Tuerco Boreal
Hilacho Lumbrela Geoda Nébulo Bisi Petardo Mediluna Nácar Nex.

**HUEVOS DE LOS INICIALES:** En la introducción los tres huevos son idénticos: copal liso con una
espiral. Al acercar el cursor, cada uno late con un color (brasa, barro o greca) para que la elección
sea por intuición.

**HUEVOS DE LA VITRINA:** Los huevos comprados en la Vitrina muestran la especie en una etiqueta del
Gabinete y nacen con rasgos estándar (Veta base, Temple neutro, sin mutación): la compra es
determinista.

### Fuente PDF · páginas 28–29 — Nombres v5 (1/2 y 2/2)

Nombres menos infantiles: sin diminutivos (-ín, -ito), con sonidos fuertes, juegos de palabras y
raíces que se entienden en español y en inglés. Los Brotes conservan un toque juguetón; los Tallados
suenan a leyenda.

| # | BROTE V4 | TALLADO V4 | BROTE V5 | TALLADO V5 | RAREZA |
|---|---|---|---|---|---|
| 1 | Kuachi | Tlecuach | Kuachi | Ascuacho | COMÚN |
| 2 | Xolumi | Atlaxolotl | Xolumi | Xolossus | COMÚN |
| 3 | Teselín | Mitlaurum | Teselo | Mitlaxis | COMÚN |
| 4 | Comalín | Brasadillo | Comalú | Magmadillo | COMÚN |
| 5 | Rillip | Riveloz | Rillip | Mantaraz | COMÚN |
| 6 | Jarrín | Cantarón | Barrock | Cantagólem | COMÚN |
| 7 | Nubi | Nubarrón | Yek | Yetormenta | COMÚN |
| 8 | Zunzi | Zunzéfiro | Zunzi | Navajazul | COMÚN |
| 9 | Raicín | Raizagave | Agavo | Quiotazo | COMÚN |
| 10 | Vainito | Vainacuerno | Vainas | Hercuerno | COMÚN |
| 11 | Zizi | Chicharrayo | Zizi | Chicharrayo | COMÚN |
| 12 | Tinco | Coatiferro | Tinco | Coatitán | COMÚN |
| 13 | Rehilín | Rehiletrón | Cuerdo | Turbinón | COMÚN |
| 14 | Pulpín | Pulpiensa | Okto | Krakensa | COMÚN |
| 15 | Murcí | Velonoche | Murk | Lunatajo | COMÚN |
| 16 | Brumi | Brumánima | Bruma | Fatuoscuro | COMÚN |
| 17 | Velita | Velador | Pabilo | Candelux | COMÚN |
| 18 | Orbi | Lunasapo | Lunk | Batraluna | COMÚN |
| 19 | Tronito | Liebrayo | Brinco | Voltalope | RARO |
| 20 | Truenín | Tronalado | Chispón | Fulminave | RARO |
| 21 | Corvi | Corvidúo | Kroa | Corvidúo | RARO |
| 22 | Brillín | Albicorno | Lumbro | Faroibex | RARO |
| 23 | Alacrín | Magmacrán | Picoso | Magmacrán | RARO |
| 24 | Aleti | Alamar | Kunko | Alamar | RARO |
| 25 | Pecarín | Chinampero | Dientón | Castorre | RARO |
| 26 | Culebri | Lorapiente | Cotorro | Lorapiente | RARO |
| 27 | Cometín | Cometaura | Medu | Cometaura | RARO |
| 28 | Latín | Hojalatero | Remache | Mechalata | RARO |
| 29 | Faroli | Farolánima | Linterno | Farolánima | RARO |
| 30 | Changui | Pincelmono | Garabato | Monomural | RARO |
| 31 | Zanquito | Grullacandil | Zanco | Grullacandil | RARO |
| 32 | Tejín | Tejemapa | Ovillo | Aracnógrafa | RARO |
| 33 | Cempí | Cempasol | Cempa | Cempasol | ÉPICO |
| 34 | Cenoti | Pezcielo | Cenoti | Leviacielo | ÉPICO |
| 35 | Hojalín | Zopilatón | Pelón | Zopilatón | ÉPICO |
| 36 | Chaquiro | Fulgurila | Chaquiro | Fulgurila | ÉPICO |
| 37 | Arita | Aráureo | Guaca | Aráureo | ÉPICO |
| 38 | Brujilla | Brujalada | Brujo | Brujalada | ÉPICO |
| 39 | Tizín | Tizonsierpe | Tizón | Tizonsierpe | ÉPICO |
| 40 | Canoíta | Canoaviento | Tuerco | Engrifo | ÉPICO |
| 41 | Caribri | Auroribú | Boreal | Auroribú | ÉPICO |
| 42 | Titerín | Titeránima | Hilacho | Titeránima | ÉPICO |
| 43 | Lumbrela | Papalumen | Lumbrela | Papalumen el Vitral Vivo | LEGENDARIO |
| 44 | Gemín | Gemaboa | Geoda | Gemaboa la Guardiana de Vetas | LEGENDARIO |
| 45 | Trotín | Astrocorcel | Nébulo | Astrocorcel el Ocho Vientos | LEGENDARIO |
| 46 | Bisi | Gemitrueno | Bisi | Gemitrueno Serpiente de Dos Mareas | LEGENDARIO |
| 47 | Cohetín | Pirotoro | Petardo | Pirotoro el Castillo de Feria | LEGENDARIO |
| 48 | Mediluna | Eclipsor | Mediluna | Eclipsor el Gato de Dos Cielos | ÚNICO |
| 49 | Ballení | Aetherion | Nácar | Aetherion la Ballena Cartógrafa | ÚNICO |
| 50 | Nex | Nexum | Nex | Nexum el Gabinete que Camina | MISTERIO |

*(Filas 1–2 en la columna izquierda de la p. 15; filas 3–25 en la derecha; filas 26–50 en la
derecha bajo «Nombres v5 (2/2)».)*

| PRINCIPIO | EJEMPLOS |
|---|---|
| 1 · Juego de palabras | Ascuacho (ascua + tlacuache), Magmadillo, Krakensa, Coatitán, Castorre. |
| 2 · Sonido fuerte | K, X, Z, R y TR: Xolossus, Voltalope, Turbinón, Mechalata. |
| 3 · Curiosidad | Que el nombre haga preguntar «¿qué es?»: Garabato, Picoso, Petardo, Barrock. |

**ANTES DE FIJARLOS:** Revisar marcas (IMPI, USPTO) y colisiones dentro de Roblox. Legendarios, Únicos
y Misterio conservan sus nombres y epítetos de la v4.

### Fuente PDF · página 31 — Los doce elementos

Tres anillos de cuatro. Cada elemento vence a dos y pierde contra dos; al menos una de esas relaciones
cruza a otro anillo.

| ELEMENTO | ANILLO · ESPECIES | MATERIALES Y FORMAS | FUERTE | DÉBIL |
|---|---|---|---|---|
| Agua | PRIMORDIAL · 7 ESPECIES | Ríos, cántaros y espuma. Formas fluidas, aletas y branquias. | Fuego Metal | Flora Rayo |
| Fuego | PRIMORDIAL · 7 ESPECIES | Brasas, comales y hornos. Lóbulos de llama y grietas encendidas. | Flora Sombra | Agua Mente |
| Aire | PRIMORDIAL · 9 ESPECIES | Papalotes, plumas y remolinos. Alas, colas largas y espirales abiertas. | Tierra Flora | Metal Luz |
| Tierra | PRIMORDIAL · 6 ESPECIES | Barro, grecas y piedra. Volúmenes pesados y caparazones. | Rayo Metal | Aire Astral |
| Metal | MATERIA · 5 ESPECIES | Hojalata repujada, herrería y remaches. Placas y filos. | Aire Astral | Agua Tierra |
| Flora | MATERIA · 5 ESPECIES | Maguey, vainas y chinampas. Hojas, raíces y flores. | Agua Luz | Fuego Aire |
| Rayo | MATERIA · 5 ESPECIES | Fulgurita, cobre y chicharras. Zigzag y puntas metálicas. | Agua Mente | Tierra Artificio |
| Artificio | MATERIA · 7 ESPECIES | Juguetes de cuerda, rehiletes y engranes. Juntas y llaves. | Rayo Astral | Sombra Mente |
| Luz | ARCANO · 9 ESPECIES | Velas, porcelana y vitral. Halos y superficies pulidas. | Sombra Aire | Flora Astral |
| Sombra | ARCANO · 7 ESPECIES | Rebozo, niebla y luna. Siluetas suaves y bordes difusos. | Mente Artificio | Fuego Luz |
| Mente | ARCANO · 5 ESPECIES | Caracolas, tinta y espirales. Ojos grandes y patrones hipnóticos. | Artificio Fuego | Rayo Sombra |
| Astral | ARCANO · 7 ESPECIES | Estrellas, cráteres y auroras. Puntos de luz y órbitas. | Luz Tierra | Metal Artificio |

*(Las filas Agua–Aire están en la p. 15; el resto, en la p. 16.)*

---

## Página 16 · Rueda de ventajas, multiplicadores, naturaleza elemental y atributos

### Fuente PDF · página 32 — Rueda de ventajas (provisional)

Resuelta por optimización: 2 fortalezas y 2 debilidades exactas por elemento, ningún par se vence
mutuamente y se conserva el triángulo Agua → Fuego → Flora → Agua.

**ATACANTE (FILAS) CONTRA DEFENSOR (COLUMNAS)** — [matriz ilegible en la extracción; la tabla
«Elemento vence a…» de abajo contiene las mismas relaciones]. Texto tal como sale:

```
Agua
Metal Fuego
1,5 1,5 .75 .75
.75 1,5 1,5 .75
Aire Flora
1,5 .75 1,5 .75
.75 1,5 1,5 .75
.75 1,5 .75 1,5
Sombra Tierra
1,5 .75 .75 1,5
1,5 .75 .75 1,5
1,5 .75 .75 1,5
1,5 .75 1,5 .75
Luz Rayo .75 1,5 .75 1,5
1,5 .75 1,5 .75
Astral Mente 1,5 .75 .75 1,5
Artificio
```

Leyenda: ×1,5 fuerte · ×0,75 débil · ×1,0 neutro.

**CORRECCIÓN DE LUZ, SOMBRA Y ASTRAL:** En la v3, Luz y Sombra se vencían entre sí y Astral perdía
contra Sombra. Ahora: Luz vence a Sombra; Sombra vence a Mente y Artificio; Astral vence a Luz y
Tierra. Sombra y Astral son neutrales entre sí.

| ELEMENTO | VENCE A… Y POR QUÉ |
|---|---|
| Agua | Fuego apaga la brasa · Metal oxida el hierro |
| Fuego | Flora quema la hoja · Sombra la llama alumbra lo oscuro |
| Aire | Tierra erosiona la roca · Flora arranca y dispersa |
| Tierra | Rayo lo descarga a tierra · Metal la roca mella el filo |
| Metal | Aire la hoja corta el viento · Astral el hierro meteórico ancla lo cósmico |
| Flora | Agua la raíz bebe el río · Luz la hoja se alimenta de luz |
| Rayo | Agua el agua conduce · Mente la descarga aturde |
| Artificio | Rayo el pararrayos lo encauza · Astral el astrolabio cartografía el cielo |
| Luz | Sombra disipa la sombra · Aire espejismo que engaña al viento |
| Sombra | Mente la pesadilla nubla · Artificio el apagón detiene la máquina |
| Mente | Artificio el ingenio vence al mecanismo · Fuego la calma doma la furia |
| Astral | Luz el eclipse cubre al sol · Tierra el meteoro parte la montaña |

### Fuente PDF · página 33 — Comprobación de multiplicadores

Se simularon 20 000 duelos por caso entre dos monstruos con el modelo de daño de la Biblia (10 % de
fallo, ±15 % de variación, 10 % de crítico). La pregunta: ¿cuánto pesa el elemento frente a la rareza?

| MULTIPLICADOR | GANA EL QUE TIENE VENTAJA (MISMA RAREZA) | UN COMÚN CON VENTAJA VENCE A UN LEGENDARIO |
|---|---|---|
| ×1,0 / ×1,0 | 50,7 % | — |
| ×1,2 / ×0,85 | 88,9 % | 36,2 % |
| ×1,25 / ×0,85 | 90,5 % | 43,6 % |
| ×1,3 / ×0,8 | 93,4 % | 59,4 % |
| ×1,5 / ×0,75 (actual) | 97,8 % | 81,0 % |

| CASO DE REFERENCIA SIN VENTAJA | VICTORIA |
|---|---|
| Raro contra Común (+8 % de atributos) | 66,9 % |
| Legendario contra Común (+24 %) | 92,2 % |
| Raro con ventaja contra Legendario, ×1,25 / ×0,85 | 68,8 % |
| Raro con ventaja contra Legendario, ×1,5 / ×0,75 | 91,5 % |

**LO QUE MUESTRA LA SIMULACIÓN:** Con ×1,5 / ×0,75 el elemento decide casi todo: un Común con ventaja
vence a un Legendario 81 de cada 100 veces y coleccionar rarezas pierde sentido en la arena.

**RECOMENDACIÓN:** Probar ×1,25 / ×0,85 (topes ×1,6 / ×0,7 con dos elementos). La ventaja sigue siendo
clara (90 % en igualdad), pero un Legendario conserva su peso (56 % contra un Común con ventaja). Se
mantiene ×1,5 hasta tu confirmación.

**LÍMITES DEL MODELO:** Duelo de un monstruo contra otro, sin cambios ni estados. En 1v1 con tres
monstruos y en 2v2 la ventaja se diluye porque el rival puede cambiar. Validar en la beta con la tasa
de victoria por emparejamiento elemental.

### Fuente PDF · página 34 — Naturaleza elemental por rareza

Cuantos más elementos, más opciones de ataque, pero también más debilidades posibles. El tope evita
multiplicadores extremos.

| COMÚN | RARO | ÉPICO | LEGENDARIO | ÚNICO | MISTERIO |
|---|---|---|---|---|---|
| 1 ELEMENTO | 1 o 2 ELEMENTOS | 2 ELEMENTOS | 2 o 3 ELEMENTOS | 3 ELEMENTOS | Eco |

**MULTIPLICADORES**

| SITUACIÓN | VALOR POR ELEMENTO DEL DEFENSOR |
|---|---|
| Fuerte contra el elemento del defensor | ×1,5 |
| Débil ante el elemento del defensor | ×0,75 |
| Defensor con 2–3 elementos | Se multiplican; tope ×1,8 y suelo ×0,6 |
| Mismo elemento que el atacante (afinidad) | ×1,2 |
| Golpe Nexo | Ignora el tope bajo (mín. ×0,75) |

**EJEMPLOS**

| CASO | POR ELEMENTO | TOTAL |
|---|---|---|
| Kuachi (Fuego) contra Castorre (Flora/Tierra) | ×1,5 · ×1 | ×1,5 |
| Voltalope (Rayo) contra Lorapiente (Agua/Flora) | ×1,5 · ×1 | ×1,5 |
| Xolossus (Agua) contra Pirotoro (Fuego/Artificio/Luz) | ×1,5 · ×1 · ×1 | ×1,5 |
| Ascuacho (Fuego) contra Leviacielo (Agua/Astral) | ×0,75 · ×1 | ×0,75 |
| Navajazul (Aire) contra Castorre (Flora/Tierra) | ×1,5 · ×1,5 | ×1,8 (tope) |
| Krakensa (Mente) contra Corvidúo (Mente/Sombra) | ×1 · ×0,75 | ×0,75 |
| Fulminave (Rayo) contra Alamar (Agua/Aire) | ×1,5 · ×1 | ×1,5 |

**QUÉ APORTA CADA ELEMENTO:** El primer elemento define la paleta, el bioma y el Golpe Nexo genérico.
Cada elemento adicional suma sus 3 básicos y 1 especial al repertorio que se puede equipar. El Misterio
(Nexum) no tiene elemento: adopta uno neutral frente al rival en cada combate («Eco»).

**MÁS ELEMENTOS, MÁS DEBILIDADES:** Con 1 elemento hay 2 debilidades; con 2, hasta 4; con 3, hasta 6
(Eclipsor), casi todas leves (×1,125). Por eso los Únicos cuestan 6 en el equipo y cada ficha muestra
sus debilidades y resistencias netas.

### Fuente PDF · página 35 — Atributos y roles

Cinco atributos. Cada especie reparte un presupuesto fijo según su rareza y su rol, y recibe un ajuste
propio para que dos monstruos de la misma rareza nunca sean iguales.

| ATRIBUTO | QUÉ HACE |
|---|---|
| VID | Vida: puntos de golpe = VID × 10 a nivel 50. |
| ATQ | Ataque: fuerza de los ataques básicos y de contacto. |
| DEF | Defensa: reduce el daño recibido. |
| ESE | Esencia: fuerza de especiales y curaciones. |
| VEL | Velocidad: orden de acción en el turno. |

**MISMA RAREZA, DISTINTO JUEGO**

| | VID | ATQ | DEF | ESE | VEL |
|---|---|---|---|---|---|
| Ascuacho · Atacante | 19 | 29 | 14 | 18 | 20 |
| Coatitán · Atacante | 18 | 28 | 15 | 17 | 22 |

Dos Comunes con el mismo presupuesto (100): uno pega primero y fuerte; el otro aguanta y acierta
críticos.

**PRESUPUESTO POR RAREZA:** Común 100 · Raro 108 · Épico 116 · Legendario 124 · Único 128 · Misterio
120. Máximo +28 % entre Común y Único. Barras desde 80 para que se note la diferencia. *(Único y
Misterio están en la p. 17.)*

**PLANTILLAS DE ROL (% DEL PRESUPUESTO)**

| ROL | VID | ATQ | DEF | ESE | VEL | ESTILO |
|---|---|---|---|---|---|---|
| Atacante | 19 | 27 | 15 | 18 | 21 | Golpea fuerte y rápido; frágil si recibe primero. |
| Defensor | 25 | 16 | 28 | 16 | 15 | Aguanta y protege; gana por desgaste. |
| Soporte | 23 | 14 | 19 | 27 | 17 | Cura, protege y mejora al aliado. |
| Control | 19 | 15 | 18 | 26 | 22 | Estados, lentitud y negación de Savia. |
| Veloz | 17 | 22 | 14 | 18 | 29 | Actúa primero y remata. |
| Bruto | 24 | 25 | 21 | 12 | 18 | Cuerpo grande y golpe pesado, poca Esencia. |
| Adaptativo | 20 | 20 | 20 | 20 | 20 | Sin punto débil ni punto fuerte. |

**ESCALA POR NIVEL:** Atributo en combate = base × (0,4 + 0,012 × nivel). Nivel 1 = 41 %, nivel 25 =
70 %, nivel 50 = 100 %. El Brote usa el 70 % de su base y cuesta 1 punto menos en el equipo.

---

## Página 17 · Ataques por elemento y arenas

### Fuente PDF · páginas 36–38 — Ataques por elemento (1/3, 2/3 y 3/3)

Cada elemento tiene 3 básicos, 2 especiales y 1 Golpe Nexo. El jugador equipa 2 básicos, 1 especial,
la Firma de su especie y, desde nivel 20 en Tallado, el Golpe Nexo.

*(La fuente imprime dos tablas lado a lado y el PDF las intercala línea a línea; se reconstruyen por
elemento. Agua, Fuego, Aire y Tierra son la página 36; Metal, Flora, Rayo y Artificio, la 37; Luz,
Sombra, Mente y Astral, la 38. Luz–Astral están en la columna derecha de la p. 17.)*

**Agua**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Chorro | 40 | +1 | Golpe directo. |
| BÁSICO | Ola Corta | 35 | +1 | +10 % VEL propia 2 turnos. |
| BÁSICO | Burbuja Fría | 35 | +1 | −10 % ATQ del rival 2 turnos. |
| ESPECIAL | Marea Lenta | 65 | 2 | −20 % VEL del rival 2 turnos. |
| ESPECIAL | Manantial | — | 2 | Cura 30 % de VID (en 2v2 puede curar al aliado). |
| G. NEXO | Diluvio de Cántaros | 120 | 3 | Limpia los efectos negativos del equipo. |

**Fuego**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Chispazo | 40 | +1 | 10 % de quemadura (−5 % VID por turno, 3 turnos). |
| BÁSICO | Zarpa de Brasa | 45 | +1 | Golpe directo. |
| BÁSICO | Humo de Copal | 30 | +1 | El rival pierde 15 % de precisión 1 turno. |
| ESPECIAL | Comal Ardiente | 70 | 2 | 30 % de quemadura. |
| ESPECIAL | Muro de Ascuas | — | 2 | Escudo del 25 % de VID 2 turnos; quema a quien lo golpee. |
| G. NEXO | Fogata del Tallador | 120 | 3 | En 2v2 golpea a ambos rivales al 75 %. |

**Aire**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Ráfaga | 40 | +1 | Actúa primero si empata en VEL. |
| BÁSICO | Pluma Cortante | 40 | +1 | +10 % de crítico. |
| BÁSICO | Remolino | 35 | +1 | El rival pierde 1 de Savia (30 %). |
| ESPECIAL | Corriente Ascendente | — | 2 | +20 % VEL al equipo 2 turnos. |
| ESPECIAL | Torbellino | 70 | 2 | En 2v2 golpea a ambos rivales al 75 %. |
| G. NEXO | Viento de los Cuatro Rumbos | 115 | 3 | Prioridad máxima: siempre actúa primero. |

**Tierra**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Pisotón | 45 | +1 | Golpe directo. |
| BÁSICO | Lanza de Barro | 40 | +1 | 20 % de −10 % DEF del rival. |
| BÁSICO | Arena en los Ojos | 30 | +1 | −15 % precisión del rival 1 turno. |
| ESPECIAL | Muralla de Adobe | — | 2 | Bloquea el siguiente golpe y +20 % DEF 2 turnos. |
| ESPECIAL | Grieta | 75 | 2 | 15 % de aturdir 1 turno. |
| G. NEXO | Corazón de Montaña | 125 | 3 | +30 % DEF al equipo 2 turnos. |

**Metal**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Golpe de Yunque | 45 | +1 | Golpe directo. |
| BÁSICO | Remache Rebote | 40 | +1 | +10 % DEF propia 2 turnos. |
| BÁSICO | Limadura | 35 | +1 | −10 % DEF del rival 2 turnos. |
| ESPECIAL | Escudo Repujado | — | 2 | Escudo del 30 % de VID 2 turnos. |
| ESPECIAL | Cuchilla de Hojalata | 75 | 2 | +15 % de crítico. |
| G. NEXO | Fragua Viva | 120 | 3 | Gana un escudo igual al 20 % del daño causado. |

**Flora**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Látigo de Enredadera | 40 | +1 | Golpe directo. |
| BÁSICO | Semilla | 35 | +1 | Drena 10 % del daño causado. |
| BÁSICO | Polen | 30 | +1 | 20 % de adormecer 1 turno. |
| ESPECIAL | Raíz Profunda | — | 2 | Cura 8 % de VID por turno 3 turnos; no puede ser forzado a cambiar. |
| ESPECIAL | Espinas de Maguey | 70 | 2 | Refleja 15 % de daño recibido 2 turnos. |
| G. NEXO | Floración del Valle | 115 | 3 | Cura 25 % de VID al equipo. |

**Rayo**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Chispa | 40 | +1 | 20 % de parálisis (pierde 1 turno). |
| BÁSICO | Descarga | 45 | +1 | Golpe directo. |
| BÁSICO | Estática | 30 | +1 | 30 % de robar 1 de Savia. |
| ESPECIAL | Tormenta Encadenada | 70 | 2 | En 2v2 salta al segundo rival al 50 %. |
| ESPECIAL | Sobrecarga | — | 2 | +25 % ATQ y ESE 2 turnos; pierde 10 % de VID. |
| G. NEXO | Relámpago Fulgurita | 130 | 3 | Ignora escudos. |

**Artificio**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Engrane | 40 | +1 | Golpe directo. |
| BÁSICO | Resorte | 35 | +1 | Prioridad +1. |
| BÁSICO | Chispa de Taller | 35 | +1 | 20 %: el siguiente especial del rival falla. |
| ESPECIAL | Trampa de Cuerda | 50 | 2 | El rival no puede cambiar 2 turnos. |
| ESPECIAL | Ajuste Fino | — | 2 | El siguiente ataque propio hace +50 %. |
| G. NEXO | Gran Autómata | 120 | 3 | Copia la última mejora activa del rival. |

**Luz**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Destello | 40 | +1 | 15 % de cegar (−20 % precisión 1 turno). |
| BÁSICO | Rayo de Alba | 40 | +1 | Golpe directo. |
| BÁSICO | Halo | — | +1 | Cura 10 % de VID. |
| ESPECIAL | Vitral | — | 2 | Refleja 20 % de los especiales recibidos 2 turnos. |
| ESPECIAL | Lanza Solar | 75 | 2 | Golpe directo potente. |
| G. NEXO | Amanecer del Nexo | 115 | 3 | Cura 40 % al equipo y elimina estados. |

**Sombra**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Zarpa Nocturna | 45 | +1 | Golpe directo. |
| BÁSICO | Niebla | 30 | +1 | +15 % evasión 1 turno. |
| BÁSICO | Susurro | 35 | +1 | −10 % ATQ del rival 2 turnos. |
| ESPECIAL | Velo de Noche | — | 2 | Esquiva el siguiente ataque. |
| ESPECIAL | Pesadilla | 70 | 2 | +50 % si el rival está dormido o confundido. |
| G. NEXO | Eclipse Breve | 120 | 3 | Anula las mejoras del rival. |

**Mente**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Pulso Mental | 40 | +1 | Usa ESE. |
| BÁSICO | Distracción | 30 | +1 | −15 % ESE del rival 2 turnos. |
| BÁSICO | Eco de Pensamiento | 35 | +1 | +10 % ESE propia 2 turnos. |
| ESPECIAL | Calma | — | 2 | Quita estados propios y +20 % ESE 2 turnos. |
| ESPECIAL | Laberinto | 65 | 2 | 30 % de confundir 1 turno. |
| G. NEXO | Sueño Lúcido | 115 | 3 | El rival duerme 1 turno (no afecta a Misterio). |

**Astral**

| TIPO | ATAQUE | PODER | SAVIA | EFECTO |
|---|---|---|---|---|
| BÁSICO | Polvo de Estrella | 40 | +1 | Golpe directo. |
| BÁSICO | Órbita | 35 | +1 | +10 % evasión 2 turnos. |
| BÁSICO | Gravedad | 35 | +1 | −15 % VEL del rival 2 turnos. |
| ESPECIAL | Lluvia de Meteoros | 70 | 2 | Dos impactos de 35. |
| ESPECIAL | Constelación | — | 2 | +30 % ESE 2 turnos. |
| G. NEXO | Supernova Tallada | 125 | 3 | Después queda con −20 % DEF 1 turno. |

### Fuente PDF · página 39 — Arenas: 1v1, 2v2 y torneos 3v3

Se mantienen los dos formatos de la v4. El 3v3 queda solo para torneos individuales (un jugador contra
otro con tres monstruos en campo), no por equipos.

| ARENA 1V1 | ARENA 2V2 | TORNEO 3V3 INDIVIDUAL |
|---|---|---|
| Jugador A contra Jugador B (A1 · A2 · A3 / B1 · B2 · B3). Hasta 3 monstruos; 1 en campo. Coste máximo 12. Turno de 20 s; límite 5 min. | Equipo A + C contra Equipo B + D (A2 C2 / B2 D2). Dos jugadores por lado, hasta 2 monstruos cada uno. Coste máximo 8 por jugador. Turno de 20 s + reserva de 45 s por jugador; límite 6 min. | Un jugador contra otro, 3 monstruos en campo. Coste máximo 15; turno de 25 s; límite 10 min. Solo en eventos de torneo con inscripción. |

*(El esquema de jugadores empieza en la p. 17 y continúa en la p. 18.)*

| FORMATO | JUGADORES | MONSTRUOS | COSTE | TURNO | LÍMITE | DURACIÓN ESPERADA |
|---|---|---|---|---|---|---|
| Arena 1v1 | 1 jugador contra 1 | Hasta 3 monstruos por jugador; 1 en campo | Coste máx. 12 | 20 s | 5 min | 2,5–4 min |
| Arena 2v2 | 2 jugadores contra 2 | Hasta 2 monstruos por jugador; 1 en campo cada uno | Coste máx. 8 por jugador | 20 s + reserva de 45 s | 6 min | 4–6 min |
| Torneo 3v3 individual | 1 jugador contra 1, solo en torneos | 3 monstruos en campo a la vez | Coste máx. 15 | 25 s | 10 min | 6–8 min |

**RESERVA DE TIEMPO EN 2V2:** Cada jugador tiene 45 s extra para toda la partida. Si se agota el turno
y la reserva, se usa el último básico. Así nadie espera más de 20 s salvo en jugadas difíciles.

**DURACIÓN:** Meta: unos 4 min en 1v1 y hasta 6 min en 2v2. Referencia: el promedio de Pokémon
Champions es de 4 min (Famitsu, mayo de 2026).

---

## Página 18 · Turno y daño, divisiones, emparejamiento y equilibrio

### Fuente PDF · página 40 — Turno, Savia y daño

Turnos simultáneos: ambos eligen a la vez y la acción se resuelve por Velocidad. Así nadie espera al
otro.

| PASO | QUÉ PASA |
|---|---|
| 1 · Elegir | 20 s en 1v1 y en 2v2 (más una reserva de 45 s por jugador en 2v2). Si se acaba el tiempo, se usa el último básico. |
| 2 · Resolver | Por VEL; empates al azar. Los cambios de monstruo van primero. |
| 3 · Efectos | Quemadura, curaciones por turno y fin de mejoras. |
| 4 · Savia | Cada básico da +1 (máx. 3). Especial = 2; Golpe Nexo = 3, una vez por combate. |

**FÓRMULA DE DAÑO**

```
Daño = Poder × A / (A + D) × 2
       × Elemento (×1,5 / ×1 / ×0,75, tope 1,8–0,6)
       × Afinidad (×1,2 si comparte elemento)
       × Variación (0,95–1,05) × Crítico (×1,5; 5 %)
A = ATQ (básicos) o ESE (especiales y Golpe Nexo)
D = DEF (básicos) o (DEF + ESE) / 2 (especiales)
```

Con ATQ igual a DEF, un básico de poder 40 hace 40 de daño; un monstruo de VID 20 tiene 200 de vida: se
derrota en 3 a 5 acciones. Las ventajas de elemento lo bajan a 2 o 3.

**DURACIÓN ESTIMADA**

| FORMATO | ESTIMACIÓN | TOTAL |
|---|---|---|
| 1v1 · 3 monstruos | 9–14 turnos × 16 s | 2,4–3,7 min |
| 2v2 · 4 por lado | 10–14 turnos × 24 s | 4,0–5,6 min |
| 3v3 (torneo) | 15–19 turnos × 25 s | 6,3–7,9 min |

Modelo: decisión media de 10 s (1v1) o 14 s (2v2) + 6 a 8 s de animación. Es una estimación de diseño;
se mide en la beta.

**ANIMACIONES:** Ningún ataque dura más de 2,5 s en pantalla. El Golpe Nexo puede durar 4 s y se puede
saltar tras verlo una vez.

**POR QUÉ TURNOS SIMULTÁNEOS:** Con turnos alternos, el 2v2 tendría cuatro esperas por ronda. Con
elección simultánea la ronda dura lo mismo que el jugador más lento y el combate se mantiene entre 3 y 6
minutos.

### Fuente PDF · página 41 — Divisiones de la v5

Los nombres de materiales (Barro, Copal, Jade…) se cambian por las etapas de una talla: del primer
trazo a la obra que se vuelve leyenda. Son propios de NEXORA y cuentan una historia de progreso.

| DIVISIÓN | LEMA | MONEDAS POR VICTORIA |
|---|---|---|
| Esbozo | «Todo gran monstruo empezó como un trazo.» | 40 Monedas por victoria |
| Gubia | «Ya sabes dónde cortar.» | 60 Monedas por victoria |
| Relieve | «Tus monstruos empiezan a sobresalir.» | 80 Monedas por victoria |
| Filigrana | «Detalle, precisión y estilo.» | 110 Monedas por victoria |
| Obra Maestra | «Tu santuario ya es leyenda.» | 140 Monedas por victoria |
| Nexo Eterno | «Los mejores guardianes del árbol.» | 180 Monedas por victoria |

Barras de cofre por división (Madera · Plata · Oro · Épico · Diamante): [ilegible en la extracción;
solo salen rótulos sueltos: 92 % · 75 % 22 % · 55 % 35 % · 35 % 40 % 20 % · 20 % 40 % 28 % · 35 % 40 %
20 %; la tabla completa está en la fuente p. 105, transcrita en la p. 33].

| V4 | V5 | PARA SUBIR | RECOMPENSA AL ASCENDER (PRIMERA VEZ) |
|---|---|---|---|
| Barro | Esbozo | 300 PT | Marco de Esbozo |
| Copal | Gubia | 600 PT | Cofre de Plata + emote |
| Jade | Relieve | 1 000 PT | Cofre de Oro + título |
| Obsidiana | Filigrana | 1 500 PT | Cofre Épico + estela |
| Oro | Obra Maestra | 2 200 PT | Cofre Diamante + aura de arena |
| Nexo | Nexo Eterno | Clasificación | Cofre Nexo + corona de temporada |

**TOPE DIARIO:** 8 cofres de victoria al día (antes 12). Después, las victorias dan Monedas y Puntos de
Talla. Referencias: Brawl Stars da 6 recompensas diarias por victoria; Clash Royale, unas 3.

**ALTERNATIVAS DE NOMBRES:** Celestial: Alba · Cénit · Aurora · Eclipse · Constelación · Nexo. Mítica:
Brote · Vigía · Guardián · Custodio · Leyenda · Nexo. Ver preguntas.

### Fuente PDF · página 42 — Emparejamiento y divisiones

Seis divisiones con nombres de las etapas de una talla. Cuanto más alta la división, mejores cofres por
victoria.

**EMPAREJAMIENTO:** Poder de equipo = suma de (nivel × coste) de los monstruos elegidos. Se busca rival
en ±10 %, que se abre a ±20 % tras 20 s. En Clasificatoria, además, la división debe ser la misma o la
contigua. En 2v2 se empareja por el Poder medio de la pareja. Los jugadores nuevos (menos de 10
partidas) solo se cruzan entre sí.

**RECOMPENSA POR VICTORIA** — Monedas por victoria y probabilidad del cofre que se gana (barras Madera ·
Plata · Oro · Épico · Diamante; solo se transcriben los rótulos legibles):

| DIVISIÓN | MONEDAS | RÓTULOS LEGIBLES DE LA BARRA |
|---|---|---|
| ESBOZO | 40 Mon. | 92 % · 8 % |
| GUBIA | 60 Mon. | 75 % · 22 % |
| RELIEVE | 80 Mon. | 55 % · 35 % · 9 % |
| FILIGRANA | 110 Mon. | 35 % · 40 % · 20 % |
| OBRA MAESTRA | 140 Mon. | 20 % · 40 % · 28 % · 0 % |
| NEXO ETERNO | 180 Mon. | 35 % · 40 % · 20 % |

**PUNTOS DE TALLA (PT)**

| RESULTADO | PT |
|---|---|
| Victoria | +30 |
| Derrota | −20 (no baja de división en Esbozo y Gubia) |
| Empate por tiempo | +5 |
| Racha de 3 victorias | +10 extra |

| DIVISIÓN | PT PARA SUBIR |
|---|---|
| Esbozo → Gubia | 300 |
| Gubia → Relieve | 600 |
| Relieve → Filigrana | 1 000 |
| Filigrana → Obra Maestra | 1 500 |
| Obra Maestra → Nexo Eterno | 2 200 |
| Nexo Eterno | Clasificación por puntos |

**TOPE DIARIO:** 8 cofres de victoria al día. Después de ese tope, las victorias solo dan Monedas y PT.
La derrota da 25 % de las Monedas de la victoria.

**2V2:** Mismas recompensas que en 1v1 para cada jugador de la pareja ganadora, para que nadie prefiera
un formato por el botín.

### Fuente PDF · página 43 — Equilibrio y anti-dominio

Reglas para que un Único o un elemento no dominen a las rarezas bajas.

1. **Coste de equipo.** Un Único cuesta 6 de 12 en 1v1 (y 6 de 8 en 2v2): obliga a acompañarlo de
   monstruos menores.
2. **Uno por equipo.** Máximo 1 Único o Misterio por jugador y 2 Legendarios en 1v1 (1 en 2v2).
3. **Presupuesto acotado.** Diferencia máxima de atributos +28 % entre Común y Único; las Firmas de
   Comunes son tan útiles como las de Legendarios.
4. **Golpe Nexo igualado.** Todos los Golpes Nexo cuestan 3 de Savia y se usan una vez; los de especie
   solo cambian el efecto, no el poder (115–130).
5. **Arena Equilibrada.** Normaliza a nivel 50; el progreso se premia con cosméticos, no con ventaja.
6. **Vigilancia de uso.** Si un elemento supera el 15 % de los equipos o el 55 % de victorias durante 2
   semanas, se ajustan sus números (no la rueda).
7. **Rotación.** Cada temporada de 8 semanas, un ajuste menor de 3 a 5 especies con notas públicas.

*(Las reglas 5–7 y la tabla siguiente están en la p. 19.)*

**EJEMPLOS DE EQUIPO (1V1, MÁXIMO 12)**

| EQUIPO | COSTE | RESULTADO |
|---|---|---|
| Único + Raro + Raro | 6 + 3 + 3 = 12 | Válido |
| Legendario + Épico + Raro | 5 + 4 + 3 = 12 | Válido |
| Único + Legendario | 6 + 5 = 11 (+1 libre) | Válido con un Brote Común (1) |
| Legendario + Legendario + Épico | 5 + 5 + 4 = 14 | No válido |
| Tres Épicos | 4 + 4 + 4 = 12 | Válido |

---
## Página 19 · Nexum, los tres iniciales y sus fichas

*(Empieza con el final de «Equilibrio y anti-dominio», transcrito en la p. 18.)*

### Fuente PDF · página 44 — Nexum: alternativa estratégica

El Misterio no debe ser «el más fuerte», sino el más raro de usar bien. Sin elemento propio,
contrarresta parcialmente a otros monstruos y castiga a quien abusa de los especiales.

**CÓMO JUEGA**

| PIEZA | EFECTO |
|---|---|
| Eco | Al entrar adopta un elemento neutral frente al rival: nunca recibe ni hace ×1,5 o ×0,75. |
| Cajón que Guarda | Especial · 2 Savia: bloquea el siguiente especial que reciba. |
| Inventario Imposible | Golpe Nexo · 3 Savia: devuelve el último especial bloqueado al 60 %. |
| Atributos | Adaptativo: 24 en todo (presupuesto 120). |

| 120 | 5 |
|---|---|
| PRESUPUESTO (ANTES 128) · Legendario 124 · Único 128 | COSTE EN EQUIPO (ANTES 6) · cabe con un Legendario |

VID 24 · ATQ 24 · DEF 24 · ESE 24 · VEL 24.

**CONTRA QUIÉN BRILLA:** Contra equipos de Control y Soporte que dependen de especiales. Contra
atacantes de básicos es solo correcto: ahí un Legendario le gana.

**LÍMITES:** Uno por cuenta, uno por equipo y nunca junto a un Único en 2v2. El Eco se recalcula al
cambiar de rival.

**POR CONFIRMAR:** Presupuesto 120 y coste 5 son propuesta de la v5. Si prefieres que conserve 128 y
coste 6, solo cambia su papel a «pieza de colección». Ver preguntas.

### Fuente PDF · página 48 — Los tres iniciales

Tres huevos idénticos. Kuachi, el tlacuache que roba el fuego; Xolumi, el ajolote que no desaparece;
Teselo, la tortuga que sostiene el cielo.

| KUACHI → ASCUACHO | XOLUMI → XOLOSSUS | TESELO → MITLAXIS |
|---|---|---|
| Fuego · Atacante. El tlacuache que robó el fuego (relato mazateco) + horno de comal. | Agua · Soporte. Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la deidad) + barro negro de Oaxaca. | Tierra · Defensor. Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla. |

| | KUACHI → ASCUACHO (FUEGO) | XOLUMI → XOLOSSUS (AGUA) | TESELO → MITLAXIS (TIERRA) |
|---|---|---|---|
| Rol | Atacante | Soporte | Defensor |
| Vence a | Flora y Sombra | Fuego y Metal | Rayo y Metal |
| Pierde contra | Agua y Mente | Flora y Rayo | Aire y Astral |
| Primer Opaco | Opaco de Flora | Opaco de Fuego | Opaco de Rayo |

### Fuente PDF · página 49 — Kuachi → Ascuacho

El tlacuache que, según el relato, robó el fuego para los demás y lo cargó en la cola. Inicial de Fuego.

- **Fuego · COMÚN** · Atacante · Cuadrúpedo · marsupial · Valle Copal
- **Brote.** Pequeño, de hocico largo y orejas redondas; cola pelada y enroscada con la punta
  chamuscada; la bolsa del vientre brilla como un horno tibio.
- **Tallado.** Tlacuache de acecho, largo y bajo; la bolsa es un horno con rejilla al rojo y la cola un
  látigo de ceniza con anillos encendidos. Mirada de ladrón astuto.
- **Atributos (Brote → Tallado, nivel 50):** VID 13→19 · ATQ 20→29 · DEF 10→14 · ESE 13→18 · VEL 14→20
- **TALENTO · BOLSA DE BRASAS.** Al entrar en combate guarda 1 de Savia extra (máx. 1 por combate).
- **FIRMA · LÁTIGO DE CENIZA.** Especial · 65 · 2 Savia. 40 % de quemadura; si el rival ya arde, +20 %
  de daño.
- **FOGATA DEL TALLADOR.** Golpe Nexo de Fuego · 120 · 3 Savia. En 2v2 golpea a ambos rivales al 75 %.
- **MEZCLA MÍTICA:** El tlacuache que robó el fuego (relato mazateco) + horno de comal.
- **CLAVES 2D:** Silueta baja y alargada · bolsa-horno brillante · gris ceniza con brasa naranja.
- **PROCEDENCIA:** Tlacuache · horno de barro de comal · relato mazateco del robo del fuego · México.

**REPERTORIO (ELEMENTO FUEGO)**

| TIPO | ATAQUE | PODER | EFECTO |
|---|---|---|---|
| Básico | Chispazo | 40 | 10 % de quemadura (−5 % VID por turno, 3 turnos). |
| Básico | Zarpa de Brasa | 45 | Golpe directo. |
| Básico | Humo de Copal | 30 | El rival pierde 15 % de precisión 1 turno. |
| Especial | Comal Ardiente | 70 | 30 % de quemadura. |
| Especial | Muro de Ascuas | — | Escudo del 25 % de VID 2 turnos; quema a quien lo golpee. |
| Golpe Nexo | Fogata del Tallador | 120 | En 2v2 golpea a ambos rivales al 75 %. |

### Fuente PDF · página 50 — Xolumi → Xolossus

Ajolote de barro negro bruñido que se regenera. Su tema es transformarse para no desaparecer. Inicial
de Agua.

- **Agua · COMÚN** · Soporte · Anfibio · Valle Copal
- **Brote.** Cabeza ancha y sonrisa tranquila; tres pares de branquias plumosas turquesa; piel negra
  pulida como cerámica de San Bartolo Coyotepec.
- **Tallado.** Ajolote colosal de seis patas, erguido como un dragón de río; branquias de humo de copal,
  cicatrices doradas y boca con colmillos pequeños.
- **Atributos (Brote → Tallado, nivel 50):** VID 17→24 · ATQ 10→14 · DEF 13→19 · ESE 19→27 · VEL 11→16
- **TALENTO · REGENERACIÓN.** Recupera 6 % de VID al final de cada turno en el que no recibió daño.
- **FIRMA · CICATRIZ DORADA.** Especial · 0 · 2 Savia. Cura 25 % y gana +15 % DEF 2 turnos.
- **DILUVIO DE CÁNTAROS.** Golpe Nexo de Agua · 120 · 3 Savia. Limpia los efectos negativos del equipo.
- **MEZCLA MÍTICA:** Ajolote y el mito del que se transforma para no desaparecer (solo el tema, sin la
  deidad) + barro negro de Oaxaca.
- **CLAVES 2D:** Seis patas y cabeza ancha · branquias de humo · negro bruñido con oro.
- **PROCEDENCIA:** Ajolote · barro negro de Oaxaca · reparación dorada de cerámica · México.

**REPERTORIO (ELEMENTO AGUA)**

| TIPO | ATAQUE | PODER | EFECTO |
|---|---|---|---|
| Básico | Chorro | 40 | Golpe directo. |
| Básico | Ola Corta | 35 | +10 % VEL propia 2 turnos. |
| Básico | Burbuja Fría | 35 | −10 % ATQ del rival 2 turnos. |
| Especial | Marea Lenta | 65 | −20 % VEL del rival 2 turnos. |
| Especial | Manantial | — | Cura 30 % de VID (en 2v2 puede curar al aliado). |
| Golpe Nexo | Diluvio de Cántaros | 120 | Limpia los efectos negativos del equipo. |

### Fuente PDF · página 51 — Teselo → Mitlaxis

Tortuga terrestre con caparazón de grecas, como los mosaicos de piedra de Mitla. Inicial de Tierra.

- **Tierra · COMÚN** · Defensor · Reptil · tortuga terrestre · Valle Copal
- **Brote.** Caparazón alto de teselas pulidas, patas columnares y cara curiosa; sin vegetación ni
  picos.
- **Tallado.** Tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que giran;
  sobre el lomo flota un disco de cielo nocturno.
- **Atributos (Brote → Tallado, nivel 50):** VID 18→25 · ATQ 12→17 · DEF 20→28 · ESE 10→15 · VEL 10→15
- **TALENTO · CAPARAZÓN DE GRECAS.** Recibe −20 % de daño de los ataques básicos.
- **FIRMA · ASTROLABIO DE PIEDRA.** Especial · 60 · 2 Savia. +25 % DEF propia y −10 % VEL del rival 2
  turnos.
- **CORAZÓN DE MONTAÑA.** Golpe Nexo de Tierra · 125 · 3 Savia. +30 % DEF al equipo 2 turnos.
- **MEZCLA MÍTICA:** Tortuga que sostiene el cielo (eco chino de Ao) + mosaico de grecas de Mitla.
- **CLAVES 2D:** Domo escalonado · anillos dorados · piedra ocre y jade.
- **PROCEDENCIA:** Tortuga del desierto · mosaico de grecas de Mitla · tortuga que sostiene el cielo
  (eco chino de Ao) · México + Eco chino.

**REPERTORIO (ELEMENTO TIERRA)** *(esta tabla está en la p. 20)*

| TIPO | ATAQUE | PODER | EFECTO |
|---|---|---|---|
| Básico | Pisotón | 45 | Golpe directo. |
| Básico | Lanza de Barro | 40 | 20 % de −10 % DEF del rival. |
| Básico | Arena en los Ojos | 30 | −15 % precisión del rival 1 turno. |
| Especial | Muralla de Adobe | — | Bloquea el siguiente golpe y +20 % DEF 2 turnos. |
| Especial | Grieta | 75 | 15 % de aturdir 1 turno. |
| Golpe Nexo | Corazón de Montaña | 125 | +30 % DEF al equipo 2 turnos. |

---

## Página 20 · Tabla maestra y primeras fichas de especie

### Fuente PDF · páginas 52–53 — Tabla maestra (1/2 y 2/2)

Atributos del Tallado a nivel 50. El Brote tiene el 70 % y cuesta 1 punto menos.

| # | BROTE → TALLADO | RAREZA | ELEMENTOS | ROL | FAMILIA | BIOMA | VID | ATQ | DEF | ESE | VEL | C. |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Kuachi → Ascuacho | COMÚN | Fuego | Atacante | Cuadrúpedo | Valle | 19 | 29 | 14 | 18 | 20 | 2 |
| 2 | Xolumi → Xolossus | COMÚN | Agua | Soporte | Anfibio | Valle | 24 | 14 | 19 | 27 | 16 | 2 |
| 3 | Teselo → Mitlaxis | COMÚN | Tierra | Defensor | Reptil | Valle | 25 | 17 | 28 | 15 | 15 | 2 |
| 4 | Comalú → Magmadillo | COMÚN | Fuego | Defensor | Cuadrúpedo | Cumbre | 26 | 16 | 29 | 15 | 14 | 2 |
| 5 | Rillip → Mantaraz | COMÚN | Agua | Veloz | Acuático | Marea | 16 | 23 | 14 | 18 | 29 | 2 |
| 6 | Barrock → Cantagólem | COMÚN | Tierra | Soporte | Objeto animado | Valle | 24 | 14 | 20 | 27 | 15 | 2 |
| 7 | Yek → Yetormenta | COMÚN | Aire | Soporte | Bípedo | Velo | 23 | 13 | 19 | 28 | 17 | 2 |
| 8 | Zunzi → Navajazul | COMÚN | Aire | Veloz | Ave | Valle | 16 | 22 | 14 | 18 | 30 | 2 |
| 9 | Agavo → Quiotazo | COMÚN | Flora | Defensor | Planta | Cumbre | 26 | 16 | 29 | 15 | 14 | 2 |
| 10 | Vainas → Hercuerno | COMÚN | Flora | Control | Insecto | Valle | 19 | 15 | 19 | 26 | 21 | 2 |
| 11 | Zizi → Chicharrayo | COMÚN | Rayo | Veloz | Insecto | Meseta | 16 | 23 | 14 | 18 | 29 | 2 |
| 12 | Tinco → Coatitán | COMÚN | Metal | Atacante | Cuadrúpedo | Cumbre | 18 | 28 | 15 | 17 | 22 | 2 |
| 13 | Cuerdo → Turbinón | COMÚN | Artificio | Control | Constructo | Meseta | 19 | 15 | 18 | 27 | 21 | 2 |
| 14 | Okto → Krakensa | COMÚN | Mente | Control | Acuático | Marea | 19 | 14 | 18 | 27 | 22 | 2 |
| 15 | Murk → Lunatajo | COMÚN | Sombra | Veloz | Volador | Velo | 16 | 23 | 14 | 17 | 30 | 2 |
| 16 | Bruma → Fatuoscuro | COMÚN | Sombra | Soporte | Fantasmal | Marea | 24 | 13 | 19 | 28 | 16 | 2 |
| 17 | Pabilo → Candelux | COMÚN | Luz | Soporte | Ave | Valle | 24 | 13 | 19 | 28 | 16 | 2 |
| 18 | Lunk → Batraluna | COMÚN | Astral | Defensor | Anfibio | Velo | 26 | 16 | 29 | 15 | 14 | 2 |
| 19 | Brinco → Voltalope | RARO | Aire Rayo | Veloz | Cuadrúpedo | Meseta | 18 | 26 | 14 | 19 | 31 | 3 |
| 20 | Chispón → Fulminave | RARO | Rayo Metal | Atacante | Ave | Meseta | 21 | 30 | 16 | 18 | 23 | 3 |
| 21 | Kroa → Corvidúo | RARO | Mente Sombra | Control | Ave | Velo | 21 | 16 | 19 | 29 | 23 | 3 |
| 22 | Lumbro → Faroibex | RARO | Luz | Soporte | Cuadrúpedo | Valle | 26 | 14 | 21 | 30 | 17 | 3 |
| 23 | Picoso → Magmacrán | RARO | Fuego Tierra | Atacante | Arácnido | Cumbre | 21 | 30 | 17 | 18 | 22 | 3 |
| 24 | Kunko → Alamar | RARO | Agua Aire | Veloz | Acuático → Ave | Marea | 18 | 25 | 15 | 19 | 31 | 3 |
| 25 | Dientón → Castorre | RARO | Flora Tierra | Defensor | Cuadrúpedo | Valle | 28 | 18 | 31 | 16 | 15 | 3 |
| 26 | Cotorro → Lorapiente | RARO | Agua Flora | Control | Serpentino | Marea | 21 | 16 | 19 | 29 | 23 | 3 |
| 27 | Medu → Cometaura | RARO | Astral | Soporte | Astral | Marea | 26 | 14 | 21 | 30 | 17 | 3 |
| 28 | Remache → Mechalata | RARO | Artificio Metal | Defensor | Constructo | Meseta | 28 | 18 | 31 | 16 | 15 | 3 |
| 29 | Linterno → Farolánima | RARO | Luz Sombra | Soporte | Fantasmal | Velo | 26 | 14 | 21 | 30 | 17 | 3 |
| 30 | Garabato → Monomural | RARO | Artificio | Control | Primate | Valle | 21 | 16 | 18 | 29 | 24 | 3 |
| 31 | Zanco → Grullacandil | RARO | Fuego | Atacante | Ave | Cumbre | 20 | 30 | 16 | 20 | 22 | 3 |
| 32 | Ovillo → Aracnógrafa | RARO | Mente Artificio | Control | Arácnido | Velo | 21 | 15 | 19 | 29 | 24 | 3 |
| 33 | Cempa → Cempasol | ÉPICO | Fuego Luz | Atacante | Cuadrúpedo | Valle | 22 | 32 | 16 | 22 | 24 | 4 |
| 34 | Cenoti → Leviacielo | ÉPICO | Agua Astral | Control | Acuático | Marea | 22 | 16 | 21 | 31 | 26 | 4 |
| 35 | Pelón → Zopilatón | ÉPICO | Aire Metal | Defensor | Ave | Cumbre | 30 | 19 | 33 | 18 | 16 | 4 |
| 36 | Chaquiro → Fulgurila | ÉPICO | Tierra Rayo | Bruto | Cuadrúpedo | Meseta | 28 | 30 | 24 | 14 | 20 | 4 |
| 37 | Guaca → Aráureo | ÉPICO | Luz Aire | Atacante | Ave | Valle | 22 | 32 | 16 | 22 | 24 | 4 |
| 38 | Brujo → Brujalada | ÉPICO | Sombra Mente | Control | Insecto | Velo | 22 | 16 | 21 | 31 | 26 | 4 |
| 39 | Tizón → Tizonsierpe | ÉPICO | Fuego Flora | Soporte | Serpentino | Valle | 28 | 15 | 22 | 32 | 19 | 4 |
| 40 | Tuerco → Engrifo | ÉPICO | Aire Artificio | Veloz | Quimera | Meseta | 19 | 27 | 16 | 20 | 34 | 4 |
| 41 | Boreal → Auroribú | ÉPICO | Luz Astral | Soporte | Cuadrúpedo | Velo | 28 | 15 | 22 | 32 | 19 | 4 |
| 42 | Hilacho → Titeránima | ÉPICO | Sombra Artificio | Control | Fantasmal | Velo | 22 | 17 | 20 | 31 | 26 | 4 |
| 43 | Lumbrela → Papalumen | LEGENDARIO | Aire Luz | Soporte | Insecto | Valle | 29 | 16 | 24 | 34 | 21 | 5 |
| 44 | Geoda → Gemaboa | LEGENDARIO | Tierra Metal | Defensor | Serpentino | Cumbre | 32 | 19 | 36 | 19 | 18 | 5 |
| 45 | Nébulo → Astrocorcel | LEGENDARIO | Aire Astral | Veloz | Cuadrúpedo | Velo | 20 | 28 | 17 | 22 | 37 | 5 |
| 46 | Bisi → Gemitrueno | LEGENDARIO | Agua Rayo | Atacante | Serpentino | Marea | 24 | 34 | 18 | 22 | 26 | 5 |
| 47 | Petardo → Pirotoro | LEGENDARIO | Fuego Artificio Luz | Atacante | Cuadrúpedo | Cumbre | 24 | 34 | 19 | 21 | 26 | 5 |
| 48 | Mediluna → Eclipsor | ÚNICO | Luz Sombra Astral | Control | Cuadrúpedo | Velo | 25 | 19 | 23 | 34 | 27 | 6 |
| 49 | Nácar → Aetherion | ÚNICO | Agua Astral Mente | Soporte | Acuático | Velo | 30 | 17 | 25 | 35 | 21 | 6 |
| 50 | Nex → Nexum | MISTERIO | Eco | Adaptativo | Objeto animado | Torre | 24 | 24 | 24 | 24 | 24 | 5 |

*(Las filas 1–31 están en la p. 20 izquierda; la 32–50, en la derecha. La fuente divide la tabla entre
sus páginas 52 y 53 a partir de la fila 26. C. = coste en equipo del Tallado.)*

### Fuente PDF · página 54 — Fichas de especie

Cada ficha conserva los datos funcionales de la v4 (atributos, Talento, Firma, Golpe Nexo, linaje) con
el nuevo diseño, la mezcla mítica y las claves para el trabajo en 2D.

*(Formato de cada ficha: los atributos son Brote → Tallado; el tercer renglón de habilidades es el Golpe
Nexo. Los rótulos «Brote» y «Tallado» que el PDF intercala entre los atributos son pies de imagen y se
omiten.)*

#### 04 Comalú → Magmadillo · COMÚN · Fuego

- Defensor · Cuadrúpedo · acorazado · Cumbre Brasa
- **Mezcla mítica:** Salamandra de fuego del folclore europeo + armadillo + comal.
- **Atributos:** VID 18→26 · ATQ 11→16 · DEF 20→29 · ESE 10→15 · VEL 10→14
- **Talento · Comal Tibio.** Los rivales que lo golpean con contacto tienen 15 % de quemarse.
- **Firma · Rodada de Brasa.** Especial · 70 · 2 Savia. Después gana +10 % DEF 2 turnos.
- **Fogata del Tallador.** Golpe Nexo de Fuego · 120 · 3 Savia. En 2v2 golpea a ambos rivales al 75 %.
- **Débil ante:** Agua Mente · **Resiste:** Flora Sombra
- **Concepto:** Armadillo cuyo caparazón es un comal de barro siempre tibio.
- **Brote:** Bola de bandas de barro con orejitas; se enrolla al asustarse.
- **Tallado:** Armadillo-tanque de placas de comal con costuras de magma y un cuerno de basalto; al rodar
  deja un surco ardiente.
- **Claves 2D:** Bola acorazada · costuras de lava · barro rojo y negro
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** Kuachi + Teselo (10 %)
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 05 Rillip → Mantaraz · COMÚN · Agua *(continúa en la p. 21)*

- Veloz · Acuático · raya · Marea Coralina
- **Mezcla mítica:** Mantarraya + listón de feria + estela de cometa marino.
- **Atributos:** VID 11→16 · ATQ 16→23 · DEF 10→14 · ESE 13→18 · VEL 20→29
- **Talento · Corriente a Favor.** +10 % VEL si actúa primero en el turno.
- **Firma · Listón de Agua.** Especial · 65 · 2 Savia. Prioridad +1.
- **Diluvio de Cántaros.** Golpe Nexo de Agua · 120 · 3 Savia. Limpia los efectos negativos del equipo.
- **Débil ante:** Flora Rayo · **Resiste:** Fuego Metal
- **Concepto:** Raya de río que vuela bajo el agua como un listón.
- **Brote:** Disco liso con cola corta; salta fuera del agua para jugar.
- **Tallado:** Manta de alas enormes con borde de cuchilla y cola-látigo con aguijón luminoso; corta la
  corriente como un planeador.
- **Claves 2D:** Rombo de alas · cola-látigo · turquesa y blanco espuma
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

---

## Página 21 · Fichas 06–11

### Fuente PDF · página 55

#### 06 Barrock → Cantagólem · COMÚN · Tierra

- Soporte · Objeto animado · vasija · Valle Copal
- **Mezcla mítica:** Gólem de barro del folclore europeo + cántaro de mercado.
- **Atributos:** VID 17→24 · ATQ 10→14 · DEF 14→20 · ESE 19→27 · VEL 10→15
- **Talento · Barro Fresco.** Sus curaciones curan 15 % más.
- **Firma · Vertido del Cántaro.** Especial · 0 · 2 Savia. Cura 20 % al aliado o a sí mismo y quita 1
  estado.
- **Corazón de Montaña.** Golpe Nexo de Tierra · 125 · 3 Savia. +30 % DEF al equipo 2 turnos.
- **Débil ante:** Aire Astral · **Resiste:** Metal Rayo
- **Concepto:** Una vasija de barro que el Tallador olvidó junto al río y que despertó llena de agua de
  lluvia.
- **Brote:** Jarrito panzón con asa-oreja, tapita de sombrero y patas de piedra.
- **Tallado:** Cántaro-gólem de brazos de barro, puños de piedra y grietas reparadas en oro; vierte agua
  curativa por el pico como un guerrero-fuente.
- **Claves 2D:** Vasija con brazos · grietas de oro · barro con grecas blancas
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** Teselo + Xolumi (10 %)
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 07 Yek → Yetormenta · COMÚN · Aire

- Soporte · Bípedo · yeti · Velo Astral
- **Mezcla mítica:** Yeti de las montañas (folclore himalayo) + nube de tormenta + cuernos de borrego
  cimarrón.
- **Atributos:** VID 16→23 · ATQ 9→13 · DEF 13→19 · ESE 20→28 · VEL 12→17
- **Talento · Sombra Fresca.** El aliado en 2v2 recibe −10 % de daño de Fuego.
- **Firma · Llovizna.** Especial · 40 · 2 Savia. Cura 15 % al equipo.
- **Viento de los Cuatro Rumbos.** Golpe Nexo de Aire · 115 · 3 Savia. Prioridad máxima: siempre actúa
  primero.
- **Débil ante:** Metal Luz · **Resiste:** Tierra Flora
- **Concepto:** Una cría de yeti hecha de nube que baja de las cumbres con la primera tormenta.
- **Brote:** Bola de pelo blanco con cuernitos y patas cortas; a veces flota como una nube.
- **Tallado:** Yeti bípedo de pelaje de nube de tormenta, cuernos en espiral de viento y brazos
  larguísimos; ruge ventiscas.
- **Claves 2D:** Bípedo peludo y alto · cuernos espiral · blanco nube y azul tormenta
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

### Fuente PDF · página 56

#### 08 Zunzi → Navajazul · COMÚN · Aire

- Veloz · Ave · colibrí · Valle Copal
- **Mezcla mítica:** Colibríes guerreros mexicas (solo el concepto, sin la deidad) + navaja de
  obsidiana.
- **Atributos:** VID 11→16 · ATQ 15→22 · DEF 10→14 · ESE 13→18 · VEL 21→30
- **Talento · Vuelo Estático.** +10 % evasión mientras no cambie de monstruo.
- **Firma · Zumbido de Trompo.** Especial · 60 · 2 Savia. Golpea dos veces si actúa primero.
- **Viento de los Cuatro Rumbos.** Golpe Nexo de Aire · 115 · 3 Savia. Prioridad máxima: siempre actúa
  primero.
- **Débil ante:** Metal Luz · **Resiste:** Tierra Flora
- **Concepto:** Colibrí que se mantiene inmóvil en el aire y zumba como un trompo.
- **Brote:** Bolita de plumas con pico corto y alas en abanico.
- **Tallado:** Colibrí de plumas de obsidiana con pico-navaja y cola en tijera; zumba tan rápido que
  deja estelas cortantes.
- **Claves 2D:** Pico-navaja · alas en abanico · azul cobalto iridiscente
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 09 Agavo → Quiotazo · COMÚN · Flora

- Defensor · Planta · agave · Cumbre Brasa
- **Mezcla mítica:** Maguey y quiote + guardián de los campos.
- **Atributos:** VID 18→26 · ATQ 11→16 · DEF 20→29 · ESE 10→15 · VEL 10→14
- **Talento · Penca Gruesa.** +15 % DEF contra Agua y Rayo.
- **Firma · Quiote.** Especial · 70 · 2 Savia. Si el rival lo golpeó el turno anterior, +25 %.
- **Floración del Valle.** Golpe Nexo de Flora · 115 · 3 Savia. Cura 25 % de VID al equipo.
- **Débil ante:** Fuego Aire · **Resiste:** Agua Luz
- **Concepto:** Un maguey pequeño que aprendió a caminar sobre sus raíces.
- **Brote:** Roseta de hojas carnosas con cara en el centro y raíces-pies.
- **Tallado:** Agave colosal de pencas con espinas de jade y un quiote-lanza que se alza como bandera de
  batalla.
- **Claves 2D:** Roseta de pencas · quiote-lanza · verde agave con espinas jade
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

### Fuente PDF · página 57

#### 10 Vainas → Hercuerno · COMÚN · Flora

- Control · Insecto · escarabajo · Valle Copal
- **Mezcla mítica:** Escarabajo hércules + vaina de huaje + sonaja.
- **Atributos:** VID 13→19 · ATQ 10→15 · DEF 13→19 · ESE 18→26 · VEL 15→21
- **Talento · Siembra.** Cada vez que usa un especial deja una semilla: el siguiente aliado que entra
  cura 8 %.
- **Firma · Sonaja de Vainas.** Especial · 50 · 2 Savia. 35 % de adormecer.
- **Floración del Valle.** Golpe Nexo de Flora · 115 · 3 Savia. Cura 25 % de VID al equipo.
- **Débil ante:** Fuego Aire · **Resiste:** Agua Luz
- **Concepto:** Escarabajo que vive dentro de una vaina de semillas y siembra por donde pasa.
- **Brote:** Escarabajo redondo con élitros de vaina y antenas de brote.
- **Tallado:** Escarabajo gigante con un cuerno doble de semilla, élitros-vaina que se abren como
  escudos y sonido de sonaja al cargar.
- **Claves 2D:** Cuerno frontal enorme · élitros de vaina · verde y ámbar
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 11 Zizi → Chicharrayo · COMÚN · Rayo *(continúa en la p. 22)*

- Veloz · Insecto · cigarra · Meseta Fulgor
- **Mezcla mítica:** Cigarra de verano + tambor de feria + bobina de cobre.
- **Atributos:** VID 11→16 · ATQ 16→23 · DEF 10→14 · ESE 13→18 · VEL 20→29
- **Talento · Canto Estático.** Sus ataques básicos tienen +10 % de parálisis.
- **Firma · Tamborazo.** Especial · 70 · 2 Savia. 25 % de robar 1 de Savia.
- **Relámpago Fulgurita.** Golpe Nexo de Rayo · 130 · 3 Savia. Ignora escudos.
- **Débil ante:** Tierra Artificio · **Resiste:** Agua Mente
- **Concepto:** Cigarra cuyo canto de verano acumula electricidad estática.
- **Brote:** Cuerpo verde-amarillo con alas transparentes cortas y ojos enormes.
- **Tallado:** Cigarra-tambor con alas de vidrio y nervaduras de cobre; su abdomen retumba en descargas.
- **Claves 2D:** Alas de vidrio · abdomen-tambor · amarillo y cobre
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

---

## Página 22 · Fichas 12–18

### Fuente PDF · página 58

#### 12 Tinco → Coatitán · COMÚN · Metal

- Atacante · Cuadrúpedo · coatí · Cumbre Brasa
- **Mezcla mítica:** Coatí + armadura de hojalata repujada.
- **Atributos:** VID 13→18 · ATQ 20→28 · DEF 10→15 · ESE 12→17 · VEL 15→22
- **Talento · Curioso.** +15 % de crítico contra rivales que acaban de entrar al campo.
- **Firma · Garra Repujada.** Especial · 70 · 2 Savia. −15 % DEF del rival 2 turnos.
- **Fragua Viva.** Golpe Nexo de Metal · 120 · 3 Savia. Gana un escudo igual al 20 % del daño causado.
- **Débil ante:** Agua Tierra · **Resiste:** Aire Astral
- **Concepto:** Coatí curioso que se cubre con láminas de hojalata repujada.
- **Brote:** Hocico largo, cola anillada hacia arriba y una placa de lata en el lomo.
- **Tallado:** Coatí armado con placas repujadas, garras de herrería y cola anillada de eslabones; ágil
  y peleonero.
- **Claves 2D:** Hocico largo y cola anillada · placas de lata · gris plata y rojo
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 13 Cuerdo → Turbinón · COMÚN · Artificio

- Control · Constructo · juguete de cuerda · Meseta Fulgor
- **Mezcla mítica:** Juguete de cuerda de feria + turbina industrial.
- **Atributos:** VID 13→19 · ATQ 10→15 · DEF 13→18 · ESE 19→27 · VEL 15→21
- **Talento · Cuerda Larga.** Cada 3 turnos su siguiente ataque tiene prioridad +1.
- **Firma · Rehiletazo.** Especial · 55 · 2 Savia. 30 % de confundir.
- **Gran Autómata.** Golpe Nexo de Artificio · 120 · 3 Savia. Copia la última mejora activa del rival.
- **Débil ante:** Sombra Mente · **Resiste:** Rayo Astral
- **Concepto:** Juguete de hojalata con rehilete en la cabeza que cobró vida en una feria.
- **Brote:** Cuerpo de lata redondo, llave de cuerda en la espalda y un rehilete pequeño.
- **Tallado:** Autómata industrial de tres turbinas-rehilete, piernas de resorte y llave gigante; sopla
  vendavales mecánicos.
- **Claves 2D:** Cilindro de lata · tres turbinas · cobre, verde y turquesa
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

### Fuente PDF · página 59

#### 14 Okto → Krakensa · COMÚN · Mente

- Control · Acuático · pulpo · Marea Coralina
- **Mezcla mítica:** Kraken del folclore nórdico (solo el concepto) + caracola + tinta de sueño.
- **Atributos:** VID 13→19 · ATQ 10→14 · DEF 13→18 · ESE 19→27 · VEL 15→22
- **Talento · Tinta de Sueño.** Sus estados de confusión duran 1 turno más.
- **Firma · Mancha de Tinta.** Especial · 55 · 2 Savia. −20 % precisión del rival 2 turnos.
- **Sueño Lúcido.** Golpe Nexo de Mente · 115 · 3 Savia. El rival duerme 1 turno (no afecta a
  Misterio).
- **Débil ante:** Rayo Sombra · **Resiste:** Fuego Artificio
- **Concepto:** Pulpo que escribe con tinta de sueños dentro de una caracola.
- **Brote:** Cabeza grande y ocho bracitos enroscados en espiral.
- **Tallado:** Pulpo colosal de brazos larguísimos con ventosas luminosas y sigilos que hipnotizan;
  emerge de una caracola.
- **Claves 2D:** Cabeza-bulbo y 8 brazos · ventosas luminosas · violeta y rosa
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 15 Murk → Lunatajo · COMÚN · Sombra

- Veloz · Volador · murciélago · Velo Astral
- **Mezcla mítica:** Murciélago magueyero + luna creciente como hoz.
- **Atributos:** VID 11→16 · ATQ 16→23 · DEF 10→14 · ESE 12→17 · VEL 21→30
- **Talento · Vuelo Silencioso.** Su primer ataque del combate no puede esquivarse.
- **Firma · Picada Nocturna.** Especial · 70 · 2 Savia. +20 % si el rival tiene menos VEL.
- **Eclipse Breve.** Golpe Nexo de Sombra · 120 · 3 Savia. Anula las mejoras del rival.
- **Débil ante:** Fuego Luz · **Resiste:** Artificio Mente
- **Concepto:** Murciélago magueyero de alas como papel amate.
- **Brote:** Orejas enormes y alas plegadas como una capa.
- **Tallado:** Murciélago de alas de amate con bordes en forma de hoz lunar; cae en picada en silencio.
- **Claves 2D:** Alas de hoz · orejas enormes · índigo y plata
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

### Fuente PDF · página 60

#### 16 Bruma → Fatuoscuro · COMÚN · Sombra

- Soporte · Fantasmal · niebla · Marea Coralina
- **Mezcla mítica:** Fuego fatuo del folclore europeo + niebla de cenote.
- **Atributos:** VID 17→24 · ATQ 9→13 · DEF 13→19 · ESE 20→28 · VEL 11→16
- **Talento · Cortina de Niebla.** El aliado en 2v2 gana +10 % evasión.
- **Firma · Abrazo de Bruma.** Especial · 0 · 2 Savia. Cura 20 % y el rival pierde 1 de Savia.
- **Eclipse Breve.** Golpe Nexo de Sombra · 120 · 3 Savia. Anula las mejoras del rival.
- **Débil ante:** Fuego Luz · **Resiste:** Artificio Mente
- **Concepto:** Niebla de cenote que tomó forma de gota y se esconde detrás de los demás.
- **Brote:** Gota de niebla con ojitos de luz y borde ondulado.
- **Tallado:** Velo de niebla en capas con fuegos fatuos azules que flotan a su alrededor y engañan al
  rival.
- **Claves 2D:** Gota de niebla · luces fatuas · violeta humo y azul
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** Murk + Xolumi (10 %)
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

#### 17 Pabilo → Candelux · COMÚN · Luz

- Soporte · Ave · codorniz · Valle Copal
- **Mezcla mítica:** Codorniz + cirio de procesión + farol.
- **Atributos:** VID 17→24 · ATQ 9→13 · DEF 13→19 · ESE 20→28 · VEL 11→16
- **Talento · Luz de Camino.** +10 % precisión a todo el equipo.
- **Firma · Pabilo.** Especial · 0 · 2 Savia. Cura 20 % al aliado y +10 % ESE.
- **Amanecer del Nexo.** Golpe Nexo de Luz · 115 · 3 Savia. Cura 40 % al equipo y elimina estados.
- **Débil ante:** Flora Astral · **Resiste:** Aire Sombra
- **Concepto:** Codorniz con un copete en forma de llama de vela que alumbra el camino.
- **Brote:** Ave redonda de patitas cortas y copete de luz.
- **Tallado:** Gallinácea de guerra con corona de velas, espolones de cera dura y un farol que nunca se
  apaga.
- **Claves 2D:** Ave redonda con corona de velas · espolones · crema y oro
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

### Fuente PDF · página 61

#### 18 Lunk → Batraluna · COMÚN · Astral *(continúa en la p. 23)*

- Defensor · Anfibio · sapo · Velo Astral
- **Mezcla mítica:** Sapo de la luna (eco chino) + cráteres + metate volcánico.
- **Atributos:** VID 18→26 · ATQ 11→16 · DEF 20→29 · ESE 10→15 · VEL 10→14
- **Talento · Gravedad Baja.** Inmune a la reducción de VEL.
- **Firma · Fase Lunar.** Especial · 60 · 2 Savia. +20 % DEF; si es de noche en el juego, +20 % ESE.
- **Supernova Tallada.** Golpe Nexo de Astral · 125 · 3 Savia. Después queda con −20 % DEF 1 turno.
- **Débil ante:** Metal Artificio · **Resiste:** Tierra Luz
- **Concepto:** Sapo que guarda una pequeña luna sobre la espalda, como en el cuento del sapo lunar.
- **Brote:** Sapo ancho y redondo con manchas de cráter y una lunita flotando.
- **Tallado:** Sapo enorme de piel de piedra volcánica con una luna que gira a su alrededor como un
  satélite.
- **Claves 2D:** Sapo ancho · luna en órbita · azul noche y gris cráter
- **Obtención:** Huevo Común (cofres), Vitrina del Gabinete (Monedas) y crianza.
- **Linaje:** —
- **Coste:** 2 (Brote 1) · **Tallado:** nivel 12 · **Incubación:** 5 min

---

## Página 23 · Fichas 19–25

#### 19 Brinco → Voltalope · RARO · Aire Rayo

- Veloz · Cuadrúpedo · liebre · Meseta Fulgor
- **Mezcla mítica:** Chacalope del folclore norteamericano (liebre con astas) + liebre embaucadora
  africana.
- **Atributos:** VID 13→18 · ATQ 18→26 · DEF 10→14 · ESE 13→19 · VEL 22→31
- **Talento · Broma Pesada.** Al entrar en combate, el rival pierde 1 de Savia.
- **Firma · Zigzag.** Especial · 70 · 2 Savia. Prioridad +1; 20 % de parálisis.
- **Viento de los Cuatro Rumbos.** Golpe Nexo de Aire · 115 · 3 Savia. Prioridad máxima: siempre actúa
  primero.
- **Débil ante:** Tierra Metal Artificio Luz · **Resiste:** Agua Flora Mente
- **Concepto:** Liebre bromista que corre más rápido que el trueno que provoca.
- **Brote:** Orejas largas con puntas de chispa y patas traseras enormes.
- **Tallado:** Liebre de patas de resorte con astas de rayo bifurcadas; aparece y desaparece en zigzag.
- **Claves 2D:** Orejas y astas · patas traseras grandes · azul cielo y amarillo
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Zunzi + Zizi (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

### Fuente PDF · página 62

#### 20 Chispón → Fulminave · RARO · Rayo Metal

- Atacante · Ave · ave de tormenta · Meseta Fulgor
- **Mezcla mítica:** Ave de tormenta cuyo trueno sale de las alas (eco africano) + pararrayos.
- **Atributos:** VID 15→21 · ATQ 21→30 · DEF 11→16 · ESE 13→18 · VEL 16→23
- **Talento · Aletazo.** Sus ataques de Rayo hacen +10 % a rivales de Agua y Aire.
- **Firma · Trueno de Alas.** Especial · 75 · 2 Savia. En 2v2 alcanza al segundo rival al 40 %.
- **Relámpago Fulgurita.** Golpe Nexo de Rayo · 130 · 3 Savia. Ignora escudos.
- **Débil ante:** Agua Tierra Artificio · **Resiste:** Aire Mente Astral
- **Concepto:** Ave de tormenta cuyo trueno nace del batir de las alas.
- **Brote:** Pollito de plumas grises con puntas metálicas que chispean.
- **Tallado:** Ave rapaz de envergadura gigante con plumas-pararrayos de acero; cada aletazo es un
  trueno.
- **Claves 2D:** Alas abiertas con plumas de acero · cresta · amarillo y gris
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Zizi + Tinco (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 21 Kroa → Corvidúo · RARO · Mente Sombra

- Control · Ave · pareja · Velo Astral
- **Mezcla mítica:** Los cuervos del pensamiento y la memoria (eco nórdico) + espejo de obsidiana.
- **Atributos:** VID 15→21 · ATQ 11→16 · DEF 13→19 · ESE 20→29 · VEL 16→23
- **Talento · Pensamiento y Memoria.** Ve qué tipo de acción eligió el rival (básico, especial o cambio)
  antes de resolver.
- **Firma · Picotazo Doble.** Especial · 2 × 35 · 2 Savia. El segundo impacto confunde 25 %.
- **Sueño Lúcido.** Golpe Nexo de Mente · 115 · 3 Savia. El rival duerme 1 turno (no afecta a
  Misterio).
- **Débil ante:** Fuego Rayo Luz Sombra · **Resiste:** Artificio Mente
- **Concepto:** Dos cuervos que son una sola criatura: uno piensa y el otro recuerda.
- **Brote:** Dos polluelos de cuervo que nunca se separan.
- **Tallado:** Dos cuervos grandes de plumas de obsidiana que vuelan en espejo; uno ve el pasado y otro
  el futuro.
- **Claves 2D:** Dos aves en espejo · ojos de color distinto · negro violeta
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Okto + Murk (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

### Fuente PDF · página 63

#### 22 Lumbro → Faroibex · RARO · Luz

- Soporte · Cuadrúpedo · cabra · Valle Copal
- **Mezcla mítica:** Íbice de montaña + faro + porcelana vidriada.
- **Atributos:** VID 18→26 · ATQ 10→14 · DEF 15→21 · ESE 21→30 · VEL 12→17
- **Talento · Faro.** En 2v2, el aliado gana +10 % DEF.
- **Firma · Haz del Faro.** Especial · 60 · 2 Savia. Cura 15 % al aliado y ciega al rival 20 %.
- **Amanecer del Nexo.** Golpe Nexo de Luz · 115 · 3 Savia. Cura 40 % al equipo y elimina estados.
- **Débil ante:** Flora Astral · **Resiste:** Aire Sombra
- **Concepto:** Cabra montés de porcelana vidriada que guía a los perdidos con su cuerno.
- **Brote:** Cabrita de pelaje blanco con un cuernito de luz.
- **Tallado:** Cabra montés de porcelana con cuernos-faro curvos que proyectan haces de luz.
- **Claves 2D:** Cuernos largos y curvos · pezuñas de cobre · blanco porcelana y oro
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Pabilo + Teselo (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 23 Picoso → Magmacrán · RARO · Fuego Tierra

- Atacante · Arácnido · alacrán · Cumbre Brasa
- **Mezcla mítica:** Alacrán + obsidiana + flujo de lava.
- **Atributos:** VID 15→21 · ATQ 21→30 · DEF 12→17 · ESE 13→18 · VEL 15→22
- **Talento · Aguijón Ardiente.** Su Firma quema siempre a rivales de Flora.
- **Firma · Aguijón de Obsidiana.** Especial · 75 · 2 Savia. 30 % de quemadura.
- **Fogata del Tallador.** Golpe Nexo de Fuego · 120 · 3 Savia. En 2v2 golpea a ambos rivales al 75 %.
- **Débil ante:** Agua Aire Mente Astral · **Resiste:** Metal Flora Rayo Sombra
- **Concepto:** Alacrán de obsidiana con grietas de magma.
- **Brote:** Alacrán pequeño y redondo con tenazas grandes y cola enroscada.
- **Tallado:** Alacrán blindado de obsidiana con grietas de magma, tenazas de basalto y aguijón de vidrio
  volcánico.
- **Claves 2D:** Cola en arco con aguijón · tenazas grandes · negro y lava
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Comalú + Barrock (8 %) · Zanco + Dientón (10 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

### Fuente PDF · página 64

#### 24 Kunko → Alamar · RARO · Agua Aire

- Veloz · Acuático → Ave · Marea Coralina
- **Mezcla mítica:** El pez Kun que se vuelve el ave Peng (eco chino).
- **Atributos:** VID 13→18 · ATQ 18→25 · DEF 10→15 · ESE 13→19 · VEL 22→31
- **Talento · Cambio de Medio.** Al tallarse conserva su Firma de pez y gana +10 % VEL.
- **Firma · Salto de Espuma.** Especial · 70 · 2 Savia. +15 % evasión 1 turno.
- **Diluvio de Cántaros.** Golpe Nexo de Agua · 120 · 3 Savia. Limpia los efectos negativos del equipo.
- **Débil ante:** Metal Flora Rayo Luz · **Resiste:** Fuego Tierra
- **Concepto:** Un pez que, al tallarse, se convierte en ave: su evolución cambia de medio.
- **Brote:** Pececito plateado con aletas largas como alas.
- **Tallado:** Ave marina de alas-aleta escamadas y cola de pez; cambia de medio al tallarse.
- **Claves 2D:** Alas-aleta · cola de pez · azul marino y espuma
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Rillip + Yek (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 25 Dientón → Castorre · RARO · Flora Tierra *(continúa en la p. 24)*

- Defensor · Cuadrúpedo · castor · Valle Copal
- **Mezcla mítica:** Castor constructor (eco canadiense) + chinampa de Xochimilco + torre de troncos.
- **Atributos:** VID 20→28 · ATQ 13→18 · DEF 22→31 · ESE 11→16 · VEL 10→15
- **Talento · Huerto.** Cura 5 % al final de cada turno.
- **Firma · Embestida de Chinampa.** Especial · 70 · 2 Savia. +10 % DEF 2 turnos.
- **Floración del Valle.** Golpe Nexo de Flora · 115 · 3 Savia. Cura 25 % de VID al equipo.
- **Débil ante:** Fuego Aire Astral · **Resiste:** Agua Metal Rayo Luz
- **Concepto:** Castor constructor que levanta diques-jardín en los canales del Valle.
- **Brote:** Castorcito de dientes naranjas que roe ramitas de copal y carga una hoja.
- **Tallado:** Castor arquitecto con una torre-dique de troncos y jardín flotante en el lomo, cola de
  remo blindada y dientes de hacha.
- **Claves 2D:** Lomo-dique de troncos · cola de remo · café madera y verde
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Vainas + Teselo (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

---
## Página 24 · Fichas 26–31

### Fuente PDF · página 65

#### 26 Cotorro → Lorapiente · RARO · Agua Flora

- Control · Serpentino · cabeza de loro · Marea Coralina
- **Mezcla mítica:** Serpiente de humedal con cabeza de loro (eco guaraní) + manglar.
- **Atributos:** VID 15→21 · ATQ 11→16 · DEF 13→19 · ESE 20→29 · VEL 16→23
- **Talento · Imitación.** Una vez por combate repite el último básico del rival.
- **Firma · Grito de Manglar.** Especial · 55 · 2 Savia. 35 % de confundir.
- **Diluvio de Cántaros.** Golpe Nexo de Agua · 120 · 3 Savia. Limpia los efectos negativos del equipo.
- **Débil ante:** Fuego Aire Flora Rayo · **Resiste:** Agua Metal Luz
- **Concepto:** Serpiente de humedal con cabeza de loro que protege los manglares.
- **Brote:** Culebrita verde con pico curvo y plumitas rojas.
- **Tallado:** Serpiente larga de escamas-hoja con gran cresta de plumas rojas y pico curvo; imita voces.
- **Claves 2D:** Cuerpo en S · pico de loro · verde y rojo
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Xolumi + Agavo (8 %) · Dientón + Kunko (10 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 27 Medu → Cometaura · RARO · Astral

- Soporte · Astral · medusa-cometa · Marea Coralina
- **Mezcla mítica:** Medusa + cometa + farol de papel de china.
- **Atributos:** VID 18→26 · ATQ 10→14 · DEF 15→21 · ESE 21→30 · VEL 12→17
- **Talento · Estela.** El aliado que entra al campo gana +15 % ESE 2 turnos.
- **Firma · Cola de Cometa.** Especial · 60 · 2 Savia. Cura 15 % al equipo.
- **Supernova Tallada.** Golpe Nexo de Astral · 125 · 3 Savia. Después queda con −20 % DEF 1 turno.
- **Débil ante:** Metal Artificio · **Resiste:** Tierra Luz
- **Concepto:** Medusa del cielo nocturno con cola de cometa.
- **Brote:** Campana pequeña translúcida con tres tentáculos de estrella.
- **Tallado:** Medusa enorme con constelaciones dentro y cola de cometa de cinco tentáculos.
- **Claves 2D:** Campana translúcida · cola de cometa · índigo y cian
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Lunk + Bruma (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

### Fuente PDF · página 66

#### 28 Remache → Mechalata · RARO · Artificio Metal

- Defensor · Constructo · bípedo · Meseta Fulgor
- **Mezcla mítica:** Hojalatero + robot industrial de fábrica.
- **Atributos:** VID 20→28 · ATQ 13→18 · DEF 22→31 · ESE 11→16 · VEL 10→15
- **Talento · Taller.** Al cambiar, el monstruo que entra recupera 10 %.
- **Firma · Martillazo Repujado.** Especial · 75 · 2 Savia. Rompe escudos.
- **Gran Autómata.** Golpe Nexo de Artificio · 120 · 3 Savia. Copia la última mejora activa del rival.
- **Débil ante:** Agua Tierra Sombra Mente · **Resiste:** Aire Rayo Astral
- **Concepto:** Autómata bípedo de hojalata que repara a los demás en el taller.
- **Brote:** Muñeco de lata con cabeza-linterna y bracitos de pinza.
- **Tallado:** Mecha industrial de lámina repujada, cabeza-linterna, martillo-brazo y corazón de engranes
  a la vista.
- **Claves 2D:** Bípedo cuadrado · cabeza-linterna · lata y latón
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Cuerdo + Tinco (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 29 Linterno → Farolánima · RARO · Luz Sombra

- Soporte · Fantasmal · farol · Velo Astral
- **Mezcla mítica:** Farol de papel calado + ánima de los caminos (sin referencias religiosas).
- **Atributos:** VID 18→26 · ATQ 10→14 · DEF 15→21 · ESE 21→30 · VEL 12→17
- **Talento · Camino de Pétalos.** Si un aliado cae, el siguiente entra con 10 % de escudo.
- **Firma · Luz de Ánima.** Especial · 50 · 2 Savia. Cura 15 % y ciega 20 %.
- **Amanecer del Nexo.** Golpe Nexo de Luz · 115 · 3 Savia. Cura 40 % al equipo y elimina estados.
- **Débil ante:** Fuego Flora Luz Astral · **Resiste:** Aire Artificio Sombra Mente
- **Concepto:** Ánima que vive dentro de un farol de papel y acompaña a los que caminan de noche.
- **Brote:** Farolito de papel con carita y un velo corto.
- **Tallado:** Farol alto de papel calado con velo de sombra y pétalos de luz que orbitan.
- **Claves 2D:** Farol vertical · velo · naranja papel y violeta
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Pabilo + Bruma (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

### Fuente PDF · página 67

#### 30 Garabato → Monomural · RARO · Artificio

- Control · Primate · Valle Copal
- **Mezcla mítica:** Monos artistas de los relatos mayas (inspiración, sin nombres) + muralismo.
- **Atributos:** VID 15→21 · ATQ 11→16 · DEF 13→18 · ESE 20→29 · VEL 17→24
- **Talento · Boceto.** El primer especial que usa cada combate cuesta 1 de Savia menos.
- **Firma · Trazo Vivo.** Especial · 50 · 2 Savia. El rival no puede cambiar 2 turnos.
- **Gran Autómata.** Golpe Nexo de Artificio · 120 · 3 Savia. Copia la última mejora activa del rival.
- **Débil ante:** Sombra Mente · **Resiste:** Rayo Astral
- **Concepto:** Mono artesano que pinta lo que imagina y lo vuelve real por un instante.
- **Brote:** Monito de cola enroscada con un pincel tras la oreja.
- **Tallado:** Mono de brazos largos con pinceles, flauta y paleta flotante; pinta trampas en el aire.
- **Claves 2D:** Cola espiral · pinceles · café y colores primarios
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Cuerdo + Kuachi (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 31 Zanco → Grullacandil · RARO · Fuego *(continúa en la p. 25)*

- Atacante · Ave · grulla de una pata · Cumbre Brasa
- **Mezcla mítica:** Ave de una pata ligada al fuego (eco chino) + candil.
- **Atributos:** VID 14→20 · ATQ 21→30 · DEF 11→16 · ESE 14→20 · VEL 15→22
- **Talento · Equilibrio.** Inmune al aturdimiento.
- **Firma · Picotazo de Candil.** Especial · 75 · 2 Savia. 25 % de quemadura.
- **Fogata del Tallador.** Golpe Nexo de Fuego · 120 · 3 Savia. En 2v2 golpea a ambos rivales al 75 %.
- **Débil ante:** Agua Mente · **Resiste:** Flora Sombra
- **Concepto:** Grulla de una sola pata que guarda una lámpara de aceite en el pecho.
- **Brote:** Polluelo zancudo de plumas de brasa que se balancea en una pata.
- **Tallado:** Grulla alta de cuello en S, plumas de ascua y un candil de barro encendido en el pecho.
- **Claves 2D:** Una pata · cuello en S · rojo brasa y negro
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Comalú + Zunzi (8 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

---

## Página 25 · Fichas 32–38

### Fuente PDF · página 68

#### 32 Ovillo → Aracnógrafa · RARO · Mente Artificio

- Control · Arácnido · tejedora · Velo Astral
- **Mezcla mítica:** Araña tejedora de los cuentos (eco africano) + telar de cintura + mapa.
- **Atributos:** VID 15→21 · ATQ 10→15 · DEF 13→19 · ESE 20→29 · VEL 17→24
- **Talento · Red de Caminos.** Los rivales no pueden huir del combate ni cambiar sin perder 1 de Savia.
- **Firma · Telaraña-Mapa.** Especial · 45 · 2 Savia. −25 % VEL del rival 3 turnos.
- **Sueño Lúcido.** Golpe Nexo de Mente · 115 · 3 Savia. El rival duerme 1 turno (no afecta a
  Misterio).
- **Débil ante:** Rayo Sombra Mente · **Resiste:** Fuego Artificio Astral
- **Concepto:** Araña tejedora que hila mapas de los caminos del Nexo.
- **Brote:** Arañita redonda con patas cortas y un ovillo de hilo dorado.
- **Tallado:** Araña cartógrafa con un mapa bordado en el abdomen y una red-mapa de hilos dorados a su
  espalda.
- **Claves 2D:** Abdomen grande · red dorada · violeta y oro
- **Obtención:** Huevo Raro (cofres), Vitrina (Monedas) y linaje de dos Comunes.
- **Linaje:** Okto + Cuerdo (8 %) · Garabato + Kroa (10 %)
- **Coste:** 3 (Brote 2) · **Tallado:** nivel 15 · **Incubación:** 20 min

#### 33 Cempa → Cempasol · ÉPICO · Fuego Luz

- Atacante · Cuadrúpedo · venado · Valle Copal
- **Mezcla mítica:** Venado + cempasúchil + brasa dorada.
- **Atributos:** VID 15→22 · ATQ 22→32 · DEF 11→16 · ESE 15→22 · VEL 17→24
- **Talento · Sendero de Pétalos.** Al derrotar a un rival, cura 15 %.
- **Firma · Corona Ardiente.** Especial · 80 · 2 Savia. 30 % de quemadura; +10 % de daño de Luz 2
  turnos.
- **Mil Pétalos.** Golpe Nexo · 125 · 3 Savia. Quema a todos los rivales; cura 15 % al equipo.
- **Débil ante:** Agua Flora Mente Astral · **Resiste:** Aire Sombra
- **Concepto:** Venado cola blanca con astas florecidas de cempasúchil que arden sin quemar.
- **Brote:** Cervatillo con manchas de pétalo y botones naranjas en la frente.
- **Tallado:** Venado de astas florecidas que arden sin quemar y un sendero de pétalos de luz.
- **Claves 2D:** Astas de flores · porte alto · naranja y oro
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Zanco + Lumbro (6 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 69

#### 34 Cenoti → Leviacielo · ÉPICO · Agua Astral

- Control · Acuático · pez de cenote · Marea Coralina
- **Mezcla mítica:** Leviatán (concepto de monstruo marino) + pez ciego de cenote + cielo estrellado.
- **Atributos:** VID 15→22 · ATQ 11→16 · DEF 15→21 · ESE 22→31 · VEL 18→26
- **Talento · Sin Ojos.** Inmune a la ceguera y a la reducción de precisión.
- **Firma · Reflejo del Cenote.** Especial · 70 · 2 Savia. −20 % VEL del rival y +10 % evasión propia.
- **Cielo Hundido.** Golpe Nexo · 120 · 3 Savia. El rival queda con −30 % VEL 3 turnos.
- **Débil ante:** Metal Flora Rayo Artificio · **Resiste:** Fuego Tierra Luz
- **Concepto:** Pez ciego de cenote que lleva el cielo estrellado dentro del cuerpo.
- **Brote:** Pez pálido con una ventanita de estrellas en el costado.
- **Tallado:** Pez colosal de cristal con una noche completa dentro y aletas como velas; nada en el aire.
- **Claves 2D:** Cuerpo de cristal con estrellas · aletas-vela · turquesa y noche
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Kunko + Medu (6 %) · Cotorro + Boreal (10 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

#### 35 Pelón → Zopilatón · ÉPICO · Aire Metal

- Defensor · Ave · zopilote · Cumbre Brasa
- **Mezcla mítica:** Zopilote rey + hojalata repujada + veleta.
- **Atributos:** VID 21→30 · ATQ 13→19 · DEF 23→33 · ESE 13→18 · VEL 11→16
- **Talento · Carroñero.** Cuando un monstruo cae en el campo, gana +15 % ATQ 2 turnos.
- **Firma · Ala Veleta.** Especial · 70 · 2 Savia. Escudo del 15 % al aliado.
- **Huracán de Lámina.** Golpe Nexo · 120 · 3 Savia. Escudo del 25 % al equipo.
- **Débil ante:** Agua Tierra Metal Luz · **Resiste:** Aire Flora Astral
- **Concepto:** Zopilote rey con alas de hojalata repujada que limpia los campos tras la tormenta.
- **Brote:** Polluelo pelón de cabeza dorada y plumón gris.
- **Tallado:** Zopilote rey de alas de lámina repujada como veletas, cabeza dorada y garras de herrero.
- **Claves 2D:** Alas abiertas de lámina · cabeza dorada · gris y oro
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Chispón + Kunko (6 %) · Remache + Guaca (10 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 70

#### 36 Chaquiro → Fulgurila · ÉPICO · Tierra Rayo

- Bruto · Cuadrúpedo · lagarto · Meseta Fulgor
- **Mezcla mítica:** Monstruo de Gila + fulgurita + chaquira.
- **Atributos:** VID 20→28 · ATQ 21→30 · DEF 17→24 · ESE 10→14 · VEL 14→20
- **Talento · Reserva.** Guarda grasa en la cola: la primera vez que bajaría de 25 % de VID, recupera
  15 %.
- **Firma · Mordida Fulgurita.** Especial · 80 · 2 Savia. 25 % de parálisis.
- **Rayo en la Arena.** Golpe Nexo · 130 · 3 Savia. Ignora escudos y paraliza 30 %.
- **Débil ante:** Aire Tierra Artificio Astral · **Resiste:** Agua Metal Rayo Mente
- **Concepto:** Monstruo de Gila con cuentas de fulgurita, el vidrio que nace cuando el rayo cae en la
  arena.
- **Brote:** Lagartito de cuentas naranjas y negras, cola gorda.
- **Tallado:** Lagarto de cuentas de vidrio de rayo con cristales que se cargan en el lomo.
- **Claves 2D:** Cuerpo bajo · cristales dorsales · naranja, negro y amarillo
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Picoso + Brinco (6 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

#### 37 Guaca → Aráureo · ÉPICO · Luz Aire

- Atacante · Ave · guacamaya · Valle Copal
- **Mezcla mítica:** Guacamaya + vitral + sol tallado.
- **Atributos:** VID 15→22 · ATQ 22→32 · DEF 11→16 · ESE 15→22 · VEL 17→24
- **Talento · Plumaje Solar.** Sus ataques de Luz tienen +10 % de crítico.
- **Firma · Barrido de Alba.** Especial · 80 · 2 Savia. En 2v2 golpea a ambos rivales al 70 %.
- **Amanecer de Plumas.** Golpe Nexo · 120 · 3 Savia. Ciega a todos los rivales 1 turno.
- **Débil ante:** Metal Flora Luz Astral · **Resiste:** Aire Tierra Sombra
- **Concepto:** Guacamaya de plumas de luz que pinta el amanecer al volar.
- **Brote:** Pichón de guacamaya con copete corto y plumas de colores suaves.
- **Tallado:** Guacamaya de alas-vitral extendidas y cola de serpentinas de luz.
- **Claves 2D:** Alas abiertas · cola larga · oro y colores de vitral
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Lumbro + Brinco (6 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 71

#### 38 Brujo → Brujalada · ÉPICO · Sombra Mente *(continúa en la p. 26)*

- Control · Insecto · palomilla · Velo Astral
- **Mezcla mítica:** Palomilla nocturna + rebozo bordado + luna.
- **Atributos:** VID 15→22 · ATQ 11→16 · DEF 15→21 · ESE 22→31 · VEL 18→26
- **Talento · Polvo de Sueño.** +15 % de probabilidad de dormir y confundir.
- **Firma · Ojos de Ala.** Especial · 60 · 2 Savia. 40 % de dormir.
- **Noche sin Fin.** Golpe Nexo · 115 · 3 Savia. Duerme al rival y +50 % a la siguiente Pesadilla.
- **Débil ante:** Fuego Rayo Luz Sombra · **Resiste:** Artificio Mente
- **Concepto:** Palomilla nocturna cuyas alas cuentan sueños a quien las mira.
- **Brote:** Palomilla peluda de antenas plumosas.
- **Tallado:** Polilla enorme con ojos pintados en las alas y polvo de sueño en órbita.
- **Claves 2D:** Cuatro alas con ojos · antenas plumosas · índigo y violeta
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Kroa + Linterno (6 %) · Ovillo + Hilacho (10 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

---

## Página 26 · Fichas 39–43

#### 39 Tizón → Tizonsierpe · ÉPICO · Fuego Flora

- Soporte · Serpentino · Valle Copal
- **Mezcla mítica:** Serpiente de fuego que protege los campos (eco tupí).
- **Atributos:** VID 20→28 · ATQ 10→15 · DEF 15→22 · ESE 22→32 · VEL 13→19
- **Talento · Guardabosque.** Inmune a la quemadura; absorbe quemaduras del aliado.
- **Firma · Brote de Ceniza.** Especial · 0 · 2 Savia. Cura 25 % al aliado y le quita la quemadura.
- **Renacer del Bosque.** Golpe Nexo · 115 · 3 Savia. Cura 35 % al equipo y quema al rival.
- **Débil ante:** Agua Fuego Aire Mente · **Resiste:** Flora Luz Sombra
- **Concepto:** Serpiente de fuego que protege el bosque: devora los incendios en lugar de provocarlos.
- **Brote:** Culebrita de brasa con hojitas en la cabeza.
- **Tallado:** Serpiente de ascuas con cresta de hojas; devora las llamas y deja brotes.
- **Claves 2D:** Cuerpo en S · cresta de hojas · brasa y verde
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Cotorro + Zanco (6 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 72

#### 40 Tuerco → Engrifo · ÉPICO · Aire Artificio

- Veloz · Quimera · grifo mecánico · Meseta Fulgor
- **Mezcla mítica:** Grifo de la mitología griega y medieval + relojería + aviación antigua.
- **Atributos:** VID 13→19 · ATQ 19→27 · DEF 11→16 · ESE 14→20 · VEL 24→34
- **Talento · Viento en Popa.** +20 % VEL el primer turno.
- **Firma · Remada Celeste.** Especial · 70 · 2 Savia. Golpea primero si tiene más VEL que el rival.
- **Travesía del Cielo.** Golpe Nexo · 120 · 3 Savia. Prioridad máxima y +20 % VEL al equipo.
- **Débil ante:** Metal Luz Sombra Mente · **Resiste:** Tierra Flora Rayo Astral
- **Concepto:** Un grifo de latón que el Tallador armó con piezas de relojes y que aprendió a volar solo.
- **Brote:** Cachorro de grifo de latón con alitas de hojalata y una llave de cuerda en la espalda.
- **Tallado:** Grifo mecánico de latón: cabeza de águila, cuerpo de felino, alas de plumas-engrane y
  hélice en la cola.
- **Claves 2D:** Cabeza de águila y alas de engranes · hélice · latón y cobre
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Garabato + Kunko (6 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

#### 41 Boreal → Auroribú · ÉPICO · Luz Astral

- Soporte · Cuadrúpedo · caribú · Velo Astral
- **Mezcla mítica:** Caribú del norte + aurora boreal (eco canadiense).
- **Atributos:** VID 20→28 · ATQ 10→15 · DEF 15→22 · ESE 22→32 · VEL 13→19
- **Talento · Noche Polar.** En 2v2 el aliado gana +15 % ESE.
- **Firma · Velo de Aurora.** Especial · 0 · 2 Savia. Escudo del 20 % al equipo.
- **Aurora del Nexo.** Golpe Nexo · 115 · 3 Savia. Cura 30 % al equipo y +20 % DEF.
- **Débil ante:** Metal Flora Artificio Astral · **Resiste:** Aire Tierra Luz Sombra
- **Concepto:** Caribú del norte con astas hechas de aurora boreal.
- **Brote:** Cervatillo de pelaje espeso con astas cortas de luz.
- **Tallado:** Caribú con astas enormes de aurora que ondulan y aliento de estrellas.
- **Claves 2D:** Astas de aurora · porte alto · crema, verde y violeta
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Lumbro + Medu (6 %) · Guaca + Cenoti (10 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 73

#### 42 Hilacho → Titeránima · ÉPICO · Sombra Artificio

- Control · Fantasmal · marioneta · Velo Astral
- **Mezcla mítica:** Marioneta de hilo + teatro de títeres europeo.
- **Atributos:** VID 15→22 · ATQ 12→17 · DEF 14→20 · ESE 22→31 · VEL 18→26
- **Talento · Hilos.** Una vez por combate obliga al rival a repetir su acción anterior.
- **Firma · Tirón de Hilos.** Especial · 60 · 2 Savia. El rival no puede usar especiales 1 turno.
- **Función Final.** Golpe Nexo · 120 · 3 Savia. Anula el Golpe Nexo del rival este combate.
- **Débil ante:** Fuego Luz Sombra Mente · **Resiste:** Rayo Artificio Astral
- **Concepto:** Ánima que mueve una marioneta de madera desde unos hilos que nadie ve.
- **Brote:** Titerito de madera con cara pintada y hilos sueltos.
- **Tallado:** Marioneta alta articulada con cruceta flotante y velo de sombra; mueve los hilos del
  rival.
- **Claves 2D:** Cruceta e hilos · juntas de madera · madera y violeta
- **Obtención:** Huevo Épico (cofres de Oro en adelante), Vitrina (Monedas o Gemas) y linaje de dos
  Raros.
- **Linaje:** Linterno + Remache (6 %) · Brujo + Tuerco (10 %)
- **Coste:** 4 (Brote 3) · **Tallado:** nivel 18 · **Incubación:** 2 h

### Fuente PDF · página 74

#### 43 Lumbrela → Papalumen, el Vitral Vivo · LEGENDARIO · Aire Luz *(continúa en la p. 27)*

- Soporte · Insecto · mariposa-linterna · Valle Copal
- **Mezcla mítica:** Mariposa monarca (migración) + papel picado + linterna.
- **Atributos:** VID 20→29 · ATQ 11→16 · DEF 17→24 · ESE 24→34 · VEL 15→21
- **Talento · Migración.** En 2v2 el aliado gana +15 % VEL y ESE.
- **Firma · Vitral de Alas.** Especial · 0 · 2 Savia. Refleja 30 % de especiales al equipo 2 turnos.
- **Migración de Luz.** Golpe Nexo · 120 · 3 Savia. Cura 35 % al equipo y lo hace inmune a estados 2
  turnos.
- **Aura:** Aura dorada, vitrales proyectados y fragmentos de papel flotando.
- **Huevo:** Huevo legendario: papel picado dorado sobre cristal.
- **Débil ante:** Metal Flora Luz Astral · **Resiste:** Aire Tierra Sombra
- **Concepto:** La mariposa-linterna de papel picado que guía la migración de los Brotes perdidos.
- **Brote:** Oruga-linterna con dos alitas de papel recién abiertas.
- **Tallado:** Cuatro alas de papel picado translúcido que proyectan vitrales en el suelo; cuerpo de
  linterna.
- **Claves 2D:** Alas enormes caladas · cuerpo linterna · oro, cielo y naranja
- **Obtención:** Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos
  Épicos (4 %).
- **Linaje:** Guaca + Brujo (4 %) · Guaca + Nébulo (10 %)
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 20 · **Incubación:** 8 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Aire | Ráfaga, Pluma Cortante, Remolino | Corriente Ascendente, Torbellino |
| Luz | Destello, Rayo de Alba, Halo | Vitral, Lanza Solar |

*(Tabla «REPERTORIO EQUIPABLE».)*

---

## Página 27 · Fichas 44–48

### Fuente PDF · página 75

#### 44 Geoda → Gemaboa, la Guardiana de Vetas · LEGENDARIO · Tierra Metal

- Defensor · Serpentino · colmillos · Cumbre Brasa
- **Mezcla mítica:** Serpiente que guarda diamantes (eco sudafricano) + geoda.
- **Atributos:** VID 22→32 · ATQ 13→19 · DEF 25→36 · ESE 13→19 · VEL 13→18
- **Talento · Veta Madre.** +10 % DEF por cada aliado de Tierra o Metal (máx. +20 %).
- **Firma · Colmillo de Cuarzo.** Especial · 85 · 2 Savia. Rompe escudos y −15 % DEF del rival.
- **Derrumbe de Geodas.** Golpe Nexo · 125 · 3 Savia. Escudo del 30 % propio.
- **Aura:** Aura dorada con cristales flotantes.
- **Huevo:** Huevo legendario: geoda abierta con vetas de oro.
- **Débil ante:** Agua Aire Tierra Astral · **Resiste:** Metal Rayo
- **Concepto:** Serpiente gigante con colmillos de cristal que guarda las vetas de la montaña.
- **Brote:** Culebrita de escamas de roca con dos colmillitos de cuarzo.
- **Tallado:** Serpiente colosal con colmillos de cristal como de elefante y escamas de geoda.
- **Claves 2D:** Cuerpo enorme en S · colmillos de cristal · piedra y cuarzo
- **Obtención:** Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos
  Épicos (4 %).
- **Linaje:** Chaquiro + Pelón (4 %)
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 20 · **Incubación:** 8 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Tierra | Pisotón, Lanza de Barro, Arena en los Ojos | Muralla de Adobe, Grieta |
| Metal | Golpe de Yunque, Remache, Limadura | Escudo Repujado, Cuchilla de Hojalata |

### Fuente PDF · página 76

#### 45 Nébulo → Astrocorcel, el Ocho Vientos · LEGENDARIO · Aire Astral

- Veloz · Cuadrúpedo · corcel · Velo Astral
- **Mezcla mítica:** El corcel de ocho patas (eco nórdico) + constelación.
- **Atributos:** VID 14→20 · ATQ 20→28 · DEF 12→17 · ESE 15→22 · VEL 26→37
- **Talento · Ocho Vientos.** Su VEL no puede reducirse; +10 % evasión.
- **Firma · Galope Estelar.** Especial · 80 · 2 Savia. Prioridad +1.
- **Galope de Ocho Vientos.** Golpe Nexo · 125 · 3 Savia. Actúa primero y golpea dos veces al 60 %.
- **Aura:** Aura dorada y patas-eco luminosas.
- **Huevo:** Huevo legendario: noche con ocho estrellas doradas.
- **Débil ante:** Metal Artificio Luz · **Resiste:** Tierra Flora
- **Concepto:** Corcel cuyas patas se desdoblan al galopar: parece tener ocho cuando corre entre
  estrellas.
- **Brote:** Potrillo de crin de nube y pezuñas de estrella.
- **Tallado:** Corcel de crin de galaxia; al galopar aparecen patas-eco translúcidas.
- **Claves 2D:** Caballo alto · patas-eco · azul noche y plata
- **Obtención:** Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos
  Épicos (4 %).
- **Linaje:** Boreal + Tuerco (4 %) · Boreal + Lumbrela (10 %)
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 20 · **Incubación:** 8 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Aire | Ráfaga, Pluma Cortante, Remolino | Corriente Ascendente, Torbellino |
| Astral | Polvo de Estrella, Órbita, Gravedad | Lluvia de Meteoros, Constelación |

### Fuente PDF · página 77

#### 46 Bisi → Gemitrueno, Serpiente de Dos Mareas · LEGENDARIO · Agua Rayo

- Atacante · Serpentino · dos cabezas · Marea Coralina
- **Mezcla mítica:** Serpiente alada de dos cabezas (eco andino) + nube de tormenta.
- **Atributos:** VID 17→24 · ATQ 24→34 · DEF 13→18 · ESE 15→22 · VEL 18→26
- **Talento · Dos Mareas.** Cada turno alterna: +15 % a Agua o +15 % a Rayo.
- **Firma · Doble Mordida.** Especial · 2 × 45 · 2 Savia. Un impacto de Agua y otro de Rayo.
- **Diluvio y Trueno.** Golpe Nexo · 130 · 3 Savia. En 2v2 golpea a ambos rivales.
- **Aura:** Aura dorada con lluvia y chispas.
- **Huevo:** Huevo legendario: dos yemas, azul y dorada.
- **Débil ante:** Tierra Flora Rayo Artificio · **Resiste:** Agua Fuego Metal Mente
- **Concepto:** Serpiente alada de dos cabezas: una trae la lluvia y la otra el trueno.
- **Brote:** Culebrita de dos cabecitas que discuten todo el tiempo.
- **Tallado:** Serpiente alada de dos cabezas, una de agua y otra de rayo, con alas de nube.
- **Claves 2D:** Dos cabezas · alas de nube · turquesa y amarillo
- **Obtención:** Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos
  Épicos (4 %).
- **Linaje:** Cenoti + Chaquiro (4 %)
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 20 · **Incubación:** 8 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Agua | Chorro, Ola Corta, Burbuja Fría | Marea Lenta, Manantial |
| Rayo | Chispa, Descarga, Estática | Tormenta Encadenada, Sobrecarga |

### Fuente PDF · página 78

#### 47 Petardo → Pirotoro, el Castillo de Feria · LEGENDARIO · Fuego Artificio Luz

- Atacante · Cuadrúpedo · toro de feria · Cumbre Brasa
- **Mezcla mítica:** Torito de pirotecnia de feria + castillo de fuegos.
- **Atributos:** VID 17→24 · ATQ 24→34 · DEF 13→19 · ESE 15→21 · VEL 18→26
- **Talento · Castillo.** Cada ataque que recibe carga 1 cohete (máx. 3); su Golpe Nexo hace +10 % por
  cohete.
- **Firma · Embestida de Cohetes.** Especial · 85 · 2 Savia. 30 % de quemadura.
- **Castillo de Feria.** Golpe Nexo · 125 · 3 Savia. Golpea a todos los rivales.
- **Aura:** Aura dorada, chispas de colores y rehiletes flotantes.
- **Huevo:** Huevo legendario: papel de colores sobre carrizo dorado.
- **Débil ante:** Agua Flora Mente Astral · **Resiste:** Aire Rayo Sombra
- **Concepto:** El toro de fiesta: un armazón de carrizo cargado de cohetes que estalla en luces.
- **Brote:** Becerrito de carrizo con un rehilete en el lomo.
- **Tallado:** Toro monumental de carrizo con castillo de rehiletes encendidos sobre el lomo.
- **Claves 2D:** Toro con castillo en el lomo · chispas · rojo, oro y papel de colores
- **Obtención:** Huevo Legendario (cofres, muy baja probabilidad), Vitrina semanal y linaje de dos
  Épicos (4 %).
- **Linaje:** Cempa + Hilacho (4 %)
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 20 · **Incubación:** 8 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Fuego | Chispazo, Zarpa de Brasa, Humo de Copal | Comal Ardiente, Muro de Ascuas |
| Artificio | Engrane, Resorte, Chispa de Taller | Trampa de Cuerda, Ajuste Fino |
| Luz | Destello, Rayo de Alba, Halo | Vitral, Lanza Solar |

### Fuente PDF · página 79

#### 48 Mediluna → Eclipsor, el Gato de Dos Cielos · ÚNICO · Luz Sombra Astral *(continúa en la p. 28)*

- Control · Cuadrúpedo · felino · Velo Astral
- **Mezcla mítica:** Felino + eclipse + velo perlado e índigo.
- **Atributos:** VID 18→25 · ATQ 13→19 · DEF 16→23 · ESE 24→34 · VEL 19→27
- **Talento · Dos Cielos.** Al entrar elige Día (+20 % curación) o Noche (+20 % daño de Sombra).
- **Firma · Corona del Eclipse.** Especial · 80 · 2 Savia. Anula 1 mejora del rival.
- **Eclipse Total.** Golpe Nexo · 125 · 3 Savia. Anula todas las mejoras del rival y cura 20 %.
- **Aura:** Colores propios: oro e índigo partidos, halo iridiscente y corona de eclipse.
- **Huevo:** Huevo único: mitad perla, mitad índigo, con un anillo dorado.
- **Débil ante:** Fuego Metal Flora Artificio Luz Astral · **Resiste:** Aire Tierra Sombra Mente
- **Concepto:** Un felino partido en dos cielos: la mitad es día y la otra mitad es noche.
- **Brote:** Gatito de pelaje perlado con media cara índigo.
- **Tallado:** Felino flotante partido en día y noche, con corona de eclipse.
- **Claves 2D:** Felino con anillo · mitad perla, mitad índigo
- **Obtención:** Cofre Nexo o historia (Acto III). Uno por cuenta.
- **Linaje:** —
- **Coste:** 6 (Brote 5) · **Tallado:** nivel 22 · **Incubación:** 24 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Luz | Destello, Rayo de Alba, Halo | Vitral, Lanza Solar |
| Sombra | Zarpa Nocturna, Niebla, Susurro | Velo de Noche, Pesadilla |
| Astral | Polvo de Estrella, Órbita, Gravedad | Lluvia de Meteoros, Constelación |

---

## Página 28 · Fichas 49–50 y crianza

### Fuente PDF · página 80

#### 49 Nácar → Aetherion, la Ballena Cartógrafa · ÚNICO · Agua Astral Mente

- Soporte · Acuático · ballena del cielo · Velo Astral
- **Mezcla mítica:** Ballena gris + mapa celeste + brújula.
- **Atributos:** VID 21→30 · ATQ 12→17 · DEF 18→25 · ESE 24→35 · VEL 15→21
- **Talento · Canto Cartógrafo.** Al entrar revela las debilidades del rival y da +10 % de daño al equipo
  contra ellas.
- **Firma · Canto Profundo.** Especial · 60 · 2 Savia. Cura 20 % al equipo y duerme 20 %.
- **Mapa del Cielo.** Golpe Nexo · 115 · 3 Savia. Cura 40 % al equipo y +20 % ESE.
- **Aura:** Colores propios: nácar y aurora, halo iridiscente.
- **Huevo:** Huevo único: nácar con un mapa estelar grabado.
- **Débil ante:** Metal Flora Rayo Artificio Sombra · **Resiste:** Fuego Tierra Luz
- **Concepto:** Ballena gris que nada por el cielo nocturno dibujando mapas de estrellas.
- **Brote:** Ballenato que flota con una brújula de nácar en la frente.
- **Tallado:** Ballena colosal que nada en el cielo con un mapa estelar grabado en el lomo.
- **Claves 2D:** Ballena flotante · mapa en el lomo · nácar y aurora
- **Obtención:** Cofre Nexo o historia (Acto III). Uno por cuenta.
- **Linaje:** —
- **Coste:** 6 (Brote 5) · **Tallado:** nivel 22 · **Incubación:** 24 h

| ELEMENTO | BÁSICOS | ESPECIALES |
|---|---|---|
| Agua | Chorro, Ola Corta, Burbuja Fría | Marea Lenta, Manantial |
| Astral | Polvo de Estrella, Órbita, Gravedad | Lluvia de Meteoros, Constelación |
| Mente | Pulso Mental, Distracción, Eco de Pensamiento | Calma, Laberinto |

### Fuente PDF · página 81

#### 50 Nex → Nexum, el Gabinete que Camina · MISTERIO · Eco

- Adaptativo · Objeto animado · gabinete · Torre del Nexo
- **Mezcla mítica:** Gabinete de curiosidades + máquinas místicas de Remedios Varo + escaleras
  imposibles.
- **Atributos:** VID 17→24 · ATQ 17→24 · DEF 17→24 · ESE 17→24 · VEL 17→24
- **Talento · Eco.** En cada combate adopta un elemento neutral frente al rival.
- **Firma · Cajón que Guarda.** Especial · 0 · 2 Savia. Guarda el siguiente especial que reciba (lo
  bloquea).
- **Inventario Imposible.** Golpe Nexo · 3 Savia. Devuelve el último especial que recibió, al 60 %.
- **Aura:** Geometría imposible, damero flotante y cajones desfasados.
- **Huevo:** Huevo del Gabinete: copal con cajoncitos y cerradura; 72 h de incubación.
- **Débil ante:** — · **Resiste:** —
- **Concepto:** La última talla del Tallador: un gabinete de curiosidades que camina, guarda y devuelve.
- **Brote:** Cofre vertical de copal con un solo ojo-cerradura, tres patas distintas (tlacuache, grulla y
  engrane) y un halo de triángulo imposible.
- **Tallado:** El gabinete se abre en abanico de cajones-bioma; por la cerradura se ve una escalera que
  sube y baja a la vez.
- **Claves 2D:** Rectángulo vertical · cajones en abanico · copal, latón y violeta
- **Obtención:** Final del Acto III («La Primera Talla»). Uno por cuenta.
- **Linaje:** —
- **Coste:** 5 (Brote 4) · **Tallado:** nivel 25 · **Incubación:** 72 h

**ECO:** Nexum no tiene repertorio fijo: copia los básicos del elemento neutral que adopta frente al
rival.

### Fuente PDF · página 83 — Cómo funciona la mezcla

El jugador lleva dos monstruos al Criadero, paga una cuota en Monedas y recibe un huevo. Todo lo que
decide el resultado se ve antes de confirmar.

> Padre A (Nv 10+ · Común a Legendario) → Padre B (Nv 10+ · distinto o igual) → Criadero (Cuota en
> Monedas) → Huevo (Especie y rareza decididas) → Incubadora (5 min a 8 h) → Eclosión (Brote con rasgos
> heredados)

**QUÉ DECIDE AL HIJO**

| PASO | REGLA |
|---|---|
| 1 · Especie | Sin receta: 50 % especie del padre A y 50 % del padre B. Con receta de linaje: los padres se reparten el resto y la especie de linaje recibe su porcentaje. |
| 2 · Rareza | La del hijo es la de su especie. La de linaje solo puede subir un nivel si ambos padres comparten la rareza más alta. |
| 3 · Eco elemental | 30 %: aprende un básico del elemento principal del otro padre (si no es su debilidad). |
| 4 · Rasgos | Veta, Temple, Don y Marca de linaje; 1 % de Veta Dorada. |
| 5 · Incubación | Según la rareza del huevo; las Gemas solo acortan el tiempo. |

**REQUISITOS Y COSTES**

| CONCEPTO | VALOR |
|---|---|
| Nivel mínimo de los padres | 10 (Brote o Tallado) |
| Cuota (rareza del padre más raro) | Común 150 · Raro 600 · Épico 2 500 · Legendario 10 000 Monedas |
| Descanso de cada padre | 1 h (Común) a 8 h (Legendario) |
| Únicos, Seres Sagrados y Misterio | No participan |
| Pagos con Gemas | Solo acelerar la incubación; nunca mejorar probabilidades |

**LO QUE NUNCA PASA:** Dos Comunes jamás dan un Épico, un Legendario ni un Único. Un Legendario de linaje
solo sale de dos Épicos (4 %).

**PANTALLA DE MEZCLA:** Antes de pagar se muestran: los resultados posibles con su porcentaje, la
rareza, el tiempo de incubación y los rasgos heredables.

### Fuente PDF · página 84 — Probabilidades por pareja de rarezas

Probabilidad de la rareza del huevo. Cuando el linaje sube un nivel, su porcentaje es bajo; cuando se
queda en la misma rareza, es del 10 %.

| PAREJA | COMÚN | RARO | ÉPICO | LEGENDARIO |
|---|---|---|---|---|
| Común + Común · receta de Raro | 92 % | 8 % | | |
| Común + Común · receta de Común | 100 % | | | |
| Común + Raro · receta de Raro | 45 % | 55 % | | |
| Raro + Raro · receta de Épico | | 94 % | 6 % | |
| Raro + Épico · receta de Épico | | 45 % | 55 % | |
| Épico + Épico · receta de Legendario | | | 96 % | [ilegible en la extracción] |
| Épico + Legendario · receta de Legendario | | | 45 % | 55 % |
| Común + Épico · sin receta posible | 50 % | | 50 % | |
| Común + Legendario · sin receta posible | 50 % | | | 50 % |

Con padres de la misma especie el resultado es esa especie al 100 % (útil para conseguir rasgos).

| PAREJA | LINAJE QUE SUBE UN NIVEL | LINAJE DE LA MISMA RAREZA | REPARTO DE LOS PADRES |
|---|---|---|---|
| Común + Común | Raro · 8 % | Común · 10 % | 46/46 o 45/45 |
| Común + Raro | No existe | Raro · 10 % | 45/45 |
| Raro + Raro | Épico · 6 % | Raro · 10 % | 47/47 o 45/45 |
| Raro + Épico | No existe | Épico · 10 % | 45/45 |
| Épico + Épico | Legendario · 4 % | Épico · 10 % | 48/48 o 45/45 |
| Épico + Legendario | No existe | Legendario · 10 % | 45/45 |
| Cualquier otra | No existe | No existe | 50/50 |

*(Las filas desde «Común + Raro» y los indicadores siguientes están en la p. 29.)*

**0 %** LEGENDARIO DESDE COMUNES · **4 %** LEGENDARIO DESDE 2 ÉPICOS · **1 %** VETA DORADA (COSMÉTICA)

---
## Página 29 · Recetas de linaje, matriz y herencia

*(Empieza con el final de «Probabilidades por pareja de rarezas», transcrito en la p. 28.)*

### Fuente PDF · páginas 85–86 — Recetas de linaje (1/2 y 2/2)

42 recetas escritas a mano. Todo elemento del hijo está en alguno de los padres. Cada Raro, Épico y
Legendario tiene al menos una receta.

| PADRE A | PADRE B | RESULTADO | RAREZA | ELEMENTOS | PROB. | NIVEL |
|---|---|---|---|---|---|---|
| Kuachi Común | Teselo Común | Comalú → Magmadillo | COMÚN | Fuego | 10 % | Igual |
| Teselo Común | Xolumi Común | Barrock → Cantagólem | COMÚN | Tierra | 10 % | Igual |
| Murk Común | Xolumi Común | Bruma → Fatuoscuro | COMÚN | Sombra | 10 % | Igual |
| Zunzi Común | Zizi Común | Brinco → Voltalope | RARO | Aire Rayo | 8 % | Sube |
| Zizi Común | Tinco Común | Chispón → Fulminave | RARO | Rayo Metal | 8 % | Sube |
| Okto Común | Murk Común | Kroa → Corvidúo | RARO | Mente Sombra | 8 % | Sube |
| Pabilo Común | Teselo Común | Lumbro → Faroibex | RARO | Luz | 8 % | Sube |
| Comalú Común | Barrock Común | Picoso → Magmacrán | RARO | Fuego Tierra | 8 % | Sube |
| Zanco Raro | Dientón Raro | Picoso → Magmacrán | RARO | Fuego Tierra | 10 % | Igual |
| Rillip Común | Yek Común | Kunko → Alamar | RARO | Agua Aire | 8 % | Sube |
| Vainas Común | Teselo Común | Dientón → Castorre | RARO | Flora Tierra | 8 % | Sube |
| Xolumi Común | Agavo Común | Cotorro → Lorapiente | RARO | Agua Flora | 8 % | Sube |
| Dientón Raro | Kunko Raro | Cotorro → Lorapiente | RARO | Agua Flora | 10 % | Igual |
| Lunk Común | Bruma Común | Medu → Cometaura | RARO | Astral | 8 % | Sube |
| Cuerdo Común | Tinco Común | Remache → Mechalata | RARO | Artificio Metal | 8 % | Sube |
| Pabilo Común | Bruma Común | Linterno → Farolánima | RARO | Luz Sombra | 8 % | Sube |
| Cuerdo Común | Kuachi Común | Garabato → Monomural | RARO | Artificio | 8 % | Sube |
| Comalú Común | Zunzi Común | Zanco → Grullacandil | RARO | Fuego | 8 % | Sube |
| Okto Común | Cuerdo Común | Ovillo → Aracnógrafa | RARO | Mente Artificio | 8 % | Sube |
| Garabato Raro | Kroa Raro | Ovillo → Aracnógrafa | RARO | Mente Artificio | 10 % | Igual |
| Zanco Raro | Lumbro Raro | Cempa → Cempasol | ÉPICO | Fuego Luz | 6 % | Sube |
| Kunko Raro | Medu Raro | Cenoti → Leviacielo | ÉPICO | Agua Astral | 6 % | Sube |
| Cotorro Raro | Boreal Épico | Cenoti → Leviacielo | ÉPICO | Agua Astral | 10 % | Igual |
| Chispón Raro | Kunko Raro | Pelón → Zopilatón | ÉPICO | Aire Metal | 6 % | Sube |
| Remache Raro | Guaca Épico | Pelón → Zopilatón | ÉPICO | Aire Metal | 10 % | Igual |
| Picoso Raro | Brinco Raro | Chaquiro → Fulgurila | ÉPICO | Tierra Rayo | 6 % | Sube |
| Lumbro Raro | Brinco Raro | Guaca → Aráureo | ÉPICO | Luz Aire | 6 % | Sube |
| Kroa Raro | Linterno Raro | Brujo → Brujalada | ÉPICO | Sombra Mente | 6 % | Sube |
| Ovillo Raro | Hilacho Épico | Brujo → Brujalada | ÉPICO | Sombra Mente | 10 % | Igual |
| Cotorro Raro | Zanco Raro | Tizón → Tizonsierpe | ÉPICO | Fuego Flora | 6 % | Sube |
| Garabato Raro | Kunko Raro | Tuerco → Engrifo | ÉPICO | Aire Artificio | 6 % | Sube |
| Lumbro Raro | Medu Raro | Boreal → Auroribú | ÉPICO | Luz Astral | 6 % | Sube |
| Guaca Épico | Cenoti Épico | Boreal → Auroribú | ÉPICO | Luz Astral | 10 % | Igual |
| Linterno Raro | Remache Raro | Hilacho → Titeránima | ÉPICO | Sombra Artificio | 6 % | Sube |
| Brujo Épico | Tuerco Épico | Hilacho → Titeránima | ÉPICO | Sombra Artificio | 10 % | Igual |
| Guaca Épico | Brujo Épico | Lumbrela → Papalumen | LEGENDARIO | Aire Luz | 4 % | Sube |
| Guaca Épico | Nébulo Legendario | Lumbrela → Papalumen | LEGENDARIO | Aire Luz | 10 % | Igual |
| Chaquiro Épico | Pelón Épico | Geoda → Gemaboa | LEGENDARIO | Tierra Metal | 4 % | Sube |
| Boreal Épico | Tuerco Épico | Nébulo → Astrocorcel | LEGENDARIO | Aire Astral | 4 % | Sube |
| Boreal Épico | Lumbrela Legendario | Nébulo → Astrocorcel | LEGENDARIO | Aire Astral | 10 % | Igual |
| Cenoti Épico | Chaquiro Épico | Bisi → Gemitrueno | LEGENDARIO | Agua Rayo | 4 % | Sube |
| Cempa Épico | Hilacho Épico | Petardo → Pirotoro | LEGENDARIO | Fuego Artificio Luz | 4 % | Sube |

*(Las filas hasta «Zanco + Lumbro → Cempa» son la página 85; el resto, la 86. Las dos últimas filas
están en la columna derecha.)*

### Fuente PDF · página 87 — Matriz completa de combinaciones

Las 47 especies criables dan 1 128 parejas posibles (1 081 de especies distintas + 47 de la misma
especie). Cada celda indica qué regla se aplica; las doradas y turquesas llevan el número de la especie
de linaje.

[Matriz 47 × 47: la columna de cada celda es ilegible en la extracción.] Números de especie de linaje
que aparecen en cada fila (en el orden impreso):

| FILA | NÚMEROS EN LA FILA | FILA | NÚMEROS EN LA FILA | FILA | NÚMEROS EN LA FILA |
|---|---|---|---|---|---|
| 1 | 4 · 30 | 17 | — | 33 | 47 |
| 2 | 6 · 26 · 16 | 18 | — | 34 | 46 · 41 |
| 3 | 25 · 22 | 19 | 37 · 36 | 35 | 44 |
| 4 | 23 · 31 | 20 | 35 | 36 | — |
| 5 | 24 | 21 | 38 · 32 | 37 | 43 · 43 |
| 6 | — | 22 | 41 · 33 | 38 | 42 |
| 7 | — | 23 | — | 39 | — |
| 8 | 19 | 24 | 26 · 34 · 40 | 40 | 45 |
| 9 | — | 25 | 23 | 41 | 45 |
| 10 | — | 26 | 39 · 34 | 42 | — |
| 11 | 20 | 27 | — | 43 | — |
| 12 | 28 | 28 | 42 · 35 | 44 | — |
| 13 | 32 | 29 | — | 45 | — |
| 14 | 21 | 30 | — | 46 | — |
| 15 | — | 31 | — | 47 | — |
| 16 | 29 · 27 | 32 | 38 | | |

Leyenda: Misma especie: 100 % esa especie · Receta que sube un nivel (8 / 6 / 4 %) · Receta de la misma
rareza (10 %) · Sin receta: 50 % cada padre.

Encabezados coloreados por rareza: los números corresponden a la Tabla maestra. Los Únicos (48–49) y
Nexum (50) no aparecen porque no se crían.

### Fuente PDF · página 88 — Herencia y rasgos

La herencia puede pasar uno o ambos elementos de los padres sin crear resultados desproporcionados: el
hijo hereda ataques y apariencia, nunca un tipo nuevo.

| RASGO | PROBABILIDAD | QUÉ HACE | NOTA |
|---|---|---|---|
| Eco elemental | 30 % | Aprende 1 básico del elemento principal del otro padre (si no es su debilidad). No cambia su tipo ni sus debilidades. | Ej.: un Kuachi con Eco de Agua puede equipar «Chorro». |
| Veta | 40 / 40 / 20 % | Color o material: 40 % de cada padre y 20 % una veta nueva del catálogo de la especie. | Solo estética. |
| Temple | 50 / 50 % | +5 % en un atributo y −5 % en otro: 50 % se hereda de un padre, 50 % al azar. | Nunca suma: es un reparto. |
| Don | 25 % | Una pequeña ventaja fuera de combate de uno de los padres (más XP, más Vínculo, recoge más rápido). | No afecta al combate. |
| Marca de linaje | Siempre | Número de generación y nombre de los padres en la ficha. | Cosmética y de orgullo. |
| Veta Dorada | 1 % | Mutación cosmética brillante; 3 % con un Incienso que solo se gana jugando. | No se vende con Gemas. |

*(Desde «Temple» la tabla está en la p. 30.)*

---

## Página 30 · Temples y dones, incubadora y economía

| TEMPLE | EFECTO |
|---|---|
| Ágil | +5 % VEL · −5 % DEF |
| Robusto | +5 % VID · −5 % VEL |
| Feroz | +5 % ATQ · −5 % ESE |
| Sabio | +5 % ESE · −5 % ATQ |
| Firme | +5 % DEF · −5 % ATQ |
| Neutro | Sin cambio |

| DON | EFECTO |
|---|---|
| Glotón | +10 % XP de la comida |
| Leal | +10 % Vínculo |
| Recolector | Recoge Monedas del hábitat 10 % más rápido (no produce más) |
| Madrugador | −10 % tiempo de descanso tras criar |

**SIN DESPROPORCIÓN:** La suma de Temple siempre es cero, el Eco no cambia debilidades y la Veta Dorada
no da atributos: un monstruo criado nunca supera el presupuesto de su rareza.

### Fuente PDF · página 89 — La incubadora flotante

Se mantiene la incubadora y sus tiempos; cambia la presentación: el huevo ya no está metido en la base,
flota sobre un pedestal de copal con anillos que giran y un haz de luz del color de su elemento.

| REPOSO | SUBIDA | CUMBRE | POR ECLOSIONAR |
|---|---|---|---|
| El huevo flota y respira | Sube 8 px y gira −6° | 12 px; brillan los anillos | Grietas de luz a 5 min |

**TIEMPOS (SIN CAMBIOS)**

| RAREZA | INCUBACIÓN | GEMAS PARA ACABAR YA |
|---|---|---|
| COMÚN | 5 min | 2 |
| RARO | 20 min | 5 |
| ÉPICO | 2 h | 21 |
| LEGENDARIO | 8 h | 57 |
| ÚNICO | 24 h | 153 |
| MISTERIO | 72 h | 441 |

**ANIMACIÓN:** Ciclo de 3 s: subida suave (ease-in-out) de 12 px y regreso. Anillo dorado y anillo del
elemento giran en sentidos opuestos (8 s por vuelta). Destellos orbitando; a 25 %, 50 % y 75 % del
tiempo aparece una grieta de luz. Al eclosionar: el huevo sube, se abre en espiral de virutas y aparece
la carta del Brote.

**RAREZA VISIBLE:** El haz y los anillos usan el color del elemento; desde Épico el huevo propio de la
especie ya muestra su diseño.

**CUMPLIMIENTO:** La especie y los rasgos se deciden al obtener el huevo, no al eclosionar. Así acelerar
con Gemas nunca es pagar por un resultado aleatorio.

### Fuente PDF · página 91 — Monedas y Gemas en la v5

Se mantiene la economía de la v4 con un cambio pedido en tus notas: el pase mensual ahora también da
Monedas. Eso tiene una consecuencia de cumplimiento que conviene ver con calma.

| MONEDAS · Recurso habitual | GEMAS · Moneda premium |
|---|---|
| Victorias, cofres, hábitats, encargos e historia. Nuevo: también el pase mensual (9 800 al mes). | Paquetes de Robux, pase mensual y logros. |
| Se gastan en comida, accesorios básicos, huevos de la Vitrina, lotes, mejoras, mezcla y cofres Madera, Plata y Oro. | Acelerar huevos, comprar cofres, potenciadores de XP y Vínculo, accesorios premium. Huevos de la Vitrina (Épico y Legendario de especie visible). |
| Nunca se venden directamente por Robux ni se convierten desde Gemas. | Nunca mejoran probabilidades. |

**LA CONSECUENCIA:** Roblox considera «pagada» una moneda que se puede conseguir con Robux, incluida una
suscripción. Si el pase da Monedas, todo lo aleatorio que se compra con Monedas (cofres de Madera, Plata
y Oro y la cuota de la mezcla) pasa a ser Paid Random Item: probabilidades visibles y PolicyService.

**TRES CAMINOS POSIBLES**

| OPCIÓN | QUÉ IMPLICA | VENTAJA | COSTO |
|---|---|---|---|
| A · Monedas en el pase (v5 por defecto) | Cofres de Monedas y mezcla con probabilidades visibles; para usuarios restringidos, cofres solo ganados y mezcla sin cuota | Cumple tu nota tal cual | Brasil, Reino Unido (<18), Australia, Bélgica y Países Bajos pierden la compra de cofres con Monedas |
| B · Pase sin Monedas (v4) | El pase da Gemas, cofres de contenido fijo y comida | Cofres de Monedas fuera de la regulación | El pase luce menos generoso |
| C · Tercera moneda ganada jugando | Una «Esencia» que solo se gana abre lo aleatorio | La separación más limpia para niños | Añade complejidad |

**PREGUNTA CLAVE:** Elige A, B o C en la sección de preguntas. La v5 aplica A porque es lo que pediste.

### Fuente PDF · página 92 — Fuentes de Monedas

Tres fuentes principales: victorias, cofres y la generación automática de cada monstruo en su hábitat.

**GENERACIÓN POR MONSTRUO**

| RAREZA | MONEDAS POR HORA |
|---|---|
| Común | 30 |
| Raro | 45 |
| Épico | 60 |
| Legendario | 90 |
| Único / Ser Sagrado | 120 |
| Misterio | 120 |

Los Brotes producen el 50 % hasta tallarse. Cada hábitat aloja 4 monstruos.

**NIVEL DEL HÁBITAT**

| NIVEL | MULTIPLICADOR | MEJORA |
|---|---|---|
| 1 | ×1 | — |
| 2 | ×1,2 | 1 500 |
| 3 | ×1,4 | 6 000 |
| 4 | ×1,7 | 20 000 |
| 5 | ×2 | 60 000 |

Fuera de línea se acumula hasta 8 h. El pase no amplía este tope.

**OTRAS FUENTES**

| FUENTE | MONEDAS |
|---|---|
| Victoria 1v1 o 2v2 | 40–180 según división |
| Derrota | 25 % de la victoria |
| Encargo diario (3) | 150–250 cada uno |
| Encargo semanal | 1 500 + Cofre de Plata |
| Capítulo de historia | 1 000–5 000 |
| Cofre de Madera / Plata | 60–120 / 200–350 + premio |

**INGRESO DIARIO ESTIMADO DE UN JUGADOR SIN PAGAR** (barras: Hábitats · Victorias · Encargos · Cofres)

| MOMENTO | MONEDAS AL DÍA |
|---|---|
| Día 1 | 1 600 |
| Semana 1 | 5 200 |
| Mes 1 | 11 900 |
| Mes 3 | 20 600 |

Modelo: 1 h de juego al día y recogida tras 8 h fuera de línea. Día 1: 1 hábitat con 2 Comunes · Semana
1: 2 hábitats · Mes 1: 4 hábitats (incluye Épicos) · Mes 3: 5 hábitats nivel 4 con 2 Legendarios.

### Fuente PDF · página 93 — Precios en Monedas

Lo que se compra jugando. Los huevos de la Vitrina muestran la especie: no hay sorpresa.

| CATEGORÍA | ARTÍCULO | PRECIO (MONEDAS) | NOTA |
|---|---|---|---|
| Alimento | Ración básica | 50 | +150 XP |
| Alimento | Ración de bioma | 220 | +600 XP · +1 Vínculo |
| Alimento | Festín | 900 | +2 500 XP · +1 Vínculo |
| Accesorio | Básico (sombrero, listón, collar) | 800 – 6 000 | Cosmético |
| Huevo fijo | Común (3 especies al día) | 1 200 | Especie visible antes de comprar |
| Huevo fijo | Raro (2 especies al día, máx. 2) | 9 000 | Especie visible antes de comprar |
| Huevo fijo | Épico (1 especie por semana, máx. 1) | 60 000 | Especie visible antes de comprar |
| Huevo fijo | Legendario (1 por semana, máx. 1) | 1 500 000 | Dificultad extrema a propósito |
| Mezcla | Cuota de crianza | 150 / 600 / 2 500 / 10 000 | Según la rareza del padre más raro |
| Hábitat | Mejora de nivel 2 a 5 | 1 500 – 60 000 | ×1,2 a ×2,0 de producción |
| Cofre | Madera / Plata / Oro | 500 / 2 000 / 7 500 | Probabilidades visibles |
| Ranura | 3.ª incubadora | 25 000 | Permanente |

**LOTES** *(la tabla continúa en la p. 31)*

| LOTE | PRECIO | REQUISITO |
|---|---|---|
| Lote Hogar | Gratis | Inicio |
| Lote del Valle | 2 500 Monedas | Capítulo 1 |
| Lote de la Marea | 10 000 Monedas | Acto I completo |
| Lote de la Cumbre | 40 000 Monedas | Acto II completo |
| Lote del Fulgor | 150 000 Monedas | Acto III completo |
| Lote del Velo | 300 000 Monedas | Acto IV completo |
| Lote de Exhibición | 600 Gemas o 400 000 Monedas | Nivel de cuenta 20 |

**COMIDA:** Ración básica · Ración de bioma · Festín (ilustraciones).

**LEGENDARIO CON MONEDAS:** 1 500 000 Monedas: con el ingreso del mes 3 (≈ 20 000 al día) son unos 75
días. Es extremadamente difícil a propósito; con Gemas cuesta 2 200.

---

## Página 31 · Gemas, Robux y pase mensual

### Fuente PDF · página 94 — Precios en Gemas

Las Gemas aceleran, decoran y compran cofres. Ningún artículo de Gemas produce Monedas ni mejora
probabilidades.

| CATEGORÍA | ARTÍCULO | GEMAS | NOTA |
|---|---|---|---|
| Aceleración | Incubación (ver tabla) | 2 – 441 | Solo acorta el tiempo |
| Cofre | Oro / Épico / Diamante / Nexo | 90 / 220 / 450 / 1 200 | Paid Random Item: probabilidades + PolicyService |
| Huevo fijo | Épico de la Vitrina | 350 | Especie visible; máx. 3 por semana |
| Huevo fijo | Legendario de la Vitrina | 2 200 | Especie visible; máx. 1 por semana |
| Potenciador | XP ×2 · 30 min | 40 | No toca Monedas ni probabilidades |
| Potenciador | Vínculo ×2 · 1 h | 50 | No toca Monedas ni probabilidades |
| Alimento | Ración Dorada | 30 | +4 000 XP · +2 Vínculo |
| Accesorio | Premium (alas de papel, máscaras, estelas) | 150 – 900 | Cosmético |
| Ranura | 4.ª incubadora | 400 | Permanente |
| Lote | Exhibición | 600 | Decorativa: no produce Monedas |
| Cosmético | Cambio de Veta (color) de un monstruo | 250 | Elegido por el jugador |

**ACELERAR INCUBACIÓN (DESDE CERO)**

| RAREZA | INCUBACIÓN | GEMAS |
|---|---|---|
| Común | 5 min | 2 |
| Raro | 20 min | 5 |
| Épico | 2 h | 21 |
| Legendario | 8 h | 57 |
| Único | 24 h | 153 |
| Misterio | 72 h | 441 |

**EQUIVALENCIAS**

| REFERENCIA | VALOR |
|---|---|
| 1 Gema (paquete pequeño) | 0,80 R$ |
| 1 Gema (paquete grande) | 0,65 R$ |
| Cofre Diamante (450) | ≈ 330 R$ |
| Huevo Legendario fijo (2 200) | ≈ 1 500 R$ |
| Cofre Nexo (1 200) | ≈ 830 R$ |

**CALIBRACIÓN:** Precios de referencia de juegos de criaturas en Roblox (2026): VIP 400–640 R$,
suscripción 299 R$/mes, huevos exclusivos 120–240 R$ cada uno. NEXORA queda en la franja media.

### Fuente PDF · página 95 — Compra de Robux

Seis paquetes de Gemas como productos de desarrollador, con precio regional activado. El desarrollador
conserva el 70 % de cada compra.

| GEMAS | PRECIO | BONO | NETO AL DESARROLLADOR |
|---|---|---|---|
| 100 | 80 R$ | — | 56 R$ · ≈ 0,21 USD |
| 260 | 200 R$ | +4 % | 140 R$ · ≈ 0,53 USD |
| 550 | 400 R$ | +10 % | 280 R$ · ≈ 1,06 USD |
| 1 150 | 800 R$ | +15 % | 560 R$ · ≈ 2,13 USD |
| 2 500 | 1 700 R$ | +18 % | 1 190 R$ · ≈ 4,52 USD |
| 6 200 | 4 000 R$ | +24 % | 2 800 R$ · ≈ 10,64 USD |

*(Las tarjetas de paquetes salen intercaladas en la extracción; la tabla las reordena por paquete.)*

**OFERTAS**

| PRODUCTO | PRECIO | CONTENIDO |
|---|---|---|
| Paquete de bienvenida (1 vez) | 149 R$ | 300 Gemas, 1 accesorio «Rebozo del Tallador», 3 Raciones de bioma |
| Primera compra de cada paquete | — | +50 % de Gemas una sola vez |
| Pase mensual Círculo del Tallador | 499 R$ / mes | Ver página siguiente |

**LO QUE LLEGA AL DESARROLLADOR**

| CONCEPTO | VALOR |
|---|---|
| Comisión | 70 % del precio en Robux |
| DevEx (Robux ganados) | 0,0038 USD por Robux |
| Retiro mínimo | 30 000 R$ (≈ 114 USD) |
| Pase mensual 499 R$ | 349 R$ ≈ 1,33 USD por suscriptor al mes |
| Precio regional | Activado: cada país ve su precio |

**SIN PASE DE TEMPORADA:** Se descarta el pase de temporada adicional: el pase mensual cubre esa función
y evita dos suscripciones para un público joven.

**CUMPLIMIENTO:** Los paquetes de Gemas son contenido fijo (no aleatorio). Lo aleatorio aparece al gastar
Gemas en cofres, y ahí se aplican las reglas de Paid Random Items.

### Fuente PDF · página 96 — Pase mensual · Círculo del Tallador (1/2)

Treinta días que alternan Monedas, Gemas, cofres de Plata y Oro y comida. No todos los días dan Gemas:
así cada día se siente distinto y el valor no depende de una sola moneda.

| DÍA 1 | DÍA 2 | DÍA 3 | DÍA 4 | DÍA 5 | DÍA 6 |
|---|---|---|---|---|---|
| 120 Gemas | 600 Monedas | Cofre de Plata del Círculo | 600 Monedas | 30 Gemas | Ración Dorada |
| **DÍA 7** | **DÍA 8** | **DÍA 9** | **DÍA 10** | **DÍA 11** | **DÍA 12** |
| Cofre de Oro del Círculo | 700 Monedas | Cofre de Plata del Círculo | 700 Monedas | 40 Gemas | 800 Monedas |
| **DÍA 13** | **DÍA 14** | **DÍA 15** | **DÍA 16** | **DÍA 17** | **DÍA 18** |
| Cofre de Plata del Círculo | Cofre de Oro del Círculo | 40 Gemas | 800 Monedas | Cofre de Plata del Círculo | 900 Monedas |
| **DÍA 19** | **DÍA 20** | **DÍA 21** | **DÍA 22** | **DÍA 23** | **DÍA 24** |
| Ración Dorada | 50 Gemas | Cofre de Oro del Círculo | 900 Monedas | Cofre de Plata del Círculo | 1 000 Monedas |
| **DÍA 25** | **DÍA 26** | **DÍA 27** | **DÍA 28** | **DÍA 29** | **DÍA 30** |
| 50 Gemas | 1 000 Monedas | Cofre de Plata del Círculo | Cofre de Oro del Círculo | Ración Dorada | Recompensa del mes |

Monedas · 10 días · Gemas · 6 días · Cofre de Plata del Círculo · 6 días · Cofre de Oro del Círculo · 4
días · Ración Dorada · 3 días · Recompensa final · 1 días

| 9 800 | 330 | 10 |
|---|---|---|
| MONEDAS AL MES · incluye las de los cofres de Plata | GEMAS AL MES · en 6 días | COFRES DE CONTENIDO FIJO · 6 de Plata y 4 de Oro |

| COFRE DEL CÍRCULO | CONTENIDO FIJO (VISIBLE EN EL CALENDARIO) |
|---|---|
| Plata · días 3, 9, 13, 17, 23, 27 | 2 Raciones de bioma + 1 accesorio básico + 300 Monedas |
| Oro · días 7, 14, 21, 28 | 1 Huevo Raro de la especie del mes (rasgos fijos) + 1 Festín |
| Día 30 | Huevo Épico a elegir entre 3 especies (rasgos fijos) + aura cosmética del mes |

### Fuente PDF · página 97 — Pase mensual · Círculo del Tallador (2/2)

Precio dentro de tu rango de US$5 a US$10 y opciones para la recompensa final.

| PRECIO | 399 R$ | 499 R$ | 799 R$ |
|---|---|---|---|
| Equivale a | ≈ US$5 | ≈ US$6 | ≈ US$10 |
| Neto al desarrollador | 279 R$ ≈ US$ 1,06 al mes | 349 R$ ≈ US$ 1,33 al mes | 559 R$ ≈ US$ 2,13 al mes |
| | | Por defecto | |

Las suscripciones de Roblox se pagan en Robux, con precio regional automático. Referencia: Pets Plus de
Adopt Me! cuesta 299 R$ al mes. Los Robux se compran a ≈ US$0,0125 en paquetes pequeños.

**RECOMPENSA FINAL**

| OPCIÓN | QUÉ DA | LECTURA |
|---|---|---|
| A · Épico elegido cada mes | Huevo Épico (3 especies a elegir) + aura del mes | Generoso y sostenible |
| B · Legendario cada mes | Huevo Legendario fijo del mes | Muy atractivo, pero devalúa a los Legendarios (5 especies) |
| C · Épico + racha (recomendada) | Épico elegido cada mes y, a los 3 meses seguidos, un Legendario a elegir | Premia la constancia sin regalar Legendarios |

**VENTAJAS MIENTRAS ESTÁ ACTIVO**

- +1 ranura de incubadora mientras esté activo
- +1 aceleración gratuita diaria (30 min)
- +10 % de XP en combates y entrenamiento
- Nombre y marco dorados en la arena
- Racha del Círculo: 3 meses seguidos = Huevo Legendario a elegir (rasgos fijos)

**CONTENIDO FIJO = SIN PAID RANDOM ITEM:** Todo lo que trae el pase está decidido y se ve en el
calendario: los cofres del Círculo no son aleatorios. Así la suscripción se puede vender igual en todos
los países.

**POR VALIDAR:** Prueba A/B de precio en el soft launch; meta: 4–6 % de suscriptores entre jugadores
activos a 30 días.

### Fuente PDF · página 98 — Ritmo de progreso *(continúa en la p. 32)*

Cuánto tarda cada meta según el perfil. El que paga llega antes, pero el que no paga llega.

| META | SIN PAGAR (1 H/DÍA) | CON PASE MENSUAL | CON COMPRAS DE GEMAS |
|---|---|---|---|
| Lote del Valle (2 500 Monedas) | Día 1–2 | Día 1 | Día 1 |
| Primer Tallado de un inicial (nivel 12) | Día 2 | Día 2 | Día 1–2 |
| Primer huevo Épico (cofre o Vitrina 60 000) | Semana 2–3 | Día 21 (cofre) o 28 (huevo elegido) | Inmediato (350 Gemas) |
| Primer Golpe Nexo (nivel 20) | Día 6–8 | Día 5–7 (+10 % XP) | Día 4–6 (potenciadores) |
| Primer Legendario | Mes 2–4 (cofres, linaje o 1,5 M) | Mes 2–3 | Inmediato (2 200 Gemas) o cofres |
| Primer Único | Acto III de la historia | Igual | Cofre Nexo (1 200 Gemas) |
| Nexum | Final de la historia | Igual | Igual: no se vende |

| ≈ 26 850 | ≈ 11 900 | 5–7 % |
|---|---|---|
| XP HASTA NIVEL 20 · 40 × L^1,5 por nivel | MONEDAS AL DÍA (MES 1) · sin pagar | META DE CONVERSIÓN · jugadores que compran algo |

**MURO DE DIVERSIÓN:** Ninguna meta de la tabla exige pagar. Lo único exclusivo del pago es cosmético
(auras del mes, accesorios premium) o de tiempo.

---

## Página 32 · Cumplimiento y cofres

### Fuente PDF · página 99 — Cumplimiento en Roblox (v5)

Actualizado con el informe de validación del 2 de noviembre de 2026: política de Paid Random Items
vigente desde el 26 de mayo de 2026, sin cambios posteriores.

| PRODUCTO | ¿ALEATORIO? | ¿PAID RANDOM ITEM? | QUÉ EXIGE EN NEXORA |
|---|---|---|---|
| Paquetes de Gemas | No | No | Contenido fijo |
| Pase mensual (contenido fijo, con Monedas) | No | No | Mismo pase para todos los países |
| Cofres Oro, Épico, Diamante y Nexo con Gemas | Sí | Sí | Probabilidades por premio y por especie · PolicyService · alternativa |
| Cofres Madera, Plata y Oro con Monedas | Sí | Sí (v5) | Monedas ahora salen también del pase: probabilidades + PolicyService; restringidos solo ganan cofres |
| Cofres ganados (arena, historia, encargos) | Sí | No | Se abren gratis; nunca con Gemas |
| Huevos de la Vitrina | No | No | Especie y rasgos fijos, visibles |
| Acelerar incubación | No | No | El resultado ya está decidido |
| Mezcla con cuota en Monedas | Sí | Sí (v5) | Probabilidades visibles; restringidos: mezcla sin cuota |
| Potenciadores de XP y Vínculo | No | No | No tocan probabilidades |
| Cofre Nexo con protección de repetidos | Sí | Sí | Contador visible y tabla recalculada por jugador |

**MERCADOS RESTRINGIDOS:** Australia, Bélgica, Países Bajos, Reino Unido (menores de 18) y Brasil
(menores de 18 desde el 17 de marzo de 2026 y adultos sin verificar desde el 31 de marzo). Nunca se
codifican países: se consulta ArePaidRandomItemsRestricted.

**DIVULGACIÓN:** Porcentaje de cada resultado final (también por especie) antes de comprar, suma 100 %,
botón con la palabra «Detalles» (no solo un ícono) y probabilidades que se actualizan con la colección
del jugador.

**ALTERNATIVA PARA RESTRINGIDOS:** Cofres solo ganados, Vitrina de huevos fijos, mezcla sin cuota y el
mismo pase. Nadie queda sin forma de progresar.

**INTERCAMBIO:** IsPaidItemTradingAllowed restringe el intercambio de todo lo pagado. Si llega el
intercambio en la fase 2, cada monstruo debe guardar si vino de una compra.

### Fuente PDF · página 101 — Los seis cofres

Madera, Plata, Oro, Épico, Diamante y Nexo. Las victorias dan sobre todo cofres de Madera y Plata; los
de mayor rareza llegan en divisiones altas o con Gemas.

| COFRE | PRECIO | CÓMO SE CONSIGUE | MONEDAS |
|---|---|---|---|
| Madera | 500 Monedas | Victorias (Esbozo a Obra Maestra) · encargos diarios · 500 Monedas | Contiene Monedas |
| Plata | 2 000 Monedas | Victorias desde Esbozo · encargos semanales · 2 000 Monedas | Contiene Monedas |
| Oro | 7 500 Monedas o 90 Gemas | Victorias desde Gubia · historia · 7 500 Monedas o 90 Gemas | Sin Monedas |
| Épico | 220 Gemas | Victorias desde Relieve · eventos · 220 Gemas | Sin Monedas |
| Diamante | 450 Gemas | Victorias desde Filigrana · eventos · 450 Gemas | Sin Monedas |
| Nexo | 1 200 Gemas | Hitos de historia · grandes objetivos · 1 200 Gemas | Sin Monedas |

**PROBABILIDAD DE HUEVO POR COFRE** (barras Común · Raro · Épico · Legendario · Otros premios (comida,
accesorios, Monedas); solo se transcriben los rótulos legibles; los segmentos pequeños no tienen
rótulo en la extracción, ver «Probabilidades detalladas»):

| COFRE | RÓTULOS LEGIBLES |
|---|---|
| Madera | 30 % · 63.5 % |
| Plata | 35 % · 24 % · 36 % |
| Oro | 12 % · 55 % · 15 % · 15 % |
| Épico | 30 % · 58 % · 9 % |
| Diamante | 62 % · 30 % |

**PLATINO ELIMINADO:** Era redundante entre Oro y Diamante. Su hueco lo ocupa el Cofre Épico, que asegura
58 % de huevo Épico.

**LEGENDARIO EN EL COFRE BÁSICO:** El Cofre de Madera puede dar un huevo Legendario con probabilidad de 1
entre 2 000 (0,05 %). Es la «leyenda del patio»: posible, pero excepcional.

### Fuente PDF · página 102 — Cambios de probabilidad v4 → v5

Aplicados según tus notas: más huevos en los cofres básicos y menos comida y accesorios. Todas las
tablas siguen sumando 100 %.

| COFRE | PREMIO | V4 | V5 | CAMBIO |
|---|---|---|---|---|
| Madera | 2 Raciones básicas | 44 % | 27,5 % | ▼ 16,5 |
| Madera | Accesorio básico | 25 % | 18 % | ▼ 7 |
| Madera | +250 Monedas | 16 % | 18 % | ▲ 2 |
| Madera | Huevo Común | 13,5 % | 30 % | ▲ 16,5 |
| Madera | Huevo Raro | 1 % | 6 % | ▲ 5 |
| Madera | Huevo Épico | 0,45 % | 0,45 % | = 0 |
| Madera | Huevo Legendario | 0,05 % | 0,05 % | = 0 |
| Plata | Ración de bioma | 24 % | 18 % | ▼ 6 |
| Plata | Accesorio básico | 26 % | 18 % | ▼ 8 |
| Plata | Huevo Común | 30 % | 35 % | ▲ 5 |
| Plata | Huevo Raro | 17 % | 24 % | ▲ 7 |
| Plata | Huevo Épico | 2,8 % | 4,5 % | ▲ 1,7 |
| Plata | Huevo Legendario | 0,2 % | 0,5 % | ▲ 0,3 |
| Oro | Accesorio raro | 22 % | 15 % | ▼ 7 |
| Oro | Huevo Común | 18 % | 12 % | ▼ 6 |
| Oro | Huevo Raro | 45 % | 55 % | ▲ 10 |
| Oro | Huevo Épico | 13,5 % | 15 % | ▲ 1,5 |
| Oro | Huevo Legendario | 1,5 % | 3 % | ▲ 1,5 |
| Épico | Huevo Raro | 38 % | 30 % | ▼ 8 |
| Épico | Huevo Épico | 52 % | 58 % | ▲ 6 |
| Épico | Huevo Legendario | 7 % | 9 % | ▲ 2 |
| Épico | Accesorio épico con aura | 3 % | 3 % | = 0 |
| Diamante | Huevo Épico | 68 % | 62 % | ▼ 6 |
| Diamante | Huevo Legendario | 27 % | 30 % | ▲ 3 |
| Diamante | Accesorio legendario con aura dorada | 5 % | 8 % | ▲ 3 |

**DIAMANTE:** Tus notas mencionan una distribución específica para Diamante que no venía detallada. La v5
propone Épico 62 % · Legendario 30 % · accesorio legendario 8 %. Confírmala en las preguntas.

### Fuente PDF · páginas 103–104 — Probabilidades detalladas (1/2 y 2/2)

Cada cofre entrega un premio garantizado y un premio principal. Las probabilidades del premio principal
suman 100 % y se muestran, también por especie, antes de abrir o comprar.

**Madera · 500 Monedas** — Garantizado: 60–120 Monedas

| PREMIO PRINCIPAL | % | POR ESPECIE | EQUIVALE A |
|---|---|---|---|
| 2 Raciones básicas | 27,5 % | | |
| Accesorio básico | 18 % | | |
| +250 Monedas | 18 % | | |
| Huevo Común | 30 % | 1,67 % c/u (18 especies) | |
| Huevo Raro | 6 % | 0,429 % c/u (14 especies) | |
| Huevo Épico | 0,45 % | 0,045 % c/u (10 especies) | 1 en 222 |
| Huevo Legendario | 0,05 % | 0,01 % c/u (5 especies) | 1 en 2 000 |

**Plata · 2 000 Monedas** — Garantizado: 200–350 Monedas y 1 Ración básica

| PREMIO PRINCIPAL | % | POR ESPECIE | EQUIVALE A |
|---|---|---|---|
| Ración de bioma | 18 % | | |
| Accesorio básico | 18 % | | |
| Huevo Común | 35 % | 1,94 % c/u (18 especies) | |
| Huevo Raro | 24 % | 1,71 % c/u (14 especies) | |
| Huevo Épico | 4,5 % | 0,45 % c/u (10 especies) | 1 en 22 |
| Huevo Legendario | 0,5 % | 0,1 % c/u (5 especies) | 1 en 200 |

**Oro · 7 500 Monedas o 90 Gemas** — Garantizado: 2 Raciones de bioma

| PREMIO PRINCIPAL | % | POR ESPECIE | EQUIVALE A |
|---|---|---|---|
| Accesorio raro | 15 % | | |
| Huevo Común | 12 % | 0,667 % c/u (18 especies) | |
| Huevo Raro | 55 % | 3,93 % c/u (14 especies) | |
| Huevo Épico | 15 % | 1,5 % c/u (10 especies) | |
| Huevo Legendario | 3 % | 0,6 % c/u (5 especies) | 1 en 33 |

**Épico · 220 Gemas** — Garantizado: 1 Festín y 1 accesorio básico *(p. 33)*

| PREMIO PRINCIPAL | % | POR ESPECIE | EQUIVALE A |
|---|---|---|---|
| Huevo Raro | 30 % | 2,14 % c/u (14 especies) | |
| Huevo Épico | 58 % | 5,8 % c/u (10 especies) | |
| Huevo Legendario | 9 % | 1,8 % c/u (5 especies) | |
| Accesorio épico con aura | 3 % | | 1 en 33 |

**Diamante · 450 Gemas** — Garantizado: 1 accesorio raro y 1 Ración Dorada *(p. 33)*

| PREMIO PRINCIPAL | % | POR ESPECIE | EQUIVALE A |
|---|---|---|---|
| Huevo Épico | 62 % | 6,2 % c/u (10 especies) | |
| Huevo Legendario | 30 % | 6 % c/u (5 especies) | |
| Accesorio legendario con aura dorada | 8 % | | |

**ESPECIE DENTRO DEL HUEVO:** Un «huevo Raro» de cofre es uno de los 14 Raros con la misma probabilidad.
Los iniciales entran al grupo de Comunes después de la introducción. Los rasgos del huevo de cofre sí
son aleatorios (Veta, Temple, Don) y se muestran sus probabilidades.

**ACCESORIOS CON AURA:** Los accesorios épicos y legendarios son cosméticos: añaden un aura visual a
cualquier monstruo sin cambiar atributos.

---
## Página 33 · Recompensas por victoria, Cofre Nexo, bucle e introducción

*(Empieza con el final de «Probabilidades detalladas», transcrito en la p. 32.)*

### Fuente PDF · página 105 — Recompensas por victoria

Cada victoria da Monedas y un cofre. El tipo de cofre depende de la división: las divisiones superiores
otorgan cofres diferentes.

| DIVISIÓN | MONEDAS | MADERA | PLATA | ORO | ÉPICO | DIAMANTE | LEGENDARIO POR VICTORIA |
|---|---|---|---|---|---|---|---|
| ESBOZO | 40 | 92 % | 8 % | 0 % | 0 % | 0 % | 1 en 1 163 |
| GUBIA | 60 | 75 % | 22 % | 3 % | 0 % | 0 % | 1 en 421 |
| RELIEVE | 80 | 55 % | 35 % | 9 % | 1 % | 0 % | 1 en 178 |
| FILIGRANA | 110 | 35 % | 40 % | 20 % | 4,5 % | 0,5 % | 1 en 73 |
| OBRA MAESTRA | 140 | 20 % | 40 % | 28 % | 10 % | 2 % | 1 en 39 |
| NEXO ETERNO | 180 | 0 % | 35 % | 40 % | 20 % | 5 % | 1 en 21 |

**OTRAS RECOMPENSAS**

| LOGRO | COFRE |
|---|---|
| Encargo diario completo | Madera |
| Encargo semanal | Plata |
| Capítulo de historia | Oro |
| Restaurar un Ser Sagrado | Nexo |
| Ascenso de división (primera vez) | Épico |
| Fin de temporada (8 semanas) | Según división: Plata a Diamante |

**TOPE Y RACHAS:** 8 cofres de victoria al día. Una racha de 3 victorias mejora el siguiente cofre un
nivel (máximo Oro).

**POR VALIDAR:** Meta del modelo: un jugador de Relieve que juega 1 h al día consigue un huevo Épico cada
6–8 días solo con victorias.

### Fuente PDF · página 106 — Cofre Nexo

Reservado para los Únicos: Eclipsor, Aetherion y los seis Seres Sagrados restaurados. Se gana en la
historia y en grandes objetivos, o se compra con 1 200 Gemas.

| ÚNICO | CUÁNDO ENTRA AL COFRE |
|---|---|
| Eclipsor | Catálogo |
| Aetherion | Catálogo |
| Copalia | Tras restaurarlo (Acto I) |
| Marejadra | Tras restaurarlo (Acto II) |
| Obsidárion | Tras restaurarlo (Acto III) |
| Fulgorón | Tras restaurarlo (Acto IV) |
| Noctelia | Tras restaurarlo (Acto V) |
| Ánima del Nexo | Tras restaurarlo (Final) |

**PROBABILIDADES SEGÚN TU COLECCIÓN**

| SITUACIÓN | PROBABILIDAD DE CADA UNO |
|---|---|
| Inicio (2 Únicos) | 50 % |
| Tras el Acto I (3) | 33,3 % |
| Tras el Acto II (4) | 25 % |
| Tras el Acto III (5) | 20 % |
| Tras el Acto IV (6) | 16,7 % |
| Tras el Acto V (7) | 14,3 % |
| Tras el Final (8) | 12,5 % |
| Te falta solo uno | 100 % ese |
| Ya los tienes todos | No se puede comprar |

**UNA COPIA POR CUENTA:** La probabilidad se reparte solo entre los que te faltan y se recalcula en
pantalla para cada jugador, como exige Roblox.

**PAID RANDOM ITEM:** Comprado con Gemas: probabilidades visibles, PolicyService y alternativa (los
Cofres Nexo ganados siguen para todos).

**CÓMO SE GANA:** 1 por cada Ser Sagrado restaurado (6), 1 por completar todos los encargos de un acto y
1 al llegar a Nexo Eterno.

### Fuente PDF · página 108 — Bucle de juego

Los monstruos pueden competir antes y después de tallarse; cada paso del bucle alimenta a los demás.

| PASO | QUÉ HACE | QUÉ DA |
|---|---|---|
| Eclosionar | Huevos de cofres, Vitrina o mezcla en la incubadora. | Nuevo monstruo |
| Cuidar | Alimentar y jugar: sube XP y Vínculo. | Tallado y Talento |
| Entrenar | El hábitat entrena y produce Monedas. | Monedas y XP pasiva |
| Explorar | Capítulos de aventura y Opacos. | Cofres de Oro y Nexo |
| Competir | Arenas 1v1 y 2v2. | Monedas, cofres y división |
| Criar | Mezclar dos monstruos. | Linajes y rasgos |

Diagrama circular: Eclosionar · Cuidar · Santuario (produce Monedas) · Entrenar · Explorar · Competir ·
Criar.

| SESIÓN CORTA · 5 MIN | SESIÓN MEDIA · 20 MIN | SESIÓN LARGA · 60 MIN |
|---|---|---|
| Recoger Monedas, alimentar, poner un huevo a incubar y abrir los cofres de la repisa. | 2 o 3 partidas de arena, un encargo y una mezcla. | Un capítulo de aventura, ascenso de división y evento de bioma. |

### Fuente PDF · página 109 — Introducción animada

Un minuto para atrapar: del sueño del Tallador a la elección del primer huevo. Se puede saltar tras
verla una vez; la versión corta para anuncios dura 15 s (planos 1, 3, 4 y 8).

| PLANO | TIEMPO | IMAGEN | SONIDO |
|---|---|---|---|
| 1 | 0:00–0:06 | Negro. Una gubia talla una espiral de copal que se enciende. | Sonido de madera y un latido. |
| 2 | 0:06–0:12 | La viruta se vuelve luz y dibuja Brotes que corren por el aire. | Flauta y percusión suave. |
| 3 | 0:12–0:20 | Plano general: el Gran Nexo y los cinco biomas como un mapa vivo. | La música crece. |
| 4 | 0:20–0:27 | El Opacamiento: una niebla gris apaga colores; Gemitrueno se vuelve gris en pleno vuelo. | Silencio y viento. |
| 5 | 0:27–0:34 | Los Seres Sagrados se apagan uno por uno: seis siluetas en el horizonte. | Seis golpes graves. |
| 6 | 0:34–0:42 | Lluvia de huevos de luz que caen como semillas sobre el Valle. | Campanas y arpa. |
| 7 | 0:42–0:52 | Un huevo llega al santuario del jugador y se divide en tres huevos idénticos que laten. | El latido vuelve. |
| 8 | 0:52–1:00 | Título NEXORA y el lema; corte a la elección del huevo. | Golpe final y tema principal. |

*(Las columnas «PLANO», «IMAGEN» y «SONIDO» son de esta transcripción; en el PDF cada plano es una
tarjeta con el tiempo, la imagen y el sonido.)*

| ESTILO | DURACIÓN | PRODUCCIÓN |
|---|---|---|
| Animación 2D de recortes con luz de copal y cámara lenta; los monstruos son las cartas animadas del juego. | 60 s máximo, sin texto en pantalla salvo el título. Todo se entiende sin palabras para el público global. | Storyboard → animática con sonido → animación final. Reutilizar las ilustraciones 2D aprobadas de las especies. |

### Fuente PDF · página 110 — Los primeros 15 minutos *(continúa en la p. 34)*

El sueño del Tallador, el huevo que llega al santuario, la elección entre tres huevos idénticos y el Lote
Hogar. Cada sistema se explica cuando el jugador lo necesita.

1. **El sueño** · Cinemática de copal: el Tallador talla y las virutas se vuelven luz (≤ 20 s).
2. **El huevo llega** · Un huevo de luz cae junto al árbol del santuario.
3. **Tres huevos idénticos** · Cada uno late con un color al acercarse: brasa, barro o greca.
4. **El Lote Hogar** · El Gabinete regala el Lote Hogar y el primer hábitat.
5. **Primer combate** · Historia: un Opaco menor débil ante el inicial elegido.
6. **Se abre el mundo** · Tienda (día 1), Arena 1v1 (capítulo 1), criadero (segundo monstruo), Arena 2v2
   (capítulo 2).

| MINUTO | MOMENTO |
|---|---|
| 0:00 | Sueño del Tallador (cinemática corta, se puede saltar) |
| 0:30 | Despertar en el santuario: llega el huevo |
| 1:00 | Elección entre tres huevos idénticos (gratis) |
| 2:00 | Eclosión del Brote y nombre |
| 3:00 | Lote Hogar y primer hábitat; primera recogida de Monedas |
| 5:00 | Alimentar y subir Vínculo |
| 7:00 | Primer combate de historia contra un Opaco menor |
| 10:00 | Cofre de Madera y primer huevo Común |
| 12:00 | Incubadora: primer huevo de 5 min |
| 15:00 | Se presentan el Gabinete (tienda) y el Portal de Arenas |

**EXPLICACIÓN PROGRESIVA:** Nunca más de una ventana de tutorial a la vez. El modo historia se presenta
con el primer Opaco, la arena con el primer cofre, la tienda con la primera compra y los lotes con la
segunda criatura.

**ELECCIÓN POR INTUICIÓN:** Los tres huevos son idénticos para que la elección sea emocional, no de
estadísticas. Tras eclosionar se muestra quién es y que los otros dos se pueden conseguir después.

**MÉTRICAS:** Meta: 85 % llega al primer combate; 70 % abre el primer cofre; 50 % vuelve al día
siguiente.

---

## Página 34 · Modo aventura

### Fuente PDF · página 111 — Modo aventura: estructura

La aventura vive dentro de los biomas y se abre conforme avanza la historia. Cada acto es un bioma con
tres regiones, cuatro etapas por región y un jefe: un Ser Sagrado opacado.

| ACTO | BIOMA | JEFE | NIVELES | ENEMIGOS | REGLA DEL BIOMA |
|---|---|---|---|---|---|
| Acto I | Valle Copal | Copalia, la Garza de Raíces | 1–15 | Opacos de Flora, Tierra y Aire | Las raíces curan a los Opacos cercanos |
| Acto II | Marea Coralina | Marejadra, el Hipocampo de Coral | 12–24 | Opacos de Agua y Mente | Corrientes que mueven el orden de turno |
| Acto III | Cumbre Brasa | Obsidárion, el Coloso de la Fragua | 22–32 | Opacos de Fuego y Metal | Suelo ardiente: quemadura cada 3 turnos |
| Acto IV | Meseta Fulgor | Fulgorón, el Tigre del Trueno | 30–40 | Opacos de Rayo y Artificio | Torres que cargan Savia al enemigo |
| Acto V | Velo Astral | Noctelia, la Medusa del Velo | 38–48 | Opacos de Luz, Sombra, Mente y Astral | Oscuridad: los ataques fallan más |
| Final | Torre del Nexo | Ánima del Nexo, la Primera Talla | 45–50 | Opacos de todos los elementos | Las gubias cambian el elemento del jefe |

| 6 | 13 | 78 | +12 |
|---|---|---|---|
| ACTOS | ETAPAS POR ACTO | ETAPAS EN TOTAL | ETAPAS SECRETAS |

**TIPOS DE ETAPA**

| TIPO | DESCRIPCIÓN |
|---|---|
| Combate | Opacos menores; 1 a 3 rivales. |
| Élite | Opaco con modificador (niebla, coraza o furia). |
| Rescate | Libera a un monstruo silvestre opacado: 10 % de huevo de su especie. |
| Tesoro | Elige ruta o resuelve un acertijo de elementos; cofre garantizado. |
| Jefe | Ser Sagrado opacado en dos o tres fases. |
| Secreta | Se abre con 3 estrellas en la región: pistas de los Guardianes Velados. |

**SIN ENERGÍA:** La aventura no usa energía: se juega cuanto se quiera. Las recompensas por repetir una
etapa ya superada bajan al 25 % y tienen un tope de 10 repeticiones con premio al día.

### Fuente PDF · página 112 — Modo aventura: mapa de un acto

Ejemplo del Acto I. Tres regiones de cuatro etapas, un jefe al final y una etapa secreta que aparece con
las 3 estrellas de la región.

Mapa: Región 1 · Región 2 · Región 3 — etapas 1 a 12, JEFE y «?» (secreta). Leyenda: Combate · Élite ·
Tesoro · Rescate · Jefe · Secreta. [Disposición de las etapas en el mapa ilegible en la extracción.]

**ESTRELLAS**

| ESTRELLAS | CÓMO SE CONSIGUEN |
|---|---|
| ★ | Ganar la etapa. |
| ★★ | Ganar sin perder ningún monstruo. |
| ★★★ | Cumplir el reto de la etapa: ganar en ≤ 8 turnos, usar un elemento concreto o rescatar sin derrotas. |

**OPACOS MENORES DEL ACTO I:** Opaco de Quiotazo · Opaco de Cantagólem · Opaco de Hercuerno · Opaco de
Navajazul · Opaco de Candelux · Opaco de Faroibex.

**DIFICULTAD**

| MODO | QUÉ CAMBIA | PREMIO |
|---|---|---|
| Normal | Niveles del acto | Monedas, XP y cofres |
| Pesadilla | Se abre al terminar el acto; rivales +10 niveles y élites con dos modificadores de bioma | ×1,5 recompensas y cosméticos |

**RESTAURAR, NO DESTRUIR:** Al vencer, la niebla gris se disipa y el monstruo recupera su color. Nadie
«muere» en NEXORA.

### Fuente PDF · página 113 — Modo aventura: jefes y guardianes

Cada acto termina con un Ser Sagrado opacado. Los combates de jefe tienen fases que cambian las reglas
para que cada uno se recuerde.

| ACTO | JEFE | FASES | AL VENCERLO |
|---|---|---|---|
| ACTO I · VALLE COPAL · NIVEL 1–15 | Copalia, la Garza de Raíces | Fase 1 cura a sus aliados con raíces · Fase 2 apaga la luz con faroles (−20 % precisión) | Cofre Nexo, Copalia entra al pool del Cofre Nexo y se abren la Marea Coralina y su lote. |
| ACTO II · MAREA CORALINA · NIVEL 12–24 | Marejadra, el Hipocampo de Coral | Fase 1 escudo de coral · Fase 2 marea que cambia de rival a tu monstruo | Cofre Nexo, Marejadra entra al pool y se abren la Cumbre Brasa y su lote. |
| ACTO III · CUMBRE BRASA · NIVEL 22–32 | Obsidárion, el Coloso de la Fragua | Fase 1 escudo-comal que refleja · Fase 2 erupción a todos los rivales | Cofre Nexo, Obsidárion entra al pool y se abren la Meseta Fulgor y su lote. |
| ACTO IV · MESETA FULGOR · NIVEL 30–40 | Fulgorón, el Tigre del Trueno | Fase 1 bobinas que paralizan · Fase 2 rugido que roba Savia | Cofre Nexo, Fulgorón entra al pool y se abren el Velo Astral y su lote. |
| ACTO V · VELO ASTRAL · NIVEL 38–48 | Noctelia, la Medusa del Velo | Fase 1 duerme a un monstruo · Fase 2 teje la noche (sin curaciones) | Cofre Nexo, Noctelia entra al pool y se abre la cima de la Torre del Nexo. |
| FINAL · TORRE DEL NEXO · NIVEL 45–50 | Ánima del Nexo, la Primera Talla | Tres fases: copia tu Golpe Nexo en la tercera | Cofre Nexo, el Ánima entra al pool, se abre Pesadilla del Final y aparece la primera pista de los Guardianes Velados. |

**EQUIPO PARA JEFES:** Equipo de 3 con coste máximo 12, como la Arena 1v1. Se recomienda un nivel; se
puede reintentar sin costo.

### Fuente PDF · página 114 — Modo aventura: recompensas y ritmo

La aventura es la fuente principal de cofres de Oro y de Cofres Nexo ganados, y la llave de los lotes de
cada bioma.

| LOGRO | RECOMPENSA |
|---|---|
| Etapa (primera vez) | 200–1 500 Monedas · 150–800 XP · Cofre de Madera o Plata |
| Tesoro | Cofre de Plata garantizado (Oro en Pesadilla) |
| Rescate | Monedas + 10 % de huevo de la especie rescatada |
| 3 estrellas en una región | Cofre de Oro |
| Jefe (primera vez) | Cofre Nexo + carta del Códice + desbloqueo del lote del bioma |
| Todas las estrellas del acto | Marco de carta del bioma + título |
| Repetición | 25 % de las Monedas y XP; máximo 10 repeticiones con premio al día |

**CÓDICE DEL NEXO**

1. **Cartas de lore.** Cada jefe, región y Opaco deja una carta del Códice con su historia.
2. **Pistas Veladas.** Las etapas secretas dejan pistas de los Guardianes Velados.
3. **Bestiario.** Cada especie vista o restaurada se registra con su mezcla mítica.

**RITMO ESPERADO (1 H AL DÍA)**

| ACTO | TIEMPO PARA TERMINARLO |
|---|---|
| Acto I | Semana 1 |
| Acto II | Semanas 2–3 |
| Acto III | Semanas 4–6 |
| Acto IV | Semanas 7–10 |
| Acto V | Semanas 11–14 |
| Final | Semanas 15–16 |

**LANZAMIENTO:** Propuesta: lanzar con Actos I y II, y sumar un acto por temporada de 8 semanas. Ver
preguntas.

### Fuente PDF · página 115 — Progresión *(continúa en la p. 35)*

Curva de experiencia: XP del nivel L al L+1 = 40 × L^1,5. Llegar a nivel 20 cuesta ≈ 26 850 XP: unos 6
días con 1 h de juego.

| HITO | XP ACUMULADA |
|---|---|
| Nv 12 · Tallado Común | 7 166 XP |
| Nv 15 · Tallado Raro | 12 799 XP |
| Nv 18 · Tallado Épico | 20 487 XP |
| Nv 20 · Golpe Nexo · Tallado Legendario | 26 855 XP |
| Nv 22 · Tallado Único | 34 282 XP |
| Nv 25 · Tallado Misterio | 47 525 XP |
| Nivel 50 | 275 808 XP |

**FUENTES DE XP**

| FUENTE | XP |
|---|---|
| Combate ganado | 120–300 |
| Combate perdido | 40–100 |
| Hábitat (por minuto) | 2 |
| Ración básica / de bioma | 150 / 600 |
| Festín / Ración Dorada | 2 500 / 4 000 |
| Capítulo de historia | 500–2 000 |

**ENCARGOS DIARIOS:** Gana 2 combates (cualquier arena). Alimenta a 4 monstruos. Incuba o mezcla 1 huevo.
Recompensa: 150–250 Monedas cada uno y un Cofre de Madera al completar los tres.

**HITOS:** Nv 10: puede criar. Nv 12–25: Tallado según rareza. Nv 20: Golpe Nexo (en Tallado). Nv 50:
tope.

**NIVELES ADECUADOS:** La Arena Libre empareja por Poder de equipo y la Equilibrada normaliza a nivel 50:
un jugador nuevo nunca se enfrenta a un equipo muy superior.

**SIN PAGO POR NIVEL:** No se venden niveles ni XP permanente; solo potenciadores temporales de XP ×2 (30
min).

---

## Página 35 · Interfaz, plan 2D, hoja de concepto y producción

### Fuente PDF · página 116 — Interfaz

Tres pantallas clave en teléfono: el menú del árbol, el combate y la Vitrina del Gabinete.

| MENÚ DEL ÁRBOL | ARENA 1V1 | VITRINA DEL GABINETE |
|---|---|---|
| Vitrina del Gabinete · Repisa de Cofres · 3 · Arena 1v1 · 2v2 · Criadero · 2 huevos · Encargos 2/3 | Kuachi Nv 14 contra Rillip Nv 13 · Savia ● ● ○ · 14 s · Chispazo · básico · Zarpa de Brasa · básico · Comal Ardiente · 2 · Látigo de Ceniza · Firma · Cambiar | Vitrina de hoy: Agavo 1 200 M · Brinco 9 000 M · Tuerco 60 000 M · Barrock 1 200 M · Cotorro 9 000 M · Nébulo 2 200 G · Cofres · toca para ver probabilidades |

*(Contenido de las tres maquetas, reordenado por pantalla; en la extracción salen intercaladas.)*

| LEGIBLE SIN LEER | PROBABILIDADES A UN TOQUE | ACCESIBILIDAD |
|---|---|---|
| Iconos de elemento y rareza en todos los botones; texto mínimo de 14 px en teléfono. | Todo cofre o mezcla muestra un botón «%» que abre la lista completa, también por especie. | Modo de alto contraste y patrones en las barras de vida para daltonismo. |

### Fuente PDF · página 118 — Plan 2D por lotes

Para empezar a trabajar en 2D poco a poco: un lote por bioma, después de fijar el estilo con los
iniciales. Cada especie se entrega con los mismos ocho elementos.

| LOTE | QUÉ | ESPECIES | TIEMPO |
|---|---|---|---|
| A | Estilo y mirada | Hoja de estilo, 3 iniciales (Brote, Tallado, cabeza feroz) | 3 semanas |
| B | Rediseños v5 | Yetormenta, Castorre, Engrifo, Voltalope, Navajazul | 2 semanas |
| C | Valle Copal | 11 especies restantes del Valle + Copalia | 4 semanas |
| D | Marea Coralina | 8 especies + Marejadra | 3 semanas |
| E | Cumbre Brasa | 8 especies + Obsidárion | 3 semanas |
| F | Meseta Fulgor | 7 especies + Fulgorón | 3 semanas |
| G | Velo Astral y Torre | 12 especies + Noctelia, Ánima y Nexum | 4 semanas |
| H | Guardianes Velados | Tres siluetas y diseños de temporada | Por temporada |

**ENTREGABLES POR ESPECIE**

| # | ENTREGABLE | DETALLE |
|---|---|---|
| 1 | Tres siluetas en negro a 64 px | Elegir una |
| 2 | Brote 3/4 frontal | Tierno, sencillo |
| 3 | Tallado 3/4 frontal | Imponente, con la mirada feroz |
| 4 | Cabeza del Tallado en 3 vistas | Frente, perfil y 3/4 |
| 5 | Hoja de giro de ambas formas | Frente, perfil, espalda, 3/4 |
| 6 | Seis expresiones | Del Brote y del Tallado |
| 7 | Paleta y materiales | Familia de color + acento de aura |
| 8 | Carta final | Fondo de bioma y marco de rareza |

*(Los entregables 6–8 están en la columna derecha; el texto de 7 y 8 sale intercalado y se reconstruye
por posición.)*

**PRIMER PASO:** Lote A: hoja de estilo con Kuachi, Xolumi y Teselo en Brote y Tallado. Cuando se
aprueben, se congela el estilo y el resto de los lotes avanza en paralelo.

### Fuente PDF · página 119 — Hoja de concepto 2D

Plantilla de entrega por especie (ejemplo: Engrifo) y el prompt base de la v5 para generar los primeros
bocetos.

Secciones de la plantilla: 1 · SILUETAS · 2 · BROTE · 3 · TALLADO · 7 · PALETA.
Mezcla mítica: Grifo de la mitología griega y medieval + relojería + aviación antigua.
Claves 2D: Cabeza de águila y alas de engranes · hélice · latón y cobre.

**PROMPT BASE V5**

```
Original creature for the Roblox game NEXORA, stylized "Copal Nexo" (Oaxacan alebrije shape
language: chimeras, S-curves, spirals, flame lobes; NOT rainbow colors). Species: [NAME],
[ELEMENTS], [RARITY]. Mythic mix: [ANIMAL] + [MYTH/LEGEND, as inspiration only] + [CRAFT/OBJECT].
BABY form: small, cute, simple, big round eyes, smooth surface. EVOLVED form: same creature grown
1.5x, imposing and aggressive but kid-friendly: almond eyes with element-colored iris and slit
pupil, strong brow, natural weapons [FANGS/HORNS/CLAWS], one big silhouette-breaking feature
[FEATURE], tone-on-tone carved relief with emissive grooves, [RARITY AURA]. Single color family
[PALETTE]. Must not resemble any existing franchise creature. Full body 3/4 view, plain
background, readable at 64 px.
```

| UNA COSA A LA VEZ | APROBACIÓN | PARA 3D |
|---|---|---|
| Primero la silueta, luego el Brote, luego el Tallado con el Brote como referencia obligatoria. Nunca especie, evolución y variante en una misma imagen. | Prueba de silueta a 64 px, prueba de parecido con otras franquicias y ficha de procedencia cultural antes de congelar. | Solo cuando el 2D está aprobado se pasa a malla. La talla se hornea a mapa de normales; la mirada feroz es textura + geometría de la ceja. |

### Fuente PDF · página 120 — Producción y presupuestos

Ninguna imagen ni malla automática es un activo terminado: todo pasa por revisión y por Roblox Studio.

| PASO | QUÉ |
|---|---|
| 1 · Ficha cerrada | Esta Biblia: ID, rareza, elementos, silueta, rasgo firma. |
| 2 · Concepto 2D | Siluetas → Brote → Tallado con el Brote como referencia. |
| 3 · Revisión | Prueba de silueta, de parecido y de cultura. |
| 4 · Malla 3D | Image-to-3D multivista; aprobar cada gasto de créditos. |
| 5 · Limpieza | Retopología, UV, talla horneada, rig y LOD. |
| 6 · Validación | Roblox Studio: escala, materiales, aura, prueba en gama baja. |

**PRESUPUESTOS POR ACTIVO**

| CATEGORÍA | TRIÁNGULOS | TEXTURA | HUESOS | EMISORES DE AURA |
|---|---|---|---|---|
| Brote | 2 500–4 000 | 1024² | ≤ 18 | 0–1 (Raro+) |
| Tallado Común–Épico | 4 000–6 500 | 1024² | ≤ 30 | 0–2 |
| Tallado Legendario/Único | 6 500–9 000 | 1024² (2048² cinemática) | ≤ 40 | 2–3 |
| Ser Sagrado (jefe) | 9 000–14 000 | 2048² | ≤ 50 | 3 |
| Huevo | 600–1 200 | 512² | 0–3 | 0–1 |
| Cofre | 1 000–2 000 | 512² | 1 (tapa) | 0–1 |

**ORDEN DE PRODUCCIÓN**

1. Kuachi, Xolumi y Teselo (Brote y Tallado) para validar el pipeline.
2. Moneda, gema, seis cofres, incubadora y huevos por rareza.
3. Papalumen y Nexum (piezas de marketing).
4. Resto del Valle Copal y Copalia.
5. Cumbre Brasa con Obsidárion; Velo Astral con Noctelia. *(este punto termina en la p. 36)*

**AURA EN ROBLOX:** Aura = ParticleEmitter + Beam + Highlight según la rareza, nunca geometría extra. En
combate el aura baja al 60 %.

**PRUEBA DE RENDIMIENTO:** 8 monstruos con aura en pantalla a 30 fps en el teléfono base antes de
aprobar un Legendario. *(la frase termina en la p. 36)*

---

## Página 36 · Continuación de «Producción y presupuestos»

Página de continuación: solo contiene el final de dos frases de la página 35, ya integradas arriba.

- «…en el teléfono base antes de aprobar un Legendario.»
- «5. Cumbre Brasa con Obsidárion; Velo Astral con Noctelia.»

---
## Página 37 · Apéndice B / Preguntas abiertas

### Las 93 preguntas para la v5.1

Transcritas en orden de lectura desde las páginas 121–126 de la fuente. Las propuestas actuales son las
de la v5.0; la columna de respuesta estaba en blanco y no se completa en esta edición.

| Nº | PREGUNTA | PROPUESTA ACTUAL V5.0 |
|---|---|---|
| 1 | ¿Los Brotes deben verse aún más tiernos (ojos más grandes, proporción de bebé) o como están ahora? | Como están |
| 2 | ¿Qué tan feroces quieres los Tallados: «heroicos» (como la v5) o «amenazantes» (más colmillos, garras y pose de ataque)? | Heroicos con mirada feroz |
| 3 | ¿Mantener una sola evolución, o abrir en el futuro una tercera forma «Ascendida» solo para Legendarios? | Una sola evolución |
| 4 | ¿Qué monstruos de la v5 todavía no te convencen? Indica número y qué cambiarías. | — |
| 5 | ¿Quieres sumar inspiración de otras mitologías (japonesa, griega, egipcia, celta, hindú)? ¿Cuáles? | Las actuales |
| 6 | ¿Apruebas los rediseños Yetormenta (yeti), Castorre (castor) y Engrifo (grifo de cuerda)? | Sí |
| 7 | Mencionaste tecnología, espacio y diseño industrial: ¿quieres una línea más grande de monstruos mecánicos o espaciales? | 5 mecánicos y 7 astrales |
| 8 | ¿Las cartas con marco por rareza se usan también dentro del juego (Álbum del Nexo)? | Sí |
| 9 | ¿Cuántas variantes de color (Veta) por especie: 3 o 5? | 3 |
| 10 | ¿Los accesorios se ven en combate o solo en el santuario? | En ambos |
| 11 | Para el 3D final, ¿más «juguete de vinilo» o más «talla de madera pintada»? | Talla pintada |
| 12 | Animación del Despertar del Tallado: ¿corta (5 s) o cinemática (12 s) por especie? | Corta + cinemática en Legendarios |
| 13 | ¿Qué nombres nuevos no te gustan? Márcalos en las páginas «Nombres v5». | — |
| 14 | ¿Nombres iguales en todo el mundo o versión localizada en inglés? | Iguales |
| 15 | ¿El epíteto de Legendarios y Únicos se muestra siempre o solo en la ficha? | Solo en la ficha |
| 16 | ¿Los Brotes conservan nombres juguetones y los Tallados de leyenda, o los quieres igual de serios? | Como ahora |
| 17 | Divisiones: ¿nombres de la talla (Esbozo…Nexo Eterno), celestiales (Alba…Constelación) o míticos (Vigía…Leyenda)? | De la talla |
| 18 | ¿Confirmas Marea Coralina (agua) y Meseta Fulgor (rayo) como biomas nuevos? | Propuesta |
| 19 | Orden de actos: Valle → Marea → Cumbre → Fulgor → Velo → Torre. ¿Otro orden? | Ese |
| 20 | ¿Un lote por bioma o varios lotes comprables en cada bioma? | Uno por bioma |
| 21 | ¿Lotes de distintos tamaños (pequeño, mediano, grande) o todos de 1 hábitat? | Todos de 1 hábitat |
| 22 | ¿Se puede ampliar un lote a 2 hábitats? ¿Con qué costo? | No en el lanzamiento |
| 23 | ¿El bono nativo de +10 % es suficiente o lo subimos a +15–20 %? | +10 % |
| 24 | ¿Los jugadores pueden visitar lotes de otros y dejar regalos? | Sí, regalos de comida |
| 25 | ¿Decoración libre (colocar objetos) o plantillas por lote? | Plantillas + 6 objetos libres |
| 26 | ¿Inventario de 40 ampliable hasta 100 está bien? | Sí |
| 27 | ¿Clima o día y noche que cambien bonos en los biomas? | Día y noche visual |
| 28 | El informe sugiere Único 12 h y Misterio 24 h para un público joven. ¿Mantienes 24 h y 72 h? | 24 h y 72 h |
| 29 | ¿Tope de 120 Gemas para acelerar cualquier huevo? | No hay tope |
| 30 | ¿El huevo flotante muestra grietas por etapas (25 / 50 / 75 %)? | Sí |
| 31 | ¿Se ve una silueta de la especie dentro del huevo antes de eclosionar? | No |

---

## Página 38 · Preguntas abiertas (32–73)

| Nº | PREGUNTA | PROPUESTA ACTUAL V5.0 |
|---|---|---|
| 32 | ¿Huevos de evento con diseño especial por temporada? | Sí |
| 33 | ¿Máximo 5 ranuras de incubadora? | 5 |
| 34 | ¿Se pueden regalar huevos entre amigos? | No en el lanzamiento |
| 35 | ¿Mantener 8 / 6 / 4 % para el linaje que sube de rareza? | Sí |
| 36 | Con Monedas en el pase, la cuota de la mezcla la vuelve Paid Random Item. ¿Quitar la cuota para todos o solo para regiones restringidas? | Solo restringidas |
| 37 | ¿Linajes secretos que no aparecen en la tabla hasta descubrirlos? | No (todo visible) |
| 38 | ¿Descanso de los padres de 1 a 8 h? | Sí |
| 39 | ¿Mezcla entre amigos (cada uno pone un padre)? | Fase 2 |
| 40 | ¿Más mutaciones visuales además de la Veta Dorada? | Una por temporada |
| 41 | ¿Los Guardianes Velados se podrán criar? | No |
| 42 | ¿Mantener 18 / 14 / 10 / 5 / 2 / 1 en el catálogo? | Sí |
| 43 | ¿Presupuestos 100 / 108 / 116 / 124 / 128 y Misterio 120? | Sí |
| 44 | ¿Nexum con coste 5 (propuesta) o 6? | 5 |
| 45 | ¿Cuántos Legendarios nuevos por temporada? | 1 |
| 46 | Guardianes Velados: ¿rareza Único o una nueva rareza «Mítica»? | Único |
| 47 | ¿Nivel máximo 50 o 60 con las temporadas? | 50 |
| 48 | ¿Probar ×1,25 / ×0,85 en la beta en lugar de ×1,5 / ×0,75? | Mantener ×1,5 hasta tu respuesta |
| 49 | ¿Turno de 20 s en 1v1 y 20 s + 45 s de reserva en 2v2? | Sí |
| 50 | ¿Límite de 6 min en 2v2? | Sí |
| 51 | Torneo 3v3 individual: ¿inscripción gratis, con Monedas o con Gemas? | Gratis con cupo |
| 52 | ¿Mostrar la ventaja de elemento en el botón de cada ataque? | Sí |
| 53 | ¿Modo práctica contra la IA? | Sí |
| 54 | ¿Temporadas de arena de 8 semanas con reinicio parcial de división? | Sí |
| 55 | ¿Tope de 8 cofres de victoria al día, o 6 como sugiere el informe? | 8 |
| 56 | ¿Las divisiones altas dan cofres distintos o solo más probabilidad de cofres buenos? | Más probabilidad |
| 57 | ¿Recompensa de fin de temporada según la división alcanzada? | Sí |
| 58 | ¿Se pierden Puntos de Talla en Esbozo y Gubia? | No |
| 59 | ¿Clasificación global, por país o por amigos? | Las tres |
| 60 | ¿Apruebas la nueva Madera (Común 30 %, Raro 6 %)? | Sí |
| 61 | Diamante: Épico 62 % · Legendario 30 % · accesorio 8 %. ¿Tenías otra distribución? | Propuesta |
| 62 | ¿Mantener el Legendario 1 entre 2 000 en Madera? | Sí |
| 63 | ¿Cofres con temporizador para abrir (que las Gemas aceleren)? Hoy se abren al instante. | Al instante |
| 64 | ¿Cofres de evento por temporada? | Sí |
| 65 | ¿Cofre Nexo con protección de repetidos y contador visible? | Sí |
| 66 | Muro Monedas/Gemas: ¿opción A (Monedas en el pase), B (pase sin Monedas) o C (tercera moneda)? | A |
| 67 | ¿Precios de cofres en Gemas 90 / 220 / 450 / 1 200? | Sí |
| 68 | ¿Seis paquetes de Gemas (80 a 4 000 R$) o menos opciones? | Seis |
| 69 | ¿Bono de +50 % en la primera compra de cada paquete? | Sí |
| 70 | ¿Reciclar monstruos repetidos por Monedas o materiales? | Sí, por Polvo de Talla |
| 71 | ¿Potenciadores temporales de Monedas con Gemas? (Hoy no existen) | No |
| 72 | ¿Intercambio entre jugadores en la fase 2? | Solo monstruos ganados |
| 73 | ¿Huevo Legendario de la Vitrina a 2 200 Gemas o 1,5 M Monedas? | Sí |

---

## Página 39 · Preguntas abiertas (74–93)

| Nº | PREGUNTA | PROPUESTA ACTUAL V5.0 |
|---|---|---|
| 74 | Precio: ¿399, 499 o 799 R$? | 499 R$ |
| 75 | Recompensa final: ¿A, B o C (Épico cada mes + Legendario a los 3 meses)? | C |
| 76 | ¿El reparto de días (Monedas 10, Gemas 6, Plata 6, Oro 4, comida 3, final 1)? | Sí |
| 77 | Si el jugador no entra un día, ¿puede recuperar el premio? | Sí, hasta 3 al mes |
| 78 | ¿El aura del mes es exclusiva para siempre o puede volver? | Exclusiva |
| 79 | ¿Quieres ofrecer también un pase permanente (VIP) además de la suscripción? | No |
| 80 | ¿Lanzar con los seis actos o con 2 actos y uno más por temporada? | 2 actos + 1 por temporada |
| 81 | ¿Sin energía (como la v5) o con energía? | Sin energía |
| 82 | ¿Dificultad Pesadilla al terminar cada acto? | Sí |
| 83 | ¿Aventura cooperativa de 2 jugadores? | Fase 2 |
| 84 | ¿Cinemática corta al inicio y al final de cada acto? | Sí |
| 85 | ¿Diálogos con voz o solo texto? | Texto + sonidos |
| 86 | ¿Los Opacos menores dan huevos de su especie al restaurarlos? | 10 % |
| 87 | ¿Eventos de mundo (tormenta en el Fulgor, marea alta)? | Sí, semanales |
| 88 | ¿Clubes o gremios? | Fase 2 |
| 89 | ¿Chat de texto limitado a frases rápidas por seguridad infantil? | Sí |
| 90 | ¿Mercados iniciales: México y LATAM o global desde el inicio? | México y LATAM |
| 91 | ¿Edad objetivo exacta para el cuestionario de madurez de Roblox? | 9+ |
| 92 | ¿Eventos con marcas o patrocinios? | No en el lanzamiento |
| 93 | ¿Qué equipo y presupuesto tienes para el 2D (artista propio, IA asistida, estudio)? | — |

---

## Página 40 · Apéndice C / Láminas visuales

### Referencias originales seleccionadas

Estas imágenes preservan parte de la intención visual de la v5.0. Son bocetos, diagramas y referencias;
no son aprobación de arte ni obligación de replicar. Los diseños de monstruos deben rediseñarse mediante
el pipeline creativo definido en esta edición.

[Lámina: imagen sin texto extraíble.]

---

## Página 41 · Mundo, mapa y biomas

[Lámina: imagen sin texto extraíble. Título de la página: «Mundo, mapa y biomas».]

---

## Página 42 · Lenguaje visual, mirada y rarezas

[Lámina: imagen sin texto extraíble. Título de la página: «Lenguaje visual, mirada y rarezas».]

---

## Página 43 · Huevos, colección y tres iniciales

[Lámina: imagen sin texto extraíble. Título de la página: «Huevos, colección y tres iniciales».]

---

## Página 44 · Referencias preliminares de los iniciales

[Lámina: imagen sin texto extraíble. Título de la página: «Referencias preliminares de los iniciales».]

---

## Página 45 · Incubación, historia y onboarding

[Lámina: imagen sin texto extraíble. Título de la página: «Incubación, historia y onboarding».]

---

## Página 46 · Interfaz y pipeline de producción

[Lámina: imagen sin texto extraíble. Título de la página: «Interfaz y pipeline de producción».]
