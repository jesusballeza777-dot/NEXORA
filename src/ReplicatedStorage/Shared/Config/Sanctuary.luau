--!strict
-- Santuario (Biblia v5.0 p. 5/7/8): Lote Hogar gratis con inventario (Vivero),
-- 1 hábitat de 4 slots y vitrina de 3 Tallados. En Fase 1 solo se implementa el
-- Lote Hogar; los demás lotes quedan declarados para que la arquitectura los admita.

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	InventoryCapacity = 40, -- ampliable +10 por 5 000 Monedas hasta 100 (fuera de Fase 1)
	InventoryMaxCapacity = 100,
	-- Ampliación del Vivero: +10 lugares por 5 000 Monedas (p. 30)
	InventoryExpansion = { step = 10, price = { Monedas = 5000 } },
	SlotsPerHabitat = 4,
	VitrinaSlots = 3,
	MaxCompanions = 1, -- la arquitectura admite más; el prototipo muestra uno (Genesis 6.D)
	MaxTeamSize = 3,

	Lots = {
		Hogar = {
			id = "Hogar",
			name = "Lote Hogar",
			biome = "ValleCopal",
			price = nil,
			unlock = "Inicio",
			habitats = { "Hogar_H1" },
			hasVitrina = true,
			implemented = true,
		},
		Valle = {
			id = "Valle",
			name = "Lote del Valle",
			biome = "ValleCopal",
			price = { Monedas = 2500 },
			unlock = "Capitulo1",
			habitats = { "Valle_H1" },
			implemented = false,
		},
		Marea = {
			id = "Marea",
			name = "Lote de la Marea",
			biome = "MareaCoralina",
			price = { Monedas = 10000 },
			unlock = "ActoI",
			habitats = { "Marea_H1" },
			implemented = false,
		},
		Cumbre = {
			id = "Cumbre",
			name = "Lote de la Cumbre",
			biome = "CumbreBrasa",
			price = { Monedas = 40000 },
			unlock = "ActoII",
			habitats = { "Cumbre_H1" },
			implemented = false,
		},
		Fulgor = {
			id = "Fulgor",
			name = "Lote del Fulgor",
			biome = "MesetaFulgor",
			price = { Monedas = 150000 },
			unlock = "ActoIII",
			habitats = { "Fulgor_H1" },
			implemented = false,
		},
		Velo = {
			id = "Velo",
			name = "Lote del Velo",
			biome = "VeloAstral",
			price = { Monedas = 300000 },
			unlock = "ActoIV",
			habitats = { "Velo_H1" },
			implemented = false,
		},
	},
	NativeBonus = { coins = 0.10, xp = 0.10 }, -- nativos en su bioma de origen
})
