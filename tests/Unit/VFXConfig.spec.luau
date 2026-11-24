--!strict
-- Config/VFX y las reglas puras de presentación (VFXPlan, VFXRuntime).
-- VFXPlan y VFXRuntime se cargan con el arnés NORMAL (sin Instance, CFrame ni task): si
-- usaran APIs de motor, estas pruebas fallarían al cargarlos.
local T = harness.T
local expect = T.expect
local VFX = harness.get("ReplicatedStorage.Shared.Config.VFX")
local Elements = harness.get("ReplicatedStorage.Shared.Config.Elements")
local Rarities = harness.get("ReplicatedStorage.Shared.Config.Rarities")
local Combat = harness.get("ReplicatedStorage.Shared.Config.Combat")
local Abilities = harness.get("ReplicatedStorage.Shared.Config.Abilities")
local VFXPlan = harness.get("StarterPlayerScripts.Client.VFX.VFXPlan")
local VFXRuntime = harness.get("StarterPlayerScripts.Client.VFX.VFXRuntime")

local AURA_ANCHORS = { Back = true, Orbit = true, Ground = true, Top = true }
local COMBAT_ANCHORS =
	{ Mouth = true, Caster = true, CasterFeet = true, Target = true, TargetFeet = true, Above = true }

local function stylesOf(profile: any): { [string]: boolean }
	local set = {}
	for _, id in ipairs(profile.aura) do
		set[id] = true
	end
	for _, phase in ipairs({ "cast", "impact" }) do
		for _, use in ipairs(profile[phase].emitters or {}) do
			set[use.style] = true
		end
	end
	if profile.travel.emitter then
		set[profile.travel.emitter] = true
	end
	return set
end

local function checkKeys(keys: { { number } }, what: string)
	expect(#keys >= 2).toBe(true)
	expect(keys[1][1]).toBe(0)
	expect(keys[#keys][1]).toBe(1)
	for i = 2, #keys do
		if keys[i][1] < keys[i - 1][1] then
			error(what .. ": keypoints desordenados")
		end
	end
end

T.describe("Config/VFX · los doce elementos", function()
	T.it("hay un perfil por cada elemento de Config/Elements, con sus ids", function()
		local n = 0
		for _, id in ipairs(Elements.Order) do
			local p = VFX.Elements[id]
			expect(p ~= nil).toBe(true)
			expect(p.id).toBe(id)
			-- El color principal sale de Config/Elements (no se duplica)
			expect(p.palette.primary).toBe(Elements.ById[id].color)
			n += 1
		end
		local count = 0
		for _ in pairs(VFX.Elements) do
			count += 1
		end
		expect(count).toBe(n)
		expect(n).toBe(12)
	end)

	T.it("cada elemento tiene composición y movimiento propios", function()
		local motions, auraKeys = {}, {}
		for _, id in ipairs(Elements.Order) do
			local p = VFX.Elements[id]
			expect(motions[p.motion] == nil).toBe(true)
			motions[p.motion] = true
			local key = table.concat(p.aura, ",")
			expect(auraKeys[key] == nil).toBe(true)
			auraKeys[key] = true
			local styles = 0
			for _ in pairs(stylesOf(p)) do
				styles += 1
			end
			if styles < 3 then
				error(id .. ": menos de 3 estilos de partícula")
			end
			-- Los estilos del aura son del propio elemento (prefijo) y existen
			for _, sid in ipairs(p.aura) do
				expect(VFX.Styles[sid] ~= nil).toBe(true)
				expect(string.sub(sid, 1, #id + 1)).toBe(id .. "_")
			end
			expect(#p.description > 40).toBe(true)
		end
	end)

	T.it("todas las referencias de estilos de los perfiles e impactos existen", function()
		local function check(profile: any)
			for sid in pairs(stylesOf(profile)) do
				if not VFX.Styles[sid] then
					error("Estilo inexistente: " .. sid)
				end
			end
		end
		for _, p in pairs(VFX.Elements) do
			check(p)
		end
		check(VFX.Neutral)
		for _, imp in pairs(VFX.Impacts) do
			for _, use in ipairs(imp.emitters) do
				expect(VFX.Styles[use.style] ~= nil).toBe(true)
			end
		end
	end)
end)

T.describe("Config/VFX · estilos de partículas", function()
	T.it("solo texturas del motor y tasa ≤ 20 partículas/s por emisor (también en pulsos)", function()
		for _, url in pairs(VFX.Textures) do
			expect(string.sub(url, 1, 29)).toBe("rbxasset://textures/particles")
			expect(string.find(url, "rbxassetid", 1, true) == nil).toBe(true)
		end
		for id, s in pairs(VFX.Styles) do
			expect(VFX.Textures[s.texture] ~= nil).toBe(true)
			if s.rate > VFX.Budget.maxRatePerEmitter then
				error(id .. ": tasa " .. s.rate)
			end
			if s.tick and (s.burst or 0) / s.tick > VFX.Budget.maxRatePerEmitter then
				error(id .. ": pulsos por encima de 20/s")
			end
			expect(s.lifetime[1] <= s.lifetime[2]).toBe(true)
			expect(s.speed[1] <= s.speed[2]).toBe(true)
			checkKeys(s.size, id)
			if s.transparency then
				checkKeys(s.transparency, id)
			end
			if s.squash then
				checkKeys(s.squash, id)
			end
			expect(AURA_ANCHORS[s.anchor] or COMBAT_ANCHORS[s.anchor]).toBe(true)
			expect(#s.note > 10).toBe(true)
		end
	end)

	T.it("el aura nunca emite hacia delante (la cara queda limpia)", function()
		local aura = {}
		for _, p in pairs(VFX.Elements) do
			for _, sid in ipairs(p.aura) do
				aura[sid] = true
			end
		end
		for _, r in pairs(VFX.Rarities) do
			for _, layer in ipairs(r.layers) do
				if string.sub(layer, 1, 1) ~= "$" then
					aura[layer] = true
				end
			end
		end
		for sid in pairs(aura) do
			local s = VFX.Styles[sid]
			expect(s.direction ~= "Forward").toBe(true)
			expect(AURA_ANCHORS[s.anchor] == true).toBe(true)
		end
	end)

	T.it("un impacto sobre el objetivo no lo tapa más de 0,3 s (o sale disparado)", function()
		local B = VFX.Budget
		local function check(use: any)
			local s = VFX.Styles[use.style]
			local anchor = use.anchor or s.anchor
			if anchor == "Target" then
				local ok = s.lifetime[2] <= B.maxTargetOcclusion or s.speed[1] >= B.fastLeaveSpeed
				if not ok then
					error("Tapa al objetivo: " .. use.style)
				end
			end
		end
		for _, p in pairs(VFX.Elements) do
			for _, use in ipairs(p.impact.emitters) do
				check(use)
			end
		end
		for _, imp in pairs(VFX.Impacts) do
			for _, use in ipairs(imp.emitters) do
				check(use)
			end
		end
	end)
end)

T.describe("Config/VFX · rareza, secuencias, impactos, calidad y LOD", function()
	T.it("presupuesto de emisores por rareza (p. 26 y 120)", function()
		local R = VFX.Rarities
		for _, q in ipairs(VFX.QualityOrder) do
			expect(R.Comun.emitters[q]).toBe(0)
			expect(R.Raro.emitters[q]).toBe(1)
			expect(R.Epico.emitters[q] >= 1 and R.Epico.emitters[q] <= 2).toBe(true)
			expect(R.Legendario.emitters[q] >= 2 and R.Legendario.emitters[q] <= 3).toBe(true)
			expect(R.Unico.emitters[q] <= 3).toBe(true)
			expect(R.Misterio.emitters[q] <= 3).toBe(true)
		end
		expect(R.Raro.attackOnly).toBe(true)
		expect(R.Raro.rim ~= nil).toBe(true)
		expect(R.Legendario.beam ~= nil).toBe(true)
		expect(R.Unico.halo ~= nil).toBe(true)
		for id in pairs(Rarities.ById) do
			expect(R[id] ~= nil).toBe(true)
			expect(#R[id].layers >= R[id].emitters.High).toBe(true)
		end
		-- El 60 % de combate es el mismo dato que Config/Combat
		expect(VFX.Budget.battleIntensity).toBe(Combat.AuraBattleIntensity)
	end)

	T.it("ningún ataque supera 1,6 s; el Golpe Nexo dura como mucho 3,5 s", function()
		for kind, seq in pairs(VFX.Sequences) do
			local total = 0
			for _, id in ipairs(VFX.PhaseOrder) do
				local d = seq.phases[id]
				expect(d ~= nil and d > 0).toBe(true)
				total += d
			end
			local limit = if kind == "Nexo" then 3.5 else 1.6
			if total > limit + 1e-9 then
				error(string.format("%s dura %.2f s", kind, total))
			end
		end
		expect(VFX.Sequences.Nexo.skippable).toBe(true)
		expect(#VFX.PhaseOrder).toBe(6)
	end)

	T.it("la biblioteca de impactos está completa y la sacudida es moderada (≤ 0,3 studs)", function()
		for _, id in ipairs({
			"Physical",
			"Elemental",
			"Shield",
			"Heal",
			"Burn",
			"Paralyze",
			"Stun",
			"Reflect",
			"Crit",
			"Victory",
		}) do
			local imp = VFX.Impacts[id]
			expect(imp ~= nil).toBe(true)
			expect(imp.shake <= VFX.Camera.maxShake).toBe(true)
			expect(type(imp.sound)).toBe("string")
		end
		expect(VFX.Camera.maxShake <= 0.3).toBe(true)
	end)

	T.it("calidad Low < Medium < High y LOD 60 / 140", function()
		local Q = VFX.Quality
		expect(Q.Low.rate < Q.Medium.rate and Q.Medium.rate <= Q.High.rate).toBe(true)
		expect(Q.High.rate).toBe(1)
		expect(Q.Low.lights).toBe(false)
		expect(VFX.LOD.full).toBe(60)
		expect(VFX.LOD.reduced).toBe(140)
		expect(VFX.Budget.broteSize).toBe(0.8)
		expect(VFX.Budget.broteRate).toBe(0.5)
	end)

	T.it("los datos están congelados", function()
		expect(table.isfrozen(VFX)).toBe(true)
		expect(table.isfrozen(VFX.Styles.Fuego_Brasas)).toBe(true)
		expect(table.isfrozen(VFX.Elements.Agua.palette)).toBe(true)
	end)
end)

T.describe("VFXPlan · presupuesto del aura (puro)", function()
	T.it("cuenta de emisores por rareza en el Tallado (calidad alta)", function()
		local function n(r: string, ctx: any?): number
			local c = ctx or {}
			c.quality = c.quality or "High"
			return #VFXPlan.aura(r, "Tallado", c).emitters
		end
		expect(n("Comun")).toBe(0)
		expect(n("Comun", { attacking = true })).toBe(0)
		expect(n("Raro")).toBe(0)
		expect(n("Raro", { attacking = true })).toBe(1)
		expect(n("Epico")).toBe(2)
		expect(n("Epico", { quality = "Low" })).toBe(1)
		expect(n("Legendario")).toBe(3)
		expect(n("Legendario", { quality = "Low" })).toBe(2)
		expect(n("Unico")).toBe(3)
		expect(VFXPlan.aura("Legendario", "Tallado", { quality = "High" }).beam ~= nil).toBe(true)
		expect(VFXPlan.aura("Unico", "Tallado", { quality = "High" }).halo ~= nil).toBe(true)
		expect(VFXPlan.aura("Raro", "Tallado", { attacking = true }).rim).toBe(true)
		expect(VFXPlan.aura("Raro", "Tallado", {}).rim).toBe(false)
	end)

	T.it("Brote: 80 % de tamaño, mitad de partículas y como mucho 1 emisor; combate al 60 %", function()
		local t = VFXPlan.aura("Legendario", "Tallado", { quality = "High" })
		local b = VFXPlan.aura("Legendario", "Brote", { quality = "High" })
		expect(#b.emitters).toBe(1)
		expect(b.emitters[1].size).toBeNear(0.8 * t.emitters[1].size)
		expect(b.emitters[1].rate).toBeNear(0.5 * t.emitters[1].rate)
		expect(b.beam == nil).toBe(true)
		local battle = VFXPlan.aura("Legendario", "Tallado", { quality = "High", battle = true })
		expect(battle.emitters[1].rate).toBeNear(0.6 * t.emitters[1].rate)
		expect(battle.brightness).toBeNear(0.6)
		expect(#battle.emitters).toBe(#t.emitters)
	end)

	T.it("opacado o lejos (LOD reducido o nada): sin partículas", function()
		expect(#VFXPlan.aura("Unico", "Tallado", { opaco = true }).emitters).toBe(0)
		expect(#VFXPlan.aura("Unico", "Tallado", { lod = "Reduced" }).emitters).toBe(0)
		expect(#VFXPlan.aura("Unico", "Tallado", { lod = "None" }).emitters).toBe(0)
		expect(VFXPlan.aura("Unico", "Tallado", { lod = "Reduced" }).glowPulse).toBe(false)
	end)

	T.it("la rareza toma el sabor del elemento («$element:N»)", function()
		local p = VFXPlan.aura("Epico", "Tallado", { quality = "High", element = "Fuego" })
		expect(p.emitters[1].style).toBe("Fuego_Brasas")
		expect(p.emitters[2].style).toBe("Rareza_Orbita")
		local w = VFXPlan.aura("Epico", "Tallado", { quality = "High", element = "Agua" })
		expect(w.emitters[1].style).toBe("Agua_Burbujas")
		expect(VFXPlan.profile(nil).id).toBe("Eco")
		expect(VFXPlan.profile("NoExiste").id).toBe("Eco")
	end)

	T.it("LOD por distancia con histéresis (no parpadea en el borde)", function()
		expect(VFXPlan.lod(10)).toBe("Full")
		expect(VFXPlan.lod(100)).toBe("Reduced")
		expect(VFXPlan.lod(200)).toBe("None")
		-- Cerca del borde de 60 se mantiene el nivel anterior
		expect(VFXPlan.lod(62, "Full")).toBe("Full")
		expect(VFXPlan.lod(58, "Reduced")).toBe("Reduced")
		expect(VFXPlan.lod(50, "Reduced")).toBe("Full")
		expect(VFXPlan.lod(70, "Full")).toBe("Reduced")
		expect(VFXPlan.lod(138, "None")).toBe("None")
		expect(VFXPlan.lod(130, "None")).toBe("Reduced")
		local tier, flips = VFXPlan.lod(60), 0
		for i = 1, 200 do
			local d = 60 + math.sin(i * 0.7) * 3 -- tiembla alrededor de 60
			local nextTier = VFXPlan.lod(d, tier)
			if nextTier ~= tier then
				flips += 1
			end
			tier = nextTier
		end
		expect(flips).toBe(0)
	end)
end)

T.describe("VFXPlan · secuencias e impactos (puro)", function()
	T.it("cada jugada elige su secuencia por tipo y efecto", function()
		local M = Abilities.ById
		expect(VFXPlan.sequenceKind(M.Chorro)).toBe("Basic")
		expect(VFXPlan.sequenceKind(M.MareaLenta)).toBe("Special")
		expect(VFXPlan.sequenceKind(M.DiluvioDeCantaros)).toBe("Nexo")
		expect(VFXPlan.sequenceKind(M.Manantial)).toBe("Heal")
		expect(VFXPlan.sequenceKind(M.Halo)).toBe("Heal")
		expect(VFXPlan.sequenceKind(M.EscudoRepujado)).toBe("Shield")
		expect(VFXPlan.sequenceKind(M.MurallaDeAdobe)).toBe("Shield")
		expect(VFXPlan.sequenceKind(M.Constelacion)).toBe("Status")
		for id, mv in pairs(M) do
			local kind = VFXPlan.sequenceKind(mv)
			local tl = VFXPlan.timeline(kind)
			if tl.total > tl.limit + 1e-9 then
				error(id .. " supera su límite")
			end
		end
	end)

	T.it("la línea de tiempo tiene las seis fases en orden y el impacto en su sitio", function()
		local tl = VFXPlan.timeline("Basic")
		expect(#tl.phases).toBe(6)
		expect(tl.phases[1].id).toBe("Preparation")
		expect(tl.phases[6].id).toBe("Recovery")
		local s = VFX.Sequences.Basic.phases
		expect(tl.hitAt).toBeNear(s.Preparation + s.Anticipation + s.Execution)
		expect(tl.total <= 1.6).toBe(true)
		expect(VFXPlan.phaseAt(tl, -0.1)).toBe(nil)
		expect(VFXPlan.phaseAt(tl, 0)).toBe("Preparation")
		expect(VFXPlan.phaseAt(tl, tl.hitAt + 0.001)).toBe("Impact")
		expect(VFXPlan.phaseAt(tl, tl.total + 0.01)).toBe("Done")
		local nexo = VFXPlan.timeline("Nexo")
		expect(nexo.total <= 3.5).toBe(true)
		expect(nexo.skippable).toBe(true)
		local fast = VFXPlan.timeline("Basic", { fast = true })
		expect(fast.total).toBeNear(tl.total * 0.6)
	end)

	T.it("cada evento del servidor tiene su impacto (sin cambiar el evento)", function()
		local M = Abilities.ById
		local hit = { t = "Damage", target = "S2A", amount = 10 }
		expect(VFXPlan.impactsFor(hit, M.Chorro)[1]).toBe("Elemental")
		expect(VFXPlan.impactsFor(hit, M.ZarpaDeBrasa)[1]).toBe("Physical")
		local crit = VFXPlan.impactsFor({ t = "Damage", crit = true }, M.Chorro)
		expect(crit[2]).toBe("Crit")
		expect(VFXPlan.impactsFor({ t = "Heal" })[1]).toBe("Heal")
		expect(VFXPlan.impactsFor({ t = "ShieldAbsorb" })[1]).toBe("Shield")
		expect(VFXPlan.impactsFor({ t = "Guard", kind = "Reflect" })[1]).toBe("Reflect")
		expect(VFXPlan.impactsFor({ t = "Status", status = "Burn" })[1]).toBe("Burn")
		expect(VFXPlan.impactsFor({ t = "Status", status = "Paralysis" })[1]).toBe("Paralyze")
		expect(VFXPlan.impactsFor({ t = "Status", status = "Stun" })[1]).toBe("Stun")
		expect(VFXPlan.impactsFor({ t = "StatusTick", status = "Burn" })[1]).toBe("Burn")
		expect(VFXPlan.impactsFor({ t = "Reflect" })[1]).toBe("Reflect")
		expect(VFXPlan.impactsFor({ t = "Restored" })[1]).toBe("Victory")
		expect(#VFXPlan.impactsFor({ t = "Savia" })).toBe(0)
		local events = {
			{ t = "Move", actor = "S1A" },
			{ t = "Damage", target = "S2A" },
			{ t = "Status", target = "S2A", status = "Burn" },
			{ t = "Move", actor = "S2A" },
			{ t = "Damage", target = "S1A" },
		}
		expect(#VFXPlan.moveGroup(events, 1)).toBe(2)
		expect(#VFXPlan.moveGroup(events, 4)).toBe(1)
	end)
end)

T.describe("VFXRuntime · un paso por frame con presupuesto (reloj falso)", function()
	T.it("temporizadores cancelables, en orden y sin hilos", function()
		local rt = VFXRuntime.new()
		local log = {}
		rt:delay(0.2, function()
			table.insert(log, "b")
		end)
		rt:delay(0.1, function()
			table.insert(log, "a")
		end)
		local cancelled = rt:delay(0.15, function()
			table.insert(log, "x")
		end)
		rt:cancel(cancelled)
		rt:step(0.05)
		expect(#log).toBe(0)
		rt:step(0.2)
		expect(table.concat(log, "")).toBe("ab")
		expect(rt:timerCount()).toBe(0)
	end)

	T.it("reparte el presupuesto sin perder tiempo y llama a finish", function()
		local rt = VFXRuntime.new({ maxPerFrame = 2 })
		local total = { 0, 0, 0 }
		local finished = 0
		for i = 1, 3 do
			rt:add({
				update = function(_, dt)
					total[i] += dt
					return total[i] < 1
				end,
				finish = function()
					finished += 1
				end,
			})
		end
		for _ = 1, 120 do
			rt:step(1 / 60)
		end
		expect(finished).toBe(3)
		expect(rt:count()).toBe(0)
		-- Cada efecto recibió su tiempo aunque no se actualizara todos los frames
		for i = 1, 3 do
			expect(total[i] >= 1).toBe(true)
		end
	end)

	T.it("cancelOwner y clear terminan lo de un dueño o todo", function()
		local rt = VFXRuntime.new({ maxEffects = 3 })
		local owner = {}
		local finished = 0
		local function effect()
			return {
				update = function()
					return true
				end,
				finish = function()
					finished += 1
				end,
			}
		end
		rt:add(effect(), owner)
		rt:add(effect(), owner)
		rt:add(effect())
		expect(rt:add(effect()) == nil).toBe(true) -- sobre el máximo: se rechaza y se termina
		expect(finished).toBe(1)
		rt:cancelOwner(owner)
		rt:step(0.016)
		expect(rt:count()).toBe(1)
		rt:clear()
		expect(rt:count()).toBe(0)
		expect(finished).toBe(4)
	end)
end)
