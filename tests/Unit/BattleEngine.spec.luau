--!strict
local T = harness.T
local expect = T.expect
local BattleEngine = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
local BattleAI = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")
local ElementChart = harness.get("ReplicatedStorage.Shared.Domain.ElementChart")
local Encounters = harness.get("ReplicatedStorage.Shared.Config.Encounters")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")

local function duel(seed: number, a: { [string]: any }, b: { [string]: any }, aiB: string?)
	return BattleEngine.new({
		battleId = "T" .. seed,
		seed = seed,
		sides = {
			{ controller = "Player", team = { a } },
			{ controller = "AI", ai = aiB or "Normal", team = { b } },
		},
	})
end

-- Política simple de jugador para simulaciones: Nexo > especial con Savia > mejor básico.
local function playerPolicy(state)
	return BattleAI.choose(state, 1, "Normal")
end

local function runToEnd(state, policy, aiProfile)
	local guard = 0
	while state.phase ~= "Ended" do
		guard += 1
		assert(guard < 100, "combate sin fin")
		local p = policy(state)
		assert(BattleEngine.submit(state, 1, { kind = "Move", moveId = p }))
		local ai = BattleAI.choose(state, 2, aiProfile)
		assert(BattleEngine.submit(state, 2, { kind = "Move", moveId = ai }))
		BattleEngine.resolveTurn(state)
	end
	return state
end

T.describe("Multiplicadores elementales (hipótesis beta ×1.25/×0.85)", function()
	T.it("Fuego contra Flora es fuerte y Flora contra Fuego es débil", function()
		expect(ElementChart.multiplier("Fuego", { "Flora" })).toBeNear(1.25)
		expect(ElementChart.multiplier("Flora", { "Fuego" })).toBeNear(0.85)
		expect(ElementChart.multiplier("Fuego", { "Tierra" })).toBeNear(1.0)
	end)

	T.it("se multiplican por elemento del defensor con tope ×1.6 y suelo ×0.7", function()
		-- Aire contra Flora/Tierra (Castorre): 1.25 × 1.25 = 1.5625
		expect(ElementChart.multiplier("Aire", { "Flora", "Tierra" })).toBeNear(1.5625)
		-- Contra 3 elementos fuertes el tope corta en 1.6
		expect(ElementChart.multiplier("Agua", { "Fuego", "Metal", "Fuego" })).toBeNear(1.6)
		-- Suelo: Fuego contra Agua/Mente/Agua = 0.85^3 = 0.614 → 0.7
		expect(ElementChart.multiplier("Fuego", { "Agua", "Mente", "Agua" })).toBeNear(0.7)
	end)

	T.it("el Golpe Nexo nunca baja de ×0.85", function()
		expect(ElementChart.multiplier("Fuego", { "Agua", "Mente" }, true)).toBeNear(0.85)
	end)
end)

T.describe("Fórmula de daño (p. 40)", function()
	T.it("a nivel 50 con ATQ = DEF un básico de 40 hace ≈40 (sin afinidad)", function()
		local state = duel(
			7,
			{ speciesId = "nex", form = "Tallado", level = 50 },
			{ speciesId = "nex", form = "Tallado", level = 50 }
		)
		local a = BattleEngine.active(state, 1)
		local b = BattleEngine.active(state, 2)
		-- Golpe sin elemento: neutral y sin afinidad
		local fake = { id = "X", name = "X", kind = "Basic", power = 40, effects = {}, text = "" }
		local roll = BattleEngine.computeDamage(state, a, b, fake :: any, 40)
		expect(roll.amount >= 38 and roll.amount <= 63).toBe(true) -- 40 × variación (±5 %) × crítico posible
	end)

	T.it("con ventaja elemental hace más daño que sin ella (misma semilla)", function()
		local function hit(defSpecies)
			local s = duel(
				11,
				{ speciesId = "kuachi", form = "Brote", level = 5 },
				{ speciesId = defSpecies, form = "Brote", level = 5 }
			)
			local roll = BattleEngine.computeDamage(
				s,
				BattleEngine.active(s, 1),
				BattleEngine.active(s, 2),
				harness.get("ReplicatedStorage.Shared.Config.Abilities").ById.ZarpaDeBrasa,
				45
			)
			return roll.amount
		end
		-- Agavo (Flora, DEF 29) y Comalú (Fuego, DEF 29) tienen la misma DEF y ESE
		expect(hit("agavo")).toBeGreaterThan(hit("comalu"))
	end)

	T.it("equal-level matchups take 3–6 actions (D-002)", function()
		local state = duel(
			3,
			{ speciesId = "kuachi", form = "Brote", level = 8 },
			{ speciesId = "tinco", form = "Brote", level = 8 }
		)
		local a, b = BattleEngine.active(state, 1), BattleEngine.active(state, 2)
		local roll = BattleEngine.computeDamage(
			state,
			a,
			b,
			harness.get("ReplicatedStorage.Shared.Config.Abilities").ById.ZarpaDeBrasa,
			45
		)
		local hits = math.ceil(b.maxHp / roll.amount)
		expect(hits >= 3 and hits <= 6).toBe(true)
	end)
end)

T.describe("Savia y repertorio", function()
	T.it("Kuachi empieza con 1 de Savia por su talento Bolsa de Brasas", function()
		local s = duel(
			1,
			{ speciesId = "kuachi", form = "Brote", level = 1 },
			{ speciesId = "agavo", form = "Brote", level = 1 }
		)
		expect(BattleEngine.active(s, 1).savia).toBe(1)
		expect(BattleEngine.active(s, 2).savia).toBe(0)
	end)

	T.it("no permite especiales sin Savia suficiente", function()
		local s = duel(
			1,
			{ speciesId = "teselo", form = "Brote", level = 1 },
			{ speciesId = "zizi", form = "Brote", level = 1 }
		)
		local ok, reason = BattleEngine.submit(s, 1, { kind = "Move", moveId = "MurallaDeAdobe" })
		expect(ok).toBe(false)
		expect(reason).toBe("NotEnoughSavia")
	end)

	T.it("rechaza jugadas no equipadas y envíos dobles", function()
		local s = duel(
			1,
			{ speciesId = "teselo", form = "Brote", level = 1 },
			{ speciesId = "zizi", form = "Brote", level = 1 }
		)
		local ok, reason = BattleEngine.submit(s, 1, { kind = "Move", moveId = "FogataDelTallador" })
		expect(ok).toBe(false)
		expect(reason).toBe("MoveNotEquipped")
		expect(BattleEngine.submit(s, 1, { kind = "Move", moveId = "Pisoton" })).toBe(true)
		ok, reason = BattleEngine.submit(s, 1, { kind = "Move", moveId = "Pisoton" })
		expect(ok).toBe(false)
		expect(reason).toBe("AlreadySubmitted")
	end)

	T.it("cada básico da +1 de Savia hasta un máximo de 3", function()
		local s = duel(
			5,
			{ speciesId = "teselo", form = "Brote", level = 30 },
			{ speciesId = "zizi", form = "Brote", level = 1 },
			"Tutorial"
		)
		local c = BattleEngine.active(s, 1)
		for _ = 1, 4 do
			if s.phase == "Ended" then
				break
			end
			assert(BattleEngine.submit(s, 1, { kind = "Move", moveId = "LanzaDeBarro" }))
			assert(BattleEngine.submit(s, 2, { kind = "Move", moveId = BattleAI.choose(s, 2, "Tutorial") }))
			BattleEngine.resolveTurn(s)
		end
		expect(c.savia <= 3).toBe(true)
	end)

	T.it("el Golpe Nexo solo se equipa en Tallado nivel 20+", function()
		local brote = BattleEngine.defaultLoadout("kuachi", "Brote", 30)
		local tallado19 = BattleEngine.defaultLoadout("kuachi", "Tallado", 19)
		local tallado20 = BattleEngine.defaultLoadout("kuachi", "Tallado", 20)
		expect(table.find(brote, "FogataDelTallador")).toBe(nil)
		expect(table.find(tallado19, "FogataDelTallador")).toBe(nil)
		expect(table.find(tallado20, "FogataDelTallador") ~= nil).toBe(true)
		-- Repertorio de la ficha de Kuachi (p. 116): 2 básicos, 1 especial y la Firma
		expect(brote).toEqual({ "Chispazo", "ZarpaDeBrasa", "ComalArdiente", "LatigoDeCeniza" })
	end)
end)

T.describe("Determinismo", function()
	T.it("la misma semilla reproduce exactamente el mismo combate", function()
		local function play(seed)
			local s = duel(
				seed,
				{ speciesId = "xolumi", form = "Brote", level = 6 },
				{ speciesId = "barrock", form = "Brote", level = 6 }
			)
			runToEnd(s, playerPolicy, "Normal")
			local parts = {}
			for _, e in ipairs(s.log) do
				table.insert(
					parts,
					string.format(
						"%s:%s:%s",
						tostring(e.t),
						tostring(e.target or e.actor),
						tostring(e.amount or e.move)
					)
				)
			end
			return table.concat(parts, "|")
		end
		expect(play(424242)).toBe(play(424242))
		expect(play(424242) ~= play(99)).toBe(true)
	end)
end)

T.describe("Efectos", function()
	T.it("Muralla de Adobe bloquea el siguiente golpe", function()
		local s = duel(
			21,
			{ speciesId = "teselo", form = "Brote", level = 10 },
			{ speciesId = "zizi", form = "Brote", level = 3 },
			"Tutorial"
		)
		local me = BattleEngine.active(s, 1)
		me.savia = 2
		-- Zizi es más rápido: golpea antes del bloqueo. El bloqueo cubre el turno siguiente.
		BattleEngine.submit(s, 1, { kind = "Move", moveId = "MurallaDeAdobe" })
		BattleEngine.submit(s, 2, { kind = "Move", moveId = "Descarga" })
		BattleEngine.resolveTurn(s)
		local hpAfterFirst = me.hp
		BattleEngine.submit(s, 1, { kind = "Move", moveId = "Pisoton" })
		BattleEngine.submit(s, 2, { kind = "Move", moveId = "Descarga" })
		local events = BattleEngine.resolveTurn(s)
		local blocked = false
		for _, e in ipairs(events) do
			if e.t == "Block" then
				blocked = true
			end
		end
		expect(blocked).toBe(true)
		expect(me.hp).toBe(hpAfterFirst)
	end)

	T.it("la quemadura resta 5 % de los PV al final del turno", function()
		local s = duel(
			2,
			{ speciesId = "kuachi", form = "Brote", level = 10 },
			{ speciesId = "agavo", form = "Brote", level = 10 },
			"Tutorial"
		)
		local foe = BattleEngine.active(s, 2)
		foe.statuses.Burn = 3
		local before = foe.hp
		BattleEngine.submit(s, 1, { kind = "Move", moveId = "ZarpaDeBrasa" })
		BattleEngine.submit(s, 2, { kind = "Move", moveId = "LatigoDeEnredadera" })
		local events = BattleEngine.resolveTurn(s)
		local tick = 0
		for _, e in ipairs(events) do
			if e.t == "StatusTick" and e.target == foe.uid then
				tick = e.amount
			end
		end
		expect(tick).toBe(math.floor(foe.maxHp * 0.05 + 0.5))
		expect(foe.hp < before).toBe(true)
	end)

	T.it("un estado de 1 turno aplicado tras actuar afecta a la siguiente acción", function()
		local s = duel(
			4,
			{ speciesId = "teselo", form = "Brote", level = 10, loadout = { "Pisoton", "ArenaEnLosOjos" } },
			{ speciesId = "zizi", form = "Brote", level = 10 },
			"Tutorial"
		)
		local foe = BattleEngine.active(s, 2)
		-- Teselo (VEL 15) es más lento que Zizi (VEL 29): el rival ya actuó
		assert(BattleEngine.submit(s, 1, { kind = "Move", moveId = "ArenaEnLosOjos" }))
		assert(BattleEngine.submit(s, 2, { kind = "Move", moveId = "Descarga" }))
		BattleEngine.resolveTurn(s)
		local found = false
		for _, m in ipairs(foe.mods) do
			if m.stat == "Precision" then
				found = true
			end
		end
		expect(found).toBe(true)
	end)

	T.it("el Opaco derrotado se restaura (nadie muere en NEXORA)", function()
		local s = duel(
			8,
			{ speciesId = "kuachi", form = "Brote", level = 15 },
			{ speciesId = "agavo", form = "Brote", level = 1, isOpaco = true },
			"Tutorial"
		)
		runToEnd(s, playerPolicy, "Tutorial")
		expect(s.outcome.winner).toBe(1)
		local restored = false
		for _, e in ipairs(s.log) do
			if e.t == "Restored" then
				restored = true
			end
		end
		expect(restored).toBe(true)
	end)

	T.it("rendirse termina el combate y da la victoria al rival", function()
		local s = duel(
			9,
			{ speciesId = "kuachi", form = "Brote", level = 1 },
			{ speciesId = "agavo", form = "Brote", level = 1 }
		)
		BattleEngine.submit(s, 1, { kind = "Forfeit" })
		BattleEngine.submit(s, 2, { kind = "Move", moveId = "LatigoDeEnredadera" })
		BattleEngine.resolveTurn(s)
		expect(s.outcome.winner).toBe(2)
		expect(s.outcome.reason).toBe("Forfeit")
	end)
end)

T.describe("Balance del primer combate (simulación)", function()
	-- El primer Opaco debe ser vencible por un jugador que pulsa cualquier ataque.
	-- El onboarding obliga a alimentar antes del combate (Ración básica = 150 XP), así
	-- que el inicial llega como mínimo a nivel 2. Hallazgo de balance B-005: Xolumi
	-- (Soporte) gana 82 % a nivel 1 y 94 % a nivel 2 con juego aleatorio.
	local enc = Encounters.ById.valle_r1_e1
	for _, starter in ipairs(Species.Starters) do
		T.it(string.format("%s gana ≥ 90 %% eligiendo ataques al azar", starter), function()
			local element = Species.ById[starter].elements[1]
			local foe = enc.opponent.byStarterElement[element]
			local wins, n = 0, 300
			for seed = 1, n do
				local s = duel(
					seed * 7919,
					{ speciesId = starter, form = "Brote", level = 2 },
					{ speciesId = foe, form = "Brote", level = enc.opponent.level, isOpaco = true },
					"Tutorial"
				)
				runToEnd(s, function(st)
					local usable = {}
					for _, opt in ipairs(BattleEngine.availableMoves(st, 1)) do
						if opt.usable then
							table.insert(usable, opt.moveId)
						end
					end
					return usable[st.rng:int(1, #usable)]
				end, "Tutorial")
				if s.outcome.winner == 1 then
					wins += 1
				end
			end
			local rate = wins / n
			if rate < 0.9 then
				error(string.format("tasa de victoria %.1f %%", rate * 100))
			end
		end)
	end

	T.it("los combates del tutorial duran entre 3 y 12 turnos de media", function()
		local total, n = 0, 100
		for seed = 1, n do
			local s = duel(
				seed * 31,
				{ speciesId = "xolumi", form = "Brote", level = 1 },
				{ speciesId = "comalu", form = "Brote", level = 1, isOpaco = true },
				"Tutorial"
			)
			runToEnd(s, playerPolicy, "Tutorial")
			total += s.turn
		end
		local avg = total / n
		expect(avg >= 3 and avg <= 12).toBe(true)
	end)
end)
