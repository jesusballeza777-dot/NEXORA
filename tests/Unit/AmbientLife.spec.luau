--!strict
-- Vida ambiental del cliente (Bloque J): funciones de paso puras (AmbientMotion) y el
-- controlador aplicado al mundo real construido por ValleBuilder en el sandbox.
local T = harness.T
local expect = T.expect
local Landscape = harness.get("ReplicatedStorage.Shared.Config.Landscape")
local World = harness.get("ReplicatedStorage.Shared.Config.World")
local AmbientMotion = harness.get("StarterPlayerScripts.Client.Controllers.AmbientMotion")

local G = Landscape.Gabinete
local DOCK = math.rad(150)

T.describe("Vida ambiental · funciones de paso (AmbientMotion)", function()
	T.it("el LOD apaga lo lejano y baja la frecuencia a media distancia", function()
		local lod = { near = 60, far = 140 }
		expect(AmbientMotion.lodTier(10, lod)).toBe("full")
		expect(AmbientMotion.lodTier(100, lod)).toBe("half")
		expect(AmbientMotion.lodTier(141, lod)).toBe("off")
	end)

	T.it("el reparto respeta el presupuesto, alterna la media frecuencia y nunca anima lo apagado", function()
		local agents = {
			{ tier = "full", cost = 100 },
			{ tier = "half", cost = 50 },
			{ tier = "off", cost = 10 },
			{ tier = "full", cost = 300 },
			{ tier = "half", cost = 80 },
		}
		local halfTurns = { 0, 0 }
		for frame = 1, 40 do
			local picked = AmbientMotion.schedule(agents, frame, 400)
			local spent = 0
			for _, i in ipairs(picked) do
				expect(agents[i].tier ~= "off").toBe(true)
				spent += agents[i].cost
				if i == 2 then
					halfTurns[1] += 1
				elseif i == 5 then
					halfTurns[2] += 1
				end
			end
			expect(spent <= 400).toBe(true)
		end
		expect(halfTurns[1] > 0 and halfTurns[1] <= 20).toBe(true)
		expect(halfTurns[2] > 0 and halfTurns[2] <= 20).toBe(true)
		-- Un agente que solo supera el presupuesto pasa igualmente (no se congela)
		expect(#AmbientMotion.schedule({ { tier = "full", cost = 999 } }, 1, 100)).toBe(1)
		expect(#AmbientMotion.schedule({}, 1, 100)).toBe(0)
	end)

	T.it("el Gabinete descansa frente a su despensa, da una vuelta completa y vuelve", function()
		local cycle, walkTime = AmbientMotion.gabineteCycle(G)
		local rest = AmbientMotion.gabinete(G.rest / 2, G, DOCK)
		expect(rest.walking).toBe(false)
		expect(rest.x).toBeNear(math.cos(DOCK) * G.radius, 1e-6)
		expect(rest.lookX).toBeNear(math.cos(DOCK), 1e-6) -- mira hacia fuera, a su despensa
		local prev = nil
		local maxSpeed = 0
		for k = 0, 400 do
			local t = G.rest + walkTime * k / 400
			local p = AmbientMotion.gabinete(t, G, DOCK)
			expect(math.sqrt(p.x * p.x + p.z * p.z)).toBeNear(G.radius, 1e-6) -- siempre en la ruta
			expect(p.lookX * p.x + p.lookZ * p.z).toBeNear(0, 1e-6) -- mira por la tangente
			if prev then
				local dt = walkTime / 400
				maxSpeed = math.max(maxSpeed, math.sqrt((p.x - prev.x) ^ 2 + (p.z - prev.z) ^ 2) / dt)
			end
			prev = p
		end
		expect(maxSpeed <= G.speed * 1.02).toBe(true) -- despacio
		local back = AmbientMotion.gabinete(cycle - 0.001, G, DOCK)
		expect(back.x).toBeNear(math.cos(DOCK) * G.radius, 1e-3)
		local a, b = AmbientMotion.gabinete(37.5, G, DOCK), AmbientMotion.gabinete(37.5 + cycle, G, DOCK)
		expect(a.x).toBeNear(b.x, 1e-6)
		expect(a.z).toBeNear(b.z, 1e-6)
	end)

	T.it("las patas caminan en trípode alterno y se quedan quietas al descansar", function()
		for k = 0, 20 do
			local phase = k / 20
			local s0, l0 = AmbientMotion.leg(phase, 0, true)
			local s1, l1 = AmbientMotion.leg(phase, 1, true)
			expect(s0).toBeNear(-s1, 1e-9)
			expect(l0 == 0 or l1 == 0).toBe(true) -- un trípode siempre apoya
			expect(math.abs(s0) <= 0.32 + 1e-9).toBe(true)
		end
		local s, l = AmbientMotion.leg(0.3, 0, false)
		expect(s).toBe(0)
		expect(l).toBe(0)
	end)

	T.it("el corazón late con dos golpes por ciclo y escala acotada", function()
		local cfg = Landscape.Life.heart
		local period = 60 / cfg.bpm
		local peaks, last, rising = 0, 0, false
		for k = 0, 200 do
			local scale, glow = AmbientMotion.heart(period * k / 200, cfg)
			expect(scale >= 1 and scale <= 1 + cfg.scale + 1e-9).toBe(true)
			expect(glow >= 0.55 - 1e-9 and glow <= 1 + 1e-9).toBe(true)
			if scale < last and rising then
				peaks += 1
			end
			rising = scale > last
			last = scale
		end
		expect(peaks >= 2).toBe(true)
	end)

	T.it("faroles y banderas oscilan dentro de su amplitud; las canoas apenas se mecen", function()
		local cfg = Landscape.Life.sway.lantern
		for k = 0, 100 do
			local p, r = AmbientMotion.sway(k * 0.37, 1.3, cfg)
			expect(math.abs(p) <= cfg.amplitude + 1e-9).toBe(true)
			expect(math.abs(r) <= cfg.amplitude + 1e-9).toBe(true)
			local dy, roll = AmbientMotion.bob(k * 0.37, 2)
			expect(math.abs(dy) <= 0.12 + 1e-9 and math.abs(roll) <= 0.05 + 1e-9).toBe(true)
		end
	end)

	T.it("los peces saltan de vez en cuando y caen al agua", function()
		local cfg = Landscape.Life.fish[1]
		local visible = 0
		for k = 0, 999 do
			local p = AmbientMotion.fish(k * cfg.period / 1000, cfg)
			if p.visible then
				visible += 1
				expect(p.y > -0.5 and p.y < 2.3).toBe(true)
			end
		end
		expect(visible > 0 and visible < 200).toBe(true)
	end)

	T.it("aves y mariposas se quedan cerca de su centro", function()
		for _, f in ipairs(Landscape.Life.flocks) do
			for i = 1, f.count do
				local b = AmbientMotion.bird(12.3 + i, i, f)
				expect(math.sqrt(b.x * b.x + b.z * b.z) <= f.radius + 1e-6).toBe(true)
				expect(math.abs(b.y) <= 5 + 1e-9).toBe(true)
			end
		end
		for _, g in ipairs(Landscape.Life.butterflies) do
			local m = AmbientMotion.butterfly(4.2, 1, g)
			expect(math.abs(m.x) <= g.radius + 1e-9 and math.abs(m.z) <= g.radius + 1e-9).toBe(true)
			expect(m.y > 0.5).toBe(true)
		end
	end)
end)

T.describe("Vida ambiental · controlador sobre el valle construido", function()
	local function setup()
		local sb = harness.sandbox.new()
		sb.load("ServerScriptService.Server.World.ValleBuilder").build()
		local Life = sb.load("StarterPlayerScripts.Client.Controllers.AmbientLifeController")
		local counts: { [string]: number } = {}
		for _, d in ipairs(sb.workspace:GetDescendants()) do
			for _, tag in ipairs(Life.Tags) do
				if d:HasTag(tag) then
					Life.track(d, tag)
					counts[tag] = (counts[tag] or 0) + 1
				end
			end
		end
		return sb, Life, counts
	end

	T.it("el servidor etiqueta todo lo que anima el cliente", function()
		local _, Life, counts = setup()
		expect(counts.GabineteWalk).toBe(1)
		expect(counts.AmbientHeart).toBe(1)
		expect((counts.AmbientSway or 0) >= 10).toBe(true)
		expect(counts.AmbientBirds).toBe(#Landscape.Life.flocks)
		expect(counts.AmbientFish).toBe(#Landscape.Life.fish)
		expect(counts.AmbientButterflies).toBe(#Landscape.Life.butterflies)
		expect(Life.count() >= 20).toBe(true)
	end)

	T.it("anima cerca, respeta el presupuesto por fotograma y no anima nada lejos", function()
		local sb, Life = setup()
		local V = harness.sandbox.roblox.Vector3
		local cam = V.new(0, 12, 20)
		local maxMoved = 0
		for f = 0, 30 do
			maxMoved = math.max(maxMoved, Life.step(100 + f / 60, cam))
		end
		expect(maxMoved > 0).toBe(true)
		-- el agente más caro (el Gabinete) puede pasar solo; si no, el tope es el presupuesto
		expect(maxMoved <= math.max(Landscape.Life.budget.partsPerFrame, 140)).toBe(true)
		local far = V.new(2000, 50, 2000)
		Life.step(200, far)
		expect(Life.step(200.02, far)).toBe(0)
		local _ = sb
	end)

	T.it("el Gabinete sale de su despensa, camina alrededor del árbol y el corazón late", function()
		local sb, Life = setup()
		local V = harness.sandbox.roblox.Vector3
		local gab = sb.workspace.ValleCopal.GabineteQueCamina
		local core = gab.Body.Core
		local start = core.CFrame.Position
		local cam = V.new(-20, 12, -10)
		local _, walkTime = AmbientMotion.gabineteCycle(G)
		local t = G.rest + walkTime * 0.25 -- un cuarto de vuelta
		Life.step(t, cam)
		Life.step(t + 1 / 60, cam)
		local now = core.CFrame.Position
		expect((now - start).Magnitude > 10).toBe(true)
		local tree = World.GranNexo.position
		local r = math.sqrt((now.X - tree[1]) ^ 2 + (now.Z - tree[3]) ^ 2)
		expect(r).toBeNear(G.radius, 0.5)
		local heart = sb.workspace.ValleCopal.GranNexo.NexoHeart
		local base = heart:GetAttribute("BaseSize")
		Life.step(0, cam)
		Life.step(0.01, cam)
		expect(heart.Size.Y > base.Y).toBe(true)
	end)
end)
