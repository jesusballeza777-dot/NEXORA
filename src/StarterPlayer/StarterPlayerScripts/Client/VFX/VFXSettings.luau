--!strict
-- Ajustes de presentación del jugador en esta sesión: calidad de efectos (Low/Medium/High),
-- movimiento reducido (sin sacudidas, acercamientos ni destellos fuertes) y combate rápido
-- (secuencias al 60 %). No se guardan en el perfil: hacerlo exigiría un remote y una
-- migración del perfil (propuesta en docs/VFX_SYSTEM.md, «Decisiones propuestas»).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local VFX = require(Config:WaitForChild("VFX"))

local VFXSettings = {}

export type Values = { quality: string, reducedMotion: boolean, fastBattle: boolean }

local values: Values = { quality = VFX.DefaultQuality, reducedMotion = false, fastBattle = false }
local listeners: { (Values) -> () } = {}

function VFXSettings.get(): Values
	return values
end

local function notify()
	for _, fn in ipairs(listeners) do
		fn(values)
	end
end

function VFXSettings.set(key: string, value: any)
	if key == "quality" then
		assert((VFX.Quality :: any)[value], "Calidad desconocida: " .. tostring(value))
		values.quality = value
	elseif key == "reducedMotion" or key == "fastBattle" then
		(values :: any)[key] = value == true
	else
		error("Ajuste desconocido: " .. key)
	end
	notify()
end

function VFXSettings.onChanged(fn: (Values) -> ()): () -> ()
	table.insert(listeners, fn)
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

-- Valores iniciales a partir de la configuración del dispositivo, si existe. En Studio hay
-- que verificar que GuiService.ReducedMotionEnabled y SavedQualityLevel se leen bien: si
-- fallan, se quedan los valores por defecto.
function VFXSettings.detect()
	local okMotion, reduced = pcall(function()
		return (game:GetService("GuiService") :: any).ReducedMotionEnabled
	end)
	if okMotion and reduced == true then
		values.reducedMotion = true
	end
	local okQuality, level = pcall(function()
		return (UserSettings() :: any).GameSettings.SavedQualityLevel.Value
	end)
	if okQuality and type(level) == "number" and level > 0 then
		values.quality = if level <= 3 then "Low" elseif level <= 7 then "Medium" else "High"
	end
	notify()
end

function VFXSettings.reset()
	values = { quality = VFX.DefaultQuality, reducedMotion = false, fastBattle = false }
	table.clear(listeners)
end

return VFXSettings
