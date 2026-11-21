--!strict
-- Construye BLOCKOUTS de criaturas a partir de Config/Visuals (arquetipo + paleta).
-- Son modelos provisionales del lado del cliente (no colisionan, no se replican) y
-- se marcan con AssetStatus = "Blockout". Cuando existan modelos aprobados, este
-- módulo clonará el activo real indicado en Visuals.modelAsset.
--
-- Animación: todas las piezas están ancladas; cada fotograma se recalcula su CFrame
-- respecto a la raíz y se aplica con workspace:BulkMoveTo (barato y sin física).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Visuals = require(Config:WaitForChild("Visuals"))

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

function CreatureBuilder.build(speciesId: string, form: string, opts: { opaco: boolean?, parent: Instance? }?): Creature
	local vis = Visuals.ById[speciesId]
	assert(vis, "Sin VisualConfiguration para " .. speciesId)
	local T = form == "Tallado"
	local pal = if T then vis.tallado else vis.brote
	local model = Instance.new("Model")
	model.Name = speciesId .. "_" .. form
	model:SetAttribute("AssetStatus", vis.assetStatus)
	local parts: { PartRec } = {}
	local counter = 0

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
		table.insert(parts, { part = p, offset = offset, kind = kind or "Body", index = counter, baseColor = color })
		return p
	end
	local body, belly, accent = rgb(pal.body), rgb(pal.belly), rgb(pal.accent)
	local glow = rgb(pal.emissive)
	local function E(size: Vector3, pos: Vector3, color: Color3, kind: string?, material: Enum.Material?)
		return add("Ellipsoid", size, CFrame.new(pos), color, kind, material)
	end
	local function eyes(center: Vector3, spread: number, size: number)
		for _, s in ipairs({ -1, 1 }) do
			local c = center + Vector3.new(s * spread, 0, 0)
			if not T then
				E(Vector3.new(size * 2, size * 2.2, size * 1.4), c, Color3.fromRGB(250, 250, 246))
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

	local a = vis.archetype
	if a == "Opossum" then
		E(
			if T then Vector3.new(1.7, 1.25, 3.3) else Vector3.new(1.9, 1.6, 2.5),
			Vector3.new(0, if T then 1.0 else 1.15, 0),
			body
		)
		E(Vector3.new(1.2, 0.9, 1.3), Vector3.new(0, if T then 0.75 else 0.85, 0.4), glow, "Glow", Enum.Material.Neon)
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
		eyes(head + Vector3.new(0, 0.16, 0.5), if T then 0.25 else 0.27, if T then 0.17 else 0.21)
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
		local head = Vector3.new(0, (if T then 1.55 else 1.05) + lift * 0.5, if T then 1.6 else 1.35)
		E(if T then Vector3.new(2.1, 1.3, 1.7) else Vector3.new(2.3, 1.45, 1.7), head, body, nil, Enum.Material.Glass)
		eyes(head + Vector3.new(0, 0.25, 0.62), if T then 0.55 else 0.6, if T then 0.16 else 0.2)
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
			add(
				"Cylinder",
				Vector3.new(0.55, 2.2, 2.2),
				CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
				belly
			)
			add("Cylinder", Vector3.new(0.5, 1.5, 1.5), CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)), body)
			add(
				"Cylinder",
				Vector3.new(0.12, 3.4, 3.4),
				CFrame.new(0, 2.2, 0),
				Color3.fromRGB(236, 196, 96),
				"SpinZ",
				Enum.Material.Neon
			)
			add(
				"Cylinder",
				Vector3.new(0.16, 1.9, 1.9),
				CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(28, 36, 70),
				"SpinY",
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
		local head = Vector3.new(0, if T then 1.05 else 0.9, if T then 1.85 else 1.6)
		E(Vector3.new(1.0, 0.9, 1.1), head, belly)
		eyes(head + Vector3.new(0, 0.12, 0.38), 0.22, if T then 0.13 else 0.16)
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
		eyes(Vector3.new(0, 1.3, 1.05), 0.3, 0.2)
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
		destroy = function(self: Creature)
			self.model:Destroy()
		end,
	}
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
	for _, rec in ipairs(c.parts) do
		rec.part.Color = rec.baseColor:Lerp(GREY, amount * 0.85)
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
