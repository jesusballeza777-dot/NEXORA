--!strict
-- El Gran Nexo (landmark de ~105 studs, Genesis §2): estructura viva, antigua y sagrada,
-- no un árbol cualquiera.
--   · Tronco de cinco hebras retorcidas en espiral (cilindros girados por segmentos) con
--     un alma central; vetas de copal (Neon ≤ 1,5 studs) metidas en los surcos.
--   · Un hueco al frente (mira al spawn) con el corazón de copal: lo anima el cliente
--     (AmbientHeart) y conserva el prompt «NexoMenu».
--   · Raíces enormes que salen del tronco, abrazan el basamento y levantan sus losas
--     (TorreBuilder recibe sus ángulos para inclinar las losas que pisan).
--   · Ramas que se abren en tres capas de copa con verdes distintos y faroles de copal.
-- Presupuesto: ~260 partes, 6 luces (faroles) + 1 (corazón), 1 emisor (corazón).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local WorldKit = require(script.Parent.WorldKit)

local GranNexoBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local STRANDS = 5
local TURNS = 0.95
-- Ángulos de las raíces (grados, atan2(z, x)); el frente (90°) queda libre para el corazón
GranNexoBuilder.RootAngles = { 18, 54, 126, 162, 200, 238, 290, 334 }
GranNexoBuilder.RootReach = 17.5

local function polar(base: Vector3, deg: number, r: number, y: number): Vector3
	local a = math.rad(deg)
	return base + V(math.cos(a) * r, y, math.sin(a) * r)
end

function GranNexoBuilder.build(root: Instance): Model
	local tree = K.model("GranNexo", root)
	local base = K.v3(World.GranNexo.position)
	local H = World.GranNexo.trunkHeight
	local barks = { C.bark, C.barkDark, C.bark, C.barkPale:Lerp(C.bark, 0.5), C.barkDark }

	-- Alma del tronco (rellena el centro de las hebras)
	local core = K.limb(base - V(0, 1, 0), base + V(0, H * 0.55, 0), 5.2, C.barkDark, M.Wood, tree, true)
	core.Name = "Trunk"
	K.limb(base + V(0, H * 0.55, 0), base + V(0, H * 0.95, 0), 3.4, C.barkDark, M.Wood, tree, true)

	-- Hebras en espiral
	local function strandAt(k: number, t: number): (Vector3, number)
		local hr = 5.6 - 2.4 * t
		local deg = k * 360 / STRANDS + t * TURNS * 360
		return polar(base, deg, hr, t * H - (1 - t) * 1), 4.1 - 1.8 * t
	end
	local tops: { Vector3 } = {}
	local steps = 8
	for k = 0, STRANDS - 1 do
		local prev, prevR = strandAt(k, 0)
		for i = 1, steps do
			local p, r = strandAt(k, i / steps)
			K.limb(prev, p, (r + prevR) / 2, barks[k + 1], M.Wood, tree, true)
			if i < steps then
				K.ball(r * 2, p, barks[k + 1], M.Wood, tree)
			end
			prev, prevR = p, r
		end
		tops[k + 1] = prev
	end

	-- Vetas de copal en tres surcos (empiezan por encima del corazón)
	for _, k in ipairs({ 1, 2, 4 }) do
		local prev: Vector3? = nil
		for i = 2, 7 do
			local t = i / 8
			local hr, sr = 5.6 - 2.4 * t, 4.1 - 1.8 * t
			local half = math.rad(180 / STRANDS)
			local rv = hr * math.cos(half) + math.sqrt(math.max(0, sr * sr - (hr * math.sin(half)) ^ 2)) + 0.2
			local deg = k * 360 / STRANDS + 36 + t * TURNS * 360
			local p = polar(base, deg, rv, t * H)
			if prev then
				local vein = K.limb(prev, p, 0.25, C.copalGlow, M.Neon, tree)
				vein.CastShadow = false
			end
			prev = p
		end
	end

	-- Hueco del corazón: arco de corteza que enmarca el corazón de copal
	local front = 7.4
	local hp = base + V(0, 9, front)
	local arch = { V(-3.4, -3, 0), V(-2.4, 3.6, 0.3), V(2.4, 3.6, 0.3), V(3.4, -3, 0) }
	for i = 1, #arch - 1 do
		K.limb(hp + arch[i], hp + arch[i + 1], 0.95, C.barkDark, M.Wood, tree)
	end
	K.ellipsoid(V(5.4, 7, 2.2), CFrame.new(hp - V(0, 0, 1.4)), C.cacao, M.Wood, tree)
	local heart = K.ellipsoid(V(3.4, 4.6, 2.8), CFrame.new(hp), C.copal, M.Glass, tree)
	heart.Name = "NexoHeart"
	heart.Transparency = 0.2
	heart.CastShadow = false
	heart:SetAttribute("BaseSize", heart.Size)
	heart:AddTag("AmbientHeart")
	local heartCore = K.ball(1.4, hp, C.copalGlow, M.Neon, tree)
	heartCore.Name = "HeartCore"
	heartCore.CastShadow = false
	K.light(heartCore, C.copalGlow, 12, 1.6)
	K.emitter(heart, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(C.copalGlow),
		Rate = 6,
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(0.6, 1.4),
		SpreadAngle = Vector2.new(60, 60),
		Size = NumberSequence.new(0.3),
		LightEmission = 1,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "NexoMenu"
	prompt.ActionText = "Abrir el menú del árbol"
	prompt.ObjectText = "Gran Nexo"
	prompt.MaxActivationDistance = World.GranNexo.interactRadius
	prompt.RequiresLineOfSight = false
	prompt.Parent = heart

	-- Raíces: arquean sobre el basamento y se hunden antes de la calzada del Gabinete
	local reach = GranNexoBuilder.RootReach
	local profile = { { 6.5, 5, 3.0 }, { 9.6, 3.2, 2.5 }, { 12.6, 1.5, 1.8 }, { 15.2, 0.4, 1.2 }, { reach, -0.8, 0.8 } }
	for i, deg in ipairs(GranNexoBuilder.RootAngles) do
		local prev: Vector3? = nil
		local prevR = 0
		for j, pr in ipairs(profile) do
			local wiggle = math.sin(i * 1.7 + j) * 5
			local p = polar(base, deg + wiggle, pr[1] * (if i % 2 == 0 then 0.96 else 1), pr[2])
			if prev then
				local root = K.limb(prev, p, (pr[3] + prevR) / 2, barks[(i % 5) + 1], M.Wood, tree, true)
				root.CanQuery = false
				if j < #profile then
					K.ball(pr[3] * 2, p, barks[(i % 5) + 1], M.Wood, tree)
				end
			end
			prev, prevR = p, pr[3]
		end
	end

	-- Ramas: cada hebra se abre en una rama principal; tres ramas bajas entre ellas
	local branchTips: { Vector3 } = {}
	local midTips: { Vector3 } = {}
	for k, top in ipairs(tops) do
		local out = (V(top.X, 0, top.Z) - V(base.X, 0, base.Z)).Unit
		local p1 = top + out * 9 + V(0, 8, 0)
		local p2 = p1 + out * 11 + V(0, 6, 0)
		local p3 = p2 + out * 8 + V(0, 4, 0)
		K.limb(top, p1, 2.1, barks[k], M.Wood, tree)
		K.ball(3.6, p1, barks[k], M.Wood, tree)
		K.limb(p1, p2, 1.5, barks[k], M.Wood, tree)
		K.limb(p2, p3, 0.9, barks[k], M.Wood, tree)
		K.limb(p2, p2 + V(0, 10, 0) - out * 5, 0.7, barks[k], M.Wood, tree)
		table.insert(branchTips, p3)
		table.insert(midTips, p2)
	end
	for i = 0, 2 do
		local deg = 54 + i * 120
		local start = base + V(0, H * 0.78, 0)
		local tip = polar(base, deg, 24, H * 0.78 + 6)
		K.limb(start, tip, 1.2, C.bark, M.Wood, tree)
		table.insert(midTips, tip)
	end

	-- Copa en tres capas: baja (verde hondo), media (hoja) y corona (hoja clara)
	local function mass(size: Vector3, pos: Vector3, color: Color3)
		K.ellipsoid(size, CFrame.new(pos) * CFrame.Angles(0, (pos.X + pos.Z) * 0.07, 0), color, M.LeafyGrass, tree)
	end
	for i, p in ipairs(midTips) do
		mass(V(25, 9.5, 21), p + V(0, 3, 0), if i % 2 == 0 then C.leafDeep else C.jadeDeep:Lerp(C.leafDeep, 0.5))
	end
	for i, p in ipairs(branchTips) do
		mass(V(27, 11, 23), p + V(0, 3.5, 0), if i % 2 == 0 then C.leaf else C.leaf:Lerp(C.leafDeep, 0.35))
		-- Puente de follaje hacia la rama vecina: la copa se lee como una sola capa
		local nxt = branchTips[(i % #branchTips) + 1]
		mass(
			V(18, 8, 16),
			(p + nxt) / 2 + V(0, 1, 0) - (V((p + nxt).X / 2, 0, (p + nxt).Z / 2) - V(base.X, 0, base.Z)) * 0.12,
			C.leaf:Lerp(C.leafDeep, 0.2)
		)
	end
	for i = 0, 3 do
		local deg = i * 90 + 30
		mass(V(23, 12, 20), polar(base, deg, 10, 91), C.leafPale:Lerp(C.leaf, 0.45))
	end
	mass(V(20, 11, 18), base + V(0, 99, 0), C.leafPale:Lerp(C.leaf, 0.3))
	for i = 0, 4 do
		mass(V(15, 7, 13), polar(base, i * 72 + 10, 17, 65), C.jadeDeep)
	end

	-- Faroles de copal colgando de las ramas (6 con luz, 4 sin luz)
	for i, p in ipairs(midTips) do
		if i <= 7 then
			K.lantern(p - V(0, 3, 0), 2 + (i % 3) * 1.5, tree, i <= 6)
		end
	end
	for i = 1, 3 do
		local p = branchTips[i]
		K.lantern(p - V(0, 3.5, 0), 2.5, tree, false)
	end

	tree.PrimaryPart = core
	return tree
end

return GranNexoBuilder
