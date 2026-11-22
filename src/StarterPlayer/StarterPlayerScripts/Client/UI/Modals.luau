--!strict
-- Ventanas modales del vertical slice. Cada botón envía una solicitud al servidor
-- (Net.request); la interfaz se actualiza cuando llega la nueva vista del perfil.
-- Nunca se calcula aquí ningún resultado: solo se muestra lo que decide el servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Economy = require(Config:WaitForChild("Economy"))
local Species = require(Config:WaitForChild("Species"))
local Talents = require(Config:WaitForChild("Talents"))
local Abilities = require(Config:WaitForChild("Abilities"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Elements = require(Config:WaitForChild("Elements"))
local Onboarding = require(Config:WaitForChild("Onboarding"))
local Encounters = require(Config:WaitForChild("Encounters"))
local SpeciesLore = require(Config:WaitForChild("SpeciesLore"))
local Progression = require(Config:WaitForChild("Progression"))
local Chests = require(Config:WaitForChild("Chests"))
local Decor = require(Config:WaitForChild("Decor"))
local Gabinete = require(Config:WaitForChild("Gabinete"))

local Kit = require(script.Parent.Kit)
local CreatureBuilder = require(script.Parent.Parent.Creatures.CreatureBuilder)
local Net = require(script.Parent.Parent.Net)
local State = require(script.Parent.Parent.State)
local Ceremony = require(script.Parent.Ceremony)

local Modals = {}

local FOOD_ICON = { RacionBasica = "🌽", RacionBioma = "🥗", Festin = "🍲", RacionDorada = "🍯" }

local gui: ScreenGui
local current: Frame? = nil
local hud: any
local onClosed: (() -> ())? = nil

function Modals.init(hudModule: any)
	hud = hudModule
	gui = Kit.screen("NexoModals", 20)
end

function Modals.isOpen(): boolean
	return current ~= nil
end

function Modals.close()
	if current then
		(current.Parent :: Instance):Destroy()
		current = nil
	end
	if onClosed then
		local cb = onClosed
		onClosed = nil
		cb()
	end
end

-- Abre una ventana con contenido desplazable. build(content) añade los elementos.
function Modals.open(build: (content: ScrollingFrame) -> (), opts: { noClose: boolean?, onClosed: (() -> ())? }?)
	Modals.close()
	onClosed = opts and opts.onClosed or nil
	local dim = Kit.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})
	local panel = Kit.panel({
		Size = UDim2.new(0.94, 0, 0.9, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = dim,
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(470, 760) }),
	})
	local content = Kit.new("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -28),
		Position = UDim2.fromOffset(12, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Kit.Color.copal,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
		Kit.list(Enum.FillDirection.Vertical, 10),
		Kit.new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }),
	})
	if not (opts and opts.noClose) then
		Kit.button("✕", "secondary", Modals.close, {
			Size = UDim2.fromOffset(42, 42),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			ZIndex = 5,
			Parent = panel,
		})
	end
	current = panel
	build(content)
	Kit.pop(panel)
end

local order = 0
local function o(): number
	order += 1
	return order
end
local function title(content: Instance, text: string)
	Kit.text(
		text,
		24,
		{ FontFace = Kit.Font.title, TextColor3 = Kit.Color.copalGlow, LayoutOrder = o(), Parent = content }
	)
end
local function sub(content: Instance, text: string)
	Kit.text(text, 15, {
		TextColor3 = Kit.Color.muted,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = o(),
		Parent = content,
	})
end
local function row(content: Instance, children: { Instance }): Frame
	local f = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		LayoutOrder = o(),
		Parent = content,
		Kit.new(
			"UIGridLayout",
			{ CellSize = UDim2.new(1 / #children, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0) }
		),
	})
	for _, c in ipairs(children) do
		c.Parent = f
	end
	return f
end
local function respond(r: Net.Response, success: string?)
	if r.ok then
		if success then
			hud.toast("✔", success)
		end
	else
		hud.toast("⚠", Net.message(r.err))
	end
end

-- Carta de monstruo (marco por rareza, fondo del bioma, pedestal, retrato 3D)
local function card(content: Instance, speciesId: string, form: string, name: string, caption: string)
	local sp = Species.ById[speciesId]
	local rar = Rarities.ById[sp.rarity]
	local frame = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 290),
		BackgroundColor3 = Color3.fromRGB(86, 128, 82),
		LayoutOrder = o(),
		Parent = content,
		Kit.corner(16),
		Kit.new(
			"UIStroke",
			{ Color = Color3.fromRGB(rar.frameColor[1], rar.frameColor[2], rar.frameColor[3]), Thickness = 4 }
		),
		Kit.new(
			"UIGradient",
			{ Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 190, 120), Color3.fromRGB(40, 70, 50)) }
		),
	})
	local vp = CreatureBuilder.portrait(speciesId, form, UDim2.fromOffset(200, 200))
	vp.AnchorPoint = Vector2.new(0.5, 0)
	vp.Position = UDim2.new(0.5, 0, 0, 10)
	vp.Parent = frame
	local els = {}
	for _, e in ipairs(sp.elements) do
		table.insert(els, e)
	end
	Kit.text("◆ " .. rar.name .. "   " .. table.concat(els, " · "), 13, {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Kit.Font.bodyHeavy,
		Parent = frame,
	})
	Kit.text(name, 26, { FontFace = Kit.Font.title, Position = UDim2.new(0, 0, 0, 210), Parent = frame })
	Kit.text(caption, 13, {
		Position = UDim2.new(0, 10, 0, 242),
		Size = UDim2.new(1, -20, 0, 40),
		TextColor3 = Kit.Color.copalSoft,
		Parent = frame,
	})
end

-- ===================== Introducción =====================
local INTRO = {
	{ "🪵", "Una gubia talla una espiral de copal… y la espiral se enciende." },
	{ "✨", "Las virutas se vuelven luz y dibujan Brotes que corren por el aire." },
	{ "🌳", "El Gran Nexo despierta y los cinco biomas aparecen como un mapa vivo." },
	{ "🌫️", "Pero una niebla gris apaga los colores: el Opacamiento." },
	{ "🥚", "Un huevo de luz cae en el santuario… y se divide en tres." },
}
function Modals.intro(onFinish: (skipped: boolean) -> ())
	local screen = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(18, 11, 7),
		ZIndex = 50,
		Parent = gui,
	})
	local i = 0
	local finished = false
	local function finish(skipped: boolean)
		if finished then
			return
		end
		finished = true
		screen:Destroy()
		onFinish(skipped)
	end
	local body = Kit.new("Frame", {
		Size = UDim2.fromScale(0.9, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = screen,
		Kit.list(Enum.FillDirection.Vertical, 14),
	})
	local glyph = Kit.text(
		"NEXORA",
		64,
		{ FontFace = Kit.Font.title, TextColor3 = Kit.Color.copalGlow, ZIndex = 52, LayoutOrder = 1, Parent = body }
	)
	local line = Kit.text(
		"Tierno al nacer. Imponente al tallarse.",
		20,
		{ TextColor3 = Kit.Color.copalSoft, ZIndex = 52, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 60), Parent = body }
	)
	local nextBtn = Kit.button(
		"Comenzar",
		"primary",
		nil,
		{ Size = UDim2.fromOffset(220, 52), ZIndex = 52, LayoutOrder = 3, Parent = body }
	)
	Kit.button("Saltar", "secondary", function()
		finish(true)
	end, {
		Size = UDim2.fromOffset(110, 44),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		ZIndex = 53,
		Parent = screen,
	})
	nextBtn.Activated:Connect(function()
		i += 1
		if i > #INTRO then
			finish(false)
			return
		end
		glyph.Text = INTRO[i][1]
		line.Text = INTRO[i][2]
		nextBtn.Text = if i == #INTRO then "Despertar" else "Continuar"
	end)
end

-- ===================== Elección del huevo y eclosión =====================
function Modals.confirmEgg(eggId: string)
	local egg = nil
	for _, e in ipairs(Onboarding.StarterEggs) do
		if e.eggId == eggId then
			egg = e
		end
	end
	Modals.open(function(c)
		title(c, "¿Este huevo?")
		sub(c, "Los tres huevos parecen iguales. Este late con un color… confía en tu intuición.")
		Kit.new("Frame", {
			Size = UDim2.fromOffset(90, 116),
			BackgroundColor3 = Kit.Color.copal,
			LayoutOrder = o(),
			Parent = c,
			Kit.corner(45),
			Kit.new(
				"UIStroke",
				{ Color = Color3.fromRGB(egg.pulseColor[1], egg.pulseColor[2], egg.pulseColor[3]), Thickness = 5 }
			),
		})
		row(c, {
			Kit.button("Seguir mirando", "secondary", Modals.close),
			Kit.button("Elegir", "primary", function()
				Modals.close()
				respond(Net.request("Hatch.ChooseStarter", eggId))
			end),
		})
	end)
end

function Modals.hatchReveal(pet: any)
	local sp = Species.ById[pet.speciesId]
	Modals.open(function(c)
		card(c, pet.speciesId, "Brote", "¡" .. sp.broteName .. "!", sp.concept or "")
		sub(c, Onboarding.OtherStartersMessage)
		local box = Kit.new("TextBox", {
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = Kit.Color.cocoa900,
			PlaceholderText = "Ponle nombre (opcional)",
			Text = "",
			TextSize = 17,
			FontFace = Kit.Font.body,
			TextColor3 = Kit.Color.cream,
			ClearTextOnFocus = false,
			LayoutOrder = o(),
			Parent = c,
			Kit.corner(12),
			Kit.stroke(),
		})
		Kit.button("¡Vamos!", "primary", function()
			local name = box.Text
			Modals.close()
			if #name > 0 then
				respond(Net.request("Pet.SetNickname", pet.id, Kit.truncate(name, Onboarding.MaxNicknameLength)))
			end
			respond(Net.request("Hatch.Ack"), "Sigue la luz de copal hasta tu Lote Hogar.")
		end, { LayoutOrder = o(), Parent = c })
	end, { noClose = true })
end

-- ===================== Ficha del monstruo =====================
function Modals.petSheet(petId: string?)
	local pet = State.pet(petId or State.view and State.view.companionPetId)
	if not pet then
		hud.toast("🥚", "Primero elige tu huevo junto al Gran Nexo.")
		return
	end
	local sp = Species.ById[pet.speciesId]
	Modals.open(function(c)
		card(
			c,
			pet.speciesId,
			pet.form,
			Kit.escape(pet.name),
			string.format("%s · %s · %s", pet.speciesName, sp.role, pet.form)
		)
		local frac = if pet.xpToNext > 0 then pet.xp / pet.xpToNext else 1
		Kit.text(
			string.format("Nivel <b>%d</b>   ·   XP %d / %d", pet.level, pet.xp, pet.xpToNext),
			15,
			{ LayoutOrder = o(), Parent = c }
		)
		local bar = Kit.bar(frac, Kit.Color.copal, 10)
		bar.LayoutOrder = o()
		bar.Parent = c
		Kit.text("Vínculo  " .. Kit.hearts(pet.hearts, pet.maxHearts), 16, { LayoutOrder = o(), Parent = c })
		Kit.text(
			"🎯 " .. pet.objective.text .. string.format("  (%d/%d)", pet.objective.current, pet.objective.target),
			15,
			{
				TextColor3 = Kit.Color.copalSoft,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = o(),
				Parent = c,
			}
		)
		if pet.canEvolve then
			Kit.button("✨ Tallar en " .. sp.talladoName, "primary", function()
				Modals.close()
				local before = pet.formStats
				local r = Net.request("Pet.Evolve", pet.id)
				respond(r)
				if r.ok then
					-- Ceremonia: aviso → animación → luz → revelación → cambios
					local after = nil
					local fresh = State.pet(pet.id)
					if fresh and fresh.form == "Tallado" then
						after = fresh.formStats
					end
					Ceremony.evolve(pet.speciesId, before, after)
				end
			end, { LayoutOrder = o(), Parent = c })
		end
		local foods = {}
		for _, foodId in ipairs(Economy.FoodOrder) do
			local food = Economy.Foods[foodId]
			local have = State.view.items[foodId] or 0
			if food.sold or have > 0 then
				table.insert(
					foods,
					Kit.button(
						string.format("%s %s\n×%d · +%d XP", FOOD_ICON[foodId], food.name, have, food.xp),
						"secondary",
						function()
							local r = Net.request("Care.Feed", pet.id, foodId)
							respond(r, if r.ok then string.format("+%d XP", r.data.xpGained) else nil)
							Modals.petSheet(pet.id)
						end,
						{ TextSize = 13, AutoButtonColor = have > 0, Active = have > 0 }
					)
				)
			end
		end
		local foodRow = row(c, foods)
		foodRow.Size = UDim2.new(1, 0, 0, 64)
		row(c, {
			Kit.button("❤ Jugar", "jade", function()
				local r = Net.request("Care.Play", pet.id)
				respond(r, if r.ok then "Vínculo +" .. tostring(r.data.bondGained) else nil)
				Modals.petSheet(pet.id)
			end),
			Kit.button(if pet.isCompanion then "Te acompaña" else "Que me acompañe", "secondary", function()
				respond(Net.request("Pet.SetCompanion", pet.id))
				Modals.close()
			end),
		})
		for _, key in ipairs({ "VID", "ATQ", "DEF", "ESE", "VEL" }) do
			local value = pet.formStats[key]
			local b = Kit.bar(value / 40, Kit.Color.jade, 10)
			Kit.new("Frame", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				LayoutOrder = o(),
				Parent = c,
				Kit.text(key, 13, {
					Size = UDim2.fromOffset(40, 18),
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Kit.Font.bodyHeavy,
				}),
				Kit.new("Frame", {
					Size = UDim2.new(1, -86, 0, 10),
					Position = UDim2.fromOffset(44, 4),
					BackgroundTransparency = 1,
					b,
				}),
				Kit.text(tostring(value), 13, {
					Size = UDim2.fromOffset(34, 18),
					Position = UDim2.new(1, -34, 0, 0),
					FontFace = Kit.Font.bodyHeavy,
				}),
			})
		end
		-- Las especies del catálogo pueden no tener aún talento/firma definidos en la config
		local talent = if sp.talent then Talents.ById[sp.talent] else nil
		local sig = if sp.signature then Abilities.ById[sp.signature] else nil
		if talent then
			sub(c, string.format("<b>Talento · %s</b>\n%s", talent.name, talent.text))
		end
		if sig then
			sub(c, string.format("<b>Firma · %s</b>\n%s", sig.name, sig.text))
		end
		local lore = SpeciesLore.ById[pet.speciesId]
		sub(c, "<b>Mezcla mítica</b>\n" .. (sp.mythicMix or (if lore then lore.mythicMix else "")))
		if pet.form == "Brote" then
			sub(
				c,
				string.format(
					"<b>Próximo hito</b> · Tallado a nivel %d con %d corazones de Vínculo",
					pet.talladoLevel,
					Progression.Bond.TallarRequiredHearts
				)
			)
		elseif pet.level < pet.nexoLevel then
			sub(c, string.format("<b>Próximo hito</b> · Golpe Nexo a nivel %d", pet.nexoLevel))
		end
		sub(c, "Modelo provisional (blockout). El diseño final pasa por el pipeline de arte y aprobación humana.")
	end)
end

function Modals.evolved(speciesId: string)
	local sp = Species.ById[speciesId]
	Modals.open(function(c)
		card(c, speciesId, "Tallado", sp.talladoName, sp.talladoDescription or "")
		sub(
			c,
			"Mismo monstruo, nueva presencia: conserva su cara, su color base y su rasgo firma. A nivel 20 desbloquea el Golpe Nexo."
		)
		Kit.button("Imponente", "primary", Modals.close, { LayoutOrder = o(), Parent = c })
	end, { noClose = true })
end

-- ===================== Santuario =====================
function Modals.sanctuary()
	local view = State.view
	local h = view and view.habitats.Hogar_H1
	if not h or not h.unlocked then
		hud.toast("🏡", "Visita tu Lote Hogar al sur del río para abrirlo.")
		return
	end
	Modals.open(function(c)
		title(c, "Lote Hogar")
		sub(
			c,
			string.format(
				"Hábitat de 4 lugares · %.1f Monedas/h · los monstruos del Vivero no producen",
				h.ratePerHour
			)
		)
		for slot = 1, 4 do
			local petId = h.slots[slot]
			local pet = if petId then State.pet(petId) else nil
			if pet then
				row(c, {
					Kit.text(string.format("Lugar %d · <b>%s</b> Nv %d", slot, Kit.escape(pet.name), pet.level), 16),
					Kit.button("Retirar", "secondary", function()
						respond(Net.request("Sanctuary.Remove", slot))
						Modals.sanctuary()
					end),
				})
			else
				local options: { Instance } =
					{ Kit.text(string.format("Lugar %d · libre", slot), 16, { TextColor3 = Kit.Color.jadeSoft }) }
				for _, p in ipairs(view.pets) do
					if not p.habitat then
						table.insert(
							options,
							Kit.button("Colocar " .. p.name, "jade", function()
								respond(Net.request("Sanctuary.Place", p.id, slot))
								Modals.sanctuary()
							end, { TextSize = 15 })
						)
						break
					end
				end
				row(c, options)
			end
		end
		Kit.button(string.format("Recoger %d Monedas", h.pendingCoins), "primary", function()
			local r = Net.request("Sanctuary.Collect")
			respond(r, if r.ok then string.format("+%d Monedas", r.data.coins) else nil)
			Modals.close()
		end, { LayoutOrder = o(), Parent = c })
		sub(
			c,
			string.format(
				"Vivero %d/%d · Vitrina e incubadora llegan en la Fase 2.",
				view.inventoryUsed,
				view.inventoryCapacity
			)
		)
	end)
end

-- ===================== Despensa del Gabinete =====================
function Modals.shop()
	Modals.open(function(c)
		title(c, "Despensa del Gabinete")
		sub(c, "🗄 <i>«" .. Gabinete.Lines.Pantry .. "»</i> Precios fijos en Monedas ganadas jugando.")
		for _, foodId in ipairs(Economy.FoodOrder) do
			local food = Economy.Foods[foodId]
			if food.sold then
				row(c, {
					Kit.text(
						string.format(
							"%s <b>%s</b>\n+%d XP%s",
							FOOD_ICON[foodId],
							food.name,
							food.xp,
							if food.bond > 0 then " · +1 Vínculo" else ""
						),
						15,
						{ TextXAlignment = Enum.TextXAlignment.Left }
					),
					Kit.button(string.format("🪙 %d", food.price.Monedas), "primary", function()
						respond(Net.request("Shop.BuyFood", foodId, 1), "Comprado")
						Modals.shop()
					end),
				})
			end
		end
	end)
end

-- ===================== Menú del árbol (Gran Nexo) =====================
function Modals.nexoMenu(onReward: (rewardId: string) -> ())
	local view = State.view
	Modals.open(function(c)
		title(c, "Gran Nexo")
		sub(c, "El árbol te lleva a cada estación; las estaciones se usan en persona.")
		if view and #view.pendingRewards > 0 then
			Kit.button(string.format("🎁 Reclamar %d recompensa(s)", #view.pendingRewards), "primary", function()
				Modals.close()
				onReward(view.pendingRewards[1].id)
			end, { LayoutOrder = o(), Parent = c })
		end
		for _, d in ipairs({
			{ "Plaza", "🌳 Plaza del Gran Nexo" },
			{ "LoteHogar", "🏡 Lote Hogar" },
			{ "Linde", "🌫️ Linde de las Chinampas" },
			{ "Despensa", "🧺 Despensa del Gabinete" },
		}) do
			Kit.button(d[2], "secondary", function()
				Modals.close()
				respond(Net.request("World.Travel", d[1]))
			end, { LayoutOrder = o(), Parent = c })
		end
		for _, locked in ipairs({ "Criadero", "Portal de Arenas", "Tablón de Encargos", "Círculo de Encuentro" }) do
			Kit.button(
				"🔒 " .. locked .. " · Fase 2",
				"secondary",
				nil,
				{ LayoutOrder = o(), Parent = c, AutoButtonColor = false, TextTransparency = 0.45 }
			)
		end
		local lines = {}
		for _, id in ipairs(Encounters.Order) do
			local e = view and view.encounters[id]
			if e then
				table.insert(
					lines,
					string.format(
						"%s %s",
						if e.cleared then "✔" elseif e.unlocked then "•" else "🔒",
						Encounters.ById[id].name
					)
				)
			end
		end
		sub(c, "<b>Linde de las Chinampas</b>\n" .. table.concat(lines, "\n"))
	end)
end

-- ===================== Recompensa =====================
function Modals.reward(rewardId: string)
	local reward = nil
	for _, r in ipairs(State.view.pendingRewards) do
		if r.id == rewardId then
			reward = r
		end
	end
	if not reward then
		return
	end
	Modals.open(function(c)
		title(c, reward.title)
		sub(c, "Recompensa determinista · procedencia registrada en el servidor")
		local lines = {}
		if reward.currencies.Monedas then
			table.insert(lines, string.format("🪙  %d Monedas", reward.currencies.Monedas))
		end
		if reward.currencies.Gemas then
			table.insert(lines, string.format("💎  %d Gemas", reward.currencies.Gemas))
		end
		for item, n in pairs(reward.items) do
			table.insert(lines, string.format("%s  %d × %s", FOOD_ICON[item] or "🎁", n, Economy.Foods[item].name))
		end
		if reward.petXp > 0 then
			table.insert(lines, string.format("⭐  %d XP para tu equipo", reward.petXp))
		end
		for _, chest in ipairs(reward.chests or {}) do
			table.insert(lines, "🎁  " .. Chests.ById[chest].name)
		end
		for _, sp in ipairs(reward.eggs or {}) do
			table.insert(lines, "🥚  Huevo de " .. Species.ById[sp].broteName)
		end
		for _, d in ipairs(reward.decor or {}) do
			table.insert(lines, "🪴  " .. Decor.ById[d].name)
		end
		for _, t in ipairs(reward.titles or {}) do
			table.insert(lines, "🏅  Título: " .. t)
		end
		for _, f in ipairs(reward.frames or {}) do
			table.insert(lines, "🖼  Marco: " .. f)
		end
		for _, line in ipairs(lines) do
			Kit.panel({
				Size = UDim2.new(1, 0, 0, 48),
				LayoutOrder = o(),
				Parent = c,
				Kit.padding(10),
				Kit.text(line, 17, {
					FontFace = Kit.Font.bodyHeavy,
					Size = UDim2.fromScale(1, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			})
		end
		Kit.button("Reclamar", "primary", function()
			Modals.close()
			respond(Net.request("Reward.Claim", rewardId), "Recompensa reclamada")
		end, { LayoutOrder = o(), Parent = c })
	end, { noClose = true })
end

Modals.ElementColor = function(element: string): Color3
	local c = Elements.ById[element].color
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Ayudantes compartidos con las pantallas de la Fase 2 (UI/Screens/*)
Modals.UI = {
	title = title,
	sub = sub,
	row = row,
	respond = respond,
	card = card,
	order = o,
	foodIcon = FOOD_ICON,
}

return Modals
