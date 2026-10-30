--!strict
-- Бейджи: внутриигровые (всегда) и настоящие бейджи Roblox (если задан ID в Config.ROBLOX_BADGE_IDS).

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Faculties = require(Shared.Data.Faculties)
local BadgeData = require(Shared.Data.Badges)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)
local Progress = require(script.Parent.Progress)

local Badges = {}

function Badges.has(player: Player, badgeId: string): boolean
	local profile = PlayerData.get(player)
	return profile ~= nil and profile.badges[badgeId] == true
end

function Badges.grant(player: Player, badgeId: string)
	local def = BadgeData.byId[badgeId]
	local profile = PlayerData.get(player)
	if not def or not profile or profile.badges[badgeId] then
		return
	end
	profile.badges[badgeId] = true
	PlayerData.markChanged(player)
	NetServer.fire(player, "Toast", "toast.badge", { "@" .. def.nameKey })

	local robloxId = Config.ROBLOX_BADGE_IDS[badgeId]
	if robloxId and robloxId > 0 then
		task.spawn(function()
			local ok, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, robloxId)
			end)
			if not ok then
				warn("[Badges] AwardBadge failed:", err)
			end
		end)
	end
end

function Badges.init()
	Progress.FacultyExplored:connect(function(player: Player, _facultyId: string, count: number)
		Badges.grant(player, "first_steps")
		if count >= #Faculties.list then
			Badges.grant(player, "explorer")
		end
	end)
	Progress.LevelUp:connect(function(player: Player, level: number)
		if level >= 5 then
			Badges.grant(player, "level_5")
		end
	end)
end

return Badges
