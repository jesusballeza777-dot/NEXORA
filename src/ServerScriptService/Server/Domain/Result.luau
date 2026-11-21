--!strict
-- Resultado uniforme de las reglas de dominio: { ok, err?, data? }.
-- Los códigos de error son estables y el cliente los traduce a mensajes.

export type Result = { ok: boolean, err: string?, data: { [string]: any }? }

local Result = {}

function Result.ok(data: { [string]: any }?): Result
	return { ok = true, data = data or {} }
end

function Result.fail(err: string): Result
	return { ok = false, err = err }
end

return Result
