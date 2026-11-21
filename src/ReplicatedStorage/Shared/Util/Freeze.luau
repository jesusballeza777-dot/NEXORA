--!strict
-- Congela tablas de configuración en profundidad para que ningún sistema
-- pueda mutar datos de diseño en tiempo de ejecución.

local Freeze = {}

function Freeze.deep<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local t = value :: any
	if table.isfrozen(t) then
		return value
	end
	for _, child in pairs(t) do
		if type(child) == "table" then
			Freeze.deep(child)
		end
	end
	table.freeze(t)
	return value
end

-- Copia profunda mutable (para datos de perfil derivados de plantillas congeladas).
function Freeze.copy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value :: any) do
		out[k] = Freeze.copy(v)
	end
	return (out :: any) :: T
end

return Freeze
