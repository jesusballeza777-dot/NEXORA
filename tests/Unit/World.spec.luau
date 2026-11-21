--!strict
-- El mundo y las criaturas de Roblox construidos con las clases reales de @lune/roblox
-- (propiedades y clases inexistentes fallan como en Studio).
local T = harness.T
local expect = T.expect
local fs = require("@lune/fs")
local World = harness.get("ReplicatedStorage.Shared.Config.World")
local Ambience = harness.get("ReplicatedStorage.Shared.Config.Ambience")
local Visuals = harness.get("ReplicatedStorage.Shared.Config.Visuals")
local FloraLayout = harness.get("ServerScriptService.Server.World.FloraLayout")

local function buildWorld()
	local sb = harness.sandbox.new()
	local ValleBuilder = sb.load("ServerScriptService.Server.World.ValleBuilder")
	local result = ValleBuilder.build()
	return sb, result
end

T.describe("Valle Copal en Roblox (ValleBuilder)", function()
	T.it("el sandbox detecta propiedades inexistentes (si no, esta prueba no valdría nada)", function()
		local part = harness.sandbox.roblox.Instance.new("Part")
		expect(pcall(function()
			(part :: any).PropiedadQueNoExiste = 1
		end)).toBe(false)
	end)

	T.it("se construye con clases y propiedades válidas, con ambiente y terreno", function()
		local sb, result = buildWorld()
		expect(result.root.Parent == sb.workspace).toBe(true)
		expect(#result.lots).toBe(#World.Lots.positions)
		for _, class in ipairs({ "Atmosphere", "BloomEffect", "SunRaysEffect", "ColorCorrectionEffect" }) do
			expect(sb.lighting:FindFirstChildOfClass(class) ~= nil).toBe(true)
		end
		expect(math.abs(sb.lighting.ClockTime - Ambience.Lighting.clockTime) < 1e-3).toBe(true)
		expect(sb.terrain.Decoration).toBe(true)
		expect(sb.terrain:FindFirstChildOfClass("Clouds") ~= nil).toBe(true)
		expect(#sb.terrainCalls > 0).toBe(true)
	end)

	T.it("cada ProximityPrompt del mundo tiene manejador en el cliente", function()
		local sb = buildWorld()
		local client = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Client/Controllers/WorldController.luau")
		local names = {}
		for _, d in ipairs(sb.workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				names[d.Name] = true
			end
		end
		expect(next(names) ~= nil).toBe(true)
		for name in pairs(names) do
			if not string.find(client, 'name == "' .. name .. '"', 1, true) then
				error("Prompt sin manejador en WorldController: " .. name)
			end
		end
	end)

	T.it("respeta el presupuesto de partes y de luces (móvil)", function()
		local sb = buildWorld()
		local parts, lights, emitters = 0, 0, 0
		for _, d in ipairs(sb.workspace:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
			elseif d:IsA("Light") then
				lights += 1
			elseif d:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		expect(parts < 1500).toBe(true)
		expect(lights <= 12).toBe(true)
		expect(emitters <= 8).toBe(true)
	end)

	T.it("las flores y motas no estorban: sin colisión ni consultas", function()
		local sb = buildWorld()
		local flora = sb.workspace.ValleCopal.Flora
		for _, d in ipairs(flora:GetDescendants()) do
			if d:IsA("BasePart") then
				expect(d.CanCollide).toBe(false)
				expect(d.CanQuery).toBe(false)
			end
		end
	end)
end)

T.describe("Flores de Valle Copal (FloraLayout)", function()
	T.it("son deterministas y salen todas las matas configuradas", function()
		local a, b = FloraLayout.clusters(), FloraLayout.clusters()
		expect(#a).toBe(Ambience.Flowers.clusters)
		expect(a).toEqual(b)
	end)
	T.it("ninguna cae en plaza, lotes, río, caminos ni zonas de interacción", function()
		for _, c in ipairs(FloraLayout.clusters()) do
			expect(FloraLayout.isClear(c.x, c.z)).toBe(true)
		end
		expect(FloraLayout.isClear(0, 8)).toBe(false) -- plaza
		expect(FloraLayout.isClear(0, 112)).toBe(false) -- lote 3
		expect(FloraLayout.isClear(0, 66)).toBe(false) -- río
		expect(FloraLayout.isClear(-78, 10)).toBe(false) -- primer Opaco
	end)
end)

T.describe("Criaturas de Roblox (CreatureBuilder)", function()
	T.it("todas las especies con visual se construyen en Brote, Tallado y Opaco", function()
		local sb = harness.sandbox.new()
		local CreatureBuilder = sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder")
		for id in pairs(Visuals.ById) do
			for _, form in ipairs({ "Brote", "Tallado" }) do
				local c = CreatureBuilder.build(id, form, { opaco = form == "Brote" })
				expect(#c.parts > 5).toBe(true)
				expect(#c.parts <= 90).toBe(true)
				expect(c.model:GetAttribute("AssetStatus")).toBe("Blockout")
				c:destroy()
			end
		end
	end)
	T.it("los Brotes tienen rubor y sonrisa; la boca se aclara sobre cuerpos oscuros", function()
		local sb = harness.sandbox.new()
		local CreatureBuilder = sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder")
		local function hasColor(c: any, rgb: { number }): boolean
			for _, rec in ipairs(c.parts) do
				local col = rec.baseColor
				if
					math.abs(col.R * 255 - rgb[1]) < 1
					and math.abs(col.G * 255 - rgb[2]) < 1
					and math.abs(col.B * 255 - rgb[3]) < 1
				then
					return true
				end
			end
			return false
		end
		local xolumi = CreatureBuilder.build("xolumi", "Brote")
		expect(hasColor(xolumi, Visuals.Face.blush)).toBe(true)
		expect(hasColor(xolumi, Visuals.Face.mouthOnDark)).toBe(true)
		local teselo = CreatureBuilder.build("teselo", "Brote")
		expect(hasColor(teselo, Visuals.Face.mouth)).toBe(true)
		local tallado = CreatureBuilder.build("teselo", "Tallado")
		expect(hasColor(tallado, Visuals.Face.blush)).toBe(false)
	end)
end)
