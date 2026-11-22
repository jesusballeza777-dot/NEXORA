--!strict
-- Simulación de balance: multiplicadores elementales Genesis (×1,25/×0,85, activos en la
-- config) frente a los originales de la Biblia (×1,5/×0,75). No cambia la config: carga
-- el motor con una copia alterada de Config/Combat. Genera docs/BALANCE_ELEMENTS.md.
-- Uso (desde la raíz): lune run tools/sim/elements
local fs = require("@lune/fs")
local VirtualGame = require("../../tests/lib/VirtualGame")

local base = VirtualGame.get("ReplicatedStorage.Shared.Config.Combat")
local Species = VirtualGame.get("ReplicatedStorage.Shared.Config.Species")
local Encounters = VirtualGame.get("ReplicatedStorage.Shared.Config.Encounters")

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = deepCopy(v)
	end
	return out
end

-- Carga BattleEngine/BattleAI con su propio caché y un Combat sustituido
local function engineWith(element: { [string]: number }): (any, any)
	local combat = deepCopy(base)
	for k, v in pairs(element) do
		combat.Element[k] = v
	end
	local cache: { [any]: any } = {}
	local function req(target: any): any
		if type(target) == "string" then
			return require(target)
		end
		local name = target:GetFullName()
		if string.sub(name, -#"Config.Combat") == "Config.Combat" then
			return combat
		end
		if not string.find(name, "Shared.Domain", 1, true) then
			return VirtualGame.require(target)
		end
		if cache[target] == nil then
			cache[target] = VirtualGame.loadFile(rawget(target, "_file"), target, { require = req })
		end
		return cache[target]
	end
	local domain = VirtualGame.game.ReplicatedStorage.Shared.Domain
	return req(domain.Battle.BattleEngine), req(domain.Battle.BattleAI)
end

local SETS = {
	{
		id = "Genesis",
		label = "Genesis ×1,25 / ×0,85 (activo)",
		element = { Strong = 1.25, Weak = 0.85, Cap = 1.6, Floor = 0.7 },
	},
	{
		id = "Biblia",
		label = "Biblia original ×1,5 / ×0,75",
		element = { Strong = 1.5, Weak = 0.75, Cap = 2.25, Floor = 0.5625 },
	},
}

local function duel(BE: any, AI: any, a: any, b: any, seed: number): number
	local state = BE.new({
		battleId = "E" .. seed,
		seed = seed,
		sides = { { controller = "Player", team = { a } }, { controller = "AI", ai = "Normal", team = { b } } },
	})
	while state.phase ~= "Ended" do
		BE.submit(state, 1, { kind = "Move", moveId = AI.choose(state, 1, "Normal") })
		BE.submit(state, 2, { kind = "Move", moveId = AI.choose(state, 2, "Normal") })
		BE.resolveTurn(state)
	end
	return if state.outcome.winner == 1 then 1 else 0
end

local out = {}
local function w(s: string?)
	table.insert(out, s or "")
end
w("# NEXORA · Simulación de multiplicadores elementales")
w()
w('> Generado por `lune run tools/sim/elements`. Combates sembrados con la IA "Normal" en ambos lados.')
w("> La config activa no cambia: la comparación carga el motor con una copia alterada de `Config/Combat`.")
w()

-- 1) Peso de la ventaja: Comunes de un elemento contra Comunes de otro, mismo nivel
w("## 1. Cuánto decide el elemento (Comunes, Tallado nivel 15, espejo de niveles)")
w()
w("| Juego | Victorias con ventaja | Victorias en neutro | Victorias con desventaja |")
w("|---|---|---|---|")
local ElementChart = VirtualGame.get("ReplicatedStorage.Shared.Domain.ElementChart")
local commons = {}
for _, id in ipairs(Species.Order) do
	local s = Species.ById[id]
	if s.rarity == "Comun" and #s.elements == 1 then
		table.insert(commons, id)
	end
end
for _, set in ipairs(SETS) do
	local BE, AI = engineWith(set.element)
	local buckets = { Strong = { 0, 0 }, Neutral = { 0, 0 }, Weak = { 0, 0 } }
	local seed = 1
	for i, a in ipairs(commons) do
		for j, b in ipairs(commons) do
			if i ~= j then
				local ea, eb = Species.ById[a].elements[1], Species.ById[b].elements[1]
				local cls = ElementChart.classify(ElementChart.single(ea, eb))
				for _ = 1, 4 do
					seed += 1
					local won = duel(
						BE,
						AI,
						{ speciesId = a, form = "Tallado", level = 15 },
						{ speciesId = b, form = "Tallado", level = 15 },
						seed
					)
					buckets[cls][1] += won
					buckets[cls][2] += 1
				end
			end
		end
	end
	local function pct(b: { number }): string
		return if b[2] > 0 then string.format("%d %% (%d)", math.floor(b[1] / b[2] * 100 + 0.5), b[2]) else "—"
	end
	w(string.format("| %s | %s | %s | %s |", set.label, pct(buckets.Strong), pct(buckets.Neutral), pct(buckets.Weak)))
end
w()
w("Lectura: cuanto más se separan las columnas, más decide el elemento frente al nivel y la estrategia.")
w()

-- 2) Iniciales en el Acto I: cada inicial solo, al nivel recomendado de cada etapa de combate
w("## 2. Cada inicial, solo, al nivel recomendado de las etapas del Acto I")
w()
w("| Juego | Kuachi (Fuego) | Xolumi (Agua) | Teselo (Tierra) |")
w("|---|---|---|---|")
local starters = { "kuachi", "xolumi", "teselo" }
for _, set in ipairs(SETS) do
	local BE, AI = engineWith(set.element)
	local cells = {}
	for _, st in ipairs(starters) do
		local wins, total = 0, 0
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			if enc.stageType ~= "Tesoro" and enc.stageType ~= "Jefe" then
				local lvl = enc.recommendedLevel
				local mine = { speciesId = st, form = if lvl >= 12 then "Tallado" else "Brote", level = lvl }
				for k = 1, 10 do
					local foes = {}
					for _, opp in ipairs(enc.opponents) do
						local sid = opp.speciesId
						if not sid then
							sid = (opp.byStarterElement :: any)[Species.ById[st].elements[1]]
						end
						table.insert(foes, {
							speciesId = sid,
							form = opp.form,
							level = opp.level,
							isOpaco = true,
							modifier = opp.modifier,
							rootHeal = if opp.rooted then 0.05 else nil,
						})
					end
					local state = BE.new({
						battleId = id .. k,
						seed = k * 7919 + #id,
						sides = {
							{ controller = "Player", team = { mine } },
							{ controller = "AI", ai = enc.ai, team = foes },
						},
					})
					while state.phase ~= "Ended" do
						BE.submit(state, 1, { kind = "Move", moveId = AI.choose(state, 1, "Normal") })
						BE.submit(state, 2, { kind = "Move", moveId = AI.choose(state, 2, enc.ai) })
						BE.resolveTurn(state)
					end
					wins += if state.outcome.winner == 1 then 1 else 0
					total += 1
				end
			end
		end
		table.insert(cells, string.format("%d %%", math.floor(wins / total * 100 + 0.5)))
	end
	w(string.format("| %s | %s |", set.label, table.concat(cells, " | ")))
end
w()
w("Las etapas con 2–3 rivales se juegan con un solo monstruo para aislar el efecto del elemento;")
w("con equipo completo la tasa real es mayor. Recomendación vigente: mantener Genesis (D-001) mientras")
w("estas tablas muestren menos dependencia del inicial elegido; revisar con datos de jugadores.")
fs.writeFile("docs/BALANCE_ELEMENTS.md", table.concat(out, "\n") .. "\n")
print("docs/BALANCE_ELEMENTS.md generado")
