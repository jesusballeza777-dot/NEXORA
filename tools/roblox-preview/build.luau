--!strict
-- Vista de los BLOCKOUTS de Roblox fuera de Studio.
-- Construye las criaturas con el CreatureBuilder real del cliente y Valle Copal con el
-- ValleBuilder real del servidor (mismas piezas, tamaños, colores y materiales) usando
-- las clases de @lune/roblox (tests/lib/RobloxSandbox), y genera:
--   build/roblox-preview/Creatures.html  galería de criaturas (?front&big&form=Brote)
--   build/roblox-preview/World.html      el valle con su terreno (?view=spawn|aerial|lots|linde)
-- Sirve para revisar caras, siluetas, paletas y composición sin abrir Studio.
-- No sustituye a Studio: la iluminación, el agua y el pasto son aproximados.
--
-- Uso (desde la raíz del repo):  lune run tools/roblox-preview/build

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local VirtualGame = require("../../tests/lib/VirtualGame")
local RobloxSandbox = require("../../tests/lib/RobloxSandbox")
local roblox = RobloxSandbox.roblox

local sandbox = RobloxSandbox.new()
local CreatureBuilder = sandbox.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder")
local Visuals = VirtualGame.get("ReplicatedStorage.Shared.Config.Visuals")
local Species = VirtualGame.get("ReplicatedStorage.Shared.Config.Species")
local Guardians = VirtualGame.get("ReplicatedStorage.Shared.Config.Guardians")

local function shapeOf(part: any): string
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	if mesh and mesh.MeshType == roblox.Enum.MeshType.Sphere then
		return "Ellipsoid"
	end
	if part.Shape == roblox.Enum.PartType.Cylinder then
		return "Cylinder"
	end
	if part.Shape == roblox.Enum.PartType.Ball then
		return "Ball"
	end
	return "Block"
end

local function round(n: number): number
	return math.floor(n * 1000 + 0.5) / 1000
end

local ids = {}
for id in pairs(Visuals.ById) do
	table.insert(ids, id)
end
table.sort(ids, function(a, b)
	local order = { kuachi = 1, xolumi = 2, teselo = 3 }
	return (order[a] or 9) .. a < (order[b] or 9) .. b
end)

local creatures = {}
for _, id in ipairs(ids) do
	for _, form in ipairs({ "Brote", "Tallado" }) do
		for _, opaco in ipairs({ false, true }) do
			if not opaco or form == "Brote" then
				local c = CreatureBuilder.build(id, form, { opaco = opaco })
				CreatureBuilder.pose(c, roblox.CFrame.new())
				local parts = {}
				for _, rec in ipairs(c.parts) do
					local p = rec.part
					local comps = { p.CFrame:GetComponents() }
					for i, v in ipairs(comps) do
						comps[i] = round(v)
					end
					table.insert(parts, {
						shape = shapeOf(p),
						size = { round(p.Size.X), round(p.Size.Y), round(p.Size.Z) },
						cf = comps,
						color = { round(p.Color.R), round(p.Color.G), round(p.Color.B) },
						neon = p.Material == roblox.Enum.Material.Neon,
						transparency = round(p.Transparency),
					})
				end
				local sp = Species.ById[id]
				local guardian = Guardians.ById[id]
				table.insert(creatures, {
					id = id,
					form = form,
					opaco = opaco,
					name = if guardian
						then guardian.shortName
						elseif form == "Tallado" then sp.talladoName
						else sp.broteName,
					parts = parts,
				})
				c:destroy()
			end
		end
	end
end

local function partRecord(p: any): { [string]: any }
	local comps = { p.CFrame:GetComponents() }
	for i, v in ipairs(comps) do
		comps[i] = round(v)
	end
	return {
		shape = shapeOf(p),
		size = { round(p.Size.X), round(p.Size.Y), round(p.Size.Z) },
		cf = comps,
		color = { round(p.Color.R), round(p.Color.G), round(p.Color.B) },
		neon = p.Material == roblox.Enum.Material.Neon,
		material = p.Material.Name,
		transparency = round(p.Transparency),
	}
end

fs.writeDir("build/roblox-preview")
local function emit(templatePath: string, outPath: string, data: any)
	local template = fs.readFile(templatePath)
	local json = serde.encode("json", data, false)
	local html = string.gsub(template, "__DATA__", function()
		return json
	end)
	fs.writeFile(outPath, html)
end

emit("tools/roblox-preview/viewer.html", "build/roblox-preview/Creatures.html", creatures)

-- Valle Copal: el mismo ValleBuilder que ejecuta el servidor
local worldBox = RobloxSandbox.new()
local ValleBuilder = worldBox.load("ServerScriptService.Server.World.ValleBuilder")
local built = ValleBuilder.build()
local worldParts = {}
for _, d in ipairs(built.root:GetDescendants()) do
	if d:IsA("BasePart") and d.Transparency < 1 then
		table.insert(worldParts, partRecord(d))
	end
end
local terrainOps = {}
local materialColors = {}
for _, call in ipairs(worldBox.terrainCalls) do
	local a = call.args
	if call.method == "FillBlock" then
		local comps = { a[1]:GetComponents() }
		table.insert(terrainOps, {
			kind = "Block",
			cf = comps,
			size = { a[2].X, a[2].Y, a[2].Z },
			material = a[3].Name,
		})
	elseif call.method == "FillBall" then
		table.insert(terrainOps, {
			kind = "Ball",
			center = { a[1].X, a[1].Y, a[1].Z },
			radius = a[2],
			material = a[3].Name,
		})
	elseif call.method == "SetMaterialColor" then
		materialColors[a[1].Name] = { a[2].R, a[2].G, a[2].B }
	end
end
local L = worldBox.lighting
local atmosphere = L:FindFirstChildOfClass("Atmosphere")
local t = worldBox.terrain
emit("tools/roblox-preview/world.html", "build/roblox-preview/World.html", {
	parts = worldParts,
	terrain = terrainOps,
	materialColors = materialColors,
	water = { color = { t.WaterColor.R, t.WaterColor.G, t.WaterColor.B }, transparency = t.WaterTransparency },
	lighting = {
		clockTime = L.ClockTime,
		latitude = L.GeographicLatitude,
		ambient = { L.OutdoorAmbient.R, L.OutdoorAmbient.G, L.OutdoorAmbient.B },
		atmosphere = {
			color = { atmosphere.Color.R, atmosphere.Color.G, atmosphere.Color.B },
			decay = { atmosphere.Decay.R, atmosphere.Decay.G, atmosphere.Decay.B },
			density = atmosphere.Density,
		},
	},
})
print(
	string.format(
		"Blockouts de Roblox: %d criaturas, mundo con %d partes y %d rellenos de terreno → build/roblox-preview/",
		#creatures,
		#worldParts,
		#terrainOps
	)
)
