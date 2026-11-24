--!strict
-- Movimiento de las criaturas (Genesis §8; docs/ANIMATION_SYSTEM.md):
-- * Families: animación procedural por familia anatómica.
-- * Species: personalidad de los tres iniciales (el resto toma los valores de su familia).
-- * States: la máquina de estados de Client/Animation/MotionStateMachine.
-- * Follow: seguimiento del acompañante (Shared/Domain/FollowSteering).
-- Ángulos en radianes, distancias en studs (escala del Brote; se multiplican por la escala
-- de la forma), frecuencias en Hz. Valores de partida para ajustar en Studio.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type FamilyId =
	"QuadrupedAgile"
	| "QuadrupedHeavy"
	| "Amphibian"
	| "ArmoredReptile"
	| "Bird"
	| "Floating"
	| "Biped"

local Families = {
	QuadrupedAgile = {
		id = "QuadrupedAgile",
		name = "Cuadrúpedo ágil",
		gait = "Trot", -- diagonales a la vez (FL+BR, FR+BL)
		walkRef = 6, -- velocidad a la que el paso va a stepHz
		runSpeed = 11,
		stepHz = 2.6,
		stride = 0.55,
		bob = 0.05,
		runBob = 0.14,
		plant = 0,
		pitchRun = 0.08,
		breathHz = 0.45,
		breathAmp = 0.025,
		headYaw = 0.9,
		headPitch = 0.4,
		headSpeed = 7,
		tailAmp = 0.35,
		tailHz = 1.4,
		lean = 0.22,
		jumpHeight = 1.4,
		landSquash = 0.08,
		hover = 0,
		wingAmp = 0,
		wingHz = 0,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0,
		idleAlt = { min = 6, max = 12, variants = { "LookAround", "Sniff", "Shake" } },
	},
	QuadrupedHeavy = {
		id = "QuadrupedHeavy",
		name = "Cuadrúpedo pesado",
		gait = "Plod", -- una pata cada vez, apoyos largos
		walkRef = 5,
		runSpeed = 10,
		stepHz = 1.5,
		stride = 0.35,
		bob = 0.025,
		runBob = 0.06,
		plant = 0.04, -- hundimiento del cuerpo al apoyar
		pitchRun = 0.04,
		breathHz = 0.3,
		breathAmp = 0.03,
		headYaw = 0.5,
		headPitch = 0.3,
		headSpeed = 3.5,
		tailAmp = 0.15,
		tailHz = 0.8,
		lean = 0.08,
		jumpHeight = 0.6,
		landSquash = 0.12,
		hover = 0,
		wingAmp = 0,
		wingHz = 0,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0,
		idleAlt = { min = 10, max = 18, variants = { "LookAround", "Rest" } },
	},
	Amphibian = {
		id = "Amphibian",
		name = "Anfibio",
		gait = "Sprawl", -- patas abiertas y ondulación del cuerpo
		walkRef = 5,
		runSpeed = 10,
		stepHz = 1.8,
		stride = 0.45,
		bob = 0.02,
		runBob = 0.05,
		plant = 0,
		pitchRun = 0.03,
		breathHz = 0.35,
		breathAmp = 0.03,
		headYaw = 0.6,
		headPitch = 0.3,
		headSpeed = 4,
		tailAmp = 0.4,
		tailHz = 1.0,
		lean = 0.1,
		jumpHeight = 0.8,
		landSquash = 0.1,
		hover = 0,
		wingAmp = 0,
		wingHz = 0,
		gillAmp = 0.25,
		gillHz = 0.6,
		undulate = 0.18,
		idleAlt = { min = 8, max = 14, variants = { "GillPulse", "LookAround", "Rest" } },
	},
	ArmoredReptile = {
		id = "ArmoredReptile",
		name = "Reptil acorazado",
		gait = "Plod",
		walkRef = 4,
		runSpeed = 9,
		stepHz = 1.2,
		stride = 0.3,
		bob = 0.015,
		runBob = 0.03,
		plant = 0.05,
		pitchRun = 0.02,
		breathHz = 0.25,
		breathAmp = 0.02,
		headYaw = 0.5,
		headPitch = 0.25,
		headSpeed = 3,
		tailAmp = 0.1,
		tailHz = 0.6,
		lean = 0.04,
		jumpHeight = 0.4,
		landSquash = 0.14,
		hover = 0,
		wingAmp = 0,
		wingHz = 0,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0,
		defend = "Retreat", -- se resguarda en el caparazón
		idleAlt = { min = 10, max = 20, variants = { "LookAround", "Retreat" } },
	},
	Bird = {
		id = "Bird",
		name = "Ave",
		gait = "Hop", -- saltitos con las dos patas
		walkRef = 6,
		runSpeed = 12,
		stepHz = 3.2,
		stride = 0.3,
		bob = 0.12,
		runBob = 0.2,
		plant = 0,
		pitchRun = 0.12,
		breathHz = 0.5,
		breathAmp = 0.02,
		headYaw = 1.1,
		headPitch = 0.45,
		headSpeed = 9,
		tailAmp = 0.2,
		tailHz = 1.6,
		lean = 0.2,
		jumpHeight = 1.6,
		landSquash = 0.06,
		hover = 0,
		wingAmp = 0.5,
		wingHz = 6,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0,
		idleAlt = { min = 5, max = 10, variants = { "LookAround", "Preen", "Flap" } },
	},
	Floating = {
		id = "Floating",
		name = "Flotante",
		gait = "Hover", -- flota y se inclina hacia donde va
		walkRef = 6,
		runSpeed = 12,
		stepHz = 0,
		stride = 0.15,
		bob = 0,
		runBob = 0,
		plant = 0,
		pitchRun = 0.2,
		breathHz = 0.4,
		breathAmp = 0.03,
		headYaw = 0.8,
		headPitch = 0.4,
		headSpeed = 6,
		tailAmp = 0.3,
		tailHz = 1.2,
		lean = 0.3,
		jumpHeight = 0.8,
		landSquash = 0,
		hover = 0.18,
		hoverHz = 0.8,
		hoverHeight = 0.5,
		wingAmp = 0.35,
		wingHz = 9,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0.05,
		idleAlt = { min = 6, max = 12, variants = { "LookAround", "Loop" } },
	},
	Biped = {
		id = "Biped",
		name = "Bípedo",
		gait = "Stride",
		walkRef = 6,
		runSpeed = 11,
		stepHz = 2.0,
		stride = 0.5,
		bob = 0.05,
		runBob = 0.1,
		plant = 0,
		pitchRun = 0.06,
		breathHz = 0.4,
		breathAmp = 0.03,
		headYaw = 0.8,
		headPitch = 0.35,
		headSpeed = 5,
		tailAmp = 0.2,
		tailHz = 1.0,
		lean = 0.12,
		jumpHeight = 1.2,
		landSquash = 0.1,
		hover = 0,
		wingAmp = 0,
		wingHz = 0,
		gillAmp = 0,
		gillHz = 0,
		undulate = 0,
		idleAlt = { min = 7, max = 13, variants = { "LookAround", "Shake" } },
	},
}

-- Personalidad de los tres iniciales (Genesis §8 y dosieres de docs/art/dossiers).
-- tempo multiplica las frecuencias; inertia divide la aceleración del seguimiento.
local SpeciesMotion = {
	kuachi = {
		family = "QuadrupedAgile",
		trait = "Curioso, rápido e inquieto: olfatea, mueve la cola en espiral y a veces se hace el muerto al jugar.",
		tempo = 1.2,
		inertia = 0.8,
		tailSpiral = true,
		tailAmp = 0.45,
		sniffHz = 7,
		playDead = { chance = 0.35, duration = 2.4 },
		idleAlt = { min = 3, max = 6, variants = { "Sniff", "LookAround", "Sniff", "TailCurl" } },
	},
	xolumi = {
		family = "Amphibian",
		trait = "Calmado: ondulación anfibia, branquias que laten y pausas largas.",
		tempo = 0.8,
		inertia = 1.2,
		gillHz = 0.5,
		gillAmp = 0.3,
		undulate = 0.25,
		pause = { every = { 4, 8 }, duration = { 0.8, 1.6 } }, -- se para un momento al pasear
		idleAlt = { min = 9, max = 16, variants = { "GillPulse", "Rest", "LookAround" } },
	},
	teselo = {
		family = "ArmoredReptile",
		trait = "Pesado: inercia, apoyos firmes y se resguarda en el caparazón para defenderse.",
		tempo = 0.75,
		inertia = 1.8,
		plant = 0.07,
		defend = "Retreat",
		idleAlt = { min = 12, max = 22, variants = { "LookAround", "Retreat" } },
	},
}

-- Familia de Config/Species → familia de movimiento. PROPUESTA (docs/ANIMATION_SYSTEM.md):
-- los Cuadrúpedos Defensores o Brutos se mueven como pesados.
local FamilyBySpecies: { [string]: FamilyId } = {
	["Cuadrúpedo"] = "QuadrupedAgile",
	["Anfibio"] = "Amphibian",
	["Reptil"] = "ArmoredReptile",
	["Serpentino"] = "Amphibian",
	["Ave"] = "Bird",
	["Volador"] = "Bird",
	["Acuático → Ave"] = "Bird",
	["Insecto"] = "Floating",
	["Fantasmal"] = "Floating",
	["Acuático"] = "Floating",
	["Astral"] = "Floating",
	["Bípedo"] = "Biped",
	["Primate"] = "Biped",
	["Constructo"] = "Biped",
	["Objeto animado"] = "Biped",
	["Planta"] = "QuadrupedHeavy",
	["Arácnido"] = "QuadrupedAgile",
	["Quimera"] = "QuadrupedAgile",
}
local HeavyRoles = { Defensor = true, Bruto = true }
local GuardianFamily: { [string]: FamilyId } = { copalia = "Bird" }

local States = {
	"Idle",
	"IdleAlt",
	"Walk",
	"Run",
	"Turn",
	"Stop",
	"Jump",
	"Fall",
	"Land",
	"Interact",
	"Eat",
	"Happy",
	"Curious",
	"Warn",
	"Hurt",
	"Stun",
	"Victory",
	"Defeat",
	"Attack",
	"Special",
	"Nexo",
}

-- Duración por defecto de los estados de un solo uso (el combate pasa la suya)
local OneShot = {
	Interact = 1.2,
	Eat = 1.6,
	Happy = 1.0,
	Curious = 1.4,
	Warn = 1.2,
	Hurt = 0.45,
	Attack = 0.8,
	Special = 1.0,
	Nexo = 2.6,
	Victory = 1.6,
	Defeat = 1.4,
	Stun = 1.0,
	Land = 0.22,
	Stop = 0.28,
}

local IdleAltDuration = {
	LookAround = 2.2,
	Sniff = 1.6,
	Shake = 0.8,
	Rest = 3.0,
	GillPulse = 2.0,
	Retreat = 2.4,
	TailCurl = 1.4,
	Preen = 1.6,
	Flap = 1.0,
	Loop = 1.8,
	PlayDead = 2.4,
}

-- Umbrales con histéresis (studs/s y rad/s)
local Thresholds = {
	walkEnter = 0.6,
	walkExit = 0.3,
	runExitFactor = 0.85,
	stopFrom = 4, -- solo hay frenada si iba al menos a esta velocidad
	turnEnter = 1.6,
	turnExit = 0.8,
	jumpEnter = 2.5,
	fallEnter = -2.5,
	landMinAir = 0.15,
	gravity = 60,
}

-- Seguimiento del acompañante (FollowSteering)
local Follow = {
	back = 4.4, -- detrás del jugador (distancia al sitio ≈ 5,1)
	side = 2.6, -- a un lado
	minDistance = 4,
	maxDistance = 6,
	personalRadius = 2.6, -- nunca entra en este radio alrededor del jugador
	arriveRadius = 0.7, -- llega al slot y descansa
	resumeRadius = 2.2, -- histéresis: vuelve a moverse si se aleja más que esto
	catchUp = 14, -- a más distancia corre
	catchUpExit = 8,
	maxSpeed = 22, -- el jugador anda a 16
	catchUpSpeed = 28,
	accel = 34,
	decel = 90,
	comfortBrake = 3, -- frenada ×3 si se acerca por debajo de minDistance + 0,5 hacia el jugador
	turnRate = 7,
	gain = 2.4,
	teleport = 60, -- solo se teletransporta por encima de esta distancia
	sideSwitch = 1.5, -- cambia de lado solo si queda claramente al otro
	probeInterval = 0.12, -- rayos de obstáculos 8 veces por segundo
	probeLength = 3,
	whiskers = { 35, 70 },
	avoidHold = 0.5,
	bodyRadius = 0.6,
	farInterval = 0.25, -- acompañantes lejos de la cámara: 4 pasos por segundo, sin rayos
}

return Freeze.deep({
	Families = Families,
	Species = SpeciesMotion,
	FamilyBySpecies = FamilyBySpecies,
	HeavyRoles = HeavyRoles,
	GuardianFamily = GuardianFamily,
	States = States,
	OneShot = OneShot,
	IdleAltDuration = IdleAltDuration,
	Thresholds = Thresholds,
	Follow = Follow,
})
