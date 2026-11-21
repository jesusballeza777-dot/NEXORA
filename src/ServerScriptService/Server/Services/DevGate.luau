--!strict
-- Autoriza la configuración de desarrollador. SOLO en Studio (incluidas las pruebas de
-- equipo de Studio), que siempre usa el almacén de pruebas. En un servidor publicado
-- devuelve SIEMPRE el contexto de producción (multiplicadores 1), aunque el UserId
-- esté en la lista: así un comando de prueba nunca escribe en el DataStore real.

local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DevConfig = require(Shared.Config.Dev)

local DevGate = {}

function DevGate.isDev(player: Player): boolean
	if not RunService:IsStudio() or not DevConfig.EnabledInStudio then
		return false
	end
	-- Lista vacía = cualquier jugador de la sesión de Studio
	return #DevConfig.AllowedUserIds == 0 or table.find(DevConfig.AllowedUserIds, player.UserId) ~= nil
end

function DevGate.ctxFor(player: Player, now: number)
	if DevGate.isDev(player) and player:GetAttribute("NexoDevBoost") == true then
		return {
			now = now,
			xpMultiplier = DevConfig.XpMultiplier,
			coinMultiplier = DevConfig.CoinMultiplier,
			skipCooldowns = DevConfig.SkipCooldowns,
		}
	end
	return { now = now }
end

return DevGate
