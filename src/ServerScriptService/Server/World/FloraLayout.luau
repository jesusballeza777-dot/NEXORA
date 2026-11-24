--!strict
-- Reparto de la flora de Valle Copal (lógica pura, probada en tests/Unit/World).
-- Semilla fija (Config/Ambience): el mismo valle en todos los servidores. Nada cae en la
-- plaza, caminos, huevos, estaciones, lotes, agua, puentes, mercado, Linde ni portales,
-- para no tapar interacciones ni confundir la lectura del espacio. La especie depende de
-- la zona (orilla, pradera, ladera, Linde) y los árboles se agrupan en bosquecillos con
-- claros entre ellos: «no satures el escenario».

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Ambience = require(Shared.Config.Ambience)
local Landscape = require(Shared.Config.Landscape)
local Rng = require(Shared.Domain.Rng)
local Landform = require(script.Parent.Landform)

local FloraLayout = {}

export type Cluster = { x: number, z: number, petals: { { dx: number, dz: number, color: number } } }

export type Kind = "Ahuejote" | "Copal" | "Sabino" | "Colorin" | "Opacado" | "Bush" | "Bougainvillea" | "Agave" | "Rock"

export type Prop = {
	kind: Kind,
	x: number,
	y: number,
	z: number,
	scale: number,
	yaw: number,
	tilt: number,
	tint: number, -- índice de color del follaje (variación determinista)
	variant: number,
}

local TREE: { [string]: boolean } = { Ahuejote = true, Copal = true, Sabino = true, Colorin = true, Opacado = true }
FloraLayout.isTree = function(kind: string): boolean
	return TREE[kind] == true
end

local function dist(ax: number, az: number, b: { number }): number
	return math.sqrt((ax - b[1]) ^ 2 + (az - b[3]) ^ 2)
end

local TREE_POS = World.GranNexo.position

-- Zonas de juego y de arquitectura que la flora respeta (margen en studs)
function FloraLayout.isClear(x: number, z: number, margin: number?): boolean
	local m = margin or 0
	if dist(x, z, World.Plaza.center) < World.Plaza.radius + 6 + m then
		return false
	end
	-- Torre del Nexo: el árbol, la calzada del Gabinete y las estaciones
	if dist(x, z, TREE_POS) < 52 + m then
		return false
	end
	if dist(x, z, World.SpawnPoint) < 14 + m then
		return false
	end
	for _, st in pairs(World.Stations) do
		if dist(x, z, st.position) < st.radius + 6 + m then
			return false
		end
	end
	-- Explanada de las Puertas de los biomas
	if math.abs(x) < 64 + m and z < -78 + m and z > -124 - m then
		return false
	end
	for _, e in pairs(World.Encounters) do
		if dist(x, z, e.position) < e.radius + 8 + m then
			return false
		end
	end
	local half = World.Lots.size[1] / 2 + 4 + m
	for _, lot in ipairs(World.Lots.positions) do
		if math.abs(x - lot[1]) < half and math.abs(z - lot[3]) < half then
			return false
		end
	end
	-- Barrio de los Oficios (mercado y taller)
	if x > 46 - m and x < 152 + m and z > -6 - m and z < 40 + m then
		return false
	end
	for _, b in ipairs(World.Bridges) do
		if dist(x, z, b) < 18 + m then
			return false
		end
	end
	local dock = Landscape.Lagoon.dock
	if math.sqrt((x - dock[1]) ^ 2 + (z - dock[2]) ^ 2) < 10 + m then
		return false
	end
	-- Macizo y poza de la cascada
	local cliff = Landscape.Waterfall.cliff
	if x > cliff.center[1] - cliff.size[1] / 2 - 6 and math.abs(z - cliff.center[3]) < cliff.size[3] / 2 + 6 then
		return false
	end
	if Landform.waterDistance(x, z) < 5 + m then
		return false
	end
	if Landform.pathDistance(x, z) < 3 + m then
		return false
	end
	return true
end

local function onTerraces(x: number, z: number): boolean
	local T = Landscape.Terraces
	return math.sqrt((x - T.center[1]) ^ 2 + (z - T.center[2]) ^ 2) < T.outerRadius + 4
end

local function inLinde(x: number, z: number): boolean
	return x < -64 and z < 32 and z > -110
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
		if FloraLayout.isClear(x, z) and not inLinde(x, z) and Landform.heightAt(x, z) < 0.5 then
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

-- Elige especie según la zona. Devuelve nil para dejar un claro.
local function pick(rng: Rng.Rng, x: number, z: number, h: number): Kind?
	local roll = rng:next()
	if inLinde(x, z) then
		return if roll < 0.45 then "Opacado" elseif roll < 0.7 then "Rock" elseif roll < 0.85 then "Bush" else nil
	end
	if Landform.waterDistance(x, z) < 16 then
		return if roll < 0.55 then "Ahuejote" elseif roll < 0.8 then "Bush" else nil
	end
	if h > 5 then -- laderas del cuenco
		return if roll < 0.3
			then "Sabino"
			elseif roll < 0.6 then "Copal"
			elseif roll < 0.75 then "Agave"
			elseif roll < 0.88 then "Bush"
			else "Rock"
	end
	return if roll < 0.3
		then "Copal"
		elseif roll < 0.42 then "Colorin"
		elseif roll < 0.52 then "Sabino"
		elseif roll < 0.72 then "Bush"
		elseif roll < 0.8 then "Bougainvillea"
		elseif roll < 0.86 then "Agave"
		else nil
end

local SPACING: { [string]: number } = {
	Sabino = 16,
	Copal = 10,
	Colorin = 10,
	Ahuejote = 7,
	Opacado = 9,
	Bush = 5,
	Bougainvillea = 5,
	Agave = 5,
	Rock = 5,
}

local propsCache: { Prop }? = nil

-- Árboles, arbustos, magueyes y rocas: protagonistas + orillas + bosquecillos con semilla
function FloraLayout.props(): { Prop }
	if propsCache then
		return propsCache
	end
	local cfg = Ambience.Flora
	local rng = Rng.new(cfg.seed)
	local out: { Prop } = {}
	local function free(x: number, z: number, kind: string): boolean
		for _, p in ipairs(out) do
			local need = math.max(SPACING[kind], SPACING[p.kind]) * 0.8
			if (p.x - x) ^ 2 + (p.z - z) ^ 2 < need * need then
				return false
			end
		end
		return true
	end
	local function add(kind: Kind, x: number, z: number, scale: number?)
		table.insert(out, {
			kind = kind,
			x = x,
			y = Landform.heightAt(x, z),
			z = z,
			scale = scale or rng:range(0.82, 1.22),
			yaw = rng:range(0, math.pi * 2),
			tilt = rng:range(-0.06, 0.06),
			tint = rng:int(1, 3),
			variant = rng:int(1, 2),
		})
	end
	for _, hero in ipairs(Landscape.HeroTrees) do
		add(hero.species :: Kind, hero.x, hero.z, hero.scale)
	end
	-- Ahuejotes en fila a lo largo de las orillas (lado alterno), como en las chinampas
	local samples = Landform.riverSamples()
	for i = 6, #samples - 2, 6 do
		local s = samples[i]
		local side = if (i // 6) % 2 == 0 then 1 else -1
		local off = World.River.width / 2 + 6 + rng:range(0, 3)
		local x, z = s.x - s.tz * off * side, s.z + s.tx * off * side
		if FloraLayout.isClear(x, z, -3) and free(x, z, "Ahuejote") then
			add("Ahuejote", x, z)
		end
	end
	-- Ahuejotes en los bordes largos de cada chinampa
	for _, isl in ipairs(Landscape.Lagoon.islands) do
		local yaw = math.rad(isl.yaw)
		for _, f in ipairs({ -0.38, 0.05, 0.4 }) do
			local lx, lz = f * isl.size[1], (if f > 0 then 1 else -1) * (isl.size[2] / 2 - 1)
			local x = isl.center[1] + lx * math.cos(yaw) + lz * math.sin(yaw)
			local z = isl.center[2] - lx * math.sin(yaw) + lz * math.cos(yaw)
			table.insert(out, {
				kind = "Ahuejote",
				x = x,
				y = Landscape.Lagoon.islandTop,
				z = z,
				scale = rng:range(0.9, 1.15),
				yaw = rng:range(0, math.pi * 2),
				tilt = rng:range(-0.04, 0.04),
				tint = rng:int(1, 3),
				variant = rng:int(1, 2),
			})
		end
	end
	-- Bosquecillos: centros con semilla; cerca de un centro hay árboles, lejos, claros
	local groves = {}
	for _ = 1, 20 do
		local a, r = rng:range(0, math.pi * 2), rng:range(70, 250)
		table.insert(groves, { math.cos(a) * r, math.sin(a) * r - 10, rng:range(22, 44) })
	end
	for _ = 1, cfg.attempts do
		local a = rng:range(0, math.pi * 2)
		local r = rng:range(cfg.minRadius, cfg.maxRadius)
		local x, z = math.cos(a) * r, math.sin(a) * r - 10
		local near = 0
		for _, g in ipairs(groves) do
			local d = math.sqrt((x - g[1]) ^ 2 + (z - g[2]) ^ 2) / g[3]
			near = math.max(near, 1 - d)
		end
		local h = Landform.heightAt(x, z)
		if rng:next() < 0.06 + near * 0.9 and h < 50 and FloraLayout.isClear(x, z) and not onTerraces(x, z) then
			local kind = pick(rng, x, z, h)
			if kind and free(x, z, kind) then
				add(kind, x, z)
			end
		end
	end
	propsCache = out
	return out
end

export type Crop = { kind: "Maize" | "Agave", x: number, y: number, z: number, yaw: number, scale: number }

-- Milpa en las terrazas (solo en el arco que mira al valle) y magueyes en los bordes
function FloraLayout.crops(): { Crop }
	local T = Landscape.Terraces
	local rng = Rng.new(Ambience.Flora.seed + 7)
	local out: { Crop } = {}
	for k, ring in ipairs(Landform.terraceRings()) do
		if k < T.rings then
			local mid = ring.radius - T.wall - (T.step - T.wall) / 2
			local n = 7 - k
			for i = 0, n - 1 do
				local deg = T.visibleArc[1] + (T.visibleArc[2] - T.visibleArc[1]) * (i + rng:range(0.2, 0.8)) / n
				local a = math.rad(deg)
				local edge = i % 3 == 2
				local rr = if edge then ring.radius - T.wall - 0.8 else mid + rng:range(-1, 1)
				table.insert(out, {
					kind = if edge then "Agave" else "Maize",
					x = ring.cx + math.cos(a) * rr,
					y = ring.top,
					z = ring.cz + math.sin(a) * rr,
					yaw = rng:range(0, math.pi * 2),
					scale = rng:range(0.85, 1.15),
				})
			end
		end
	end
	return out
end

export type Reed = { x: number, y: number, z: number, yaw: number, scale: number }

-- Juncos y tules en las orillas del río y del lago (sin tapar puentes ni embarcadero)
function FloraLayout.reeds(): { Reed }
	local rng = Rng.new(Ambience.Flora.seed + 13)
	local out: { Reed } = {}
	local samples = Landform.riverSamples()
	for i = 2, #samples, 3 do
		local s = samples[i]
		if rng:chance(0.55) then
			local side = if rng:chance(0.5) then 1 else -1
			local off = World.River.width / 2 + rng:range(-0.5, 1.5)
			local x, z = s.x - s.tz * off * side, s.z + s.tx * off * side
			local nearBridge = false
			for _, b in ipairs(World.Bridges) do
				if math.sqrt((x - b[1]) ^ 2 + (z - b[3]) ^ 2) < 16 then
					nearBridge = true
				end
			end
			if not nearBridge and Landform.pathDistance(x, z) > 2 then
				table.insert(
					out,
					{ x = x, y = -0.6, z = z, yaw = rng:range(0, math.pi * 2), scale = rng:range(0.8, 1.2) }
				)
			end
		end
	end
	for _, c in ipairs(Landscape.Lagoon.circles) do
		for _ = 1, 3 do
			local a = rng:range(0, math.pi * 2)
			local x, z = c[1] + math.cos(a) * (c[3] - 0.5), c[2] + math.sin(a) * (c[3] - 0.5)
			local dock = Landscape.Lagoon.dock
			if Landform.waterDistance(x, z) > -2 and math.sqrt((x - dock[1]) ^ 2 + (z - dock[2]) ^ 2) > 8 then
				table.insert(
					out,
					{ x = x, y = -0.6, z = z, yaw = rng:range(0, math.pi * 2), scale = rng:range(0.8, 1.2) }
				)
			end
		end
	end
	return out
end

return FloraLayout
