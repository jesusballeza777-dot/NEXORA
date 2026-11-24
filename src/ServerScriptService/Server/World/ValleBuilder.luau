--!strict
-- Construye Valle Copal (BLOCKOUT) a partir de Config/World.
-- Geometría provisional pero con composición: el Gran Nexo como ancla, plaza de
-- copal, río con chinampas, lotes al sur, Linde de las Chinampas al oeste y el
-- Mirador de Biomas detrás del árbol. Todo queda marcado con AssetStatus = "Blockout".
-- Presupuesto: < 1 500 partes, luces puntuales ≤ 12, partículas solo en zonas clave.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Elements = require(Shared.Config.Elements)
local SpeciesConfig = require(Shared.Config.Species)
local Ambience = require(Shared.Config.Ambience)
local TerrainBuilder = require(script.Parent.TerrainBuilder)
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

local function buildPlaza(root: Instance)
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = root
	local center = v3(World.Plaza.center)
	disc(World.Plaza.radius, 1, center + Vector3.new(0, 0.2, 0), C.stone, plaza, Enum.Material.Slate)
	-- Anillos de greca (relieve tono sobre tono)
	for i, r in ipairs({ World.Plaza.radius - 2, World.Plaza.radius - 9, 7 }) do
		disc(r, 1.1, center + Vector3.new(0, 0.25 + i * 0.01, 0), C.stoneDark, plaza, Enum.Material.Slate)
		disc(r - 1, 1.2, center + Vector3.new(0, 0.26 + i * 0.01, 0), C.stone, plaza, Enum.Material.Slate)
	end
	-- Camino de la plaza al árbol
	part({
		Size = Vector3.new(12, 1, 30),
		CFrame = CFrame.new(0, 0.3, -18),
		Color = C.stone,
		Material = Enum.Material.Slate,
	}, plaza)
	-- Papel picado entre postes (identidad festiva sin saturar)
	local posts = { Vector3.new(-26, 0, 22), Vector3.new(26, 0, 22), Vector3.new(-26, 0, -4), Vector3.new(26, 0, -4) }
	for _, pos in ipairs(posts) do
		part({
			Size = Vector3.new(1, 14, 1),
			CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)),
			Color = C.wood,
			Material = Enum.Material.Wood,
		}, plaza)
	end
	local strings = { { posts[1], posts[2] }, { posts[3], posts[4] }, { posts[1], posts[3] }, { posts[2], posts[4] } }
	for s, pair in ipairs(strings) do
		local a, b = pair[1] + Vector3.new(0, 13.5, 0), pair[2] + Vector3.new(0, 13.5, 0)
		local n = math.floor((b - a).Magnitude / 3)
		for i = 1, n - 1 do
			local t = i / n
			local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 2.5, 0)
			part({
				Size = Vector3.new(1.6, 1.8, 0.1),
				CFrame = CFrame.lookAt(p, p + (b - a).Unit:Cross(Vector3.yAxis)),
				Color = C.papel[(i + s) % #C.papel + 1],
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				CastShadow = false,
				Transparency = 0.05,
			}, plaza)
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CFrame = CFrame.lookAt(v3(World.SpawnPoint), v3(World.GranNexo.position))
	spawn.Duration = 0
	spawn.Parent = plaza
end

local function buildTree(root: Instance)
	local tree = Instance.new("Model")
	tree.Name = "GranNexo"
	tree.Parent = root
	local base = v3(World.GranNexo.position)
	local H, R = World.GranNexo.trunkHeight, World.GranNexo.trunkRadius
	-- Tronco retorcido por segmentos (silueta reconocible desde todo el valle)
	local segments = 7
	local trunk: BasePart? = nil
	for i = 0, segments - 1 do
		local t = i / segments
		local r = R * (1 - t * 0.45)
		local twist = math.rad(i * 11)
		local cf = CFrame.new(base + Vector3.new(math.sin(t * 3) * 2, H * t + H / segments / 2, math.cos(t * 2) * 1.5))
			* CFrame.Angles(0, twist, math.rad(math.sin(t * 5) * 4))
		local seg = part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(H / segments + 2, r * 2, r * 2),
			CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.bark,
			Material = Enum.Material.Wood,
		}, tree)
		if i == 0 then
			trunk = seg
			seg.Name = "Trunk"
		end
	end
	-- Raíces que abrazan la plaza
	for i = 1, 9 do
		local a = math.rad(i * 40)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = 16 + (i % 3) * 5
		local pos = base + dir * (R + len / 2 - 3) + Vector3.new(0, 1.4, 0)
		part({
			Size = Vector3.new(3.2, 2.8, len),
			CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(math.rad(-6), 0, 0),
			Color = C.bark,
			Material = Enum.Material.Wood,
		}, tree)
	end
	-- Ramas y copa (volúmenes de hoja con faroles de copal)
	local lights = 0
	for i = 1, 8 do
		local a = math.rad(i * 45 + 10)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local start = base + Vector3.new(0, H * 0.75, 0)
		local tip = start + dir * (World.GranNexo.canopyRadius * 0.55) + Vector3.new(0, 10 + (i % 2) * 6, 0)
		local mid = (start + tip) / 2
		part({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new((tip - start).Magnitude, 3.4, 3.4),
			CFrame = CFrame.lookAt(mid, tip) * CFrame.Angles(0, math.rad(90), 0),
			Color = C.bark,
			Material = Enum.Material.Wood,
		}, tree)
		ellipsoid(
			Vector3.new(26, 16, 26),
			CFrame.new(tip + Vector3.new(0, 4, 0)),
			if i % 2 == 0 then C.leaf else C.leafDeep,
			tree,
			Enum.Material.LeafyGrass
		)
		if lights < 8 then
			lights += 1
			local lantern = ellipsoid(
				Vector3.new(1.4, 1.4, 1.4),
				CFrame.new(tip - Vector3.new(0, 4, 0)),
				C.copalGlow,
				tree,
				Enum.Material.Neon
			)
			lantern.CastShadow = false
			local light = Instance.new("PointLight")
			light.Color = C.copalGlow
			light.Range = 12
			light.Shadows = false
			light.Brightness = 1.4
			light.Parent = lantern
		end
	end
	ellipsoid(
		Vector3.new(48, 26, 48),
		CFrame.new(base + Vector3.new(0, H + 8, 0)),
		C.leaf,
		tree,
		Enum.Material.LeafyGrass
	)
	-- Corazón de copal: el "nexo" que late (lo anima el cliente)
	local heart = ellipsoid(
		Vector3.new(5, 6.5, 5),
		CFrame.new(base + Vector3.new(0, 9, R - 0.6)),
		C.copalGlow,
		tree,
		Enum.Material.Glass
	)
	heart.Name = "NexoHeart"
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(C.copalGlow)
	particles.Rate = 6
	particles.Lifetime = NumberRange.new(3, 5)
	particles.Speed = NumberRange.new(1, 2)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Size = NumberSequence.new(0.35)
	particles.LightEmission = 1
	particles.Parent = heart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "NexoMenu"
	prompt.ActionText = "Abrir el menú del árbol"
	prompt.ObjectText = "Gran Nexo"
	prompt.MaxActivationDistance = World.GranNexo.interactRadius
	prompt.RequiresLineOfSight = false
	prompt.Parent = heart
	if trunk then
		tree.PrimaryPart = trunk
	end
end

local function buildEggs(root: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "StarterEggs"
	folder.Parent = root
	for eggId, pos in pairs(World.StarterEggPedestals) do
		local p = v3(pos)
		disc(3.4, 1.6, p + Vector3.new(0, 0.8, 0), C.stone, folder, Enum.Material.Slate)
		disc(2.6, 1.8, p + Vector3.new(0, 1.0, 0), C.copal, folder, Enum.Material.Glass)
		local egg = ellipsoid(
			Vector3.new(3.2, 4.2, 3.2),
			CFrame.new(p + Vector3.new(0, 4.2, 0)),
			C.copal,
			folder,
			Enum.Material.SmoothPlastic
		)
		egg.Name = eggId
		egg:SetAttribute("EggId", eggId)
		-- Espiral tallada: idéntica en los tres huevos (la elección es por intuición)
		for i = 0, 5 do
			local a = math.rad(i * 60)
			local y = 2.9 + i * 0.42
			ellipsoid(
				Vector3.new(0.5, 0.5, 0.5),
				CFrame.new(p + Vector3.new(math.cos(a) * 1.55, y, math.sin(a) * 1.55)),
				Color3.fromRGB(170, 112, 50),
				folder
			)
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ChooseEgg"
		prompt.ActionText = "Elegir este huevo"
		prompt.ObjectText = "Huevo de copal"
		prompt.MaxActivationDistance = World.EggInteractRadius
		prompt.Enabled = false -- el cliente lo activa en el paso "Elige tu huevo"
		prompt.Parent = egg
	end
end

local function buildStations(root: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Stations"
	folder.Parent = root
	for id, st in pairs(World.Stations) do
		local pos = v3(st.position)
		local model = Instance.new("Model")
		model.Name = id
		model.Parent = folder
		disc(7, 1, pos + Vector3.new(0, 0.5, 0), C.stoneDark, model, Enum.Material.Slate)
		local booth = part({
			Size = Vector3.new(10, 7, 6),
			CFrame = CFrame.lookAt(pos + Vector3.new(0, 4, 0), Vector3.new(0, 4, -36)),
			Color = if st.implemented then C.clay else C.stoneDark,
			Material = Enum.Material.Brick,
		}, model)
		part({
			Size = Vector3.new(12, 1, 8),
			CFrame = booth.CFrame * CFrame.new(0, 4, 0),
			Color = C.papel[(#id % #C.papel) + 1],
			Material = Enum.Material.Fabric,
		}, model)
		model.PrimaryPart = booth
		label(
			booth,
			st.label,
			if st.implemented then nil else "Próximamente",
			if st.implemented then nil else Color3.fromRGB(210, 200, 190)
		)
		if st.implemented then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Station"
			prompt.ActionText = "Abrir"
			prompt.ObjectText = st.label
			prompt.MaxActivationDistance = st.radius
			prompt.Parent = booth
			booth:SetAttribute("StationId", id)
		end
	end
	-- Mirador de Biomas: puertas selladas con vitral del color de cada bioma
	for _, gate in ipairs(World.BiomeGates) do
		local pos = v3(gate.position)
		local facing = CFrame.lookAt(pos, Vector3.new(0, 0, -36))
		local biome = SpeciesConfig.Biomes[gate.biome]
		local elementColor = ({
			MareaCoralina = Elements.ById.Agua.color,
			CumbreBrasa = Elements.ById.Fuego.color,
			MesetaFulgor = Elements.ById.Rayo.color,
			VeloAstral = Elements.ById.Astral.color,
		})[gate.biome]
		local tint = Color3.fromRGB(elementColor[1], elementColor[2], elementColor[3])
		for _, x in ipairs({ -6, 6 }) do
			part({
				Size = Vector3.new(3, 20, 3),
				CFrame = facing * CFrame.new(x, 10, 0),
				Color = C.stone,
				Material = Enum.Material.Slate,
			}, folder)
		end
		part({
			Size = Vector3.new(16, 3, 3),
			CFrame = facing * CFrame.new(0, 21, 0),
			Color = C.stone,
			Material = Enum.Material.Slate,
		}, folder)
		local glass = part({
			Size = Vector3.new(9, 18, 0.6),
			CFrame = facing * CFrame.new(0, 10, 0),
			Color = tint,
			Material = Enum.Material.Glass,
			Transparency = 0.35,
		}, folder)
		label(glass, biome.name, biome.act .. " · sellado")
	end
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
	buildPlaza(root)
	buildTree(root)
	buildEggs(root)
	buildStations(root)
	local lots = buildLots(root)
	buildEncounters(root)
	RiverBuilder.build(root)
	FloraBuilder.build(root)
	buildMotes(root)
	root.Parent = Workspace
	return { lots = lots, root = root }
end

return ValleBuilder
