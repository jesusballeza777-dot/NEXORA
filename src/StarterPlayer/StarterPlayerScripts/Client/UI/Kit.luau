--!strict
-- Kit de interfaz de NEXORA: tema (cacao, copal, jade, barro), tipografía y piezas
-- reutilizables. Móvil primero: botones de al menos 48 px, texto mínimo 14 px y un
-- UIScale global que ajusta todo al alto de la pantalla.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Kit = {}

Kit.Color = {
	cocoa900 = Color3.fromRGB(29, 19, 14),
	cocoa800 = Color3.fromRGB(42, 28, 21),
	cocoa700 = Color3.fromRGB(58, 39, 29),
	copal = Color3.fromRGB(232, 168, 72),
	copalGlow = Color3.fromRGB(255, 196, 96),
	copalSoft = Color3.fromRGB(246, 217, 166),
	jade = Color3.fromRGB(62, 150, 122),
	jadeSoft = Color3.fromRGB(143, 209, 185),
	clay = Color3.fromRGB(176, 98, 64),
	cream = Color3.fromRGB(255, 244, 222),
	muted = Color3.fromRGB(216, 198, 170),
	danger = Color3.fromRGB(226, 88, 91),
	ok = Color3.fromRGB(108, 194, 138),
	ink = Color3.fromRGB(42, 23, 11),
}
Kit.Font = {
	title = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
	body = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold),
	bodyHeavy = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold),
}

type Props = { [string]: any }

-- Crea una instancia con propiedades e hijos. Las claves numéricas son hijos.
function Kit.new(className: string, props: Props?): any
	local inst = Instance.new(className)
	local children = {}
	for k, v in pairs(props or {}) do
		if type(k) == "number" then
			table.insert(children, v)
		elseif k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, child in ipairs(children) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Kit.corner(radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 16) })
end

function Kit.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Kit.new("UIStroke", {
		Color = color or Kit.Color.copal,
		Thickness = thickness or 2,
		Transparency = transparency or 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.padding(px: number): UIPadding
	return Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

function Kit.list(direction: Enum.FillDirection?, gap: number?, align: Enum.HorizontalAlignment?): UIListLayout
	return Kit.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 8),
		HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Kit.panel(props: Props): Frame
	local p = table.clone(props)
	p.BackgroundColor3 = p.BackgroundColor3 or Kit.Color.cocoa800
	p.BackgroundTransparency = p.BackgroundTransparency or 0.06
	table.insert(p, Kit.corner(18))
	table.insert(p, Kit.stroke())
	return Kit.new("Frame", p)
end

function Kit.text(text: string, size: number, props: Props?): TextLabel
	local p = table.clone(props or {})
	p.Text = text
	p.TextSize = size
	p.FontFace = p.FontFace or Kit.Font.body
	p.TextColor3 = p.TextColor3 or Kit.Color.cream
	p.BackgroundTransparency = 1
	p.TextWrapped = if p.TextWrapped == nil then true else p.TextWrapped
	p.Size = p.Size or UDim2.new(1, 0, 0, size + 6)
	p.RichText = true
	return Kit.new("TextLabel", p)
end

export type ButtonStyle = "primary" | "secondary" | "jade"

function Kit.button(text: string, style: ButtonStyle?, onClick: (() -> ())?, props: Props?): TextButton
	local s = style or "primary"
	local bg = if s == "primary" then Kit.Color.copal elseif s == "jade" then Kit.Color.jade else Kit.Color.cocoa700
	local fg = if s == "secondary" then Kit.Color.cream else Kit.Color.ink
	local p = table.clone(props or {})
	p.Text = text
	p.TextSize = p.TextSize or 18
	p.FontFace = Kit.Font.title
	p.TextColor3 = fg
	p.BackgroundColor3 = bg
	p.AutoButtonColor = true
	p.Size = p.Size or UDim2.new(1, 0, 0, 52)
	table.insert(p, Kit.corner(14))
	if s == "secondary" then
		table.insert(p, Kit.stroke(Kit.Color.copal, 1.5, 0.5))
	end
	local b = Kit.new("TextButton", p)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Barra de progreso; devuelve el marco y una función para actualizarla.
function Kit.bar(fraction: number, color: Color3?, height: number?): (Frame, (number) -> ())
	local fill = Kit.new("Frame", {
		Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1),
		BackgroundColor3 = color or Kit.Color.copal,
		Kit.corner(6),
	})
	local frame = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, height or 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.88,
		Kit.corner(6),
		fill,
	})
	local function set(f: number)
		TweenService:Create(fill, TweenInfo.new(0.35), { Size = UDim2.fromScale(math.clamp(f, 0, 1), 1) }):Play()
	end
	return frame, set
end

function Kit.screen(name: string, order: number): ScreenGui
	local player = Players.LocalPlayer
	local gui = Kit.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- Escala global: diseñado para ~900 px de alto, legible en teléfono y TV
	local scale = Kit.new("UIScale", { Parent = gui })
	local function update()
		local camera = Workspace.CurrentCamera
		local h = if camera then camera.ViewportSize.Y else 900
		scale.Scale = math.clamp(h / 900, 0.72, 1.35)
	end
	update()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	return gui
end

function Kit.hearts(hearts: number, max: number): string
	return string.format(
		'<font color="#ff7b8a">%s</font><font color="#5b4a40">%s</font>',
		string.rep("❤", hearts),
		string.rep("❤", math.max(0, max - hearts))
	)
end

function Kit.pop(gui: GuiObject)
	local scale = gui:FindFirstChildOfClass("UIScale") or Kit.new("UIScale", { Parent = gui })
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

return Kit
