--!strict
-- Ciclo de vida de los perfiles: carga con bloqueo de sesión, autoguardado, guardado
-- al salir y en BindToClose, y envío de la vista del perfil al cliente.
--
-- Almacén: Studio y servidores con jugadores en la lista de pruebas usan el DataStore
-- de PRUEBAS; solo el servidor publicado usa el de producción. Si Studio no tiene
-- acceso a la API, se usa un backend en memoria (los datos no persisten).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DevConfig = require(Shared.Config.Dev)
local Contract = require(Shared.Net.Contract)

local Server = script.Parent.Parent
local ProfileStore = require(Server.Persistence.ProfileStore)
local MemoryBackend = require(Server.Persistence.MemoryBackend)
local RobloxBackend = require(Server.Persistence.RobloxBackend)
local ProfileView = require(Server.Domain.ProfileView)
local Actions = require(Server.Domain.Actions)
local Log = require(Server.Util.Log).scope("Data")
local DevGate = require(script.Parent.DevGate)

local AUTOSAVE_SECONDS = 120

local PlayerDataService = {}
PlayerDataService.sessions = {} :: { [Player]: ProfileStore.Session }
PlayerDataService.loaded = Instance.new("BindableEvent")
PlayerDataService.store = (nil :: any) :: ProfileStore.ProfileStore
PlayerDataService.storeKind = "Unknown"

local analytics: any = nil
local pushRemote: RemoteEvent? = nil

local function chooseBackend(): (any, string)
	if RunService:IsStudio() then
		local ok = pcall(function()
			game:GetService("DataStoreService"):GetDataStore(DevConfig.TestDataStoreName):GetAsync("__probe")
		end)
		if ok then
			return RobloxBackend.new(DevConfig.TestDataStoreName), "StudioTestStore"
		end
		Log.warn("Studio sin acceso a la API de DataStore: datos solo en memoria")
		return MemoryBackend.new(), "Memory"
	end
	return RobloxBackend.new(DevConfig.ProductionDataStoreName), "Production"
end

function PlayerDataService.init(deps: { analytics: any })
	analytics = deps.analytics
	local backend, kind = chooseBackend()
	PlayerDataService.storeKind = kind
	PlayerDataService.store = ProfileStore.new({
		backend = backend,
		jobId = if game.JobId ~= "" then game.JobId else "studio-" .. tostring(os.time()),
		clock = os.time,
		wait = function(s: number)
			task.wait(s)
		end,
	})
	Log.info("Almacén de perfiles: %s", kind)
end

function PlayerDataService.setPushRemote(remote: RemoteEvent)
	pushRemote = remote
end

function PlayerDataService.get(player: Player): ProfileStore.Session?
	local s = PlayerDataService.sessions[player]
	if s and not s.lockLost and not s.released then
		return s
	end
	return nil
end

function PlayerDataService.ctx(player: Player): Actions.Ctx
	return DevGate.ctxFor(player, os.time())
end

function PlayerDataService.pushProfile(player: Player)
	local s = PlayerDataService.get(player)
	if s and pushRemote then
		pushRemote:FireClient(player, Contract.Push.Profile, ProfileView.build(s.data, os.time()))
	end
end

function PlayerDataService.toast(player: Player, kind: string, text: string)
	if pushRemote then
		pushRemote:FireClient(player, Contract.Push.Toast, { kind = kind, text = text })
	end
end

local function onPlayerAdded(player: Player)
	local session, err = PlayerDataService.store:load(player.UserId)
	if not player.Parent then
		-- Se fue mientras cargaba: liberar sin tocar nada más
		if session then
			PlayerDataService.store:saveWithRetry(session, true)
		end
		return
	end
	if not session then
		Log.error("No se pudo cargar el perfil de %d: %s", player.UserId, tostring(err))
		player:Kick("No pudimos cargar tus datos de forma segura. Vuelve a entrar en un momento.")
		return
	end
	PlayerDataService.sessions[player] = session
	local r = Actions.onLoad(session.data, PlayerDataService.ctx(player))
	if analytics then
		analytics.logResult(player, r)
		analytics.log(player, "session_start", { isNew = session.isNew })
	end
	PlayerDataService.loaded:Fire(player, session)
	PlayerDataService.pushProfile(player)
end

local function release(player: Player)
	local session = PlayerDataService.sessions[player]
	if not session then
		return
	end
	PlayerDataService.sessions[player] = nil
	session.data.playSeconds += math.max(0, os.time() - session.loadedAt)
	local ok, err = PlayerDataService.store:saveWithRetry(session, true)
	if analytics then
		analytics.log(player, "data_save_status", { ok = ok, reason = err or "release" })
		analytics.log(player, "session_end", { seconds = os.time() - session.loadedAt })
	end
	if not ok then
		Log.error("Guardado final fallido para %d: %s", player.UserId, tostring(err))
	end
end

function PlayerDataService.start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(release)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, session in pairs(PlayerDataService.sessions) do
				task.spawn(function()
					local ok, err = PlayerDataService.store:save(session, false)
					if not ok and err == "LockLost" then
						Log.warn("Bloqueo perdido para %d: se expulsa para evitar duplicados", player.UserId)
						PlayerDataService.sessions[player] = nil
						player:Kick("Tu partida se abrió en otro servidor.")
					elseif not ok and err ~= "SaveInProgress" then
						Log.warn("Autoguardado fallido %d: %s", player.UserId, tostring(err))
					end
				end)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(PlayerDataService.sessions) do
			pending += 1
			task.spawn(function()
				release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

-- Ejecuta una acción de dominio sobre el perfil del jugador y sincroniza.
function PlayerDataService.run(player: Player, fn: (profile: any, ctx: Actions.Ctx) -> any): any
	local session = PlayerDataService.get(player)
	if not session then
		return { ok = false, err = "ProfileNotReady" }
	end
	local result = fn(session.data, PlayerDataService.ctx(player))
	if analytics and type(result) == "table" then
		analytics.logResult(player, result)
	end
	PlayerDataService.pushProfile(player)
	return result
end

-- Reemplaza el perfil (solo DevService en Studio / almacén de pruebas).
function PlayerDataService.resetForDev(player: Player, fresh: any)
	local s = PlayerDataService.get(player)
	if s and PlayerDataService.storeKind ~= "Production" then
		s.data = fresh
	end
end

return PlayerDataService
