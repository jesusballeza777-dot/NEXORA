--!strict
-- Reglas de combate (Biblia v5.0 p. 32–34 y 40).
-- Ver docs/DESIGN_DECISIONS.md: D-001 (multiplicadores), D-002 (escala de daño por
-- nivel), D-003 (crítico/variación/precisión), D-004 (turno simultáneo en PvE).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	-- Hipótesis de beta exigida por Project Genesis; la Biblia mantiene ×1.5/×0.75
	-- "hasta confirmación" (pregunta 48). Cambiar aquí basta para comparar.
	Element = {
		Strong = 1.25,
		Weak = 0.85,
		Neutral = 1.0,
		-- Topes con defensores de 2–3 elementos (recomendación p. 32 para ×1.25/×0.85)
		Cap = 1.6,
		Floor = 0.7,
		-- El Golpe Nexo ignora el suelo bajo: nunca baja de Weak (p. 34)
		NexoFloor = 0.85,
		Affinity = 1.2, -- el ataque comparte elemento con el atacante (p. 34/40)
	},

	-- Fórmula p. 40: Daño = Poder × A/(A+D) × 2 × Elemento × Afinidad × Variación × Crítico
	DamageRatioMultiplier = 2,
	VarianceMin = 0.95,
	VarianceMax = 1.05,
	CritChance = 0.05,
	CritMultiplier = 1.5,
	BaseAccuracy = 1.0, -- la fórmula de p. 40 no incluye fallo base (D-003)
	MinAccuracy = 0.35,
	MaxEvasion = 0.5,

	-- D-002: el daño escala con el nivel/forma del atacante para que los PV (que sí
	-- escalan) mantengan "3 a 5 acciones" en cualquier nivel.
	ScaleDamageByAttackerLevel = true,

	-- Savia (p. 40)
	Savia = {
		Start = 0,
		Max = 3,
		BasicGain = 1,
		SpecialCost = 2,
		NexoCost = 3,
		NexoUsesPerBattle = 1,
	},

	-- Estados (p. 36–38)
	Status = {
		Burn = { damagePercent = 0.05, defaultTurns = 3 },
		Paralysis = { defaultTurns = 1 },
		Stun = { defaultTurns = 1 },
		Sleep = { defaultTurns = 1 },
		Confuse = { defaultTurns = 1, selfHitChance = 0.33, selfHitPower = 30 },
	},

	-- Turnos (p. 39–40). En PvE de historia no hay temporizador de turno.
	TurnSeconds = 20,
	MaxTurns = 30, -- límite de seguridad del motor; al agotarse gana quien tenga más % de PV
	PriorityMax = 99,

	-- Repertorio equipable (p. 36): 2 básicos + 1 especial + Firma (+ Golpe Nexo en Tallado nv 20)
	Loadout = {
		Basics = 2,
		Specials = 1,
	},

	-- El aura baja al 60 % en combate (p. 26)
	AuraBattleIntensity = 0.6,
})
