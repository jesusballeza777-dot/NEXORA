--!strict
-- Paridad de PERFIL Luau ↔ JS de la vista previa web.
--   lune run tools/web-preview/profile_parity
-- Ejecuta recorridos guionizados (tutorial → huevos → cofres → encargos → Acto I con
-- tesoros, rescates, etapas de 2–3 rivales y Copalia → santuario, repeticiones, derrotas
-- y migración 1→2) con las Actions REALES del servidor y escribe, paso a paso, el perfil
-- resultante en build/web/profile_parity_luau.json.
-- Después:  node tools/web-preview/profile-parity.mjs  repite los mismos pasos con
-- src/domain.js + src/engine.js y exige perfiles idénticos en cada paso.

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local VirtualGame = require("../../tests/lib/VirtualGame")

local ROOT = VirtualGame.ROOT
local get = VirtualGame.get

local Actions = get("ServerScriptService.Server.Domain.Actions")
local ProfileSchema = get("ServerScriptService.Server.Domain.ProfileSchema")
local PetRules = get("ServerScriptService.Server.Domain.PetRules")
local EncounterRules = get("ServerScriptService.Server.Domain.EncounterRules")
local BattleEngine = get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
local BattleAI = get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")
local ElementChart = get("ReplicatedStorage.Shared.Domain.ElementChart")
local Rng = get("ReplicatedStorage.Shared.Domain.Rng")
local Encounters = get("ReplicatedStorage.Shared.Config.Encounters")

local T0 = 1_800_000_000

-- ------------------------------------------------------------------
-- Guiones (los mismos datos los ejecuta profile-parity.mjs)
-- ------------------------------------------------------------------
local function correct(id: string): string
	local enc = Encounters.ById[id]
	for _, el in ipairs(enc.riddle.options) do
		if ElementChart.classify(ElementChart.multiplier(el, { enc.riddle.sealElement }, false)) == "Strong" then
			return el
		end
	end
	error("acertijo sin respuesta: " .. id)
end

local function wrong(id: string): string
	local enc = Encounters.ById[id]
	local right = correct(id)
	for _, el in ipairs(enc.riddle.options) do
		if el ~= right then
			return el
		end
	end
	error("acertijo sin opción errónea: " .. id)
end

-- Id de combate cuya tirada de rescate (10 %) acierta o falla: la tirada es reproducible
local function rescueBattle(prefix: string, encId: string, hit: boolean): string
	local chance = Encounters.ById[encId].rescue.eggChance
	for i = 1, 1000 do
		local id = prefix .. i
		local roll = Rng.new(Rng.seedFromString("rescue:" .. id)):next()
		if (roll < chance) == hit then
			return id
		end
	end
	error("sin id de rescate")
end

local function tutorial(userId: number, egg: string): { any }
	return {
		{ op = "new", userId = userId },
		{ op = "onLoad" },
		{ op = "finishIntro", skipped = true },
		{ op = "chooseStarter", egg = egg },
		{ op = "ackHatch" },
		{ op = "visitHome" },
		{ op = "place", pet = "starter", slot = 1 },
		{ op = "advance", s = 600 },
		{ op = "collect" },
		{ op = "feed", pet = "starter", food = "RacionBasica" },
		{ op = "play", pet = "starter" },
	}
end

local function concat(...: { any }): { any }
	local out = {}
	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			table.insert(out, v)
		end
	end
	return out
end

local journey = concat(tutorial(777, "EggBrasa"), {
	{ op = "encounter", id = "valle_r1_e1", battle = "B1", seed = 11 },
	{ op = "claimAll" },
	-- Cuidados y encargos fáciles (alimentar, jugar, recoger)
	{ op = "buyFood", food = "RacionBasica", qty = 3 },
	{ op = "feed", pet = "starter", food = "RacionBasica" },
	{ op = "feed", pet = "starter", food = "RacionBasica" },
	{ op = "feed", pet = "starter", food = "RacionBasica" },
	{ op = "advance", s = 60 },
	{ op = "play", pet = "starter" },
	{ op = "advance", s = 60 },
	{ op = "play", pet = "starter" },
	{ op = "advance", s = 3600 },
	{ op = "collect" },
	{ op = "advance", s = 3600 },
	{ op = "collect" },
	{ op = "claimQuests" },
	-- Primer cofre, primer huevo e incubadora con reconexión
	{ op = "boost", pet = "starter", level = 9, bond = 10 },
	{ op = "encounter", id = "valle_r1_e2", battle = "B2", seed = 21 },
	{ op = "claimAll" },
	{ op = "openChests" },
	{ op = "incubate", slot = 1 },
	{ op = "hatch", slot = 1 },
	{ op = "advance", s = 301 },
	{ op = "onLoad" },
	{ op = "hatch", slot = 1 },
	-- Tallado real y equipo de tres
	{ op = "boost", pet = "starter", level = 12 },
	{ op = "evolve", pet = "starter" },
	{ op = "devPet", species = "zunzi", as = "z" },
	{ op = "devPet", species = "xolumi", as = "x" },
	{ op = "boost", pet = "starter", level = 22, form = "Tallado" },
	{ op = "boost", pet = "z", level = 22, form = "Tallado" },
	{ op = "boost", pet = "x", level = 22, form = "Tallado" },
	{ op = "setTeam", pets = { "starter", "z", "x" } },
	-- Región 1
	{ op = "encounter", id = "valle_r1_e3", battle = "B3", seed = 31 },
	{ op = "claimAll" },
	{ op = "treasure", id = "valle_r1_e4", element = wrong("valle_r1_e4") },
	{ op = "treasure", id = "valle_r1_e4", element = correct("valle_r1_e4") },
	{ op = "claimAll" },
	{ op = "openChests" },
	-- Región 2: rescate con huevo, 2 y 3 rivales, élite con un solo monstruo
	{ op = "encounter", id = "valle_r2_e5", battle = rescueBattle("RS", "valle_r2_e5", true), seed = 41 },
	{ op = "claimAll" },
	{ op = "encounter", id = "valle_r2_e6", battle = "B6", seed = 42 },
	{ op = "setTeam", pets = { "starter" } },
	{ op = "encounter", id = "valle_r2_e7", battle = "B7", seed = 43 },
	{ op = "setTeam", pets = { "starter", "z", "x" } },
	{ op = "claimAll" },
	{ op = "encounter", id = "valle_r2_e8", battle = "B8", seed = 44 },
	{ op = "claimAll" },
	-- Región 3 y jefe
	{ op = "treasure", id = "valle_r3_e9", element = correct("valle_r3_e9") },
	{ op = "encounter", id = "valle_r3_e10", battle = rescueBattle("RM", "valle_r3_e10", false), seed = 45 },
	{ op = "encounter", id = "valle_r3_e11", battle = "B11", seed = 46 },
	{ op = "encounter", id = "valle_r3_e12", battle = "B12", seed = 47 },
	{ op = "claimAll" },
	{ op = "encounter", id = "valle_boss", battle = "BOSS", seed = 48 },
	{ op = "claimAll" },
	{ op = "openChests" },
	{ op = "incubate", slot = 1 },
	{ op = "incubate", slot = 2 },
	{ op = "advance", s = 1300 },
	{ op = "hatch", slot = 1 },
	{ op = "hatch", slot = 2 },
	{ op = "claimQuests" },
	-- Santuario
	{ op = "placeDecor", slot = 1, decor = "FarolDeCopal" },
	{ op = "placeDecor", slot = 2, decor = "FarolDeCopal" },
	{ op = "template", id = "Jardin" },
	{ op = "placeDecor", slot = 7, decor = "BancaDeMadera" },
	{ op = "showcase", pets = { "starter", "z" } },
	{ op = "grantCoins", n = 30000 },
	{ op = "buySlot", slot = 3 },
	{ op = "buySlot", slot = 4 },
	{ op = "expand" },
	{ op = "equipTitle", title = "Guardián del Valle" },
})
-- Repeticiones al 25 % hasta el tope diario y nuevo día
for i = 1, 11 do
	table.insert(journey, { op = "encounter", id = "valle_r1_e1", battle = "R" .. i, seed = 60 + i })
	table.insert(journey, { op = "claimAll" })
end
for _, s in ipairs({
	{ op = "advance", s = 86400 },
	{ op = "onLoad" },
	{ op = "encounter", id = "valle_r1_e1", battle = "R12", seed = 80 },
	{ op = "claimAll" },
	{ op = "claimQuests" },
}) do
	table.insert(journey, s)
end

local losses = concat(tutorial(778, "EggBarro"), {
	{ op = "encounter", id = "valle_r1_e1", battle = "F1", seed = 5, forfeit = true },
	{ op = "encounter", id = "valle_r1_e1", battle = "W1", seed = 6 },
	{ op = "claimAll" },
	{ op = "encounter", id = "valle_r1_e3", battle = "L0", seed = 7 },
	{ op = "encounter", id = "valle_r1_e2", battle = "L1", seed = 8 },
	{ op = "encounter", id = "valle_r1_e2", battle = "L2", seed = 9 },
	{ op = "treasure", id = "valle_r1_e4", element = "Agua" },
	{ op = "claimQuests" },
	{ op = "openChests" },
	{ op = "incubate", slot = 1 },
	{ op = "claimAll" },
})

local migration = concat(tutorial(779, "EggGreca"), {
	{ op = "encounter", id = "valle_r1_e1", battle = "M1", seed = 31 },
	{ op = "claimAll" },
	{ op = "legacy" },
	{ op = "onLoad" },
	{ op = "boost", pet = "starter", level = 12, bond = 10 },
	{ op = "evolve", pet = "starter" },
	{ op = "legacy" },
})

local scenarios = {
	{ name = "Recorrido del Acto I", steps = journey },
	{ name = "Derrotas, huida y bloqueos", steps = losses },
	{ name = "Migración 1→2", steps = migration },
}

-- ------------------------------------------------------------------
-- Ejecutor (espejo exacto del de profile-parity.mjs)
-- ------------------------------------------------------------------
local V2_KEYS = {
	"collection",
	"eggs",
	"nextEggSerial",
	"incubators",
	"chests",
	"nextChestSerial",
	"history",
	"quests",
	"codex",
	"decor",
	"showcase",
	"titles",
	"frames",
	"guardians",
}

local function sortedKeys(t: { [string]: any }): { string }
	local out = {}
	for k in pairs(t) do
		table.insert(out, k)
	end
	table.sort(out)
	return out
end

local function run(sc: { name: string, steps: { any } })
	local p: any = nil
	local now = T0
	local vars: { [string]: string } = {}
	local snapshots, results = {}, {}
	local function ctx()
		return { now = now }
	end
	local function pet(ref: string): string
		return vars[ref] or ref
	end
	local function res(r: any, extra: string?): string
		return string.format("%s|%s%s", tostring(r.ok), tostring(r.err), extra or "")
	end
	for _, step in ipairs(sc.steps) do
		local op = step.op
		local out = ""
		if op == "new" then
			p = ProfileSchema.new(step.userId, now)
		elseif op == "advance" then
			now += step.s
		elseif op == "onLoad" then
			out = res(Actions.onLoad(p, ctx()))
		elseif op == "finishIntro" then
			out = res(Actions.finishIntro(p, step.skipped, ctx()))
		elseif op == "chooseStarter" then
			local r = Actions.chooseStarter(p, step.egg, ctx())
			if r.ok then
				vars.starter = r.data.petId
			end
			out = res(r)
		elseif op == "ackHatch" then
			out = res(Actions.ackHatch(p, ctx()))
		elseif op == "visitHome" then
			out = res(Actions.visitHome(p, ctx()))
		elseif op == "place" then
			out = res(Actions.place(p, pet(step.pet), step.slot, ctx()))
		elseif op == "collect" then
			local r = Actions.collect(p, ctx())
			out = res(r, if r.ok then "|" .. tostring(r.data.coins) else "")
		elseif op == "feed" then
			out = res(Actions.feed(p, pet(step.pet), step.food, ctx()))
		elseif op == "play" then
			out = res(Actions.play(p, pet(step.pet), ctx()))
		elseif op == "evolve" then
			out = res(Actions.evolve(p, pet(step.pet), ctx()))
		elseif op == "buyFood" then
			out = res(Actions.buyFood(p, step.food, step.qty, ctx()))
		elseif op == "devPet" then
			local r = PetRules.create(p, step.species, { kind = "Dev", at = now })
			if r.ok then
				vars[step.as] = r.data.petId
			end
			out = res(r)
		elseif op == "boost" then
			local pt = p.pets[pet(step.pet)]
			pt.level = step.level
			pt.xp = 0
			if step.form then
				pt.form = step.form
			end
			if step.bond then
				pt.bond = step.bond
			end
		elseif op == "grantCoins" then
			p.currencies.Monedas += step.n
		elseif op == "setTeam" then
			local ids = {}
			for _, ref in ipairs(step.pets) do
				table.insert(ids, pet(ref))
			end
			out = res(Actions.setTeam(p, ids, ctx()))
		elseif op == "encounter" then
			local can = Actions.canStartEncounter(p, step.id)
			if not can.ok then
				out = res(can)
			else
				Actions.markBattleStarted(p, step.id, ctx())
				local state = BattleEngine.new(EncounterRules.buildSetup(p, step.id, step.battle, step.seed))
				local guard = 0
				while state.phase ~= "Ended" do
					guard += 1
					assert(guard < 200, "combate sin fin")
					local mine = if step.forfeit
						then { kind = "Forfeit" }
						else { kind = "Move", moveId = BattleAI.choose(state, 1, "Normal") }
					assert(BattleEngine.submit(state, 1, mine))
					assert(
						BattleEngine.submit(
							state,
							2,
							{ kind = "Move", moveId = BattleAI.choose(state, 2, state.sides[2].ai) }
						)
					)
					BattleEngine.resolveTurn(state)
				end
				local won = state.outcome.winner == 1
				local r = Actions.finishEncounter(
					p,
					step.id,
					step.battle,
					won,
					state.turn,
					EncounterRules.participantsFor(p, step.id),
					ctx(),
					state.outcome.reason,
					BattleEngine.summary(state)
				)
				out = res(r, string.format("|%s|%d", tostring(won), state.turn))
			end
		elseif op == "treasure" then
			local r = Actions.solveTreasure(p, step.id, step.element, ctx())
			out = res(r, if r.ok then "|" .. tostring(r.data.solved) else "")
		elseif op == "claimAll" then
			local parts = {}
			for _, id in ipairs(sortedKeys(p.rewards.pending)) do
				table.insert(parts, id .. ":" .. res(Actions.claimReward(p, id, ctx())))
			end
			out = table.concat(parts, ",")
		elseif op == "openChests" then
			local parts = {}
			for _, id in ipairs(sortedKeys(p.chests)) do
				table.insert(parts, id .. ":" .. res(Actions.openChest(p, id, ctx())))
			end
			out = table.concat(parts, ",")
		elseif op == "incubate" then
			local eggId = nil
			for _, id in ipairs(sortedKeys(p.eggs)) do
				if eggId == nil and p.eggs[id].state == "Stored" then
					eggId = id
				end
			end
			out = if eggId then res(Actions.startIncubation(p, eggId, step.slot, ctx())) else "noegg"
		elseif op == "hatch" then
			out = res(Actions.hatchEgg(p, step.slot, ctx()))
		elseif op == "buySlot" then
			out = res(Actions.buyIncubatorSlot(p, step.slot, ctx()))
		elseif op == "claimQuests" then
			local parts = {}
			for i = 1, #p.quests.daily do
				table.insert(parts, res(Actions.claimQuest(p, "Daily", i, ctx())))
			end
			table.insert(parts, res(Actions.claimQuest(p, "Weekly", 1, ctx())))
			out = table.concat(parts, ",")
		elseif op == "placeDecor" then
			out = res(Actions.placeDecor(p, step.slot, step.decor, ctx()))
		elseif op == "template" then
			out = res(Actions.applyDecorTemplate(p, step.id, ctx()))
		elseif op == "showcase" then
			local ids = {}
			for _, ref in ipairs(step.pets) do
				table.insert(ids, pet(ref))
			end
			out = res(Actions.setShowcase(p, ids, ctx()))
		elseif op == "expand" then
			out = res(Actions.expandInventory(p, ctx()))
		elseif op == "equipTitle" then
			out = res(Actions.equipTitle(p, step.title, ctx()))
		elseif op == "legacy" then
			for _, k in ipairs(V2_KEYS) do
				p[k] = nil
			end
			p.story = { cleared = p.story.cleared, repeatDay = p.story.repeatDay, repeatCount = p.story.repeatCount }
			p.schemaVersion = 1
			p = ProfileSchema.migrate(p, now)
			local ok, why = ProfileSchema.validate(p)
			out = tostring(ok) .. "|" .. tostring(why)
		else
			error("paso desconocido: " .. tostring(op))
		end
		table.insert(results, out)
		table.insert(snapshots, serde.encode("json", p))
	end
	return { name = sc.name, steps = sc.steps, results = results, snapshots = snapshots, t0 = T0 }
end

local out = {}
for _, sc in ipairs(scenarios) do
	local r = run(sc)
	table.insert(out, r)
	-- Resumen legible de los combates (para elegir semillas con sentido)
	local wins, fights = 0, 0
	for i, step in ipairs(sc.steps) do
		if step.op == "encounter" then
			fights += 1
			if string.find(r.results[i], "|true|", 1, true) then
				wins += 1
			end
		end
	end
	print(string.format("%s: %d pasos · %d/%d combates ganados", sc.name, #sc.steps, wins, fights))
end
fs.writeDir(ROOT .. "build/web")
fs.writeFile(ROOT .. "build/web/profile_parity_luau.json", serde.encode("json", out))
