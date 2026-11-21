--!strict
-- Traduce los campos de un evento de dominio al formato de AnalyticsService:
-- hasta 3 campos personalizados con claves fijas (CustomField01..03) y valores de texto
-- "clave - valor". Lógica pura: las claves llegan por parámetro (Enum en Roblox).
-- * Las claves se ordenan alfabéticamente: cada campo significa siempre lo mismo.
-- * Los números no van a los campos (dispararían la cardinalidad): el primero en ese
--   orden se usa como valor numérico del evento; sin números, el valor es 1.

local AnalyticsFields = {}

AnalyticsFields.MAX_TEXT = 48

function AnalyticsFields.encode(fields: { [string]: any }?, keyNames: { string }): ({ [string]: string }?, number)
	if not fields then
		return nil, 1
	end
	local keys = {}
	for k in pairs(fields) do
		table.insert(keys, k)
	end
	table.sort(keys)
	local out: { [string]: string } = {}
	local value = 1
	local valueTaken = false
	local n = 0
	for _, k in ipairs(keys) do
		local v = fields[k]
		if type(v) == "number" then
			if not valueTaken then
				value = v
				valueTaken = true
			end
		elseif n < #keyNames then
			n += 1
			out[keyNames[n]] = string.sub(k .. " - " .. tostring(v), 1, AnalyticsFields.MAX_TEXT)
		end
	end
	return if n > 0 then out else nil, value
end

return AnalyticsFields
