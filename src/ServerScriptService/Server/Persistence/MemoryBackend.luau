--!strict
-- Backend en memoria con la misma semántica que UpdateAsync (copias profundas,
-- transform puede cancelar devolviendo nil). Sirve para:
-- * pruebas automatizadas (Lune) con inyección de fallos;
-- * Studio sin acceso a la API de DataStore (los datos viven solo en la sesión).
-- Nunca toca DataStoreService, así que jamás puede afectar datos de producción.

local Freeze = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Util.Freeze)

local MemoryBackend = {}
MemoryBackend.__index = MemoryBackend

export type MemoryBackend = typeof(setmetatable(
	{} :: { store: { [string]: any }, failNext: number, calls: number },
	MemoryBackend
))

function MemoryBackend.new(): MemoryBackend
	return setmetatable({ store = {}, failNext = 0, calls = 0 }, MemoryBackend)
end

function MemoryBackend.update(self: MemoryBackend, key: string, transform: (any?) -> any?): (any?, string?)
	self.calls += 1
	if self.failNext > 0 then
		self.failNext -= 1
		return nil, "SimulatedFailure"
	end
	local current = Freeze.copy(self.store[key])
	local nextValue = transform(current)
	if nextValue ~= nil then
		self.store[key] = Freeze.copy(nextValue)
	end
	return Freeze.copy(self.store[key]), nil
end

-- Solo para pruebas: lectura directa sin bloqueo.
function MemoryBackend.peek(self: MemoryBackend, key: string): any?
	return Freeze.copy(self.store[key])
end

return MemoryBackend
