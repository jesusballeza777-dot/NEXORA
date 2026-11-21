# NEXORA · Alcance de la Fase 1 (vertical slice)

Una porción pequeña y real del juego, completa de principio a fin: Valle Copal, tres iniciales
provisionales, eclosión, acompañante, Lote Hogar, cuidado, XP y Vínculo, combate PvE, recompensa
y guardado. Todo lo demás queda preparado en datos y contratos, no implementado.

## Criterios de aceptación (Genesis §15)

Leyenda: ✅ implementado y verificado aquí · 🟡 implementado, falta validarlo en Roblox Studio · ⬜ pendiente

| # | Criterio | Código Roblox | Verificación disponible hoy |
|---|---|---|---|
| 1 | Iniciar una partida desde cero | 🟡 `PlayerDataService` + `ProfileSchema.new` | ✅ Lune: cuenta nueva por cada inicial · ✅ vista previa web |
| 2 | Aparecer en Valle Copal | 🟡 `ValleBuilder` + `SpawnLocation` | ✅ vista previa (misma distribución `Config/World`) |
| 3 | Recibir la introducción (saltable) | 🟡 `Modals.intro` | ✅ vista previa (saltar y completar) |
| 4 | Elegir entre Kuachi, Xolumi y Teselo | 🟡 prompts + `Hatch.ChooseStarter` (proximidad) | ✅ Lune (3 iniciales) · ✅ vista previa |
| 5 | Obtener el monstruo correspondiente | 🟡 `Actions.chooseStarter` | ✅ Lune |
| 6 | Ver la eclosión | 🟡 tarjeta de eclosión (sin cinemática 3D en Roblox aún) | ✅ vista previa (huevo que se eleva, tiembla y se abre) |
| 7 | Tenerlo como acompañante | 🟡 `WorldController` (seguimiento suave, terreno, reaparición) | ✅ vista previa |
| 8 | Acceder al Lote Hogar | 🟡 `Sanctuary.Visit` (proximidad) + regalo | ✅ Lune · ✅ vista previa |
| 9 | Consultar el inventario | 🟡 ficha del santuario (Vivero x/40) | ✅ vista previa |
| 10 | Alimentar al monstruo | 🟡 `Care.Feed` | ✅ Lune (sin comida, mascota ajena) · ✅ vista previa |
| 11 | Obtener experiencia y Vínculo | 🟡 `Care.Play`, comida de bioma | ✅ Lune (curva verificada contra la Biblia) |
| 12 | Iniciar y completar el primer combate PvE | 🟡 `BattleService` + `BattleController` | ✅ Lune (motor + 300 simulaciones por inicial) · ✅ vista previa · ✅ paridad Luau↔JS |
| 13 | Recibir una recompensa | 🟡 `Reward.Claim` | ✅ Lune (idempotencia, procedencia) · ✅ vista previa |
| 14 | Desconectarse y regresar sin perder progreso | 🟡 `ProfileStore` + `PlayerDataService` | ✅ Lune (reconexión, recompensa pendiente, bloqueo) · ✅ vista previa (recarga) |
| 15 | Interfaz funcional en móvil | 🟡 UI con `UIScale`, botones ≥ 48 px | ✅ vista previa en 390×844 |

Requisitos transversales: economía y progresión autoritativas en el servidor ✅ (diseño + pruebas de
reglas); proyecto organizado y documentado ✅; provisionales distinguidos de aprobados ✅
(`AssetStatus = "Blockout"`); ruta a la Fase 2 ✅ (`docs/ROADMAP.md`). **Sin errores críticos
conocidos** depende de la primera sesión en Studio (`tests/Playtest/STUDIO_PLAYTEST.md`).

## Contenido incluido
- **Mundo:** Valle Copal compacto: plaza de copal, Gran Nexo (menú físico y radial), tres huevos, Despensa, estaciones reservadas con señalización, Mirador con las cuatro puertas de bioma selladas, río con chinampas y puentes, 6 Lotes Hogar, Linde de las Chinampas con 3 Opacos.
- **Especies jugables:** 3 iniciales + 5 rivales (Agavo, Comalú, Zizi, Barrock, Vainas). Las 50 especies están en datos (Álbum con siluetas en la vista previa).
- **Combate:** 1v1 por turnos simultáneos, Savia, 2 básicos + 1 especial + Firma (+ Golpe Nexo en Tallado nv 20), estados, talentos, IA tutorial/normal, ventajas elementales ×1.25/×0.85.
- **Progresión:** XP y nivel, Vínculo con corazones, próximo objetivo visible, Tallado a nivel 12 con 2 corazones.
- **Santuario:** Lote Hogar, 1 hábitat de 4 lugares, Vivero 40, producción de Monedas y XP pasiva por tiempo de servidor con tope de 8 h.
- **Economía:** Monedas ganadas; Gemas solo por logros deterministas; Despensa de precio fijo. Sin Robux, sin aleatoriedad pagada.
- **Analítica:** embudo de onboarding completo (12 pasos) y eventos de sesión, guardado, combate, recogida y desbloqueo.
- **Modo de desarrollador:** XP ×10 y Monedas ×5 solo en Studio o lista blanca; nunca en producción.

## Fuera de la Fase 1 (preparado, no construido)
Cinco biomas completos · 50 modelos finales · seis actos y guardianes · Guardianes Velados · crianza y 42 recetas · incubadora · cofres · Arena 1v1/2v2 y torneos · intercambio · gremios · suscripción · tienda con Robux · eventos comerciales · vitrina · decoración.
