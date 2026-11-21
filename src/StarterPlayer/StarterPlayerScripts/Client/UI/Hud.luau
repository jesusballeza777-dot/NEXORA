--!strict
-- HUD principal: Monedas y Gemas, objetivo actual (un solo aviso de tutorial a la vez),
-- accesos (Monstruo, Santuario, Nexo), tarjeta del acompañante y avisos breves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Onboarding = require(Config:WaitForChild("Onboarding"))

local Kit = require(script.Parent.Kit)
local CreatureBuilder = require(script.Parent.Parent.Creatures.CreatureBuilder)

local Hud = {}

local gui: ScreenGui
local coinsLabel: TextLabel
local gemsLabel: TextLabel
local objectiveTitle: TextLabel
local objectiveHint: TextLabel
local objectivePanel: Frame
local companionCard: TextButton
local companionKey = ""
local toastHolder: Frame
local dock: Frame

local function chip(icon: string, color: Color3): (Frame, TextLabel)
	local value = Kit.text(
		"0",
		18,
		{ FontFace = Kit.Font.title, Size = UDim2.new(0, 70, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }
	)
	local frame = Kit.new("Frame", {
		Size = UDim2.fromOffset(118, 40),
		BackgroundColor3 = Kit.Color.cocoa800,
		BackgroundTransparency = 0.08,
		Kit.corner(20),
		Kit.stroke(),
		Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left),
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
		Kit.new("TextLabel", {
			Size = UDim2.fromOffset(28, 28),
			Position = UDim2.fromOffset(0, 6),
			BackgroundColor3 = color,
			Text = icon,
			TextSize = 14,
			FontFace = Kit.Font.title,
			TextColor3 = Kit.Color.ink,
			Kit.corner(14),
		}),
		value,
	})
	local layout = frame:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return frame, value
end

function Hud.init(actions: { openPet: () -> (), openSanctuary: () -> (), openNexo: () -> () })
	gui = Kit.screen("NexoHud", 5)
	gui.Enabled = false

	local top = Kit.new("Frame", {
		Size = UDim2.new(1, -24, 0, 44),
		Position = UDim2.fromOffset(12, 8),
		BackgroundTransparency = 1,
		Parent = gui,
		Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right),
	})
	local coins, coinsValue = chip("●", Kit.Color.copalGlow)
	local gems, gemsValue = chip("◆", Color3.fromRGB(120, 200, 240))
	coins.Parent = top
	gems.Parent = top
	coinsLabel, gemsLabel = coinsValue, gemsValue

	objectivePanel = Kit.panel({
		Size = UDim2.fromOffset(330, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(12, 60),
		Parent = gui,
		Kit.padding(12),
		Kit.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left),
	})
	Kit.text("OBJETIVO", 12, {
		TextColor3 = Kit.Color.copal,
		FontFace = Kit.Font.bodyHeavy,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = objectivePanel,
	})
	objectiveTitle = Kit.text("", 19, {
		FontFace = Kit.Font.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = objectivePanel,
	})
	objectiveHint = Kit.text("", 15, {
		TextColor3 = Kit.Color.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 3,
		Parent = objectivePanel,
	})

	dock = Kit.new("Frame", {
		Size = UDim2.fromOffset(66, 220),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.45, 0),
		BackgroundTransparency = 1,
		Parent = gui,
		Kit.list(Enum.FillDirection.Vertical, 10),
	})
	for i, entry in ipairs({
		{ "🐾", "Monstruo", actions.openPet },
		{ "🏡", "Santuario", actions.openSanctuary },
		{ "🌳", "Nexo", actions.openNexo },
	}) do
		local b = Kit.new("TextButton", {
			Size = UDim2.fromOffset(64, 64),
			BackgroundColor3 = Kit.Color.cocoa800,
			Text = entry[1],
			TextSize = 26,
			LayoutOrder = i,
			Parent = dock,
			Kit.corner(18),
			Kit.stroke(),
		})
		Kit.text(entry[2], 11, {
			FontFace = Kit.Font.bodyHeavy,
			TextColor3 = Kit.Color.copalSoft,
			Position = UDim2.new(0, 0, 1, -16),
			Size = UDim2.new(1, 0, 0, 14),
			Parent = b,
		})
		b.Activated:Connect(entry[3])
	end

	companionCard = Kit.new("TextButton", {
		Size = UDim2.fromOffset(250, 84),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -210),
		BackgroundColor3 = Kit.Color.cocoa800,
		BackgroundTransparency = 0.06,
		Text = "",
		AutoButtonColor = true,
		Visible = false,
		Parent = gui,
		Kit.corner(18),
		Kit.stroke(),
	})
	companionCard.Activated:Connect(actions.openPet)

	toastHolder = Kit.new("Frame", {
		Size = UDim2.fromOffset(420, 300),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = gui,
		Kit.list(Enum.FillDirection.Vertical, 8),
	})
end

function Hud.setVisible(visible: boolean)
	gui.Enabled = visible
end

local function stepInfo(step: string): { objective: string, hint: string }
	for _, s in ipairs(Onboarding.Steps) do
		if s.id == step then
			return s
		end
	end
	return Onboarding.Steps[#Onboarding.Steps]
end

function Hud.render(view: any)
	coinsLabel.Text = tostring(view.currencies.Monedas or 0)
	gemsLabel.Text = tostring(view.currencies.Gemas or 0)
	local info = stepInfo(view.onboarding.step)
	objectiveTitle.Text = info.objective
	objectiveHint.Text = info.hint

	local pet = nil
	for _, p in ipairs(view.pets) do
		if p.id == view.companionPetId then
			pet = p
		end
	end
	companionCard.Visible = pet ~= nil and view.onboarding.step ~= "Hatch"
	if pet then
		local key = pet.speciesId .. pet.form
		if key ~= companionKey then
			companionKey = key
			for _, child in ipairs(companionCard:GetChildren()) do
				if child:IsA("ViewportFrame") then
					child:Destroy()
				end
			end
			local vp = CreatureBuilder.portrait(pet.speciesId, pet.form, UDim2.fromOffset(72, 72))
			vp.Position = UDim2.fromOffset(6, 6)
			vp.Parent = companionCard
		end
		local info2 = companionCard:FindFirstChild("Info") :: Frame?
		if info2 then
			info2:Destroy()
		end
		local frac = if pet.xpToNext > 0 then pet.xp / pet.xpToNext else 1
		local bar = Kit.bar(frac, Kit.Color.copal, 8)
		Kit.new("Frame", {
			Name = "Info",
			Size = UDim2.new(1, -92, 1, -12),
			Position = UDim2.fromOffset(86, 6),
			BackgroundTransparency = 1,
			Parent = companionCard,
			Kit.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left),
			Kit.text(
				Kit.escape(pet.name),
				17,
				{ FontFace = Kit.Font.title, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }
			),
			Kit.text(
				string.format("Nv %d · %s", pet.level, pet.form),
				13,
				{ TextColor3 = Kit.Color.muted, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 }
			),
			Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 3, bar }),
			Kit.text(
				Kit.hearts(pet.hearts, pet.maxHearts),
				14,
				{ TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4 }
			),
		})
	end
end

function Hud.toast(icon: string, text: string)
	if not toastHolder then
		return
	end
	local t = Kit.panel({
		Size = UDim2.new(1, 0, 0, 46),
		Parent = toastHolder,
		Kit.padding(10),
		Kit.text(
			icon .. "  " .. text,
			16,
			{ FontFace = Kit.Font.bodyHeavy, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left }
		),
	})
	Kit.pop(t)
	task.delay(3.2, function()
		local tween = TweenService:Create(t, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		t:Destroy()
	end)
end

return Hud
