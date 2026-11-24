--!strict
-- Lo construido sobre el agua (el agua en sí es Terrain, ver Landform):
--   · puentes de madera en arco, perpendiculares al cauce, con barandal y estribos;
--   · surcos y cultivos de las chinampas, canoas y el embarcadero del lago;
--   · cempasúchil y hojas que flotan, nenúfares en las orillas tranquilas;
--   · espuma, chorros y bruma al pie de la cascada.
-- Puentes y embarcadero son sólidos (se caminan); el resto es decoración.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local Ambience = require(Shared.Config.Ambience)
local Rng = require(Shared.Domain.Rng)
local WorldKit = require(script.Parent.WorldKit)
local Landform = require(script.Parent.Landform)

local RiverBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new
local WL = Landscape.River.waterLevel

local function riverTangent(x: number, z: number): (number, number)
	local best, tx, tz = math.huge, 1, 0
	for _, s in ipairs(Landform.riverSamples()) do
		local d = (s.x - x) ^ 2 + (s.z - z) ^ 2
		if d < best then
			best, tx, tz = d, s.tx, s.tz
		end
	end
	return tx, tz
end

-- Puente en arco: tablones siguiendo la curva, vigas, barandal y estribos de piedra
local function bridge(center: Vector3, parent: Instance)
	local m = K.model("Puente", parent)
	local tx, tz = riverTangent(center.X, center.Z)
	local axis = V(-tz, 0, tx) -- cruza el cauce
	if axis.Z < 0 then
		axis = -axis
	end
	local side = V(tx, 0, tz)
	local L, rise, n = World.River.width + 14, 3, 12
	local function at(s: number, lateral: number, lift: number): Vector3
		return center + axis * (s - 0.5) * L + side * lateral + V(0, 0.35 + rise * math.sin(math.pi * s) + lift, 0)
	end
	for i = 0, n - 1 do
		local a, b = at(i / n, 0, 0), at((i + 1) / n, 0, 0)
		local plank = K.box(
			V(8, 0.5, (b - a).Magnitude + 0.06),
			CFrame.lookAt((a + b) / 2, b),
			if i % 2 == 0 then C.barkPale else C.bark,
			M.WoodPlanks,
			m,
			true
		)
		plank.CanQuery = true -- el acompañante pisa el puente (rayos de suelo)
	end
	for _, lat in ipairs({ -3.8, 3.8 }) do
		for k = 0, 2 do
			K.limb(at(k / 3, lat, -0.5), at((k + 1) / 3, lat, -0.5), 0.4, C.barkDark, M.Wood, m)
		end
		local prevTop: Vector3? = nil
		for k = 0, 4 do
			local base = at(k / 4, lat * 1.02, 0)
			local top = base + V(0, 2.8, 0)
			K.limb(base, top, 0.22, C.barkDark, M.Wood, m, true)
			if prevTop then
				K.limb(prevTop, top, 0.16, C.bark, M.Wood, m, true)
			end
			prevTop = top
		end
	end
	for _, s in ipairs({ 0, 1 }) do
		K.box(V(11, 2.2, 3), CFrame.lookAt(at(s, 0, -1.3), at(s, 0, -1.3) + axis), C.stoneMid, M.Slate, m, true)
	end
end

-- Canoa de madera (casco, proa y popa en cuña, banca y remo). Se mece en el cliente.
local function canoe(pos: Vector3, yaw: number, parent: Instance): Model
	local m = K.model("Canoa", parent)
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	K.box(V(1.7, 0.8, 5), cf, C.barkPale, M.Wood, m)
	K.wedge(V(1.7, 0.8, 1.6), cf * CFrame.new(0, 0, -3.3) * CFrame.Angles(0, math.pi, 0), C.barkPale, M.Wood, m)
	K.wedge(V(1.7, 0.8, 1.6), cf * CFrame.new(0, 0, 3.3), C.barkPale, M.Wood, m)
	K.box(V(1.5, 0.2, 0.7), cf * CFrame.new(0, 0.3, 0.8), C.bark, M.Wood, m)
	K.limb(
		(cf * CFrame.new(0.5, 0.4, -1)).Position,
		(cf * CFrame.new(-0.4, 0.5, 2.6)).Position,
		0.1,
		C.barkDark,
		M.Wood,
		m
	)
	m.WorldPivot = cf
	m:SetAttribute("SwayKind", "bob")
	m:AddTag("AmbientSway")
	return m
end

local function chinampas(parent: Instance)
	local L = Landscape.Lagoon
	local folder = K.folder("Chinampas", parent)
	for i, isl in ipairs(L.islands) do
		local cf = CFrame.new(isl.center[1], L.islandTop, isl.center[2]) * CFrame.Angles(0, math.rad(isl.yaw), 0)
		local len = isl.size[1] * 0.82
		for r = -1, 1 do
			local ridge = cf * CFrame.new(0, 0.2, r * 2.6)
			K.box(V(len, 0.35, 1.3), ridge, C.cacaoMid:Lerp(C.clayDark, 0.35), M.Ground, folder).CastShadow = false
			-- Una chinampa de cempasúchil; las demás, hortalizas
			for k = 0, 2 do
				local p = (ridge * CFrame.new((k - 1) * len * 0.32, 0.55, 0)).Position
				if i == 2 then
					K.ball(0.9, p, K.rgb(Ambience.Flowers.colors[1]), M.SmoothPlastic, folder)
				else
					K.ellipsoid(
						V(1.6, 0.9, 1.4),
						CFrame.new(p),
						if k % 2 == 0 then C.leaf else C.leafPale,
						M.LeafyGrass,
						folder
					)
				end
			end
		end
	end
	-- Embarcadero y canoas
	local dock = L.dock
	local base = V(dock[1], 0, dock[2])
	local dir = (V(-114, 0, 50) - base).Unit
	for k = 0, 5 do
		local p = base + dir * (k * 1.7) + V(0, 0.15, 0)
		K.box(
			V(4, 0.4, 1.6),
			CFrame.lookAt(p, p + dir),
			if k % 2 == 0 then C.barkPale else C.bark,
			M.WoodPlanks,
			folder,
			true
		).CanQuery =
			true
	end
	for _, k in ipairs({ 1, 5 }) do
		for _, lat in ipairs({ -1.8, 1.8 }) do
			local p = base + dir * (k * 1.7) + dir:Cross(Vector3.yAxis) * lat
			K.limb(p - V(0, 3, 0), p + V(0, 1.2, 0), 0.22, C.barkDark, M.Wood, folder)
		end
	end
	local across = dir:Cross(Vector3.yAxis)
	canoe(base + dir * 8 + across * 2.6 + V(0, WL + 0.2, 0), math.atan2(-dir.X, -dir.Z), folder)
	canoe(V(-140, WL + 0.2, 58.5), math.rad(84), folder)
	canoe(V(-162, WL + 0.2, 76), math.rad(30), folder)
end

-- Cempasúchil y hojas a la deriva; nenúfares donde el agua está quieta
local function floats(parent: Instance)
	local folder = K.folder("Flotantes", parent)
	local rng = Rng.new(4242)
	local samples = Landform.riverSamples()
	for i = 3, #samples, 5 do
		local s = samples[i]
		local off = rng:range(-World.River.width / 2 + 2.5, World.River.width / 2 - 2.5)
		local p = V(s.x - s.tz * off, WL + 0.12, s.z + s.tx * off)
		if rng:chance(0.6) then
			K.ball(0.75, p, K.rgb(Ambience.Flowers.colors[1]), M.SmoothPlastic, folder).CastShadow = false
		else
			K.ellipsoid(
				V(1.5, 0.12, 0.8),
				CFrame.new(p) * CFrame.Angles(0, rng:range(0, 6.28), 0),
				C.leafPale,
				M.SmoothPlastic,
				folder
			).CastShadow =
				false
		end
	end
	for _, c in ipairs(Landscape.Lagoon.circles) do
		for _ = 1, 4 do
			local a = rng:range(0, math.pi * 2)
			local r = c[3] - rng:range(2, 5)
			local x, z = c[1] + math.cos(a) * r, c[2] + math.sin(a) * r
			if Landform.waterDistance(x, z) < -1.5 then
				local pad = K.disc(
					rng:range(0.9, 1.6),
					0.12,
					V(x, WL + 0.08, z),
					C.jadeDeep:Lerp(C.leaf, 0.4),
					M.SmoothPlastic,
					folder
				)
				pad.CastShadow = false
				if rng:chance(0.35) then
					K.ellipsoid(
						V(0.8, 0.6, 0.8),
						CFrame.new(x + 0.3, WL + 0.45, z),
						C.cream:Lerp(K.rgb(Ambience.Papel[1]), 0.25),
						M.SmoothPlastic,
						folder
					)
				end
			end
		end
	end
end

-- Pie de la cascada: espuma, chorros claros sobre la lámina de agua y bruma
local function waterfall(parent: Instance)
	local W = Landscape.Waterfall
	local folder = K.folder("Cascada", parent)
	local f = W.fall
	local foot = V(f.center[1] - 2.6, WL + 0.1, f.center[3])
	for k = -1, 1 do
		K.limb(
			V(f.center[1] - 2.15, f.center[2] + f.size[2] / 2 - 0.4, f.center[3] + k * 2.6),
			V(f.center[1] - 2.4, WL + 0.4, f.center[3] + k * 2.9),
			0.32,
			C.cream,
			M.Glass,
			folder
		).Transparency =
			0.45
	end
	for _, e in ipairs({ { 0, 0, 7, 5 }, { -3, 2, 5, 4 }, { -2, -3, 4, 3.5 } }) do
		local foam =
			K.ellipsoid(V(e[3], 0.6, e[4]), CFrame.new(foot + V(e[1], 0, e[2])), C.cream, M.SmoothPlastic, folder)
		foam.Transparency = 0.3
		foam.CastShadow = false
	end
	local spray = K.box(V(6, 1, 8), CFrame.new(foot + V(0, 1.5, 0)), C.cream, M.SmoothPlastic, folder)
	spray.Name = "Bruma"
	spray.Transparency = 1
	K.emitter(spray, {
		Name = "WaterfallMist",
		Color = ColorSequence.new(Color3.fromRGB(236, 244, 240)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new(3.5),
		Rate = 12,
		Lifetime = NumberRange.new(2, 3.5),
		Speed = NumberRange.new(1.5, 3),
		SpreadAngle = Vector2.new(70, 70),
		Shape = Enum.ParticleEmitterShape.Box,
	})
end

function RiverBuilder.build(root: Instance)
	local folder = K.folder("Rio", root)
	for _, b in ipairs(World.Bridges) do
		bridge(K.v3(b), folder)
	end
	chinampas(folder)
	floats(folder)
	waterfall(folder)
end

return RiverBuilder
