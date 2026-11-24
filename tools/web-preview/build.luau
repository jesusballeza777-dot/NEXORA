--!strict
-- Construye la vista previa web de NEXORA a partir de la configuración Luau.
--   lune run tools/web-preview/build
-- Salidas:
--   build/web/config.json           configuración exportada (fuente: src/.../Config)
--   build/web/parity_luau.json      combates de referencia del motor Luau
--   tools/web-preview/dist/NEXORA_Preview.html   página única jugable (con todo en línea)
-- Después ejecutar:  node tools/web-preview/parity.mjs   (compara motor Luau vs JS)

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local VirtualGame = require("../../tests/lib/VirtualGame")

local ROOT = VirtualGame.ROOT
local get = VirtualGame.get

local names = {
	"Elements",
	"Rarities",
	"Roles",
	"Species",
	"Abilities",
	"Talents",
	"Progression",
	"Combat",
	"Economy",
	"Sanctuary",
	"Encounters",
	"Rewards",
	"Onboarding",
	"Visuals",
	"Guardians",
	"World",
	-- Fase 2
	"Incubation",
	"Chests",
	"Quests",
	"Codex",
	"Decor",
	"SpeciesLore",
	"Achievements",
}
local config = {}
for _, name in ipairs(names) do
	config[name] = get("ReplicatedStorage.Shared.Config." .. name)
end
local json = serde.encode("json", config)

fs.writeDir(ROOT .. "build/web")
fs.writeFile(ROOT .. "build/web/config.json", json)

-- Combates de referencia para comprobar paridad con el port JavaScript
local BattleEngine = get("ReplicatedStorage.Shared.Domain.Battle.BattleEngine")
local BattleAI = get("ReplicatedStorage.Shared.Domain.Battle.BattleAI")
local function solo(player: string, foe: string, lp: number, lf: number, ai: string, form: string)
	return {
		ai = ai,
		player = { { speciesId = player, form = form, level = lp } },
		foe = {
			{
				speciesId = foe,
				form = "Brote",
				level = lf,
				isOpaco = true,
				modifier = if foe == "vainas" then "Coraza" else nil,
			},
		},
	}
end
local matchups = {
	solo("kuachi", "agavo", 2, 1, "Tutorial", "Brote"),
	solo("xolumi", "comalu", 2, 1, "Tutorial", "Brote"),
	solo("teselo", "zizi", 2, 1, "Tutorial", "Brote"),
	solo("xolumi", "barrock", 6, 4, "Normal", "Brote"),
	solo("kuachi", "vainas", 9, 7, "Normal", "Brote"),
	solo("teselo", "vainas", 22, 7, "Normal", "Tallado"),
	solo("kuachi", "comalu", 25, 12, "Normal", "Tallado"),
	-- Fase 2: equipos de 3 con sustitución y raíces del Acto I
	{
		ai = "Normal",
		player = {
			{ speciesId = "kuachi", form = "Brote", level = 8 },
			{ speciesId = "xolumi", form = "Brote", level = 7 },
			{ speciesId = "teselo", form = "Brote", level = 7 },
		},
		foe = {
			{ speciesId = "agavo", form = "Brote", level = 6, isOpaco = true, rootHeal = 0.05 },
			{ speciesId = "barrock", form = "Brote", level = 6, isOpaco = true },
			{ speciesId = "vainas", form = "Brote", level = 7, isOpaco = true, modifier = "Coraza", rootHeal = 0.05 },
		},
	},
	-- Fase 2: Copalia (Ser Sagrado con fases) contra un equipo de 3 Tallados
	{
		ai = "Normal",
		player = {
			{ speciesId = "kuachi", form = "Tallado", level = 15 },
			{ speciesId = "xolumi", form = "Tallado", level = 14 },
			{ speciesId = "teselo", form = "Tallado", level = 14 },
		},
		foe = {
			{ speciesId = "copalia", guardianId = "copalia", form = "Tallado", level = 15, isOpaco = true },
		},
	},
}
local function logString(log: { any }): string
	local parts = {}
	for _, e in ipairs(log) do
		table.insert(
			parts,
			string.format(
				"%s:%s:%s:%s",
				tostring(e.t),
				tostring(e.target or e.actor or e.to),
				tostring(e.amount or e.move or e.status or e.phase),
				tostring(e.hp)
			)
		)
	end
	return table.concat(parts, "|")
end
local cases = {}
for m, mu in ipairs(matchups) do
	for seed = 1, 25 do
		local s = seed * 104729 + m
		local setup = {
			battleId = "P",
			seed = s,
			sides = {
				{ controller = "Player", team = mu.player },
				{ controller = "AI", ai = mu.ai, team = mu.foe },
			},
		}
		local state = BattleEngine.new(setup)
		while state.phase ~= "Ended" do
			BattleEngine.submit(state, 1, { kind = "Move", moveId = BattleAI.choose(state, 1, "Normal") })
			BattleEngine.submit(state, 2, { kind = "Move", moveId = BattleAI.choose(state, 2, mu.ai) })
			BattleEngine.resolveTurn(state)
		end
		table.insert(cases, {
			setup = setup,
			log = logString(state.log),
			winner = state.outcome.winner,
			turns = state.turn,
		})
	end
end
fs.writeFile(ROOT .. "build/web/parity_luau.json", serde.encode("json", cases))

-- Ensamblar la página única
local src = ROOT .. "tools/web-preview/src/"
local html = fs.readFile(src .. "index.html")
local engine = fs.readFile(src .. "engine.js")
local normalize = fs.readFile(src .. "normalize.js")
local domain = fs.readFile(src .. "domain.js")
-- El módulo del juego se arma con sus partes (comparten ámbito; el arranque va al final)
local parts = {}
for _, name in ipairs({ "game.js", "battle.js", "screens.js", "boot.js" }) do
	table.insert(parts, fs.readFile(src .. name))
end
local game = table.concat(parts, "\n")
local css2 = fs.readFile(src .. "phase2.css")
local function inject(text: string, marker: string, content: string): string
	local i, j = string.find(text, marker, 1, true)
	assert(i, "Falta el marcador " .. marker)
	return string.sub(text, 1, i - 1) .. content .. string.sub(text, (j :: number) + 1)
end
-- Modelos 3D de la Fase 3 (propuesta): versión web de assets/Creatures/**/web/*.web.glb en base64
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64(data: string): string
	local out = table.create(math.ceil(#data / 3))
	for i = 1, #data, 3 do
		local a, b, c = string.byte(data, i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local c1 = bit32.extract(n, 18, 6) + 1
		local c2 = bit32.extract(n, 12, 6) + 1
		local c3 = bit32.extract(n, 6, 6) + 1
		local c4 = bit32.extract(n, 0, 6) + 1
		table.insert(
			out,
			string.sub(B64, c1, c1)
				.. string.sub(B64, c2, c2)
				.. (if b then string.sub(B64, c3, c3) else "=")
				.. (if c then string.sub(B64, c4, c4) else "=")
		)
	end
	return table.concat(out)
end
local glbEntries = {}
local initials = ROOT .. "assets/Creatures/Initials/"
if fs.isDir(initials) then
	local names = fs.readDir(initials)
	table.sort(names)
	for _, name in ipairs(names) do
		local metaPath = initials .. name .. "/asset.json"
		if fs.isFile(metaPath) then
			local meta = serde.decode("json", fs.readFile(metaPath))
			local web = initials .. name .. "/web/" .. meta.id .. ".web.glb"
			if fs.isFile(web) then
				table.insert(
					glbEntries,
					string.format('"%s:%s":"%s"', meta.species, meta.form, base64(fs.readFile(web)))
				)
			end
		end
	end
end
html = inject(
	html,
	"/*__NEXORA_CONFIG__*/",
	"window.NEXORA_CONFIG = " .. json .. ";\nwindow.NEXORA_GLB = {" .. table.concat(glbEntries, ",") .. "};"
)
html = inject(html, "/*__NEXORA_NORMALIZE__*/", normalize)
html = inject(html, "/*__NEXORA_ENGINE__*/", engine)
html = inject(html, "/*__NEXORA_DOMAIN__*/", domain)
html = inject(html, "/*__NEXORA_CSS2__*/", css2)
html = inject(html, "/*__NEXORA_GAME__*/", game)
fs.writeDir(ROOT .. "tools/web-preview/dist")
fs.writeFile(ROOT .. "tools/web-preview/dist/NEXORA_Preview.html", html)

-- Variante para Artifact de claude.ai: el visor aporta doctype/head/body propios
local fragment = html
for _, tag in ipairs({
	"<!doctype html>\n",
	'<html lang="es">\n',
	"<head>\n",
	"</head>\n",
	"<body>\n",
	"</body>\n",
	"</html>\n",
}) do
	local i, j = string.find(fragment, tag, 1, true)
	if i then
		fragment = string.sub(fragment, 1, i - 1) .. string.sub(fragment, (j :: number) + 1)
	end
end
fragment = string.gsub(fragment, '<meta charset="utf%-8">\n', "", 1)
fragment = string.gsub(fragment, '<meta name="viewport"[^\n]*\n', "", 1)
fs.writeFile(ROOT .. "build/web/NEXORA_Preview.artifact.html", fragment)
print(
	string.format(
		"Vista previa: %d KB · %d combates de referencia · %d modelos 3D",
		math.floor(#html / 1024),
		#cases,
		#glbEntries
	)
)
