--!strict
-- Progresión (Biblia v5.0 p. 35 y 115).
-- DEFINIDO: curva 40 × L^1.5, tope 50, escala de atributos 0.4 + 0.012 × nivel,
--           Brote al 70 %, Tallado Común a nivel 12, Golpe Nexo a nivel 20 en Tallado.
-- PROVISIONAL (D-006): escala del Vínculo; la Biblia no define tope ni niveles.

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	LevelCap = 50,
	-- XP necesaria para pasar del nivel L al L+1 = XpBase × L ^ XpExponent
	XpBase = 40,
	XpExponent = 1.5,

	-- Atributo en combate = base × FormFactor × (LevelScaleBase + LevelScalePerLevel × nivel)
	LevelScaleBase = 0.4,
	LevelScalePerLevel = 0.012,
	FormFactor = {
		Brote = 0.7,
		Tallado = 1.0,
	},
	-- Puntos de golpe = VID efectiva × HpPerVid (VID × 10 a nivel 50, p. 35)
	HpPerVid = 10,

	-- Desbloqueos por nivel
	NexoUnlockLevel = 20, -- y solo en Tallado
	BreedingUnlockLevel = 10, -- fuera de Fase 1

	-- Vínculo (PROVISIONAL): puntos enteros; los niveles se muestran como corazones.
	Bond = {
		Max = 100,
		-- Umbral acumulado para cada corazón (0 = sin corazón)
		Thresholds = { 3, 8, 15, 25, 40, 60, 80, 100 },
		PlayCooldownSeconds = 45,
		PlayGain = 1,
		-- Vínculo necesario para Tallar (PROVISIONAL, D-007): el Tallado se gana cuidando.
		TallarRequiredHearts = 2,
	},
})
