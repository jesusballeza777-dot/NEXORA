--!strict
-- El mundo y las criaturas de Roblox construidos con las clases reales de @lune/roblox
-- (propiedades y clases inexistentes fallan como en Studio).
local T = harness.T
local expect = T.expect
local fs = require("@lune/fs")
local World = harness.get("ReplicatedStorage.Shared.Config.World")
local Ambience = harness.get("ReplicatedStorage.Shared.Config.Ambience")
local Landscape = harness.get("ReplicatedStorage.Shared.Config.Landscape")
local Visuals = harness.get("ReplicatedStorage.Shared.Config.Visuals")
local FloraLayout = harness.get("ServerScriptService.Server.World.FloraLayout")
local Landform = harness.get("ServerScriptService.Server.World.Landform")

-- Presupuesto móvil del valle (justificación en docs/WORLD_BUILDING.md §7)
local BUDGET = { parts = 4000, lights = 24, lightRange = 12, emitters = 10, emitterRate = 20, neonThickness = 1.5 }

local built: any = nil
local function buildWorld()
	if built then
		return built.sb, built.result
	end
	local sb = harness.sandbox.new()
	local ValleBuilder = sb.load("ServerScriptService.Server.World.ValleBuilder")
	local result = ValleBuilder.build()
	built = { sb = sb, result = result }
	return sb, result
end

local function flat(a: { number }, x: number, z: number): number
	return math.sqrt((a[1] - x) ^ 2 + (a[3] - z) ^ 2)
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

	T.it("la luz respeta la Biblia visual (bloom, contraste, saturación, atmósfera)", function()
		expect(Ambience.Bloom.intensity <= 0.6).toBe(true)
		expect(Ambience.Bloom.threshold >= 0.9).toBe(true)
		expect(Ambience.Grade.contrast >= 0.05 and Ambience.Grade.contrast <= 0.1).toBe(true)
		expect(math.abs(Ambience.Grade.saturation) <= 0.05).toBe(true)
		expect(Ambience.Atmosphere.density >= 0.3 and Ambience.Atmosphere.density <= 0.38).toBe(true)
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

	T.it("respeta el presupuesto de partes, luces, emisores y neón (móvil)", function()
		local sb = buildWorld()
		local parts, lights, emitters = 0, 0, 0
		for _, d in ipairs(sb.workspace:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				if d.Material == harness.sandbox.roblox.Enum.Material.Neon then
					local s = d.Size
					local thin = math.min(s.X, s.Y, s.Z)
					if thin > BUDGET.neonThickness then
						error(string.format("Neón de %.2f studs de grosor en %s", thin, d:GetFullName()))
					end
				end
			elseif d:IsA("Light") then
				lights += 1
				expect(d.Range <= BUDGET.lightRange).toBe(true)
				expect(d.Shadows).toBe(false)
			elseif d:IsA("ParticleEmitter") then
				emitters += 1
				expect(d.Rate <= BUDGET.emitterRate).toBe(true)
			end
		end
		expect(parts < BUDGET.parts).toBe(true)
		expect(lights <= BUDGET.lights).toBe(true)
		expect(emitters <= BUDGET.emitters).toBe(true)
	end)

	T.it("las flores y la flora no estorban: sin colisión ni consultas (salvo troncos)", function()
		local sb = buildWorld()
		local flora = sb.workspace.ValleCopal.Flora
		for _, d in ipairs(flora:GetDescendants()) do
			if d:IsA("BasePart") then
				expect(d.CanQuery).toBe(false)
				if d.Name ~= "Trunk" then
					expect(d.CanCollide).toBe(false)
				end
			end
		end
	end)
end)

-- Caja (en planta) de una pieza: exacta si solo gira en Y; si no, su AABB
local function footprint(part: any): (number, number, number, number, number, number)
	local cf, s = part.CFrame, part.Size
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local hx = math.abs(r00) * s.X / 2 + math.abs(r01) * s.Y / 2 + math.abs(r02) * s.Z / 2
	local hy = math.abs(r10) * s.X / 2 + math.abs(r11) * s.Y / 2 + math.abs(r12) * s.Z / 2
	local hz = math.abs(r20) * s.X / 2 + math.abs(r21) * s.Y / 2 + math.abs(r22) * s.Z / 2
	return x, y, z, hx, hy, hz
end

T.describe("Torre del Nexo, estaciones y Gabinete", function()
	T.it("las siete estaciones existen, cada una con su prompt sobre su posición de juego", function()
		local sb = buildWorld()
		local folder = sb.workspace.ValleCopal.Stations
		local count = 0
		for id, st in pairs(World.Stations) do
			count += 1
			local model = folder:FindFirstChild(id)
			if not model then
				error("Falta la estación " .. id)
			end
			local prompt = nil
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("ProximityPrompt") and d.Name == "Station" then
					prompt = d
				end
			end
			if not prompt then
				error("Estación sin prompt: " .. id)
			end
			local booth = prompt.Parent
			expect(booth:GetAttribute("StationId")).toBe(id)
			expect(prompt.MaxActivationDistance).toBe(st.radius)
			expect(flat(st.position, booth.CFrame.X, booth.CFrame.Z) < 6).toBe(true)
			expect(model:GetAttribute("AssetStatus")).toBe("Blockout")
		end
		expect(count).toBe(7)
		-- Las que aún no abren avisan en el cliente en vez de quedar mudas
		local boot = fs.readFile("src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.luau")
		expect(string.find(boot, "se abrirá más adelante", 1, true) ~= nil).toBe(true)
	end)

	T.it("el Gran Nexo mide 90–120 studs y su corazón está etiquetado", function()
		local sb = buildWorld()
		local tree = sb.workspace.ValleCopal.GranNexo
		local top = 0
		for _, d in ipairs(tree:GetDescendants()) do
			if d:IsA("BasePart") then
				local _, y, _, _, hy = footprint(d)
				top = math.max(top, y + hy)
			end
		end
		expect(top >= 90 and top <= 120).toBe(true)
		local heart = tree:FindFirstChild("NexoHeart")
		expect(heart ~= nil).toBe(true)
		expect(heart:HasTag("AmbientHeart")).toBe(true)
		expect(heart:FindFirstChild("NexoMenu") ~= nil).toBe(true)
	end)

	T.it("el Gabinete que Camina está etiquetado, con seis patas y sin colisión", function()
		local sb = buildWorld()
		local gab = sb.workspace.ValleCopal:FindFirstChild("GabineteQueCamina")
		expect(gab ~= nil).toBe(true)
		expect(gab:HasTag("GabineteWalk")).toBe(true)
		local legs = 0
		for _, c in ipairs(gab:GetChildren()) do
			if string.match(c.Name, "^Leg%d$") then
				legs += 1
				expect(c:GetAttribute("Side") ~= nil).toBe(true)
			end
		end
		expect(legs).toBe(6)
		local drawers = 0
		for _, d in ipairs(gab:GetDescendants()) do
			if d:IsA("BasePart") then
				expect(d.CanCollide).toBe(false)
				expect(d.CanQuery).toBe(false)
				if d.Material == harness.sandbox.roblox.Enum.Material.WoodPlanks then
					drawers += 1
				end
			end
		end
		expect(drawers >= 20).toBe(true) -- cajones al frente y costillas a los lados
	end)

	T.it("la calzada del Gabinete queda libre: nada de la Torre se cruza en su ruta", function()
		local sb = buildWorld()
		local g = Landscape.Gabinete
		local cx, cz = World.GranNexo.position[1], World.GranNexo.position[3]
		local inner, outer = g.radius - g.halfSpan, g.radius + g.halfSpan
		local valle = sb.workspace.ValleCopal
		for _, folder in ipairs({ valle.Stations, valle.GranNexo, valle.Plaza }) do
			for _, d in ipairs(folder:GetDescendants()) do
				if d:IsA("BasePart") and not d:IsDescendantOf(valle.Stations.Basamento) then
					-- Muestras sobre el volumen de la pieza (5 × 5 × 5)
					local cf, size = d.CFrame, d.Size
					for a = -2, 2 do
						for b = -2, 2 do
							for c = -2, 2 do
								local p = cf
									* harness.sandbox.roblox.Vector3.new(a / 4 * size.X, b / 4 * size.Y, c / 4 * size.Z)
								local r = math.sqrt((p.X - cx) ^ 2 + (p.Z - cz) ^ 2)
								if r > inner and r < outer and p.Y > 2 and p.Y < 27 then
									error(
										string.format(
											"%s invade la calzada (r = %.1f, y = %.1f)",
											d:GetFullName(),
											r,
											p.Y
										)
									)
								end
							end
						end
					end
				end
			end
		end
		-- Los huevos quedan bajo el vientre del Gabinete (no los pisa)
		for _, egg in ipairs(valle.StarterEggs:GetChildren()) do
			if egg:IsA("BasePart") then
				local _, y, _, _, hy = footprint(egg)
				expect(y + hy < 8).toBe(true)
			end
		end
	end)

	T.it("nada bloquea el spawn ni la vista del spawn al corazón del Nexo", function()
		local sb = buildWorld()
		local sp = World.SpawnPoint
		local heart = sb.workspace.ValleCopal.GranNexo.NexoHeart.CFrame.Position
		local eye = { sp[1], sp[2] + 5, sp[3] }
		for k = 0, 40 do -- el terreno tampoco se interpone
			local t = k / 40
			local px, pz = eye[1] + (heart.X - eye[1]) * t, eye[3] + (heart.Z - eye[3]) * t
			expect(Landform.heightAt(px, pz) < eye[2] + (heart.Y - eye[2]) * t).toBe(true)
		end
		for _, d in ipairs(sb.workspace:GetDescendants()) do
			if d:IsA("BasePart") and d.ClassName ~= "Terrain" and d.CanCollide and d.Transparency < 1 then
				local x, y, z, hx, hy, hz = footprint(d)
				-- Cilindro libre de 6 studs alrededor del spawn (por encima del suelo)
				local qx, qz = math.max(math.abs(sp[1] - x) - hx, 0), math.max(math.abs(sp[3] - z) - hz, 0)
				if math.sqrt(qx * qx + qz * qz) < 6 and y + hy > 0.6 and y - hy < 10 then
					error("Bloquea el spawn: " .. d:GetFullName())
				end
			end
			if
				d:IsA("BasePart")
				and d.ClassName ~= "Terrain"
				and d.Transparency < 0.5
				and not d:IsDescendantOf(sb.workspace.ValleCopal.GranNexo)
			then
				-- La línea de mirada del spawn al corazón no atraviesa ninguna pieza opaca
				local x, y, z, hx, hy, hz = footprint(d)
				for k = 0, 40 do
					local t = k / 40
					local px = eye[1] + (heart.X - eye[1]) * t
					local py = eye[2] + (heart.Y - eye[2]) * t
					local pz = eye[3] + (heart.Z - eye[3]) * t
					if math.abs(px - x) < hx and math.abs(py - y) < hy and math.abs(pz - z) < hz then
						error("Tapa la vista del spawn al Gran Nexo: " .. d:GetFullName())
					end
				end
			end
		end
	end)
end)

T.describe("Lotes Hogar (LotsBuilder)", function()
	T.it("cada lote conserva sus piezas de juego: pedestales a 1,9, recolector, incubadora y letrero", function()
		local sb = buildWorld()
		for i, pos in ipairs(World.Lots.positions) do
			local lot = sb.workspace.ValleCopal.Lots:FindFirstChild("Lot" .. i)
			expect(lot ~= nil).toBe(true)
			expect(lot:GetAttribute("LotIndex")).toBe(i)
			expect(lot:FindFirstChild("Ground") ~= nil).toBe(true)
			for s, off in ipairs(World.Lots.slotOffsets) do
				local slot = lot.Habitat:FindFirstChild("Slot" .. s)
				expect(slot:FindFirstChild("SlotPrompt") ~= nil).toBe(true)
				local x, y, z, _, hy = footprint(slot)
				expect(y + hy).toBeNear(1.9, 1e-3) -- ahí se paran los monstruos del hábitat
				expect(flat(pos, x - off[1], z - off[3]) < 1e-3).toBe(true)
			end
			local collector = lot:FindFirstChild("Collector")
			expect(collector:FindFirstChild("CollectPrompt") ~= nil).toBe(true)
			expect(lot:FindFirstChild("IncubatorRing") ~= nil).toBe(true)
			expect(lot:FindFirstChild("Incubator") ~= nil).toBe(true)
			expect(lot.Sign:FindFirstChild("OwnerLabel") ~= nil).toBe(true)
		end
	end)
end)

T.describe("Paisaje de Valle Copal (Landform)", function()
	T.it("el río, el lago y la cascada son agua de terreno", function()
		local sb = buildWorld()
		local water = 0
		for _, call in ipairs(sb.terrainCalls) do
			local mat = call.args[#call.args]
			if call.method ~= "SetMaterialColor" and mat.Name == "Water" then
				water += 1
			end
		end
		expect(water > 20).toBe(true)
		-- Bajo cada puente y en la poza hay agua (distancia con signo negativa)
		for _, b in ipairs(World.Bridges) do
			expect(Landform.waterDistance(b[1], b[3]) < -4).toBe(true)
		end
		local pool = Landscape.Waterfall.pool.center
		expect(Landform.waterDistance(pool[1], pool[2]) < 0).toBe(true)
		-- La cascada cae desde el saliente de roca hasta el nivel del río
		local fall = Landscape.Waterfall.fall
		expect(fall.center[2] + fall.size[2] / 2 > 15).toBe(true)
		expect(fall.center[2] - fall.size[2] / 2 <= Landscape.River.waterLevel).toBe(true)
	end)

	T.it("el río serpentea (no es un canal recto)", function()
		local zs = {}
		for _, s in ipairs(Landform.riverSamples()) do
			table.insert(zs, s.z)
		end
		local turns, lastSign = 0, 0
		for i = 2, #zs do
			local d = zs[i] - zs[i - 1]
			local sign = if d > 0.05 then 1 elseif d < -0.05 then -1 else 0
			if sign ~= 0 and sign ~= lastSign then
				turns += 1
				lastSign = sign
			end
		end
		expect(turns >= 8).toBe(true)
	end)

	T.it("las zonas de juego quedan planas (Y = 0) y secas", function()
		local function check(x: number, z: number, what: string)
			if math.abs(Landform.heightAt(x, z)) > 1e-6 then
				error(string.format("%s no está a ras de suelo (%.1f, %.1f)", what, x, z))
			end
		end
		check(World.SpawnPoint[1], World.SpawnPoint[3], "spawn")
		for a = 0, 7 do
			local r = World.Plaza.radius
			check(World.Plaza.center[1] + math.cos(a) * r, World.Plaza.center[3] + math.sin(a) * r, "plaza")
		end
		for id, st in pairs(World.Stations) do
			check(st.position[1], st.position[3], id)
		end
		for i, lot in ipairs(World.Lots.positions) do
			for _, c in ipairs({ { -22, -22 }, { 22, -22 }, { -22, 22 }, { 22, 22 } }) do
				check(lot[1] + c[1], lot[3] + c[2], "lote " .. i)
			end
		end
		for id, e in pairs(World.Encounters) do
			for a = 0, 5 do
				check(e.position[1] + math.cos(a) * e.radius, e.position[3] + math.sin(a) * e.radius, id)
			end
			expect(Landform.waterDistance(e.position[1], e.position[3]) > e.radius).toBe(true)
		end
		for _, stall in ipairs(Landscape.Market.stalls) do
			check(stall.position[1], stall.position[3], stall.kind)
		end
		expect(Landform.waterDistance(World.SpawnPoint[1], World.SpawnPoint[3]) > 8).toBe(true)
	end)

	T.it("los lotes y la plaza quedan fuera del agua", function()
		for _, lot in ipairs(World.Lots.positions) do
			expect(Landform.waterDistance(lot[1], lot[3] - World.Lots.size[2] / 2) > 0).toBe(true)
		end
		expect(Landform.waterDistance(0, World.Plaza.center[3] + World.Plaza.radius) > 2).toBe(true)
	end)
end)

T.describe("Flora de Valle Copal (FloraLayout)", function()
	T.it("las flores son deterministas y salen todas las matas configuradas", function()
		local a, b = FloraLayout.clusters(), FloraLayout.clusters()
		expect(#a).toBe(Ambience.Flowers.clusters)
		expect(a).toEqual(b)
	end)
	T.it("ninguna mata cae en plaza, lotes, río, caminos ni zonas de interacción", function()
		for _, c in ipairs(FloraLayout.clusters()) do
			expect(FloraLayout.isClear(c.x, c.z)).toBe(true)
		end
		expect(FloraLayout.isClear(0, 8)).toBe(false) -- plaza
		expect(FloraLayout.isClear(0, 112)).toBe(false) -- lote 3
		expect(FloraLayout.isClear(0, 66)).toBe(false) -- río
		expect(FloraLayout.isClear(-78, 10)).toBe(false) -- primer Opaco
		expect(FloraLayout.isClear(84, 18)).toBe(false) -- calle del mercado
	end)
	T.it("hay variedad de especies y ningún árbol idéntico a otro", function()
		local props = FloraLayout.props()
		local kinds, seen = {}, {}
		for _, p in ipairs(props) do
			kinds[p.kind] = true
			if FloraLayout.isTree(p.kind) then
				local key = string.format("%s|%.3f|%.3f", p.kind, p.scale, p.yaw)
				expect(seen[key] == nil).toBe(true)
				seen[key] = true
			end
		end
		for _, k in ipairs({ "Ahuejote", "Copal", "Sabino", "Colorin", "Bush", "Agave" }) do
			if not kinds[k] then
				error("Falta la especie " .. k)
			end
		end
		expect(props).toEqual(FloraLayout.props())
	end)
	T.it("los árboles se apoyan en el terreno y no invaden el agua ni las zonas de juego", function()
		for _, p in ipairs(FloraLayout.props()) do
			if math.abs(p.y - Landform.heightAt(p.x, p.z)) > 1e-6 and p.y ~= Landscape.Lagoon.islandTop then
				error(string.format("%s flota en (%.1f, %.1f)", p.kind, p.x, p.z))
			end
			expect(flat(World.SpawnPoint, p.x, p.z) > 14).toBe(true)
			expect(flat(World.GranNexo.position, p.x, p.z) > 50).toBe(true)
		end
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
