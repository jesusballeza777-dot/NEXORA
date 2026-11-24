--!strict
-- Ajustes de efectos del jugador (sesión): calidad (Baja/Media/Alta), movimiento reducido
-- (sin sacudidas, acercamientos de cámara ni destellos fuertes) y combate rápido.
-- Botones de 52 px (≥ 48 px) y textos ≥ 14 px (interfaz móvil primero).

local Kit = require(script.Parent.Parent.Kit)
local Modals = require(script.Parent.Parent.Modals)
local VFXSettings = require(script.Parent.Parent.Parent.VFX.VFXSettings)

local EffectsSettings = {}

local QUALITY = { Low = "Baja", Medium = "Media", High = "Alta" }

function EffectsSettings.open()
	local ui = Modals.UI
	local function build(content: ScrollingFrame)
		local v = VFXSettings.get()
		ui.title(content, "Efectos y movimiento")
		ui.sub(content, "Ajusta los efectos a tu dispositivo. La rareza se sigue viendo en las cartas y los marcos.")
		local row = Kit.new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = ui.order(),
			Parent = content,
			Kit.new("UIGridLayout", { CellSize = UDim2.new(1 / 3, -7, 0, 52), CellPadding = UDim2.fromOffset(10, 10) }),
		})
		for _, q in ipairs({ "Low", "Medium", "High" }) do
			Kit.button(QUALITY[q], if v.quality == q then "primary" else "secondary", function()
				VFXSettings.set("quality", q)
				EffectsSettings.open()
			end, { Parent = row })
		end
		Kit.button(
			(if v.reducedMotion then "✓ " else "") .. "Movimiento reducido",
			if v.reducedMotion then "jade" else "secondary",
			function()
				VFXSettings.set("reducedMotion", not v.reducedMotion)
				EffectsSettings.open()
			end,
			{ LayoutOrder = ui.order(), Parent = content }
		)
		ui.sub(content, "Sin sacudidas ni acercamientos de cámara y sin destellos fuertes.")
		Kit.button(
			(if v.fastBattle then "✓ " else "") .. "Combate rápido",
			if v.fastBattle then "jade" else "secondary",
			function()
				VFXSettings.set("fastBattle", not v.fastBattle)
				EffectsSettings.open()
			end,
			{ LayoutOrder = ui.order(), Parent = content }
		)
		ui.sub(content, "Las animaciones de ataque duran menos. En combate, ⏩ salta lo que se está viendo.")
	end
	Modals.open(build)
end

return EffectsSettings
