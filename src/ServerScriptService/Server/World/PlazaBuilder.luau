--!strict
-- Plaza del Nexo: piedra clara con anillo de greca y escalonados de copal, medallón en
-- espiral, bancas, faroles de copal, una estela de greca (primer plano oscuro que
-- encuadra la llegada), macetas de cempasúchil y papel picado alto que no tapa la cámara.
-- También los tres huevos iniciales y el SpawnLocation (mirando al Gran Nexo).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)

local PlazaBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local function flat2(t: { number }, y: number): Vector3
	return V(t[1], y, t[2])
end

local function estela(at: Vector3, face: Vector3, parent: Instance)
	local m = K.model("Estela", parent)
	local cf = CFrame.lookAt(at, V(face.X, at.Y, face.Z))
	K.box(V(5, 0.6, 3.4), cf * CFrame.new(0, 0.3, 0), C.stoneMid, M.Slate, m, true)
	K.box(V(4, 0.6, 2.6), cf * CFrame.new(0, 0.9, 0), C.stone, M.Slate, m, true)
	K.box(V(2.8, 7.4, 1), cf * CFrame.new(0, 4.9, 0), C.stoneDark, M.Slate, m, true)
	K.box(V(3.3, 0.6, 1.4), cf * CFrame.new(0, 8.9, 0), C.stoneMid, M.Slate, m, true)
	-- Greca en espiral escalonada, tallada tono sobre tono en la cara
	local steps = {
		{ -0.8, 7.4 },
		{ -0.4, 6.8 },
		{ 0, 6.2 },
		{ 0.4, 5.6 },
		{ 0.8, 5 },
		{ 0.4, 4.4 },
		{ 0, 3.8 },
		{ -0.4, 3.2 },
		{ -0.8, 2.6 },
	}
	for _, s in ipairs(steps) do
		K.box(V(0.7, 0.45, 0.25), cf * CFrame.new(s[1], s[2], -0.6), C.stoneMid, M.Slate, m)
	end
	K.disc(0.9, 0.5, (cf * CFrame.new(0, 1.45, -1.6)).Position, C.clay, M.Slate, m)
	K.ball(0.6, (cf * CFrame.new(0, 1.8, -1.6)).Position, C.copalPale, M.SmoothPlastic, m)
end

local function bench(at: Vector3, face: Vector3, parent: Instance)
	local cf = CFrame.lookAt(at, V(face.X, at.Y, face.Z))
	K.box(V(5.4, 0.6, 1.7), cf * CFrame.new(0, 1.6, 0), C.stone, M.Slate, parent, true)
	for _, x in ipairs({ -1.9, 1.9 }) do
		K.box(V(0.9, 1.3, 1.4), cf * CFrame.new(x, 0.65, 0), C.stoneMid, M.Slate, parent, true)
	end
end

local function lanternPost(at: Vector3, face: Vector3, parent: Instance)
	local m = K.model("PosteFarol", parent)
	K.limb(at, at + V(0, 9, 0), 0.35, C.barkDark, M.Wood, m, true)
	K.disc(0.9, 0.5, at + V(0, 0.25, 0), C.stoneMid, M.Slate, m)
	local dir = (V(face.X, 0, face.Z) - V(at.X, 0, at.Z)).Unit
	local tip = at + V(0, 8.8, 0) + dir * 1.9
	K.limb(at + V(0, 8.8, 0), tip, 0.15, C.barkDark, M.Wood, m)
	K.lantern(tip, 0.5, m, true)
end

local function pot(at: Vector3, parent: Instance, seed: number)
	K.disc(1, 1.2, at + V(0, 0.6, 0), C.clay, M.Slate, parent)
	K.ellipsoid(V(1.9, 1, 1.9), CFrame.new(at + V(0, 1.4, 0)), C.leafDeep, M.LeafyGrass, parent)
	for i = 0, 2 do
		local a = i * 2.1 + seed
		K.ball(
			0.75,
			at + V(math.cos(a) * 0.5, 1.95, math.sin(a) * 0.5),
			K.rgb(Ambience.Flowers.colors[1]),
			M.SmoothPlastic,
			parent
		)
	end
end

local function eggs(root: Instance)
	local folder = K.folder("StarterEggs", root)
	for eggId, pos in pairs(World.StarterEggPedestals) do
		local p = K.v3(pos)
		K.disc(3.4, 1.6, p + V(0, 0.8, 0), C.stone, M.Slate, folder, true)
		local glass = K.disc(2.6, 1.8, p + V(0, 1.0, 0), C.copal, M.Glass, folder, true)
		glass.Transparency = 0.15
		local egg = K.part({
			Size = V(3.2, 4.2, 3.2),
			CFrame = CFrame.new(p + V(0, 4.2, 0)),
			Color = C.copal,
			Material = M.SmoothPlastic,
		}, folder)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = egg
		egg.Name = eggId
		egg:SetAttribute("EggId", eggId)
		-- Espiral tallada: idéntica en los tres huevos (la elección es por intuición)
		for i = 0, 5 do
			local a = math.rad(i * 60)
			K.ball(
				0.5,
				p + V(math.cos(a) * 1.55, 2.9 + i * 0.42, math.sin(a) * 1.55),
				C.clayDark:Lerp(C.copal, 0.4),
				M.SmoothPlastic,
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

function PlazaBuilder.build(root: Instance)
	local plaza = K.folder("Plaza", root)
	local P = Landscape.Plaza
	local center = K.v3(World.Plaza.center)
	local R = World.Plaza.radius
	local tree = K.v3(World.GranNexo.position)
	K.disc(R, 0.4, center + V(0, 0.2, 0), C.stone, M.Slate, plaza, true).CanQuery = true
	K.disc(R - 1.6, 0.44, center + V(0, 0.22, 0), C.stoneDark, M.Slate, plaza, true)
	K.disc(R - 3.2, 0.46, center + V(0, 0.23, 0), C.stone, M.Slate, plaza, true).CanQuery = true
	-- Escalonados de copal sobre el anillo de greca
	for i = 0, 19 do
		local a = (i + 0.5) / 20 * math.pi * 2
		local p = center + V(math.cos(a) * (R - 2.4), 0.48, math.sin(a) * (R - 2.4))
		K.box(
			V(1.4, 0.06, if i % 2 == 0 then 1.2 else 0.7),
			CFrame.lookAt(p, V(center.X, 0.48, center.Z)),
			C.copal,
			M.Slate,
			plaza
		)
	end
	-- Medallón central en espiral
	K.disc(4.2, 0.5, center + V(0, 0.25, 0), C.stoneMid, M.Slate, plaza)
	for i = 0, 6 do
		local a = i * 0.95
		local r = 0.6 + i * 0.48
		K.disc(0.55 - i * 0.03, 0.54, center + V(math.cos(a) * r, 0.27, math.sin(a) * r), C.copal, M.Slate, plaza)
	end
	estela(flat2(P.estela, 0), K.v3(World.SpawnPoint), plaza)
	for _, b in ipairs(P.benches) do
		bench(flat2(b, 0), center, plaza)
	end
	for _, l in ipairs(P.lanterns) do
		lanternPost(flat2(l, 0.4), center, plaza)
	end
	for i, s in ipairs(P.papelStrings) do
		local a, b = flat2(s[1], 0), flat2(s[2], 0)
		for _, p in ipairs({ a, b }) do
			K.limb(p, p + V(0, P.papelHeight + 1, 0), 0.38, C.barkDark, M.Wood, plaza, true)
		end
		K.papelPicado(a + V(0, P.papelHeight, 0), b + V(0, P.papelHeight, 0), 2.2, plaza, i)
	end
	for i, p in ipairs({ { -24, 18 }, { 24, 18 }, { -9, 37 }, { 9, 37 } }) do
		pot(flat2(p, 0.4), plaza, i)
	end
	eggs(root)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = V(10, 1, 10)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CFrame = CFrame.lookAt(K.v3(World.SpawnPoint), tree)
	spawn.Duration = 0
	spawn.Parent = plaza
end

return PlazaBuilder
