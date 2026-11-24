--!strict
-- El Gabinete que Camina: un Nexum anciano, gabinete de curiosidades vivo (inspiración:
-- máquinas místicas de Remedios Varo y escaleras imposibles). No es un cofre con cajones:
--   · cuerpo alto de gabinete sobre seis patas de madera articuladas (cadera, muslo,
--     rodilla, tibia y pie), con la rodilla por encima del cuerpo, como un insecto;
--   · cajones de tamaños distintos al frente y, en los costados, cajones largos que se
--     abultan como costillas;
--   · dos ojos-farol de copal sobre tallos, con párpado de madera;
--   · el cajón ancho entreabierto con luz dentro es su boca (habla por cajones);
--   · una escalera de caracol a la espalda que sube hasta el tejadito.
-- El servidor solo lo construye en su descanso (frente a la Despensa) y lo etiqueta
-- («GabineteWalk»); el cliente lo hace caminar por la ruta de Config/Landscape.Gabinete.
-- Sin colisión ni consultas: camina entre jugadores sin empujarlos ni tapar prompts.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = require(Shared.Config.World)
local Landscape = require(Shared.Config.Landscape)
local WorldKit = require(script.Parent.WorldKit)

local GabineteBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

-- Punto de descanso: sobre la ruta, en la dirección de su Despensa, mirando hacia fuera
function GabineteBuilder.dock(): CFrame
	local g = Landscape.Gabinete
	local tree = K.v3(World.GranNexo.position)
	local st = K.v3(World.Stations[g.dockStation].position)
	local dir = (V(st.X, 0, st.Z) - V(tree.X, 0, tree.Z)).Unit
	local pos = V(tree.X, 0, tree.Z) + dir * g.radius
	return CFrame.lookAt(pos, pos + dir)
end

-- Patas: cadera en el costado del cuerpo; la rodilla sube por encima de la cadera
local LEGS = {
	{ side = -1, z = -2.3, gait = 0 },
	{ side = 1, z = -2.3, gait = 1 },
	{ side = -1, z = 0, gait = 1 },
	{ side = 1, z = 0, gait = 0 },
	{ side = -1, z = 2.3, gait = 0 },
	{ side = 1, z = 2.3, gait = 1 },
}
GabineteBuilder.Legs = LEGS

function GabineteBuilder.build(root: Instance): Model
	local cf = GabineteBuilder.dock()
	local m = K.model("GabineteQueCamina", root)
	local body = K.model("Body", m)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end

	-- Cuerpo y moldura
	K.box(V(8, 12, 6), at(0, 14, 0), C.barkDark, M.Wood, body).Name = "Core"
	K.box(V(8.8, 0.7, 6.8), at(0, 20.3, 0), C.bark, M.Wood, body)
	K.box(V(8.6, 0.6, 6.6), at(0, 8.1, 0), C.bark, M.Wood, body)

	-- Cajones del frente (−Z): filas de tamaños distintos con tirador de latón
	local rows = {
		{ 18.6, 1.8, { 2.2, 3.0, 2.2 } },
		{ 16.4, 2.2, { 3.6, 3.6 } },
		{ 13.9, 2.4, { 7.4 } },
		{ 11.4, 2.2, { 2.4, 2.4, 2.4 } },
		{ 9.3, 1.8, { 3.6, 3.6 } },
	}
	for r, row in ipairs(rows) do
		local total = 0
		for _, w in ipairs(row[3]) do
			total += w
		end
		local x = -total / 2
		for _, w in ipairs(row[3]) do
			local cx = x + w / 2
			local open = r == 3
			local depth = if open then 1.6 else 0.5
			local zf = -3 - depth / 2 - (if open then 0.6 else 0)
			K.box(V(w - 0.25, row[2] - 0.25, depth), at(cx, row[1], zf), C.barkPale, M.WoodPlanks, body)
			K.ball(0.42, (at(cx, row[1], zf - depth / 2 - 0.15)).Position, C.brass, M.Metal, body)
			if open then
				-- La boca: cajón ancho entreabierto con luz cálida dentro
				K.box(V(w - 1, 0.3, 0.8), at(cx, row[1] + 0.95, -3.4), C.copalGlow, M.Neon, body).CastShadow = false
			end
			x += w
		end
	end

	-- Costillas: cajones largos en los costados que se abultan hacia el centro
	local bulge = { 0.3, 0.8, 1.15, 0.8, 0.3 }
	for _, side in ipairs({ -1, 1 }) do
		for k, b in ipairs(bulge) do
			local y = 9.4 + k * 1.85
			K.box(
				V(0.5 + b, 1.5, 5.4 - b * 0.6),
				at(side * (4 + (0.5 + b) / 2), y, 0),
				C.barkPale:Lerp(C.bark, (k % 2) * 0.3),
				M.WoodPlanks,
				body
			)
			K.ball(0.36, (at(side * (4.3 + 0.5 + b), y, 0)).Position, C.brass, M.Metal, body)
		end
	end

	-- Ojos-farol con párpado
	for _, side in ipairs({ -1, 1 }) do
		local stalk = at(side * 3, 20.6, -2)
		local eye = at(side * 3.8, 23.2, -3)
		K.limb(stalk.Position, (eye * CFrame.new(0, -1.1, 0)).Position, 0.3, C.bark, M.Wood, body)
		local shell = K.ellipsoid(V(2.2, 2.6, 2.2), eye, C.copal, M.Glass, body)
		shell.Transparency = 0.2
		shell.CastShadow = false
		local core = K.ball(1, eye.Position, C.copalGlow, M.Neon, body)
		core.Name = "Eye"
		core.CastShadow = false
		K.light(core, C.copalGlow, 9, 1.2)
		K.wedge(
			V(2.6, 0.7, 1.4),
			eye * CFrame.new(0, 1.15, -0.2) * CFrame.Angles(0, 0, side * 0.18),
			C.barkDark,
			M.Wood,
			body
		)
	end

	-- Tejadito a dos aguas con remate de copal
	K.gable(7.6, 9.6, 2.6, at(0, 20.6, 0) * CFrame.Angles(0, math.rad(90), 0), C.clay, body)
	K.limb(at(0, 23.3, -4.8).Position, at(0, 23.3, 4.8).Position, 0.25, C.barkDark, M.Wood, body)
	K.limb(at(0, 23.3, -3.6).Position, at(0, 25.6, -3.6).Position, 0.12, C.brass, M.Metal, body)
	K.ball(0.7, at(0, 25.9, -3.6).Position, C.copalGlow, M.Neon, body)

	-- Escalera de caracol a la espalda (+Z), del suelo de su vientre al tejado
	local pole = at(0, 0, 4.9)
	K.limb(
		(pole * CFrame.new(0, 7.2, 0)).Position,
		(pole * CFrame.new(0, 24.4, 0)).Position,
		0.3,
		C.barkDark,
		M.Wood,
		body
	)
	for k = 0, 13 do
		local a = math.rad(k * 42)
		local y = 7.8 + k * 1.15
		K.box(
			V(2.4, 0.25, 0.9),
			pole * CFrame.new(0, y, 0) * CFrame.Angles(0, a, 0) * CFrame.new(1.25, 0, 0),
			C.barkPale,
			M.WoodPlanks,
			body
		)
	end
	K.disc(1.6, 0.3, (pole * CFrame.new(0, 24.6, 0)).Position, C.bark, M.Wood, body)

	-- Patas articuladas (cada una es un modelo con pivote en la cadera)
	for i, leg in ipairs(LEGS) do
		local lm = K.model("Leg" .. i, m)
		local s = leg.side
		local hip = at(s * 4.3, 9.2, leg.z)
		local knee = at(s * 7.6, 13.4, leg.z * 1.3)
		local foot = at(s * 9.4, 0.35, leg.z * 1.55)
		K.ball(1.2, hip.Position, C.bark, M.Wood, lm)
		K.limb(hip.Position, knee.Position, 0.45, C.bark, M.Wood, lm)
		K.ball(1, knee.Position, C.brass, M.Metal, lm)
		K.limb(knee.Position, foot.Position + V(0, 0.2, 0), 0.34, C.barkDark, M.Wood, lm)
		K.disc(0.7, 0.4, foot.Position, C.barkDark, M.Wood, lm)
		lm.WorldPivot = hip
		lm:SetAttribute("Side", s)
		lm:SetAttribute("Gait", leg.gait)
	end

	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			K.decor(d)
		end
	end
	local core = body:FindFirstChild("Core") :: BasePart
	body.PrimaryPart = core
	K.label(core, "Gabinete que Camina", nil, nil, 13)
	m.PrimaryPart = core
	m.WorldPivot = cf
	m:SetAttribute("AssetStatus", "Blockout")
	m:AddTag("GabineteWalk")
	return m
end

return GabineteBuilder
