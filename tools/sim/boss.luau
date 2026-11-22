--!strict
-- Simulación de balance del jefe de un acto (Fase 2). Uso: lune run tools/sim/boss [nivel] [forma]
-- Imprime tasa de victoria y turnos medios de un equipo de 3 iniciales contra el Ser Sagrado.
local process = require("@lune/process")
local VirtualGame = require("../../tests/lib/VirtualGame")
local BattleEngine = VirtualGame.get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
local BattleAI = VirtualGame.get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")
local level = tonumber(process.args[1]) or 15
local form = process.args[2] or "Tallado"
local bossLevel = tonumber(process.args[3]) or 15
-- "real": inicial Tallado + dos Brotes 3 niveles por debajo (equipo típico al llegar al jefe)
local real = process.args[4] == "real"
local N = 200
local wins, turns, phase2 = 0, 0, 0
for seed = 1, N do
	local state = BattleEngine.new({
		battleId = "S" .. seed,
		seed = seed * 7919,
		sides = {
			{
				controller = "Player",
				team = if real
					then {
						{ speciesId = "kuachi", form = "Tallado", level = level },
						{ speciesId = "agavo", form = "Brote", level = level - 3 },
						{ speciesId = "zizi", form = "Brote", level = level - 3 },
					}
					else {
						{ speciesId = "kuachi", form = form, level = level },
						{ speciesId = "xolumi", form = form, level = level - 1 },
						{ speciesId = "teselo", form = form, level = level - 1 },
					},
			},
			{
				controller = "AI",
				ai = "Normal",
				team = {
					{
						speciesId = "copalia",
						guardianId = "copalia",
						form = "Tallado",
						level = bossLevel,
						isOpaco = true,
					},
				},
			},
		},
	})
	while state.phase ~= "Ended" do
		BattleEngine.submit(state, 1, { kind = "Move", moveId = BattleAI.choose(state, 1, "Normal") })
		BattleEngine.submit(state, 2, { kind = "Move", moveId = BattleAI.choose(state, 2, "Normal") })
		BattleEngine.resolveTurn(state)
	end
	if state.outcome.winner == 1 then
		wins += 1
	end
	turns += state.turn
	if BattleEngine.active(state, 2).phaseIndex > 1 then
		phase2 += 1
	end
end
print(
	string.format(
		(if real then "[real] " else "")
			.. "Copalia nv "
			.. bossLevel
			.. " vs 3 %s nv %d: victoria %.0f %% · turnos medios %.1f · fase 2 alcanzada %.0f %%",
		form,
		level,
		wins / N * 100,
		turns / N,
		phase2 / N * 100
	)
)
