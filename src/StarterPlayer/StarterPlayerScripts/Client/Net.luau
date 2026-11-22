--!strict
-- Cliente de red: envía solicitudes con número de secuencia creciente (el servidor
-- rechaza repeticiones) y reparte los mensajes "push" del servidor por tipo.
-- El cliente nunca envía cantidades: solo intenciones ("alimenta a X con Y").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contract = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"):WaitForChild("Contract"))

local PushBuffer = require(script.Parent.PushBuffer)

local Net = {}

local folder = ReplicatedStorage:WaitForChild(Contract.RemoteFolder)
local request = folder:WaitForChild(Contract.RequestName) :: RemoteFunction
local push = folder:WaitForChild(Contract.PushName) :: RemoteEvent

local seq = 0

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

-- Los mensajes que llegan antes de tener oyente se guardan (ver PushBuffer)
local buffer = PushBuffer.new({
	latestOnly = { Contract.Push.Profile },
	maxPending = 32,
	spawn = function(fn, payload)
		task.spawn(fn, payload)
	end,
})

function Net.on(kind: string, fn: (any) -> ())
	buffer.on(kind, fn)
end

push.OnClientEvent:Connect(function(kind: string, payload: any)
	if type(kind) == "string" then
		buffer.push(kind, payload)
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
	NoCompanion = "Elige un acompañante o un equipo primero.",
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
	-- Fase 2
	NotReady = "Aún no está listo para eclosionar.",
	SlotLocked = "Esa ranura de la incubadora está cerrada.",
	SlotBusy = "Esa ranura ya tiene un huevo.",
	SlotEmpty = "No hay ningún huevo en esa ranura.",
	EggStorageFull = "No caben más huevos guardados: incuba alguno primero.",
	ChestStorageFull = "Tu Repisa de Cofres está llena: abre alguno primero.",
	ChestNotFound = "Ese cofre ya no está.",
	NotAvailable = "No disponible en la beta.",
	PreviousSlotLocked = "Primero desbloquea la ranura anterior.",
	QuestNotComplete = "Aún no completas ese encargo.",
	AlreadyClaimed = "Ya lo reclamaste.",
	TeamTooCostly = "Tu equipo supera el coste máximo (12) para el jefe.",
	NotABattle = "Esta etapa es un tesoro: resuelve el acertijo.",
	WrongElement = "Ese elemento no abre el sello. ¡Prueba otro!",
	SecretLocked = "Consigue las 3 estrellas en todas las etapas de la región.",
	DecorNotOwned = "No tienes ese objeto de decoración.",
	BadTeamSize = "Elige de 1 a 3 monstruos.",
	DuplicatePet = "Ese monstruo ya está elegido.",
	InventoryAtMax = "El Vivero ya está al máximo.",
	TooManyPets = "La vitrina admite menos monstruos.",
}

function Net.message(err: string?): string
	return MESSAGES[err or ""] or "No se pudo completar la acción."
end

return Net
