--!strict
-- Construye Valle Copal (BLOCKOUT) a partir de Config/World.
-- Geometría provisional pero con composición: el Gran Nexo como ancla, plaza de
-- copal, río con chinampas, lotes al sur, Linde de las Chinampas al oeste y el
-- Mirador de Biomas detrás del árbol. Todo queda marcado con AssetStatus = "Blockout".
-- Presupuesto: < 1 500 partes, luces puntuales ≤ 12, partículas solo en zonas clave.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Ambience = require(Shared.Config.Ambience)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
local PlazaBuilder = require(script.Parent.PlazaBuilder)
local GranNexoBuilder = require(script.Parent.GranNexoBuilder)
local TorreBuilder = require(script.Parent.TorreBuilder)
local GabineteBuilder = require(script.Parent.GabineteBuilder)
local FloraBuilder = require(script.Parent.FloraBuilder)
local RiverBuilder = require(script.Parent.RiverBuilder)

local ValleBuilder = {}

-- Paleta del valle (fantasía artesanal: copal, barro, jade, piedra, papel picado)
local C = {
	copal = Color3.fromRGB(232, 168, 72),
	copalGlow = Color3.fromRGB(255, 196, 96),
	stone = Color3.fromRGB(196, 182, 160),
	stoneDark = Color3.fromRGB(122, 108, 96),
	clay = Color3.fromRGB(176, 98, 64),
	jade = Color3.fromRGB(62, 150, 122),
	leaf = Color3.fromRGB(86, 150, 92),
	leafDeep = Color3.fromRGB(54, 112, 78),
	bark = Color3.fromRGB(96, 70, 52),
	wood = Color3.fromRGB(140, 100, 66),
	fog = Color3.fromRGB(150, 150, 160),
	papel = {
		Color3.fromRGB(232, 74, 110),
		Color3.fromRGB(250, 186, 50),
		Color3.fromRGB(64, 170, 214),
		Color3.fromRGB(150, 96, 222),
		Color3.fromRGB(104, 190, 96),
	},
}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	props.ClassName = nil
	if props.Shape then
		(p :: Part).Shape = props.Shape -- antes del tamaño: Ball/Cylinder ajustan Size
		props.Shape = nil
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function ellipsoid(size: Vector3, cf: CFrame, color: Color3, parent: Instance, material: Enum.Material?): BasePart
	local p =
		part({ Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.SmoothPlastic }, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function disc(
	radius: number,
	height: number,
	pos: Vector3,
	color: Color3,
	parent: Instance,
	material: Enum.Material?
): BasePart
	return part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, parent)
end

local function label(adornee: BasePart, text: string, sub: string?, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = Vector3.new(0, adornee.Size.Y / 2 + 3, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = color or Color3.fromRGB(255, 244, 222)
	title.TextStrokeTransparency = 0.35
	title.TextStrokeColor3 = Color3.fromRGB(60, 36, 20)
	title.Text = text
	title.Parent = gui
	if sub then
		local s = title:Clone()
		s.Position = UDim2.fromScale(0, 0.6)
		s.Size = UDim2.new(1, 0, 0.4, 0)
		s.Font = Enum.Font.GothamMedium
		s.TextColor3 = Color3.fromRGB(240, 226, 200)
		s.Text = sub
		s.Parent = gui
	end
	gui.Parent = adornee
	return gui
end

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function buildLots(root: Instance): { Model }
	local folder = Instance.new("Folder")
	folder.Name = "Lots"
	folder.Parent = root
	local cfg = World.Lots
	local lots = {}
	for i, pos in ipairs(cfg.positions) do
		local center = v3(pos)
		local lot = Instance.new("Model")
		lot.Name = "Lot" .. i
		lot:SetAttribute("LotIndex", i)
		lot.Parent = folder
		local ground = part({
			Size = Vector3.new(cfg.size[1], 1, cfg.size[2]),
			CFrame = CFrame.new(center + Vector3.new(0, 0.4, 0)),
			Color = Color3.fromRGB(120, 168, 96),
			Material = Enum.Material.Grass,
		}, lot)
		ground.Name = "Ground"
		lot.PrimaryPart = ground
		-- Borde de piedra con grecas
		for _, side in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
			local horizontal = side[1] == 0
			part({
				Size = if horizontal then Vector3.new(cfg.size[1], 1.4, 1.4) else Vector3.new(1.4, 1.4, cfg.size[2]),
				CFrame = CFrame.new(center + Vector3.new(side[1] * cfg.size[1] / 2, 0.9, side[2] * cfg.size[2] / 2)),
				Color = C.stone,
				Material = Enum.Material.Slate,
			}, lot)
		end
		-- Hábitat: cuatro pedestales de copal
		local habitat = Instance.new("Model")
		habitat.Name = "Habitat"
		habitat.Parent = lot
		disc(
			16,
			0.6,
			center + v3(cfg.habitatOffset) + Vector3.new(0, 0.9, 0),
			Color3.fromRGB(150, 190, 120),
			habitat,
			Enum.Material.Grass
		)
		for s, off in ipairs(cfg.slotOffsets) do
			local p = center + v3(off)
			local ped = disc(3.2, 1.2, p + Vector3.new(0, 1.3, 0), C.copal, habitat, Enum.Material.SmoothPlastic)
			ped.Name = "Slot" .. s
			ped:SetAttribute("Slot", s)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SlotPrompt"
			prompt.ActionText = "Gestionar hábitat"
			prompt.ObjectText = "Lugar " .. s
			prompt.MaxActivationDistance = 10
			prompt.Enabled = false
			prompt.Parent = ped
		end
		-- Recolector de Monedas (cántaro) e incubadora
		local collector = ellipsoid(
			Vector3.new(4, 5, 4),
			CFrame.new(center + v3(cfg.collectorOffset) + Vector3.new(0, 3, 0)),
			C.clay,
			lot
		)
		collector.Name = "Collector"
		local cprompt = Instance.new("ProximityPrompt")
		cprompt.Name = "CollectPrompt"
		cprompt.ActionText = "Recoger Monedas"
		cprompt.ObjectText = "Recolector"
		cprompt.MaxActivationDistance = 10
		cprompt.Enabled = false
		cprompt.Parent = collector
		local inc = center + v3(cfg.incubatorOffset)
		disc(3, 1.4, inc + Vector3.new(0, 1.1, 0), C.stone, lot, Enum.Material.Slate)
		local ring = disc(3.6, 0.3, inc + Vector3.new(0, 4, 0), C.copalGlow, lot, Enum.Material.Neon)
		ring.Name = "IncubatorRing"
		ring.CastShadow = false
		local incubator = part({
			Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(inc + Vector3.new(0, 4.5, 0)),
			Transparency = 1,
			CanCollide = false,
		}, lot)
		incubator.Name = "Incubator"
		label(incubator, "Incubadora", "Próximamente")
		-- Vitrina (3 Tallados) reservada
		local vit = center + v3(cfg.vitrinaOffset)
		for k = -1, 1 do
			part({
				Size = Vector3.new(4, 6, 3),
				CFrame = CFrame.new(vit + Vector3.new(k * 5, 3.5, 0)),
				Color = C.wood,
				Material = Enum.Material.Wood,
				Transparency = 0.2,
			}, lot)
		end
		local sign = part({
			Size = Vector3.new(10, 3, 0.6),
			CFrame = CFrame.new(center + Vector3.new(0, 4, -cfg.size[2] / 2 - 1)),
			Color = C.wood,
			Material = Enum.Material.Wood,
		}, lot)
		sign.Name = "Sign"
		local ownerLabel = label(sign, "Lote libre", nil)
		ownerLabel.Name = "OwnerLabel"
		table.insert(lots, lot)
	end
	return lots
end

local function buildEncounters(root: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Encounters"
	folder.Parent = root
	for markerId, enc in pairs(World.Encounters) do
		local pos = v3(enc.position)
		local zone = disc(
			enc.radius * 0.55,
			0.4,
			pos + Vector3.new(0, 0.3, 0),
			Color3.fromRGB(110, 110, 116),
			folder,
			Enum.Material.Slate
		)
		zone.Name = markerId
		zone:SetAttribute("Marker", markerId)
		local linde = Ambience.Linde
		-- Rocas de basalto redondeadas alrededor del Opaco
		for k = 1, 5 do
			local a = math.rad(k * 72)
			local h = 2 + (k % 3)
			ellipsoid(
				Vector3.new(3.4, h, 3),
				CFrame.new(pos + Vector3.new(math.cos(a) * 9, h * 0.3, math.sin(a) * 9))
					* CFrame.Angles(0, a, math.rad(10)),
				rgb(linde.boulder),
				folder,
				Enum.Material.Basalt
			)
		end
		-- Juncos de chinampa: matas de tallos finos en anillo, con un hueco hacia el sendero
		for k = 1, linde.reedClustersPerZone do
			local a = (k + 0.5) / (linde.reedClustersPerZone + 1) * math.pi * 1.6 + math.pi * 0.45
			local center = pos + Vector3.new(math.cos(a) * enc.radius * 0.8, 0, math.sin(a) * enc.radius * 0.8)
			for j = 0, 2 do
				local h = 3 + ((k + j) % 3) * 0.8
				local reed = part({
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(h, 0.35, 0.35),
					CFrame = CFrame.new(center + Vector3.new((j - 1) * 0.7, h / 2, ((k + j) % 2) * 0.6))
						* CFrame.Angles(0, 0, math.rad(90) + (j - 1) * 0.12),
					Color = rgb(linde.reedColors[((k + j) % #linde.reedColors) + 1]),
					Material = Enum.Material.Grass,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
				}, folder)
				reed.CastShadow = false
			end
		end
		local mist = Instance.new("ParticleEmitter")
		mist.Name = "OpacoMist"
		mist.Color = ColorSequence.new(C.fog)
		mist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		mist.Size = NumberSequence.new(6)
		mist.Rate = 4
		mist.Lifetime = NumberRange.new(5, 7)
		mist.Speed = NumberRange.new(0.5, 1)
		mist.SpreadAngle = Vector2.new(180, 20)
		mist.Parent = zone
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EncounterPrompt"
		prompt.ActionText = "Restaurar"
		prompt.ObjectText = "Opaco"
		prompt.MaxActivationDistance = enc.radius
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = zone
	end
end

-- Motas de copal flotando sobre la plaza y el árbol (una sola fuente, tasa baja)
local function buildMotes(root: Instance)
	local m = Ambience.Motes
	local volume = part({
		Name = "CopalMotes",
		Size = v3(m.size),
		CFrame = CFrame.new(v3(m.center)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	}, root)
	local motes = Instance.new("ParticleEmitter")
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Shape = Enum.ParticleEmitterShape.Box
	motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	motes.Color = ColorSequence.new(rgb(m.color))
	motes.LightEmission = 1
	motes.Rate = m.rate
	motes.Lifetime = NumberRange.new(m.lifetime[1], m.lifetime[2])
	motes.Speed = NumberRange.new(m.speed[1], m.speed[2])
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Size = NumberSequence.new(m.particleSize)
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Parent = volume
end

function ValleBuilder.build(): { lots: { Model }, root: Folder }
	TerrainBuilder.lighting()
	TerrainBuilder.build()
	local root = Instance.new("Folder")
	root.Name = "ValleCopal"
	root:SetAttribute("AssetStatus", "Blockout")
	PlazaBuilder.build(root)
	GranNexoBuilder.build(root)
	TorreBuilder.build(root)
	GabineteBuilder.build(root)
	local lots = buildLots(root)
	buildEncounters(root)
	RiverBuilder.build(root)
	FloraBuilder.build(root)
	buildMotes(root)
	root.Parent = Workspace
	return { lots = lots, root = root }
end

return ValleBuilder
