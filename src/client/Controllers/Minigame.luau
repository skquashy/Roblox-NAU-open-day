--!strict
-- Клієнтська частина мінігри: вікно вибору складності (за підказкою пульта), панель стану місії
-- (таймер, лічильники, кнопка «Вийти») і вікно результату. Усе лише показує те, що
-- надсилає сервер; перевірки та нагороди рахує сервер.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)

local Lib = script.Parent.Parent.Lib
local Lang = require(Lib.Lang)
local NetClient = require(Lib.NetClient)
local UI = require(Lib.UI)
local Screen = require(script.Parent.Screen)
local State = require(script.Parent.State)

local Minigame = {}

local theme = UI.theme

local promptWindow: Frame
local promptContent: Frame
local resultWindow: Frame
local resultTitle: TextLabel
local resultScore: TextLabel
local resultReward: TextLabel
local missionFrame: Frame
local timeLabel: TextLabel
local statsLabel: TextLabel
local setSecurity: (number) -> ()

local function showPrompt(facultyId: string)
	if not Screen.canOpen() then
		return
	end
	UI.clear(promptContent)
	local snapshot = State.snapshot
	local stat: Types.MinigameStat? = nil
	if snapshot then
		stat = snapshot.minigames[facultyId]
	end
	UI.label({
		key = "mg." .. facultyId .. ".title",
		FontFace = theme.fontBold,
		TextSize = 30,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = promptContent,
	})
	UI.label({
		key = "mg." .. facultyId .. ".hint",
		TextSize = 18,
		TextColor3 = theme.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 70),
		Parent = promptContent,
	})
	local bestText = Lang.t("ui.no_best")
	if stat and stat.best > 0 then
		bestText = Lang.t("ui.best", { tostring(math.floor(stat.best * 100 + 0.5)) })
	end
	UI.label({
		Text = bestText,
		TextSize = 18,
		TextColor3 = theme.sky,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 122),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = promptContent,
	})
	local passes = 0
	if stat then
		passes = stat.passes
	end
	for difficulty = 1, 3 do
		local locked = passes < difficulty - 1
		local label = Lang.t("ui.difficulty") .. " " .. difficulty
		if locked then
			label = "🔒 " .. label
		end
		UI.button({
			Text = label,
			TextSize = 20,
			Size = UDim2.new(1, 0, 0, 52),
			Position = UDim2.fromOffset(0, 162 + (difficulty - 1) * 62),
			BackgroundColor3 = locked and theme.panel2 or theme.accent,
			onClick = function()
				if locked then
					return
				end
				NetClient.fire("MinigameStart", facultyId, difficulty)
				Screen.closeModal(promptWindow)
			end,
			Parent = promptContent,
		})
	end
	Screen.openModal(promptWindow)
end

local function buildMissionPanel(parent: Frame)
	missionFrame = UI.frame({
		BackgroundColor3 = theme.navy,
		BackgroundTransparency = 0.12,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(440, 130),
		Visible = false,
		Parent = parent,
	})
	UI.corner(missionFrame, 14)
	UI.stroke(missionFrame, theme.pink, 2)
	timeLabel = UI.label({
		Text = "",
		FontFace = theme.fontBold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -150, 0, 28),
		Parent = missionFrame,
	})
	statsLabel = UI.label({
		Text = "",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 36),
		Size = UDim2.new(1, -28, 0, 24),
		Parent = missionFrame,
	})
	UI.button({
		key = "ui.leave",
		TextSize = 16,
		Size = UDim2.fromOffset(110, 32),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		BackgroundColor3 = theme.pink,
		onClick = function()
			NetClient.fire("MinigameCancel")
		end,
		Parent = missionFrame,
	})
	-- Рівень безпеки: одна широка шкала.
	local bar, setBar = UI.bar({
		Position = UDim2.fromOffset(14, 74),
		Size = UDim2.new(1, -28, 0, 18),
		Parent = missionFrame,
	}, theme.good)
	bar.BackgroundColor3 = theme.panel
	setBar(1)
	setSecurity = setBar
	UI.label({
		key = "mg.fknt.security",
		TextSize = 14,
		TextColor3 = theme.muted,
		Position = UDim2.fromOffset(14, 96),
		Size = UDim2.new(1, -28, 0, 22),
		Parent = missionFrame,
	})
end

local function onMissionState(state: { [string]: any })
	if state.ended then
		missionFrame.Visible = false
		return
	end
	missionFrame.Visible = true
	timeLabel.Text = Lang.t("mg.time", { tostring(state.timeLeft or 0) })
	statsLabel.Text = Lang.t("mg.stats", {
		tostring(state.solved or 0),
		tostring(state.wrong or 0),
		tostring(state.missed or 0),
	})
	local security = state.security
	if typeof(security) == "number" then
		setSecurity(security / 100)
	end
end

local function buildResultWindow()
	resultWindow = UI.frame({
		Name = "MissionResult",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 330),
		Visible = false,
	})
	UI.corner(resultWindow, 16)
	UI.stroke(resultWindow, theme.pink, 3)
	resultTitle = UI.label({
		Text = "",
		FontFace = theme.fontBold,
		TextSize = 38,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 56),
		Parent = resultWindow,
	})
	resultScore = UI.label({
		Text = "",
		TextSize = 28,
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = resultWindow,
	})
	resultReward = UI.label({
		Text = "",
		TextSize = 22,
		TextColor3 = theme.gold,
		Position = UDim2.fromOffset(0, 150),
		Size = UDim2.new(1, 0, 0, 36),
		Parent = resultWindow,
	})
	UI.button({
		key = "ui.close",
		Size = UDim2.fromOffset(200, 50),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -28),
		onClick = function()
			Screen.closeModal(resultWindow)
		end,
		Parent = resultWindow,
	})
end

local function onResult(result: { [string]: any })
	local passed = result.passed == true
	resultTitle.Text = Lang.t(passed and "mg.win" or "mg.lose")
	resultTitle.TextColor3 = passed and theme.good or theme.text
	resultScore.Text = Lang.t("mg.score", { tostring(math.floor((result.score or 0) * 100 + 0.5)) })
	if passed then
		resultReward.Text =
			Lang.t("mg.reward", { tostring(result.xp or 0), tostring(result.coins or 0) })
	else
		resultReward.Text = Lang.t("mg.no_reward")
	end
	missionFrame.Visible = false
	Screen.openModal(resultWindow)
end

function Minigame.init()
	local window, content = Screen.makeWindow("ui.difficulty", Vector2.new(520, 400), nil)
	promptWindow = window
	promptContent = content
	buildResultWindow()
	buildMissionPanel(Screen.hudLayer)
	NetClient.on("MinigamePrompt", showPrompt)
	NetClient.on("MissionState", onMissionState)
	NetClient.on("MissionResult", onResult)
end

return Minigame
