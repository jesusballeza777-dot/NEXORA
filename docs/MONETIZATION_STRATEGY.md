# NEXORA · Estrategia de monetización (futura)

**En la Fase 1 no hay ninguna venta.** Este documento define cómo será rentable sin romper la
diversión ni la confianza, y qué debe ocurrir antes de activar cualquier producto.

## 1. Principios
1. **Diversión antes que monetización.** Todo el progreso principal se consigue sin pagar (Biblia p. 98: "el que paga llega antes, pero el que no paga llega").
2. **Vender identidad, no superioridad.** Ninguna compra da ventaja competitiva decisiva; no se venden niveles ni XP permanente.
3. **Transparencia total.** Lo que se compra se ve antes de comprarlo ("lo que ves es lo que te llevas").
4. **Sin presión.** Sin temporizadores agresivos, "último aviso", precios tachados falsos ni exclusividad que obligue a entrar a diario (p. 12).
5. **Público joven (9+).** Cumplimiento de Roblox antes que ingresos.

## 2. Dos monedas, funciones separadas
| | Monedas | Gemas |
|---|---|---|
| Se obtienen | Jugando: hábitats, victorias, encargos, historia | Logros; en el futuro, paquetes de Robux |
| Se gastan | Comida, accesorios básicos, Vitrina (especie visible), lotes, mejoras | Cosméticos premium, aceleración de incubación, huevos de especie visible |
| Conversión | **Nunca** Gemas → Monedas ni Robux → Monedas directas | — |
Las Gemas nunca mejoran probabilidades ni producen Monedas (p. 94).

## 3. Productos prioritarios (contenido fijo y visible)
1. **Auras y efectos de evolución** (el Tallado es el momento emocional del juego).
2. **Accesorios** visibles en santuario y combate (rebozos, alas de papel, estelas).
3. **Decoración y personalización del Lote** (plantillas + objetos libres, p. 25).
4. **Animaciones, emotes y marcos de colección** del Álbum.
5. **Paquetes temáticos de contenido fijo** (p. ej. "Paquete de bienvenida": Gemas + accesorio + raciones, una vez).
6. **Círculo del Tallador** (suscripción mensual): se conserva la idea de la Biblia, pero **se pospone** hasta tener contenido suficiente y evidencia de retención. Contenido fijo y calendario visible.

## 4. Lo que NO se implementa al inicio
Cofres aleatorios comprados con Robux · huevos pagados con resultado aleatorio · potenciadores de suerte · mejoras de probabilidad · aleatoriedad financiada indirectamente con Robux · intercambio de artículos pagados.

## 5. Cumplimiento antes de vender (revisar la política vigente al implementar)
- `PolicyService:GetPolicyInfoForPlayerAsync` → `ArePaidRandomItemsRestricted` e `IsPaidItemTradingAllowed`. **Nunca** codificar listas de países.
- Divulgación de probabilidades por premio y por especie antes de comprar, con botón "Detalles"; tablas que sumen 100 % y se recalculen por jugador cuando cambie la colección.
- Alternativa para regiones restringidas: cofres solo ganados, Vitrina de huevos fijos, mezcla sin cuota.
- **Pase y Monedas (P66):** si el pase da Monedas, todo lo aleatorio que se compra con Monedas pasa a ser Paid Random Item. Recomendación: opción **B** (pase sin Monedas) — ver `DESIGN_DECISIONS.md` D-015.
- Compras: `MarketplaceService.ProcessReceipt` **idempotente y persistente**: registrar `PurchaseId` en el perfil a través de `RewardRules` antes de devolver `PurchaseGranted`; si el perfil no está cargado o el guardado falla, devolver `NotProcessedYet`.
- Intercambio (Fase 2+): cada monstruo guarda si provino de una compra (`acquired.kind`).

## 6. Medición (no inventar cifras)
Instrumentado desde la Fase 1 (`AnalyticsTracker`): embudo de onboarding, primera recompensa, combates, recogidas, desbloqueos, sesión y guardado.
Cuando haya tráfico suficiente, usar **Creator Analytics** y cohortes reales para: retención D1/D7/D30, duración media de sesión, finalización del onboarding, DAU/WAU/MAU, conversión de pagadores, ARPPU, ingresos y origen de jugadores.

Metas de la Biblia que deben **validarse**, no asumirse: 85 % llega al primer combate, 50 % vuelve al día siguiente (p. 110), 5–7 % de pagadores y 4–6 % de suscriptores (p. 97–98).

**Puerta para activar ventas:** onboarding y retención D1/D7 medidos en un soft launch, economía revisada con datos reales, política de Roblox revisada y autorización explícita del equipo. Sin adquisición masiva antes de validar la retención.
