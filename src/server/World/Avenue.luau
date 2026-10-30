--!strict
-- Южная сторона проспекта Гузара за тротуаром (вне барьера, видна с кампуса): ряд жилых домов
-- (магазины с первых этажей убраны). Дома развёрнуты фасадом к проспекту; в плане идут вдоль дороги.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)

local Apartment = require(script.Parent.Buildings.Apartment)

local Avenue = {}

local FROM_X = -300
local TO_X = 520
local SIDEWALK = 7.5
local GAP = 16 -- от тротуара до фасада; барьер стоит у края тротуара, дома за ним
local DEPTH = 36
local PALETTE = {
	Color3.fromRGB(222, 210, 184),
	Color3.fromRGB(205, 214, 224),
	Color3.fromRGB(235, 232, 222),
	Color3.fromRGB(226, 205, 150),
	Color3.fromRGB(200, 150, 128),
	Color3.fromRGB(190, 196, 184),
}

function Avenue.build(parent: Instance)
	local road = Campus.roadById("guzara")
	if not road then
		return
	end
	local _, north = Campus.roadFrame(road)
	local south = -north
	local model = Instance.new("Model")
	model.Name = "Avenue"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = parent

	local random = Random.new(1933)
	local x = FROM_X
	while x < TO_X do
		local width = random:NextNumber(56, 84)
		local floors = random:NextInteger(6, 9)
		local onRoad = Campus.roadAtX(road, x + width / 2)
		local center = onRoad + south * (road.width / 2 + SIDEWALK + GAP + DEPTH / 2)
		local ground = Vector3.new(center.X, 0, center.Z)
		Apartment.build(
			model,
			CFrame.lookAt(ground, ground + north),
			width,
			DEPTH,
			floors,
			{ wall = PALETTE[random:NextInteger(1, #PALETTE)], shops = false, random = random }
		)
		x += width + random:NextNumber(6, 14)
	end
end

return Avenue
