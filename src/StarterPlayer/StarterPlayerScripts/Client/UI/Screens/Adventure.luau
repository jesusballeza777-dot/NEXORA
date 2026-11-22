--!strict
-- Modo aventura · Acto I (Fase 2): mapa con las tres regiones como un recorrido visual
-- (no un menú numérico), ficha de etapa, selector de equipo y acertijo del Tesoro.
-- El cliente solo pide "empezar la etapa X" o "responder Y": el servidor valida todo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Encounters = require(Config:WaitForChild("Encounters"))
local Species = require(Config:WaitForChild("Species"))
local Guardians = require(Config:WaitForChild("Guardians"))
local Elements = require(Config:WaitForChild("Elements"))
local Chests = require(Config:WaitForChild("Chests"))

local UI = script.Parent.Parent
local Kit = require(UI.Kit)
local Modals = require(UI.Modals)
local Ceremony = require(UI.Ceremony)
local Net = require(UI.Parent.Net)
local State = require(UI.Parent.State)

local Adventure = {}

local TYPE_ICON = { Combate = "⚔", Elite = "☗", Tesoro = "💎", Rescate = "🕊", Jefe = "👑", Secreta = "?" }
local TYPE_NAME = {
	Combate = "Combate",
	Elite = "Élite",
	Tesoro = "Tesoro",
	Rescate = "Rescate",
	Jefe = "Jefe",
	Secreta = "Secreta",
}

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function starString(stars: { boolean }?): string
	local s = stars or { false, false, false }
	local out = ""
	for i = 1, 3 do
		out ..= if s[i] then "★" else "☆"
	end
	return out
end

local function opponentName(id: string): string
	local g = Guardians.ById[id]
	if g then
		return g.shortName
	end
	local sp = Species.ById[id]
	return if sp then sp.broteName else id
end

-- Línea entre dos nodos del mapa (en escala 0–1 del lienzo)
local function link(parent: Instance, a: { number }, b: { number }, size: Vector2, color: Color3)
	local ax, ay = a[1] * size.X, a[2] * size.Y
	local bx, by = b[1] * size.X, b[2] * size.Y
	local len = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
	Kit.new("Frame", {
		Size = UDim2.fromOffset(len, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2),
		Rotation = math.deg(math.atan2(by - ay, bx - ax)),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = parent,
		Kit.corner(3),
	})
end

function Adventure.map()
	local view = State.view
	if not view then
		return
	end
	local adv = view.adventure
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, Encounters.Acts.ActoI.name)
		ui.sub(
			content,
			string.format(
				"%s · ★ %d / %d · Sin energía: juega cuanto quieras",
				Encounters.Acts.ActoI.biomeRule,
				adv.totalStars,
				adv.maxStars
			)
		)
		-- Lienzo horizontal desplazable: las regiones se recorren de izquierda a derecha
		local W, H = 1100, 360
		local scroller = Kit.new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, H + 12),
			BackgroundTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.fromOffset(W, H),
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = Kit.Color.copal,
			LayoutOrder = ui.order(),
			Parent = content,
		})
		local canvas = Kit.new("Frame", {
			Size = UDim2.fromOffset(W, H),
			BackgroundColor3 = Kit.Color.cocoa900,
			Parent = scroller,
			Kit.corner(16),
		})
		local size = Vector2.new(W, H)
		-- Bandas de región con su paleta (identidad visual de cada región)
		for i, region in ipairs(Encounters.Regions) do
			local x0 = (i - 1) / 3
			local band = Kit.new("Frame", {
				Size = UDim2.fromScale(1 / 3, 1),
				Position = UDim2.fromScale(x0 * 0.94, 0),
				BackgroundColor3 = rgb(region.palette.ground),
				BackgroundTransparency = 0.35,
				Parent = canvas,
				Kit.new("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new(rgb(region.palette.sky), rgb(region.palette.ground)),
				}),
			})
			local rv = adv.regions[i]
			Kit.text(
				string.format(
					"%s%s",
					region.name,
					if rv and rv.allStars then "  ✨" elseif rv and rv.cleared then "  ✔" else ""
				),
				15,
				{
					FontFace = Kit.Font.title,
					Size = UDim2.new(1, -10, 0, 20),
					Position = UDim2.new(0, 5, 1, -44),
					Parent = band,
				}
			)
			Kit.text(region.subtitle .. " · nv " .. region.levels, 13, {
				TextColor3 = Kit.Color.cream,
				Size = UDim2.new(1, -10, 0, 18),
				Position = UDim2.new(0, 5, 1, -24),
				Parent = band,
			})
		end
		-- Camino entre etapas numeradas y al jefe
		local path = {}
		for _, region in ipairs(Encounters.Regions) do
			for _, id in ipairs(region.stages) do
				table.insert(path, id)
			end
		end
		table.insert(path, Encounters.Acts.ActoI.boss)
		for i = 1, #path - 1 do
			local a, b = Encounters.ById[path[i]], Encounters.ById[path[i + 1]]
			local done = adv.stages[path[i]].cleared
			link(canvas, a.mapPos, b.mapPos, size, if done then Kit.Color.copalGlow else Kit.Color.cocoa700)
		end
		-- Nodos
		for _, id in ipairs(Encounters.Order) do
			local enc = Encounters.ById[id]
			local st = adv.stages[id]
			local isSecret = enc.stageType == "Secreta"
			local isBoss = enc.stageType == "Jefe"
			local d = if isBoss then 84 else 58
			local node = Kit.new("TextButton", {
				Size = UDim2.fromOffset(d, d),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(enc.mapPos[1] * W, enc.mapPos[2] * H),
				BackgroundColor3 = if not st.unlocked
					then Color3.fromRGB(50, 44, 40)
					elseif st.cleared then Kit.Color.jade
					else Kit.Color.copal,
				Text = if isSecret and not st.unlocked
					then "?"
					else TYPE_ICON[enc.stageType] .. (if enc.stage > 0 then "\n" .. enc.stage else ""),
				TextSize = if isBoss then 26 else 18,
				FontFace = Kit.Font.title,
				TextColor3 = Kit.Color.ink,
				ZIndex = 3,
				Parent = canvas,
				Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
				Kit.stroke(if isBoss then Kit.Color.copalGlow else Kit.Color.cream, if isBoss then 4 else 2),
			})
			if st.cleared then
				Kit.text(starString(st.stars), 15, {
					Size = UDim2.fromOffset(70, 18),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 1, 2),
					TextColor3 = Kit.Color.copalGlow,
					ZIndex = 3,
					Parent = node,
				})
			end
			node.Activated:Connect(function()
				if st.unlocked then
					Adventure.stage(id)
				elseif isSecret then
					Modals.UI.respond({ ok = false, err = "SecretLocked" })
				else
					Modals.UI.respond({ ok = false, err = "EncounterLocked" })
				end
			end)
		end
		ui.row(content, {
			Kit.button("Equipo", "secondary", function()
				Adventure.team(nil)
			end),
			Kit.button("Códice", "secondary", function()
				local Collection = require(script.Parent.Collection)
				Collection.codex()
			end),
		})
	end)
end

function Adventure.stage(id: string)
	local view = State.view
	if not view then
		return
	end
	local enc = Encounters.ById[id]
	local st = view.adventure.stages[id]
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, TYPE_ICON[enc.stageType] .. "  " .. enc.name)
		ui.sub(
			content,
			string.format(
				"%s · Región %d · nivel recomendado %d · %s",
				TYPE_NAME[enc.stageType],
				enc.region,
				enc.recommendedLevel,
				starString(st.stars)
			)
		)
		ui.sub(content, enc.intro)
		if #enc.opponents > 0 then
			local names = {}
			for i, opp in ipairs(enc.opponents) do
				local sid = st.opponents[i] or opp.speciesId or "?"
				local mods = {}
				if opp.modifier then
					table.insert(mods, Encounters.Modifiers[opp.modifier].name)
				end
				if opp.rooted then
					table.insert(mods, "🌿 raíces")
				end
				table.insert(
					names,
					string.format(
						"• Opaco de %s · nv %d%s",
						opponentName(sid),
						opp.level,
						if #mods > 0 then " · " .. table.concat(mods, ", ") else ""
					)
				)
			end
			ui.sub(content, table.concat(names, "\n"))
		end
		if enc.stageType == "Jefe" then
			local g = Guardians.ById.copalia
			ui.sub(content, string.format("<b>%s</b> · %s\nFase 2: %s", g.talentName, g.talentText, g.phases[1].text))
		end
		ui.sub(content, string.format("★ Ganar   ★★ Sin perder monstruos   ★★★ %s", enc.challenge.text))
		local reward = if st.cleared
			then string.format(
				"Repetición: %d Monedas y %d XP (quedan %d repeticiones con premio hoy)",
				math.floor(enc.baseReward.Monedas * Encounters.Repeat.RewardScale),
				math.floor(enc.baseReward.petXp * Encounters.Repeat.RewardScale),
				math.max(0, view.adventure.repeatsLeft)
			)
			else string.format(
				"Primera victoria: %d Monedas · %d XP%s%s",
				enc.baseReward.Monedas,
				enc.baseReward.petXp,
				if enc.firstClearChest then " · " .. Chests.ById[enc.firstClearChest].name else "",
				if enc.rescue then " · 10 % de huevo de " .. opponentName(enc.rescue.speciesId) else ""
			)
		ui.sub(content, reward)
		if enc.stageType == "Tesoro" then
			Kit.button("Resolver el acertijo", "primary", function()
				Adventure.treasure(id)
			end, { Size = UDim2.new(1, 0, 0, 52), LayoutOrder = ui.order(), Parent = content })
			return
		end
		local team = {}
		for _, pet in ipairs(view.pets) do
			if pet.inTeam then
				table.insert(team, string.format("%s nv %d", Kit.escape(pet.name), pet.level))
			end
		end
		ui.sub(
			content,
			"Equipo: "
				.. (if #team > 0 then table.concat(team, " · ") else "tu acompañante")
				.. string.format(" (máx. %d)", enc.teamSize)
		)
		ui.row(content, {
			Kit.button("Cambiar equipo", "secondary", function()
				Adventure.team(id)
			end),
			Kit.button("¡A combatir!", "primary", function()
				local r = Net.request("Battle.Start", id)
				if r.ok then
					Modals.close()
				else
					ui.respond(r)
				end
			end),
		})
	end)
end

function Adventure.treasure(id: string)
	local enc = Encounters.ById[id]
	local riddle = enc.riddle :: any
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "💎 " .. enc.name)
		ui.sub(content, riddle.prompt)
		for _, element in ipairs(riddle.options) do
			local c = Elements.ById[element].color
			Kit.button(element, "secondary", function()
				local r = Net.request("Adventure.Treasure", id, element)
				if not r.ok then
					ui.respond(r)
				elseif r.data.solved then
					Modals.close()
					Ceremony.stageResult(enc.name, r.data, function()
						if r.data.rewardId then
							Modals.reward(r.data.rewardId)
						end
					end)
				else
					ui.respond({ ok = false, err = "WrongElement" })
				end
			end, {
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Color3.fromRGB(c[1], c[2], c[3]),
				LayoutOrder = ui.order(),
				Parent = content,
			})
		end
	end)
end

-- Equipo de aventura: hasta 3 monstruos propios
function Adventure.team(returnTo: string?)
	local view = State.view
	if not view then
		return
	end
	local selected: { string } = {}
	for _, pet in ipairs(view.pets) do
		if pet.inTeam then
			table.insert(selected, pet.id)
		end
	end
	local ui = Modals.UI
	Modals.open(function(content)
		ui.title(content, "Equipo de aventura")
		ui.sub(content, "Elige hasta 3 monstruos. Si cae uno, entra el siguiente.")
		local buttons: { [string]: TextButton } = {}
		local function refresh()
			for id, b in pairs(buttons) do
				local idx = table.find(selected, id)
				b.BackgroundColor3 = if idx then Kit.Color.jade else Kit.Color.cocoa700
				b.Text = (if idx then tostring(idx) .. ". " else "") .. b:GetAttribute("Label")
			end
		end
		for _, pet in ipairs(view.pets) do
			local label = string.format("%s · nv %d · %s", Kit.escape(pet.name), pet.level, pet.form)
			local b = Kit.button(label, "secondary", function()
				local idx = table.find(selected, pet.id)
				if idx then
					table.remove(selected, idx)
				elseif #selected < 3 then
					table.insert(selected, pet.id)
				end
				refresh()
			end, { Size = UDim2.new(1, 0, 0, 48), LayoutOrder = ui.order(), Parent = content })
			b:SetAttribute("Label", label)
			buttons[pet.id] = b
		end
		refresh()
		Kit.button("Guardar equipo", "primary", function()
			if #selected == 0 then
				return
			end
			ui.respond(Net.request("Team.Set", table.concat(selected, ",")), "Equipo listo")
			if returnTo then
				Adventure.stage(returnTo)
			else
				Adventure.map()
			end
		end, { Size = UDim2.new(1, 0, 0, 52), LayoutOrder = ui.order(), Parent = content })
	end)
end

return Adventure
