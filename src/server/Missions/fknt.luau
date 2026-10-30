--!strict
-- Жива місія ФКНТ «Кіберзахист». У центрі лабораторії голографічна мережа з шести вузлів. На вузлах
-- з'являються загрози трьох видів: вірус (лікується кнопкою «Встановити патч»), атака з IP («Заблокувати IP»)
-- і збій системи («Перезапустити»). У кожної загрози таймер. Гравець тисне потрібну кнопку перед голограмою:
-- кнопка розв'язує найтерміновішу загрозу свого виду. Хибне натискання, пропущена загроза знижують безпеку.
-- Результат = безпека наприкінці (0..1). Натискання приймає сервер через ProximityPrompt, клієнт
-- нічого не надсилає. Назви загроз і табло беруться з Locale мовою гравця.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)
local Types = require(Shared.Types)

local Server = script.Parent.Parent
local PlayerData = require(Server.Systems.PlayerData)
local Fknt = require(Server.World.Labs.Fknt)

local Mission = {}

type ThreatDef = { id: string, action: string, nameKey: string, icon: string, color: Color3 }

type Threat = {
	def: ThreatDef,
	node: number,
	total: number,
	left: number,
	gui: BillboardGui,
	bar: Frame,
}

local THREATS: { ThreatDef } = {
	{
		id = "virus",
		action = "patch",
		nameKey = "mg.fknt.threat.virus",
		icon = "☠",
		color = Color3.fromRGB(232, 65, 80),
	},
	{
		id = "attack",
		action = "block",
		nameKey = "mg.fknt.threat.attack",
		icon = "⛔",
		color = Color3.fromRGB(240, 140, 40),
	},
	{
		id = "crash",
		action = "restart",
		nameKey = "mg.fknt.threat.crash",
		icon = "⚠",
		color = Color3.fromRGB(240, 210, 60),
	},
}

local DURATION = { 70, 85, 100 }
local SPAWN_INTERVAL = { 5.5, 4.2, 3.2 } -- пауза між новими загрозами
local THREAT_TIME = { 11, 8.5, 7 } -- скільки секунд до того, як загрозу буде пропущено
local MAX_ACTIVE = { 1, 2, 3 }
local MISSED_PENALTY = 15
local WRONG_PENALTY = 4
local SOLVED_BONUS = 3
local BUTTON_COOLDOWN = 0.3
local PUSH_INTERVAL = 0.25
local NODE_COLOR = Color3.fromRGB(150, 220, 255)

Mission.id = "fknt"
Mission.titleKey = "mg.fknt.title"
Mission.hintKey = "mg.fknt.hint"

function Mission.duration(difficulty: number): number
	return DURATION[difficulty] or DURATION[1]
end

local function languageOf(player: Player): string
	local profile = PlayerData.get(player)
	if profile and profile.lang ~= "" then
		return profile.lang
	end
	return "uk"
end

local function findPart(room: Model, name: string): BasePart?
	local part = room:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

-- Хмаринка над вузлом: іконка, назва загрози та смужка часу, що залишився.
local function makeBillboard(node: BasePart, def: ThreatDef, lang: string): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Threat"
	gui.Size = UDim2.fromOffset(190, 110)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = node
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(1, 0, 0, 56)
	icon.TextScaled = true
	icon.TextColor3 = def.color
	icon.Text = def.icon
	icon.Parent = gui
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(0, 54)
	name.Size = UDim2.new(1, 0, 0, 26)
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Text = Locale.translate(lang, def.nameKey)
	name.Parent = gui
	local back = Instance.new("Frame")
	back.BackgroundColor3 = Color3.fromRGB(12, 20, 40)
	back.Position = UDim2.fromOffset(15, 86)
	back.Size = UDim2.new(1, -30, 0, 10)
	back.BorderSizePixel = 0
	back.Parent = gui
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = def.color
	bar.Size = UDim2.fromScale(1, 1)
	bar.BorderSizePixel = 0
	bar.Parent = back
	return gui, bar
end

function Mission.start(ctx: Types.MissionContext): Types.MissionRun?
	local room = ctx.room
	local hub = findPart(room, "Hub")
	local nodes: { BasePart } = {}
	local beams: { BasePart } = {}
	for index = 1, Fknt.NODE_COUNT do
		local node = findPart(room, "Node" .. index)
		local beam = findPart(room, "Beam" .. index)
		if not node or not beam then
			warn("[fknt] в лаборатории не хватает узлов сети")
			return nil
		end
		table.insert(nodes, node)
		table.insert(beams, beam)
	end
	local buttons: { [string]: ProximityPrompt } = {}
	for _, name in { "ButtonPatch", "ButtonBlock", "ButtonRestart" } do
		local part = findPart(room, name)
		local prompt = part and part:FindFirstChildWhichIsA("ProximityPrompt")
		local action = part and part:GetAttribute("Action")
		if not part or not prompt or typeof(action) ~= "string" then
			warn("[fknt] в лаборатории не хватает кнопок")
			return nil
		end
		buttons[action] = prompt
	end
	local statusLabel = room:FindFirstChild("StatusLabel", true)

	local lang = languageOf(ctx.player)
	local difficulty = ctx.difficulty
	local active: { Threat } = {}
	local security = 100
	local solved, wrong, missed = 0, 0, 0
	local spawnTimer = 2
	local pushTimer = 0
	local lastPress = 0
	local stopped = false
	local connections: { RBXScriptConnection } = {}

	local function burst(position: Vector3, color: Color3)
		local flash = Instance.new("Part")
		flash.Anchored = true
		flash.CanCollide = false
		flash.Shape = Enum.PartType.Ball
		flash.Material = Enum.Material.Neon
		flash.Color = color
		flash.Size = Vector3.new(2.4, 2.4, 2.4)
		flash.Position = position
		flash.Parent = room
		task.delay(0.3, function()
			flash:Destroy()
		end)
	end

	local function resetNode(index: number)
		beams[index].Color = Fknt.BEAM_COLOR
		beams[index].Transparency = 0
		nodes[index].Color = NODE_COLOR
	end

	local function removeThreat(threat: Threat)
		local index = table.find(active, threat)
		if index then
			table.remove(active, index)
		end
		threat.gui:Destroy()
		resetNode(threat.node)
	end

	local function updateStatus()
		if statusLabel and statusLabel:IsA("TextLabel") then
			statusLabel.Text =
				Locale.translate(lang, "mg.fknt.status", { tostring(math.floor(security + 0.5)) })
			local color = Color3.fromRGB(80, 220, 120)
			if security < 35 then
				color = Color3.fromRGB(232, 65, 80)
			elseif security < 70 then
				color = Color3.fromRGB(240, 190, 40)
			end
			statusLabel.TextColor3 = color
		end
	end

	local function pushState()
		updateStatus()
		ctx.push({
			security = security,
			solved = solved,
			wrong = wrong,
			missed = missed,
			threats = #active,
		})
	end

	local function spawnThreat()
		local taken: { [number]: boolean } = {}
		for _, threat in active do
			taken[threat.node] = true
		end
		local free: { number } = {}
		for index = 1, #nodes do
			if not taken[index] then
				table.insert(free, index)
			end
		end
		if #free == 0 then
			return
		end
		local node = free[ctx.rng:NextInteger(1, #free)]
		local def = THREATS[ctx.rng:NextInteger(1, #THREATS)]
		local total = THREAT_TIME[difficulty] or THREAT_TIME[1]
		local gui, bar = makeBillboard(nodes[node], def, lang)
		beams[node].Color = def.color
		nodes[node].Color = def.color
		table.insert(
			active,
			{ def = def, node = node, total = total, left = total, gui = gui, bar = bar }
		)
	end

	local function onButton(action: string, player: Player)
		if stopped or player ~= ctx.player then
			return
		end
		local now = os.clock()
		if now - lastPress < BUTTON_COOLDOWN then
			return
		end
		lastPress = now
		local best: Threat? = nil
		for _, threat in active do
			if threat.def.action == action and (not best or threat.left < best.left) then
				best = threat
			end
		end
		if best then
			solved += 1
			security = math.min(100, security + SOLVED_BONUS)
			burst(nodes[best.node].Position, Color3.fromRGB(80, 220, 120))
			removeThreat(best)
		else
			wrong += 1
			security = math.max(0, security - WRONG_PENALTY)
			if hub then
				burst(hub.Position, Color3.fromRGB(232, 65, 80))
			end
		end
		pushState()
	end

	for action, prompt in buttons do
		prompt.Enabled = true
		table.insert(
			connections,
			prompt.Triggered:Connect(function(player: Player)
				onButton(action, player)
			end)
		)
	end
	pushState()

	local run = {} :: Types.MissionRun

	run.tick = function(dt: number)
		if stopped then
			return
		end
		spawnTimer -= dt
		if spawnTimer <= 0 then
			spawnTimer = (SPAWN_INTERVAL[difficulty] or SPAWN_INTERVAL[1])
				* ctx.rng:NextNumber(0.8, 1.2)
			if #active < (MAX_ACTIVE[difficulty] or 1) then
				spawnThreat()
			end
		end
		for _, threat in table.clone(active) do
			threat.left -= dt
			threat.bar.Size = UDim2.fromScale(math.clamp(threat.left / threat.total, 0, 1), 1)
			-- Промінь загрози блимає, чим менше часу, тим частіше.
			local urgency = 1 - math.clamp(threat.left / threat.total, 0, 1)
			local pulse = math.abs(math.sin(os.clock() * (3 + urgency * 9)))
			beams[threat.node].Transparency = pulse * 0.6
			if threat.left <= 0 then
				missed += 1
				security = math.max(0, security - MISSED_PENALTY)
				burst(nodes[threat.node].Position, Color3.fromRGB(232, 65, 80))
				removeThreat(threat)
				pushState()
			end
		end
		pushTimer -= dt
		if pushTimer <= 0 then
			pushTimer = PUSH_INTERVAL
			pushState()
		end
	end

	run.score = function(): number
		return math.clamp(security / 100, 0, 1)
	end

	run.isOver = function(): boolean
		return security <= 0
	end

	run.stop = function()
		stopped = true
		for _, connection in connections do
			connection:Disconnect()
		end
		for _, prompt in buttons do
			prompt.Enabled = false
		end
		for _, threat in table.clone(active) do
			removeThreat(threat)
		end
		for index = 1, #beams do
			resetNode(index)
		end
		if statusLabel and statusLabel:IsA("TextLabel") then
			statusLabel.TextColor3 = Fknt.BEAM_COLOR
			statusLabel.Text = Locale.translate("uk", "mg.fknt.title")
				.. " / "
				.. Locale.translate("en", "mg.fknt.title")
		end
	end

	return run
end

return Mission
