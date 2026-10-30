--!strict
-- Предмети гравця та магазин косметики. Ціни й каталог беруться ТІЛЬКИ з Shared/Data/Items
-- на сервері; від клієнта приймається лише id предмета.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Items = require(Shared.Data.Items)
local Guard = require(Shared.Util.Guard)

local Server = script.Parent.Parent
local NetServer = require(Server.Lib.NetServer)
local PlayerData = require(script.Parent.PlayerData)
local Preferences = require(script.Parent.Preferences)

local Inventory = {}

function Inventory.has(player: Player, itemId: string): boolean
	local profile = PlayerData.get(player)
	return profile ~= nil and (profile.inventory[itemId] or 0) > 0
end

function Inventory.grant(player: Player, itemId: string, count: number?)
	local item = Items.byId[itemId]
	local profile = PlayerData.get(player)
	if not item or not profile then
		return
	end
	local amount = count or 1
	profile.inventory[itemId] = (profile.inventory[itemId] or 0) + amount
	PlayerData.markChanged(player)
	NetServer.fire(player, "Toast", "toast.item", { "@" .. item.nameKey })
end

function Inventory.init()
	NetServer.on("BuyItem", function(player: Player, raw: unknown)
		local itemId = Guard.str(raw, 40)
		local profile = PlayerData.get(player)
		if not itemId or not profile then
			return
		end
		local item = Items.byId[itemId]
		if not item or item.category ~= "cosmetic" then
			return
		end
		if (profile.inventory[itemId] or 0) > 0 then
			NetServer.fire(player, "Toast", "toast.have_item", {})
			return
		end
		if profile.coins < item.price then
			NetServer.fire(player, "Toast", "toast.no_coins", {})
			return
		end
		profile.coins -= item.price
		profile.inventory[itemId] = 1
		PlayerData.markChanged(player)
		NetServer.fire(player, "Toast", "toast.bought", { "@" .. item.nameKey })
	end)

	NetServer.on("EquipItem", function(player: Player, raw: unknown)
		local profile = PlayerData.get(player)
		if not profile or typeof(raw) ~= "string" then
			return
		end
		if raw == "" then
			profile.hat = ""
			Preferences.refresh(player)
			return
		end
		local item = Items.byId[raw]
		if not item or item.category ~= "cosmetic" or (profile.inventory[raw] or 0) < 1 then
			return
		end
		profile.hat = raw
		Preferences.refresh(player)
	end)
end

return Inventory
