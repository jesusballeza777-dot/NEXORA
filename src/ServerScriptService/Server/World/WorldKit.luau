--!strict
-- Piezas básicas del mundo (Parts con material nativo y color de la paleta de la Biblia
-- visual Genesis §4.2). Los constructores de Server/World/* solo componen estas piezas.
-- Toda pieza nace anclada, con superficies lisas; la decoración menuda sin colisión ni
-- consultas para no estorbar al jugador ni a los rayos del acompañante.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ambience = require(Shared.Config.Ambience)

local WorldKit = {}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end
WorldKit.rgb = rgb

-- Paleta del valle (Config/Ambience.Palette → Color3)
local C: { [string]: Color3 } = {}
for name, value in pairs(Ambience.Palette) do
	C[name] = rgb(value)
end
WorldKit.C = C

function WorldKit.v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

export type Props = { [string]: any }

-- Parte genérica. `props.ClassName` permite WedgePart; `props.Shape`, Ball/Cylinder.
function WorldKit.part(props: Props, parent: Instance): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	if props.Shape then
		(p :: Part).Shape = props.Shape -- antes del tamaño: Ball/Cylinder ajustan Size
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		if k ~= "ClassName" and k ~= "Shape" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- Pieza decorativa: sin colisión, sin consultas y sin toques
function WorldKit.decor(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

function WorldKit.box(
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	solid: boolean?
): BasePart
	local p = WorldKit.part({ Size = size, CFrame = cf, Color = color, Material = material }, parent)
	if not solid then
		WorldKit.decor(p)
	end
	return p
end

-- Elipsoide (SpecialMesh esfera): follaje, cántaros, rocas suaves
function WorldKit.ellipsoid(
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): BasePart
	local p = WorldKit.decor(WorldKit.part({ Size = size, CFrame = cf, Color = color, Material = material }, parent))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

function WorldKit.ball(
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): BasePart
	return WorldKit.decor(WorldKit.part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		CFrame = CFrame.new(pos),
		Color = color,
		Material = material,
	}, parent))
end

-- Cilindro vertical (disco, poste, tambor)
function WorldKit.disc(
	radius: number,
	height: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	solid: boolean?
): BasePart
	local p = WorldKit.part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
	}, parent)
	if not solid then
		WorldKit.decor(p)
	end
	return p
end

-- Cilindro entre dos puntos (ramas, raíces, patas, cuerdas)
function WorldKit.limb(
	a: Vector3,
	b: Vector3,
	radius: number,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	solid: boolean?
): BasePart
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local cf = if len > 1e-4 then CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0) else CFrame.new(mid)
	local p = WorldKit.part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(math.max(len, 0.05), radius * 2, radius * 2),
		CFrame = cf,
		Color = color,
		Material = material,
	}, parent)
	if not solid then
		WorldKit.decor(p)
	end
	return p
end

-- Cuña (WedgePart): la pendiente mira a -Z (LookVector) y sube hacia +Z
function WorldKit.wedge(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, parent: Instance): BasePart
	return WorldKit.decor(WorldKit.part({
		ClassName = "WedgePart",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material,
	}, parent))
end

-- Tejado a dos aguas sobre `cf` (cumbrera en X local): dos cuñas espalda con espalda
function WorldKit.gable(width: number, depth: number, rise: number, cf: CFrame, color: Color3, parent: Instance)
	for _, side in ipairs({ -1, 1 }) do
		WorldKit.wedge(
			Vector3.new(width, rise, depth / 2),
			cf * CFrame.new(0, rise / 2, side * depth / 4) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
			color,
			Enum.Material.ClayRoofTiles,
			parent
		)
	end
end

-- Luz puntual con el presupuesto de la Biblia: rango ≤ 12 y sin sombras
function WorldKit.light(parent: Instance, color: Color3, range: number, brightness: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = math.min(range, 12)
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	return light
end

function WorldKit.folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function WorldKit.model(name: string, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Farol de copal colgante: cuerpo translúcido, tapa de madera y núcleo luminoso fino.
-- El pivote del modelo es el punto de cuelgue: el cliente lo hace oscilar (AmbientSway).
function WorldKit.lantern(hang: Vector3, drop: number, parent: Instance, withLight: boolean): Model
	local m = WorldKit.model("Farol", parent)
	local body = hang - Vector3.new(0, drop + 1.3, 0)
	if drop > 0.05 then
		WorldKit.limb(hang, hang - Vector3.new(0, drop, 0), 0.07, C.cacao, Enum.Material.Fabric, m)
	end
	WorldKit.disc(0.75, 0.35, hang - Vector3.new(0, drop + 0.15, 0), C.barkDark, Enum.Material.Wood, m)
	local shell = WorldKit.ellipsoid(Vector3.new(1.7, 2.3, 1.7), CFrame.new(body), C.copal, Enum.Material.Glass, m)
	shell.Transparency = 0.25
	shell.CastShadow = false
	local core = WorldKit.ball(0.7, body, C.copalGlow, Enum.Material.Neon, m)
	core.CastShadow = false
	WorldKit.disc(0.55, 0.3, body - Vector3.new(0, 1.2, 0), C.barkDark, Enum.Material.Wood, m)
	if withLight then
		WorldKit.light(core, C.copalGlow, 10, 1.3)
	end
	m.WorldPivot = CFrame.new(hang)
	m:SetAttribute("SwayKind", "lantern")
	m:AddTag("AmbientSway")
	return m
end

-- Cuerda de papel picado entre dos puntos, con comba. Cada bandera se mece sola en el
-- cliente (AmbientSway, SwayKind = "papel"). Colores de acento con saturación ≤ 70 %.
function WorldKit.papelPicado(a: Vector3, b: Vector3, sag: number, parent: Instance, seed: number): Model
	local m = WorldKit.model("PapelPicado", parent)
	local n = math.max(3, math.floor((b - a).Magnitude / 2.6))
	local prev = a
	local across = (b - a).Unit:Cross(Vector3.yAxis)
	local colors = Ambience.Papel
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		WorldKit.limb(prev, p, 0.05, C.cacao, Enum.Material.Fabric, m)
		prev = p
		if i < n then
			local flag = WorldKit.box(
				Vector3.new(1.5, 1.8, 0.08),
				CFrame.lookAt(p - Vector3.new(0, 0.95, 0), p - Vector3.new(0, 0.95, 0) + across),
				rgb(colors[(i + seed) % #colors + 1]),
				Enum.Material.SmoothPlastic,
				m
			)
			flag.Name = "Flag"
			flag.Transparency = 0.08
			flag.CastShadow = false
		end
	end
	m:SetAttribute("SwayKind", "papel")
	m.WorldPivot = CFrame.new(a:Lerp(b, 0.5))
	m:AddTag("AmbientSway")
	return m
end

-- Rótulo flotante (BillboardGui) con título y subtítulo
function WorldKit.label(adornee: BasePart, text: string, sub: string?, color: Color3?, offset: number?): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffset = Vector3.new(0, offset or (adornee.Size.Y / 2 + 3), 0)
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

-- Emisor de partículas con el tope de la Biblia (≤ 20 partículas/s)
function WorldKit.emitter(parent: Instance, props: Props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do
		(e :: any)[k] = v
	end
	e.Rate = math.min(e.Rate, 20)
	e.Parent = parent
	return e
end

-- Clona una plantilla (Model en el origen) en `cf` con escala uniforme `s`
function WorldKit.place(template: Model, cf: CFrame, s: number, parent: Instance): Model
	local m = template:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			local rel = d.CFrame
			d.Size *= s
			d.CFrame = cf * CFrame.new(rel.Position * s) * (rel - rel.Position)
		end
	end
	m.WorldPivot = cf
	m.Parent = parent
	return m
end

return WorldKit
