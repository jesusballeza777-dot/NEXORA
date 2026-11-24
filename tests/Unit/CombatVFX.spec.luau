--!strict
-- Combate visual y evolución con clases reales y reloj falso: fases y duraciones de las
-- secuencias, salto, los doce elementos, la biblioteca de impactos, la cámara (sacudida
-- ≤ 0,3; movimiento reducido) y la ceremonia del Tallado. Sin render: el aspecto es de Studio.
local T = harness.T
local expect = T.expect
local VFX = harness.get("ReplicatedStorage.Shared.Config.VFX")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Abilities = harness.get("ReplicatedStorage.Shared.Config.Abilities")
local roblox = harness.sandbox.roblox

local DT = 1 / 60

local function setup()
	local sb = harness.sandbox.newClient({})
	local env = {
		Builder = sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder"),
		Animator = sb.load("StarterPlayerScripts.Client.Animation.CreatureAnimator"),
		Aura = sb.load("StarterPlayerScripts.Client.VFX.AuraController"),
		Combat = sb.load("StarterPlayerScripts.Client.VFX.CombatVFXController"),
		Impact = sb.load("StarterPlayerScripts.Client.VFX.ImpactVFXController"),
		Elemental = sb.load("StarterPlayerScripts.Client.VFX.ElementalVFXController"),
		Camera = sb.load("StarterPlayerScripts.Client.VFX.CameraDirector"),
		Context = sb.load("StarterPlayerScripts.Client.VFX.VFXContext"),
		Plan = sb.load("StarterPlayerScripts.Client.VFX.VFXPlan"),
		Evolution = sb.load("StarterPlayerScripts.Client.VFX.EvolutionVFXController"),
		Settings = sb.load("StarterPlayerScripts.Client.VFX.VFXSettings"),
		folder = roblox.Instance.new("Folder"),
	}
	env.Context.setRoot(env.folder)
	env.Settings.set("quality", "High") -- el caso con más efectos (luces, beams, trails)
	env.rt = env.Context.runtime()
	env.pool = env.Context.pool()
	return env
end

local function side(env: any, id: string, form: string, uid: string, x: number): any
	local c = env.Builder.build(id, form, { parent = env.folder })
	env.Builder.pose(
		c,
		roblox.CFrame.new(x, 0, 0) * roblox.CFrame.Angles(0, if x < 0 then math.pi / 2 else -math.pi / 2, 0)
	)
	return { creature = c, anim = env.Animator.new(c), uid = uid }
end

local function settle(env: any, seconds: number)
	local t = 0
	while t < seconds do
		env.rt:step(DT)
		t += DT
	end
end

local function runSeq(env: any, move: any, events: { any }?, camera: any?): (any, { any }, number, number)
	local a = side(env, "kuachi", "Brote", "S1A", -4)
	local b = side(env, "xolumi", "Brote", "S2A", 4)
	local phases = {}
	local impacts = 0
	local seq = env.Combat.play({
		move = move,
		attacker = a,
		target = b,
		events = events or { { t = "Damage", target = "S2A", amount = 10 } },
		camera = camera,
		runtime = env.rt,
		pool = env.pool,
		onPhase = function(p, t)
			table.insert(phases, { p, t })
		end,
		onImpact = function()
			impacts += 1
		end,
	})
	local clock = 0
	while not seq.done and clock < 6 do
		env.rt:step(DT)
		clock += DT
	end
	return seq, phases, impacts, clock
end

T.describe("Secuencias de ataque (reloj falso)", function()
	T.it("básico: seis fases en orden, a su hora, y ≤ 1,6 s (+ pausa de impacto)", function()
		local env = setup()
		local move = Abilities.ById.Chispazo
		local seq, phases, impacts, clock = runSeq(env, move)
		local tl = env.Plan.timeline("Basic")
		expect(seq.done).toBe(true)
		expect(impacts).toBe(1)
		local order = {}
		for _, p in ipairs(phases) do
			table.insert(order, p[1])
		end
		expect(table.concat(order, ">")).toBe(table.concat(VFX.PhaseOrder, ">") .. ">Done")
		for i, slot in ipairs(tl.phases) do
			expect(math.abs(phases[i][2] - slot.start) <= DT + 1e-6).toBe(true)
		end
		expect(tl.total <= 1.6).toBe(true)
		local hitStop = VFX.Impacts.Elemental.hitStop
		expect(clock <= tl.total + hitStop + 3 * DT).toBe(true)
		-- Cuando se apagan las últimas partículas, todo ha vuelto al pool
		settle(env, 3) -- el humo del Fuego vive 2,2 s (a ras de suelo)
		expect(env.pool:stats().active).toBe(0)
		expect(env.rt:count()).toBe(0)
	end)

	T.it("Golpe Nexo: ≤ 3,5 s, con luz y cámara; se puede saltar y deja todo limpio", function()
		local env = setup()
		local cam = roblox.Instance.new("Camera")
		local director = env.Camera.new(cam, { reducedMotion = false })
		director:setBase(roblox.Vector3.new(0, 7, 14), roblox.Vector3.new(0, 1.6, 0))
		local tl = env.Plan.timeline("Nexo")
		expect(tl.total <= 3.5).toBe(true)
		local a = side(env, "kuachi", "Tallado", "S1A", -4)
		local b = side(env, "teselo", "Tallado", "S2A", 4)
		local impacts = 0
		local seq = env.Combat.play({
			move = Abilities.ById.DiluvioDeCantaros,
			attacker = a,
			target = b,
			events = { { t = "Damage", target = "S2A", amount = 40 } },
			camera = director,
			runtime = env.rt,
			pool = env.pool,
			onImpact = function()
				impacts += 1
			end,
		})
		settle(env, 0.5)
		expect(seq.phase).toBe("Anticipation")
		-- La escena se oscurece durante el Golpe Nexo (ColorCorrection en Lighting)
		expect(seq.dimmed).toBe(true)
		seq.skip()
		expect(seq.done).toBe(true)
		expect(impacts).toBe(1) -- el impacto sale una vez aunque se salte
		expect(seq.dimmed).toBe(false)
		expect(env.pool:ownedBy(seq)).toBe(0)
		seq.skip() -- dos veces no rompe nada
		expect(impacts).toBe(1)
	end)

	T.it("curación y escudo van sobre el propio atacante y sin embestida", function()
		local env = setup()
		local seq = runSeq(env, Abilities.ById.Manantial, { { t = "Heal", target = "S1A", amount = 12 } })
		expect(seq.kind).toBe("Heal")
		expect(seq.lungeMax).toBe(0)
		local shield = runSeq(env, Abilities.ById.EscudoRepujado, { { t = "Shield", target = "S1A", amount = 20 } })
		expect(shield.kind).toBe("Shield")
	end)

	T.it("los doce elementos reproducen lanzamiento, viaje e impacto y lo devuelven todo", function()
		local env = setup()
		for _, el in ipairs(Elements.Order) do
			for _, kind in ipairs({ "Basic", "Special", "Nexo" }) do
				local move = { id = "T_" .. el, element = el, kind = kind, power = 40, effects = {} }
				local seq = runSeq(env, move)
				expect(seq.done).toBe(true)
			end
		end
		expect(env.pool:stats().created > 0).toBe(true)
		settle(env, 2)
		expect(env.pool:stats().active).toBe(0)
		-- Ninguna tasa por encima de 20 en lo que se creó
		for _, list in pairs(env.pool.free) do
			for _, inst in ipairs(list) do
				if inst:IsA("ParticleEmitter") then
					expect(inst.Rate <= VFX.Budget.maxRatePerEmitter).toBe(true)
				end
			end
		end
	end)

	T.it("el aura de un Raro se enciende al atacar y se apaga al terminar", function()
		local env = setup()
		local a = side(env, "lumbro", "Tallado", "S1A", -4)
		a.aura = env.Aura.attach(a.creature, { battle = true, quality = "High" })
		local b = side(env, "xolumi", "Brote", "S2A", 4)
		local seq = env.Combat.play({
			move = Abilities.ById.RayoDeAlba,
			attacker = a,
			target = b,
			events = {},
			runtime = env.rt,
			pool = env.pool,
		})
		settle(env, 0.2)
		expect(a.aura:emitterCount()).toBe(1)
		while not seq.done do
			env.rt:step(DT)
		end
		expect(a.aura:emitterCount()).toBe(0)
	end)
end)

T.describe("Biblioteca de impactos y cámara", function()
	T.it("cada impacto se pinta, su sacudida es ≤ 0,3 y vuelve al pool", function()
		local env = setup()
		local b = side(env, "teselo", "Brote", "S2A", 4)
		for id in pairs(VFX.Impacts) do
			local r = env.Impact.play(
				{ id },
				{ creature = b.creature },
				{ element = "Tierra", pool = env.pool, runtime = env.rt }
			)
			expect(r.shake <= 0.3).toBe(true)
			expect(type(r.sounds[1])).toBe("string")
		end
		local crit = env.Impact.play({ "Elemental", "Crit" }, { creature = b.creature }, { element = "Tierra" })
		expect(crit.shake).toBe(0.3)
		expect(crit.reaction).toBe("Hurt")
		settle(env, 2)
		expect(env.pool:stats().active).toBe(0)
	end)

	T.it("la sacudida nunca pasa de 0,3 studs y con movimiento reducido la cámara no se mueve", function()
		local env = setup()
		local cam = roblox.Instance.new("Camera")
		local director = env.Camera.new(cam, { reducedMotion = false })
		director:setBase(roblox.Vector3.new(0, 7, 14), roblox.Vector3.new(0, 1.6, 0))
		local base = director:update(0)
		director:shake(5) -- se pide demasiado: se recorta
		local worst = 0
		for _ = 1, 30 do
			local cf = director:update(DT)
			worst = math.max(worst, (cf.Position - base.Position).Magnitude)
		end
		expect(worst > 0).toBe(true)
		expect(worst <= VFX.Camera.maxShake + 1e-6).toBe(true)
		local calm = env.Camera.new(cam, { reducedMotion = true })
		calm:setBase(roblox.Vector3.new(0, 7, 14), roblox.Vector3.new(0, 1.6, 0))
		local still = calm:update(0)
		calm:shake(0.3)
		calm:beat("PushIn", roblox.Vector3.new(-4, 1, 0))
		calm:beat("Nexo", roblox.Vector3.new(-4, 1, 0), 2)
		for _ = 1, 30 do
			local cf = calm:update(DT)
			expect((cf.Position - still.Position).Magnitude < 1e-6).toBe(true)
		end
		-- Acercamiento breve y vuelta al encuadre
		director:clear()
		director:beat("PushIn", roblox.Vector3.new(-4, 1, 0))
		local mid = nil
		for i = 1, 30 do
			local cf = director:update(DT)
			if i == 10 then
				mid = cf
			end
		end
		expect((mid :: any).Position.X < base.Position.X).toBe(true)
		expect((director:update(DT).Position - base.Position).Magnitude < 1e-3).toBe(true)
	end)
end)

T.describe("Evolución (Tallado) en la ceremonia", function()
	T.it("fases en orden, ≤ 5 s, el Brote se va y aparece el Tallado (otro modelo)", function()
		local env = setup()
		local root = roblox.Instance.new("Frame")
		local order = {}
		local seenBroteAtReveal = true
		local evo
		evo = env.Evolution.new(root, "kuachi", {
			onPhase = function(p)
				table.insert(order, p)
				if p == "Reveal" then
					seenBroteAtReveal = evo.broteVp ~= nil
				end
			end,
		})
		local brote = evo.broteVp
		expect(brote ~= nil).toBe(true)
		local clock = 0
		local darkened = false
		while not evo.done and clock < 8 do
			evo:step(DT)
			clock += DT
			if evo.phase == "Transition" and evo.brote then
				local rec = evo.brote.parts[1]
				if rec.part.Color ~= rec.baseColor then
					darkened = true
				end
			end
		end
		expect(table.concat(order, ">")).toBe("Preparation>Energy>Transition>Light>Reveal>Presentation>Done")
		expect(evo.total <= VFX.Evolution.maxSeconds).toBe(true)
		expect(clock <= evo.total + 2 * DT).toBe(true)
		expect(darkened).toBe(true)
		expect(seenBroteAtReveal).toBe(false)
		expect(brote.Parent == nil).toBe(true)
		expect(evo.talladoVp ~= nil and evo.talladoVp.Parent == root).toBe(true)
		expect(evo.tallado.form).toBe("Tallado")
		-- Al terminar, el Tallado conserva sus colores y materiales
		for _, rec in ipairs(evo.tallado.parts) do
			expect(rec.part.Color == rec.baseColor).toBe(true)
		end
	end)

	T.it("se puede saltar en cualquier momento y queda el Tallado", function()
		local env = setup()
		local root = roblox.Instance.new("Frame")
		local evo = env.Evolution.new(root, "teselo")
		for _ = 1, 20 do
			evo:step(DT)
		end
		evo:skip()
		expect(evo.done).toBe(true)
		expect(evo.broteVp == nil).toBe(true)
		expect(evo.talladoVp ~= nil).toBe(true)
		local frames = 0
		for _, d in ipairs(root:GetChildren()) do
			if d:IsA("Frame") then
				frames += 1
			end
		end
		expect(frames).toBe(0) -- sin chispas ni destello colgando
	end)
end)
