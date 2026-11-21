--!strict
-- Punto de entrada del servidor. Orden explícito de inicialización (sin magia):
--   init(): crear estado e instancias, registrar manejadores
--   start(): conectar eventos de jugadores y bucles
-- Las dependencias se pasan de forma explícita: no hay variables globales.

local RunService = game:GetService("RunService")
local Server = script.Parent:WaitForChild("Server")
local Services = Server:WaitForChild("Services")

local Log = require(Server.Util.Log)
local log = Log.scope("Bootstrap")
if RunService:IsStudio() then
	Log.level = 1
end

local AnalyticsTracker = require(Services.AnalyticsTracker)
local PlayerDataService = require(Services.PlayerDataService)
local RemoteGateway = require(Services.RemoteGateway)
local WorldService = require(Services.WorldService)
local GameplayService = require(Services.GameplayService)
local BattleService = require(Services.BattleService)
local DevService = require(Services.DevService)
local DevGate = require(Services.DevGate)
local ProfileView = require(Server.Domain.ProfileView)

local started = os.clock()

WorldService.init()
PlayerDataService.init({ analytics = AnalyticsTracker })
RemoteGateway.init({ data = PlayerDataService, world = WorldService, analytics = AnalyticsTracker })
PlayerDataService.setPushRemote(RemoteGateway.push)
GameplayService.init({ data = PlayerDataService, world = WorldService, gateway = RemoteGateway })
BattleService.init({ data = PlayerDataService, gateway = RemoteGateway, analytics = AnalyticsTracker })
DevService.init({ data = PlayerDataService, gateway = RemoteGateway })

-- Al cargar un perfil: publicar estado público y, en Studio, activar el modo de prueba
PlayerDataService.loaded.Event:Connect(function(player: Player, session: any)
	WorldService.publish(player, ProfileView.build(session.data, os.time()))
	if DevGate.isDev(player) then
		DevService.setBoost(player, true)
	end
end)

WorldService.start()
RemoteGateway.start()
BattleService.start()
PlayerDataService.start()

log.info("Servidor listo en %.2fs (almacén: %s)", os.clock() - started, PlayerDataService.storeKind)
