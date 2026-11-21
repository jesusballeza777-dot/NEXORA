# NEXORA · Registro de decisiones de diseño

Registro vivo de qué viene definido por la Biblia, qué es provisional, qué sigue pendiente y qué
cambiamos por motivos técnicos, comerciales, creativos o de experiencia. Cada decisión que toca el
código remite al archivo de configuración donde vive, para que cambiarla sea editar un dato.

**Fuentes consultadas**

- `docs/reference/NEXORA_Biblia_Compacta_v1.0.pdf`: Biblia Compacta de Desarrollo v1.0 (46 páginas, 21 nov 2026), que transcribe por página el contenido de la Biblia de Creación v5.0 (fuente de 120 páginas de contenido más 6 de preguntas).
- **Falta en el repositorio** `docs/reference/NEXORA_Biblia_v5.pdf` (127 páginas). Este registro se hizo con la compacta; las láminas originales y cualquier dato que la compacta haya omitido deben revisarse cuando se incorpore. Ver `docs/reference/README.md`.

**Clasificación**

| Código | Significado |
|---|---|
| **A · Definido** | Establecido expresamente en la Biblia (estado HECHO o dato sin marca de propuesta). |
| **B · Provisional** | Propuesta de diseño (PROPUESTA en la Biblia, o hueco que el prototipo tuvo que rellenar). Se valida en pruebas. |
| **C · Pendiente** | Pregunta abierta (las 93 preguntas de la v5.1 u otras). No se responde en nombre del equipo. |
| **D · Mejora recomendada** | Cambio que proponemos frente a la Biblia, con su justificación. Requiere aprobación. |

---

## 1. Mapa de clasificación por área

| Área | A · Definido | B · Provisional | C · Pendiente | D · Mejora |
|---|---|---|---|---|
| Mundo | Valle Copal como centro con lotes y Torre del Nexo; Cumbre Brasa y Velo Astral; lotes y precios; 4 slots por hábitat; inventario 40→100; bono nativo +10 % | Marea Coralina y Meseta Fulgor (p. 9); orden de actos | P18–P27 | Estaciones accesibles por "viaje rápido" del menú del árbol, no a distancia (D-011) |
| Arte | Brote tierno / Tallado imponente; 8 reglas de evolución; mirada del Tallado; cartas por rareza; aura por rareza y presupuesto técnico | Estilos 3D ("talla pintada" vs "vinilo", P11) | P1–P16 | Lenguaje de materiales más amplio que la madera (Genesis §5.1) |
| Especies | 50 especies, nombres v5, rareza, elementos, rol, familia, bioma, atributos (todas suman el presupuesto exacto: comprobado por prueba) | Rediseños v5 (P6) | P4, P13, P42–P47 | — |
| Elementos | 12 elementos, rueda 2/2, triángulo Agua→Fuego→Flora (comprobado por prueba) | Rueda marcada "provisional" en la fuente | P48 | Multiplicadores ×1.25/×0.85 en beta (D-001) |
| Atributos y combate | 5 atributos; presupuestos; plantillas de rol; escala 0.4+0.012·nivel; Brote 70 %; Savia; repertorio por elemento; fórmula de daño | Duración de turnos, límites | P49–P53 | Escala de daño por nivel (D-002); precisión base 100 % (D-003); PvE sin temporizador (D-004) |
| Progresión | XP 40·L^1.5 (verificada contra las cifras publicadas); Tallado Común nv 12; Golpe Nexo nv 20 | Escala del Vínculo | — | Vínculo mínimo para tallar (D-007); "Jugar" da Vínculo (D-006) |
| Economía | Monedas/Gemas separadas; precios de comida; producción por rareza; Brote 50 %; tope 8 h | — | P66–P79 | Opción de pase B (D-015) |
| Cofres | Seis cofres y probabilidades v5 | Diamante 62/30/8 (P61) | P60–P65 | Fuera de la Fase 1 (Genesis) |
| Eclosión/incubación | Tiempos 5 min…72 h; especie decidida al obtener el huevo | Único 24 h y Misterio 72 h (P28) | P28–P34 | — |
| Crianza y herencia | 42 recetas; reglas por pareja; Temple/Veta/Don/Eco | — | P35–P41 | Fuera de la Fase 1 |
| Aventura | 6 actos, regiones, etapas, estrellas, sin energía, repetición al 25 % con tope 10/día | Lanzar con 2 actos (P80) | P80–P87 | — |
| Primeros 15 minutos | Secuencia sueño→huevo→3 huevos→Lote→alimentar→combate | Minutos exactos | — | Sustituir cofre de Madera por recompensa determinista (D-012) |
| Producción 2D/3D | Pipeline, entregables por especie, presupuestos por activo | Herramientas (Gemini, Meshy) | P93 | Blockouts jugables mientras el arte se aprueba (D-016) |
| Monetización | Sin pay-to-win; probabilidades visibles; PolicyService | Precios en Robux, pase 399–799 R$ | P66–P79 | Posponer todo hasta medir retención (Genesis §9) |

---

## 2. Decisiones registradas

Formato: **estado** · decisión · por qué · consecuencias · dónde vive · pregunta relacionada.

### D-001 · Multiplicadores elementales ×1.25 / ×0.85 en la beta — D
- **Biblia:** mantiene ×1.5 / ×0.75 "hasta confirmación" (p. 3, 32, 34; pregunta 48), aunque su propia simulación (p. 33) muestra que con ×1.5 un Común con ventaja vence a un Legendario el 81 % de las veces y recomienda ×1.25 / ×0.85 con topes ×1.6 / ×0.7.
- **Decisión:** la Fase 1 usa ×1.25 / ×0.85, tope ×1.6, suelo ×0.7 y suelo del Golpe Nexo ×0.85. Lo exige además Project Genesis.
- **Consecuencias:** la rareza conserva peso; el elemento sigue decidiendo combates igualados. Cambiar de hipótesis es editar `Config/Combat.luau → Element`.
- **Pendiente:** validar con la tasa de victoria por emparejamiento elemental en la beta (P48).

### D-002 · El daño escala con el nivel y la forma del atacante — D
- **Contradicción:** la fórmula de la p. 40 (`Poder × A/(A+D) × 2 × …`) no depende del nivel en términos absolutos (A y D escalan igual y el cociente se cancela), pero los PV sí escalan (`VID × 10` a nivel 50, `base × (0.4 + 0.012·nivel)`). Resultado: a nivel 1 un básico de 40 haría ≈40 de daño contra ≈55 PV y cualquier combate terminaría en 1–2 golpes; el ejemplo de la Biblia ("se derrota en 3 a 5 acciones") solo se cumple a nivel 50.
- **Decisión:** multiplicar el daño por la escala del atacante (`factorForma × factorNivel`). A igualdad de nivel se recuperan las 3–5 acciones en cualquier nivel; el nivel importa en PvE.
- **Dónde:** `Config/Combat.luau → ScaleDamageByAttackerLevel`; `Domain/Battle/BattleEngine.computeDamage`.
- **Verificado:** prueba "equal-level matchups take 3–6 actions" y simulación del primer combate.

### D-003 · Precisión base 100 %, crítico 5 %, variación ±5 % — B
- **Contradicción:** la fórmula de la p. 40 usa crítico 5 % (×1.5) y variación 0.95–1.05 sin fallo base; la simulación de la p. 33 usó 10 % de fallo, ±15 % y 10 % de crítico.
- **Decisión:** se aplica la fórmula de la p. 40 (es la especificación; la simulación es un modelo). La precisión solo baja por efectos (Humo de Copal, Arena en los Ojos, Destello).
- **Dónde:** `Config/Combat.luau`.

### D-004 · Turnos simultáneos sin temporizador en PvE de historia — D
- **Biblia:** turnos de 20 s (p. 39–40) pensados para arenas.
- **Decisión:** el combate de historia no tiene temporizador (público joven, primer contacto); el motor ya admite `TurnSeconds` para la arena.

### D-005 · Motor preparado para equipos de 3, prototipo 1 contra 1 — A/B
- El motor admite equipos de 1 a 3 con uno en campo (Arena 1v1 de la p. 39). Los cambios de monstruo, los efectos de 2v2 (`Area2v2`) y "no puede cambiar" (`NoSwitch`) se conservan como datos y el motor 1v1 los ignora de forma explícita (`Abilities.IgnoredIn1v1`).

### D-006 · El Vínculo se gana jugando y con comida de bioma — B/D
- **Contradicción:** "Primeros 15 minutos: 5:00 Alimentar y subir Vínculo" (p. 110), pero la tabla de precios (p. 93) no da Vínculo a la Ración básica (solo a la de bioma, Festín y Dorada). El bucle (p. 108) dice "Cuidar: alimentar **y jugar**: sube XP y Vínculo".
- **Decisión:** se respeta la tabla (Ración básica = 0 Vínculo) y se añade la interacción **Jugar** (+1 Vínculo, enfriamiento 45 s). El tutorial separa "Aliméntalo" (XP) de "Juega con él" (Vínculo).
- **Dónde:** `Config/Progression.luau → Bond`, `Config/Economy.luau → Foods`.

### D-007 · Escala del Vínculo y requisito para tallar — B (C para el equipo)
- **Hueco:** la Biblia usa "+1/+2 Vínculo" y "Don Leal: +10 % Vínculo", pero no define tope, niveles ni efecto.
- **Decisión provisional:** puntos enteros 0–100; 8 corazones con umbrales 3·8·15·25·40·60·80·100; **tallar requiere nivel de Tallado y 2 corazones** (8 puntos). Así el Tallado se gana cuidando, no solo combatiendo (Genesis §3: "lo cuida, lo alimenta, desarrolla su vínculo… y finalmente lo transforma").
- **Pendiente:** confirmar si el Vínculo debe dar algo más (cosmético, recolección, frases).

### D-008 · Primer Opaco por inicial: Agavo, Comalú y Zizi — B
- **Biblia:** p. 48 fija el tipo (Kuachi → Opaco de Flora, Xolumi → de Fuego, Teselo → de Rayo); p. 112 lista los Opacos menores del Acto I (Quiotazo, Cantagólem, Hercuerno, Navajazul, Candelux, Faroibex), que no incluyen ningún Fuego ni Rayo.
- **Decisión:** Agavo (Flora, el Brote de Quiotazo, ya en la lista del Acto I), Comalú (Fuego, único Común de Fuego además de Kuachi) y Zizi (Rayo, Común). Etapa 2: Cantagólem (Barrock); etapa 3 (élite con Coraza): Hercuerno (Vainas). Los tres de la lista.
- **Hallazgo de balance (B-005):** con juego aleatorio, a nivel 2 Kuachi y Teselo ganan ≈100 % y Xolumi 94 % (6,5 turnos de media frente a 3,5–3,9). Xolumi es Soporte de ATQ bajo contra un Defensor. Aceptable para el tutorial (el flujo garantiza nivel ≥ 2 y la derrota no castiga), pero conviene revisarlo cuando haya arte y sonido: un Opaco de Fuego menos defensivo igualaría la experiencia.

### D-009 · El bono nativo se decide por el bioma de la especie — B
- **Contradicción:** "Nativos con bono del Valle: Comunes y Raros de Flora, Tierra y Aire" (p. 9) frente a la tabla maestra, donde los iniciales de Fuego y Agua tienen bioma Valle Copal, y la regla general "los nativos obtienen +10 % en su bioma de origen".
- **Decisión:** el bono usa el campo `biome` de la especie (tabla maestra). Kuachi, Xolumi y Teselo producen +10 % en el Lote Hogar.

### D-010 · Inventario (Vivero) a nivel de cuenta — B
- **Contradicción:** "Inventario de la Torre: 40" (p. 7) frente a "Lote Hogar: inventario, 1 hábitat y vitrina" (p. 5/8).
- **Decisión:** el Vivero es de la cuenta (40 plazas, ampliable a 100) y se gestiona desde la ficha del Lote Hogar; físicamente puede vivir en la Torre más adelante.

### D-011 · El menú del árbol lleva a las estaciones; no las usa a distancia — D
- **Biblia:** "las mismas estaciones están en un menú radial para quien no quiera caminar" (p. 11).
- **Decisión:** el menú ofrece **viaje rápido** a la estación (servidor valida destinos fijos). Recoger Monedas, colocar monstruos, comprar comida y combatir exigen estar en el lugar (validación de proximidad). Conserva la comodidad móvil y protege el valor del mundo físico y de las visitas sociales futuras.

### D-012 · Sin cofres en la Fase 1: recompensas deterministas — A (Genesis)
- **Biblia:** el minuto 10 entrega un Cofre de Madera y el 12 la incubadora (p. 110).
- **Decisión:** Project Genesis prohíbe aleatoriedad en esta fase. El primer combate entrega un paquete fijo (200 Monedas + 10 Gemas por logro + 2 Raciones de bioma + 150 XP) y la incubadora queda reservada en el lote. Las Gemas por logro son coherentes con la p. 91 ("Gemas: … logros").

### D-013 · El acompañante puede vivir en el hábitat — D
- **Hueco:** la Biblia no dice si un monstruo puede producir en el hábitat y a la vez acompañar al jugador. Con un solo monstruo en el tutorial (colocar en el hábitat en el minuto 3 y combatir en el 7), exigir elegir sería frustrante.
- **Decisión:** el acompañante cuenta para la producción de su lugar; mientras pasea, su lugar muestra la marca "paseando". Revisar cuando haya varios monstruos.

### D-014 · Reserva de 50 Monedas en la primera recogida — D
- La producción real de un Brote Común es 16,5 Monedas/h con bono nativo: en el minuto 3 del tutorial el recolector estaría vacío. La primera apertura del lote deja 50 Monedas para que "primera recogida de Monedas" (p. 110) sea un momento real. Configurable en `Server/Domain/Actions.luau` (`FIRST_COLLECT_BONUS`).

### D-015 · Pase mensual: recomendar la opción B — D (decisión del equipo, P66)
- **Biblia:** la v5 aplica la opción A (Monedas en el pase) aunque convierte todo lo aleatorio comprado con Monedas en Paid Random Item.
- **Recomendación:** opción B (pase sin Monedas: Gemas, cofres de contenido fijo y comida). Mantiene los cofres de Monedas fuera de la regulación, simplifica el cumplimiento por país y encaja con un público de 9+ años. Nada de esto se activa en la Fase 1.

### D-016 · Blockouts jugables mientras el arte se aprueba — D
- Ningún diseño de personaje se fija sin aprobación humana (Genesis §5.4). El prototipo usa blockouts procedurales marcados `AssetStatus = "Blockout"` en Roblox y la vista previa web. La interfaz y el mundo sí tienen dirección visual trabajada.

### D-017 · Requisitos de Roblox no publicados en la Biblia — D
- **Apodos:** se filtran con `TextService:FilterStringAsync` antes de guardarse; si el filtro falla, se rechaza.
- **DataStore de pruebas:** Studio usa `NEXORA_Profiles_TEST_v1`; solo el servidor publicado usa el de producción.
- **Analítica:** `AnalyticsService` (embudo de onboarding y eventos personalizados), sin inventar métricas.

### D-018 · Estructura del proyecto — D
- Se sigue la estructura propuesta con tres ajustes: archivos `.luau`; la lógica pura vive en `Shared/Domain` y `Server/Domain` para poder probarse fuera de Studio; los servicios pequeños de juego (eclosión, cuidado, santuario, tienda, recompensas) comparten `GameplayService` porque cada manejador es una línea que delega en `Domain/Actions`.

### D-019 · Mundo sin streaming en el vertical slice — D
- Valle Copal es pequeño (un solo lugar, piezas procedurales). Con `StreamingEnabled` el cliente podía arrancar sin los huevos, estaciones o lotes y dejar ProximityPrompts sin conectar.
- **Decisión:** `Workspace.StreamingEnabled = false` en `default.project.json`; el cliente espera a `game.Loaded`, y todos los prompts pasan por un único `ProximityPromptService.PromptTriggered`, que sigue funcionando si se reactiva el streaming. Revisar cuando el mundo crezca (Fase 2: región 2 y Copalia), midiendo memoria en móviles de gama baja.

### D-020 · Huir no da experiencia; consolación limitada — D
- **Biblia:** perder un combate da algo de XP para que no se sienta como un castigo (p. 63–64).
- **Hueco:** huir en el primer turno también contaba como derrota, así que se podía repetir "empezar y huir" para cultivar XP sin jugar.
- **Decisión:** huir (`Forfeit`) cierra el combate sin XP ni recompensa. La XP de consolación por derrota real se limita a **10 por día** por cuenta (`EncounterRules.DAILY_CONSOLATION_LIMIT`, día UTC). Cubierto por pruebas de integración.

### D-021 · Comandos de desarrollador solo en Studio — D
- Antes, un UserId en `Config/Dev.AllowedUserIds` activaba los comandos de prueba también en servidores publicados, que escriben en el DataStore de producción.
- **Decisión:** `DevGate` solo autoriza dentro de Studio (que usa el almacén de pruebas); en Studio la lista restringe quién puede usarlos (vacía = todos). Ningún multiplicador puede tocar datos reales.

---

## 3. Contradicciones detectadas en la Biblia

| # | Versión 1 | Versión 2 | Solución provisional |
|---|---|---|---|
| 1 | ×1.5/×0.75 vigente (p. 3, 34) | Simulación recomienda ×1.25/×0.85 (p. 32–33) | D-001 |
| 2 | Crítico 5 %, ±5 %, sin fallo (p. 40) | Simulación con 10 % crítico, ±15 %, 10 % fallo (p. 33) | D-003 |
| 3 | Daño sin escala de nivel (p. 40) | PV escalados por nivel (p. 35) | D-002 |
| 4 | Ración básica sin Vínculo (p. 93) | "Alimentar y subir Vínculo" en el minuto 5 (p. 110) | D-006 |
| 5 | Nativos del Valle = Flora/Tierra/Aire (p. 9) | Iniciales de Fuego/Agua con bioma Valle (p. 52) | D-009 |
| 6 | Inventario en la Torre (p. 7) | Inventario en el Lote Hogar (p. 5/8) | D-010 |
| 7 | Primer Opaco de Fuego y de Rayo (p. 48) | Opacos del Acto I sin Fuego ni Rayo (p. 112) | D-008 |
| 8 | Cofre y huevo aleatorio en los primeros 15 min (p. 110) | Genesis: sin aleatoriedad en Fase 1 | D-012 |
| 9 | Misterio presupuesto 120 / coste 5 (propuesta v5) | 128 / 6 (v4) | Se usa la propuesta v5 en datos; no afecta a la Fase 1 (P43–P44) |
| 10 | Agavo/Quiotazo con bioma Cumbre Brasa (p. 52) | Aparece como Opaco del Acto I del Valle (p. 112) | Sin conflicto real: los Opacos pueden estar fuera de su bioma. Se documenta. |
| 11 | "Hábitat (por minuto) · 2" XP (p. 115, tabla partida en la transcripción) | — | Lectura provisional: 2 XP por minuto a cada monstruo del hábitat (B) |

---

## 4. Las 93 preguntas de la v5.1

La Biblia trae 93 preguntas con una "propuesta actual" y la columna de respuesta en blanco. **No se
contestan aquí.** El prototipo usa la propuesta actual cuando la necesita y lo marca como provisional.

**Ninguna bloquea la Fase 1.** Las que más afectan a la Fase 2 y deberían responderse primero:

| Pregunta | Tema | Por qué importa ya |
|---|---|---|
| P48 | Multiplicadores elementales | Ya usamos ×1.25/×0.85 (D-001); confirmar o cambiar en datos |
| P11 | 3D "talla pintada" o "juguete de vinilo" | Fija el pipeline de modelado de los iniciales |
| P1–P2, P4 | Ternura del Brote, ferocidad del Tallado, especies que no convencen | Entrada directa al rediseño de los iniciales |
| P93 | Equipo y presupuesto de arte 2D | Determina el calendario de producción |
| P28 | Tiempos de incubación de Únicos y Misterio | Fase 2 (incubadora) |
| P66 | Opción A/B/C del pase y las Monedas | Cumplimiento de Paid Random Items (D-015) |
| P80 | Lanzar con 2 actos | Alcance del primer lanzamiento |
| P90–P91 | Mercados iniciales y edad objetivo | Localización, chat, cuestionario de madurez |
| P36 | Cuota de mezcla en regiones restringidas | Diseño de la crianza |

El cuestionario completo está en el apéndice B de la Biblia compacta (p. 36–38).
