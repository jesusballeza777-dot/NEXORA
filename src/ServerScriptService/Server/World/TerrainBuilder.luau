--!strict
-- Ejecuta en Workspace.Terrain los rellenos que describe Landform (terreno primero:
-- colinas, terrazas, orillas, río, lago, chinampas y cascada) y aplica el aspecto de los
-- materiales, el agua y las nubes de Config/Ambience. También prepara la iluminación.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ambience = require(Shared.Config.Ambience)
local Landform = require(script.Parent.Landform)

local TerrainBuilder = {}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

function TerrainBuilder.lighting()
	local L = Ambience.Lighting
	Lighting.ClockTime = L.clockTime
	Lighting.Brightness = L.brightness
	Lighting.GeographicLatitude = L.geographicLatitude
	Lighting.Ambient = rgb(L.ambient)
	Lighting.OutdoorAmbient = rgb(L.outdoorAmbient)
	Lighting.EnvironmentDiffuseScale = L.environmentDiffuseScale
	Lighting.EnvironmentSpecularScale = L.environmentSpecularScale
	Lighting.ShadowSoftness = L.shadowSoftness
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	local A = Ambience.Atmosphere
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = A.density
	atmosphere.Offset = A.offset
	atmosphere.Color = rgb(A.color)
	atmosphere.Decay = rgb(A.decay)
	atmosphere.Glare = A.glare
	atmosphere.Haze = A.haze
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = Ambience.Bloom.intensity
	bloom.Size = Ambience.Bloom.size
	bloom.Threshold = Ambience.Bloom.threshold
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = Ambience.SunRays.intensity
	rays.Spread = Ambience.SunRays.spread
	rays.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = Ambience.Grade.saturation
	grade.Contrast = Ambience.Grade.contrast
	grade.TintColor = rgb(Ambience.Grade.tint)
	grade.Parent = Lighting
end

-- Devuelve cuántos rellenos se ejecutaron (presupuesto en docs/WORLD_BUILDING.md)
function TerrainBuilder.build(): number
	local terrain = Workspace.Terrain
	local look = Ambience.Terrain
	terrain.Decoration = look.decoration
	for name, color in pairs(look.materials) do
		terrain:SetMaterialColor((Enum.Material :: any)[name], rgb(color))
	end
	local ops = Landform.ops()
	for _, op in ipairs(ops) do
		local pos = Vector3.new(op.pos[1], op.pos[2], op.pos[3])
		local material = (Enum.Material :: any)[op.material]
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(op.yaw or 0), 0)
		if op.fn == "FillBlock" then
			local s = op.size :: { number }
			terrain:FillBlock(cf, Vector3.new(s[1], s[2], s[3]), material)
		elseif op.fn == "FillWedge" then
			local s = op.size :: { number }
			terrain:FillWedge(cf, Vector3.new(s[1], s[2], s[3]), material)
		elseif op.fn == "FillBall" then
			terrain:FillBall(pos, op.radius :: number, material)
		elseif op.fn == "FillCylinder" then
			terrain:FillCylinder(cf, op.height :: number, op.radius :: number, material)
		end
	end
	local water = look.water
	terrain.WaterColor = rgb(water.color)
	terrain.WaterTransparency = water.transparency
	terrain.WaterWaveSize = water.waveSize
	terrain.WaterWaveSpeed = water.waveSpeed
	terrain.WaterReflectance = water.reflectance
	local clouds = Instance.new("Clouds")
	clouds.Cover = Ambience.Clouds.cover
	clouds.Density = Ambience.Clouds.density
	clouds.Color = rgb(Ambience.Clouds.color)
	clouds.Parent = terrain
	return #ops
end

return TerrainBuilder
