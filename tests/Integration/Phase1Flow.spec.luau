--!strict
-- Prueba de integración del vertical slice: recorre el flujo de aceptación de la
-- Fase 1 con el mismo código de dominio que usan los servicios de Roblox, y la
-- persistencia con bloqueo de sesión sobre un backend en memoria.

local T = harness.T
local expect = T.expect
local Actions = harness.get("ServerScriptService.Server.Domain.Actions")
local ProfileStore = harness.get("ServerScriptService.Server.Persistence.ProfileStore")
local MemoryBackend = harness.get("ServerScriptService.Server.Persistence.MemoryBackend")
local ProfileSchema = harness.get("ServerScriptService.Server.Domain.ProfileSchema")
local EncounterRules = harness.get("ServerScriptService.Server.Domain.EncounterRules")
local BattleEngine = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
local BattleAI = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")
local Species = harness.get("ReplicatedStorage.Shared.Config.Species")
local Onboarding = harness.get("ReplicatedStorage.Shared.Config.Onboarding")

local clockValue = 1_800_000_000
local function clock()
	return clockValue
end
local function advance(seconds: number)
	clockValue += seconds
end
local function ctx()
	return { now = clockValue }
end

local function newStore(backend, jobId)
	return ProfileStore.new({ backend = backend, jobId = jobId, clock = clock })
end

-- Juega un combate completo en el servidor y aplica el resultado.
local function playEncounter(p, encounterId: string, battleId: string, seed: number)
	local can = Actions.canStartEncounter(p, encounterId)
	assert(can.ok, "no puede empezar: " .. tostring(can.err))
	Actions.markBattleStarted(p, encounterId, ctx())
	local state = BattleEngine.new(EncounterRules.buildSetup(p, encounterId, battleId, seed))
	while state.phase ~= "Ended" do
		assert(BattleEngine.submit(state, 1, { kind = "Move", moveId = BattleAI.choose(state, 1, "Normal") }))
		assert(BattleEngine.submit(state, 2, { kind = "Move", moveId = BattleAI.choose(state, 2, state.sides[2].ai) }))
		BattleEngine.resolveTurn(state)
	end
	local won = state.outcome.winner == 1
	return Actions.finishEncounter(p, encounterId, battleId, won, state.turn, table.clone(p.team), ctx()), won
end

local function runTutorial(p, eggId: string)
	expect(Actions.onLoad(p, ctx()).ok).toBe(true)
	expect(p.onboarding.step).toBe("Intro")
	expect(Actions.finishIntro(p, true, ctx()).ok).toBe(true)
	expect(p.onboarding.step).toBe("ChooseEgg")

	local chosen = Actions.chooseStarter(p, eggId, ctx())
	expect(chosen.ok).toBe(true)
	local petId = chosen.data.petId
	expect(p.companionPetId).toBe(petId)
	expect(p.onboarding.step).toBe("Hatch")
	expect(Actions.ackHatch(p, ctx()).ok).toBe(true)
	expect(p.onboarding.step).toBe("MeetHome")

	local home = Actions.visitHome(p, ctx())
	expect(home.data.gifted).toBe(true)
	expect(p.lots.Hogar.unlocked).toBe(true)
	expect(p.items.RacionBasica).toBe(3)
	expect(p.onboarding.step).toBe("PlaceInHabitat")

	expect(Actions.place(p, petId, 1, ctx()).ok).toBe(true)
	local collected = Actions.collect(p, ctx())
	expect(collected.data.coins).toBe(50) -- primera recogida del tutorial
	expect(p.onboarding.step).toBe("FirstFeed")

	local fed = Actions.feed(p, petId, "RacionBasica", ctx())
	expect(fed.ok).toBe(true)
	expect(fed.data.xpGained).toBe(150)
	expect(p.pets[petId].level).toBe(2)
	expect(p.onboarding.step).toBe("FirstBond")

	local played = Actions.play(p, petId, ctx())
	expect(played.ok).toBe(true)
	expect(p.pets[petId].bond).toBe(1)
	expect(p.onboarding.step).toBe("FirstBattle")
	return petId
end

T.describe("Fase 1 · flujo completo por inicial", function()
	for _, egg in ipairs(Onboarding.StarterEggs) do
		T.it(string.format("cuenta nueva con %s llega al final del tutorial", egg.speciesId), function()
			local backend = MemoryBackend.new()
			local store = newStore(backend, "server-A")
			local session = assert(store:load(1000 + #egg.eggId))
			local p = session.data
			expect(session.isNew).toBe(true)

			local petId = runTutorial(p, egg.eggId)
			expect(p.pets[petId].speciesId).toBe(egg.speciesId)

			-- Primer combate: el servidor decide el resultado. Con política sensata
			-- el inicial de nivel 2 vence al Opaco tutorial (probado también en Unit).
			local finished, won = playEncounter(p, "valle_r1_e1", "B1", 12345)
			expect(won).toBe(true)
			expect(finished.ok).toBe(true)
			local rewardId = finished.data.rewardId
			expect(rewardId).toBe("battle:B1")
			expect(p.onboarding.step).toBe("ClaimReward")

			local before = p.currencies.Monedas
			local claimed = Actions.claimReward(p, rewardId, ctx())
			expect(claimed.ok).toBe(true)
			expect(p.currencies.Monedas).toBe(before + 200)
			expect(p.currencies.Gemas).toBe(10)
			expect(p.items.RacionBioma).toBe(2)
			expect(p.onboarding.completed).toBe(true)
			expect(p.firsts.tutorial_completed ~= nil).toBe(true)

			-- No se puede reclamar dos veces
			local again = Actions.claimReward(p, rewardId, ctx())
			expect(again.ok).toBe(false)
			expect(again.err).toBe("AlreadyClaimed")

			expect(store:save(session, true)).toBe(true)
		end)
	end
end)

T.describe("Fase 1 · persistencia, reconexión y duplicados", function()
	T.it("desconectar y volver conserva todo sin duplicar monstruos ni recompensas", function()
		local backend = MemoryBackend.new()
		local storeA = newStore(backend, "server-A")
		local s1 = assert(storeA:load(42))
		local p = s1.data
		local petId = runTutorial(p, "EggBrasa")
		local finished = playEncounter(p, "valle_r1_e1", "B-persist", 777)
		local rewardId = finished.data.rewardId
		-- Se desconecta ANTES de reclamar: la recompensa queda pendiente y persistida
		expect(storeA:save(s1, true)).toBe(true)

		advance(3600)
		local storeB = newStore(backend, "server-B")
		local s2 = assert(storeB:load(42))
		local q = s2.data
		expect(s2.isNew).toBe(false)
		Actions.onLoad(q, ctx())
		local count = 0
		for _ in pairs(q.pets) do
			count += 1
		end
		expect(count).toBe(1)
		expect(q.pets[petId].level).toBe(p.pets[petId].level)
		expect(q.rewards.pending[rewardId] ~= nil).toBe(true)
		expect(q.onboarding.step).toBe("ClaimReward")

		expect(Actions.claimReward(q, rewardId, ctx()).ok).toBe(true)
		-- El mismo combate no puede aplicarse dos veces
		local dup = EncounterRules.applyResult(q, "valle_r1_e1", "B-persist", true, { petId }, ctx())
		expect(dup.ok).toBe(false)
		expect(dup.err).toBe("ResultAlreadyApplied")
		-- Elegir otro huevo inicial no está permitido
		expect(Actions.chooseStarter(q, "EggBarro", ctx()).ok).toBe(false)
		expect(storeB:save(s2, true)).toBe(true)
	end)

	T.it("un segundo servidor no puede abrir un perfil bloqueado", function()
		local backend = MemoryBackend.new()
		local storeA = newStore(backend, "server-A")
		local storeB = ProfileStore.new({ backend = backend, jobId = "server-B", clock = clock, maxLoadAttempts = 2 })
		local sA = assert(storeA:load(7))
		local sB, err = storeB:load(7)
		expect(sB).toBe(nil)
		expect(err).toBe("SessionLocked")
		-- A sigue siendo dueño y guarda sin problemas
		sA.data.currencies.Monedas = 999
		expect(storeA:save(sA, false)).toBe(true)
	end)

	T.it("si otro servidor roba un bloqueo caducado, el antiguo dueño no sobrescribe", function()
		local backend = MemoryBackend.new()
		local storeA = newStore(backend, "server-A")
		local storeB = newStore(backend, "server-B")
		local sA = assert(storeA:load(8))
		sA.data.currencies.Monedas = 10
		expect(storeA:save(sA, false)).toBe(true)
		advance(4000) -- el servidor A dejó de latir más de 30 min
		local sB = assert(storeB:load(8))
		sB.data.currencies.Monedas = 500
		expect(storeB:save(sB, false)).toBe(true)
		-- El servidor A "despierta" e intenta guardar datos viejos
		sA.data.currencies.Monedas = 1
		local ok, err = storeA:save(sA, false)
		expect(ok).toBe(false)
		expect(err).toBe("LockLost")
		expect(backend:peek("Player_8").data.currencies.Monedas).toBe(500)
	end)

	T.it("reintenta ante fallos transitorios del almacén", function()
		local backend = MemoryBackend.new()
		backend.failNext = 2
		local store = newStore(backend, "server-A")
		local s = store:load(9)
		expect(s ~= nil).toBe(true)
	end)

	T.it("nunca sobrescribe un perfil corrupto", function()
		local backend = MemoryBackend.new()
		backend.store.Player_11 = {
			meta = {},
			data = { schemaVersion = 1, userId = 11, currencies = { Monedas = -50 }, pets = {}, lots = {} },
		}
		local store = newStore(backend, "server-A")
		local s, err = store:load(11)
		expect(s).toBe(nil)
		expect(string.find(err, "InvalidProfile") ~= nil).toBe(true)
		expect(backend:peek("Player_11").data.currencies.Monedas).toBe(-50)
	end)

	T.it("las migraciones se aplican en orden y rellenan campos nuevos", function()
		local legacy = { schemaVersion = 0, userId = 5, currencies = { Monedas = 30 }, pets = {} }
		local calls = {}
		local migrations = {
			[0] = function(d)
				table.insert(calls, 0)
				d.items = { RacionBasica = 1 }
				return d
			end,
		}
		local migrated = ProfileSchema.migrate(legacy, clockValue, migrations)
		expect(migrated.schemaVersion).toBe(ProfileSchema.CURRENT_VERSION)
		expect(calls[1]).toBe(0)
		expect(migrated.currencies.Monedas).toBe(30)
		expect(migrated.currencies.Gemas).toBe(0)
		expect(migrated.items.RacionBasica).toBe(1)
		expect(migrated.lots.Hogar ~= nil).toBe(true)
		expect(ProfileSchema.validate(migrated)).toBe(true)
	end)
end)

T.describe("Fase 1 · reglas de servidor", function()
	local function freshTutorial()
		local p = ProfileSchema.new(77, clockValue)
		local petId = runTutorial(p, "EggGreca")
		return p, petId
	end

	T.it("no se puede alimentar sin comida ni a un monstruo ajeno", function()
		local p, petId = freshTutorial()
		expect(Actions.feed(p, "U999-1", "RacionBasica", ctx()).err).toBe("PetNotOwned")
		p.items.RacionBasica = nil
		expect(Actions.feed(p, petId, "RacionBasica", ctx()).err).toBe("NoFood")
	end)

	T.it("jugar tiene enfriamiento", function()
		local p, petId = freshTutorial()
		local r = Actions.play(p, petId, ctx())
		expect(r.ok).toBe(false)
		expect(r.err).toBe("Cooldown")
		advance(60)
		expect(Actions.play(p, petId, ctx()).ok).toBe(true)
	end)

	T.it("la producción del hábitat respeta el tope de 8 h y no se duplica", function()
		local p = freshTutorial()
		advance(20 * 3600)
		local r = Actions.collect(p, ctx())
		-- Brote común: 30/h × 50 % = 15/h; Teselo es nativo del Valle Copal (+10 %):
		-- 16.5/h con tope de 8 h = 132
		expect(r.data.coins).toBe(132)
		local again = Actions.collect(p, ctx())
		expect(again.data.coins).toBe(0)
	end)

	T.it("comprar comida descuenta Monedas y no permite saldo negativo", function()
		local p = freshTutorial()
		p.currencies.Monedas = 120
		expect(Actions.buyFood(p, "RacionBasica", 2, ctx()).ok).toBe(true)
		expect(p.currencies.Monedas).toBe(20)
		local r = Actions.buyFood(p, "RacionBasica", 1, ctx())
		expect(r.err).toBe("NotEnoughMonedas")
		expect(Actions.buyFood(p, "RacionDorada", 1, ctx()).err).toBe("NotForSale")
		expect(Actions.buyFood(p, "RacionBasica", 0, ctx()).err).toBe("BadQuantity")
	end)

	T.it("el combate de la etapa 2 exige superar la etapa 1", function()
		local p = freshTutorial()
		expect(Actions.canStartEncounter(p, "valle_r1_e2").err).toBe("EncounterLocked")
	end)

	T.it("las repeticiones pagan 25 % con tope diario de 10", function()
		local p, petId = freshTutorial()
		p.pets[petId].level = 20
		local first = playEncounter(p, "valle_r1_e1", "R0", 1)
		Actions.claimReward(p, first.data.rewardId, ctx())
		local rewarded = 0
		for i = 1, 12 do
			local r = playEncounter(p, "valle_r1_e1", "R" .. i, i)
			if r.data.rewardId then
				rewarded += 1
				expect(p.rewards.pending[r.data.rewardId].currencies.Monedas).toBe(50)
				Actions.claimReward(p, r.data.rewardId, ctx())
			else
				expect(r.data.capped).toBe(true)
			end
		end
		expect(rewarded).toBe(10)
	end)

	T.it("tallar exige nivel 12 y 2 corazones de Vínculo; cambia la forma", function()
		local p, petId = freshTutorial()
		expect(Actions.evolve(p, petId, ctx()).err).toBe("LevelTooLow")
		p.pets[petId].level = 12
		expect(Actions.evolve(p, petId, ctx()).err).toBe("BondTooLow")
		p.pets[petId].bond = 8
		local r = Actions.evolve(p, petId, ctx())
		expect(r.ok).toBe(true)
		expect(p.pets[petId].form).toBe("Tallado")
		expect(Species.ById[p.pets[petId].speciesId].talladoName).toBe("Mitlaxis")
	end)

	T.it("un monstruo no puede ocupar dos slots", function()
		local p, petId = freshTutorial()
		expect(Actions.place(p, petId, 2, ctx()).err).toBe("AlreadyPlaced")
		expect(Actions.remove(p, 1, ctx()).ok).toBe(true)
		expect(Actions.place(p, petId, 4, ctx()).ok).toBe(true)
		expect(Actions.place(p, petId, 9, ctx()).err).toBe("BadSlot")
	end)
end)

T.describe("Revisión: huir y consolación", function()
	T.it("retirarse de un combate no da XP (no es una granja)", function()
		local p = ProfileSchema.new(91, clockValue)
		local petId = runTutorial(p, "EggBrasa")
		local before = { level = p.pets[petId].level, xp = p.pets[petId].xp }
		for i = 1, 20 do
			local r = Actions.finishEncounter(p, "valle_r1_e1", "F" .. i, false, 1, { petId }, ctx(), "Forfeit")
			expect(r.ok).toBe(true)
		end
		expect(p.pets[petId].level).toBe(before.level)
		expect(p.pets[petId].xp).toBe(before.xp)
	end)

	T.it("la XP de consolación por derrota tiene tope diario", function()
		local p = ProfileSchema.new(92, clockValue)
		local petId = runTutorial(p, "EggGreca")
		local granted = 0
		for i = 1, 15 do
			local r = Actions.finishEncounter(p, "valle_r1_e1", "L" .. i, false, 3, { petId }, ctx(), "Defeat")
			if r.data.pets then
				granted += 1
			end
		end
		expect(granted).toBe(10)
		advance(86400)
		local r = Actions.finishEncounter(p, "valle_r1_e1", "L-next-day", false, 3, { petId }, ctx(), "Defeat")
		expect(r.data.pets ~= nil).toBe(true)
	end)
end)
