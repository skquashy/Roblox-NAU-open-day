--!strict
-- Окна: «Квести», «Бейджі», «Інвентар» (квестовые предметы и косметика с магазином), «Налаштування».
-- Окно перерисовывается при каждом новом Snapshot, пока открыто. Покупка и одевание только запросы серверу.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Locale = require(Shared.Locale)
local QuestData = require(Shared.Data.Quests)
local BadgeData = require(Shared.Data.Badges)
local Items = require(Shared.Data.Items)

local Lib = script.Parent.Parent.Lib
local Lang = require(Lib.Lang)
local NetClient = require(Lib.NetClient)
local UI = require(Lib.UI)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local Panels = {}

local theme = UI.theme

type Panel = {
	window: Frame,
	scroll: ScrollingFrame,
	render: (snapshot: Types.Snapshot, scroll: ScrollingFrame) -> (),
}

local panels: { [string]: Panel } = {}
local activeName: string? = nil

local function newScroller(content: Frame): ScrollingFrame
	local scroll = UI.make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = content,
	})
	return scroll
end

local function header(parent: Instance, key: string, order: number)
	UI.label({
		key = key,
		FontFace = theme.fontBold,
		TextSize = 22,
		TextColor3 = theme.sky,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -12, 0, 34),
		LayoutOrder = order,
		Parent = parent,
	})
end

local function renderQuests(snapshot: Types.Snapshot, scroll: ScrollingFrame)
	UI.clear(scroll)
	UI.list(scroll, 8)
	for index, quest in snapshot.quests do
		local def = QuestData.byId[quest.id]
		if def then
			local row = UI.frame({
				BackgroundColor3 = theme.panel2,
				Size = UDim2.new(1, -12, 0, 64),
				LayoutOrder = index,
				Parent = scroll,
			})
			UI.corner(row, 10)
			local title = Lang.t(def.titleKey)
			if quest.target > 1 then
				title ..= (" (%d/%d)"):format(quest.progress, quest.target)
			end
			local color = theme.text
			if quest.done then
				title = "✔ " .. title
				color = theme.good
			end
			UI.label({
				Text = title,
				TextSize = 19,
				TextColor3 = color,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Parent = row,
			})
		end
	end
end

local function renderBadges(snapshot: Types.Snapshot, scroll: ScrollingFrame)
	UI.clear(scroll)
	local owned: { [string]: boolean } = {}
	for _, id in snapshot.badges do
		owned[id] = true
	end
	UI.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(210, 118),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	for index, badge in BadgeData.list do
		local has = owned[badge.id] == true
		local card = UI.frame({
			BackgroundColor3 = theme.panel2,
			BackgroundTransparency = has and 0 or 0.55,
			LayoutOrder = index,
			Parent = scroll,
		})
		UI.corner(card, 12)
		UI.stroke(card, has and theme.gold or theme.navy, 2)
		UI.label({
			Text = has and badge.icon or "🔒",
			TextSize = 32,
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.new(1, 0, 0, 40),
			Parent = card,
		})
		UI.label({
			Text = Lang.t(badge.nameKey),
			FontFace = theme.fontBold,
			TextSize = 17,
			Position = UDim2.fromOffset(8, 46),
			Size = UDim2.new(1, -16, 0, 22),
			Parent = card,
		})
		UI.label({
			Text = Lang.t(badge.descKey),
			TextSize = 13,
			TextColor3 = theme.muted,
			Position = UDim2.fromOffset(8, 70),
			Size = UDim2.new(1, -16, 0, 44),
			Parent = card,
		})
	end
end

local function itemRow(
	scroll: ScrollingFrame,
	order: number,
	item: Items.ItemDef,
	count: number?
): Frame
	local row = UI.frame({
		BackgroundColor3 = theme.panel2,
		Size = UDim2.new(1, -12, 0, 56),
		LayoutOrder = order,
		Parent = scroll,
	})
	UI.corner(row, 10)
	UI.label({
		Text = item.icon,
		TextSize = 30,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.fromOffset(48, 56),
		Parent = row,
	})
	local text = Lang.t(item.nameKey)
	if count and count > 1 then
		text ..= " ×" .. count
	end
	UI.label({
		Text = text,
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(64, 0),
		Size = UDim2.new(1, -240, 1, 0),
		Parent = row,
	})
	return row
end

local function renderInventory(snapshot: Types.Snapshot, scroll: ScrollingFrame)
	UI.clear(scroll)
	UI.list(scroll, 8)
	local order = 0
	order += 1
	header(scroll, "ui.quest_items", order)
	local any = false
	for _, item in Items.list do
		local count = snapshot.inventory[item.id] or 0
		if item.category == "quest" and count > 0 then
			any = true
			order += 1
			itemRow(scroll, order, item, count)
		end
	end
	if not any then
		order += 1
		UI.label({
			key = "ui.empty",
			TextColor3 = theme.muted,
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -12, 0, 28),
			LayoutOrder = order,
			Parent = scroll,
		})
	end
	order += 1
	header(scroll, "ui.cosmetics", order)
	for _, item in Items.list do
		if item.category == "cosmetic" then
			order += 1
			local row = itemRow(scroll, order, item, nil)
			local owned = (snapshot.inventory[item.id] or 0) > 0
			local equipped = snapshot.hat == item.id
			local label = Lang.t("ui.buy", { tostring(item.price) })
			if equipped then
				label = Lang.t("ui.unequip")
			elseif owned then
				label = Lang.t("ui.equip")
			end
			UI.button({
				Text = label,
				TextSize = 16,
				Size = UDim2.fromOffset(150, 38),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				BackgroundColor3 = owned and theme.accent or theme.pink,
				onClick = function()
					if not owned then
						NetClient.fire("BuyItem", item.id)
					elseif equipped then
						NetClient.fire("EquipItem", "")
					else
						NetClient.fire("EquipItem", item.id)
					end
				end,
				Parent = row,
			})
		end
	end
end

local function renderSettings(_snapshot: Types.Snapshot, scroll: ScrollingFrame)
	UI.clear(scroll)
	UI.list(scroll, 10)
	header(scroll, "ui.language", 1)
	local row = UI.frame({
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 48),
		LayoutOrder = 2,
		Parent = scroll,
	})
	UI.list(row, 10, true)
	for index, lang in Locale.languages do
		UI.button({
			Text = string.upper(lang),
			Size = UDim2.fromOffset(120, 44),
			BackgroundColor3 = lang == Lang.get() and theme.accent or theme.panel2,
			LayoutOrder = index,
			onClick = function()
				Lang.set(lang)
				NetClient.fire("SetLanguage", lang)
			end,
			Parent = row,
		})
	end
end

local function register(
	name: string,
	titleKey: string,
	render: (Types.Snapshot, ScrollingFrame) -> ()
)
	local window, content = Screen.makeWindow(titleKey, Vector2.new(720, 540), function()
		activeName = nil
	end)
	panels[name] = { window = window, scroll = newScroller(content), render = render }
end

function Panels.open(name: string)
	local panel = panels[name]
	if not panel or not Screen.canOpen() then
		return
	end
	activeName = name
	if State.snapshot then
		panel.render(State.snapshot, panel.scroll)
	end
	Screen.openModal(panel.window)
end

function Panels.init()
	register("quests", "ui.quests", renderQuests)
	register("badges", "ui.badges", renderBadges)
	register("inventory", "ui.inventory", renderInventory)
	register("settings", "ui.settings", renderSettings)
	local function refresh()
		local name = activeName
		local snapshot = State.snapshot
		if name and snapshot then
			local panel = panels[name]
			if panel.window.Visible then
				panel.render(snapshot, panel.scroll)
			else
				activeName = nil
			end
		end
	end
	State.Changed:connect(refresh)
	Lang.changed:connect(refresh)
end

return Panels
