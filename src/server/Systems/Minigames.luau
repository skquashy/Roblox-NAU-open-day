--!strict
-- Мини-игры факультетов. Игрок подходит к пульту лаборатории (ProximityPrompt), клиент показывает выбор
-- сложности, дальше сервер запускает «живую миссию» (src/server/Missions), сам считает результат и выдаёт
-- награду. Клиент только просит начать/отменить и показывает состояние. Правила:
--  * одна лаборатория = один игрок за раз;
--  * сложность 2 открывается после первой победы, 3 после двух побед в этой игре;
--  * первая победа даёт полную награду, повторные 25% (против фарма);
--  * игрок ушёл от лаборатории или вышел: миссия отменяется без награды.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Faculties = require(Shared.Data.Faculties)
local Guard = require(Shared.Util.Guard)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)
local Progress = require(script.Parent.Progress)
local Badges = require(script.Parent.Badges)
local Quests = require(script.Parent.Quests)

local Minigames = {}

type Session = {
	facultyId: string,
	difficulty: number,
	startedAt: number,
	duration: number,
	run: Types.MissionRun,
	room: Model,
	state: { [string]: any },
}

-- Реестр миссий: id факультета -> миссия. Остальные игры добавляются по мере появления материалов.
local registry: { [string]: Types.Mission } = {
	fknt = require(Server.Missions.fknt),
}

local sessions: { [Player]: Session } = {}
local roomOwners: { [string]: Player } = {}
local connected: { [Instance]: boolean } = {}

local function findRoom(facultyId: string): Model?
	for _, instance in CollectionService:GetTagged(Config.ROOM_TAG) do
		if instance:IsA("Model") and instance:GetAttribute("FacultyId") == facultyId then
			return instance
		end
	end
	return nil
end

local function distanceToRoom(player: Player, room: Model): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local floor = room:FindFirstChild("Floor")
	if not floor or not floor:IsA("BasePart") then
		return nil
	end
	return (root.Position - floor.Position).Magnitude
end

local function statOf(profile: Types.Profile, facultyId: string): Types.MinigameStat
	local stat = profile.minigames[facultyId]
	if not stat then
		stat = { best = 0, plays = 0, passes = 0 }
		profile.minigames[facultyId] = stat
	end
	return stat
end

-- Завершение: считаем результат (если не отмена), убираем объекты миссии, выдаём награду.
local function finish(player: Player, cancelled: boolean)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if roomOwners[session.facultyId] == player then
		roomOwners[session.facultyId] = nil
	end
	local score = 0
	if not cancelled then
		score = math.clamp(session.run.score(), 0, 1)
	end
	session.run.stop()
	if cancelled then
		NetServer.fire(player, "MissionState", { facultyId = session.facultyId, ended = true })
		return
	end

	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local stat = statOf(profile, session.facultyId)
	stat.plays += 1
	stat.best = math.max(stat.best, score)
	local passed = score >= Config.PASS_SCORE
	local firstWin = passed and stat.passes == 0
	if passed then
		stat.passes += 1
	end

	-- Награда: сложность увеличивает её, повторные победы дают 25%.
	local multiplier = 1 + 0.25 * (session.difficulty - 1)
	if passed and not firstWin then
		multiplier *= 0.25
	end
	local coins = 0
	local xp = 0
	if passed then
		coins = math.floor(Config.MINIGAME_BASE_COINS * score * multiplier + 0.5)
		xp = math.floor(Config.MINIGAME_BASE_XP * score * multiplier + 0.5)
		Progress.addCoins(player, coins)
		Progress.addXp(player, xp)
		Progress.markExplored(player, session.facultyId)
		Badges.grant(player, "faculty_" .. session.facultyId)
		Quests.report(player, "minigame", session.facultyId)
		Quests.recountMinigames(player)
	end
	PlayerData.markChanged(player)
	NetServer.fire(player, "MissionState", { facultyId = session.facultyId, ended = true })
	NetServer.fire(player, "MissionResult", {
		facultyId = session.facultyId,
		difficulty = session.difficulty,
		score = score,
		passed = passed,
		xp = xp,
		coins = coins,
	})
end

local function start(player: Player, facultyId: string, difficulty: number)
	if sessions[player] then
		return
	end
	local mission = registry[facultyId]
	local room = findRoom(facultyId)
	local profile = PlayerData.get(player)
	if not mission or not room or not profile or not Faculties.byId[facultyId] then
		return
	end
	local radius = room:GetAttribute("Radius")
	local distance = distanceToRoom(player, room)
	if typeof(radius) ~= "number" or not distance or distance > radius then
		NetServer.fire(player, "Toast", "toast.too_far", {})
		return
	end
	local owner = roomOwners[facultyId]
	if owner and owner ~= player and sessions[owner] then
		NetServer.fire(player, "Toast", "toast.room_busy", {})
		return
	end
	if statOf(profile, facultyId).passes < difficulty - 1 then
		NetServer.fire(player, "Toast", "toast.mg_locked", {})
		return
	end

	local duration = mission.duration(difficulty)
	local session: Session = {
		facultyId = facultyId,
		difficulty = difficulty,
		startedAt = os.clock(),
		duration = duration,
		run = nil :: any,
		room = room,
		state = {},
	}
	local context: Types.MissionContext = {
		player = player,
		room = room,
		difficulty = difficulty,
		rng = Random.new(),
		toast = function(key: string, args: { string }?)
			NetServer.fire(player, "Toast", key, args or {})
		end,
		push = function(state: { [string]: any })
			session.state = state
		end,
	}
	local run = mission.start(context)
	if not run then
		return
	end
	session.run = run
	sessions[player] = session
	roomOwners[facultyId] = player
	Progress.markExplored(player, facultyId)
	PlayerData.markChanged(player)
end

-- Подписка на подсказку пульта в каждой лаборатории (и в тех, что появятся позже).
local function hookRoom(room: Instance)
	if connected[room] or not room:IsA("Model") then
		return
	end
	local facultyId = room:GetAttribute("FacultyId")
	local prompt = room:FindFirstChildWhichIsA("ProximityPrompt", true)
	if typeof(facultyId) ~= "string" or not prompt then
		return
	end
	connected[room] = true
	prompt.Triggered:Connect(function(player: Player)
		if not sessions[player] then
			NetServer.fire(player, "MinigamePrompt", facultyId)
		end
	end)
end

function Minigames.init()
	NetServer.on(
		"MinigameStart",
		function(player: Player, rawFaculty: unknown, rawDifficulty: unknown)
			local facultyId = Guard.str(rawFaculty, 20)
			local difficulty = Guard.int(rawDifficulty, 1, 3)
			if facultyId and difficulty then
				start(player, facultyId, difficulty)
			end
		end
	)
	NetServer.on("MinigameCancel", function(player: Player)
		finish(player, true)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		finish(player, true)
	end)
	CollectionService:GetInstanceAddedSignal(Config.ROOM_TAG):Connect(hookRoom)
end

function Minigames.start()
	for _, room in CollectionService:GetTagged(Config.ROOM_TAG) do
		hookRoom(room)
	end
	local pushTimer = 0
	RunService.Heartbeat:Connect(function(dt: number)
		pushTimer -= dt
		local sendState = false
		if pushTimer <= 0 then
			pushTimer = 0.25
			sendState = true
		end
		for player, session in table.clone(sessions) do
			local elapsed = os.clock() - session.startedAt
			local distance = distanceToRoom(player, session.room)
			local radius = session.room:GetAttribute("Radius")
			if
				typeof(radius) == "number"
				and (not distance or distance > radius + Config.ROOM_LEAVE_MARGIN)
			then
				finish(player, true)
			elseif elapsed >= session.duration then
				finish(player, false)
			else
				session.run.tick(dt)
				if sendState then
					local state = table.clone(session.state)
					state.facultyId = session.facultyId
					state.timeLeft = math.max(0, math.ceil(session.duration - elapsed))
					NetServer.fire(player, "MissionState", state)
				end
			end
		end
	end)
end

return Minigames
