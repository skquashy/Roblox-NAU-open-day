--!strict
-- Выбор образа при первом входе (и выбор языка на случай, если автоопределение ошиблось).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Archetypes = require(Shared.Data.Archetypes)
local Locale = require(Shared.Locale)

local Lib = script.Parent.Parent.Lib
local NetClient = require(Lib.NetClient)
local Lang = require(Lib.Lang)
local UI = require(Lib.UI)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local ArchetypePicker = {}

local window: Frame
local shown = false

local function build()
	window = UI.frame({
		Name = "ArchetypePicker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(860, 520),
		Visible = false,
	})
	UI.corner(window, 18)
	UI.stroke(window, UI.theme.accent, 2)

	UI.label({
		key = "arch.title",
		FontFace = UI.theme.fontBold,
		TextSize = 34,
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 48),
		Parent = window,
	})
	UI.label({
		key = "arch.hint",
		TextSize = 19,
		TextColor3 = UI.theme.muted,
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = window,
	})

	-- Переключатель языка
	local langRow = UI.frame({
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(180, 40),
		Parent = window,
	})
	UI.list(langRow, 8, true)
	for index, lang in Locale.languages do
		UI.button({
			Text = string.upper(lang),
			Size = UDim2.fromOffset(80, 36),
			BackgroundColor3 = UI.theme.panel2,
			LayoutOrder = index,
			onClick = function()
				Lang.set(lang)
				NetClient.fire("SetLanguage", lang)
			end,
			Parent = langRow,
		})
	end

	local grid = UI.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(30, 104),
		Size = UDim2.new(1, -60, 1, -130),
		Parent = window,
	})
	UI.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(240, 180),
		CellPadding = UDim2.fromOffset(15, 15),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	for index, archetype in Archetypes.list do
		local card = UI.button({
			BackgroundColor3 = UI.theme.panel2,
			LayoutOrder = index,
			onClick = function()
				NetClient.fire("SelectArchetype", archetype.id)
				Screen.closeModal(window)
			end,
			Parent = grid,
		})
		UI.stroke(card, archetype.color, 3)
		UI.label({
			Text = archetype.icon,
			TextSize = 60,
			Position = UDim2.fromOffset(0, 14),
			Size = UDim2.new(1, 0, 0, 80),
			Parent = card,
		})
		UI.label({
			key = archetype.nameKey,
			FontFace = UI.theme.fontBold,
			TextSize = 24,
			Position = UDim2.fromOffset(8, 104),
			Size = UDim2.new(1, -16, 0, 60),
			Parent = card,
		})
	end
end

function ArchetypePicker.init()
	build()
	State.Changed:connect(function(snapshot: Types.Snapshot)
		if snapshot.archetype == "" and not shown then
			shown = true
			Screen.openModal(window, true)
		elseif snapshot.archetype ~= "" and window.Visible then
			Screen.closeModal(window)
		end
	end)
end

return ArchetypePicker
