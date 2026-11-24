--!strict
-- Catálogo de señales de sonido (solo la ESTRUCTURA: no hay audio aprobado).
-- Todas las señales tienen assetId = nil y status = "Pending": Client/Audio/SoundController
-- no reproduce nada hasta que una persona apruebe un audio real y escriba su ID aquí.
-- NUNCA se inventan IDs (rbxassetid).
--
-- Convención de ids:
-- * SFX_<Elemento>_<Fase>   Cast · Travel · Impact (los 12 elementos de Config/Elements)
-- * SFX_Combat_<Evento>     Hit · Crit · Shield · Heal · Burn · Paralyze · Stun · Reflect ·
--                           Victory · Defeat · NexoCharge
-- * SFX_CR_<especie>_<acción>  kuachi, xolumi y teselo: Idle · Move · Happy · Hurt ·
--                           Attack · Special · Evolve · Victory
-- * AMB_<Bioma>_<Capa>      ambiente por capas de cada bioma (Config/Species.Biomes)
-- * MUS_<Bioma>_<Estado>    Explore · Battle · Boss · Victory
-- * SFX_UI_<Acción>         interfaz

local Freeze = require(script.Parent.Parent.Util.Freeze)
local Elements = require(script.Parent.Elements)
local Species = require(script.Parent.Species)

export type Category = "Ambient" | "Music" | "Creature" | "Combat" | "UI" | "World"

export type Cue = {
	id: string,
	category: Category,
	assetId: string?,
	volume: number,
	rollOffMaxDistance: number?, -- sonido espacial (nil = sonido de interfaz, sin posición)
	pitchVariance: number?, -- ± variación de tono por reproducción
	loop: boolean?,
	status: "Pending" | "Approved",
}

local ById: { [string]: Cue } = {}
local Order: { string } = {}

local function cue(id: string, category: Category, volume: number, extra: { [string]: any }?)
	assert(ById[id] == nil, "Señal duplicada: " .. id)
	local c: Cue = {
		id = id,
		category = category,
		assetId = nil,
		volume = volume,
		rollOffMaxDistance = extra and extra.rollOffMaxDistance,
		pitchVariance = extra and extra.pitchVariance,
		loop = extra and extra.loop,
		status = "Pending",
	}
	ById[id] = c
	table.insert(Order, id)
end

-- Elementos: lanzamiento, viaje e impacto
for _, el in ipairs(Elements.Order) do
	for _, phase in ipairs({ "Cast", "Travel", "Impact" }) do
		cue("SFX_" .. el .. "_" .. phase, "Combat", 0.7, { rollOffMaxDistance = 90, pitchVariance = 0.06 })
	end
end
-- Ataques sin elemento (Eco)
for _, phase in ipairs({ "Cast", "Travel", "Impact" }) do
	cue("SFX_Eco_" .. phase, "Combat", 0.6, { rollOffMaxDistance = 90, pitchVariance = 0.06 })
end

-- Eventos de combate
for _, ev in ipairs({
	"Hit",
	"Crit",
	"Shield",
	"Heal",
	"Burn",
	"Paralyze",
	"Stun",
	"Reflect",
	"Victory",
	"Defeat",
	"NexoCharge",
}) do
	cue("SFX_Combat_" .. ev, "Combat", if ev == "Victory" or ev == "Defeat" then 0.8 else 0.7, {
		rollOffMaxDistance = 90,
		pitchVariance = if ev == "Victory" or ev == "Defeat" then 0 else 0.05,
	})
end

-- Voces y ruidos de los tres iniciales
for _, sp in ipairs({ "kuachi", "xolumi", "teselo" }) do
	for _, action in ipairs({ "Idle", "Move", "Happy", "Hurt", "Attack", "Special", "Evolve", "Victory" }) do
		cue("SFX_CR_" .. sp .. "_" .. action, "Creature", 0.6, {
			rollOffMaxDistance = if action == "Evolve" then nil else 60,
			pitchVariance = if action == "Evolve" then 0 else 0.08,
		})
	end
end

-- Ambiente por capas y música por estado (propuesta de capas; ver docs/VFX_SYSTEM.md)
local AmbientLayers: { [string]: { string } } = {
	ValleCopal = { "Base", "Water", "Fauna", "Market" },
	MareaCoralina = { "Base", "Waves", "Fauna" },
	CumbreBrasa = { "Base", "Lava", "Wind" },
	MesetaFulgor = { "Base", "Storm", "Wind" },
	VeloAstral = { "Base", "Wind", "Stars" },
	TorreDelNexo = { "Base", "Echo" },
}
local biomes = {}
for id in pairs(Species.Biomes) do
	table.insert(biomes, id)
end
table.sort(biomes)
for _, biome in ipairs(biomes) do
	for _, layer in ipairs(AmbientLayers[biome] or { "Base" }) do
		cue("AMB_" .. biome .. "_" .. layer, "Ambient", if layer == "Base" then 0.5 else 0.35, {
			loop = true,
			rollOffMaxDistance = if layer == "Base" then nil else 120,
		})
	end
	for _, state in ipairs({ "Explore", "Battle", "Boss", "Victory" }) do
		cue("MUS_" .. biome .. "_" .. state, "Music", 0.45, { loop = state ~= "Victory" })
	end
end

-- Interfaz
for _, action in ipairs({
	"Tap",
	"Open",
	"Close",
	"Confirm",
	"Back",
	"Error",
	"Toast",
	"Reward",
	"Achievement",
	"Hatch",
	"Evolve",
	"LevelUp",
}) do
	cue("SFX_UI_" .. action, "UI", 0.5)
end

return Freeze.deep({
	ById = ById,
	Order = Order,
	AmbientLayers = AmbientLayers,
	-- Volumen por categoría (el jugador podrá ajustarlo cuando haya audio)
	CategoryVolume = { Ambient = 1, Music = 1, Creature = 1, Combat = 1, UI = 1, World = 1 },
})
