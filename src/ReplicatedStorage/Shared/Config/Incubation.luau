--!strict
-- Huevos e incubadora (Biblia compacta p. 27, 11 y 102).
-- * Tiempos por rareza: 5 min · 20 min · 2 h · 8 h · 24 h · 72 h (HECHO en la v5).
-- * El Criadero tiene de 1 a 5 ranuras. Precios de la Biblia: 3.ª ranura 25 000 Monedas
--   (permanente); 4.ª ranura 400 Gemas (permanente); el pase daría +1 mientras está activo.
-- * La 2.ª ranura no tiene coste en la Biblia: PROPUESTA (D-025) desbloquearla al terminar
--   la Región 1 del Acto I, para que la incubación doble llegue jugando.
-- * Fase 2: sin aceleraciones con Gemas ni compras reales (Genesis F2 §8.4). La 4.ª y la
--   5.ª ranura quedan declaradas pero no disponibles en la beta.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type SlotRule = {
	slot: number,
	unlock: "Start" | "Story" | "Monedas" | "Gemas" | "Pass",
	ref: string?,
	price: { [string]: number }?,
	availableInBeta: boolean,
	label: string,
}

return Freeze.deep({
	SecondsByRarity = {
		Comun = 5 * 60,
		Raro = 20 * 60,
		Epico = 2 * 3600,
		Legendario = 8 * 3600,
		Unico = 24 * 3600,
		Misterio = 72 * 3600,
	},
	MaxSlots = 5,
	Slots = {
		{ slot = 1, unlock = "Start", availableInBeta = true, label = "Incluida con el Lote Hogar" },
		{
			slot = 2,
			unlock = "Story",
			ref = "region:ActoI:1",
			availableInBeta = true,
			label = "Al completar la Región 1 del Acto I",
		},
		{
			slot = 3,
			unlock = "Monedas",
			price = { Monedas = 25000 },
			availableInBeta = true,
			label = "25 000 Monedas (permanente)",
		},
		{
			slot = 4,
			unlock = "Gemas",
			price = { Gemas = 400 },
			availableInBeta = false,
			label = "400 Gemas (permanente) · no disponible en la beta",
		},
		{
			slot = 5,
			unlock = "Pass",
			availableInBeta = false,
			label = "Pase del Nexo · no disponible en la beta",
		},
	} :: { SlotRule },
	-- Huevos guardados sin incubar (PROPUESTA: suficiente para varios días de cofres)
	EggStorageCapacity = 24,
	-- Grietas de luz del huevo flotante (p. 102, pregunta abierta: se implementan)
	CrackStages = { 0.25, 0.5, 0.75 },
})
