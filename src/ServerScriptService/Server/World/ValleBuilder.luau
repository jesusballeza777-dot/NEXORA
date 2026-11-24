--!strict
-- Construye Valle Copal (BLOCKOUT con composición, docs/WORLD_BUILDING.md) a partir de
-- Config/World (posiciones de juego), Config/Landscape (paisaje) y Config/Ambience (luz
-- y paleta). Cada parte del valle tiene su constructor con una responsabilidad acotada:
--   TerrainBuilder · luz, terreno, agua y cascada (Terrain primero)
--   PlazaBuilder   · plaza, estela, papel picado, huevos y spawn
--   GranNexoBuilder· el landmark
--   TorreBuilder   · basamento, calzada, siete estaciones y puertas de los biomas
--   GabineteBuilder· el Gabinete que Camina (lo anima el cliente)
--   OficiosBuilder · mercado y taller
--   RiverBuilder   · puentes, chinampas, canoas, flotantes y pie de la cascada
--   LotsBuilder    · Lotes Hogar
--   LindeBuilder   · claros de los Opacos
--   FloraBuilder   · vegetación con plantillas · FaunaBuilder · aves, peces y mariposas
-- Todo queda marcado con AssetStatus = "Blockout".

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
local PlazaBuilder = require(script.Parent.PlazaBuilder)
local GranNexoBuilder = require(script.Parent.GranNexoBuilder)
local TorreBuilder = require(script.Parent.TorreBuilder)
local GabineteBuilder = require(script.Parent.GabineteBuilder)
local OficiosBuilder = require(script.Parent.OficiosBuilder)
local RiverBuilder = require(script.Parent.RiverBuilder)
local LotsBuilder = require(script.Parent.LotsBuilder)
local LindeBuilder = require(script.Parent.LindeBuilder)
local FloraBuilder = require(script.Parent.FloraBuilder)
local FaunaBuilder = require(script.Parent.FaunaBuilder)

local ValleBuilder = {}

-- Motas de copal flotando sobre la plaza y el árbol (una sola fuente, tasa baja)
local function buildMotes(root: Instance)
	local m = Ambience.Motes
	local volume = WorldKit.box(
		WorldKit.v3(m.size),
		CFrame.new(WorldKit.v3(m.center)),
		WorldKit.C.copalGlow,
		Enum.Material.SmoothPlastic,
		root
	)
	volume.Name = "CopalMotes"
	volume.Transparency = 1
	volume.CastShadow = false
	WorldKit.emitter(volume, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Color = ColorSequence.new(WorldKit.rgb(m.color)),
		LightEmission = 1,
		Rate = m.rate,
		Lifetime = NumberRange.new(m.lifetime[1], m.lifetime[2]),
		Speed = NumberRange.new(m.speed[1], m.speed[2]),
		SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new(m.particleSize),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
end

function ValleBuilder.build(): { lots: { Model }, root: Folder, terrainOps: number }
	TerrainBuilder.lighting()
	local terrainOps = TerrainBuilder.build()
	local root = Instance.new("Folder")
	root.Name = "ValleCopal"
	root:SetAttribute("AssetStatus", "Blockout")
	PlazaBuilder.build(root)
	GranNexoBuilder.build(root)
	TorreBuilder.build(root)
	GabineteBuilder.build(root)
	OficiosBuilder.build(root)
	RiverBuilder.build(root)
	local lots = LotsBuilder.build(root)
	LindeBuilder.build(root)
	FloraBuilder.build(root)
	FaunaBuilder.build(root)
	buildMotes(root)
	root.Parent = Workspace
	return { lots = lots, root = root, terrainOps = terrainOps }
end

return ValleBuilder
