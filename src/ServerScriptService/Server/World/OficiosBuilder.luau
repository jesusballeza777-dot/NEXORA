--!strict
-- Barrio de los Oficios (este de la plaza): la calle del mercado y el taller.
-- Cinco puestos distintos, cada uno con su toldo de tela inclinado y su mercancía:
--   Cántaros (alfarería) · Frutas (canastas) · Comal (cocina, con brasa) ·
--   Canastas y textiles · Flores y velas de copal.
-- Al fondo de la calle, el Taller del Barro y el Telar: casa de adobe con vigas, horno de
-- barro con humo y un telar de pedal bajo un cobertizo. La calle remata en el taller
-- (punto de fuga) y desemboca en el puente del este hacia los lotes.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Landscape = require(Shared.Config.Landscape)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)

local OficiosBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new
local P = Ambience.Papel

local function frame(pos: { number }, face: { number }): CFrame
	local at = V(pos[1], 0, pos[3])
	return CFrame.lookAt(at, V(face[1], 0, face[2]))
end

local function jar(cf: CFrame, s: number, color: Color3, parent: Instance)
	K.ellipsoid(V(1.6, 1.9, 1.6) * s, cf * CFrame.new(0, 0.95 * s, 0), color, M.Slate, parent)
	K.disc(0.45 * s, 0.6 * s, (cf * CFrame.new(0, 2 * s, 0)).Position, color:Lerp(C.clayDark, 0.25), M.Slate, parent)
end

local AWNING = {
	Cantaros = C.clayPale,
	Frutas = C.jade:Lerp(C.cream, 0.25),
	Comal = C.copal:Lerp(C.cream, 0.2),
	Canastas = K.rgb(P[4]):Lerp(C.stoneMid, 0.35),
	Flores = K.rgb(P[1]):Lerp(C.cream, 0.3),
}

-- Estructura común: postes, mostrador, toldo inclinado hacia la calle y faldón
local function stall(kind: string, cf: CFrame, parent: Instance): Model
	local m = K.model("Puesto" .. kind, parent)
	local cloth = AWNING[kind]
	for _, p in ipairs({ { -4, -2.6, 6.6 }, { 4, -2.6, 6.6 }, { -4, 2.6, 8.4 }, { 4, 2.6, 8.4 } }) do
		K.limb(
			(cf * CFrame.new(p[1], 0, p[2])).Position,
			(cf * CFrame.new(p[1], p[3], p[2])).Position,
			0.25,
			C.bark,
			M.Wood,
			m,
			true
		)
	end
	local slope = math.atan2(1.8, 5.2)
	K.box(V(9.6, 0.2, 6.4), cf * CFrame.new(0, 7.6, 0) * CFrame.Angles(-slope, 0, 0), cloth, M.Fabric, m)
	for i = -2, 2 do
		K.box(
			V(1.7, 0.9, 0.08),
			cf * CFrame.new(i * 1.9, 6.1, -3.2),
			if i % 2 == 0 then cloth else C.cream,
			M.Fabric,
			m
		)
	end
	K.box(V(8, 2.4, 1.2), cf * CFrame.new(0, 1.2, -2), C.barkPale, M.WoodPlanks, m, true)
	K.box(V(8.4, 0.25, 1.6), cf * CFrame.new(0, 2.5, -2), C.bark, M.Wood, m)
	return m
end

local Goods = {}

function Goods.Cantaros(m: Model, cf: CFrame)
	K.box(V(7.6, 0.4, 1.4), cf * CFrame.new(0, 3.6, 1.8), C.barkPale, M.WoodPlanks, m)
	for i = -2, 2 do
		jar(cf * CFrame.new(i * 1.5, 2.62, -2), 0.55 + (i % 2) * 0.15, if i % 2 == 0 then C.clay else C.clayPale, m)
		jar(cf * CFrame.new(i * 1.5 + 0.4, 3.8, 1.8), 0.7, if i % 2 == 0 then C.clayDark else C.clay, m)
	end
	jar(cf * CFrame.new(-5.6, 0, -2.6), 1.15, C.clay, m)
	jar(cf * CFrame.new(5.4, 0, -2.2), 0.9, C.clayDark, m)
end

function Goods.Frutas(m: Model, cf: CFrame)
	local fruit = { V(0.89, 0.6, 0.28), V(0.77, 0.27, 0.47), V(0.55, 0.7, 0.32) }
	for i = 0, 3 do
		local b = cf * CFrame.new(-2.9 + i * 1.95, 2.85, -2)
		K.disc(0.85, 0.6, b.Position, C.barkPale:Lerp(C.copalPale, 0.4), M.Fabric, m)
		local c = fruit[(i % 3) + 1]
		for k = 0, 2 do
			K.ball(
				0.62,
				(b * CFrame.new((k - 1) * 0.45, 0.45, (k % 2) * 0.3)).Position,
				Color3.new(c.X, c.Y, c.Z),
				M.SmoothPlastic,
				m
			)
		end
	end
	for i = -1, 1 do
		K.disc(1.3, 1, (cf * CFrame.new(i * 2.8, 0.5, 2.2)).Position, C.barkPale:Lerp(C.copalPale, 0.4), M.Fabric, m)
	end
end

function Goods.Comal(m: Model, cf: CFrame)
	K.box(V(3.4, 1.2, 2.2), cf * CFrame.new(-1.6, 3.1, 1.6), C.stoneMid, M.Slate, m)
	K.disc(1.5, 0.2, (cf * CFrame.new(-1.6, 3.8, 1.6)).Position, C.cacao, M.Metal, m)
	local ember = K.box(V(1.8, 0.3, 0.4), cf * CFrame.new(-1.6, 2.7, 0.45), K.rgb({ 236, 120, 60 }), M.Neon, m)
	ember.CastShadow = false
	K.light(ember, K.rgb({ 255, 150, 80 }), 8, 1.2)
	for k = 0, 3 do
		K.disc(0.7, 0.12, (cf * CFrame.new(1.4, 2.7 + k * 0.13, -2)).Position, C.cream, M.SmoothPlastic, m)
	end
	jar(cf * CFrame.new(2.8, 2.62, -2), 0.6, C.cacaoMid, m)
	jar(cf * CFrame.new(2.6, 0, 2.4), 0.9, C.clay, m)
end

function Goods.Canastas(m: Model, cf: CFrame)
	K.limb((cf * CFrame.new(-4, 6, 2.6)).Position, (cf * CFrame.new(4, 6, 2.6)).Position, 0.15, C.bark, M.Wood, m)
	for i = -1, 1 do
		local p = cf * CFrame.new(i * 2.6, 5, 2.6)
		K.ellipsoid(V(1.8, 1.1, 1.8), p, C.barkPale:Lerp(C.copalPale, 0.45), M.Fabric, m)
	end
	for k = 0, 3 do -- rebozos doblados
		K.box(
			V(2.4, 0.35, 1.2),
			cf * CFrame.new(-1.8, 2.8 + k * 0.36, -2),
			K.rgb(P[(k % #P) + 1]):Lerp(C.cream, 0.3),
			M.Fabric,
			m
		)
	end
	K.box(V(2.6, 0.5, 1.2), cf * CFrame.new(1.8, 2.85, -2), C.jade:Lerp(C.cream, 0.4), M.Fabric, m)
end

function Goods.Flores(m: Model, cf: CFrame)
	for i = -1, 1 do
		local b = cf * CFrame.new(i * 2.4, 0, -3.6)
		K.disc(0.9, 1.4, (b * CFrame.new(0, 0.7, 0)).Position, C.stoneMid, M.Metal, m)
		for k = 0, 3 do
			local a = k * 1.6 + i
			K.ball(
				0.7,
				(b * CFrame.new(math.cos(a) * 0.5, 1.9 + (k % 2) * 0.3, math.sin(a) * 0.5)).Position,
				K.rgb(Ambience.Flowers.colors[if k == 3 then 2 else 1]),
				M.SmoothPlastic,
				m
			)
		end
	end
	for i = 0, 4 do -- velas de copal
		local p = cf * CFrame.new(-3 + i * 1.4, 2.6, -1.8)
		K.disc(
			0.22,
			1 + (i % 3) * 0.35,
			(p * CFrame.new(0, 0.5 + (i % 3) * 0.17, 0)).Position,
			C.copalPale,
			M.SmoothPlastic,
			m
		)
	end
end

local function workshop(parent: Instance)
	local W = Landscape.Workshop
	local cf = frame(W.position, W.face)
	local m = K.model("Taller", parent)
	-- Casa de adobe con vigas salientes y puerta en arco rebajado
	K.box(V(14, 8, 10), cf * CFrame.new(0, 4, 2), C.adobe, M.Plaster, m, true)
	K.box(V(14.6, 0.8, 10.6), cf * CFrame.new(0, 8.4, 2), C.clayPale, M.Plaster, m, true)
	for i = -2, 2 do
		K.limb(
			(cf * CFrame.new(i * 3, 7.4, -3.4)).Position,
			(cf * CFrame.new(i * 3, 7.4, 7.6)).Position,
			0.3,
			C.barkDark,
			M.Wood,
			m
		)
	end
	K.box(V(3.4, 5.2, 0.4), cf * CFrame.new(-2.5, 2.6, -3.05), C.cacaoMid, M.Wood, m)
	K.box(V(4.4, 0.8, 0.6), cf * CFrame.new(-2.5, 5.5, -3.1), C.clayPale, M.Plaster, m)
	K.box(V(2.2, 1.8, 0.3), cf * CFrame.new(3.6, 4.4, -3.05), C.cacaoMid, M.Wood, m)
	K.box(V(2.8, 0.4, 0.6), cf * CFrame.new(3.6, 3.4, -3.15), C.barkPale, M.Wood, m)
	-- Horno de barro con boca, chimenea y humo
	local oven = cf * CFrame.new(5.5, 0, -8)
	K.ellipsoid(V(6.4, 5.6, 6.4), oven * CFrame.new(0, 1.6, 0), C.clay, M.Slate, m)
	K.box(V(2, 1.8, 1), oven * CFrame.new(0, 1.4, -2.9), C.cacao, M.Slate, m)
	local ember = K.box(V(1.5, 0.3, 0.5), oven * CFrame.new(0, 0.7, -2.7), K.rgb({ 236, 120, 60 }), M.Neon, m)
	ember.CastShadow = false
	K.light(ember, K.rgb({ 255, 140, 70 }), 9, 1.4)
	K.disc(0.6, 1.8, (oven * CFrame.new(1.2, 4.6, 0.8)).Position, C.clayDark, M.Slate, m)
	local smoke = K.box(V(1, 1, 1), oven * CFrame.new(1.2, 5.8, 0.8), C.cream, M.SmoothPlastic, m)
	smoke.Transparency = 1
	K.emitter(smoke, {
		Name = "OvenSmoke",
		Color = ColorSequence.new(Color3.fromRGB(214, 206, 196)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) }),
		Rate = 4,
		Lifetime = NumberRange.new(4, 6),
		Speed = NumberRange.new(1.5, 2.5),
		SpreadAngle = Vector2.new(12, 12),
	})
	-- Cobertizo con telar de pedal
	local shed = cf * CFrame.new(-9.5, 0, -4)
	for _, p in ipairs({ { -2.6, -2.4, 5.4 }, { 2.6, -2.4, 5.4 }, { -2.6, 2.4, 6.4 }, { 2.6, 2.4, 6.4 } }) do
		K.limb(
			(shed * CFrame.new(p[1], 0, p[2])).Position,
			(shed * CFrame.new(p[1], p[3], p[2])).Position,
			0.22,
			C.bark,
			M.Wood,
			m,
			true
		)
	end
	K.box(
		V(6.4, 0.25, 6),
		shed * CFrame.new(0, 6.1, 0) * CFrame.Angles(-math.atan2(1, 4.8), 0, 0),
		C.barkPale,
		M.WoodPlanks,
		m
	)
	local loom = shed * CFrame.new(0, 0, 0)
	for _, x in ipairs({ -1.8, 1.8 }) do
		K.limb(
			(loom * CFrame.new(x, 0, 0)).Position,
			(loom * CFrame.new(x, 4, 0)).Position,
			0.18,
			C.barkDark,
			M.Wood,
			m
		)
	end
	K.limb(
		(loom * CFrame.new(-1.9, 3.8, 0)).Position,
		(loom * CFrame.new(1.9, 3.8, 0)).Position,
		0.16,
		C.barkDark,
		M.Wood,
		m
	)
	K.limb(
		(loom * CFrame.new(-1.9, 1, 0)).Position,
		(loom * CFrame.new(1.9, 1, 0)).Position,
		0.16,
		C.barkDark,
		M.Wood,
		m
	)
	for i = 0, 5 do
		K.limb(
			(loom * CFrame.new(-1.4 + i * 0.56, 1, 0)).Position,
			(loom * CFrame.new(-1.4 + i * 0.56, 3.8, 0)).Position,
			0.04,
			C.cream,
			M.Fabric,
			m
		)
	end
	K.box(V(3.2, 1.3, 0.1), loom * CFrame.new(0, 1.8, -0.05), K.rgb(P[1]):Lerp(C.cream, 0.2), M.Fabric, m)
	-- Cántaros secándose y leña
	K.box(V(5, 0.3, 1.2), cf * CFrame.new(-1, 1.2, -4.4), C.barkPale, M.WoodPlanks, m)
	for i = 0, 2 do
		jar(cf * CFrame.new(-2.6 + i * 1.6, 1.35, -4.4), 0.55, C.clayPale, m)
	end
	for i = 0, 3 do
		local y = 0.35 + (i // 2) * 0.6
		K.limb(
			(oven * CFrame.new(-4.2, y, -1 + (i % 2) * 0.6)).Position,
			(oven * CFrame.new(-4.2, y, 2.4 + (i % 2) * 0.6)).Position,
			0.3,
			C.barkPale,
			M.Wood,
			m
		)
	end
end

function OficiosBuilder.build(root: Instance)
	local folder = K.folder("Oficios", root)
	for _, s in ipairs(Landscape.Market.stalls) do
		local cf = frame(s.position, s.face)
		local m = stall(s.kind, cf, folder);
		(Goods :: any)[s.kind](m, cf)
	end
	for i, line in ipairs(Landscape.Market.papel) do
		local a, b = V(line[1][1], 0, line[1][2]), V(line[2][1], 0, line[2][2])
		for _, p in ipairs({ a, b }) do
			K.limb(p, p + V(0, 12, 0), 0.28, C.barkDark, M.Wood, folder, true)
		end
		K.papelPicado(a + V(0, 11.4, 0), b + V(0, 11.4, 0), 1.4, folder, i + 2)
		if i == 1 then
			K.lantern(a:Lerp(b, 0.5) + V(0, 10.2, 0), 1.4, folder, true)
		end
	end
	workshop(folder)
end

return OficiosBuilder
