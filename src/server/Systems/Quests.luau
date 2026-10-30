--!strict
-- Квести: сервер сам визначає виконання цілі за подіями (вхід у зону, діалог, результат гри).
-- Клієнт лише показує список.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local QuestData = require(Shared.Data.Quests)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)
local Progress = require(script.Parent.Progress)
local Inventory = require(script.Parent.Inventory)

local Quests = {}

Quests.list = QuestData.list

local function stateFor(profile: Types.Profile, id: string): Types.QuestState
	local state = profile.quests[id]
	if not state then
		state = { progress = 0, done = false }
		profile.quests[id] = state
	end
	return state
end

local function complete(player: Player, def: QuestData.QuestDef)
	NetServer.fire(player, "Toast", "toast.quest_done", { "@" .. def.titleKey })
	Progress.addXp(player, def.xp)
	Progress.addCoins(player, def.coins)
	if def.itemReward then
		Inventory.grant(player, def.itemReward, 1)
	end
end

local function advance(player: Player, def: QuestData.QuestDef, newProgress: number)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local state = stateFor(profile, def.id)
	if state.done or newProgress <= state.progress then
		return
	end
	state.progress = math.min(def.count, newProgress)
	if state.progress >= def.count then
		state.done = true
		PlayerData.markChanged(player)
		complete(player, def)
	else
		PlayerData.markChanged(player)
	end
end

-- Подія "+1" для квестів із конкретною ціллю (talk / collect / visit / minigame / finale).
function Quests.report(player: Player, kind: string, target: string)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	for _, def in QuestData.list do
		if def.kind == kind and (def.target == "" or def.target == target) then
			local state = stateFor(profile, def.id)
			advance(player, def, state.progress + 1)
		end
	end
end

-- Для квестів-лічильників (explore_count, minigame_count): задає абсолютне значення.
function Quests.setCount(player: Player, kind: string, value: number)
	for _, def in QuestData.list do
		if def.kind == kind then
			advance(player, def, value)
		end
	end
end

local function recount(player: Player, profile: Types.Profile)
	Quests.setCount(player, "explore_count", Progress.exploredCount(profile))
	local passed = 0
	for _, stat in profile.minigames do
		if stat.passes > 0 then
			passed += 1
		end
	end
	Quests.setCount(player, "minigame_count", passed)
end

-- Викликається мініграми після успішного проходження.
function Quests.recountMinigames(player: Player)
	local profile = PlayerData.get(player)
	if profile then
		recount(player, profile)
	end
end

function Quests.init()
	Progress.FacultyExplored:connect(function(player: Player, _facultyId: string, count: number)
		Quests.setCount(player, "explore_count", count)
	end)
	PlayerData.Loaded:connect(function(player: Player, profile: Types.Profile)
		recount(player, profile)
	end)
end

return Quests
