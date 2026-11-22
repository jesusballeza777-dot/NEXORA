--!strict
-- Historial de obtenciones (cofres, huevos, eclosiones, encargos, etapas): lo que el
-- jugador consiguió, cuándo y de dónde. Acotado para que el perfil no crezca sin límite.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Types = require(Shared.Types)

type Profile = Types.Profile

local HistoryRules = {}

HistoryRules.LIMIT = 100

function HistoryRules.add(p: Profile, entry: Types.HistoryEntry)
	table.insert(p.history, entry)
	while #p.history > HistoryRules.LIMIT do
		table.remove(p.history, 1)
	end
end

return HistoryRules
