--!strict
-- Construye las criaturas del cliente (no colisionan, no se replican):
-- * si el modelo 3D está importado en ReplicatedStorage.CreatureModels (MeshCreature,
--   Fase 3, D-040), lo clona y la animación usa sus huesos;
-- * si no, construye el BLOCKOUT a partir de Config/Visuals (arquetipo + paleta), marcado
--   con AssetStatus = "Blockout".
--
-- Animación: todas las piezas están ancladas; cada fotograma se recalcula su CFrame
-- respecto a la raíz y se aplica con workspace:BulkMoveTo (barato y sin física).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Visuals = require(Config:WaitForChild("Visuals"))
local SpeciesConfig = require(Config:WaitForChild("Species"))
local Guardians = require(Config:WaitForChild("Guardians"))
local Rarities = require(Config:WaitForChild("Rarities"))
local MeshCreature = require(script.Parent.MeshCreature)

local CreatureBuilder = {}

export type PartRec = { part: BasePart, offset: CFrame, kind: string, index: number, baseColor: Color3 }
export type Creature = {
	model: Model,
	parts: { PartRec },
	speciesId: string,
	form: string,
	scale: number,
	phase: number,
	opaco: number,
	react: number,
	aura: ParticleEmitter?,
	mesh: boolean?, -- true: modelo importado con huesos (MeshCreature)
	destroy: (self: Creature) -> (),
}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local GREY = Color3.fromRGB(138, 138, 146)

local function newPart(model: Model, shape: string, size: Vector3, color: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	end
	p.Size = size
	if shape == "Ellipsoid" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = model
	return p
end

-- Criatura a partir del modelo importado en Studio (Fase 3, D-040). Mismo contrato que el
-- blockout: piezas ancladas con su desfase respecto al pivote (pose/update con BulkMoveTo) y,
-- además, mesh = true para que CreatureAnimator mueva los Bone por nombre.
local function fromMesh(
	model: Model,
	speciesId: string,
	form: string,
	opts: { opaco: boolean?, parent: Instance? }?
): Creature
	-- desfases respecto a la pieza primaria (la raíz de la criatura queda en su lugar)
	local origin = if model.PrimaryPart then model.PrimaryPart.CFrame else CFrame.identity
	local parts: { PartRec } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			local offset = origin:Inverse() * d.CFrame
			table.insert(parts, { part = d, offset = offset, kind = "Mesh", index = #parts + 1, baseColor = d.Color })
		end
	end
	local creature: Creature = {
		model = model,
		parts = parts,
		speciesId = speciesId,
		form = form,
		scale = 1, -- los activos ya vienen en studs reales (asset.json → sizeStuds)
		phase = math.random() * 10,
		opaco = 0,
		react = 0,
		aura = nil,
		mesh = true,
		destroy = function(self: Creature)
			self.model:Destroy()
		end,
	}
	CreatureBuilder.setOpaco(creature, if opts and opts.opaco then 1 else 0)
	model.Parent = if opts and opts.parent then opts.parent else Workspace
	return creature
end

function CreatureBuilder.build(speciesId: string, form: string, opts: { opaco: boolean?, parent: Instance? }?): Creature
	-- Si el modelo 3D está importado en el lugar, se usa; si no, el blockout de siempre.
	local imported = MeshCreature.build(speciesId, form)
	if imported then
		return fromMesh(imported, speciesId, form, opts)
	end
	local vis = Visuals.ById[speciesId]
	assert(vis, "Sin VisualConfiguration para " .. speciesId)
	local T = form == "Tallado"
	local pal = if T then vis.tallado else vis.brote
	local model = Instance.new("Model")
	model.Name = speciesId .. "_" .. form
	model:SetAttribute("AssetStatus", vis.assetStatus)
	local parts: { PartRec } = {}
	local counter = 0
	-- Hueso lógico de cada pieza (atributo "Bone" y nombre), con los nombres de los rigs de
	-- assets/Creatures/*/asset.json: así Client/Animation anima igual el blockout y la malla.
	local bone = "spine"

	local function add(
		shape: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		kind: string?,
		material: Enum.Material?
	): BasePart
		counter += 1
		local p = newPart(model, shape, size, color, material)
		local o = offset.Position
		local side = if o.X > 0 then "_L" else "_R" -- +X es la izquierda (la criatura mira a +Z)
		local name = if kind == "Leg"
			then (if o.Z > 0.2 then "legF" elseif o.Z < -0.05 then "legB" else "legM") .. side
			elseif kind == "Gill" then (if vis.archetype == "Axolotl" then "gill" else "wing") .. side
			elseif kind == "Tail" then "tail1"
			else bone
		p.Name = name
		p:SetAttribute("Bone", name)
		table.insert(parts, { part = p, offset = offset, kind = kind or "Body", index = counter, baseColor = color })
		return p
	end
	local body, belly, accent = rgb(pal.body), rgb(pal.belly), rgb(pal.accent)
	local glow = rgb(pal.emissive)
	local function E(size: Vector3, pos: Vector3, color: Color3, kind: string?, material: Enum.Material?)
		return add("Ellipsoid", size, CFrame.new(pos), color, kind, material)
	end
	-- Ojos grandes con dos brillos y rubor (Brote); ojos rasgados con ceño (Tallado).
	-- `cheekZ` = dónde queda la superficie de la mejilla respecto al centro del ojo
	-- (depende de la curvatura de cada cabeza; calculado por arquetipo).
	local function eyes(center: Vector3, spread: number, size: number, cheekZ: number?)
		for _, s in ipairs({ -1, 1 }) do
			local c = center + Vector3.new(s * spread, 0, 0)
			if not T then
				E(Vector3.new(size * 2, size * 2.2, size * 1.4), c, rgb(Visuals.Face.sclera))
				E(
					Vector3.new(size * 1.25, size * 1.4, size * 0.8),
					c + Vector3.new(0, -size * 0.1, size * 0.5),
					rgb(pal.eye)
				)
				E(
					Vector3.new(size * 0.4, size * 0.4, size * 0.3),
					c + Vector3.new(-s * size * 0.25, size * 0.35, size * 0.9),
					Color3.new(1, 1, 1),
					"Body",
					Enum.Material.Neon
				)
				E(
					Vector3.new(size * 0.2, size * 0.2, size * 0.2),
					c + Vector3.new(s * size * 0.2, -size * 0.3, size * 0.92),
					Color3.new(1, 1, 1),
					"Body",
					Enum.Material.Neon
				)
				E(
					Vector3.new(size * 1.05, size * 0.55, size * 0.4),
					c + Vector3.new(s * size * 0.35, -size * 1.25, cheekZ or 0),
					rgb(Visuals.Face.blush)
				)
			else
				add(
					"Ellipsoid",
					Vector3.new(size * 2.2, size * 1.1, size * 1.2),
					CFrame.new(c) * CFrame.Angles(0, 0, s * 0.28),
					Color3.fromRGB(248, 240, 222)
				)
				E(
					Vector3.new(size, size * 0.9, size * 0.6),
					c + Vector3.new(0, 0, size * 0.4),
					rgb(pal.iris),
					"Body",
					Enum.Material.Neon
				)
				add(
					"Block",
					Vector3.new(size * 0.15, size * 0.75, size * 0.1),
					CFrame.new(c + Vector3.new(0, 0, size * 0.7)),
					Color3.fromRGB(10, 8, 8)
				)
				add(
					"Block",
					Vector3.new(size * 2.4, size * 0.35, size * 0.4),
					CFrame.new(c + Vector3.new(-s * size * 0.15, size * 0.65, size * 0.15))
						* CFrame.Angles(0, 0, s * 0.42),
					accent
				)
			end
		end
	end

	-- Sonrisa del Brote: dos trazos finos en "v" suave sobre la superficie de la cabeza.
	local bodyLuma = body.R * 0.299 + body.G * 0.587 + body.B * 0.114
	local mouthColor = rgb(if bodyLuma < 0.25 then Visuals.Face.mouthOnDark else Visuals.Face.mouth)
	local function smile(at: Vector3, width: number)
		if T then
			return
		end
		for _, s in ipairs({ -1, 1 }) do
			add(
				"Block",
				Vector3.new(width, width * 0.15, width * 0.2),
				CFrame.new(at + Vector3.new(s * width * 0.43, width * 0.07, 0)) * CFrame.Angles(0, 0, s * 0.32),
				mouthColor
			)
		end
	end

	local a = vis.archetype
	if a == "Opossum" then
		E(
			if T then Vector3.new(1.7, 1.25, 3.3) else Vector3.new(1.9, 1.6, 2.5),
			Vector3.new(0, if T then 1.0 else 1.15, 0),
			body
		)
		E(Vector3.new(1.2, 0.9, 1.3), Vector3.new(0, if T then 0.75 else 0.85, 0.4), glow, "Glow", Enum.Material.Neon)
		bone = "head"
		local head = Vector3.new(0, if T then 1.45 else 1.75, if T then 1.7 else 1.25)
		E(if T then Vector3.new(1.2, 1.0, 1.4) else Vector3.new(1.3, 1.3, 1.3), head, body)
		E(Vector3.new(0.5, 0.45, if T then 1.6 else 1.2), head + Vector3.new(0, -0.15, if T then 0.95 else 0.8), belly)
		E(
			Vector3.new(0.26, 0.26, 0.26),
			head + Vector3.new(0, -0.12, if T then 1.75 else 1.4),
			Color3.fromRGB(30, 20, 20)
		)
		for _, s in ipairs({ -1, 1 }) do
			add(
				"Ellipsoid",
				Vector3.new(0.6, if T then 0.75 else 0.62, 0.2),
				CFrame.new(head + Vector3.new(s * 0.42, 0.55, -0.1)) * CFrame.Angles(0, 0, s * -0.3),
				accent
			)
		end
		eyes(head + Vector3.new(0, 0.16, 0.5), if T then 0.25 else 0.27, if T then 0.17 else 0.21, 0.045)
		for i = 1, 4 do
			local s = if i % 2 == 0 then 1 else -1
			add(
				"Cylinder",
				Vector3.new(0.65, 0.32, 0.32),
				CFrame.new(s * 0.5, 0.35, if i <= 2 then 0.6 else -0.6) * CFrame.Angles(0, 0, math.rad(90)),
				accent,
				"Leg"
			)
		end
		local n = if T then 11 else 8
		local prev = Vector3.new(0, if T then 0.95 else 1.1, if T then -1.6 else -1.2)
		for i = 0, n - 1 do
			local t = i / n
			local ang = t * (if T then 2.4 else 3.6)
			local p = Vector3.new(
				0,
				prev.Y + (if T then 0.12 else 0.22) * math.cos(ang),
				prev.Z - (if T then 0.32 else 0.22) * math.cos(ang * 0.6)
			)
			local tip = i >= n - 2
			local ring = T and i % 2 == 0
			local r = (if T then 0.4 else 0.34) * (1 - t * 0.35)
			local color = if tip or ring
				then glow
				else (if T then Color3.fromRGB(70, 64, 62) else Color3.fromRGB(214, 176, 170))
			E(Vector3.new(r, r, r), p, color, "Tail", if tip or ring then Enum.Material.Neon else nil)
			prev = p
		end
	elseif a == "Axolotl" then
		local lift = if T then 0.5 else 0
		E(
			if T then Vector3.new(1.7, 1.25, 3.4) else Vector3.new(1.9, 1.15, 2.7),
			Vector3.new(0, 0.85 + lift, -0.1),
			body,
			nil,
			Enum.Material.Glass
		)
		bone = "head"
		local head = Vector3.new(0, (if T then 1.55 else 1.05) + lift * 0.5, if T then 1.6 else 1.35)
		E(if T then Vector3.new(2.1, 1.3, 1.7) else Vector3.new(2.3, 1.45, 1.7), head, body, nil, Enum.Material.Glass)
		eyes(head + Vector3.new(0, 0.25, 0.62), if T then 0.55 else 0.6, if T then 0.16 else 0.2, 0.07)
		smile(head + Vector3.new(0, -0.2, 0.82), 0.34)
		for _, s in ipairs({ -1, 1 }) do
			for k = 0, 2 do
				add(
					"Ellipsoid",
					Vector3.new(0.25, 1.0, 0.35),
					CFrame.new(head + Vector3.new(s * (if T then 1.0 else 1.05), 0.3 + k * 0.22, -0.3 - k * 0.1))
						* CFrame.Angles(0, 0, s * (0.9 + k * 0.15)),
					glow,
					"Gill",
					Enum.Material.Neon
				)
			end
		end
		E(
			Vector3.new(0.16, 1.1, 2.2),
			Vector3.new(0, 1.0 + lift, if T then -2.0 else -1.6),
			if T then Color3.fromRGB(214, 170, 74) else accent,
			"Tail"
		)
		local legsN = if T then 6 else 4
		for i = 1, legsN do
			local s = if i % 2 == 0 then 1 else -1
			local z = ({ 0.7, -0.7, 0 })[math.ceil(i / 2)]
			E(Vector3.new(0.44, 0.76, 0.44), Vector3.new(s * 0.85, 0.4, z), body, "Leg")
		end
		if T then
			bone = "spine"
			for k = 0, 4 do
				add(
					"Cylinder",
					Vector3.new(0.12, 1.4, 1.15),
					CFrame.new(0, 0.95 + lift, -0.9 + k * 0.42) * CFrame.Angles(0, math.rad(90), 0),
					Color3.fromRGB(226, 186, 80),
					"Body",
					Enum.Material.Metal
				)
			end
		end
	elseif a == "Tortoise" then
		bone = "body"
		if not T then
			E(Vector3.new(2.5, 2.2, 2.9), Vector3.new(0, 0.9, 0), body)
			for i = 0, 11 do
				local ang, el = i * 2.4, 0.35 + (i % 4) * 0.2
				E(
					Vector3.new(0.6, 0.25, 0.6),
					Vector3.new(
						math.cos(ang) * 1.2 * math.cos(el),
						0.9 + math.sin(el) * 1.05,
						math.sin(ang) * 1.4 * math.cos(el)
					),
					if i % 3 == 0 then accent else belly
				)
			end
		else
			add(
				"Cylinder",
				Vector3.new(0.6, 2.8, 2.8),
				CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)),
				body
			)
			bone = "ringA"
			add(
				"Cylinder",
				Vector3.new(0.55, 2.2, 2.2),
				CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
				belly
			)
			bone = "ringB"
			add("Cylinder", Vector3.new(0.5, 1.5, 1.5), CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)), body)
			-- Disco de cielo sobre las terrazas: noche con estrellas y borde de oro,
			-- inclinado hacia el frente para que se lea desde la cámara del jugador.
			bone = "skyDisc"
			local disc = CFrame.new(0, 2.45, 0.1) * CFrame.Angles(0.38, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
			add("Cylinder", Vector3.new(0.1, 2.3, 2.3), disc, Color3.fromRGB(226, 182, 80), "Body", Enum.Material.Metal)
			add(
				"Cylinder",
				Vector3.new(0.16, 1.95, 1.95),
				disc * CFrame.new(0.04, 0, 0),
				Color3.fromRGB(30, 38, 84),
				"Body",
				Enum.Material.Neon
			)
			for k = 0, 6 do
				local r = 0.25 + (k % 3) * 0.24
				local ang = k * 2.39
				E(
					Vector3.new(0.09, 0.09, 0.09),
					(disc * CFrame.new(0.13, math.cos(ang) * r, math.sin(ang) * r)).Position,
					Color3.fromRGB(255, 244, 214),
					"Body",
					Enum.Material.Neon
				)
			end
			-- Sol de copal girando detrás del disco
			add(
				"Cylinder",
				Vector3.new(0.12, 0.9, 0.9),
				CFrame.new(0, 3.35, -0.35),
				Color3.fromRGB(246, 200, 92),
				"SpinZ",
				Enum.Material.Neon
			)
		end
		for i = 1, 4 do
			local s = if i % 2 == 0 then 1 else -1
			add(
				"Cylinder",
				Vector3.new(0.75, 0.62, 0.62),
				CFrame.new(s * 0.85, 0.35, if i <= 2 then 0.75 else -0.75) * CFrame.Angles(0, 0, math.rad(90)),
				belly,
				"Leg"
			)
		end
		bone = "head"
		local head = Vector3.new(0, if T then 1.05 else 0.9, if T then 1.85 else 1.6)
		E(Vector3.new(1.0, 0.9, 1.1), head, belly)
		eyes(head + Vector3.new(0, 0.12, 0.38), 0.22, if T then 0.13 else 0.16, 0.07)
		smile(head + Vector3.new(0, -0.18, 0.5), 0.18)
	elseif a == "Heron" then
		bone = "root"
		-- Ser Sagrado (Copalia): garza alta; patas de raíz que se abren en el suelo,
		-- cuello en S, alas de hoja con faroles colgantes.
		local bark = Color3.fromRGB(96, 70, 52)
		for _, sx in ipairs({ -1, 1 }) do
			add(
				"Cylinder",
				Vector3.new(2.6, 0.32, 0.32),
				CFrame.new(sx * 0.45, 1.3, -0.1) * CFrame.Angles(0, 0, math.rad(90)),
				bark,
				"Leg"
			)
			for k = 0, 2 do
				local ang = sx * (0.5 + k * 0.6)
				add(
					"Cylinder",
					Vector3.new(1.1, 0.2, 0.2),
					CFrame.new(sx * 0.45 + math.sin(ang) * 0.4, 0.12, -0.1 + math.cos(ang) * 0.4)
						* CFrame.Angles(0, ang, math.rad(10)),
					bark
				)
			end
		end
		bone = "spine"
		E(Vector3.new(1.6, 1.4, 2.4), Vector3.new(0, 3.1, -0.2), body)
		E(Vector3.new(1.2, 0.9, 1.6), Vector3.new(0, 2.85, 0.05), belly)
		bone = "neck"
		local neck =
			{ Vector3.new(0, 3.7, 0.8), Vector3.new(0, 4.3, 1.0), Vector3.new(0, 4.9, 0.8), Vector3.new(0, 5.4, 1.05) }
		for _, pos in ipairs(neck) do
			E(Vector3.new(0.5, 0.75, 0.5), pos, body)
		end
		bone = "head"
		local head = Vector3.new(0, 5.75, 1.3)
		E(Vector3.new(0.7, 0.6, 0.85), head, belly)
		add(
			"Block",
			Vector3.new(0.18, 0.16, 1.2),
			CFrame.new(head + Vector3.new(0, -0.05, 0.85)) * CFrame.Angles(math.rad(8), 0, 0),
			Color3.fromRGB(226, 182, 80)
		)
		eyes(head + Vector3.new(0, 0.12, 0.3), 0.26, 0.11, 0.0)
		-- Cresta de hojas
		for k = -1, 1 do
			add(
				"Ellipsoid",
				Vector3.new(0.22, 0.9, 0.4),
				CFrame.new(head + Vector3.new(k * 0.12, 0.45, -0.25)) * CFrame.Angles(-0.6, 0, k * 0.3),
				accent
			)
		end
		-- Alas de hoja con faroles
		bone = "spine"
		for _, sx in ipairs({ -1, 1 }) do
			for k = 0, 2 do
				add(
					"Ellipsoid",
					Vector3.new(0.18, 1.0 + k * 0.15, 2.0 - k * 0.3),
					CFrame.new(sx * (0.85 + k * 0.28), 3.3 + k * 0.15, -0.3 - k * 0.2)
						* CFrame.Angles(0.15, 0, sx * (0.45 + k * 0.2)),
					accent,
					"Gill"
				)
			end
			for k = 0, 1 do
				E(
					Vector3.new(0.32, 0.42, 0.32),
					Vector3.new(sx * (1.2 + k * 0.35), 2.55 - k * 0.15, -0.4 - k * 0.3),
					glow,
					"Glow",
					Enum.Material.Neon
				)
			end
		end
		-- Cola de hojas
		add(
			"Ellipsoid",
			Vector3.new(0.9, 0.25, 1.4),
			CFrame.new(0, 3.0, -1.6) * CFrame.Angles(0.3, 0, 0),
			accent,
			"Tail"
		)
	else
		-- Arquetipos de rivales del vertical slice (Agave, Armadillo, Cicada, Jar, Beetle)
		E(Vector3.new(2.0, 1.7, 2.3), Vector3.new(0, 1.0, 0), body)
		if a == "Agave" then
			for i = 0, 7 do
				local ang = i / 8 * math.pi * 2
				add(
					"Ellipsoid",
					Vector3.new(0.5, 2.0, 0.25),
					CFrame.new(math.cos(ang) * 0.9, 1.3, math.sin(ang) * 0.9)
						* CFrame.Angles(math.sin(ang) * 0.7, 0, -math.cos(ang) * 0.7),
					accent
				)
			end
		elseif a == "Armadillo" then
			for k = -2, 2 do
				add(
					"Cylinder",
					Vector3.new(0.18, 1.85, 1.85),
					CFrame.new(0, 1.0, k * 0.35) * CFrame.Angles(0, math.rad(90), 0),
					glow,
					"Glow",
					Enum.Material.Neon
				)
			end
		elseif a == "Cicada" then
			for _, s in ipairs({ -1, 1 }) do
				add(
					"Ellipsoid",
					Vector3.new(0.9, 0.12, 2.4),
					CFrame.new(s * 0.6, 1.6, -0.4) * CFrame.Angles(0.3, s * 0.3, s * 0.25),
					Color3.fromRGB(210, 240, 250),
					"Gill",
					Enum.Material.Glass
				)
			end
		elseif a == "Jar" then
			add(
				"Cylinder",
				Vector3.new(0.3, 1.5, 1.5),
				CFrame.new(0, 2.0, 0) * CFrame.Angles(0, 0, math.rad(90)),
				accent
			)
		elseif a == "Beetle" then
			for _, s in ipairs({ -1, 1 }) do
				E(Vector3.new(1.1, 1.0, 2.2), Vector3.new(s * 0.45, 1.25, -0.05), accent)
			end
		end
		bone = "head"
		eyes(Vector3.new(0, 1.3, 1.05), 0.3, 0.2, 0.02)
		smile(Vector3.new(0, 0.98, 1.12), 0.24)
		for i = 1, 4 do
			local s = if i % 2 == 0 then 1 else -1
			add(
				"Cylinder",
				Vector3.new(0.5, 0.3, 0.3),
				CFrame.new(s * 0.6, 0.25, if i <= 2 then 0.5 else -0.5) * CFrame.Angles(0, 0, math.rad(90)),
				accent,
				"Leg"
			)
		end
	end

	-- Cola repartida en tail1..tail5 (como los rigs de los modelos importados)
	local tails = {}
	for _, rec in ipairs(parts) do
		if rec.kind == "Tail" then
			table.insert(tails, rec)
		end
	end
	for i, rec in ipairs(tails) do
		local name = "tail" .. tostring(math.min(5, math.floor((i - 1) * 5 / #tails) + 1))
		rec.part.Name = name
		rec.part:SetAttribute("Bone", name)
	end

	local scale = if T then vis.talladoScale else vis.broteScale
	for _, rec in ipairs(parts) do
		rec.part.Size *= scale
		rec.offset = CFrame.new(rec.offset.Position * scale) * rec.offset.Rotation
	end
	local creature: Creature = {
		model = model,
		parts = parts,
		speciesId = speciesId,
		form = form,
		scale = scale,
		phase = math.random() * 10,
		opaco = 0,
		react = 0,
		aura = nil,
		destroy = function(self: Creature)
			self.model:Destroy()
		end,
	}
	-- Aura por rareza (p. 26 y 120): ninguna en Comunes; en el Brote, como mucho un emisor
	-- discreto. Es la identidad de rareza, no una decoración: se apaga si está opacado.
	local rarityId = if SpeciesConfig.ById[speciesId]
		then SpeciesConfig.ById[speciesId].rarity
		elseif Guardians.ById[speciesId] then Guardians.ById[speciesId].rarity
		else nil
	local rarity = if rarityId then Rarities.ById[rarityId] else nil
	if rarity and rarity.auraEmitters > 0 and #parts > 0 then
		local strength = if T then rarity.auraEmitters else 1
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "RarityAura"
		aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		aura.Color = ColorSequence.new(Color3.fromRGB(rarity.frameColor[1], rarity.frameColor[2], rarity.frameColor[3]))
		aura.LightEmission = 1
		aura.Rate = 2 + strength * 2
		aura.Lifetime = NumberRange.new(1.2, 2.2)
		aura.Speed = NumberRange.new(0.4, 1)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.25 * scale)
		aura.Parent = parts[1].part
		creature.aura = aura
	end
	CreatureBuilder.setOpaco(creature, if opts and opts.opaco then 1 else 0)
	model.Parent = if opts and opts.parent then opts.parent else Workspace
	return creature
end

-- Pose estática (retratos en ViewportFrame: BulkMoveTo solo aplica en Workspace).
function CreatureBuilder.pose(c: Creature, root: CFrame)
	for _, rec in ipairs(c.parts) do
		rec.part.CFrame = root * rec.offset
	end
end

-- Retrato 3D para cartas y fichas (la Biblia pide ViewportFrame con el modelo).
function CreatureBuilder.portrait(speciesId: string, form: string, size: UDim2?): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Size = size or UDim2.fromOffset(160, 160)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 170, 150)
	vp.LightColor = Color3.fromRGB(255, 236, 210)
	vp.LightDirection = Vector3.new(-1, -1.4, -1)
	local c = CreatureBuilder.build(speciesId, form, { parent = vp })
	CreatureBuilder.pose(c, CFrame.Angles(0, math.rad(-35), 0))
	local cam = Instance.new("Camera")
	local extent = c.model:GetExtentsSize()
	local d = math.max(extent.X, extent.Y, extent.Z) * 1.9
	local center = Vector3.new(0, extent.Y * 0.45, 0)
	cam.FieldOfView = 34
	cam.CFrame = CFrame.lookAt(center + Vector3.new(d * 0.2, d * 0.22, d), center)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

-- Niebla gris: desatura la criatura (1 = Opaco, 0 = restaurada con sus colores).
function CreatureBuilder.setOpaco(c: Creature, amount: number)
	c.opaco = amount
	if c.aura then
		c.aura.Enabled = amount < 0.5
	end
	for _, rec in ipairs(c.parts) do
		rec.part.Color = rec.baseColor:Lerp(GREY, amount * 0.85)
		if rec.kind == "Mesh" then
			-- malla importada: el tinte va en SurfaceAppearance (el color de la pieza no se ve)
			local sa = rec.part:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				sa.Color = Color3.new(1, 1, 1):Lerp(GREY, amount * 0.85)
			end
		end
		if rec.kind == "Glow" or rec.kind == "Gill" then
			rec.part.Material = if amount > 0.5 then Enum.Material.SmoothPlastic else Enum.Material.Neon
		end
	end
end

-- Coloca y anima la criatura. moving = se desplaza; t = tiempo global.
local cfs: { CFrame } = {}
local list: { BasePart } = {}
function CreatureBuilder.update(c: Creature, root: CFrame, t: number, dt: number, moving: boolean)
	local ph = t * (if moving then 9 else 2.2) + c.phase
	local bob = if moving then math.abs(math.sin(ph)) * 0.35 * c.scale else math.sin(ph) * 0.06 * c.scale
	local spin = 0
	if c.react > 0 then
		c.react = math.max(0, c.react - dt)
		local k = c.react / 0.9
		bob += math.sin(k * math.pi) * 1.6
		spin = (1 - k) * math.pi * 2
	end
	local base = root * CFrame.new(0, bob, 0) * CFrame.Angles(0, spin, 0)
	table.clear(cfs)
	table.clear(list)
	for _, rec in ipairs(c.parts) do
		local anim = CFrame.identity
		if rec.kind == "Tail" then
			anim = CFrame.new(math.sin(t * 3 + rec.index * 0.6) * 0.05 * rec.index * 0.3, 0, 0)
		elseif rec.kind == "Gill" then
			anim = CFrame.Angles(0, math.sin(t * 2.5 + rec.index) * 0.25, 0)
		elseif rec.kind == "Leg" and moving then
			anim = CFrame.Angles(math.sin(ph + (rec.index % 2) * math.pi) * 0.6, 0, 0)
		elseif rec.kind == "SpinY" then
			anim = CFrame.Angles(0, t * 0.4, 0)
		elseif rec.kind == "SpinZ" then
			anim = CFrame.Angles(0, -t * 0.9, 0)
		end
		table.insert(list, rec.part)
		table.insert(cfs, base * rec.offset * anim)
	end
	Workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

return CreatureBuilder
