--!strict
-- Fauna ambiental del valle (Bloque J): el servidor solo la construye y la etiqueta; la
-- anima el cliente (Client/Controllers/AmbientLifeController) con LOD por distancia.
--   AmbientBirds        · bandadas que circulan sobre el Gran Nexo y sobre las terrazas
--   AmbientFish         · peces que saltan de vez en cuando en el río y el lago
--   AmbientButterflies  · mariposas sobre las flores de la plaza, los lotes y las chinampas
-- Todo sin colisión ni consultas y con pocas piezas (presupuesto en WORLD_BUILDING.md).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Landscape = require(Shared.Config.Landscape)
local Ambience = require(Shared.Config.Ambience)
local WorldKit = require(script.Parent.WorldKit)

local FaunaBuilder = {}

local K = WorldKit
local C = K.C
local M = Enum.Material
local V = Vector3.new

local function bird(cf: CFrame, parent: Instance): Model
	local m = K.model("Ave", parent)
	K.ellipsoid(V(0.7, 0.55, 1.5), cf, C.cacaoMid, M.SmoothPlastic, m).Name = "Body"
	for _, side in ipairs({ -1, 1 }) do
		local w = K.box(
			V(1.7, 0.08, 0.8),
			cf * CFrame.new(side * 1.05, 0.05, 0.1),
			C.cacaoMid:Lerp(C.stoneMid, 0.25),
			M.SmoothPlastic,
			m
		)
		w.Name = if side < 0 then "WingL" else "WingR"
	end
	m.WorldPivot = cf
	return m
end

function FaunaBuilder.build(root: Instance)
	local folder = K.folder("Fauna", root)
	local L = Landscape.Life
	for i, f in ipairs(L.flocks) do
		local flock = K.model("Bandada" .. i, folder)
		local c = K.v3(f.center)
		for b = 1, f.count do
			local a = b / f.count * math.pi * 2
			bird(CFrame.new(c + V(math.cos(a) * f.radius, 0, math.sin(a) * f.radius)), flock)
		end
		flock:SetAttribute("Flock", i)
		flock.WorldPivot = CFrame.new(c)
		flock:AddTag("AmbientBirds")
	end
	local wl = Landscape.River.waterLevel
	for i, f in ipairs(L.fish) do
		local m = K.model("Pez" .. i, folder)
		local cf = CFrame.new(f.origin[1], wl - 1.2, f.origin[2]) * CFrame.Angles(0, math.rad(f.heading), 0)
		local body = K.ellipsoid(V(0.7, 0.6, 1.9), cf, C.copal:Lerp(C.clay, 0.3), M.SmoothPlastic, m)
		body.Name = "Body"
		K.wedge(V(0.1, 0.8, 0.7), cf * CFrame.new(0, 0, 1.2), C.clay, M.SmoothPlastic, m).Name = "Tail"
		for _, d in ipairs(m:GetChildren()) do
			(d :: BasePart).Transparency = 1 -- bajo el agua hasta que salta
		end
		m.WorldPivot = cf
		m:SetAttribute("Fish", i)
		m:AddTag("AmbientFish")
	end
	for i, g in ipairs(L.butterflies) do
		local group = K.model("Mariposas" .. i, folder)
		local c = K.v3(g.center)
		for b = 1, g.count do
			local m = K.model("Mariposa", group)
			local cf = CFrame.new(c + V(b - g.count / 2, 1.5, 0))
			local color = if b % 2 == 0 then K.rgb(Ambience.Flowers.colors[1]) else C.cream
			for _, side in ipairs({ -1, 1 }) do
				local w = K.box(V(0.55, 0.05, 0.5), cf * CFrame.new(side * 0.3, 0, 0), color, M.SmoothPlastic, m)
				w.Name = if side < 0 then "WingL" else "WingR"
				w.CastShadow = false
			end
			m.WorldPivot = cf
		end
		group:SetAttribute("Group", i)
		group.WorldPivot = CFrame.new(c)
		group:AddTag("AmbientButterflies")
	end
end

return FaunaBuilder
