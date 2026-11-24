--!strict
-- Aura de rareza con clases reales de @lune/roblox: monta criaturas, aplica auras de cada
-- rareza y elemento y comprueba presupuesto, tasa, 60 % en combate, 80 %/50 % en el Brote,
-- cara limpia, reutilización del pool y limpieza al destruir. No valida el aspecto: eso es
-- de Studio (texturas del motor, color real, legibilidad).
local T = harness.T
local expect = T.expect
local VFX = harness.get("ReplicatedStorage.Shared.Config.VFX")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Rarities = harness.get("ReplicatedStorage.Shared.Config.Rarities")

local roblox = harness.sandbox.roblox

local function setup()
	local sb = harness.sandbox.newClient({})
	local CreatureBuilder = sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder")
	local AuraController = sb.load("StarterPlayerScripts.Client.VFX.AuraController")
	local VFXPool = sb.load("StarterPlayerScripts.Client.VFX.VFXPool")
	local CreatureRig = sb.load("StarterPlayerScripts.Client.Creatures.CreatureRig")
	local folder = roblox.Instance.new("Folder")
	return {
		build = function(id: string, form: string, opaco: boolean?)
			return CreatureBuilder.build(id, form, { parent = folder, opaco = opaco })
		end,
		CreatureBuilder = CreatureBuilder,
		Aura = AuraController,
		Pool = VFXPool,
		Rig = CreatureRig,
		folder = folder,
	}
end

local function emittersIn(model: any): { any }
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			table.insert(list, d)
		end
	end
	return list
end

local function firstSize(e: any): number
	return e.Size.Keypoints[1].Value
end

T.describe("Aura · presupuesto por rareza y elemento (clases reales)", function()
	T.it("cada rareza × elemento respeta su presupuesto y la tasa ≤ 20/s", function()
		local env = setup()
		local pool = env.Pool.new()
		local checked = 0
		for _, rarity in ipairs(Rarities.Order) do
			for _, element in ipairs(Elements.Order) do
				for _, form in ipairs({ "Brote", "Tallado" }) do
					for _, quality in ipairs(VFX.QualityOrder) do
						local c = env.build("kuachi", form)
						local aura =
							env.Aura.attach(c, { pool = pool, rarity = rarity, element = element, quality = quality })
						aura:setAttacking(true) -- el caso con más emisores (Raro solo emite al atacar)
						local emitters = emittersIn(c.model)
						local max = VFX.Rarities[rarity].emitters[quality]
						if form == "Brote" then
							max = math.min(max, VFX.Budget.broteMaxEmitters)
						end
						if #emitters ~= max then
							error(string.format("%s %s %s %s: %d emisores", rarity, element, form, quality, #emitters))
						end
						for _, e in ipairs(emitters) do
							if e.Rate > VFX.Budget.maxRatePerEmitter then
								error("Tasa " .. e.Rate .. " en " .. e.Name)
							end
						end
						expect(aura:emitterCount()).toBe(#emitters)
						c:destroy()
						checked += 1
					end
				end
			end
		end
		expect(checked).toBe(#Rarities.Order * 12 * 2 * 3)
		-- Todo volvió al pool
		expect(pool:stats().active).toBe(0)
	end)

	T.it("Común: 0 emisores; Raro: 1 solo al atacar y luz de contorno al atacar", function()
		local env = setup()
		local pool = env.Pool.new()
		local comun = env.build("kuachi", "Tallado")
		env.Aura.attach(comun, { pool = pool, quality = "High" }):setAttacking(true)
		expect(#emittersIn(comun.model)).toBe(0)
		expect(comun.model:FindFirstChildOfClass("Highlight") == nil).toBe(true)
		local raro = env.build("lumbro", "Tallado") -- Lumbro es Raro
		local aura = env.Aura.attach(raro, { pool = pool, quality = "High" })
		expect(#emittersIn(raro.model)).toBe(0)
		aura:setAttacking(true)
		expect(#emittersIn(raro.model)).toBe(1)
		local rim = raro.model:FindFirstChildOfClass("Highlight")
		expect(rim ~= nil and rim.Enabled).toBe(true)
		aura:setAttacking(false)
		expect(#emittersIn(raro.model)).toBe(0)
		expect(raro.model:FindFirstChildOfClass("Highlight") == nil).toBe(true)
	end)

	T.it("Legendario: haz; Único: halo; Épico: emisivo animado", function()
		local env = setup()
		local pool = env.Pool.new()
		local leg = env.build("kuachi", "Tallado")
		env.Aura.attach(leg, { pool = pool, rarity = "Legendario", quality = "High" })
		local beams = 0
		for _, d in ipairs(leg.model:GetDescendants()) do
			if d:IsA("Beam") then
				beams += 1
			end
		end
		expect(beams).toBe(1)
		local uni = env.build("xolumi", "Tallado")
		env.Aura.attach(uni, { pool = pool, rarity = "Unico", quality = "High" })
		local ring = 0
		for _, d in ipairs(uni.model:GetDescendants()) do
			if d:IsA("Beam") then
				ring += 1
			end
		end
		expect(ring).toBe(2) -- el anillo son dos semicircunferencias
		local epic = env.build("kuachi", "Tallado")
		local aura = env.Aura.attach(epic, { pool = pool, rarity = "Epico", quality = "High" })
		local glow = nil
		for _, rec in ipairs(epic.parts) do
			if rec.kind == "Glow" then
				glow = rec
			end
		end
		aura:update(0.5)
		expect(glow ~= nil).toBe(true)
		local g = glow :: any
		expect(g.part.Color ~= g.baseColor).toBe(true)
	end)
end)

T.describe("Aura · combate 60 %, Brote 80 %/50 %, opacado y distancia", function()
	T.it("en combate la tasa baja al 60 % y el número de emisores no cambia", function()
		local env = setup()
		local pool = env.Pool.new()
		local world = env.build("kuachi", "Tallado")
		env.Aura.attach(world, { pool = pool, rarity = "Legendario", quality = "High" })
		local battle = env.build("kuachi", "Tallado")
		env.Aura.attach(battle, { pool = pool, rarity = "Legendario", quality = "High", battle = true })
		local a, b = emittersIn(world.model), emittersIn(battle.model)
		expect(#a).toBe(#b)
		local byName = {}
		for _, e in ipairs(a) do
			byName[e.Name] = e
		end
		for _, e in ipairs(b) do
			local w = byName[e.Name]
			if w.Rate > 0 then
				expect(e.Rate).toBeNear(w.Rate * 0.6, 1e-4)
			end
			expect(e.LightEmission).toBeNear(w.LightEmission * 0.6, 1e-4)
		end
	end)

	T.it("el Brote lleva el aura al 80 % de tamaño y con la mitad de partículas", function()
		local env = setup()
		local pool = env.Pool.new()
		local brote = env.build("kuachi", "Brote")
		env.Aura.attach(brote, { pool = pool, rarity = "Legendario", quality = "High" })
		local tallado = env.build("kuachi", "Tallado")
		env.Aura.attach(tallado, { pool = pool, rarity = "Legendario", quality = "High" })
		local eb, et = emittersIn(brote.model)[1], nil
		for _, e in ipairs(emittersIn(tallado.model)) do
			if e.Name == eb.Name then
				et = e
			end
		end
		expect(et ~= nil).toBe(true)
		local style = VFX.Styles[eb.Name]
		-- Tamaño = estilo × 80 % × escala de la forma (el Tallado mide ×1,55)
		expect(firstSize(eb)).toBeNear(style.size[1][2] * 0.8 * brote.scale, 1e-4)
		expect(firstSize(et :: any)).toBeNear(style.size[1][2] * tallado.scale, 1e-4)
		expect(eb.Rate).toBeNear((et :: any).Rate * 0.5, 1e-4)
	end)

	T.it("opacado: sin aura; al restaurarse vuelve", function()
		local env = setup()
		local pool = env.Pool.new()
		local c = env.build("kuachi", "Tallado", true)
		local aura = env.Aura.attach(c, { pool = pool, rarity = "Epico", quality = "High" })
		expect(#emittersIn(c.model)).toBe(0)
		env.CreatureBuilder.setOpaco(c, 0)
		aura:update(0.016)
		expect(#emittersIn(c.model)).toBe(2)
	end)

	T.it("a más de 60 studs no hay partículas; al volver, sí (sin parpadeo)", function()
		local env = setup()
		local pool = env.Pool.new()
		local c = env.build("kuachi", "Tallado")
		local aura = env.Aura.attach(c, { pool = pool, rarity = "Legendario", quality = "High" })
		aura:update(0.016, 30)
		expect(#emittersIn(c.model)).toBe(3)
		aura:update(0.016, 100)
		expect(#emittersIn(c.model)).toBe(0)
		aura:update(0.016, 200)
		expect(aura.lod).toBe("None")
		aura:update(0.016, 58) -- dentro de la histéresis: sigue reducido
		expect(#emittersIn(c.model)).toBe(0)
		aura:update(0.016, 40)
		expect(#emittersIn(c.model)).toBe(3)
	end)
end)

T.describe("Aura · la cara nunca queda tapada", function()
	T.it("los puntos de emisión están detrás de la cara o en la órbita exterior fuera del frente", function()
		local env = setup()
		local pool = env.Pool.new()
		for _, id in ipairs({ "kuachi", "xolumi", "teselo", "zunzi", "copalia" }) do
			for _, form in ipairs({ "Brote", "Tallado" }) do
				for _, element in ipairs(Elements.Order) do
					local c = env.build(id, form)
					local aura =
						env.Aura.attach(c, { pool = pool, rarity = "Legendario", element = element, quality = "High" })
					local rig = env.Rig.get(c)
					local a = rig.anchors
					for _ = 1, 40 do
						aura:update(0.05)
						for _, slot in ipairs(aura.slots) do
							local p = slot.pos
							local o = slot.style.orbit
							if o and (o.plane or "Horizontal") == "Horizontal" then
								local flat = roblox.Vector3.new(p.X - a.center.X, 0, p.Z - a.center.Z)
								expect(flat.Magnitude >= VFX.Budget.faceClearance * a.bodyRadius - 1e-3).toBe(true)
								-- Si pasa por delante, no emite
								if flat.Unit.Z > math.cos(math.rad(60)) + 1e-6 then
									expect(slot.free).toBe(false)
									if not slot.style.tick then
										expect(slot.emitter.Enabled).toBe(false)
									end
								end
							elseif not (o and o.plane == "Ground") then
								if p.Z > a.faceZ - 0.3 then
									error(
										string.format(
											"%s %s %s: emisor delante (z=%.2f, cara=%.2f)",
											id,
											form,
											element,
											p.Z,
											a.faceZ
										)
									)
								end
							end
						end
					end
					c:destroy()
				end
			end
		end
	end)
end)

T.describe("Aura · pool y limpieza", function()
	T.it("el pool reutiliza instancias en vez de crear nuevas", function()
		local env = setup()
		local pool = env.Pool.new()
		local c1 = env.build("kuachi", "Tallado")
		env.Aura.attach(c1, { pool = pool, rarity = "Legendario", quality = "High" })
		local created = pool:stats().created
		c1:destroy()
		for _ = 1, 10 do
			local c = env.build("kuachi", "Tallado")
			local aura = env.Aura.attach(c, { pool = pool, rarity = "Legendario", quality = "High" })
			aura:setBattle(true)
			aura:setBattle(false)
			c:destroy()
		end
		local s = pool:stats()
		expect(s.created).toBe(created)
		expect(s.reused > 0).toBe(true)
		expect(s.active).toBe(0)
		expect(s.lost).toBe(0)
	end)

	T.it("al destruir la criatura todo vuelve al pool y el aura sale del registro", function()
		local env = setup()
		local pool = env.Pool.new()
		local before = env.Aura.count()
		local c = env.build("teselo", "Tallado")
		local aura = env.Aura.attach(c, { pool = pool, rarity = "Unico", quality = "High" })
		expect(pool:ownedBy(aura) > 0).toBe(true)
		expect(env.Aura.count()).toBe(before + 1)
		c:destroy()
		expect(pool:ownedBy(aura)).toBe(0)
		expect(env.Aura.count()).toBe(before)
		expect(aura.destroyed).toBe(true)
		-- Las instancias guardadas no cuelgan de ningún sitio
		for _, list in pairs(pool.free) do
			for _, inst in ipairs(list) do
				expect(inst.Parent == nil).toBe(true)
			end
		end
	end)

	T.it("sustituye el emisor provisional del constructor y respeta los límites del pool", function()
		local env = setup()
		local c = env.build("lumbro", "Tallado")
		expect(c.aura ~= nil).toBe(true) -- el blockout trae su emisor provisional
		local pool = env.Pool.new({ ParticleEmitter = 1 })
		local aura = env.Aura.attach(c, { pool = pool, rarity = "Legendario", quality = "High" })
		expect(c.aura == nil).toBe(true)
		-- Con un solo emisor disponible, el aura se queda en uno y no falla
		expect(aura:emitterCount()).toBe(1)
		expect(#emittersIn(c.model)).toBe(1)
	end)
end)
