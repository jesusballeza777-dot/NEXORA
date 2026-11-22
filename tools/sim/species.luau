--!strict
-- Lista de especies por bioma (ayuda de diseño): lune run tools/sim/species [Bioma]
local process = require("@lune/process")
local VirtualGame = require("../../tests/lib/VirtualGame")
local Species = VirtualGame.get("ReplicatedStorage.Shared.Config.Species")
local Visuals = VirtualGame.get("ReplicatedStorage.Shared.Config.Visuals")
local filter = process.args[1]
for _, id in ipairs(Species.Order) do
	local s = Species.ById[id]
	if not filter or s.biome == filter then
		print(
			string.format(
				"%2d %-10s %-12s %-12s %-10s %-22s %-10s %s",
				s.number,
				id,
				s.broteName,
				s.talladoName,
				s.rarity,
				table.concat(s.elements, "+"),
				s.biome,
				if Visuals.ById[id] then "VISUAL" else ""
			)
		)
	end
end
