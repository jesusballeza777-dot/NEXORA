--!strict
-- Momentos importantes a pantalla completa (Fase 2): eclosión, Tallado, apertura de
-- cofre y resultado de etapa. Son solo presentación: el servidor ya decidió el resultado
-- y la vista del perfil llega por su cuenta. Una ceremonia a la vez; tocar salta.
--
-- Tallado (Genesis F2 §6.4): 1) aviso de que está preparado · 2) animación especial ·
-- 3) luz y efectos · 4) revelación del Tallado · 5) cambios · 6) la ficha se actualiza.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Species = require(Config:WaitForChild("Species"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Chests = require(Config:WaitForChild("Chests"))
local Economy = require(Config:WaitForChild("Economy"))

local Kit = require(script.Parent.Kit)
local CreatureBuilder = require(script.Parent.Parent.Creatures.CreatureBuilder)
local EvolutionVFXController = require(script.Parent.Parent.VFX.EvolutionVFXController)

local Ceremony = {}

local gui: ScreenGui? = nil
local busy = false

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function screen(): ScreenGui
	if not gui then
		gui = Kit.screen("NexoCeremony", 30)
	end
	return gui :: ScreenGui
end

-- Capa oscura con rayos giratorios del color indicado; devuelve la capa y un "skip".
local function stage(color: Color3): (Frame, () -> boolean)
	local root = Kit.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(12, 8, 6),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = screen(),
	})
	TweenService:Create(root, TweenInfo.new(0.35), { BackgroundTransparency = 0.25 }):Play()
	local rays = Kit.new("Frame", {
		Size = UDim2.fromOffset(520, 520),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		BackgroundTransparency = 1,
		Parent = root,
	})
	for i = 0, 7 do
		Kit.new("Frame", {
			Size = UDim2.new(0, 40, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = i * 22.5,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Parent = rays,
		})
	end
	TweenService
		:Create(rays, TweenInfo.new(9, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
		:Play()
	local skipped = false
	root.Activated:Connect(function()
		skipped = true
	end)
	return root, function()
		return skipped
	end
end

local function waitOrSkip(seconds: number, isSkipped: () -> boolean)
	local t = 0
	while t < seconds and not isSkipped() do
		t += task.wait()
	end
end

local function portrait(parent: Instance, speciesId: string, form: string, opaco: boolean?): ViewportFrame
	local vp = CreatureBuilder.portrait(speciesId, form, UDim2.fromOffset(300, 300))
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.42)
	vp.Parent = parent
	if opaco then
		vp.ImageColor3 = Color3.fromRGB(150, 150, 156)
	end
	return vp
end

local function caption(parent: Instance, title: string, subtitle: string?)
	local box = Kit.new("Frame", {
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.7),
		BackgroundTransparency = 1,
		Parent = parent,
		Kit.list(Enum.FillDirection.Vertical, 4),
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(520, 400) }),
	})
	Kit.text(title, 30, { FontFace = Kit.Font.title, TextColor3 = Kit.Color.copalGlow, Parent = box })
	if subtitle then
		Kit.text(subtitle, 17, {
			TextColor3 = Kit.Color.cream,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = box,
		})
	end
	Kit.pop(box)
	return box
end

local function closeOnTap(root: GuiButton, isSkipped: () -> boolean)
	Kit.text("Toca para continuar", 14, {
		Size = UDim2.new(1, 0, 0, 24),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		TextColor3 = Kit.Color.muted,
		Parent = root,
	})
	local _ = isSkipped
	local closed = false
	root.Activated:Connect(function()
		closed = true
	end)
	local t = 0
	while not closed and t < 12 do
		t += task.wait()
	end
	TweenService:Create(root, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	task.wait(0.3)
	root:Destroy()
	busy = false
end

-- Destello de luz real en el mundo (Bloom) durante la revelación
local function flash()
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		local before = bloom.Intensity
		bloom.Intensity = before + 1.5
		TweenService:Create(bloom, TweenInfo.new(1.2), { Intensity = before }):Play()
	end
end

function Ceremony.hatch(speciesId: string, petName: string?, newSpecies: boolean?)
	if busy then
		return
	end
	busy = true
	local sp = Species.ById[speciesId]
	local rar = Rarities.ById[sp.rarity]
	task.spawn(function()
		local root, skipped = stage(rgb(rar.frameColor))
		-- El huevo tiembla con grietas de luz y se abre
		local egg = Kit.new("Frame", {
			Size = UDim2.fromOffset(120, 150),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			BackgroundColor3 = Kit.Color.copalSoft,
			Parent = root,
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			Kit.stroke(rgb(rar.frameColor), 4),
		})
		for i = 1, 3 do
			Kit.new("Frame", {
				Size = UDim2.fromOffset(4, 26 + i * 8),
				Position = UDim2.fromScale(0.25 + i * 0.15, 0.2 + i * 0.12),
				Rotation = (i % 2 == 0) and 25 or -25,
				BackgroundColor3 = Kit.Color.copalGlow,
				Parent = egg,
			})
			egg.Rotation = if i % 2 == 0 then 8 else -8
			waitOrSkip(0.35, skipped)
		end
		egg:Destroy()
		flash()
		portrait(root, speciesId, "Brote")
		caption(
			root,
			if newSpecies then "¡Especie nueva! " .. sp.broteName else "¡Nació " .. (petName or sp.broteName) .. "!",
			string.format("%s · %s", rar.name, table.concat(sp.elements, " · "))
		)
		closeOnTap(root :: any, skipped)
	end)
end

function Ceremony.evolve(speciesId: string, beforeStats: { [string]: number }?, afterStats: { [string]: number }?)
	if busy then
		return
	end
	busy = true
	local sp = Species.ById[speciesId]
	local rar = Rarities.ById[sp.rarity]
	task.spawn(function()
		local root, skipped = stage(Kit.Color.copalGlow)
		local note: Instance? =
			caption(root, sp.broteName .. " está listo para tallarse", "El Nexo responde a su Vínculo…")
		-- Secuencia del Tallado (EvolutionVFXController): preparación corporal, energía del
		-- elemento, transición de materiales, luz, revelación del Tallado y presentación.
		local evo = EvolutionVFXController.new(root, speciesId, {
			onFlash = flash,
			onPhase = function(phase: string)
				if phase == "Reveal" and note then
					note:Destroy()
					note = nil
				end
			end,
		})
		while not evo.done do
			local dt = task.wait()
			if skipped() then
				evo:skip()
			else
				evo:step(dt)
			end
		end
		if note then
			note:Destroy()
		end
		local changes = nil
		if beforeStats and afterStats then
			local parts = {}
			for _, k in ipairs({ "VID", "ATQ", "DEF", "ESE", "VEL" }) do
				table.insert(parts, string.format("%s %d→%d", k, beforeStats[k] or 0, afterStats[k] or 0))
			end
			changes = table.concat(parts, "  ")
		end
		caption(
			root,
			"¡" .. sp.broteName .. " se talla en " .. sp.talladoName .. "!",
			(changes or "Conserva su cara, su color y su rasgo firma.") .. "\n" .. rar.name
		)
		closeOnTap(root :: any, skipped)
	end)
end

-- Apertura de cofre: tiembla, se ilumina con el color de su rango y muestra lo que trae
function Ceremony.chest(chestType: string, result: any)
	if busy then
		return
	end
	busy = true
	local def = Chests.ById[chestType]
	task.spawn(function()
		local root, skipped = stage(rgb(def.glow))
		local box = Kit.new("Frame", {
			Size = UDim2.fromOffset(170, 120),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			BackgroundColor3 = rgb(def.color),
			Parent = root,
			Kit.corner(14),
			Kit.stroke(rgb(def.glow), 4),
		})
		for i = 1, 6 do
			box.Rotation = if i % 2 == 0 then 6 else -6
			waitOrSkip(0.12, skipped)
		end
		box.Rotation = 0
		flash()
		TweenService:Create(box, TweenInfo.new(0.4), { BackgroundTransparency = 0.6 }):Play()
		local lines = {}
		for cur, v in pairs(result.currencies or {}) do
			table.insert(lines, string.format("%s %d %s", if cur == "Gemas" then "◆" else "●", v, cur))
		end
		for item, v in pairs(result.items or {}) do
			local food = Economy.Foods[item]
			table.insert(lines, string.format("%d × %s", v, if food then food.name else item))
		end
		for _, egg in ipairs(result.eggs or {}) do
			table.insert(lines, "🥚 Huevo de " .. Species.ById[egg.speciesId].broteName)
		end
		for _ in ipairs(result.codex or {}) do
			table.insert(lines, "📜 Carta del Códice")
		end
		caption(root, def.name, table.concat(lines, "\n"))
		closeOnTap(root :: any, skipped)
	end)
end

-- Resultado de etapa: estrellas ganadas, premios de región y jefe
function Ceremony.stageResult(stageName: string, result: any, onDone: (() -> ())?)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local root, skipped = stage(Kit.Color.copalGlow)
		local stars = result.stars or { true, false, false }
		local row = Kit.new("Frame", {
			Size = UDim2.fromOffset(260, 80),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
			BackgroundTransparency = 1,
			Parent = root,
			Kit.list(Enum.FillDirection.Horizontal, 12),
		})
		local layout = row:FindFirstChildOfClass("UIListLayout") :: UIListLayout
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		for i = 1, 3 do
			local star = Kit.text(if stars[i] then "★" else "☆", 64, {
				Size = UDim2.fromOffset(72, 72),
				FontFace = Kit.Font.title,
				TextColor3 = if stars[i] then Kit.Color.copalGlow else Kit.Color.muted,
				Parent = row,
			})
			Kit.pop(star)
			waitOrSkip(0.3, skipped)
		end
		local notes = {}
		if result.firstClear then
			table.insert(notes, "Primera victoria")
		end
		for _, c in ipairs(result.chests or {}) do
			table.insert(notes, "🎁 " .. Chests.ById[c].name)
		end
		if result.rescueEgg then
			table.insert(notes, "🥚 ¡Huevo de " .. Species.ById[result.rescueEgg].broteName .. "!")
		end
		if result.regionCleared then
			table.insert(notes, "🗺 Región completada")
		end
		if result.regionStars then
			table.insert(notes, "✨ ¡Todas las estrellas de la región!")
		end
		if result.guardianRestored then
			table.insert(notes, "🪶 Copalia recupera su color. El Valle florece.")
		end
		if result.codex and #result.codex > 0 then
			table.insert(notes, "📜 Nueva carta del Códice")
		end
		caption(root, stageName, table.concat(notes, "\n"))
		closeOnTap(root :: any, skipped)
		if onDone then
			onDone()
		end
	end)
end

function Ceremony.isBusy(): boolean
	return busy
end

return Ceremony
