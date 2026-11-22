--!strict
-- Criadero (huevos e incubadora), Repisa de Cofres, Tablón de Encargos e Historial.
-- La cuenta atrás usa los timestamps del servidor (readyAt) corregidos con la diferencia
-- entre el reloj del servidor y el del dispositivo: cambiar la hora del teléfono no
-- adelanta nada, porque la eclosión la valida el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Species = require(Config:WaitForChild("Species"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Chests = require(Config:WaitForChild("Chests"))
local Economy = require(Config:WaitForChild("Economy"))
local Gabinete = require(Config:WaitForChild("Gabinete"))

local UI = script.Parent.Parent
local Kit = require(UI.Kit)
local Modals = require(UI.Modals)
local Ceremony = require(UI.Ceremony)
local Net = require(UI.Parent.Net)
local State = require(UI.Parent.State)

local Breeding = {}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function clockOffset(): number
	local view = State.view
	return if view then view.serverTime - os.time() else 0
end

local function fmt(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d h %02d min", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- Actualiza etiquetas mientras la ventana siga abierta
local function ticker(anchor: Instance, update: (now: number) -> ())
	local conn: RBXScriptConnection
	local acc = 0
	conn = RunService.Heartbeat:Connect(function(dt)
		if not anchor.Parent then
			conn:Disconnect()
			return
		end
		acc += dt
		if acc >= 0.5 then
			acc = 0
			update(os.time() + clockOffset())
		end
	end)
end

local function speciesName(id: string): string
	local sp = Species.ById[id]
	return if sp then sp.broteName else id
end

function Breeding.incubator()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Criadero · Incubadora")
		ui.sub(
			content,
			string.format(
				"Huevos guardados: %d/%d. La especie de cada huevo ya está decidida: lo que ves es lo que nace.",
				view.eggStorage.used,
				view.eggStorage.capacity
			)
		)
		local stored = {}
		for _, egg in ipairs(view.eggs) do
			if egg.state == "Stored" then
				table.insert(stored, egg)
			end
		end
		for _, slot in ipairs(view.incubators) do
			local panel = Kit.panel({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = ui.order(),
				Parent = content,
				Kit.padding(10),
				Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left),
			})
			local head = string.format("Ranura %d", slot.slot)
			if not slot.unlocked then
				Kit.text("🔒 " .. head .. " · " .. slot.unlockLabel, 16, {
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					Parent = panel,
				})
				if slot.buyable then
					Kit.button(string.format("Desbloquear · %d Monedas", slot.price.Monedas), "primary", function()
						ui.respond(Net.request("Incubator.BuySlot", slot.slot), "Ranura desbloqueada")
						Breeding.incubator()
					end, { Size = UDim2.new(1, 0, 0, 48), Parent = panel })
				end
			elseif slot.eggId then
				local rar = Rarities.ById[slot.rarity]
				Kit.text(
					string.format("🥚 %s · Huevo de %s (%s)", head, speciesName(slot.speciesId), rar.name),
					16,
					{ FontFace = Kit.Font.bodyHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }
				)
				local bar, setBar = Kit.bar(slot.progress, rgb(rar.frameColor), 14)
				Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = panel, bar })
				local label = Kit.text("", 15, { TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
				local hatchButton = Kit.button("¡Eclosionar!", "jade", function()
					local r = Net.request("Egg.Hatch", slot.slot)
					if r.ok then
						Modals.close()
						Ceremony.hatch(r.data.speciesId, nil, r.data.newSpecies)
					else
						ui.respond(r)
					end
				end, { Size = UDim2.new(1, 0, 0, 48), Visible = slot.ready, Parent = panel })
				local function update(now: number)
					local total = math.max(1, slot.readyAt - slot.startedAt)
					local left = slot.readyAt - now
					setBar(math.clamp(1 - left / total, 0, 1))
					-- Grietas de luz al 25 %, 50 % y 75 % (p. 102)
					local p = 1 - left / total
					local cracks = if p >= 0.75
						then " ✦✦✦"
						elseif p >= 0.5 then " ✦✦"
						elseif p >= 0.25 then " ✦"
						else ""
					label.Text = if left <= 0 then "Listo para eclosionar" else "Faltan " .. fmt(left) .. cracks
					hatchButton.Visible = left <= 0
				end
				update(os.time() + clockOffset())
				ticker(panel, update)
			else
				Kit.text(
					"○ " .. head .. " · vacía",
					16,
					{ TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }
				)
				for _, egg in ipairs(stored) do
					local rar = Rarities.ById[egg.rarity]
					Kit.button(
						string.format("Incubar %s · %s · %s", speciesName(egg.speciesId), rar.name, fmt(egg.seconds)),
						"secondary",
						function()
							ui.respond(Net.request("Egg.Incubate", egg.id, slot.slot), "Huevo en la incubadora")
							Breeding.incubator()
						end,
						{ Size = UDim2.new(1, 0, 0, 48), Parent = panel }
					)
				end
				if #stored == 0 then
					Kit.text("Consigue huevos en cofres, rescates y encargos.", 14, {
						TextColor3 = Kit.Color.muted,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = panel,
					})
				end
			end
		end
	end)
end

function Breeding.chests()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Repisa de Cofres")
		ui.sub(content, "🗄 <i>«" .. Gabinete.Lines.Shelf .. "»</i>")
		if #view.chests == 0 then
			ui.sub(content, "🗄 <i>«" .. Gabinete.Lines.Empty .. "»</i>")
		end
		for _, chest in ipairs(view.chests) do
			local def = Chests.ById[chest.chestType]
			local lines = {}
			for cur, v in pairs(chest.contents.currencies) do
				table.insert(lines, string.format("%d %s", v, cur))
			end
			for item, v in pairs(chest.contents.items) do
				local food = Economy.Foods[item]
				table.insert(lines, string.format("%d × %s", v, if food then food.name else item))
			end
			local voice = Gabinete.Lines.Odds
			for _, egg in ipairs(chest.contents.eggs) do
				table.insert(lines, "Huevo de " .. speciesName(egg.speciesId))
				voice = string.format(Gabinete.Lines.Fixed, speciesName(egg.speciesId))
			end
			table.insert(lines, 1, "🗄 «" .. voice .. "»")
			Kit.panel({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = ui.order(),
				Parent = content,
				Kit.stroke(rgb(def.glow), 2),
				Kit.padding(10),
				Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left),
				Kit.text(
					"🎁 " .. def.name,
					18,
					{ FontFace = Kit.Font.title, TextXAlignment = Enum.TextXAlignment.Left }
				),
				Kit.text(chest.odds.note .. "\n" .. table.concat(lines, " · "), 15, {
					TextColor3 = Kit.Color.muted,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Kit.button("Abrir", "primary", function()
					local r = Net.request("Chest.Open", chest.id)
					if r.ok then
						Modals.close()
						Ceremony.chest(chest.chestType, r.data)
					else
						ui.respond(r)
					end
				end, { Size = UDim2.new(1, 0, 0, 48) }),
			})
		end
	end)
end

function Breeding.quests()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Tablón de Encargos")
		local resetLabel = Kit.text("", 15, {
			TextColor3 = Kit.Color.muted,
			LayoutOrder = ui.order(),
			Parent = content,
		})
		ticker(resetLabel, function(now)
			resetLabel.Text = string.format(
				"Nuevos encargos en %s · semanal en %s",
				fmt(view.quests.nextDailyReset - now),
				fmt(view.quests.nextWeeklyReset - now)
			)
		end)
		local function questPanel(q: any)
			if not q then
				return
			end
			local panel = Kit.panel({
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = ui.order(),
				Parent = content,
				Kit.padding(10),
				Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left),
				Kit.text(
					string.format(
						"%s%s · %d Monedas",
						if q.kind == "Weekly" then "Semanal · " else "",
						q.title,
						q.coins
					),
					17,
					{ FontFace = Kit.Font.title, TextXAlignment = Enum.TextXAlignment.Left }
				),
				Kit.text(q.description, 15, {
					TextColor3 = Kit.Color.muted,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
				}),
			})
			local bar = Kit.bar(q.progress / q.target, Kit.Color.jade, 12)
			Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Parent = panel, bar })
			if q.claimed then
				Kit.text("✔ Reclamado", 15, { TextColor3 = Kit.Color.ok, Parent = panel })
			elseif q.complete then
				Kit.button("Reclamar", "jade", function()
					local r = Net.request("Quest.Claim", q.kind, q.index)
					if r.ok and r.data.chestType then
						Ceremony.chest(r.data.chestType, { currencies = { Monedas = r.data.coins } })
					end
					ui.respond(r, if r.ok then string.format("+%d Monedas", r.data.coins) else nil)
					Breeding.quests()
				end, { Size = UDim2.new(1, 0, 0, 48), Parent = panel })
			else
				Kit.text(string.format("%d / %d", q.progress, q.target), 15, { Parent = panel })
			end
		end
		for _, q in ipairs(view.quests.daily) do
			questPanel(q)
		end
		ui.sub(
			content,
			if view.quests.dailyBonusClaimed
				then "✔ Cofre de Madera de hoy reclamado."
				else "Completa los tres encargos de hoy para ganar un Cofre de Madera."
		)
		questPanel(view.quests.weekly)
	end)
end

function Breeding.history()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Historial de obtenciones")
		for _, h in ipairs(view.history) do
			local what = if h.speciesId then speciesName(h.speciesId) else (h.detail or h.ref)
			ui.sub(
				content,
				string.format("%s · %s · %s · %s", os.date("%d/%m %H:%M", h.at), h.kind, what, h.source or "")
			)
		end
	end)
end

return Breeding
