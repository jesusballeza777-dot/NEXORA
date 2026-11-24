--!strict
-- Relieve de Valle Copal como datos puros (sin APIs de motor; probado en tests/Unit/World).
-- Convierte Config/Landscape y Config/World.River en una lista ordenada de rellenos de
-- Terrain (TerrainBuilder los ejecuta) y responde preguntas de geometría que usan la
-- flora y las pruebas: altura del suelo, distancia al agua y a los caminos.
-- El orden importa (como en Terrain): suelo → colinas → terrazas → acantilado → manchas
-- y caminos al ras → orillas de barro → vaciado (Air) → agua → bancos e islas → cascada.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local Rng = require(Shared.Domain.Rng)

local Landform = {}

export type Op = {
	fn: "FillBlock" | "FillBall" | "FillCylinder" | "FillWedge",
	pos: { number },
	size: { number }?, -- Block/Wedge
	radius: number?, -- Ball/Cylinder
	height: number?, -- Cylinder (vertical)
	yaw: number?, -- grados alrededor de Y
	material: string,
}

export type Sample = { x: number, z: number, tx: number, tz: number }

local RIVER = Landscape.River
local HALF = World.River.width / 2

local function block(x: number, y: number, z: number, sx: number, sy: number, sz: number, mat: string, yaw: number?): Op
	return { fn = "FillBlock", pos = { x, y, z }, size = { sx, sy, sz }, yaw = yaw, material = mat }
end

local function cylinder(x: number, z: number, radius: number, bottom: number, top: number, mat: string): Op
	return {
		fn = "FillCylinder",
		pos = { x, (bottom + top) / 2, z },
		radius = radius,
		height = top - bottom,
		material = mat,
	}
end

local function ball(x: number, y: number, z: number, radius: number, mat: string): Op
	return { fn = "FillBall", pos = { x, y, z }, radius = radius, material = mat }
end

-- Radio de una bola que asoma `h` studs con una huella de radio `f` sobre Y = 0
local function capRadius(f: number, h: number): number
	return (f * f + h * h) / (2 * h)
end

-- ------------------------------------------------------------------
-- Río: Catmull-Rom uniforme por los puntos de Config/World.River
-- ------------------------------------------------------------------
local samplesCache: { Sample }? = nil

function Landform.riverSamples(): { Sample }
	if samplesCache then
		return samplesCache
	end
	local pts = World.River.points
	local out: { Sample } = {}
	local function p(i: number): { number }
		return pts[math.clamp(i, 1, #pts)]
	end
	for i = 1, #pts - 1 do
		local p0, p1, p2, p3 = p(i - 1), p(i), p(i + 1), p(i + 2)
		local len = math.sqrt((p2[1] - p1[1]) ^ 2 + (p2[3] - p1[3]) ^ 2)
		local n = math.max(2, math.ceil(len / RIVER.sampleStep))
		for k = 0, n - 1 do
			local t = k / n
			local t2, t3 = t * t, t * t * t
			local function cr(a: number, b: number, c: number, d: number): number
				return 0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
			end
			local function dcr(a: number, b: number, c: number, d: number): number
				return 0.5 * ((-a + c) + 2 * (2 * a - 5 * b + 4 * c - d) * t + 3 * (-a + 3 * b - 3 * c + d) * t2)
			end
			local x = cr(p0[1], p1[1], p2[1], p3[1])
			local z = cr(p0[3], p1[3], p2[3], p3[3])
			local tx, tz = dcr(p0[1], p1[1], p2[1], p3[1]), dcr(p0[3], p1[3], p2[3], p3[3])
			local m = math.sqrt(tx * tx + tz * tz)
			table.insert(out, { x = x, z = z, tx = tx / m, tz = tz / m })
		end
	end
	local last = pts[#pts]
	local prev = out[#out]
	table.insert(out, { x = last[1], z = last[3], tx = prev.tx, tz = prev.tz })
	samplesCache = out
	return out
end

-- Distancia (en planta) al eje del río
function Landform.riverDistance(x: number, z: number): number
	local best = math.huge
	local s = Landform.riverSamples()
	for i = 1, #s - 1 do
		local a, b = s[i], s[i + 1]
		local abx, abz = b.x - a.x, b.z - a.z
		local len2 = abx * abx + abz * abz
		local t = if len2 > 0 then math.clamp(((x - a.x) * abx + (z - a.z) * abz) / len2, 0, 1) else 0
		local d = math.sqrt((x - a.x - abx * t) ^ 2 + (z - a.z - abz * t) ^ 2)
		if d < best then
			best = d
		end
	end
	return best
end

-- Distancia con signo al borde del agua (negativa dentro del río, el lago o la poza)
function Landform.waterDistance(x: number, z: number): number
	local d = Landform.riverDistance(x, z) - HALF
	for _, c in ipairs(Landscape.Lagoon.circles) do
		d = math.min(d, math.sqrt((x - c[1]) ^ 2 + (z - c[2]) ^ 2) - c[3])
	end
	local pool = Landscape.Waterfall.pool
	d = math.min(d, math.sqrt((x - pool.center[1]) ^ 2 + (z - pool.center[2]) ^ 2) - pool.radius)
	-- Las islas de las chinampas son tierra firme
	for _, isl in ipairs(Landscape.Lagoon.islands) do
		local yaw = math.rad(isl.yaw)
		local dx, dz = x - isl.center[1], z - isl.center[2]
		local lx = dx * math.cos(yaw) - dz * math.sin(yaw)
		local lz = dx * math.sin(yaw) + dz * math.cos(yaw)
		if math.abs(lx) < isl.size[1] / 2 and math.abs(lz) < isl.size[2] / 2 then
			return math.max(d, 1)
		end
	end
	return d
end

local function segDist(px: number, pz: number, a: { number }, b: { number }): number
	local abx, abz = b[1] - a[1], b[2] - a[2]
	local len2 = abx * abx + abz * abz
	local t = if len2 > 0 then math.clamp(((px - a[1]) * abx + (pz - a[2]) * abz) / len2, 0, 1) else 0
	return math.sqrt((px - a[1] - abx * t) ^ 2 + (pz - a[2] - abz * t) ^ 2)
end

-- Distancia al borde del camino de tierra más cercano (negativa sobre el camino)
function Landform.pathDistance(x: number, z: number): number
	local best = math.huge
	for _, path in ipairs(Landscape.Paths) do
		local w = path[1] :: number
		for i = 2, #path - 1 do
			best = math.min(best, segDist(x, z, path[i] :: { number }, path[i + 1] :: { number }) - w / 2)
		end
	end
	return best
end

-- ------------------------------------------------------------------
-- Alturas de los sólidos (colinas, terrazas, acantilado), sin el agua
-- ------------------------------------------------------------------
local function ballTop(x: number, z: number, cx: number, cy: number, cz: number, r: number): number
	local d2 = (x - cx) ^ 2 + (z - cz) ^ 2
	if d2 >= r * r then
		return -math.huge
	end
	return cy + math.sqrt(r * r - d2)
end

local function hillsTop(x: number, z: number): number
	local h = 0
	for _, hill in ipairs(Landscape.Hills) do
		h = math.max(h, ballTop(x, z, hill[1], hill[2], hill[3], hill[4]))
	end
	return h
end

-- Zona jugable (plano a Y = 0): ninguna loma satélite puede invadirla
local function protected(x: number, z: number, r: number): boolean
	if math.sqrt(x * x + z * z) - r < 160 then
		return true
	end
	for _, lot in ipairs(World.Lots.positions) do
		if math.abs(x - lot[1]) < 52 + r and math.abs(z - lot[3]) < 52 + r then
			return true
		end
	end
	local cliff = Landscape.Waterfall.cliff
	return math.abs(x - cliff.center[1]) < 40 + r and math.abs(z - cliff.center[3]) < 50 + r
end

-- Lomas satélite sobre cada colina (semilla fija): rompen la silueta de domo
local lumpsCache: { { number } }? = nil
function Landform.lumps(): { { number } }
	if lumpsCache then
		return lumpsCache
	end
	local rng = Rng.new(Landscape.LumpSeed)
	local out: { { number } } = {}
	for _, hill in ipairs(Landscape.Hills) do
		local r, cy = hill[4], hill[2]
		local foot = math.sqrt(math.max(0, r * r - cy * cy))
		for _ = 1, 4 do
			local a = rng:range(0, math.pi * 2)
			local d = foot * rng:range(0.2, 0.75)
			local x, z = hill[1] + math.cos(a) * d, hill[3] + math.sin(a) * d
			local rs = r * rng:range(0.16, 0.3)
			local s = hillsTop(x, z)
			local rocky = rng:chance(0.22)
			if rocky then
				rs *= 0.45
			end
			if s > 10 and not protected(x, z, rs) then
				table.insert(out, { x, s - rs * rng:range(0.55, 0.8), z, rs, if rocky then 1 else 0 })
			end
		end
	end
	lumpsCache = out
	return out
end

local function solidTop(x: number, z: number): number
	local h = hillsTop(x, z)
	for _, l in ipairs(Landform.lumps()) do
		h = math.max(h, ballTop(x, z, l[1], l[2], l[3], l[4]))
	end
	return h
end

local function terraceRings(): { { cx: number, cz: number, radius: number, top: number } }
	local T = Landscape.Terraces
	local rings = {}
	for k = 0, T.rings - 1 do
		table.insert(rings, {
			cx = T.center[1] + T.jitter * math.cos(k * 2.1),
			cz = T.center[2] + T.jitter * math.sin(k * 1.7),
			radius = T.outerRadius - k * T.step,
			top = T.rise * (k + 1),
		})
	end
	return rings
end
Landform.terraceRings = terraceRings

function Landform.heightAt(x: number, z: number): number
	local h = solidTop(x, z)
	for _, o in ipairs(Landscape.Outcrops) do
		local base = solidTop(o[1], o[2])
		h = math.max(h, ballTop(x, z, o[1], base + o[4] - o[3], o[2], o[3]))
	end
	for _, m in ipairs(Landscape.Mounds) do
		local r = capRadius(m[3], m[4])
		h = math.max(h, ballTop(x, z, m[1], m[4] - r, m[2], r))
	end
	for _, ring in ipairs(terraceRings()) do
		if (x - ring.cx) ^ 2 + (z - ring.cz) ^ 2 < ring.radius ^ 2 then
			h = math.max(h, ring.top)
		end
	end
	local cap = Landscape.Terraces.cap
	h = math.max(h, ballTop(x, z, cap[1], cap[2], cap[3], cap[4]))
	local cliff = Landscape.Waterfall.cliff
	if math.abs(x - cliff.center[1]) < cliff.size[1] / 2 and math.abs(z - cliff.center[3]) < cliff.size[3] / 2 then
		h = math.max(h, cliff.center[2] + cliff.size[2] / 2)
	end
	return h
end

-- ------------------------------------------------------------------
-- Lista de rellenos
-- ------------------------------------------------------------------
function Landform.ops(): { Op }
	local ops: { Op } = {}
	local function add(op: Op)
		table.insert(ops, op)
	end
	local g = Landscape.Ground
	add(block(g.center[1], g.center[2], g.center[3], g.size[1], g.size[2], g.size[3], "Grass"))

	-- Colinas, afloramientos y lomas
	for _, hill in ipairs(Landscape.Hills) do
		add(ball(hill[1], hill[2], hill[3], hill[4], hill[5]))
	end
	for _, l in ipairs(Landform.lumps()) do
		add(ball(l[1], l[2], l[3], l[4], if l[5] == 1 then "Rock" else "Grass"))
	end
	for _, o in ipairs(Landscape.Outcrops) do
		add(ball(o[1], solidTop(o[1], o[2]) + o[4] - o[3], o[2], o[3], o[5]))
	end
	for _, m in ipairs(Landscape.Mounds) do
		local r = capRadius(m[3], m[4])
		add(ball(m[1], m[4] - r, m[2], r, "Grass"))
	end

	-- Terrazas: muro de piedra y tierra de cultivo por anillo (de fuera hacia dentro)
	local T = Landscape.Terraces
	for k, ring in ipairs(terraceRings()) do
		add(cylinder(ring.cx, ring.cz, ring.radius, -8, ring.top, "Slate"))
		add(
			cylinder(
				ring.cx,
				ring.cz,
				ring.radius - T.wall,
				ring.top - 4,
				ring.top,
				if k % 2 == 1 then "Ground" else "LeafyGrass"
			)
		)
	end
	add(ball(T.cap[1], T.cap[2], T.cap[3], T.cap[4], "LeafyGrass"))

	-- Macizo de la cascada (antes de los caminos: es roca, no suelo)
	local W = Landscape.Waterfall
	add(
		block(
			W.cliff.center[1],
			W.cliff.center[2],
			W.cliff.center[3],
			W.cliff.size[1],
			W.cliff.size[2],
			W.cliff.size[3],
			"Rock"
		)
	)
	for _, r in ipairs(W.rocks) do
		add(ball(r[1], r[2], r[3], r[4], "Rock"))
	end

	-- Manchas y caminos al ras (la superficie queda en Y = 0,05)
	for _, p in ipairs(Landscape.Patches) do
		add(cylinder(p[1], p[2], p[3], -3.95, 0.05, p[4]))
	end
	for _, lot in ipairs(World.Lots.positions) do
		add(block(lot[1], -1.95, lot[3], World.Lots.size[1], 4, World.Lots.size[2], "LeafyGrass"))
	end
	for _, path in ipairs(Landscape.Paths) do
		local w = path[1] :: number
		for i = 2, #path - 1 do
			local a, b = path[i] :: { number }, path[i + 1] :: { number }
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local len = math.sqrt(dx * dx + dz * dz)
			add(
				block(
					(a[1] + b[1]) / 2,
					-1.95,
					(a[2] + b[2]) / 2,
					w,
					4,
					len + w * 0.6,
					"Ground",
					math.deg(math.atan2(dx, dz))
				)
			)
		end
	end

	-- Agua: orillas de barro, vaciado y agua (en pasadas, para que no se pisen)
	local samples = Landform.riverSamples()
	local wl, bed = RIVER.waterLevel, RIVER.bed
	local pool = W.pool
	local basins: { { number } } = {}
	for _, s in ipairs(samples) do
		table.insert(basins, { s.x, s.z, HALF })
	end
	for _, c in ipairs(Landscape.Lagoon.circles) do
		table.insert(basins, { c[1], c[2], c[3] })
	end
	table.insert(basins, { pool.center[1], pool.center[2], pool.radius })
	for _, b in ipairs(basins) do
		add(cylinder(b[1], b[2], b[3] + RIVER.bank, bed - 4, 0.2, "Mud"))
	end
	for _, b in ipairs(basins) do
		local top = math.max(8, Landform.heightAt(b[1], b[2]) + 4)
		add(cylinder(b[1], b[2], b[3] + 1, wl, top, "Air"))
	end
	for _, b in ipairs(basins) do
		add(cylinder(b[1], b[2], b[3], bed, wl, "Water"))
	end
	for _, sb in ipairs(RIVER.sandBars) do
		add(ball(sb[1], -0.5 - sb[3], sb[2], sb[3], "Sand"))
	end

	-- Chinampas: islas rectangulares de lodo con tierra de cultivo encima
	local L = Landscape.Lagoon
	for _, isl in ipairs(L.islands) do
		add(block(isl.center[1], -3, isl.center[2], isl.size[1] + 2, 4, isl.size[2] + 2, "Mud", isl.yaw))
		add(block(isl.center[1], L.islandTop - 1.5, isl.center[2], isl.size[1], 3, isl.size[2], "LeafyGrass", isl.yaw))
	end

	-- Cascada: canal sobre el macizo, saliente de roca y lámina de agua hasta la poza
	local ch = W.channel
	local cx, cl = (ch.from[1] + ch.to[1]) / 2, math.abs(ch.from[1] - ch.to[1])
	add(block(cx, (ch.floor + 64) / 2, ch.to[2], cl, 64 - ch.floor, ch.width, "Air"))
	add(block(cx, (ch.floor + ch.water) / 2, ch.to[2], cl, ch.water - ch.floor, ch.width - 1, "Water"))
	add(
		block(
			W.ledge.center[1],
			W.ledge.center[2],
			W.ledge.center[3],
			W.ledge.size[1],
			W.ledge.size[2],
			W.ledge.size[3],
			"Rock"
		)
	)
	add(
		block(
			W.fall.center[1],
			W.fall.center[2],
			W.fall.center[3],
			W.fall.size[1],
			W.fall.size[2],
			W.fall.size[3],
			"Water"
		)
	)
	return ops
end

return Landform
