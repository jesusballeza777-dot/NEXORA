--!strict
-- Torre del Nexo: la arquitectura alrededor de la base del Gran Nexo (Biblia p. 11).
--   · Basamento de losas en dos anillos; donde pasa una raíz, la losa se levanta.
--   · Calzada circular del Gabinete que Camina (libre de obstáculos).
--   · Las siete estaciones, cada una con identidad y un remate que se lee a 80 studs:
--       Criadero        · vivero con cúpulas de copal translúcido e incubadoras (cúpula + linterna)
--       Tablón          · tablero tallado con greca, papeles, cuerdas y tejadito (mástil con papel picado)
--       Portal de Arenas· arco de piedra con anillo vertical, sellado hasta la Fase 4 (cresta escalonada)
--       Círculo         · anfiteatro de bancas en círculo (mástil con banderolas)
--       Repisa de Cofres· nicho de piedra con estantes y cofres (espadaña con campana)
--       Mirador         · terraza elevada con catalejos hacia las puertas (pérgola y mástil)
--       Despensa        · el puesto del Gabinete que Camina (toldo y farol)
--   · Las cuatro Puertas de los biomas, selladas, al pie de la loma norte.
-- El prompt de cada estación («Station») está sobre su posición de Config/World, que es
-- la que valida el servidor; la arquitectura se construye detrás, hacia fuera.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local Elements = require(Shared.Config.Elements)
local SpeciesConfig = require(Shared.Config.Species)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)
local GranNexoBuilder = require(script.Parent.GranNexoBuilder)

local TorreBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local TREE = K.v3(World.GranNexo.position)

local function flatLook(from: Vector3, to: Vector3): CFrame
	return CFrame.lookAt(V(from.X, 0, from.Z), V(to.X, 0, to.Z))
end

-- Pieza sólida (arquitectura que se pisa o se rodea)
local function solid(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, parent: Instance): BasePart
	return K.box(size, cf, color, material, parent, true)
end

-- Greca escalonada: bloques que suben y bajan a lo largo de una banda (relieve tono sobre tono)
local function greca(cf: CFrame, width: number, count: number, color: Color3, parent: Instance)
	local step = width / count
	for i = 0, count - 1 do
		local h = if i % 2 == 0 then 0.5 else 0.9
		K.box(V(step * 0.8, h, 0.3), cf * CFrame.new(-width / 2 + step * (i + 0.5), h / 2, 0), color, M.Slate, parent)
	end
end

local function prompt(booth: BasePart, id: string, st: any)
	booth.Name = "Booth"
	booth:SetAttribute("StationId", id)
	booth:SetAttribute("Implemented", st.implemented)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Station"
	p.ActionText = if st.implemented then "Abrir" else "Mirar"
	p.ObjectText = st.label
	p.MaxActivationDistance = st.radius
	p.RequiresLineOfSight = false
	p.Parent = booth
	K.label(
		booth,
		st.label,
		if st.implemented then nil else "Próximamente",
		if st.implemented then nil else Color3.fromRGB(210, 200, 190),
		7
	)
end

-- ---------------------------------------------------------------------------
-- Basamento y calzada
-- ---------------------------------------------------------------------------
local function basamento(parent: Instance)
	local folder = K.folder("Basamento", parent)
	local roots = GranNexoBuilder.RootAngles
	for ring, radii in ipairs(Landscape.Torre.slabRings) do
		local r0, r1 = radii[1], radii[2]
		local n = if ring == 1 then 12 else 16
		for i = 0, n - 1 do
			local deg = (i + 0.5) / n * 360 + ring * 7
			local a = math.rad(deg)
			local mid = (r0 + r1) / 2
			local chord = 2 * mid * math.sin(math.pi / n) - 0.35
			local pos = TREE + V(math.cos(a) * mid, 0.25, math.sin(a) * mid)
			local cf = CFrame.lookAt(pos, V(TREE.X, 0.25, TREE.Z)) -- −Z hacia el árbol
			local lifted = false
			for _, rd in ipairs(roots) do
				local diff = math.abs(((deg - rd + 180) % 360) - 180)
				if diff < 360 / n * 0.55 then
					lifted = true
				end
			end
			if lifted then
				-- La raíz empuja la losa: se levanta del lado del tronco y se inclina
				cf = cf * CFrame.new(0, 0.9 + ring * 0.3, 0) * CFrame.Angles(math.rad(-14 - ring * 4), 0, math.rad(6))
			end
			local slab = solid(
				V(chord, 0.5, r1 - r0 - 0.35),
				cf,
				if (i + ring) % 3 == 0 then C.stoneMid else C.stone,
				M.Slate,
				folder
			)
			slab.CanQuery = true
		end
	end
	-- Calzada del Gabinete (se omite donde ya hay plaza)
	local wk = Landscape.Torre.walkway
	local n = 30
	local plaza = K.v3(World.Plaza.center)
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local mid = (wk.inner + wk.outer) / 2
		local pos = TREE + V(math.cos(a) * mid, 0.18, math.sin(a) * mid)
		if (V(pos.X, 0, pos.Z) - V(plaza.X, 0, plaza.Z)).Magnitude > World.Plaza.radius - 2 then
			local chord = 2 * mid * math.sin(math.pi / n) - 0.3
			local cf = CFrame.lookAt(pos, V(TREE.X, 0.18, TREE.Z))
			solid(
				V(chord, 0.36, wk.outer - wk.inner - 0.3),
				cf,
				if i % 2 == 0 then C.stone else C.stone:Lerp(C.stoneMid, 0.35),
				M.Slate,
				folder
			).CanQuery =
				true
			K.box(
				V(chord + 0.3, 0.44, 0.7),
				cf * CFrame.new(0, 0, -(wk.outer - wk.inner) / 2 + 0.35),
				C.stoneDark,
				M.Slate,
				folder
			)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Estaciones (coordenadas locales: −Z mira hacia `face`; el prompt queda al frente)
-- ---------------------------------------------------------------------------
local Station = {}

function Station.Criadero(m: Model, cf: CFrame, front: number)
	solid(V(13.5, 0.4, 13.5), cf * CFrame.new(0, 0.2, 0), C.stone, M.Slate, m)
	for i = 1, 5 do -- muro bajo de adobe, abierto al frente
		local a = math.rad(i * 60 + 90)
		local p = CFrame.new(math.sin(a) * 6.2, 1.5, -math.cos(a) * 6.2)
		solid(V(6.4, 2.6, 0.9), cf * p * CFrame.Angles(0, -a, 0), C.adobe, M.Plaster, m)
	end
	local drum = cf * CFrame.new(0, 1.6, 1)
	K.disc(5.2, 2.4, (drum * CFrame.new(0, 0.4, 0)).Position, C.adobe, M.Plaster, m, true)
	K.disc(5.35, 0.4, (drum * CFrame.new(0, 1.7, 0)).Position, C.brass, M.Metal, m)
	local dome = K.ellipsoid(V(10, 13, 10), drum * CFrame.new(0, 1.8, 0), C.copal, M.Glass, m)
	dome.Transparency = 0.35
	dome.CastShadow = false
	-- Linterna de remate
	local top = drum * CFrame.new(0, 8.3, 0)
	K.disc(1.2, 0.8, top.Position, C.brass, M.Metal, m)
	local cup = K.ellipsoid(V(2, 2.6, 2), top * CFrame.new(0, 1.6, 0), C.copal, M.Glass, m)
	cup.Transparency = 0.2
	K.limb((top * CFrame.new(0, 2.8, 0)).Position, (top * CFrame.new(0, 6, 0)).Position, 0.18, C.brass, M.Metal, m)
	K.ball(1, (top * CFrame.new(0, 1.6, 0)).Position, C.copalGlow, M.Neon, m)
	-- Cúpulas laterales
	for _, x in ipairs({ -6.6, 6.6 }) do
		local p = cf * CFrame.new(x, 0, 3)
		K.disc(2.4, 1.6, (p * CFrame.new(0, 0.8, 0)).Position, C.adobe, M.Plaster, m, true)
		local d = K.ellipsoid(V(4.4, 5, 4.4), p * CFrame.new(0, 1.6, 0), C.copal, M.Glass, m)
		d.Transparency = 0.35
	end
	-- Incubadoras bajo la cúpula (se ven a través del copal)
	for _, o in ipairs({ { -2.1, 0 }, { 2.1, 0 }, { 0, 2.4 } }) do
		local p = drum * CFrame.new(o[1], 0, o[2])
		K.disc(0.9, 1.2, (p * CFrame.new(0, 1.4, 0)).Position, C.stoneMid, M.Slate, m)
		K.ellipsoid(V(1.3, 1.7, 1.3), p * CFrame.new(0, 2.8, 0), C.copalPale, M.SmoothPlastic, m)
	end
	K.light(K.ball(0.8, (drum * CFrame.new(0, 3.2, 0)).Position, C.copalGlow, M.Neon, m), C.copalGlow, 12, 1.1)
	local counter = solid(V(5, 2.6, 1.2), cf * CFrame.new(0, 1.3, front + 0.6), C.bark, M.Wood, m)
	K.box(V(5.4, 0.3, 1.5), cf * CFrame.new(0, 2.7, front + 0.6), C.barkPale, M.WoodPlanks, m)
	return counter
end

function Station.Tablon(m: Model, cf: CFrame, _front: number)
	for _, x in ipairs({ -6.6, 6.6 }) do
		K.limb((cf * CFrame.new(x, 0, 0)).Position, (cf * CFrame.new(x, 11, 0)).Position, 0.6, C.bark, M.Wood, m, true)
	end
	local board = solid(V(12, 7, 0.8), cf * CFrame.new(0, 6.6, 0), C.barkPale, M.WoodPlanks, m)
	for _, b in ipairs({
		{ 0, 10.3, 12.8, 0.7 },
		{ 0, 2.9, 12.8, 0.7 },
		{ -6.2, 6.6, 0.7, 7.8 },
		{ 6.2, 6.6, 0.7, 7.8 },
	}) do
		K.box(V(b[3], b[4], 1.1), cf * CFrame.new(b[1], b[2], 0), C.barkDark, M.Wood, m)
	end
	greca(cf * CFrame.new(0, 10.6, -0.4), 11, 9, C.barkDark, m)
	-- Papeles clavados (encargos) y cuerdas cruzadas
	local papers =
		{ { -3.6, 7.6, 8 }, { -1, 5.4, -6 }, { 1.8, 7.9, 4 }, { 4.2, 5.2, -3 }, { -4.2, 4.6, 3 }, { 0.6, 8.6, -2 } }
	for i, p in ipairs(papers) do
		local color = if i == 3 then K.rgb(Ambience.Papel[2]) else C.cream
		K.box(
			V(1.8, 2.2, 0.08),
			cf * CFrame.new(p[1], p[2], -0.46) * CFrame.Angles(0, 0, math.rad(p[3])),
			color,
			M.SmoothPlastic,
			m
		)
	end
	K.limb(
		(cf * CFrame.new(-5.6, 9.2, -0.55)).Position,
		(cf * CFrame.new(5.6, 4.4, -0.55)).Position,
		0.06,
		C.cacao,
		M.Fabric,
		m
	)
	K.limb(
		(cf * CFrame.new(-5.6, 4.6, -0.55)).Position,
		(cf * CFrame.new(5.6, 9, -0.55)).Position,
		0.06,
		C.cacao,
		M.Fabric,
		m
	)
	K.gable(14, 3.4, 1.6, cf * CFrame.new(0, 11, 0), C.clay, m)
	-- Remate: mástil con papel picado hacia el tablero
	local mast = cf * CFrame.new(9.5, 0, 1.5)
	K.limb(mast.Position, (mast * CFrame.new(0, 17, 0)).Position, 0.3, C.barkDark, M.Wood, m, true)
	K.wedge(
		V(0.2, 1.6, 2.6),
		mast * CFrame.new(0, 16, -1.4) * CFrame.Angles(0, 0, 0),
		K.rgb(Ambience.Papel[1]),
		M.Fabric,
		m
	)
	K.papelPicado((mast * CFrame.new(0, 15.5, 0)).Position, (cf * CFrame.new(-6.6, 11.6, 0)).Position, 1.5, m, 2)
	return board
end

function Station.PortalArenas(m: Model, cf: CFrame, front: number)
	solid(V(22, 0.6, 9), cf * CFrame.new(0, 0.3, 0), C.stoneMid, M.Slate, m)
	for _, x in ipairs({ -8.4, 8.4 }) do
		local p = cf * CFrame.new(x, 0, 0)
		solid(V(4.6, 2, 4.6), p * CFrame.new(0, 1.6, 0), C.stoneMid, M.Slate, m)
		solid(V(3.6, 13, 3.6), p * CFrame.new(0, 9.1, 0), C.stone, M.Slate, m)
		solid(V(4.6, 1.4, 4.6), p * CFrame.new(0, 16.3, 0), C.stoneMid, M.Slate, m)
	end
	solid(V(21.4, 3, 4.4), cf * CFrame.new(0, 18.5, 0), C.stone, M.Slate, m)
	greca(cf * CFrame.new(0, 17.6, -2.35), 18, 11, C.stoneDark, m)
	solid(V(12, 1.6, 3.4), cf * CFrame.new(0, 20.8, 0), C.stoneMid, M.Slate, m)
	solid(V(7, 1.6, 3), cf * CFrame.new(0, 22.4, 0), C.stone, M.Slate, m)
	solid(V(3, 1.8, 2.6), cf * CFrame.new(0, 24.1, 0), C.stoneMid, M.Slate, m)
	K.disc(1.6, 0.8, (cf * CFrame.new(0, 25.4, 0)).Position, C.clayDark, M.Slate, m)
	-- Anillo vertical de cobre (16 dovelas) y sello de piedra
	local center = cf * CFrame.new(0, 9.6, 0)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		K.box(
			V(2.5, 1.2, 1.5),
			center * CFrame.Angles(0, 0, a) * CFrame.new(0, 6.2, 0),
			C.brass:Lerp(C.jade, 0.25),
			M.Metal,
			m
		)
	end
	local seal = K.part({
		Shape = Enum.PartType.Cylinder,
		Size = V(0.6, 11.2, 11.2),
		CFrame = center * CFrame.Angles(0, math.rad(90), 0),
		Color = C.stoneDark,
		Material = M.Slate,
	}, m)
	seal.Name = "Sello"
	for _, s in ipairs({ 1, -1 }) do
		K.box(
			V(13, 0.8, 0.5),
			center * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, 0, math.rad(35 * s)),
			C.barkDark,
			M.Wood,
			m
		)
	end
	K.box(V(1.4, 1.8, 0.6), center * CFrame.new(0, 0, -0.9), C.copal, M.Glass, m)
	return solid(V(2.4, 2.4, 1.6), cf * CFrame.new(0, 1.2, front), C.stoneMid, M.Slate, m)
end

function Station.Circulo(m: Model, cf: CFrame, _front: number)
	local stage = K.disc(4.6, 0.5, (cf * CFrame.new(0, 0.25, 0)).Position, C.stone, M.Slate, m, true)
	K.disc(5.1, 0.4, (cf * CFrame.new(0, 0.2, 0)).Position, C.stoneDark, M.Slate, m)
	K.disc(1.6, 0.56, (cf * CFrame.new(0, 0.28, 0)).Position, C.copal, M.Slate, m)
	for tier = 1, 2 do
		local r = 6.8 + tier * 2.6
		local y = 0.5 + (tier - 1) * 1.2
		for i = -4, 4 do
			local a = math.rad(i * 30 + 180) -- abierto hacia −Z (la plaza)
			local p = cf * CFrame.new(math.sin(a) * r, y, -math.cos(a) * r)
			local seat = (cf - cf.Position) * CFrame.Angles(0, -a, 0)
			solid(V(r * 0.5, 1, 2), CFrame.new(p.Position) * seat, if tier == 1 then C.stone else C.adobe, M.Slate, m)
			if tier == 2 then
				solid(
					V(r * 0.5, 1.2, 2.2),
					CFrame.new((p * CFrame.new(0, -0.6, 0)).Position) * seat,
					C.stoneMid,
					M.Slate,
					m
				)
			end
		end
	end
	local mast = cf * CFrame.new(0, 0, 13.5)
	K.limb(mast.Position, (mast * CFrame.new(0, 15, 0)).Position, 0.32, C.barkDark, M.Wood, m, true)
	for i = 0, 2 do
		K.wedge(
			V(0.15, 1.4, 2.4),
			mast * CFrame.Angles(0, i * math.rad(120), 0) * CFrame.new(0, 14.2 - i * 1.6, -1.3),
			K.rgb(Ambience.Papel[(i % #Ambience.Papel) + 3]),
			M.Fabric,
			m
		)
	end
	K.lantern((mast * CFrame.new(0, 12, -0.8)).Position, 0.6, m, false)
	return stage
end

function Station.RepisaCofres(m: Model, cf: CFrame, front: number)
	solid(V(17, 15, 2.6), cf * CFrame.new(0, 7.5, 2.4), C.stone, M.Slate, m)
	K.box(V(10.6, 11.4, 0.3), cf * CFrame.new(0, 6.4, 1), C.cacaoMid, M.Slate, m)
	for _, x in ipairs({ -6, 6 }) do
		solid(V(2.2, 13, 1.8), cf * CFrame.new(x, 6.5, 0.6), C.stoneMid, M.Slate, m)
	end
	solid(V(14.4, 2.2, 1.8), cf * CFrame.new(0, 13.1, 0.6), C.stoneMid, M.Slate, m)
	for _, s in ipairs({ -1, 1 }) do -- arco rebajado
		K.wedge(
			V(1.8, 1.4, 2.2),
			cf * CFrame.new(s * 4, 11.3, 0.6) * CFrame.Angles(0, math.rad(-90 * s), math.rad(180)),
			C.stoneMid,
			M.Slate,
			m
		)
	end
	local chestColors = { C.barkPale, C.stoneMid, C.brass, C.bark, C.barkPale }
	for shelf = 0, 2 do
		local y = 2.6 + shelf * 3.4
		K.box(V(10.4, 0.4, 2.4), cf * CFrame.new(0, y, 0.2), C.barkPale, M.WoodPlanks, m)
		for j = 0, 1 do
			if shelf * 2 + j < 5 then
				local x = (j - 0.5) * 4.4 + (shelf - 1) * 0.8
				local c = cf * CFrame.new(x, y + 0.9, 0)
				local size = 1 - shelf * 0.12
				K.box(V(2.4, 1.3, 1.5) * size, c, chestColors[shelf * 2 + j + 1], M.Wood, m)
				K.part({
					Shape = Enum.PartType.Cylinder,
					Size = V(2.4 * size, 1.5 * size, 1.5 * size),
					CFrame = c * CFrame.new(0, 0.65 * size, 0),
					Color = chestColors[shelf * 2 + j + 1]:Lerp(C.barkDark, 0.2),
					Material = M.Wood,
				}, m).CanCollide =
					false
				K.box(V(0.35, 1.6, 1.6) * size, c * CFrame.new(0, 0.15, 0), C.brass, M.Metal, m)
			end
		end
	end
	K.light(K.ball(0.6, (cf * CFrame.new(0, 11.4, 0.4)).Position, C.copalGlow, M.Neon, m), C.copalGlow, 10, 1)
	-- Cornisa escalonada con greca y espadaña con campana
	solid(V(18.4, 1, 3.6), cf * CFrame.new(0, 15.5, 2.2), C.stoneMid, M.Slate, m)
	solid(V(15.6, 1, 3.1), cf * CFrame.new(0, 16.5, 2.3), C.stone, M.Slate, m)
	greca(cf * CFrame.new(0, 16, 0.3), 16, 13, C.stoneDark, m)
	local esp = cf * CFrame.new(0, 17, 2.4)
	for _, x in ipairs({ -2.2, 2.2 }) do
		solid(V(1.2, 4.2, 1.4), esp * CFrame.new(x, 2.1, 0), C.stone, M.Slate, m)
	end
	solid(V(5.6, 1.2, 1.6), esp * CFrame.new(0, 4.8, 0), C.stoneMid, M.Slate, m)
	K.wedge(V(5.6, 1.4, 0.8), esp * CFrame.new(0, 6.1, -0.4), C.stone, M.Slate, m)
	K.ball(1.5, (esp * CFrame.new(0, 3, 0)).Position, C.brass, M.Metal, m)
	return solid(V(6, 0.8, 2.6), cf * CFrame.new(0, 0.4, front), C.stoneMid, M.Slate, m)
end

function Station.Mirador(m: Model, cf: CFrame, front: number)
	local h = 5
	solid(V(14, h, 12), cf * CFrame.new(0, h / 2, 1), C.stone, M.Slate, m).CanQuery = true
	K.box(V(14.3, 0.7, 12.3), cf * CFrame.new(0, h - 0.9, 1), C.stoneDark, M.Slate, m)
	for k = 1, 6 do -- escalera lateral (deja libre la calzada del Gabinete)
		local s = solid(
			V(1.5, h * k / 6, 5),
			cf * CFrame.new(-7.75 - (6 - k) * 1.5, h * k / 12, -2.2),
			C.stoneMid,
			M.Slate,
			m
		)
		s.CanQuery = true
	end
	-- Barandal: fondo, lado derecho y medio frente (la escalera llega por la izquierda)
	local corners = { V(-6.8, 0, 6.8), V(6.8, 0, 6.8), V(6.8, 0, -5), V(-1.5, 0, -5) }
	for i = 1, 3 do
		local a, b = cf * CFrame.new(corners[i] + V(0, h, 0)), cf * CFrame.new(corners[i + 1] + V(0, h, 0))
		K.limb(a.Position, (a * CFrame.new(0, 2.6, 0)).Position, 0.28, C.barkDark, M.Wood, m, true)
		K.limb(
			(a * CFrame.new(0, 2.4, 0)).Position,
			(b * CFrame.new(0, 2.4, 0)).Position,
			0.18,
			C.bark,
			M.Wood,
			m,
			true
		)
	end
	-- Catalejos de latón hacia las puertas (detrás, +Z local)
	for _, x in ipairs({ -3.6, 3.6 }) do
		local base = cf * CFrame.new(x, h, 4.2)
		for i = 0, 2 do
			local a = i / 3 * math.pi * 2
			K.limb(
				(base * CFrame.new(math.cos(a) * 0.9, 0, math.sin(a) * 0.9)).Position,
				(base * CFrame.new(0, 2.6, 0)).Position,
				0.1,
				C.barkDark,
				M.Wood,
				m
			)
		end
		K.limb(
			(base * CFrame.new(0, 2.7, -0.9)).Position,
			(base * CFrame.new(x * 0.1, 3.4, 1.9)).Position,
			0.32,
			C.brass,
			M.Metal,
			m
		)
	end
	-- Pérgola y mástil de remate
	for _, p in ipairs({ { -4.5, -1.5 }, { 4.5, -1.5 }, { -4.5, 4.5 }, { 4.5, 4.5 } }) do
		K.limb(
			(cf * CFrame.new(p[1], h, p[2])).Position,
			(cf * CFrame.new(p[1], h + 6, p[2])).Position,
			0.3,
			C.bark,
			M.Wood,
			m,
			true
		)
	end
	K.gable(10.4, 7.6, 1.8, cf * CFrame.new(0, h + 6, 1.5), C.clay, m)
	local mast = cf * CFrame.new(6.2, h, 6.2)
	K.limb(mast.Position, (mast * CFrame.new(0, 13, 0)).Position, 0.22, C.barkDark, M.Wood, m, true)
	K.wedge(
		V(0.15, 1.4, 3),
		mast * CFrame.new(0, 12, 1.6) * CFrame.Angles(0, math.pi, 0),
		K.rgb(Ambience.Papel[3]),
		M.Fabric,
		m
	)
	local table_ = solid(V(3, 1.2, 1.8), cf * CFrame.new(0, h + 0.6, front + 4.2), C.bark, M.Wood, m)
	K.box(V(2.6, 0.08, 1.5), cf * CFrame.new(0, h + 1.24, front + 4.2), C.cream, M.SmoothPlastic, m)
	return table_
end

function Station.Despensa(m: Model, cf: CFrame, front: number)
	solid(V(9, 0.4, 8), cf * CFrame.new(0, 0.2, 0), C.stone, M.Slate, m)
	solid(V(9, 7.5, 0.8), cf * CFrame.new(0, 3.75, 3.6), C.adobe, M.Plaster, m)
	for _, p in ipairs({ { -4.2, -2.6 }, { 4.2, -2.6 } }) do
		K.limb(
			(cf * CFrame.new(p[1], 0, p[2])).Position,
			(cf * CFrame.new(p[1], 6.4, p[2])).Position,
			0.3,
			C.bark,
			M.Wood,
			m,
			true
		)
	end
	-- Estantes con cántaros, costales y raciones
	for shelf = 0, 1 do
		local y = 2.6 + shelf * 2.4
		K.box(V(7.6, 0.3, 1.4), cf * CFrame.new(0, y, 2.6), C.barkPale, M.WoodPlanks, m)
		for j = -1, 1 do
			local c = if (j + shelf) % 2 == 0 then C.clay else C.clayPale
			K.ellipsoid(V(1.3, 1.6, 1.3), cf * CFrame.new(j * 2.4 + shelf * 0.6, y + 0.9, 2.6), c, M.Slate, m)
		end
	end
	K.ellipsoid(V(1.8, 1.4, 1.6), cf * CFrame.new(-3, 0.9, 1.4), C.cream, M.Fabric, m)
	K.ellipsoid(V(1.6, 1.2, 1.4), cf * CFrame.new(-1.6, 0.8, 1.8), C.cream:Lerp(C.clayPale, 0.3), M.Fabric, m)
	local counter = solid(V(7.4, 2.6, 1.2), cf * CFrame.new(0, 1.3, front + 0.6), C.bark, M.Wood, m)
	K.box(V(7.8, 0.3, 1.5), cf * CFrame.new(0, 2.75, front + 0.6), C.barkPale, M.WoodPlanks, m)
	K.box(V(7.6, 1.2, 0.1), cf * CFrame.new(0, 2, front - 0.02), C.jade, M.Fabric, m)
	-- Toldo inclinado y letrero colgante
	K.box(
		V(10, 0.25, 6.6),
		cf * CFrame.new(0, 6.9, 0.2) * CFrame.Angles(math.rad(-14), 0, 0),
		C.jade:Lerp(C.cream, 0.35),
		M.Fabric,
		m
	)
	for i = -2, 2 do
		K.box(V(1.6, 0.8, 0.1), cf * CFrame.new(i * 2, 5.9, -3.05), if i % 2 == 0 then C.jade else C.cream, M.Fabric, m)
	end
	local sign = K.box(V(4.6, 1.2, 0.2), cf * CFrame.new(0, 4.9, -3.1), C.barkPale, M.WoodPlanks, m)
	sign.Name = "Letrero"
	K.lantern((cf * CFrame.new(3.4, 6.5, -2.2)).Position, 0.4, m, true)
	return counter
end

-- ---------------------------------------------------------------------------
-- Puertas de los biomas (selladas, con vitral y sello del elemento)
-- ---------------------------------------------------------------------------
local GLYPH = {
	MareaCoralina = "wave",
	CumbreBrasa = "flame",
	MesetaFulgor = "bolt",
	VeloAstral = "star",
}

local function gate(gateCfg: any, parent: Instance)
	local pos = K.v3(gateCfg.position)
	local cf = flatLook(pos, TREE)
	local m = K.model("Puerta_" .. gateCfg.biome, parent)
	local biome = SpeciesConfig.Biomes[gateCfg.biome]
	local elementColor = ({
		MareaCoralina = Elements.ById.Agua.color,
		CumbreBrasa = Elements.ById.Fuego.color,
		MesetaFulgor = Elements.ById.Rayo.color,
		VeloAstral = Elements.ById.Astral.color,
	})[gateCfg.biome]
	local tint = K.rgb(elementColor)
	solid(V(18, 0.8, 7), cf * CFrame.new(0, 0.4, 0), C.stoneMid, M.Slate, m)
	for _, x in ipairs({ -6.4, 6.4 }) do
		solid(V(3.6, 2, 3.6), cf * CFrame.new(x, 1.8, 0), C.stoneMid, M.Slate, m)
		solid(V(2.8, 17, 2.8), cf * CFrame.new(x, 11.3, 0), C.stone, M.Slate, m)
	end
	solid(V(17, 2.6, 3.6), cf * CFrame.new(0, 21, 0), C.stone, M.Slate, m)
	greca(cf * CFrame.new(0, 20.1, -1.85), 14, 9, C.stoneDark, m)
	solid(V(9, 1.4, 3), cf * CFrame.new(0, 23, 0), C.stoneMid, M.Slate, m)
	local glass = solid(V(9.6, 18, 0.6), cf * CFrame.new(0, 11, 0), tint:Lerp(C.stone, 0.25), M.Glass, m)
	glass.Transparency = 0.35
	local sealCf = cf * CFrame.new(0, 11, -0.5)
	K.part({
		Shape = Enum.PartType.Cylinder,
		Size = V(0.5, 4.4, 4.4),
		CFrame = sealCf * CFrame.Angles(0, math.rad(90), 0),
		Color = C.stone,
		Material = M.Slate,
	}, m).CanCollide =
		false
	local glyphCf = sealCf * CFrame.new(0, 0, -0.35)
	local kind = GLYPH[gateCfg.biome]
	if kind == "flame" then
		K.wedge(V(0.3, 2.4, 1.4), glyphCf * CFrame.Angles(0, math.rad(90), 0), tint, M.SmoothPlastic, m)
		K.ball(1.2, (glyphCf * CFrame.new(0, -0.9, 0)).Position, tint, M.SmoothPlastic, m)
	elseif kind == "wave" then
		for i = -1, 1 do
			K.box(
				V(0.9, 0.4, 0.3),
				glyphCf * CFrame.new(i * 0.9, math.abs(i) * 0.5 - 0.2, 0) * CFrame.Angles(0, 0, i * 0.6),
				tint,
				M.SmoothPlastic,
				m
			)
		end
	elseif kind == "bolt" then
		for i = -1, 1 do
			K.box(
				V(0.4, 1.3, 0.3),
				glyphCf * CFrame.new(i * 0.35, -i * 0.9, 0) * CFrame.Angles(0, 0, if i == 0 then -0.9 else 0.5),
				tint,
				M.SmoothPlastic,
				m
			)
		end
	else -- estrella de ocho puntas: dos rayos largos y dos cortos
		for i = 0, 3 do
			local long = i % 2 == 0
			K.box(
				V(if long then 3 else 1.8, 0.35, 0.3),
				glyphCf * CFrame.Angles(0, 0, i * math.pi / 4),
				tint,
				M.SmoothPlastic,
				m
			)
		end
		K.ball(0.8, glyphCf.Position, tint, M.SmoothPlastic, m)
	end
	-- Enredadera que trepa por una jamba
	K.limb(
		(cf * CFrame.new(-6.4, 0.5, -1.6)).Position,
		(cf * CFrame.new(-5.6, 14, -1.6)).Position,
		0.25,
		C.leafDeep,
		M.Grass,
		m
	)
	K.ellipsoid(V(2.6, 3.4, 1.2), cf * CFrame.new(-6.2, 9, -1.7), C.leafDeep, M.LeafyGrass, m)
	K.ellipsoid(V(2.2, 2.4, 1.1), cf * CFrame.new(-5.6, 14.2, -1.7), C.leaf, M.LeafyGrass, m)
	K.label(glass, biome.name, biome.act .. " · sellado")
end

function TorreBuilder.build(root: Instance): { [string]: Model }
	local folder = K.folder("Stations", root)
	basamento(folder)
	local out: { [string]: Model } = {}
	local plaza = K.v3(World.Plaza.center)
	for id, st in pairs(World.Stations) do
		local shell = Landscape.Torre.stations[id]
		local pos = K.v3(st.position)
		local faceTo = if shell.face == "plaza" then plaza else TREE
		local away = (V(pos.X, 0, pos.Z) - V(faceTo.X, 0, faceTo.Z)).Unit
		local center = pos + away * shell.outward
		local cf = flatLook(center, center - away)
		local m = K.model(id, folder)
		local front = -shell.outward
		local booth = (Station :: any)[id](m, cf, front)
		-- El prompt queda sobre la posición que valida el servidor
		prompt(booth, id, st)
		m.PrimaryPart = booth
		m:SetAttribute("AssetStatus", "Blockout")
		out[id] = m
	end
	local gates = K.folder("BiomeGates", folder)
	for _, g in ipairs(World.BiomeGates) do
		gate(g, gates)
	end
	return out
end

return TorreBuilder
