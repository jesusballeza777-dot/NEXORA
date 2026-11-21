--!strict
-- Analítica del vertical slice sobre AnalyticsService (Creator Analytics).
-- * Embudo de onboarding con LogOnboardingFunnelStepEvent (pasos en Config/Analytics).
-- * Eventos personalizados con LogCustomEvent.
-- * Todo envuelto en pcall: la analítica nunca rompe el juego.
-- No se inventan métricas: aquí solo se registran hechos del servidor.

local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AnalyticsConfig = require(Shared.Config.Analytics)
local AnalyticsFields = require(script.Parent.Parent.Util.AnalyticsFields)
local Log = require(script.Parent.Parent.Util.Log).scope("Analytics")

local AnalyticsTracker = {}

local funnelIndex: { [string]: number } = {}
for i, name in ipairs(AnalyticsConfig.OnboardingFunnel) do
	funnelIndex[name] = i
end

-- Claves fijas de los campos personalizados (formato en Util/AnalyticsFields)
local FIELD_KEYS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

function AnalyticsTracker.log(player: Player, name: string, fields: { [string]: any }?)
	if RunService:IsStudio() then
		Log.debug("%s %s", name, if fields then tostring(next(fields)) else "")
	end
	local custom, value = AnalyticsFields.encode(fields, FIELD_KEYS)
	local step = funnelIndex[name]
	if step then
		pcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name, custom :: any)
		end)
	end
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value, custom :: any)
	end)
end

-- Registra los eventos que devuelve una acción de dominio (data.analytics).
function AnalyticsTracker.logResult(player: Player, result: any)
	if type(result) ~= "table" or type(result.data) ~= "table" then
		return
	end
	local list = result.data.analytics
	if type(list) ~= "table" then
		return
	end
	for _, e in ipairs(list) do
		AnalyticsTracker.log(player, e.name, e.fields)
	end
end

return AnalyticsTracker
