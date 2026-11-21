--!strict
-- Primeros 15 minutos (Biblia v5.0 p. 110) adaptados al vertical slice.
-- "Nunca más de una ventana de tutorial a la vez" y "cada sistema se explica cuando
-- el jugador lo necesita". La introducción se puede saltar.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type StepId =
	"Intro"
	| "ChooseEgg"
	| "Hatch"
	| "MeetHome"
	| "PlaceInHabitat"
	| "FirstFeed"
	| "FirstBond"
	| "FirstBattle"
	| "ClaimReward"
	| "Done"

local Steps: { { id: StepId, objective: string, hint: string } } = {
	{ id = "Intro", objective = "El sueño del Tallador", hint = "Toca para continuar o salta la introducción." },
	{ id = "ChooseEgg", objective = "Elige tu huevo", hint = "Acércate a los tres huevos junto al Gran Nexo." },
	{ id = "Hatch", objective = "¡Está naciendo!", hint = "Tu Brote está saliendo del huevo." },
	{ id = "MeetHome", objective = "Visita tu Lote Hogar", hint = "Sigue la luz de copal hasta tu lote." },
	{ id = "PlaceInHabitat", objective = "Dale un hogar", hint = "Coloca a tu Brote en el hábitat y recoge Monedas." },
	{ id = "FirstFeed", objective = "Aliméntalo", hint = "Abre su ficha y dale una Ración." },
	{ id = "FirstBond", objective = "Juega con él", hint = "Toca a tu monstruo para jugar y subir el Vínculo." },
	{
		id = "FirstBattle",
		objective = "Restaura al primer Opaco",
		hint = "Ve a la Linde de las Chinampas: una niebla gris apagó a un monstruo.",
	},
	{ id = "ClaimReward", objective = "Reclama tu recompensa", hint = "El valle recupera el color." },
	{ id = "Done", objective = "Explora el Valle Copal", hint = "Cuida, entrena y talla a tu Brote." },
}

-- Tres huevos de copal visualmente equivalentes (p. 4 y 27). El jugador no ve la
-- especie antes de elegir; solo un pulso de color al acercarse.
local StarterEggs = {
	{ eggId = "EggBrasa", speciesId = "kuachi", pulseColor = { 236, 112, 50 }, cue = "brasa" },
	{ eggId = "EggBarro", speciesId = "xolumi", pulseColor = { 64, 170, 214 }, cue = "barro" },
	{ eggId = "EggGreca", speciesId = "teselo", pulseColor = { 196, 154, 90 }, cue = "greca" },
}

return Freeze.deep({
	Steps = Steps,
	StarterEggs = StarterEggs,
	StarterLevel = 1,
	-- Tras eclosionar se comunica que los otros dos se podrán conseguir después (p. 4).
	OtherStartersMessage = "Los otros dos huevos volverán a aparecer más adelante en tu aventura.",
	MaxNicknameLength = 16,
})
