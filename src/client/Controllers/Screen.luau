--!strict
-- Кореневий інтерфейс: масштабування під екран (телефон/планшет/ПК), шари, модальні вікна.
-- Усе інше будується всередині Screen.root у «дизайн-пікселях» (мінімум 1280x720).

local Players = game:GetService("Players")

local UI = require(script.Parent.Parent.Lib.UI)

local DESIGN_WIDTH, DESIGN_HEIGHT = 1280, 720

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local gui = UI.make("ScreenGui", {
	Name = "KAIUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
	Parent = playerGui,
})

local root: Frame = UI.make("Frame", {
	Name = "Root",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(DESIGN_WIDTH, DESIGN_HEIGHT),
	Parent = gui,
})
local uiScale: UIScale = UI.make("UIScale", { Parent = root })

-- Шари: HUD нижче, модальні вікна вище, сповіщення поверх усього.
local hudLayer: Frame = UI.make("Frame", {
	Name = "HUD",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 1,
	Parent = root,
})
local modalLayer: Frame = UI.make("Frame", {
	Name = "Modals",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 20,
	Parent = root,
})
local toastLayer: Frame = UI.make("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 40,
	Parent = root,
})

-- Затемнення за модальним вікном; перехоплює натискання, щоб не клікати по світу.
local backdrop: TextButton = UI.make("TextButton", {
	Name = "Backdrop",
	Text = "",
	AutoButtonColor = false,
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Size = UDim2.fromScale(1, 1),
	Visible = false,
	Parent = modalLayer,
})

local function updateScale()
	local size = gui.AbsoluteSize
	if size.X < 10 or size.Y < 10 then
		return
	end
	local scale = math.clamp(math.min(size.X / DESIGN_WIDTH, size.Y / DESIGN_HEIGHT), 0.4, 1.6)
	uiScale.Scale = scale
	root.Size = UDim2.fromOffset(size.X / scale, size.Y / scale)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)
updateScale()

local Screen = {}

Screen.root = root
Screen.hudLayer = hudLayer
Screen.toastLayer = toastLayer

local currentModal: GuiObject? = nil
local currentBlocking = false

-- Відкриває модальне вікно. blocking = true: поки воно відкрите, інші вікна відкрити не можна.
function Screen.openModal(frame: GuiObject, blocking: boolean?)
	if currentModal and currentModal ~= frame then
		currentModal.Visible = false
	end
	frame.Parent = modalLayer
	frame.ZIndex = 2
	frame.Visible = true
	backdrop.Visible = true
	currentModal = frame
	currentBlocking = blocking == true
end

function Screen.closeModal(frame: GuiObject?)
	if frame and currentModal ~= frame then
		return
	end
	if currentModal then
		currentModal.Visible = false
	end
	currentModal = nil
	currentBlocking = false
	backdrop.Visible = false
end

function Screen.canOpen(): boolean
	return not currentBlocking
end

function Screen.current(): GuiObject?
	return currentModal
end

-- Клік по затемненню закриває звичайне (не блокувальне) вікно.
backdrop.Activated:Connect(function()
	if currentModal and not currentBlocking then
		Screen.closeModal()
	end
end)

-- Типова рамка модального вікна: заголовок + кнопка закриття + область вмісту.
function Screen.makeWindow(titleKey: string, size: Vector2, onClose: (() -> ())?): (Frame, Frame)
	local window = UI.frame({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		Visible = false,
	})
	UI.corner(window, 16)
	UI.stroke(window, UI.theme.accent, 2)

	UI.label({
		key = titleKey,
		FontFace = UI.theme.fontBold,
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(24, 12),
		Size = UDim2.new(1, -110, 0, 44),
		Parent = window,
	})
	UI.button({
		Text = "X",
		TextSize = 24,
		BackgroundColor3 = UI.theme.panel2,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(44, 44),
		onClick = function()
			if onClose then
				onClose()
			end
			Screen.closeModal(window)
		end,
		Parent = window,
	})
	local content = UI.frame({
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 70),
		Size = UDim2.new(1, -48, 1, -90),
		Parent = window,
	})
	return window, content
end

return Screen
