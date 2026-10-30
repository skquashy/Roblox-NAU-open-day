--!strict
-- Отправляет клиенту полный "снимок" состояния для интерфейса.
-- Отправка не чаще ~5 раз в секунду на игрока (изменения копятся).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Faculties = require(Shared.Data.Faculties)
local QuestData = require(Shared.Data.Quests)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)
local Progress = require(script.Parent.Progress)

local Snapshot = {}

local pending: { [Player]: boolean } = {}

local function build(profile: Types.Profile): Types.Snapshot
	local explored: { string } = {}
	for _, faculty in Faculties.list do
		if profile.explored[faculty.id] then
			table.insert(explored, faculty.id)
		end
	end

	local quests: { Types.QuestView } = {}
	for _, def in QuestData.list do
		local state = profile.quests[def.id]
		table.insert(quests, {
			id = def.id,
			progress = state and state.progress or 0,
			target = def.count,
			done = state ~= nil and state.done,
		})
	end

	local badges: { string } = {}
	for id in profile.badges do
		table.insert(badges, id)
	end

	return {
		lang = profile.lang,
		archetype = profile.archetype,
		xp = profile.xp,
		coins = profile.coins,
		explored = explored,
		exploredCount = Progress.exploredCount(profile),
		quests = quests,
		badges = badges,
		inventory = table.clone(profile.inventory),
		hat = profile.hat,
		minigames = table.clone(profile.minigames),
		finaleDone = profile.finaleDone,
	}
end

function Snapshot.init()
	NetServer.on("RequestSnapshot", function(player: Player)
		pending[player] = true
	end)
	PlayerData.Loaded:connect(function(player: Player)
		pending[player] = true
	end)
	PlayerData.Changed:connect(function(player: Player)
		pending[player] = true
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		pending[player] = nil
	end)
end

function Snapshot.start()
	while true do
		task.wait(0.2)
		for player in pending do
			pending[player] = nil
			local profile = PlayerData.get(player)
			if profile then
				NetServer.fire(player, "Snapshot", build(profile))
			end
		end
	end
end

return Snapshot
