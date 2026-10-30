--!strict
-- Язык интерфейса, выбор образа и визуальная часть (головной убор-заглушка).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)
local Archetypes = require(Shared.Data.Archetypes)
local Items = require(Shared.Data.Items)
local Guard = require(Shared.Util.Guard)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)

local Preferences = {}

local HAT_NAME = "KAIHat"

local function applyHat(player: Player)
	local profile = PlayerData.get(player)
	local character = player.Character
	if not profile or not character then
		return
	end
	local old = character:FindFirstChild(HAT_NAME)
	if old then
		old:Destroy()
	end
	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local shape: Enum.PartType? = nil
	local size: Vector3? = nil
	local color: Color3? = nil

	local item = Items.byId[profile.hat]
	if item and item.category == "cosmetic" then
		shape, size, color = item.hatShape, item.hatSize, item.hatColor
	else
		local archetype = Archetypes.byId[profile.archetype]
		if archetype then
			shape, size, color = archetype.hatShape, archetype.hatSize, archetype.color
		end
	end
	if not shape or not size or not color then
		return
	end

	local hat = Instance.new("Part")
	hat.Name = HAT_NAME
	hat.Shape = shape
	hat.Size = size
	hat.Color = color
	hat.Material = Enum.Material.SmoothPlastic
	hat.CanCollide = false
	hat.CanQuery = false
	hat.CanTouch = false
	hat.Massless = true
	local lift = head.Size.Y / 2 + size.Y / 2 - 0.15
	if shape == Enum.PartType.Cylinder then
		-- Цилиндр в Roblox лежит вдоль оси X: поворачиваем, чтобы стоял вертикально.
		hat.CFrame = head.CFrame
			* CFrame.new(0, head.Size.Y / 2 + size.X / 2 - 0.15, 0)
			* CFrame.Angles(0, 0, math.rad(90))
	else
		hat.CFrame = head.CFrame * CFrame.new(0, lift, 0)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = hat
	weld.Parent = hat
	hat.Parent = character
end

-- Вызывайте после смены образа или косметики.
function Preferences.refresh(player: Player)
	applyHat(player)
	PlayerData.markChanged(player)
end

function Preferences.init()
	NetServer.on("SetLanguage", function(player: Player, raw: unknown)
		local lang = Guard.str(raw, 5)
		local profile = PlayerData.get(player)
		if not lang or not profile or not Locale.isSupported(lang) then
			return
		end
		profile.lang = lang
		PlayerData.markChanged(player)
	end)

	NetServer.on("SelectArchetype", function(player: Player, raw: unknown)
		local id = Guard.str(raw, 30)
		local profile = PlayerData.get(player)
		if not id or not profile or not Archetypes.byId[id] then
			return
		end
		profile.archetype = id
		Preferences.refresh(player)
	end)

	PlayerData.Loaded:connect(function(player: Player)
		applyHat(player)
	end)
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function()
		-- Ждём профиль (если ещё грузится), затем надеваем.
		task.spawn(function()
			local waited = 0
			while not PlayerData.get(player) and waited < 30 and player.Parent do
				task.wait(0.25)
				waited += 0.25
			end
			task.wait(0.3) -- дать персонажу собраться
			applyHat(player)
		end)
	end)
end

function Preferences.start()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return Preferences
