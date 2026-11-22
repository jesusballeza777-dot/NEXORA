--!strict
-- El Gabinete que Camina (Biblia compacta p. 13–15): ceremonioso, coleccionista y
-- bromista. Habla por cajones (cada cajón tiene su voz) y nunca miente sobre lo que hay
-- dentro. REGLA DEL CAJÓN ABIERTO: todo lo que dé con azar enseña antes la lista completa
-- de premios y porcentajes; sin esa pantalla no hay botón.
-- Las tres primeras frases son literales de la Biblia; las marcadas PROPUESTA siguen su
-- voz para las estaciones nuevas de la Fase 2 (sin ventas: la beta no vende nada).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	Personality = "Ceremonioso, coleccionista y bromista. Habla por cajones: cada cajón tiene su voz. Nunca miente sobre lo que hay dentro.",
	Lines = {
		-- Biblia (literales)
		Fixed = "Este cajón guarda un huevo de %s. Lo que ves es lo que te llevas.",
		Odds = "Mis cofres sí tienen sorpresa, así que te enseño los números antes.",
		Care = "¿Otro cofre? Primero tu Vínculo; tus monstruos tienen hambre.",
		-- PROPUESTA (misma voz)
		Shelf = "Cajón de los premios ganados: aquí no se vende nada, solo se abre lo que ya es tuyo.",
		Pantry = "Cajón de la Despensa: comida honesta, precio honesto. Ni una Moneda de más.",
		Empty = "Este cajón está vacío… por ahora. Los Opacos del Valle guardan cofres que esperan dueño.",
	},
})
