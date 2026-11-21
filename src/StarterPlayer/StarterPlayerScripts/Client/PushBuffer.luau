--!strict
-- Reparto de mensajes push por tipo. Un mensaje que llega antes de que alguien lo
-- escuche (p. ej. el primer perfil mientras el cliente aún construye la interfaz) se
-- guarda y se entrega al primer oyente de ese tipo:
-- * tipos "solo el último" (la vista del perfil): se conserva únicamente el más reciente;
-- * el resto se conserva en orden, hasta `maxPending` por tipo.
-- Lógica pura: `spawn` llega por parámetro (task.spawn en Roblox).

local PushBuffer = {}

export type PushBuffer = {
	on: (kind: string, fn: (any) -> ()) -> (),
	push: (kind: string, payload: any) -> (),
}

function PushBuffer.new(opts: {
	latestOnly: { string },
	maxPending: number,
	spawn: (fn: (any) -> (), payload: any) -> (),
}): PushBuffer
	local listeners: { [string]: { (any) -> () } } = {}
	local pending: { [string]: { any } } = {}
	local latestOnly: { [string]: boolean } = {}
	for _, kind in ipairs(opts.latestOnly) do
		latestOnly[kind] = true
	end

	local function deliver(kind: string, payload: any)
		for _, fn in ipairs(listeners[kind]) do
			opts.spawn(fn, payload)
		end
	end

	local function on(kind: string, fn: (any) -> ())
		local first = listeners[kind] == nil
		listeners[kind] = listeners[kind] or {}
		table.insert(listeners[kind], fn)
		local queued = pending[kind]
		if first and queued then
			pending[kind] = nil
			for _, payload in ipairs(queued) do
				opts.spawn(fn, payload)
			end
		end
	end

	local function push(kind: string, payload: any)
		if listeners[kind] then
			deliver(kind, payload)
		elseif latestOnly[kind] then
			pending[kind] = { payload }
		else
			local queue = pending[kind] or {}
			if #queue < opts.maxPending then
				table.insert(queue, payload)
			end
			pending[kind] = queue
		end
	end

	return { on = on, push = push }
end

return PushBuffer
