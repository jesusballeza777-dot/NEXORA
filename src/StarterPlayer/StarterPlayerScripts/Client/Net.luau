--!strict
-- Cliente de red: envía solicitudes con número de secuencia creciente (el servidor
-- rechaza repeticiones) y reparte los mensajes "push" del servidor por tipo.
-- El cliente nunca envía cantidades: solo intenciones ("alimenta a X con Y").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("Contract"))

local Net = {}

local folder = ReplicatedStorage:WaitForChild(Contract.RemoteFolder)
local request = folder:WaitForChild(Contract.RequestName) :: RemoteFunction
local push = folder:WaitForChild(Contract.PushName) :: RemoteEvent

local seq = 0
local listeners: { [string]: { (any) -> () } } = {}

export type Response = { ok: boolean, err: string?, data: any? }

function Net.request(action: string, ...: any): Response
	assert(Contract.Actions[action], "Acción desconocida: " .. action)
	seq += 1
	local ok, result = pcall(request.InvokeServer, request, action, seq, ...)
	if not ok then
		return { ok = false, err = "NetworkError" }
	end
	if type(result) ~= "table" then
		return { ok = false, err = "BadResponse" }
	end
	return result :: Response
end

function Net.on(kind: string, fn: (any) -> ())
	listeners[kind] = listeners[kind] or {}
	table.insert(listeners[kind], fn)
end

push.OnClientEvent:Connect(function(kind: string, payload: any)
	for _, fn in ipairs(listeners[kind] or {}) do
		task.spawn(fn, payload)
	end
end)

-- Mensajes de error legibles (el servidor devuelve códigos estables)
local MESSAGES: { [string]: string } = {
	TooFar = "Acércate más: esta acción se hace en persona.",
	RateLimited = "Despacio… inténtalo en un momento.",
	NoFood = "No tienes esa comida.",
	Cooldown = "Tu monstruo está descansando.",
	NotEnoughMonedas = "Te faltan Monedas.",
	LevelTooLow = "Aún no alcanza el nivel para tallarse.",
	BondTooLow = "Necesita más Vínculo para tallarse.",
	EncounterLocked = "Primero restaura al Opaco anterior.",
	FinishTutorialFirst = "Sigue el objetivo del tutorial.",
	SlotOccupied = "Ese lugar ya está ocupado.",
	AlreadyPlaced = "Ya vive en el hábitat.",
	InventoryFull = "Tu Vivero está lleno.",
	FilterUnavailable = "No pudimos revisar el nombre. Prueba otro.",
	ProfileNotReady = "Cargando tus datos…",
	ServerError = "Algo salió mal. Inténtalo de nuevo.",
	NetworkError = "Conexión inestable. Inténtalo de nuevo.",
}

function Net.message(err: string?): string
	return MESSAGES[err or ""] or "No se pudo completar la acción."
end

return Net
