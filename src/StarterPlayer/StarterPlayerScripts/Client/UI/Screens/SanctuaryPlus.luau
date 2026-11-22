--!strict
-- Santuario ampliado (Fase 2): decoración en 6 espacios (en el propio lote), plantillas,
-- vitrina de exhibición, ampliación del Vivero y títulos. Todo lo valida el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Decor = require(Config:WaitForChild("Decor"))
local Sanctuary = require(Config:WaitForChild("Sanctuary"))

local UI = script.Parent.Parent
local Kit = require(UI.Kit)
local Modals = require(UI.Modals)
local Net = require(UI.Parent.Net)
local State = require(UI.Parent.State)

local SanctuaryPlus = {}

function SanctuaryPlus.decor()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Decorar el Lote Hogar")
		ui.sub(content, "Seis espacios alrededor del hábitat. Hazlo en tu lote: el servidor lo comprueba.")
		for slot = 1, Decor.FreeSlots do
			local current = view.decor.slots[slot]
			local name = if current then Decor.ById[current].name else "vacío"
			Kit.text(string.format("Espacio %d · %s", slot, name), 16, {
				FontFace = Kit.Font.bodyHeavy,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = ui.order(),
				Parent = content,
			})
			local options = {}
			for _, id in ipairs(Decor.Order) do
				if (view.decor.owned[id] or 0) > 0 and id ~= current then
					table.insert(
						options,
						Kit.button(Decor.ById[id].name, "secondary", function()
							ui.respond(Net.request("Sanctuary.PlaceDecor", slot, id), "Colocado")
							SanctuaryPlus.decor()
						end)
					)
				end
			end
			if current then
				table.insert(
					options,
					Kit.button("Quitar", "secondary", function()
						ui.respond(Net.request("Sanctuary.ClearDecor", slot))
						SanctuaryPlus.decor()
					end)
				)
			end
			if #options > 0 then
				local grid = Kit.new("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = ui.order(),
					Parent = content,
					Kit.new(
						"UIGridLayout",
						{ CellSize = UDim2.new(0.5, -4, 0, 48), CellPadding = UDim2.fromOffset(8, 6) }
					),
				})
				for _, b in ipairs(options) do
					b.Parent = grid
				end
			end
		end
		ui.sub(content, "<b>Plantillas</b> (colocan lo que ya tienes en los espacios libres)")
		for _, t in ipairs(Decor.Templates) do
			Kit.button(t.name, "jade", function()
				ui.respond(Net.request("Sanctuary.Template", t.id), "Plantilla aplicada")
				SanctuaryPlus.decor()
			end, { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = ui.order(), Parent = content })
		end
		local owned = 0
		for _ in pairs(view.decor.owned) do
			owned += 1
		end
		if owned == 0 then
			ui.sub(content, "Consigue objetos de decoración en el Acto I: tesoros, regiones y Copalia.")
		end
	end)
end

function SanctuaryPlus.showcase()
	local view = State.view
	if not view then
		return
	end
	local selected = table.clone(view.showcase)
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Vitrina de exhibición")
		ui.sub(content, string.format("Elige hasta %d monstruos para lucirlos en tu lote.", Sanctuary.VitrinaSlots))
		for _, pet in ipairs(view.pets) do
			local on = table.find(selected, pet.id) ~= nil
			Kit.button(
				string.format(
					"%s%s · %s · nv %d",
					if on then "✔ " else "",
					Kit.escape(pet.name),
					pet.form,
					pet.level
				),
				if on then "jade" else "secondary",
				function()
					local idx = table.find(selected, pet.id)
					if idx then
						table.remove(selected, idx)
					elseif #selected < Sanctuary.VitrinaSlots then
						table.insert(selected, pet.id)
					end
					ui.respond(Net.request("Sanctuary.Showcase", table.concat(selected, ",")))
					SanctuaryPlus.showcase()
				end,
				{ Size = UDim2.new(1, 0, 0, 48), LayoutOrder = ui.order(), Parent = content }
			)
		end
		ui.sub(
			content,
			string.format(
				"Vivero: %d / %d monstruos (máx. %d)",
				view.inventoryUsed,
				view.inventoryCapacity,
				Sanctuary.InventoryMaxCapacity
			)
		)
		if view.inventoryCapacity < Sanctuary.InventoryMaxCapacity then
			local rule = Sanctuary.InventoryExpansion
			Kit.button(
				string.format("Ampliar Vivero +%d · %d Monedas", rule.step, rule.price.Monedas),
				"primary",
				function()
					ui.respond(Net.request("Sanctuary.Expand"), "Vivero ampliado")
					SanctuaryPlus.showcase()
				end,
				{ Size = UDim2.new(1, 0, 0, 48), LayoutOrder = ui.order(), Parent = content }
			)
		end
		local titles = {}
		for id in pairs(view.titles.owned) do
			table.insert(titles, id)
		end
		if #titles > 0 then
			ui.sub(content, "<b>Títulos</b>")
			for _, id in ipairs(titles) do
				Kit.button((if view.titles.equipped == id then "✔ " else "") .. id, "secondary", function()
					ui.respond(Net.request("Title.Equip", if view.titles.equipped == id then "none" else id))
					SanctuaryPlus.showcase()
				end, { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = ui.order(), Parent = content })
			end
		end
	end)
end

return SanctuaryPlus
