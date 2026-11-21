--!strict
-- Economía de la Fase 1 (Biblia v5.0 p. 91–93 y 115).
-- Regla Genesis: sin ventas reales, sin cofres aleatorios, sin productos de Robux.
-- Las Gemas existen en el perfil (moneda premium separada) pero solo se obtienen por
-- logros deterministas en esta fase. Nunca se convierten Gemas <-> Monedas.

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	Currencies = {
		Monedas = { id = "Monedas", name = "Monedas", premium = false },
		Gemas = { id = "Gemas", name = "Gemas", premium = true },
	},
	StartingBalance = { Monedas = 0, Gemas = 0 },
	MaxBalance = { Monedas = 1e12, Gemas = 1e9 },

	-- Alimentos (p. 93 y 115). DEFINIDO en precio y XP; el Vínculo de la Ración básica
	-- no aparece en la tabla (0). Ración Dorada es de Gemas: no se vende en Fase 1.
	Foods = {
		RacionBasica = {
			id = "RacionBasica",
			name = "Ración básica",
			xp = 150,
			bond = 0,
			price = { Monedas = 50 },
			sold = true,
		},
		RacionBioma = {
			id = "RacionBioma",
			name = "Ración de bioma",
			xp = 600,
			bond = 1,
			price = { Monedas = 220 },
			sold = true,
		},
		Festin = { id = "Festin", name = "Festín", xp = 2500, bond = 1, price = { Monedas = 900 }, sold = true },
		RacionDorada = {
			id = "RacionDorada",
			name = "Ración Dorada",
			xp = 4000,
			bond = 2,
			price = { Gemas = 30 },
			sold = false,
		},
	},
	FoodOrder = { "RacionBasica", "RacionBioma", "Festin", "RacionDorada" },
	MaxItemStack = 999,
	MaxPurchaseQuantity = 10,

	-- Producción del hábitat (p. 92 y 115)
	Habitat = {
		BroteProductionFactor = 0.5, -- los Brotes producen el 50 % hasta tallarse
		OfflineCapSeconds = 8 * 3600,
		PassiveXpPerMinute = 2, -- "Hábitat (por minuto): 2 XP" (lectura de p. 115)
		CollectMinimum = 1, -- no se registra una recogida de 0 Monedas
	},
})
