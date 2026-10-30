--!strict
-- Живая миссия ФКНТ «Кіберзахист». Из шлюза в лаборатории летят пакеты к четырём серверным стойкам:
-- безопасные (зелёные) надо пропустить, шкідливі (красные) заблокировать кликом. Пропущенный шкідливий
-- пакет снижает здоровье стойки. Всё считает сервер: клик ловит ClickDetector на сервере, клиент ничего
-- не присылает. Результат = среднее здоровье стоек минус штраф за блокировку безопасных пакетов.
-- Тексты пакетов берутся из Locale (mg.fknt.safe1..3, mg.fknt.bad1..3) на языке игрока.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)
local Types = require(Shared.Types)

local Server = script.Parent.Parent
local PlayerData = require(Server.Systems.PlayerData)
local Fknt = require(Server.World.Labs.Fknt)

local Mission = {}

type Rack = {
	body: BasePart,
	fill: BasePart,
	lamp: BasePart,
	hp: number,
	flash: number,
}

type Packet = {
	part: Part,
	target: number,
	malicious: boolean,
	direction: Vector3,
	remaining: number,
}

local SPAWN_INTERVAL = { 1.7, 1.25, 0.95 }
local SPEED = { 6, 8, 10 } -- студов в секунду
local DURATION = { 70, 85, 100 }
local MALICIOUS_SHARE = { 0.45, 0.5, 0.55 }
local DAMAGE = { 18, 22, 26 }
local FALSE_BLOCK_PENALTY = 0.04
local PUSH_INTERVAL = 0.25
local SAFE_COLOR = Color3.fromRGB(80, 220, 120)
local BAD_COLOR = Color3.fromRGB(232, 65, 80)
local FLY_HEIGHT = 5
local SAFE_KEYS = { "mg.fknt.safe1", "mg.fknt.safe2", "mg.fknt.safe3" }
local BAD_KEYS = { "mg.fknt.bad1", "mg.fknt.bad2", "mg.fknt.bad3" }

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

local function setBar(rack: Rack)
	local fraction = math.clamp(rack.hp / 100, 0, 1)
	local width = math.max(Fknt.BAR_WIDTH * fraction, 0.05)
	local color = SAFE_COLOR
	if fraction < 0.35 then
		color = BAD_COLOR
	elseif fraction < 0.7 then
		color = Color3.fromRGB(240, 190, 40)
	end
	local origin = rack.fill.CFrame
	-- Шкала сжимается к левому краю стойки: сдвигаем центр так, чтобы левая граница осталась на месте.
	local oldWidth = rack.fill.Size.X
	rack.fill.Size = Vector3.new(width, rack.fill.Size.Y, rack.fill.Size.Z)
	rack.fill.CFrame = origin * CFrame.new((oldWidth - width) / 2, 0, 0)
	rack.fill.Color = color
	rack.lamp.Color = color
end

local function collectRacks(room: Model): { Rack }?
	local racks: { Rack } = {}
	for index = 1, Fknt.RACK_COUNT do
		local body = room:FindFirstChild("Rack" .. index)
		local fill = room:FindFirstChild("Rack" .. index .. "Fill")
		local lamp = room:FindFirstChild("Rack" .. index .. "Lamp")
		if
			not (
				body
				and body:IsA("BasePart")
				and fill
				and fill:IsA("BasePart")
				and lamp
				and lamp:IsA("BasePart")
			)
		then
			return nil
		end
		table.insert(racks, { body = body, fill = fill, lamp = lamp, hp = 100, flash = 0 })
	end
	return racks
end

function Mission.start(ctx: Types.MissionContext): Types.MissionRun?
	local gateway = ctx.room:FindFirstChild("Gateway")
	local racks = collectRacks(ctx.room)
	if not (gateway and gateway:IsA("BasePart")) or not racks then
		warn("[fknt] в лаборатории не хватает шлюза или стоек")
		return nil
	end
	local lang = languageOf(ctx.player)
	local difficulty = ctx.difficulty
	local folder = Instance.new("Folder")
	folder.Name = "MissionPackets"
	folder.Parent = ctx.room

	local packets: { Packet } = {}
	local spawnTimer = 0.8
	local pushTimer = 0
	local blocked, leaked, falseBlocks, delivered = 0, 0, 0, 0
	local stopped = false

	local function removePacket(packet: Packet)
		local index = table.find(packets, packet)
		if index then
			table.remove(packets, index)
		end
		packet.part:Destroy()
	end

	local function burst(position: Vector3, color: Color3)
		local flash = Instance.new("Part")
		flash.Anchored = true
		flash.CanCollide = false
		flash.Shape = Enum.PartType.Ball
		flash.Material = Enum.Material.Neon
		flash.Color = color
		flash.Size = Vector3.new(2, 2, 2)
		flash.Position = position
		flash.Parent = folder
		task.delay(0.25, function()
			flash:Destroy()
		end)
	end

	local function spawnPacket()
		local malicious = ctx.rng:NextNumber() < (MALICIOUS_SHARE[difficulty] or 0.45)
		local target = ctx.rng:NextInteger(1, #racks)
		local rack = racks[target]
		local part = Instance.new("Part")
		part.Size = Vector3.new(2.6, 1.6, 1.6)
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = malicious and BAD_COLOR or SAFE_COLOR
		local startPosition = gateway.Position + Vector3.new(0, 0, ctx.rng:NextNumber(-1.5, 1.5))
		startPosition = Vector3.new(
			startPosition.X,
			gateway.Position.Y - 0.6 + ctx.rng:NextNumber(-0.6, 0.6),
			startPosition.Z
		)
		part.Position = startPosition
		part.Name = "Packet"

		local goal = rack.body.Position + rack.body.CFrame.LookVector * 3.2
		goal = Vector3.new(goal.X, FLY_HEIGHT, goal.Z)
		local offset = goal - startPosition
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(110, 34)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.AlwaysOnTop = true
		gui.MaxDistance = 90
		gui.Parent = part
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		local keys = SAFE_KEYS
		if malicious then
			keys = BAD_KEYS
		end
		label.Text = Locale.translate(lang, keys[ctx.rng:NextInteger(1, #keys)])
		label.Parent = gui

		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 80
		detector.Parent = part
		part.Parent = folder

		local packet: Packet = {
			part = part,
			target = target,
			malicious = malicious,
			direction = offset.Unit,
			remaining = offset.Magnitude,
		}
		table.insert(packets, packet)
		detector.MouseClick:Connect(function(clicker: Player)
			if stopped or clicker ~= ctx.player or table.find(packets, packet) == nil then
				return
			end
			if packet.malicious then
				blocked += 1
				burst(part.Position, SAFE_COLOR)
			else
				falseBlocks += 1
				burst(part.Position, BAD_COLOR)
			end
			removePacket(packet)
		end)
	end

	local function averageHealth(): number
		local total = 0
		for _, rack in racks do
			total += rack.hp
		end
		return total / (#racks * 100)
	end

	local function pushState()
		local hp: { number } = {}
		for _, rack in racks do
			table.insert(hp, rack.hp)
		end
		ctx.push({
			racks = hp,
			blocked = blocked,
			leaked = leaked,
			falseBlocks = falseBlocks,
			delivered = delivered,
		})
	end

	for _, rack in racks do
		setBar(rack)
	end
	pushState()

	local run = {} :: Types.MissionRun

	run.tick = function(dt: number)
		if stopped then
			return
		end
		spawnTimer -= dt
		if spawnTimer <= 0 then
			spawnTimer = SPAWN_INTERVAL[difficulty] or 1.7
			spawnPacket()
		end
		local speed = (SPEED[difficulty] or 6) * dt
		for _, packet in table.clone(packets) do
			local step = math.min(speed, packet.remaining)
			packet.part.Position += packet.direction * step
			packet.remaining -= step
			if packet.remaining <= 0.05 then
				local rack = racks[packet.target]
				if packet.malicious then
					leaked += 1
					rack.hp = math.max(0, rack.hp - (DAMAGE[difficulty] or 18))
					setBar(rack)
					burst(packet.part.Position, BAD_COLOR)
				else
					delivered += 1
				end
				removePacket(packet)
			end
		end
		pushTimer -= dt
		if pushTimer <= 0 then
			pushTimer = PUSH_INTERVAL
			pushState()
		end
	end

	run.score = function(): number
		return math.clamp(averageHealth() - FALSE_BLOCK_PENALTY * falseBlocks, 0, 1)
	end

	run.stop = function()
		stopped = true
		packets = {}
		folder:Destroy()
		for _, rack in racks do
			rack.hp = 100
			setBar(rack)
		end
	end

	return run
end

return Mission
