--!strict
-- Genera docs/CONTENT_CATALOG.md a partir de la configuración real (Shared/Config).
-- Uso (desde la raíz):  lune run tools/catalog/build
-- Nunca editar el catálogo a mano: cambia la config y vuelve a generarlo.

local fs = require("@lune/fs")
local VirtualGame = require("../../tests/lib/VirtualGame")
local get = function(name: string)
	return VirtualGame.get("ReplicatedStorage.Shared.Config." .. name)
end
local Species, Lore, Rarities = get("Species"), get("SpeciesLore"), get("Rarities")
local Visuals, Encounters, Guardians = get("Visuals"), get("Encounters"), get("Guardians")
local Chests, Quests, Codex, Decor, Incubation =
	get("Chests"), get("Quests"), get("Codex"), get("Decor"), get("Incubation")

local out = {}
local function w(line: string?)
	table.insert(out, line or "")
end
local function esc(s: string?): string
	return (string.gsub(s or "", "|", "/"))
end

w("# NEXORA · Catálogo de contenido (Fase 2)")
w()
w("> Generado por `lune run tools/catalog/build` desde `src/ReplicatedStorage/Shared/Config`. No editar a mano.")
w('> Estado artístico: todo modelo actual es **blockout** (`AssetStatus = "Blockout"`); nada está aprobado.')
w()
w("## 1. Especies (50)")
w()
w("| # | Brote → Tallado | Rareza | Elementos | Bioma | Rol | Familia | Tallado | Incubación | Modelo en la beta |")
w("|---|---|---|---|---|---|---|---|---|---|")
for _, id in ipairs(Species.Order) do
	local s = Species.ById[id]
	local r = Rarities.ById[s.rarity]
	local secs = Incubation.SecondsByRarity[s.rarity]
	local inc = if secs >= 3600 then string.format("%d h", secs // 3600) else string.format("%d min", secs // 60)
	local vis = Visuals.ById[id]
	local model = if not vis
		then "Silueta (sin modelo)"
		elseif string.find(vis.signatureFeature, "prestado", 1, true) then "Blockout provisional (arquetipo prestado)"
		else "Blockout"
	w(
		string.format(
			"| %d | %s → %s | %s | %s | %s | %s | %s | nv %d | %s | %s |",
			s.number,
			s.broteName,
			s.talladoName,
			r.name,
			table.concat(s.elements, " + "),
			Species.Biomes[s.biome].name,
			s.role,
			s.family,
			r.talladoLevel,
			inc,
			model
		)
	)
end
w()
w("## 2. Valle Copal: las 14 especies nativas")
w()
for _, id in ipairs(Species.Order) do
	local s = Species.ById[id]
	if s.biome == "ValleCopal" then
		local l = Lore.ById[id]
		w(string.format("### #%d %s → %s", s.number, s.broteName, s.talladoName))
		w()
		w("- **Concepto:** " .. esc(l.concept))
		w("- **Mezcla mítica:** " .. esc(l.mythicMix))
		w("- **Rasgo distintivo:** " .. esc(l.distinctiveTrait))
		w("- **Obtención (Biblia):** " .. esc(l.obtention))
		w()
	end
end
w("## 3. Seres Sagrados")
w()
for _, id in ipairs(Guardians.Order) do
	local g = Guardians.ById[id]
	w(string.format("### %s", g.name))
	w()
	w(string.format("- %s · %s · %s", g.epithet, table.concat(g.elements, " + "), g.rarity))
	w(
		string.format(
			"- Atributos (%s): VID %d · ATQ %d · DEF %d · ESE %d · VEL %d",
			g.statsStatus,
			g.stats.VID,
			g.stats.ATQ,
			g.stats.DEF,
			g.stats.ESE,
			g.stats.VEL
		)
	)
	w(string.format("- Talento %s: %s", g.talentName, g.talentText))
	for i, ph in ipairs(g.phases) do
		w(string.format("- Fase %d (al %d %% de VID): %s", i + 1, math.floor(ph.threshold * 100), ph.text))
	end
	w("- Al restaurarla: " .. g.restoreBonus)
	w()
end
w("## 4. Acto I — Valle Copal")
w()
for _, region in ipairs(Encounters.Regions) do
	w(string.format("### Región %d · %s (nv %s)", region.index, region.name, region.levels))
	w()
	w("| Etapa | Tipo | Rivales | Reto ★★★ | 1.ª victoria |")
	w("|---|---|---|---|---|")
	local ids = table.clone(region.stages)
	table.insert(ids, region.secret)
	if region.index == 3 then
		table.insert(ids, Encounters.Acts.ActoI.boss)
	end
	for _, id in ipairs(ids) do
		local e = Encounters.ById[id]
		local rivals = {}
		for _, o in ipairs(e.opponents) do
			local name = if o.guardianId
				then Guardians.ById[o.guardianId].shortName
				elseif o.speciesId then Species.ById[o.speciesId].broteName
				else "según el inicial"
			table.insert(
				rivals,
				string.format(
					"%s nv %d%s%s",
					name,
					o.level,
					if o.modifier then " " .. o.modifier else "",
					if o.rooted then " 🌿" else ""
				)
			)
		end
		w(
			string.format(
				"| %s | %s | %s | %s | %d Monedas · %d XP%s |",
				e.name,
				e.stageType,
				if #rivals > 0 then table.concat(rivals, ", ") else "Acertijo elemental",
				e.challenge.text,
				e.baseReward.Monedas,
				e.baseReward.petXp,
				if e.firstClearChest then " · " .. Chests.ById[e.firstClearChest].name else ""
			)
		)
	end
	w()
end
w("## 5. Cofres")
w()
w("| Cofre | Activo en la beta | Modo | Contenido fijo | Tabla de la Biblia | Fuentes |")
w("|---|---|---|---|---|---|")
for _, id in ipairs(Chests.Order) do
	local c = Chests.ById[id]
	local fixed = "—"
	if c.fixed then
		local parts = {}
		for cur, v in pairs(c.fixed.currencies) do
			table.insert(parts, string.format("%d %s", v, cur))
		end
		for item, v in pairs(c.fixed.items) do
			table.insert(parts, string.format("%d %s", v, item))
		end
		for _, e in ipairs(c.fixed.eggs) do
			table.insert(parts, "huevo " .. e.pool)
		end
		table.sort(parts)
		fixed = table.concat(parts, ", ")
	end
	local rows = {}
	for _, r in ipairs(c.bibleTable) do
		table.insert(rows, r.prize .. ": " .. (if r.percent then tostring(r.percent) .. " %" else r.status))
	end
	w(
		string.format(
			"| %s | %s | %s | %s | %s | %s |",
			c.name,
			if c.activeInBeta then "Sí" else "No",
			c.mode,
			fixed,
			esc(table.concat(rows, "; ")),
			esc(c.sources)
		)
	)
end
w()
w("## 6. Tablón de Encargos")
w()
w("| Id | Encargo | Dificultad | Meta | Monedas |")
w("|---|---|---|---|---|")
for _, list in ipairs({ Quests.Daily, Quests.Weekly }) do
	for _, q in ipairs(list) do
		w(
			string.format(
				"| %s | %s — %s | %s | %d | %d |",
				q.id,
				q.title,
				q.description,
				q.difficulty,
				q.target,
				q.coins
			)
		)
	end
end
w()
w("## 7. Códice del Acto I")
w()
for _, id in ipairs(Codex.Order) do
	local e = Codex.ById[id]
	w(string.format("- %s **%s** (%s): %s", e.symbol, e.title, e.kind, e.text))
end
w()
w("## 8. Decoración")
w()
for _, id in ipairs(Decor.Order) do
	local d = Decor.ById[id]
	w(string.format("- **%s** (%s): %s", d.name, d.category, d.description))
end
w()
fs.writeFile("docs/CONTENT_CATALOG.md", table.concat(out, "\n"))
print(string.format("Catálogo: %d líneas → docs/CONTENT_CATALOG.md", #out))
