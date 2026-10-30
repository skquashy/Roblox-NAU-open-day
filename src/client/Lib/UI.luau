--!strict
-- Небольшая библиотека для сборки интерфейса из кода.
-- Дизайн-размеры считаются в "дизайн-пикселях": Screen масштабирует всё через UIScale.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Lang = require(script.Parent.Lang)

local UI = {}

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))

-- Палитра интерфейса: фирменные цвета КАІ из Theme и несколько производных (светлее/темнее, золото монет).
UI.theme = {
	navy = Theme.colors.ink,
	panel = Theme.colors.deep,
	panel2 = Color3.fromRGB(46, 88, 170),
	accent = Theme.colors.primary,
	pink = Theme.colors.accent,
	sky = Theme.colors.sky,
	gold = Color3.fromRGB(255, 196, 0),
	text = Theme.colors.white,
	muted = Color3.fromRGB(186, 210, 238),
	good = Color3.fromRGB(70, 200, 120),
	bad = Color3.fromRGB(235, 90, 90),
	font = Theme.font(Enum.FontWeight.Medium),
	fontBold = Theme.font(Enum.FontWeight.Bold),
}

local PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function merge(base: { [string]: any }, extra: { [string]: any }?): { [string]: any }
	local out = table.clone(base)
	if extra then
		for k, v in extra do
			out[k] = v
		end
	end
	return out
end

function UI.make(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local parent: Instance? = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UI.corner(parent: Instance, radius: number?): UICorner
	return UI.make("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

function UI.stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	return UI.make("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.padding(parent: Instance, px: number): UIPadding
	return UI.make("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.list(parent: Instance, gap: number, horizontal: boolean?): UIListLayout
	return UI.make("UIListLayout", {
		Padding = UDim.new(0, gap),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function UI.frame(props: { [string]: any }): Frame
	return UI.make(
		"Frame",
		merge({ BackgroundColor3 = UI.theme.panel, BorderSizePixel = 0 }, props)
	)
end

-- Текст. Если указан props.key, текст привязывается к локализации (props.args - параметры).
function UI.label(props: { [string]: any }): TextLabel
	local key = props.key
	local args = props.args
	local clean = merge({
		BackgroundTransparency = 1,
		TextColor3 = UI.theme.text,
		FontFace = UI.theme.font,
		TextSize = 22,
		TextWrapped = true,
		Text = "",
	}, props)
	clean.key = nil
	clean.args = nil
	local label = UI.make("TextLabel", clean)
	if key then
		Lang.bind(label, key, args)
	end
	return label
end

-- Кнопка с анимацией нажатия. props.onClick - обработчик, props.key - ключ локализации текста.
function UI.button(props: { [string]: any }): TextButton
	local key = props.key
	local args = props.args
	local onClick = props.onClick
	local clean = merge({
		AutoButtonColor = false,
		BackgroundColor3 = UI.theme.accent,
		TextColor3 = UI.theme.text,
		FontFace = UI.theme.fontBold,
		TextSize = 22,
		TextWrapped = true,
		Size = UDim2.fromOffset(160, 44),
		Text = "",
		BorderSizePixel = 0,
	}, props)
	clean.key = nil
	clean.args = nil
	clean.onClick = nil
	local button = UI.make("TextButton", clean)
	UI.corner(button, 10)
	local scale = UI.make("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, PRESS_INFO, { Scale = 0.95 }):Play()
	end)
	local function release()
		TweenService:Create(scale, PRESS_INFO, { Scale = 1 }):Play()
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	if key then
		Lang.bind(button, key, args)
	end
	if typeof(onClick) == "function" then
		button.Activated:Connect(onClick)
	end
	return button
end

function UI.setSelected(button: GuiButton, selected: boolean)
	if selected then
		button.BackgroundColor3 = UI.theme.accent
	else
		button.BackgroundColor3 = UI.theme.panel2
	end
end

function UI.clear(container: Instance)
	for _, child in container:GetChildren() do
		if
			not child:IsA("UIListLayout")
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIPadding")
		then
			child:Destroy()
		end
	end
end

-- Горизонтальная шкала прогресса. Возвращает (фон, функция установки доли 0..1).
function UI.bar(props: { [string]: any }, fillColor: Color3?): (Frame, (fraction: number) -> ())
	local background = UI.frame(merge({ BackgroundColor3 = UI.theme.navy }, props))
	UI.corner(background, 8)
	local fill = UI.frame({
		BackgroundColor3 = fillColor or UI.theme.accent,
		Size = UDim2.fromScale(0, 1),
		Parent = background,
	})
	UI.corner(fill, 8)
	return background,
		function(fraction: number)
			TweenService:Create(
				fill,
				TweenInfo.new(0.25),
				{ Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) }
			):Play()
		end
end

return UI
