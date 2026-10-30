--!strict
-- XP, монеты, уровни, исследование факультетов.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Faculties = require(Shared.Data.Faculties)
local Progression = require(Shared.Util.Progression)
local Signal = require(Shared.Util.Signal)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)

local Progress = {}

-- FacultyExplored(player, facultyId, exploredCount); LevelUp(player, newLevel)
Progress.FacultyExplored = Signal.new()
Progress.LevelUp = Signal.new()

function Progress.exploredCount(profile: Types.Profile): number
	local count = 0
	for _ in profile.explored do
		count += 1
	end
	return count
end

function Progress.addCoins(player: Player, amount: number)
	local profile = PlayerData.get(player)
	if not profile or amount <= 0 then
		return
	end
	profile.coins += math.floor(amount)
	PlayerData.markChanged(player)
end

function Progress.addXp(player: Player, amount: number)
	local profile = PlayerData.get(player)
	if not profile or amount <= 0 then
		return
	end
	local before = Progression.levelInfo(profile.xp)
	profile.xp += math.floor(amount)
	local after = Progression.levelInfo(profile.xp)
	PlayerData.markChanged(player)
	if after > before then
		NetServer.fire(player, "Toast", "toast.levelup", { tostring(after) })
		Progress.LevelUp:fire(player, after)
	end
end

-- true, если факультет исследован впервые.
function Progress.markExplored(player: Player, facultyId: string): boolean
	if not Faculties.byId[facultyId] then
		return false
	end
	local profile = PlayerData.get(player)
	if not profile or profile.explored[facultyId] then
		return false
	end
	profile.explored[facultyId] = true
	NetServer.fire(player, "Toast", "toast.explored", { "@fac." .. facultyId .. ".name" })
	Progress.addXp(player, Config.EXPLORE_XP)
	Progress.addCoins(player, Config.EXPLORE_COINS)
	PlayerData.markChanged(player)
	Progress.FacultyExplored:fire(player, facultyId, Progress.exploredCount(profile))
	return true
end

return Progress
