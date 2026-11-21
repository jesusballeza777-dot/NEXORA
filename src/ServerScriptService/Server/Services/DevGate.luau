--!strict
-- Autoriza la configuración de desarrollador. En el servidor publicado y para
-- jugadores normales devuelve SIEMPRE el contexto de producción (multiplicadores 1).

local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DevConfig = require(Shared.Config.Dev)

local DevGate = {}

function DevGate.isDev(player: Player): boolean
	if RunService:IsStudio() and DevConfig.EnabledInStudio then
		return true
	end
	return table.find(DevConfig.AllowedUserIds, player.UserId) ~= nil
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
