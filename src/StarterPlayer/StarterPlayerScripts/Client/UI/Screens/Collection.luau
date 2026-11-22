--!strict
-- Álbum del Nexo, Bestiario y Códice (Fase 2). Solo muestra lo que el servidor registró
-- (view.collection / view.codex); los textos vienen de Config (SpeciesLore, Codex).
-- Rendimiento: el Álbum nunca construye los 50 modelos a la vez. Cada carta descubierta
-- recibe su retrato 3D solo cuando entra en la zona visible del desplazamiento.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Species = require(Config:WaitForChild("Species"))
local SpeciesLore = require(Config:WaitForChild("SpeciesLore"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Elements = require(Config:WaitForChild("Elements"))
local Visuals = require(Config:WaitForChild("Visuals"))
local Codex = require(Config:WaitForChild("Codex"))

local UI = script.Parent.Parent
local Kit = require(UI.Kit)
local Modals = require(UI.Modals)
local CreatureBuilder = require(UI.Parent.Creatures.CreatureBuilder)
local State = require(UI.Parent.State)

local Collection = {}

local BIOME_ORDER = { "ValleCopal", "MareaCoralina", "CumbreBrasa", "MesetaFulgor", "VeloAstral", "TorreDelNexo" }
local BIOME_TINT: { [string]: Color3 } = {
	ValleCopal = Color3.fromRGB(86, 128, 82),
	MareaCoralina = Color3.fromRGB(52, 110, 140),
	CumbreBrasa = Color3.fromRGB(140, 70, 48),
	MesetaFulgor = Color3.fromRGB(120, 110, 60),
	VeloAstral = Color3.fromRGB(70, 60, 120),
	TorreDelNexo = Color3.fromRGB(110, 86, 60),
}
local MAX_NEW_PORTRAITS_PER_FRAME = 2

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function elementDots(elements: { string }): string
	local parts = {}
	for _, e in ipairs(elements) do
		local c = rgb(Elements.ById[e].color)
		table.insert(parts, string.format('<font color="#%s">●</font> %s', c:ToHex(), e))
	end
	return table.concat(parts, "  ")
end

local function discovered(entry: any): boolean
	return entry ~= nil and (entry.seenAt or entry.restoredAt or entry.broteAt or entry.talladoAt) ~= nil
end

local function tier(entry: any): number
	if not entry then
		return 0
	end
	if entry.talladoAt then
		return 3
	elseif entry.restoredAt or entry.broteAt then
		return 2
	elseif entry.seenAt then
		return 1
	end
	return 0
end

-- Carta pequeña del Álbum: marco por rareza, gema, número, fondo del bioma.
local function albumCard(parent: Instance, speciesId: string, form: string, entry: any, onTap: () -> ())
	local sp = Species.ById[speciesId]
	local rar = Rarities.ById[sp.rarity]
	local known = discovered(entry)
	local owned = entry and (if form == "Tallado" then entry.talladoAt else entry.broteAt) ~= nil
	local frame = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = if known then BIOME_TINT[sp.biome] else Color3.fromRGB(34, 28, 24),
		LayoutOrder = sp.number,
		Parent = parent,
		Kit.corner(12),
		Kit.stroke(rgb(rar.frameColor), if owned then 3 else 1.5, if owned then 0 else 0.5),
	})
	-- Gema de rareza arriba a la izquierda (p. 25)
	Kit.new("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(6, 6),
		Rotation = 45,
		BackgroundColor3 = rgb(rar.frameColor),
		Parent = frame,
	})
	Kit.text(string.format("#%d", sp.number), 13, {
		Size = UDim2.new(1, -12, 0, 16),
		Position = UDim2.fromOffset(6, 4),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Kit.Color.muted,
		Parent = frame,
	})
	local holder = Kit.new("Frame", {
		Name = "Portrait",
		Size = UDim2.new(1, -8, 1, -46),
		Position = UDim2.fromOffset(4, 20),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	if not known then
		Kit.text("?", 34, {
			Size = UDim2.fromScale(1, 1),
			FontFace = Kit.Font.title,
			TextColor3 = Color3.fromRGB(70, 60, 54),
			Parent = holder,
		})
	end
	Kit.text(if known then (if form == "Tallado" then sp.talladoName else sp.broteName) else "???", 14, {
		FontFace = Kit.Font.bodyHeavy,
		Size = UDim2.new(1, -6, 0, 22),
		Position = UDim2.new(0, 3, 1, -24),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
		Parent = frame,
	})
	frame.Activated:Connect(function()
		if known then
			onTap()
		end
	end)
	frame:SetAttribute("SpeciesId", speciesId)
	frame:SetAttribute("Form", form)
	frame:SetAttribute("Portrait", known and Visuals.ById[speciesId] ~= nil and (owned or form == "Brote"))
	return frame
end

-- Crea retratos 3D solo para las cartas visibles (y como mucho 2 por fotograma).
local function lazyPortraits(scroller: ScrollingFrame, grid: Instance)
	local done: { [Instance]: boolean } = {}
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not scroller.Parent then
			conn:Disconnect()
			return
		end
		local top = scroller.AbsolutePosition.Y
		local bottom = top + scroller.AbsoluteSize.Y
		local made = 0
		for _, cardFrame in ipairs(grid:GetChildren()) do
			if made >= MAX_NEW_PORTRAITS_PER_FRAME then
				break
			end
			if cardFrame:IsA("GuiButton") and not done[cardFrame] and cardFrame:GetAttribute("Portrait") then
				local y = cardFrame.AbsolutePosition.Y
				if y + cardFrame.AbsoluteSize.Y >= top - 40 and y <= bottom + 40 then
					done[cardFrame] = true
					made += 1
					local vp = CreatureBuilder.portrait(
						cardFrame:GetAttribute("SpeciesId"),
						cardFrame:GetAttribute("Form"),
						UDim2.fromScale(1, 1)
					)
					vp.Parent = cardFrame:FindFirstChild("Portrait")
				end
			end
		end
	end)
end

function Collection.album(startBiome: string?, startForm: string?)
	local view = State.view
	if not view then
		return
	end
	local biome = startBiome or "ValleCopal"
	local form = startForm or "Brote"
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Álbum del Nexo")
		local prog = view.collectionProgress
		ui.sub(
			content,
			string.format(
				"%d de %d especies descubiertas · %d de %d cartas",
				prog.discovered,
				prog.totalSpecies,
				prog.cards,
				prog.totalCards
			)
		)
		-- Pestañas de bioma (progreso por bioma)
		local tabs = Kit.new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 3,
			LayoutOrder = ui.order(),
			Parent = content,
			Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left),
		})
		for _, b in ipairs(BIOME_ORDER) do
			local bp = prog.byBiome[b]
			if bp then
				local label = string.format("%s %d/%d", Species.Biomes[b].name, bp.cards, bp.total * 2)
				Kit.button(label, if b == biome then "primary" else "secondary", function()
					Collection.album(b, form)
				end, { Size = UDim2.fromOffset(150, 48), Parent = tabs })
			end
		end
		ui.row(content, {
			Kit.button("Brotes", if form == "Brote" then "jade" else "secondary", function()
				Collection.album(biome, "Brote")
			end),
			Kit.button("Tallados", if form == "Tallado" then "jade" else "secondary", function()
				Collection.album(biome, "Tallado")
			end),
		})
		local grid = Kit.new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = ui.order(),
			Parent = content,
			Kit.new("UIGridLayout", {
				CellSize = UDim2.fromOffset(104, 150),
				CellPadding = UDim2.fromOffset(8, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		for _, id in ipairs(Species.Order) do
			if Species.ById[id].biome == biome then
				albumCard(grid, id, form, view.collection[id], function()
					Collection.bestiary(id)
				end)
			end
		end
		local bp = prog.byBiome[biome]
		if bp and bp.complete then
			ui.sub(content, "✨ Bioma completo: marco especial desbloqueado.")
		end
		lazyPortraits(content, grid)
	end)
end

-- Ficha del Bestiario: se revela por niveles (visto → restaurado/obtenido → Tallado)
function Collection.bestiary(speciesId: string)
	local view = State.view
	if not view then
		return
	end
	local sp = Species.ById[speciesId]
	local lore = SpeciesLore.ById[speciesId]
	local entry = view.collection[speciesId]
	local level = tier(entry)
	local ui = Modals.UI
	Modals.open(function(content)
		if entry and entry.broteAt and Visuals.ById[speciesId] then
			ui.card(content, speciesId, "Brote", sp.broteName, string.format("#%d · Brote", sp.number))
		else
			ui.title(content, string.format("#%d %s", sp.number, sp.broteName))
		end
		local function line(label: string, text: string?)
			if text and text ~= "" and text ~= "Pendiente" then
				ui.sub(content, string.format("<b>%s</b> · %s", label, Kit.escape(text)))
			end
		end
		ui.sub(
			content,
			string.format(
				"%s · %s · %s",
				Rarities.ById[sp.rarity].name,
				Species.Biomes[sp.biome].name,
				elementDots(sp.elements)
			)
		)
		line("Concepto", lore.concept)
		if level >= 2 then
			line("Rol", sp.role)
			line("Brote", lore.broteLook)
			line("Comportamiento", lore.behavior)
			line("Hábitat", lore.habitat)
			line("Mezcla mítica", lore.mythicMix)
			line("Anatomía", lore.anatomy)
		else
			ui.sub(content, "🔒 Restaura u obtén esta especie para conocer más.")
		end
		if level >= 3 then
			if Visuals.ById[speciesId] then
				ui.card(content, speciesId, "Tallado", sp.talladoName, string.format("#%d · Tallado", sp.number))
			end
			line("Tallado", lore.talladoLook)
			line("Rasgo distintivo", lore.distinctiveTrait)
		elseif level >= 2 then
			ui.sub(content, "🔒 Tállalo para revelar su forma imponente.")
		end
		line("Obtención", lore.obtention)
	end)
end

function Collection.codex()
	local view = State.view
	if not view then
		return
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Códice del Nexo")
		local unlocked = 0
		for _, id in ipairs(Codex.Order) do
			if view.codex[id] then
				unlocked += 1
			end
		end
		ui.sub(content, string.format("%d de %d cartas del Acto I", unlocked, #Codex.Order))
		for _, kind in ipairs({ "Lore", "Guardian", "Velada" }) do
			ui.sub(
				content,
				if kind == "Lore"
					then "<b>Cartas de lore</b>"
					elseif kind == "Guardian" then "<b>Seres Sagrados</b>"
					else "<b>Pistas Veladas</b>"
			)
			for _, id in ipairs(Codex.Order) do
				local e = Codex.ById[id]
				if e.kind == kind then
					local open = view.codex[id] ~= nil
					Kit.panel({
						Size = UDim2.new(1, 0, 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = if open then Kit.Color.cocoa700 else Kit.Color.cocoa900,
						LayoutOrder = ui.order(),
						Parent = content,
						Kit.padding(10),
						Kit.list(Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Left),
						Kit.text(
							if open then e.symbol .. "  " .. e.title else "🔒  ???",
							17,
							{ FontFace = Kit.Font.title, TextXAlignment = Enum.TextXAlignment.Left }
						),
						Kit.text(if open then e.text else "Sigue explorando el Valle Copal.", 15, {
							TextColor3 = Kit.Color.muted,
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.new(1, 0, 0, 0),
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
					})
				end
			end
		end
	end)
end

return Collection
