--!strict
-- Combate PvE autoritativo. El servidor:
-- * crea la batalla (id y semilla propios), elige la acción del Opaco y resuelve;
-- * valida battleId y número de turno (control de secuencia, sin duplicados);
-- * aplica el resultado al perfil una sola vez (EncounterRules: "battle:<id>");
-- * descarta la batalla sin recompensa si el jugador se desconecta.
-- El cliente solo envía "quiero usar el movimiento X en el turno N".

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Contract = require(Shared.Net.Contract)
local BattleEngine = require(Shared.Domain.Battle.BattleEngine)
local BattleAI = require(Shared.Domain.Battle.BattleAI)

local Server = script.Parent.Parent
local Actions = require(Server.Domain.Actions)
local EncounterRules = require(Server.Domain.EncounterRules)
local Log = require(Server.Util.Log).scope("Battle")

type Session = {
	state: BattleEngine.BattleState,
	encounterId: string,
	battleId: string,
	participants: { string },
	startedAt: number,
}

local BattleService = {}

local active: { [Player]: Session } = {}
local rng = Random.new()
local data: any
local analytics: any
local push: RemoteEvent

local function fire(player: Player, kind: string, payload: any)
	push:FireClient(player, kind, payload)
end

local function start(player: Player, encounterId: string)
	if active[player] then
		return { ok = false, err = "AlreadyInBattle" }
	end
	local session = data.get(player)
	if not session then
		return { ok = false, err = "ProfileNotReady" }
	end
	local p = session.data
	local can = Actions.canStartEncounter(p, encounterId)
	if not can.ok then
		return can
	end
	local battleId = HttpService:GenerateGUID(false)
	local seed = rng:NextInteger(1, 2147483646)
	local state = BattleEngine.new(EncounterRules.buildSetup(p, encounterId, battleId, seed))
	active[player] = {
		state = state,
		encounterId = encounterId,
		battleId = battleId,
		participants = table.clone(p.team),
		startedAt = os.time(),
	}
	for _, e in ipairs(Actions.markBattleStarted(p, encounterId, data.ctx(player))) do
		analytics.log(player, e.name, e.fields)
	end
	local snapshot = BattleEngine.snapshot(state)
	snapshot.encounterId = encounterId
	snapshot.options = BattleEngine.availableMoves(state, 1)
	snapshot.intro = state.log
	fire(player, Contract.Push.BattleStart, snapshot)
	return { ok = true, data = { battleId = battleId } }
end

local function conclude(player: Player, s: Session)
	local outcome = s.state.outcome :: any
	local won = outcome.winner == 1
	-- Se libera antes de aplicar el resultado: un error nunca deja al jugador "en combate"
	active[player] = nil
	local okRun, result = pcall(data.run, player, function(p, ctx)
		return Actions.finishEncounter(
			p,
			s.encounterId,
			s.battleId,
			won,
			s.state.turn,
			s.participants,
			ctx,
			outcome.reason
		)
	end)
	if not okRun then
		Log.error("No se pudo aplicar el combate %s: %s", s.battleId, tostring(result))
		result = { ok = false, err = "ServerError" }
	end
	fire(player, Contract.Push.BattleEnd, {
		battleId = s.battleId,
		encounterId = s.encounterId,
		won = won,
		reason = outcome.reason,
		turns = s.state.turn,
		result = if result.ok
			then {
				rewardId = result.data.rewardId,
				firstClear = result.data.firstClear,
				capped = result.data.capped,
				pets = result.data.pets,
			}
			else nil,
	})
end

local function act(player: Player, battleId: string, turn: number, moveId: string)
	local s = active[player]
	if not s or s.battleId ~= battleId then
		return { ok = false, err = "NoSuchBattle" }
	end
	if turn ~= s.state.turn + 1 then
		return { ok = false, err = "BadTurn" }
	end
	local ok, reason = BattleEngine.submit(s.state, 1, { kind = "Move", moveId = moveId })
	if not ok then
		return { ok = false, err = reason }
	end
	local aiMove = BattleAI.choose(s.state, 2, s.state.sides[2].ai)
	BattleEngine.submit(s.state, 2, { kind = "Move", moveId = aiMove })
	local events = BattleEngine.resolveTurn(s.state)
	local snapshot = BattleEngine.snapshot(s.state)
	snapshot.options = if s.state.phase == "Ended" then {} else BattleEngine.availableMoves(s.state, 1)
	fire(player, Contract.Push.BattleTurn, { battleId = battleId, events = events, snapshot = snapshot })
	if s.state.phase == "Ended" then
		conclude(player, s)
	end
	return { ok = true }
end

local function forfeit(player: Player, battleId: string)
	local s = active[player]
	if not s or s.battleId ~= battleId then
		return { ok = false, err = "NoSuchBattle" }
	end
	BattleEngine.submit(s.state, 1, { kind = "Forfeit" })
	BattleEngine.submit(s.state, 2, { kind = "Move", moveId = BattleAI.choose(s.state, 2, s.state.sides[2].ai) })
	local events = BattleEngine.resolveTurn(s.state)
	fire(
		player,
		Contract.Push.BattleTurn,
		{ battleId = battleId, events = events, snapshot = BattleEngine.snapshot(s.state) }
	)
	conclude(player, s)
	return { ok = true }
end

function BattleService.init(deps: { data: any, gateway: any, analytics: any })
	data = deps.data
	analytics = deps.analytics
	push = deps.gateway.push
	deps.gateway.register("Battle.Start", start)
	deps.gateway.register("Battle.Act", act)
	deps.gateway.register("Battle.Forfeit", forfeit)
end

function BattleService.start()
	Players.PlayerRemoving:Connect(function(player)
		if active[player] then
			Log.info("Combate abandonado por desconexión (%d): sin resultado", player.UserId)
			active[player] = nil
		end
	end)
end

function BattleService.isInBattle(player: Player): boolean
	return active[player] ~= nil
end

return BattleService
