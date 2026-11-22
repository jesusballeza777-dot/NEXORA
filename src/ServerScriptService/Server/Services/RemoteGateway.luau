--!strict
-- Puerta única cliente → servidor. Para cada petición valida, en este orden:
--   1) nombre de acción conocido   2) número de secuencia creciente (anti-repetición)
--   3) frecuencia (cubeta por acción)   4) tipos y rangos de argumentos
--   5) permiso de desarrollador        6) proximidad física si la acción la exige
--   7) perfil cargado                  8) procesamiento en serie por jugador
-- Cualquier error interno se captura: el cliente recibe "ServerError" y se registra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Contract = require(Shared.Net.Contract)

local Server = script.Parent.Parent
local Guard = require(Server.Util.Guard)
local Log = require(Server.Util.Log).scope("Gateway")
local DevGate = require(script.Parent.DevGate)

type Handler = (player: Player, ...any) -> { ok: boolean, err: string?, data: any? }

local RemoteGateway = {}

local handlers: { [string]: Handler } = {}
local lastSeq: { [Player]: number } = {}
local buckets: { [Player]: { [string]: Guard.Bucket } } = {}
local busy: { [Player]: boolean } = {}
local deps: { data: any, world: any, analytics: any } = {} :: any

RemoteGateway.push = (nil :: any) :: RemoteEvent

function RemoteGateway.init(d: { data: any, world: any, analytics: any })
	deps = d
	local folder = Instance.new("Folder")
	folder.Name = Contract.RemoteFolder
	local request = Instance.new("RemoteFunction")
	request.Name = Contract.RequestName
	request.Parent = folder
	local push = Instance.new("RemoteEvent")
	push.Name = Contract.PushName
	push.Parent = folder
	folder.Parent = ReplicatedStorage
	RemoteGateway.push = push
	RemoteGateway.request = request
end

function RemoteGateway.register(action: string, handler: Handler)
	assert(Contract.Actions[action], "Acción no declarada en el contrato: " .. action)
	assert(handlers[action] == nil, "Acción registrada dos veces: " .. action)
	handlers[action] = handler
end

-- Rechazos registrados en analítica: como mucho REJECT_LOG_PER_MINUTE por jugador y
-- minuto, y nunca con texto enviado por el cliente (una acción desconocida es "Unknown").
local REJECT_LOG_PER_MINUTE = 5
local rejectLog: { [Player]: Guard.Window } = {}

local function reject(player: Player, action: string, reason: string)
	if deps.analytics then
		local now = os.clock()
		local window = rejectLog[player] or Guard.newWindow(now)
		rejectLog[player] = window
		if Guard.allowInWindow(window, REJECT_LOG_PER_MINUTE, 60, now) then
			deps.analytics.log(player, "remote_rejected", {
				action = if Contract.Actions[action] then action else "Unknown",
				reason = reason,
			})
		end
	end
	return { ok = false, err = reason }
end

-- Cola de espera por jugador: hilos de peticiones pendientes (máximo MAX_QUEUED)
local MAX_QUEUED = 8
local waiting: { [Player]: { thread } } = {}

-- Cede el turno a la siguiente petición en cola (el turno pasa sin liberar "busy").
local function releaseTurn(player: Player)
	local queue = waiting[player]
	local nextThread = if queue then table.remove(queue, 1) else nil
	if nextThread then
		task.spawn(nextThread)
	else
		busy[player] = nil
	end
end

local function handle(player: Player, action: any, seq: any, ...: any)
	if type(action) ~= "string" or not Contract.Actions[action] or not handlers[action] then
		return reject(player, if type(action) == "string" then action else "?", "UnknownAction")
	end
	local spec = Contract.Actions[action]
	if type(seq) ~= "number" or seq ~= seq or math.floor(seq) ~= seq or seq <= (lastSeq[player] or 0) then
		return reject(player, action, "BadSequence")
	end
	lastSeq[player] = seq

	local now = os.clock()
	buckets[player] = buckets[player] or {}
	local bucket = buckets[player][action]
	if not bucket then
		bucket = Guard.newBucket(spec.rate.burst, now)
		buckets[player][action] = bucket
	end
	if not Guard.take(bucket, spec.rate.burst, spec.rate.perSecond, now) then
		return reject(player, action, "RateLimited")
	end

	local args = table.pack(...)
	args.n = nil
	local ok, why = Guard.checkArgs(spec.args :: any, args :: any)
	if not ok then
		return reject(player, action, why :: string)
	end
	if spec.devOnly and not DevGate.isDev(player) then
		return reject(player, action, "Forbidden")
	end
	if spec.near and not deps.world.isNear(player, spec.near, args) then
		return reject(player, action, "TooFar")
	end
	if not deps.data.get(player) then
		return { ok = false, err = "ProfileNotReady" }
	end

	-- Procesamiento en serie: una petición por jugador a la vez. Las que llegan mientras
	-- otra se procesa esperan en una cola FIFO (sin sondeo) y reciben el turno al terminar.
	if busy[player] then
		local queue = waiting[player] or {}
		waiting[player] = queue
		if #queue >= MAX_QUEUED then
			return { ok = false, err = "Busy" }
		end
		table.insert(queue, coroutine.running())
		coroutine.yield()
		if not player.Parent then
			releaseTurn(player)
			return { ok = false, err = "Busy" }
		end
	end
	busy[player] = true
	local success, result = pcall(handlers[action], player, table.unpack(args))
	releaseTurn(player)
	if not success then
		Log.error("%s falló para %d: %s", action, player.UserId, tostring(result))
		return { ok = false, err = "ServerError" }
	end
	-- El cliente solo recibe ok/err/data públicos (sin analítica interna)
	local data = if type(result) == "table" then result.data else nil
	if type(data) == "table" then
		data.analytics = nil
	end
	return { ok = result.ok, err = result.err, data = data }
end

function RemoteGateway.start()
	RemoteGateway.request.OnServerInvoke = handle
	Players.PlayerRemoving:Connect(function(player)
		lastSeq[player] = nil
		buckets[player] = nil
		busy[player] = nil
		rejectLog[player] = nil
		-- Despierta a las peticiones en cola: verán que el jugador se fue y saldrán
		local queue = waiting[player]
		waiting[player] = nil
		if queue then
			for _, thread in ipairs(queue) do
				task.spawn(thread)
			end
		end
	end)
end

return RemoteGateway
