--!strict
-- Animación de criaturas: máquina de estados (pura), personalidad por especie y animador
-- procedural con clases reales (blockout de Parts y modelo con Bone por nombre).
local T = harness.T
local expect = T.expect
local CreatureMotion = harness.get("ReplicatedStorage.Shared.Config.CreatureMotion")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")
local Guardians = harness.get("ReplicatedStorage.Shared.Config.Guardians")
local MotionStateMachine = harness.get("StarterPlayerScripts.Client.Animation.MotionStateMachine")
local roblox = harness.sandbox.roblox

local DT = 1 / 60

local function run(sm: any, seconds: number, input: any): { string }
	local seen = {}
	local t = 0
	while t < seconds do
		local s = sm:update(DT, input)
		if seen[#seen] ~= s then
			table.insert(seen, s)
		end
		t += DT
	end
	return seen
end

T.describe("CreatureMotion · familias y personalidad", function()
	T.it("las siete familias tienen sus parámetros y cada especie tiene familia", function()
		local needed = {
			"gait",
			"walkRef",
			"runSpeed",
			"stepHz",
			"stride",
			"breathHz",
			"headYaw",
			"tailAmp",
			"lean",
			"jumpHeight",
		}
		for _, id in ipairs({
			"QuadrupedAgile",
			"QuadrupedHeavy",
			"Amphibian",
			"ArmoredReptile",
			"Bird",
			"Floating",
			"Biped",
		}) do
			local f = CreatureMotion.Families[id]
			expect(f ~= nil).toBe(true)
			for _, k in ipairs(needed) do
				if f[k] == nil then
					error(id .. " sin " .. k)
				end
			end
		end
		for _, id in ipairs(Species.Order) do
			expect(CreatureMotion.Families[MotionStateMachine.familyFor(id)] ~= nil).toBe(true)
		end
		for id in pairs(Guardians.ById) do
			expect(CreatureMotion.Families[MotionStateMachine.familyFor(id)] ~= nil).toBe(true)
		end
		expect(#CreatureMotion.States).toBe(21)
	end)

	T.it("Kuachi inquieto, Xolumi calmado, Teselo pesado; el resto toma su familia", function()
		local k = MotionStateMachine.profile("kuachi")
		local x = MotionStateMachine.profile("xolumi")
		local t = MotionStateMachine.profile("teselo")
		expect(k.family).toBe("QuadrupedAgile")
		expect(x.family).toBe("Amphibian")
		expect(t.family).toBe("ArmoredReptile")
		expect(k.tempo > 1 and x.tempo < 1 and t.tempo < 1).toBe(true)
		expect(k.idleAlt.max < x.idleAlt.min).toBe(true) -- Kuachi no se está quieto
		expect(k.tailSpiral).toBe(true)
		expect(k.playDead ~= nil).toBe(true)
		expect(x.gillAmp > 0 and x.pause ~= nil).toBe(true)
		expect(t.inertia > 1 and t.defend == "Retreat").toBe(true)
		-- Comalú es Cuadrúpedo Defensor: se mueve como pesado
		expect(MotionStateMachine.familyFor("comalu")).toBe("QuadrupedHeavy")
		expect(MotionStateMachine.familyFor("zunzi")).toBe("Bird")
		expect(MotionStateMachine.familyFor("copalia")).toBe("Bird")
		local generic = MotionStateMachine.profile("zunzi")
		expect(generic.tempo).toBe(1)
		expect(generic.stepHz).toBe(CreatureMotion.Families.Bird.stepHz)
	end)
end)

T.describe("MotionStateMachine · locomoción (pura)", function()
	T.it("cambia de estado según la velocidad: Idle → Walk → Run → Walk → Stop → Idle", function()
		local sm = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), 7)
		local all = {}
		for _, step in ipairs({ { 0.3, 0 }, { 1, 3 }, { 1, 14 }, { 1, 5 }, { 0.6, 0 } }) do
			for _, s in ipairs(run(sm, step[1], { speed = step[2] })) do
				if all[#all] ~= s then
					table.insert(all, s)
				end
			end
		end
		expect(table.concat(all, ">")).toBe("Idle>Walk>Run>Walk>Stop>Idle")
	end)

	T.it("con histéresis no vibra cerca de los umbrales", function()
		local sm = MotionStateMachine.new(MotionStateMachine.profile("teselo"), 3)
		run(sm, 0.5, { speed = 3 })
		local before = sm.transitions
		local t = 0
		while t < 3 do
			-- ruido alrededor del umbral de andar (entra a 0,6 y sale a 0,3)
			sm:update(DT, { speed = 0.45 + 0.12 * math.sin(t * 40) })
			t += DT
		end
		expect(sm.transitions - before).toBe(0)
		local run2 = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), 3)
		run(run2, 0.5, { speed = 12 })
		local b2 = run2.transitions
		t = 0
		while t < 3 do
			run2:update(DT, { speed = 10.5 + 0.8 * math.sin(t * 30) }) -- entre 9,35 y 11
			t += DT
		end
		expect(run2.transitions - b2).toBe(0)
	end)

	T.it("giro en el sitio, salto, caída y aterrizaje", function()
		local sm = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), 5)
		expect(run(sm, 0.2, { speed = 0, yawRate = 3 })[1]).toBe("Turn")
		expect(sm:update(DT, { speed = 0, grounded = false, verticalSpeed = 6 })).toBe("Jump")
		expect(sm:update(DT, { speed = 0, grounded = false, verticalSpeed = -6 })).toBe("Fall")
		run(sm, 0.3, { speed = 0, grounded = false, verticalSpeed = -8 })
		expect(sm:update(DT, { speed = 0, grounded = true })).toBe("Land")
		local after = run(sm, 0.5, { speed = 0 })
		expect(after[#after]).toBe("Idle")
	end)

	T.it("variante de reposo según la personalidad y Kuachi que se hace el muerto", function()
		local sm = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), 11)
		local states = run(sm, 8, { speed = 0 })
		expect(table.find(states, "IdleAlt") ~= nil).toBe(true)
		local variants = MotionStateMachine.profile("kuachi").idleAlt.variants
		expect(table.find(variants, sm.idleVariant) ~= nil).toBe(true)
		local played = 0
		for seed = 1, 40 do
			local k = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), seed)
			k:trigger("Happy")
			k:update(DT, { speed = 0 })
			if k.variant == "PlayDead" then
				played += 1
			end
		end
		expect(played > 0 and played < 40).toBe(true)
		local x = MotionStateMachine.new(MotionStateMachine.profile("xolumi"), 1)
		for _ = 1, 20 do
			x:trigger("Happy")
			x:update(DT, { speed = 0 })
			expect(x.variant ~= "PlayDead").toBe(true)
		end
	end)

	T.it("estados de un solo uso y fijados; Teselo se resguarda al avisar", function()
		local sm = MotionStateMachine.new(MotionStateMachine.profile("teselo"), 2)
		run(sm, 0.5, { speed = 3 })
		sm:trigger("Hurt")
		expect(sm:update(DT, { speed = 3 })).toBe("Hurt")
		local after = run(sm, 1, { speed = 3 })
		expect(after[#after]).toBe("Walk")
		sm:hold("Stun")
		expect(run(sm, 2, { speed = 0 })[1]).toBe("Stun")
		sm:hold(nil)
		sm:trigger("Warn")
		sm:update(DT, { speed = 0 })
		expect(sm.state).toBe("Warn")
		expect(sm.variant).toBe("Retreat")
		-- Todos los estados de la lista se pueden alcanzar
		local reached = {}
		for _, s in ipairs(CreatureMotion.States) do
			local m = MotionStateMachine.new(MotionStateMachine.profile("kuachi"), 9)
			if CreatureMotion.OneShot[s] and s ~= "Land" and s ~= "Stop" then
				m:trigger(s)
				m:update(DT, { speed = 0 })
				reached[m.state] = true
			end
		end
		for _, s in ipairs({
			"Interact",
			"Eat",
			"Happy",
			"Curious",
			"Warn",
			"Hurt",
			"Stun",
			"Victory",
			"Defeat",
			"Attack",
			"Special",
			"Nexo",
		}) do
			expect(reached[s]).toBe(true)
		end
	end)
end)

T.describe("CreatureAnimator · blockout y huesos (clases reales)", function()
	local function setup()
		local sb = harness.sandbox.newClient({})
		local CreatureBuilder = sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder")
		local Animator = sb.load("StarterPlayerScripts.Client.Animation.CreatureAnimator")
		local folder = roblox.Instance.new("Folder")
		return CreatureBuilder, Animator, folder
	end

	local function bonePart(c: any, bone: string): any
		for _, rec in ipairs(c.parts) do
			if rec.part:GetAttribute("Bone") == bone then
				return rec.part
			end
		end
		return nil
	end

	T.it("los blockouts llevan huesos con los nombres de asset.json", function()
		local CreatureBuilder = setup()
		local expected = {
			kuachi = { "spine", "head", "legF_L", "legF_R", "legB_L", "legB_R", "tail1", "tail5" },
			xolumi = { "spine", "head", "gill_L", "gill_R", "tail1", "legF_L", "legB_R" },
			teselo = { "body", "head", "legF_L", "legB_R" },
		}
		for id, bones in pairs(expected) do
			local c = CreatureBuilder.build(id, "Brote", { parent = roblox.Instance.new("Folder") })
			for _, b in ipairs(bones) do
				if not bonePart(c, b) then
					error(id .. " sin hueso " .. b)
				end
			end
		end
		local mit = CreatureBuilder.build("teselo", "Tallado", { parent = roblox.Instance.new("Folder") })
		for _, b in ipairs({ "ringA", "ringB", "skyDisc" }) do
			expect(bonePart(mit, b) ~= nil).toBe(true)
		end
		local xolossus = CreatureBuilder.build("xolumi", "Tallado", { parent = roblox.Instance.new("Folder") })
		expect(bonePart(xolossus, "legM_L") ~= nil).toBe(true)
	end)

	T.it("al andar se mueven las patas y la cola; parado respira sin dar pasos", function()
		local CreatureBuilder, Animator, folder = setup()
		local c = CreatureBuilder.build("kuachi", "Brote", { parent = folder })
		local anim = Animator.new(c, { seed = 4 })
		local leg, tail = bonePart(c, "legF_L"), bonePart(c, "tail5")
		local root = roblox.CFrame.new(0, 0, 0)
		anim:update(DT, root, { speed = 0 })
		local legIdle = leg.CFrame
		for _ = 1, 30 do
			anim:update(DT, root, { speed = 0 })
		end
		-- Parado: la pata apenas se mueve (solo la respiración del torso)
		expect((leg.CFrame.Position - legIdle.Position).Magnitude < 0.1).toBe(true)
		local tailA = tail.CFrame
		for _ = 1, 20 do
			anim:update(DT, root, { speed = 8 })
		end
		expect(anim:state()).toBe("Walk")
		local legLook = leg.CFrame.LookVector
		expect(math.abs(legLook.Y - legIdle.LookVector.Y) > 0.01 or math.abs(legLook.Z - legIdle.LookVector.Z) > 0.01).toBe(
			true
		)
		expect((tail.CFrame.Position - tailA.Position).Magnitude > 0.005).toBe(true)
	end)

	T.it("la cabeza mira al objetivo dentro de su límite", function()
		local CreatureBuilder, Animator, folder = setup()
		local c = CreatureBuilder.build("kuachi", "Brote", { parent = folder })
		local anim = Animator.new(c, { seed = 2 })
		local head = bonePart(c, "head")
		local root = roblox.CFrame.new()
		anim:update(DT, root, { speed = 0 })
		local before = head.CFrame.ZVector -- la criatura mira a +Z
		anim:setLookTarget(roblox.Vector3.new(20, 1.5, 5)) -- a su izquierda (+X)
		for _ = 1, 90 do
			anim:update(DT, root, { speed = 0 })
		end
		local after = head.CFrame.ZVector
		expect(after.X > before.X + 0.2).toBe(true)
		expect(math.abs(anim.p.headYaw) <= anim.profile.headYaw + 1e-6).toBe(true)
	end)

	T.it("Teselo se resguarda: la cabeza se mete en el caparazón", function()
		local CreatureBuilder, Animator, folder = setup()
		local c = CreatureBuilder.build("teselo", "Brote", { parent = folder })
		local anim = Animator.new(c, { seed = 1 })
		local head = bonePart(c, "head")
		anim:update(DT, roblox.CFrame.new(), { speed = 0 })
		local z0 = head.CFrame.Position.Z
		anim:trigger("Warn")
		for _ = 1, 30 do
			anim:update(DT, roblox.CFrame.new(), { speed = 0 })
		end
		expect(head.CFrame.Position.Z < z0 - 0.2).toBe(true)
	end)

	T.it("las branquias de Xolumi laten aunque esté quieto", function()
		local CreatureBuilder, Animator, folder = setup()
		local c = CreatureBuilder.build("xolumi", "Brote", { parent = folder })
		local anim = Animator.new(c, { seed = 1 })
		local gill = bonePart(c, "gill_L")
		local seen = {}
		for i = 1, 120 do
			anim:update(DT, roblox.CFrame.new(), { speed = 0 })
			if i % 20 == 0 then
				table.insert(seen, gill.CFrame.UpVector.X)
			end
		end
		local lo, hi = math.huge, -math.huge
		for _, v in ipairs(seen) do
			lo, hi = math.min(lo, v), math.max(hi, v)
		end
		expect(hi - lo > 0.05).toBe(true)
	end)

	T.it("LOD: a media distancia anima un frame de cada dos; lejos, nada", function()
		local CreatureBuilder, Animator, folder = setup()
		local c = CreatureBuilder.build("kuachi", "Brote", { parent = folder })
		local anim = Animator.new(c, { seed = 1 })
		for _ = 1, 10 do
			anim:update(DT, roblox.CFrame.new(), { speed = 5 }, "Reduced")
		end
		expect(anim.applied).toBe(5)
		for _ = 1, 10 do
			anim:update(DT, roblox.CFrame.new(), { speed = 5 }, "None")
		end
		expect(anim.applied).toBe(5)
	end)

	T.it("con un modelo importado escribe Bone.Transform por nombre", function()
		local _, Animator = setup()
		local model = roblox.Instance.new("Model")
		local root = roblox.Instance.new("Part")
		root.Parent = model
		model.PrimaryPart = root
		local function bone(name: string, parent: any, pos: any): any
			local b = roblox.Instance.new("Bone")
			b.Name = name
			b.CFrame = roblox.CFrame.new(pos)
			b.Parent = parent
			return b
		end
		local spine = bone("spine", root, roblox.Vector3.new(0, 0.6, 0))
		local head = bone("head", spine, roblox.Vector3.new(0, 0.3, 0.5))
		local leg = bone("legF_L", spine, roblox.Vector3.new(0.3, -0.1, 0.3))
		local tail = bone("tail1", spine, roblox.Vector3.new(0, 0, -0.6))
		local anim = Animator.new(
			{ model = model, speciesId = "kuachi", form = "Brote", scale = 1 },
			{ mesh = true, seed = 3 }
		)
		expect(anim.mesh).toBe(true)
		expect(anim.rig.bones.head.parent).toBe("spine")
		anim:setLookTarget(roblox.Vector3.new(10, 1, 2))
		for _ = 1, 40 do
			anim:update(DT, roblox.CFrame.new(), { speed = 6 })
		end
		local function moved(b: any): boolean
			local cf = b.Transform
			return cf.Position.Magnitude > 1e-4 or math.abs(cf.LookVector.Z - 1) > 1e-4
		end
		expect(moved(head)).toBe(true)
		expect(moved(leg)).toBe(true)
		expect(moved(tail)).toBe(true)
	end)
end)
