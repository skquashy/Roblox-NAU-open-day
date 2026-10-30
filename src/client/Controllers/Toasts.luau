--!strict
-- Всплывающие уведомления (получен бейдж, новый уровень, квест выполнен и т.д.) в цветах КАІ.
-- Тексты приходят ключами Locale, сервер сам их не переводит.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Theme = require(Shared.Theme)

local Lib = script.Parent.Parent.Lib
local NetClient = require(Lib.NetClient)
local Lang = require(Lib.Lang)

local Toasts = {}

local container: Frame

function Toasts.show(text: string)
	local toast = Instance.new("Frame")
	toast.BackgroundColor3 = Theme.colors.deep
	toast.BackgroundTransparency = 1
	toast.Size = UDim2.fromOffset(460, 46)
	toast.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.colors.accent
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Theme.font(Enum.FontWeight.SemiBold)
	label.TextSize = 22
	label.TextColor3 = Theme.colors.white
	label.TextTransparency = 1
	label.TextWrapped = true
	label.Text = text
	label.Parent = toast

	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(toast, info, { BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(label, info, { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, info, { Transparency = 0 }):Play()

	task.delay(3.2, function()
		local out = TweenInfo.new(0.35)
		TweenService:Create(toast, out, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, out, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, out, { Transparency = 1 }):Play()
		task.wait(0.4)
		toast:Destroy()
	end)
end

function Toasts.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "KAIToasts"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	container = Instance.new("Frame")
	container.Name = "ToastList"
	container.BackgroundTransparency = 1
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.new(0.5, 0, 0, 84)
	container.Size = UDim2.fromOffset(460, 300)
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = container

	NetClient.on("Toast", function(key: string, args: { string }?)
		if typeof(key) == "string" then
			Toasts.show(Lang.t(key, args))
		end
	end)
end

return Toasts
