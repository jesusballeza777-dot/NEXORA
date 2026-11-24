--!strict
-- La Linde de las Chinampas (oeste): donde el valle pierde el color. El sendero de tierra
-- se vuelve gris (manchas de Slate y Basalt en el terreno), los juncos se secan, los
-- árboles quedan opacados y una estela caída cuenta que aquí hubo un camino cuidado.
-- Cada claro de Opaco conserva su marcador (EncounterN, Marker), su niebla y su prompt.
-- El lado +Z de cada claro queda libre: ahí se coloca la cámara del combate.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)

local LindeBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local function deadTree(at: Vector3, yaw: number, s: number, parent: Instance)
	local m = K.model("ArbolOpacado", parent)
	local trunk = K.rgb(Ambience.Flora.species.Opacado.trunk)
	local cf = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
	local top = (cf * CFrame.new(0.4 * s, 7 * s, 0)).Position
	local t = K.limb(at, top, 0.55 * s, trunk, M.Wood, m, true)
	t.Name = "Trunk"
	K.limb(top, (cf * CFrame.new(-2.6 * s, 10 * s, 0.8 * s)).Position, 0.28 * s, trunk, M.Wood, m)
	K.limb(top, (cf * CFrame.new(2.2 * s, 10.6 * s, -1.2 * s)).Position, 0.26 * s, trunk, M.Wood, m)
	K.limb(
		(cf * CFrame.new(0.2, 4 * s, 0)).Position,
		(cf * CFrame.new(2.6 * s, 6 * s, 1.4 * s)).Position,
		0.2 * s,
		trunk,
		M.Wood,
		m
	)
	K.ellipsoid(V(3.2, 1.6, 2.8) * s, cf * CFrame.new(-2.3 * s, 10.2 * s, 0.8 * s), C.opaco, M.Grass, m)
end

function LindeBuilder.build(root: Instance)
	local folder = K.folder("Encounters", root)
	local linde = Ambience.Linde
	local index = 0
	for markerId, enc in pairs(World.Encounters) do
		index += 1
		local pos = K.v3(enc.position)
		-- Claro de piedra gris, apenas sobre el terreno (el marcador que usa el combate)
		local zone = K.disc(enc.radius * 0.55, 0.3, pos + V(0, 0.15, 0), C.opaco:Lerp(C.stoneMid, 0.3), M.Slate, folder)
		zone.Name = markerId
		zone:SetAttribute("Marker", markerId)
		zone.Transparency = 0.15
		-- Rocas de basalto semienterradas en arco (abierto hacia +Z, la cámara del combate)
		for k = 1, 5 do
			local a = math.rad(160 + k * 44)
			local h = 2 + (k % 3)
			K.ellipsoid(
				V(3.4, h, 3),
				CFrame.new(pos + V(math.cos(a) * 10, h * 0.25, math.sin(a) * 10)) * CFrame.Angles(0, a, math.rad(10)),
				K.rgb(linde.boulder),
				M.Basalt,
				folder
			)
		end
		-- Juncos secos en anillo, con un hueco hacia el sendero
		for k = 1, linde.reedClustersPerZone do
			local a = (k + 0.5) / (linde.reedClustersPerZone + 1) * math.pi * 1.5 + math.pi * 0.75
			local c = pos + V(math.cos(a) * enc.radius * 0.85, 0, math.sin(a) * enc.radius * 0.85)
			for j = 0, 2 do
				local h = 3 + ((k + j) % 3) * 0.8
				local base = c + V((j - 1) * 0.7, 0, ((k + j) % 2) * 0.6)
				K.limb(
					base,
					base + V((j - 1) * 0.35, h, 0),
					0.17,
					K.rgb(linde.reedColors[((k + j) % #linde.reedColors) + 1]),
					M.Grass,
					folder
				).CastShadow =
					false
			end
		end
		deadTree(pos + V(-enc.radius - 4, 0, -6 - index * 2), index * 1.7, 1 + index * 0.08, folder)
		K.emitter(zone, {
			Name = "OpacoMist",
			Color = ColorSequence.new(C.fog),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Size = NumberSequence.new(6),
			Rate = 4,
			Lifetime = NumberRange.new(5, 7),
			Speed = NumberRange.new(0.5, 1),
			SpreadAngle = Vector2.new(180, 20),
		})
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EncounterPrompt"
		prompt.ActionText = "Restaurar"
		prompt.ObjectText = "Opaco"
		prompt.MaxActivationDistance = enc.radius
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = zone
	end
	-- Estela caída junto al sendero: aquí hubo un camino cuidado antes del Opaco
	local e2 = K.v3(World.Encounters.Encounter2.position)
	local fallen = CFrame.new(e2 + V(16, 0.7, 14)) * CFrame.Angles(0, 0.6, math.rad(84))
	K.box(V(2.6, 7, 1), fallen, C.opaco:Lerp(C.stoneDark, 0.3), M.Slate, folder, true)
	K.box(
		V(3.6, 0.8, 2.6),
		CFrame.new(e2 + V(19, 0.4, 16.5)) * CFrame.Angles(0, 0.6, 0),
		C.opaco,
		M.Slate,
		folder,
		true
	)
	-- Papel picado descolorido, roto, en un poste torcido a la entrada de la Linde
	local post = V(-56, 0, 22)
	K.limb(post, post + V(0.6, 9, 0.2), 0.3, C.opaco:Lerp(C.bark, 0.4), M.Wood, folder, true)
	for i = 0, 2 do
		local flag = K.box(
			V(1.4, 1.6, 0.08),
			CFrame.new(post + V(1.2 + i * 1.5, 7.6 - i * 0.5, 0.3)) * CFrame.Angles(0, 0, 0.2 * i),
			C.opaco:Lerp(K.rgb(Ambience.Papel[i + 1]), 0.18),
			M.SmoothPlastic,
			folder
		)
		flag.Transparency = 0.15
	end
end

return LindeBuilder
