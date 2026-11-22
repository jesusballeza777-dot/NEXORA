--!strict
-- Exporta el Acto I (etapas, regiones) a JSON para documentos e informes.
-- Uso: lune run tools/sim/export_act > archivo.json
local serde = require("@lune/serde")
local VirtualGame = require("../../tests/lib/VirtualGame")
local Encounters = VirtualGame.get("ReplicatedStorage.Shared.Config.Encounters")
local out = { regions = {}, stages = {} }
for _, r in ipairs(Encounters.Regions) do
	table.insert(out.regions, { index = r.index, name = r.name, levels = r.levels, palette = r.palette })
end
for _, id in ipairs(Encounters.Order) do
	local e = Encounters.ById[id]
	table.insert(out.stages, {
		id = id,
		name = e.name,
		region = e.region,
		stage = e.stage,
		stageType = e.stageType,
		mapPos = e.mapPos,
		challenge = e.challenge.text,
		rivals = #e.opponents,
	})
end
print(serde.encode("json", out))
