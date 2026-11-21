--!strict
-- Reparto de matas de flores de Valle Copal (lógica pura, probada en tests/Unit/World).
-- Semilla fija (Config/Ambience): el mismo valle en todos los servidores. Ninguna mata
-- cae en la plaza, caminos, huevos, estaciones, lotes, río, puentes, Linde ni portales,
-- para no tapar interacciones ni confundir la lectura del espacio.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Ambience = require(Shared.Config.Ambience)
local Rng = require(Shared.Domain.Rng)

local FloraLayout = {}

export type Cluster = { x: number, z: number, petals: { { dx: number, dz: number, color: number } } }

local function dist2(ax: number, az: number, b: { number }): number
	local dx, dz = ax - b[1], az - b[3]
	return math.sqrt(dx * dx + dz * dz)
end

local function distToSegment(px: number, pz: number, a: { number }, b: { number }): number
	local abx, abz = b[1] - a[1], b[3] - a[3]
	local len2 = abx * abx + abz * abz
	local t = if len2 > 0 then math.clamp(((px - a[1]) * abx + (pz - a[3]) * abz) / len2, 0, 1) else 0
	local cx, cz = a[1] + abx * t, a[3] + abz * t
	return math.sqrt((px - cx) ^ 2 + (pz - cz) ^ 2)
end

-- Camino de la plaza al árbol y sendero hacia la Linde (mismo trazado que ValleBuilder)
local PATHS = {
	{ { 0, 0, 0 }, { 0, 0, -36 }, 10 },
	{ { -20, 0, 12 }, { -70, 0, -3 }, 7 },
	{ { -70, 0, -3 }, { -120, 0, -48 }, 7 },
}

function FloraLayout.isClear(x: number, z: number): boolean
	if dist2(x, z, World.Plaza.center) < World.Plaza.radius + 6 then
		return false
	end
	if dist2(x, z, World.GranNexo.position) < World.GranNexo.trunkRadius + 12 then
		return false
	end
	if dist2(x, z, World.SpawnPoint) < 14 then
		return false
	end
	for _, p in pairs(World.StarterEggPedestals) do
		if dist2(x, z, p) < 10 then
			return false
		end
	end
	for _, st in pairs(World.Stations) do
		if dist2(x, z, st.position) < st.radius then
			return false
		end
	end
	for _, g in ipairs(World.BiomeGates) do
		if dist2(x, z, g.position) < 12 then
			return false
		end
	end
	for _, e in pairs(World.Encounters) do
		if dist2(x, z, e.position) < e.radius + 6 then
			return false
		end
	end
	local half = World.Lots.size[1] / 2 + 4
	for _, lot in ipairs(World.Lots.positions) do
		if math.abs(x - lot[1]) < half and math.abs(z - lot[3]) < half then
			return false
		end
	end
	local pts = World.River.points
	for i = 1, #pts - 1 do
		if distToSegment(x, z, pts[i], pts[i + 1]) < World.River.width / 2 + 7 then
			return false
		end
	end
	for _, b in ipairs(World.Bridges) do
		if dist2(x, z, b) < 14 then
			return false
		end
	end
	for _, path in ipairs(PATHS) do
		if distToSegment(x, z, path[1] :: { number }, path[2] :: { number }) < path[3] :: number then
			return false
		end
	end
	return true
end

function FloraLayout.clusters(): { Cluster }
	local cfg = Ambience.Flowers
	local rng = Rng.new(cfg.seed)
	local out: { Cluster } = {}
	local attempts = 0
	while #out < cfg.clusters and attempts < cfg.clusters * 40 do
		attempts += 1
		local ang = rng:next() * math.pi * 2
		local r = cfg.minRadius + rng:next() * (cfg.maxRadius - cfg.minRadius)
		local x, z = math.cos(ang) * r, math.sin(ang) * r - 10
		if FloraLayout.isClear(x, z) then
			local petals = {}
			local color = rng:int(1, #cfg.colors)
			for k = 1, cfg.petalsPerCluster do
				local a = k / cfg.petalsPerCluster * math.pi * 2 + rng:next()
				table.insert(petals, {
					dx = math.cos(a) * cfg.petalSize * 0.9,
					dz = math.sin(a) * cfg.petalSize * 0.9,
					-- Mayoría de un color con algún acento
					color = if rng:chance(0.25) then rng:int(1, #cfg.colors) else color,
				})
			end
			table.insert(out, { x = x, z = z, petals = petals })
		end
	end
	return out
end

export type Prop = {
	kind: "Tree" | "Rock" | "Bush",
	x: number,
	z: number,
	height: number,
	spread: number,
	yaw: number,
	tilt: number,
	jitter: { number },
}

-- Árboles, rocas y arbustos del perímetro (mismas probabilidades que la vista previa).
function FloraLayout.scatter(): { Prop }
	local cfg = Ambience.Scatter
	local rng = Rng.new(cfg.seed)
	local out: { Prop } = {}
	for _ = 1, cfg.attempts do
		local ang = rng:next() * math.pi * 2
		local r = rng:range(cfg.minRadius, cfg.maxRadius)
		local x, z = math.cos(ang) * r, math.sin(ang) * r
		local roll = rng:next()
		local kind: "Tree" | "Rock" | "Bush" = if roll < cfg.treeChance
			then "Tree"
			elseif roll < cfg.treeChance + cfg.rockChance then "Rock"
			else "Bush"
		local prop: Prop = {
			kind = kind,
			x = x,
			z = z,
			height = rng:range(7, 13),
			spread = rng:range(3.5, 6),
			yaw = rng:range(0, math.pi * 2),
			tilt = rng:range(-0.08, 0.08),
			jitter = { rng:range(-0.5, 0.5), rng:range(-0.5, 0.5), rng:range(-0.5, 0.5) },
		}
		if FloraLayout.isClear(x, z) then
			table.insert(out, prop)
		end
	end
	return out
end

return FloraLayout
