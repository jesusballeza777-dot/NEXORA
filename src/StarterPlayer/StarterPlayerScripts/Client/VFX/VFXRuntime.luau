--!strict
-- Un solo paso por frame para TODOS los efectos (sin hilos sueltos ni esperas).
-- * add(effect): el efecto se actualiza cada frame hasta que su update devuelve false;
--   entonces se llama a su finish (allí devuelve sus instancias al pool).
-- * delay(s, fn): temporizador cancelable que corre dentro del mismo paso.
-- * Presupuesto: como mucho `maxPerFrame` efectos por frame; los demás esperan al
--   siguiente frame y reciben el tiempo acumulado (no se pierde tiempo, solo se reparte).
-- Es lógica pura: el reloj lo da quien llama a step(dt), así las pruebas usan un reloj
-- falso. En el juego, bind(RunService.RenderStepped) conecta una única señal.

local VFXRuntime = {}
VFXRuntime.__index = VFXRuntime

export type Effect = {
	update: (self: any, dt: number) -> boolean,
	finish: ((self: any) -> ())?,
}

type Entry = { id: number, effect: Effect, owner: any?, pending: number, alive: boolean }
type Timer = { id: number, at: number, fn: () -> (), owner: any?, alive: boolean }

export type Runtime = typeof(setmetatable(
	{} :: {
		now: number,
		maxPerFrame: number,
		maxEffects: number,
		entries: { Entry },
		timers: { Timer },
		cursor: number,
		nextId: number,
		connection: any?,
		rejected: number,
	},
	VFXRuntime
))

function VFXRuntime.new(opts: { maxPerFrame: number?, maxEffects: number? }?): Runtime
	return setmetatable({
		now = 0,
		maxPerFrame = opts and opts.maxPerFrame or 48,
		maxEffects = opts and opts.maxEffects or 64,
		entries = {},
		timers = {},
		cursor = 1,
		nextId = 0,
		connection = nil,
		rejected = 0,
	}, VFXRuntime)
end

-- Devuelve un identificador para cancelarlo, o nil si se superó el máximo de efectos.
function VFXRuntime.add(self: Runtime, effect: Effect, owner: any?): number?
	if #self.entries >= self.maxEffects then
		self.rejected += 1
		if effect.finish then
			effect.finish(effect)
		end
		return nil
	end
	self.nextId += 1
	table.insert(self.entries, { id = self.nextId, effect = effect, owner = owner, pending = 0, alive = true })
	return self.nextId
end

function VFXRuntime.delay(self: Runtime, seconds: number, fn: () -> (), owner: any?): number
	self.nextId += 1
	table.insert(self.timers, { id = self.nextId, at = self.now + seconds, fn = fn, owner = owner, alive = true })
	return self.nextId
end

local function finish(e: Entry)
	if e.alive then
		e.alive = false
		if e.effect.finish then
			e.effect.finish(e.effect)
		end
	end
end

-- Cancela un efecto o un temporizador por id. Los efectos cancelados hacen su finish.
function VFXRuntime.cancel(self: Runtime, id: number?)
	if not id then
		return
	end
	for _, e in ipairs(self.entries) do
		if e.id == id then
			finish(e)
		end
	end
	for _, t in ipairs(self.timers) do
		if t.id == id then
			t.alive = false
		end
	end
end

-- Cancela todo lo de un dueño (p. ej. una criatura que se destruye o un combate que acaba)
function VFXRuntime.cancelOwner(self: Runtime, owner: any)
	for _, e in ipairs(self.entries) do
		if e.owner == owner then
			finish(e)
		end
	end
	for _, t in ipairs(self.timers) do
		if t.owner == owner then
			t.alive = false
		end
	end
end

function VFXRuntime.step(self: Runtime, dt: number)
	self.now += dt
	-- Temporizadores vencidos (en orden de vencimiento)
	if #self.timers > 0 then
		local due: { Timer } = {}
		local keep: { Timer } = {}
		for _, t in ipairs(self.timers) do
			if t.alive and t.at <= self.now then
				table.insert(due, t)
			elseif t.alive then
				table.insert(keep, t)
			end
		end
		self.timers = keep
		table.sort(due, function(a, b)
			return a.at < b.at
		end)
		for _, t in ipairs(due) do
			t.fn()
		end
	end
	-- Efectos con presupuesto por frame (reparto rotatorio)
	local n = #self.entries
	if n == 0 then
		return
	end
	for _, e in ipairs(self.entries) do
		e.pending += dt
	end
	local budget = math.min(n, self.maxPerFrame)
	local start = if self.cursor > n then 1 else self.cursor
	for k = 0, budget - 1 do
		local e = self.entries[((start - 1 + k) % n) + 1]
		if e.alive then
			local step = e.pending
			e.pending = 0
			if not e.effect.update(e.effect, step) then
				finish(e)
			end
		end
	end
	self.cursor = ((start - 1 + budget) % n) + 1
	-- Limpia los terminados
	local alive: { Entry } = {}
	for _, e in ipairs(self.entries) do
		if e.alive then
			table.insert(alive, e)
		end
	end
	self.entries = alive
	if self.cursor > #alive then
		self.cursor = 1
	end
end

function VFXRuntime.count(self: Runtime): number
	return #self.entries
end

function VFXRuntime.timerCount(self: Runtime): number
	local n = 0
	for _, t in ipairs(self.timers) do
		if t.alive then
			n += 1
		end
	end
	return n
end

-- Termina todos los efectos y temporizadores (fin de combate, salida del jugador).
function VFXRuntime.clear(self: Runtime)
	for _, e in ipairs(self.entries) do
		finish(e)
	end
	self.entries = {}
	self.timers = {}
	self.cursor = 1
end

-- Conecta el paso a una señal por frame (una sola conexión por runtime).
function VFXRuntime.bind(self: Runtime, signal: any)
	if self.connection then
		return
	end
	self.connection = signal:Connect(function(dt: number)
		self:step(dt)
	end)
end

return VFXRuntime
