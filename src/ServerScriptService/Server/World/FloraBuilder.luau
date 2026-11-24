--!strict
-- Vegetación de Valle Copal con plantillas clonadas (Genesis §9): cada especie se modela
-- una vez en el origen (2 variantes) y se clona con escala, giro, inclinación y tono de
-- follaje deterministas (FloraLayout). Especies con silueta propia:
--   Ahuejote  · alto y estrecho, columna de follaje (orillas y chinampas)
--   Copal     · tronco torcido rojizo y copa plana en sombrilla (pradera y ladera)
--   Sabino    · ahuehuete grande de copa caída (encuadra las vistas)
--   Colorín   · ramas abiertas con racimos de flor coral (acento, pocos)
--   Opacado   · árbol gris casi sin hojas (la Linde pierde el color)
-- Más arbustos, bugambilias, magueyes, milpa, juncos, rocas y matas de flores.
-- Todo es decoración: sin colisión ni consultas (no estorba al jugador ni al acompañante).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)
local FloraLayout = require(script.Parent.FloraLayout)

local FloraBuilder = {}

local K = WorldKit
local rgb = K.rgb
local M = Enum.Material
local F = Ambience.Flora

local function leaf(p: BasePart)
	p.Name = "Leaf"
end

-- El tronco sí colisiona (no se atraviesa un ahuehuete), pero no lo consultan los rayos
local function trunk(p: BasePart)
	p.Name = "Trunk"
	p.CanCollide = true
end

local function templates(): { [string]: { Model } }
	local store = Instance.new("Folder")
	local t: { [string]: { Model } } = {}
	local function new(kind: string): Model
		local m = K.model(kind, store)
		t[kind] = t[kind] or {}
		table.insert(t[kind], m)
		return m
	end
	local V = Vector3.new
	for variant = 1, 2 do
		local s = if variant == 1 then 1 else -1
		local sp = F.species

		-- Ahuejote: tronco fino y columna de follaje
		local a = new("Ahuejote")
		trunk(K.limb(V(0, 0, 0), V(0.3 * s, 10, 0.2), 0.55, rgb(sp.Ahuejote.trunk), M.Wood, a))
		for i, e in ipairs({ { 3.4, 5, 7.5 }, { 3.9, 6.2, 11 }, { 3.3, 5.6, 14.6 }, { 2.2, 4.2, 17.6 } }) do
			leaf(
				K.ellipsoid(
					V(e[1], e[2], e[1] * (0.9 + variant * 0.05)),
					CFrame.new(0.25 * s * i * 0.2, e[3], 0),
					rgb(sp.Ahuejote.leaves[(i % 2) + 1]),
					M.LeafyGrass,
					a
				)
			)
		end

		-- Copal: tronco torcido y copa en sombrilla
		local c = new("Copal")
		local cTrunk = rgb(sp.Copal.trunk)
		local fork = V(0.6 * s, 4, 0.3)
		trunk(K.limb(V(0, 0, 0), fork, 0.6, cTrunk, M.Wood, c))
		K.limb(fork, V(-2.4 * s, 7, 0.8), 0.38, cTrunk, M.Wood, c)
		K.limb(fork, V(2.6 * s, 7.6, -0.9), 0.38, cTrunk, M.Wood, c)
		leaf(K.ellipsoid(V(6, 2.6, 5.4), CFrame.new(-2.5 * s, 8, 0.7), rgb(sp.Copal.leaves[1]), M.LeafyGrass, c))
		leaf(K.ellipsoid(V(6.6, 3, 6), CFrame.new(2.5 * s, 8.5, -0.7), rgb(sp.Copal.leaves[2]), M.LeafyGrass, c))
		leaf(K.ellipsoid(V(5, 2.4, 4.8), CFrame.new(0, 9.7, 0.2 * s), rgb(sp.Copal.leaves[1]), M.LeafyGrass, c))

		-- Sabino (ahuehuete): tronco grueso con contrafuertes y copa caída
		local b = new("Sabino")
		local bTrunk = rgb(sp.Sabino.trunk)
		trunk(K.limb(V(0, 0, 0), V(0.4 * s, 13, 0), 1.8, bTrunk, M.Wood, b))
		K.limb(V(0, 3.5, 0), V(3 * s, 0, 1.2), 0.9, bTrunk, M.Wood, b)
		K.limb(V(0, 3, 0), V(-2.2 * s, 0, -2), 0.8, bTrunk, M.Wood, b)
		for i, e in ipairs({
			{ 12, 7, 11, 0, 16.5, 0 },
			{ 9, 6, 8, 5 * s, 13.5, 2 },
			{ 9.5, 6, 9, -5 * s, 14, -1 },
			{ 8, 5, 8, 1, 12.5, -5 * s },
			{ 7, 5, 7, -1, 20, 1 },
		}) do
			leaf(
				K.ellipsoid(
					V(e[1], e[2], e[3]),
					CFrame.new(e[4], e[5], e[6]),
					rgb(sp.Sabino.leaves[(i % 3) + 1]),
					M.LeafyGrass,
					b
				)
			)
		end

		-- Colorín: ramas abiertas y racimos de flor coral
		local r = new("Colorin")
		local rTrunk = rgb(sp.Colorin.trunk)
		local top = V(0.4 * s, 6, 0)
		trunk(K.limb(V(0, 0, 0), top, 0.5, rTrunk, M.Wood, r))
		K.limb(top, V(-2.2 * s, 9, 0.5), 0.3, rTrunk, M.Wood, r)
		K.limb(top, V(2.5 * s, 9.6, -0.4), 0.3, rTrunk, M.Wood, r)
		leaf(K.ellipsoid(V(5, 3, 4.6), CFrame.new(-2.2 * s, 9.8, 0.4), rgb(sp.Colorin.leaves[1]), M.LeafyGrass, r))
		leaf(K.ellipsoid(V(5.2, 3, 4.6), CFrame.new(2.5 * s, 10.3, -0.4), rgb(sp.Colorin.leaves[1]), M.LeafyGrass, r))
		for _, f in ipairs({ { -2.6 * s, 11.2, 1 }, { 2, 11.7, -1.2 }, { 3.4 * s, 10.6, 0.8 } }) do
			K.ball(1.3, V(f[1], f[2], f[3]), rgb(sp.Colorin.bloom), M.SmoothPlastic, r)
		end

		-- Opacado: árbol gris de la Linde, casi sin hojas
		local o = new("Opacado")
		local oTrunk = rgb(sp.Opacado.trunk)
		local oTop = V(0.3 * s, 6.5, 0.2)
		trunk(K.limb(V(0, 0, 0), oTop, 0.5, oTrunk, M.Wood, o))
		K.limb(oTop, V(-2.6 * s, 9.5, 1), 0.25, oTrunk, M.Wood, o)
		K.limb(oTop, V(2 * s, 10, -1.4), 0.25, oTrunk, M.Wood, o)
		K.limb(V(0.2, 4, 0), V(2.4 * s, 6, 1.6), 0.2, oTrunk, M.Wood, o)
		leaf(K.ellipsoid(V(3.4, 1.8, 3), CFrame.new(-2.2 * s, 9.8, 0.8), rgb(sp.Opacado.leaves[1]), M.Grass, o))

		-- Arbusto y bugambilia
		local bush = new("Bush")
		leaf(K.ellipsoid(V(3.8, 2.6, 3.4), CFrame.new(0, 1, 0), rgb(F.bush[1]), M.LeafyGrass, bush))
		leaf(K.ellipsoid(V(2.6, 2, 2.4), CFrame.new(1.6 * s, 0.8, 0.8), rgb(F.bush[2]), M.LeafyGrass, bush))
		local bou = new("Bougainvillea")
		leaf(K.ellipsoid(V(3.6, 2.8, 3.2), CFrame.new(0, 1.2, 0), rgb(F.bush[3]), M.LeafyGrass, bou))
		K.ellipsoid(V(2, 1.4, 1.8), CFrame.new(0.9 * s, 2.2, 0.5), rgb(F.bougainvillea), M.SmoothPlastic, bou)
		K.ellipsoid(V(1.6, 1.2, 1.6), CFrame.new(-1 * s, 1.8, -0.7), rgb(F.bougainvillea), M.SmoothPlastic, bou)

		-- Maguey: hojas en roseta
		local ag = new("Agave")
		for i = 0, 5 do
			local ang = i / 6 * math.pi * 2 + variant * 0.3
			K.box(
				V(0.5, 3.4, 1.1),
				CFrame.Angles(0, ang, 0) * CFrame.new(0, 1.4, -0.9) * CFrame.Angles(math.rad(-32 - (i % 2) * 14), 0, 0),
				rgb(F.agave),
				M.SmoothPlastic,
				ag
			)
		end

		-- Roca: dos masas superpuestas
		local rock = new("Rock")
		K.ellipsoid(V(3.2, 1.8, 2.6), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, 0.15 * s), rgb(F.rock), M.Slate, rock)
		K.ellipsoid(
			V(1.8, 1.3, 1.6),
			CFrame.new(1.3 * s, 0.4, 0.7),
			rgb(F.rock):Lerp(Color3.new(0, 0, 0), 0.12),
			M.Slate,
			rock
		)

		-- Milpa: tres cañas
		local maize = new("Maize")
		for i = 0, 2 do
			local ang = i / 3 * math.pi * 2
			local h = 4.4 + i * 0.5
			local base = V(math.cos(ang) * 0.6, 0, math.sin(ang) * 0.6)
			K.limb(
				base,
				base + V(math.cos(ang) * 0.4, h, math.sin(ang) * 0.4),
				0.16,
				rgb(F.maize[(i % 2) + 1]),
				M.Grass,
				maize
			)
		end

		-- Junco y tule
		local reed = new("Reed")
		for i = 0, 2 do
			local ang = i / 3 * math.pi * 2 + variant
			local base = V(math.cos(ang) * 0.5, 0, math.sin(ang) * 0.5)
			local tip = base + V(math.cos(ang) * 0.5, 3.6 + (i % 2) * 0.8, math.sin(ang) * 0.5)
			K.limb(base, tip, 0.12, rgb(F.reed[(i % 3) + 1]), M.Grass, reed)
			if i == 0 then
				K.ellipsoid(
					V(0.35, 1, 0.35),
					CFrame.new(tip - V(0, 0.6, 0)),
					rgb({ 104, 72, 50 }),
					M.SmoothPlastic,
					reed
				)
			end
		end
	end
	for _, d in ipairs(store:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CastShadow = d.Size.Magnitude > 3
		end
	end
	return t
end

local function tint(m: Model, kind: string, index: number)
	local spec = (F.species :: any)[kind]
	if not spec then
		return
	end
	local leaves = spec.leaves
	local i = 0
	for _, d in ipairs(m:GetChildren()) do
		if d:IsA("BasePart") and d.Name == "Leaf" then
			i += 1
			d.Color = rgb(leaves[((index + i) % #leaves) + 1])
		end
	end
end

function FloraBuilder.build(root: Instance): { trees: number, props: number }
	local folder = K.folder("Flora", root)
	local tpl = templates()
	local trees, count = 0, 0
	local function put(kind: string, variant: number, cf: CFrame, s: number): Model
		local list = tpl[kind]
		local m = K.place(list[((variant - 1) % #list) + 1], cf, s, folder)
		count += 1
		return m
	end
	for _, p in ipairs(FloraLayout.props()) do
		local cf = CFrame.new(p.x, p.y, p.z) * CFrame.Angles(p.tilt, p.yaw, p.tilt * 0.5)
		local m = put(p.kind, p.variant, cf, p.scale)
		tint(m, p.kind, p.tint)
		if FloraLayout.isTree(p.kind) then
			trees += 1
		end
	end
	for _, crop in ipairs(FloraLayout.crops()) do
		put(crop.kind, 1, CFrame.new(crop.x, crop.y, crop.z) * CFrame.Angles(0, crop.yaw, 0), crop.scale)
	end
	for i, reed in ipairs(FloraLayout.reeds()) do
		put("Reed", i, CFrame.new(reed.x, reed.y, reed.z) * CFrame.Angles(0, reed.yaw, 0), reed.scale)
	end
	-- Matas de flores (hoja + pétalos)
	local cfg = Ambience.Flowers
	for _, cluster in ipairs(FloraLayout.clusters()) do
		K.ellipsoid(
			Vector3.new(cfg.petalSize * 2.2, 0.5, cfg.petalSize * 2.2),
			CFrame.new(cluster.x, 0.2, cluster.z),
			K.C.leafDeep,
			M.LeafyGrass,
			folder
		).CastShadow =
			false
		for _, petal in ipairs(cluster.petals) do
			local p = K.ellipsoid(
				Vector3.new(cfg.petalSize, cfg.petalSize * 0.8, cfg.petalSize),
				CFrame.new(cluster.x + petal.dx, 0.65, cluster.z + petal.dz),
				rgb(cfg.colors[petal.color]),
				M.SmoothPlastic,
				folder
			)
			p.CastShadow = false
		end
	end
	return { trees = trees, props = count }
end

-- Plantillas para otros constructores (ahuejotes de las chinampas, macetas del lote…)
FloraBuilder.templates = templates

return FloraBuilder
