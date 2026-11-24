--!strict
-- Lotes Hogar (Biblia p. 8: hábitat de 4 lugares, comedero, decoración y recolector).
-- La base es terreno (LeafyGrass, ver Landform); aquí va lo construido:
--   · cerca baja de madera con portón al norte (da al camino de los lotes);
--   · caminos de piedra del portón al hábitat, a la vitrina, al recolector y a la incubadora;
--   · hábitat con 4 pedestales de piedra y copal (la cima queda a 1,9 studs: ahí se paran
--     los monstruos) y un comedero tallado en el centro;
--   · recolector de Monedas: un cántaro de barro con monedas derramadas;
--   · vitrina de 3 Tallados con respaldo tallado y tejadito;
--   · faroles en el portón y macetas en las esquinas.
-- Nombres y posiciones que usan el servidor y el cliente: Lot<i> (LotIndex), Ground,
-- Habitat/Slot<n> (+ SlotPrompt), Collector (+ CollectPrompt), IncubatorRing, Incubator,
-- Sign (+ OwnerLabel). Las piezas decorativas no colisionan con el acompañante.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)

local LotsBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local function stone(at: Vector3, r: number, parent: Instance)
	local s = K.disc(r, 0.3, at + V(0, 0.12, 0), C.stone:Lerp(C.stoneMid, (r * 7) % 1), M.Slate, parent, true)
	s.CanQuery = true
end

local function fence(center: Vector3, half: number, parent: Instance)
	local f = K.model("Cerca", parent)
	local function post(x: number, z: number)
		K.limb(center + V(x, 0, z), center + V(x, 2.6, z), 0.22, C.bark, M.Wood, f, true)
	end
	local function rail(ax: number, az: number, bx: number, bz: number)
		for _, y in ipairs({ 1.2, 2.2 }) do
			K.limb(center + V(ax, y, az), center + V(bx, y, bz), 0.12, C.barkPale, M.Wood, f, true)
		end
	end
	for _, x in ipairs({ -half, -half / 3, half / 3, half }) do
		post(x, half)
		post(x, -half)
	end
	for _, z in ipairs({ -half / 3, half / 3 }) do
		post(-half, z)
		post(half, z)
	end
	post(-4, -half)
	post(4, -half)
	rail(-half, half, half, half)
	rail(-half, -half, -half, half)
	rail(half, -half, half, half)
	rail(-half, -half, -4, -half) -- portón abierto entre x = −4 y 4
	rail(4, -half, half, -half)
end

local function collector(at: Vector3, parent: Instance)
	K.disc(2.1, 0.6, at + V(0, 0.3, 0), C.barkPale, M.WoodPlanks, parent, true)
	local body = K.part({
		Size = V(3.6, 4.4, 3.6),
		CFrame = CFrame.new(at + V(0, 2.8, 0)),
		Color = C.clay,
		Material = M.Slate,
	}, parent)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	body.Name = "Collector"
	K.disc(0.95, 1.2, at + V(0, 5.4, 0), C.clay, M.Slate, parent)
	K.disc(1.25, 0.3, at + V(0, 6.05, 0), C.clayDark, M.Slate, parent)
	-- Monedas: unas asoman por la boca y otras se derraman al pie
	K.disc(0.85, 0.2, at + V(0, 6.2, 0), C.brass, M.Metal, parent)
	for i = 0, 4 do
		local a = i * 1.3
		local coin = K.disc(
			0.45,
			0.12,
			at + V(math.cos(a) * (2.2 + i * 0.2), 0.08 + (i % 2) * 0.12, math.sin(a) * 2.2),
			C.brass,
			M.Metal,
			parent
		)
		coin.CFrame *= CFrame.Angles(0.3 * (i % 3), 0, 0)
	end
	-- Franja de greca pintada en la panza del cántaro
	K.disc(1.86, 0.35, at + V(0, 3.2, 0), C.clayPale, M.Slate, parent)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectPrompt"
	prompt.ActionText = "Recoger Monedas"
	prompt.ObjectText = "Recolector"
	prompt.MaxActivationDistance = 10
	prompt.Enabled = false
	prompt.Parent = body
end

local function vitrina(at: Vector3, parent: Instance)
	local m = K.model("Vitrina", parent)
	K.box(V(13, 3.4, 0.6), CFrame.new(at + V(0, 1.7, 2.4)), C.barkPale, M.WoodPlanks, m, true)
	K.box(V(13.4, 0.5, 0.9), CFrame.new(at + V(0, 3.6, 2.4)), C.bark, M.Wood, m)
	K.gable(14, 2.2, 0.9, CFrame.new(at + V(0, 3.85, 2.3)), C.clay, m)
	for k = -1, 1 do
		K.disc(1.6, 2.2, at + V(k * 4, 1.1, 0), C.stone, M.Slate, m, true)
		K.disc(1.75, 0.3, at + V(k * 4, 2.05, 0), C.copal, M.Slate, m)
	end
end

local function pot(at: Vector3, parent: Instance, seed: number)
	K.disc(1.1, 1.3, at + V(0, 0.65, 0), C.clay, M.Slate, parent)
	K.ellipsoid(V(2.4, 1.8, 2.4), CFrame.new(at + V(0, 1.9, 0)), C.leafDeep, M.LeafyGrass, parent)
	K.ball(0.8, at + V(0.5, 2.6, 0.2), K.rgb(Ambience.Flowers.colors[(seed % 2) + 1]), M.SmoothPlastic, parent)
	K.ball(0.7, at + V(-0.5, 2.5, -0.3), K.rgb(Ambience.Flowers.colors[1]), M.SmoothPlastic, parent)
end

function LotsBuilder.build(root: Instance): { Model }
	local folder = K.folder("Lots", root)
	local cfg = World.Lots
	local half = cfg.size[1] / 2
	local lots = {}
	for i, pos in ipairs(cfg.positions) do
		local center = K.v3(pos)
		local lot = K.model("Lot" .. i, folder)
		lot:SetAttribute("LotIndex", i)
		local ground = K.box(V(cfg.size[1], 0.2, cfg.size[2]), CFrame.new(center + V(0, 0.1, 0)), C.leaf, M.Grass, lot)
		ground.Name = "Ground"
		ground.Transparency = 1
		lot.PrimaryPart = ground
		fence(center, half, lot)
		-- Caminos de piedra
		for _, st in ipairs({
			{ 0, -20, 1.5 },
			{ 0.7, -17.2, 1.3 },
			{ -0.4, -14.6, 1.4 },
			{ 0.3, 10.6, 1.3 },
			{ 11, 12.4, 1.2 },
			{ 13.4, 14.6, 1.1 },
			{ -11, 12.4, 1.2 },
			{ -13.4, 14.6, 1.1 },
		}) do
			stone(center + V(st[1], 0, st[2]), st[3], lot)
		end
		-- Hábitat: borde de piedra, musgo y cuatro pedestales de piedra y copal
		local habitat = K.model("Habitat", lot)
		local hc = center + K.v3(cfg.habitatOffset)
		K.disc(15.6, 0.16, hc + V(0, 0.08, 0), C.stoneMid, M.Slate, habitat)
		K.disc(15, 0.2, hc + V(0, 0.1, 0), C.leaf:Lerp(C.leafPale, 0.35), M.Grass, habitat)
		for s, off in ipairs(cfg.slotOffsets) do
			local p = center + K.v3(off)
			K.disc(3.4, 1.2, p + V(0, 0.6, 0), C.stone, M.Slate, habitat, true)
			K.disc(3.55, 0.3, p + V(0, 1.15, 0), C.stoneDark, M.Slate, habitat)
			local ped = K.disc(2.7, 0.6, p + V(0, 1.6, 0), C.copal, M.SmoothPlastic, habitat, true)
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
		-- Comedero tallado con raciones
		local feed = hc + V(0, 0, 1)
		K.box(V(3.6, 0.9, 1.7), CFrame.new(feed + V(0, 0.75, 0)), C.bark, M.Wood, habitat, true)
		K.box(V(3.1, 0.2, 1.2), CFrame.new(feed + V(0, 1.25, 0)), C.copalPale, M.SmoothPlastic, habitat)
		for _, x in ipairs({ -1.3, 1.3 }) do
			K.box(V(0.5, 0.4, 1.9), CFrame.new(feed + V(x, 0.2, 0)), C.barkDark, M.Wood, habitat)
		end
		collector(center + K.v3(cfg.collectorOffset), lot)
		-- Incubadora (el cliente añade huevo, anillos y haz cuando hay un huevo)
		local inc = center + K.v3(cfg.incubatorOffset)
		K.disc(3, 1.4, inc + V(0, 0.7, 0), C.stone, M.Slate, lot, true)
		K.disc(2.4, 0.3, inc + V(0, 1.55, 0), C.copal, M.SmoothPlastic, lot)
		local ring = K.disc(3.6, 0.3, inc + V(0, 4, 0), C.copalGlow, M.Neon, lot)
		ring.Name = "IncubatorRing"
		ring.CastShadow = false
		local incubator = K.box(V(1, 1, 1), CFrame.new(inc + V(0, 4.5, 0)), C.copal, M.SmoothPlastic, lot)
		incubator.Name = "Incubator"
		incubator.Transparency = 1
		K.label(incubator, "Incubadora", "Próximamente")
		vitrina(center + K.v3(cfg.vitrinaOffset), lot)
		-- Letrero del dueño (fuera de la cerca, junto al portón)
		local signAt = center + V(0, 0, -half - 1)
		for _, x in ipairs({ -4.6, 4.6 }) do
			K.limb(signAt + V(x, 0, 0), signAt + V(x, 5.4, 0), 0.25, C.barkDark, M.Wood, lot, true)
		end
		local sign = K.box(V(10, 3, 0.6), CFrame.new(signAt + V(0, 4, 0)), C.barkPale, M.WoodPlanks, lot, true)
		sign.Name = "Sign"
		local ownerLabel = K.label(sign, "Lote libre", nil)
		ownerLabel.Name = "OwnerLabel"
		-- Faroles del portón y macetas en las esquinas del sur
		for _, x in ipairs({ -5.2, 5.2 }) do
			local base = center + V(x, 0, -half + 1.2)
			local out = V(if x > 0 then 1.1 else -1.1, 0, 0)
			K.limb(base, base + V(0, 5.4, 0), 0.22, C.barkDark, M.Wood, lot, true)
			K.limb(base + V(0, 5.2, 0), base + out + V(0, 5.2, 0), 0.1, C.barkDark, M.Wood, lot)
			K.lantern(base + out + V(0, 5.1, 0), 0.2, lot, false)
		end
		pot(center + V(-half + 2.6, 0, half - 2.6), lot, i)
		pot(center + V(half - 2.6, 0, half - 2.6), lot, i + 1)
		table.insert(lots, lot)
	end
	return lots
end

return LotsBuilder
