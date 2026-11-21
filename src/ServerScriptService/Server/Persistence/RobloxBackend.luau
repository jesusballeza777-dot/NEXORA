--!strict
-- Backend real sobre DataStoreService (solo se ejecuta dentro de Roblox).
-- * UpdateAsync siempre (nunca SetAsync) para respetar el bloqueo de sesión.
-- * Espera presupuesto de peticiones antes de escribir.
-- * Errores capturados con pcall: el ProfileStore decide reintentos.

local DataStoreService = game:GetService("DataStoreService")

local RobloxBackend = {}
RobloxBackend.__index = RobloxBackend

export type RobloxBackend = typeof(setmetatable({} :: { store: DataStore, name: string }, RobloxBackend))

function RobloxBackend.new(storeName: string): RobloxBackend
	return setmetatable({ store = DataStoreService:GetDataStore(storeName), name = storeName }, RobloxBackend)
end

local function waitForBudget()
	local deadline = os.clock() + 10
	while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 do
		if os.clock() > deadline then
			return
		end
		task.wait(0.5)
	end
end

function RobloxBackend.update(self: RobloxBackend, key: string, transform: (any?) -> any?): (any?, string?)
	waitForBudget()
	local ok, result = pcall(function()
		return self.store:UpdateAsync(key, function(old: any?)
			return transform(old)
		end)
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

return RobloxBackend
