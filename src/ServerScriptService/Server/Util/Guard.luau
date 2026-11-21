--!strict
-- Validación de argumentos remotos según Shared/Net/Contract y cubeta de fichas
-- para limitar la frecuencia. Puro: se prueba en Lune.

local Guard = {}

export type ArgSpec = { kind: string, max: number?, min: number? }

function Guard.checkArgs(specs: { ArgSpec }, args: { any }): (boolean, string?)
	if #args > #specs then
		return false, "TooManyArgs"
	end
	for i, spec in ipairs(specs) do
		local v = args[i]
		if spec.kind == "string" then
			if type(v) ~= "string" then
				return false, "Arg" .. i .. "NotString"
			end
			if #v == 0 or #v > (spec.max or 64) then
				return false, "Arg" .. i .. "BadLength"
			end
			if utf8.len(v) == nil then
				return false, "Arg" .. i .. "BadUtf8"
			end
		elseif spec.kind == "int" then
			if type(v) ~= "number" or v ~= v or math.floor(v) ~= v then
				return false, "Arg" .. i .. "NotInt"
			end
			if (spec.min and v < spec.min) or (spec.max and v > spec.max) then
				return false, "Arg" .. i .. "OutOfRange"
			end
		elseif spec.kind == "bool" then
			if type(v) ~= "boolean" then
				return false, "Arg" .. i .. "NotBool"
			end
		else
			return false, "UnknownSpec"
		end
	end
	return true, nil
end

export type Bucket = { tokens: number, updatedAt: number }

-- Devuelve true si la acción está permitida y consume una ficha.
function Guard.take(bucket: Bucket, burst: number, perSecond: number, now: number): boolean
	local elapsed = math.max(0, now - bucket.updatedAt)
	bucket.tokens = math.min(burst, bucket.tokens + elapsed * perSecond)
	bucket.updatedAt = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

function Guard.newBucket(burst: number, now: number): Bucket
	return { tokens = burst, updatedAt = now }
end

return Guard
