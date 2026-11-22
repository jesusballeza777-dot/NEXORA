--!strict
-- Utilidades compartidas por las pruebas de integración de la Fase 2: reloj simulado,
-- tutorial completo y combates jugados en el servidor con la política "Normal".
-- Uso en un spec:  local Play = harness.require("./Play")(harness)

return function(harness: any)
	local Actions = harness.get("ServerScriptService.Server.Domain.Actions")
	local ProfileSchema = harness.get("ServerScriptService.Server.Domain.ProfileSchema")
	local EncounterRules = harness.get("ServerScriptService.Server.Domain.EncounterRules")
	local BattleEngine = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
	local BattleAI = harness.get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")

	local Play = {}
	Play.now = 1_800_000_000

	function Play.advance(seconds: number)
		Play.now += seconds
	end

	function Play.ctx(extra: { [string]: any }?): any
		local c = { now = Play.now }
		if extra then
			for k, v in pairs(extra) do
				c[k] = v
			end
		end
		return c
	end

	-- Perfil nuevo con el tutorial terminado hasta "FirstBattle"
	function Play.tutorialProfile(userId: number, eggId: string?): (any, string)
		local p = ProfileSchema.new(userId, Play.now)
		Actions.onLoad(p, Play.ctx())
		Actions.finishIntro(p, true, Play.ctx())
		local chosen = Actions.chooseStarter(p, eggId or "EggBrasa", Play.ctx())
		assert(chosen.ok, "sin inicial: " .. tostring(chosen.err))
		local petId = chosen.data.petId
		Actions.ackHatch(p, Play.ctx())
		Actions.visitHome(p, Play.ctx())
		Actions.place(p, petId, 1, Play.ctx())
		Actions.collect(p, Play.ctx())
		Actions.feed(p, petId, "RacionBasica", Play.ctx())
		Actions.play(p, petId, Play.ctx())
		return p, petId
	end

	-- Combate completo decidido por el servidor; devuelve el Result y si ganó
	function Play.encounter(
		p: any,
		encounterId: string,
		battleId: string,
		seed: number,
		policy: any?
	): (any, boolean, any)
		local can = Actions.canStartEncounter(p, encounterId)
		assert(can.ok, "no puede empezar " .. encounterId .. ": " .. tostring(can.err))
		Actions.markBattleStarted(p, encounterId, Play.ctx())
		local state = BattleEngine.new(EncounterRules.buildSetup(p, encounterId, battleId, seed))
		local guard = 0
		while state.phase ~= "Ended" do
			guard += 1
			assert(guard < 200, "combate sin fin")
			local move = if policy then policy(state) else BattleAI.choose(state, 1, "Normal")
			assert(BattleEngine.submit(state, 1, { kind = "Move", moveId = move }))
			assert(
				BattleEngine.submit(state, 2, { kind = "Move", moveId = BattleAI.choose(state, 2, state.sides[2].ai) })
			)
			BattleEngine.resolveTurn(state)
		end
		local won = state.outcome.winner == 1
		local r = Actions.finishEncounter(
			p,
			encounterId,
			battleId,
			won,
			state.turn,
			EncounterRules.participantsFor(p, encounterId),
			Play.ctx(),
			state.outcome.reason,
			BattleEngine.summary(state)
		)
		return r, won, state
	end

	-- Sube a un monstruo directamente (atajo de pruebas, no pasa por comida)
	function Play.boost(p: any, petId: string, level: number, form: string?)
		local pet = p.pets[petId]
		pet.level = level
		pet.xp = 0
		if form then
			pet.form = form
		end
	end

	return Play
end
