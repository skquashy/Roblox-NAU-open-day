--!strict
-- Постійний інтерфейс у кольорах КАІ: ліворуч угорі монети та рівень зі шкалою XP, по центру прогрес за
-- факультетами, ліворуч трекер квестів, праворуч унизу кнопки вікон (квести, бейджі, інвентар, налаштування).
-- Усе лише показує стан від сервера (Snapshot); нічого не рахує.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Faculties = require(Shared.Data.Faculties)
local QuestData = require(Shared.Data.Quests)
local Progression = require(Shared.Util.Progression)

local Lib = script.Parent.Parent.Lib
local Lang = require(Lib.Lang)
local UI = require(Lib.UI)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)
local Panels = require(script.Parent.Panels)

local HUD = {}

local theme = UI.theme
local MAX_TRACKED_QUESTS = 4

local coinsLabel: TextLabel
local levelLabel: TextLabel
local xpLabel: TextLabel
local setXp: (number) -> ()
local facultiesLabel: TextLabel
local setFaculties: (number) -> ()
local questList: Frame

-- Плашка з темним тлом, закругленням і обводкою кольору КАІ.
local function pill(parent: Instance, position: UDim2, size: UDim2, anchor: Vector2?): Frame
	local frame = UI.frame({
		BackgroundColor3 = theme.navy,
		BackgroundTransparency = 0.12,
		AnchorPoint = anchor or Vector2.new(0, 0),
		Position = position,
		Size = size,
		Parent = parent,
	})
	UI.corner(frame, 14)
	UI.stroke(frame, theme.accent, 2)
	return frame
end

local function renderQuests(snapshot: Types.Snapshot)
	UI.clear(questList)
	local shown = 0
	for _, quest in snapshot.quests do
		local def = QuestData.byId[quest.id]
		if def and not quest.done and shown < MAX_TRACKED_QUESTS then
			shown += 1
			local row = UI.frame({
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
				LayoutOrder = shown,
				Parent = questList,
			})
			local box = UI.frame({
				BackgroundColor3 = theme.panel,
				Position = UDim2.fromOffset(0, 8),
				Size = UDim2.fromOffset(20, 20),
				Parent = row,
			})
			UI.corner(box, 5)
			UI.stroke(box, theme.pink, 2)
			local text = Lang.t(def.titleKey)
			if quest.target > 1 then
				text ..= (" (%d/%d)"):format(quest.progress, quest.target)
			end
			UI.label({
				Text = text,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Parent = row,
			})
		end
	end
	if shown == 0 then
		UI.label({
			Text = "✔ " .. Lang.t("ui.done"),
			TextSize = 19,
			TextColor3 = theme.good,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 34),
			Parent = questList,
		})
	end
end

local function render(snapshot: Types.Snapshot)
	coinsLabel.Text = tostring(snapshot.coins)
	local level, into, need = Progression.levelInfo(snapshot.xp)
	levelLabel.Text = tostring(level)
	if need > 0 then
		xpLabel.Text = Lang.t("ui.level", { tostring(level) })
			.. "   "
			.. into
			.. "/"
			.. need
			.. " XP"
		setXp(into / need)
	else
		xpLabel.Text = Lang.t("ui.level", { tostring(level) }) .. "   MAX"
		setXp(1)
	end
	local total = #Faculties.list
	facultiesLabel.Text =
		Lang.t("ui.faculties", { tostring(snapshot.exploredCount), tostring(total) })
	setFaculties(snapshot.exploredCount / total)
	renderQuests(snapshot)
end

local function buildTopLeft(parent: Frame)
	-- Монети: золота монета і число.
	local coins = pill(parent, UDim2.fromOffset(16, 14), UDim2.fromOffset(180, 44))
	local coin = UI.frame({
		BackgroundColor3 = theme.gold,
		Position = UDim2.fromOffset(5, 5),
		Size = UDim2.fromOffset(34, 34),
		Parent = coins,
	})
	UI.corner(coin, 17)
	UI.stroke(coin, Color3.fromRGB(190, 130, 0), 2)
	UI.label({
		Text = "К",
		FontFace = theme.fontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(150, 90, 0),
		Size = UDim2.fromScale(1, 1),
		Parent = coin,
	})
	coinsLabel = UI.label({
		Text = "0",
		FontFace = theme.fontBold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Parent = coins,
	})

	-- Рівень і шкала XP.
	local level = pill(parent, UDim2.fromOffset(16, 66), UDim2.fromOffset(300, 56))
	local badge = UI.frame({
		BackgroundColor3 = theme.pink,
		Position = UDim2.fromOffset(6, 7),
		Size = UDim2.fromOffset(42, 42),
		Parent = level,
	})
	UI.corner(badge, 21)
	levelLabel = UI.label({
		Text = "1",
		FontFace = theme.fontBold,
		TextSize = 24,
		Size = UDim2.fromScale(1, 1),
		Parent = badge,
	})
	xpLabel = UI.label({
		Text = "",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(58, 5),
		Size = UDim2.new(1, -66, 0, 20),
		Parent = level,
	})
	local xpBar, setBar = UI.bar({
		Position = UDim2.fromOffset(58, 32),
		Size = UDim2.new(1, -70, 0, 12),
		Parent = level,
	}, theme.accent)
	xpBar.BackgroundColor3 = theme.panel
	setXp = setBar

	-- Трекер квестів.
	local quests = pill(parent, UDim2.fromOffset(16, 134), UDim2.fromOffset(300, 220))
	UI.label({
		key = "ui.quests",
		FontFace = theme.fontBold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -32, 0, 28),
		Parent = quests,
	})
	questList = UI.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 44),
		Size = UDim2.new(1, -32, 1, -52),
		Parent = quests,
	})
	UI.list(questList, 2)
end

local function buildTopCenter(parent: Frame)
	local box =
		pill(parent, UDim2.new(0.5, 0, 0, 14), UDim2.fromOffset(300, 56), Vector2.new(0.5, 0))
	facultiesLabel = UI.label({
		Text = "",
		FontFace = theme.fontBold,
		TextSize = 20,
		Position = UDim2.fromOffset(0, 5),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = box,
	})
	local bar, setBar = UI.bar({
		Position = UDim2.fromOffset(16, 34),
		Size = UDim2.new(1, -32, 0, 12),
		Parent = box,
	}, theme.pink)
	bar.BackgroundColor3 = theme.panel
	setFaculties = setBar
end

local function buildButtons(parent: Frame)
	local row = UI.frame({
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(620, 52),
		Parent = parent,
	})
	local layout = UI.list(row, 10, true)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local entries = {
		{ panel = "quests", key = "ui.quests" },
		{ panel = "badges", key = "ui.badges" },
		{ panel = "inventory", key = "ui.inventory" },
		{ panel = "settings", key = "ui.settings" },
	}
	for index, entry in entries do
		UI.button({
			key = entry.key,
			TextSize = 19,
			Size = UDim2.fromOffset(142, 48),
			BackgroundColor3 = theme.accent,
			LayoutOrder = index,
			onClick = function()
				if Screen.canOpen() then
					Panels.open(entry.panel)
				end
			end,
			Parent = row,
		})
	end
end

function HUD.init()
	local parent = Screen.hudLayer
	buildTopLeft(parent)
	buildTopCenter(parent)
	buildButtons(parent)
	State.Changed:connect(render)
	Lang.changed:connect(function()
		if State.snapshot then
			render(State.snapshot)
		end
	end)
	if State.snapshot then
		render(State.snapshot)
	end
end

return HUD
