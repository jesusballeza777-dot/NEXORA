--!strict
-- Generador pseudoaleatorio determinista (Park–Miller, módulo 2^31−1).
-- Todas las operaciones caben exactamente en un double (< 2^53), así que la misma
-- semilla produce la misma secuencia en Luau (Roblox/Lune) y en JavaScript
-- (prototipo web). El servidor siembra cada combate; los tests fijan la semilla.

local MOD = 2147483647
local MULT = 48271

export type Rng = {
	state: number,
	next: (self: Rng) -> number,
	chance: (self: Rng, p: number) -> boolean,
	range: (self: Rng, min: number, max: number) -> number,
	int: (self: Rng, min: number, max: number) -> number,
}

local Rng = {}
Rng.__index = Rng

function Rng.new(seed: number): Rng
	local s = math.floor(math.abs(seed)) % MOD
	if s == 0 then
		s = 1
	end
	return (setmetatable({ state = s }, Rng) :: any) :: Rng
end

-- Devuelve un número en [0, 1)
function Rng.next(self: Rng): number
	self.state = (self.state * MULT) % MOD
	return (self.state - 1) / (MOD - 1)
end

function Rng.chance(self: Rng, p: number): boolean
	if p <= 0 then
		return false
	end
	if p >= 1 then
		return true
	end
	return self:next() < p
end

function Rng.range(self: Rng, min: number, max: number): number
	return min + (max - min) * self:next()
end

function Rng.int(self: Rng, min: number, max: number): number
	return min + math.floor(self:next() * (max - min + 1))
end

return Rng
