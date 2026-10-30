--!strict
-- Лесопосадки и рощи на свободных участках кампуса: густые деревья разных оттенков зелени, небольшие
-- осенние акценты, кусты. Не ставятся на здания, дороги, площади и занятые области.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Build)

local Greenery = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

-- Участки: центр и половины размеров в мировых координатах и число деревьев.
local PATCHES = {
	{ x = -170, z = -40, hx = 80, hz = 55, trees = 70 },
	{ x = 300, z = -40, hx = 165, hz = 55, trees = 110 },
	{ x = 410, z = 105, hx = 50, hz = 45, trees = 40 },
	{ x = -60, z = -85, hx = 60, hz = 18, trees = 25 },
}
local GREENS = {
	Color3.fromRGB(56, 126, 62),
	Color3.fromRGB(66, 142, 70),
	Color3.fromRGB(80, 156, 76),
	Color3.fromRGB(46, 108, 58),
	Color3.fromRGB(104, 160, 70),
}
local AUTUMN = {
	Color3.fromRGB(226, 178, 52),
	Color3.fromRGB(214, 122, 40),
}
local MIN_SPACING = 9

local function insideRect(rect: Rect, x: number, z: number, margin: number): boolean
	return math.abs(x - rect.x) < rect.hx + margin and math.abs(z - rect.z) < rect.hz + margin
end

function Greenery.build(parent: Instance, placed: { Campus.Placed }, reserved: { Rect })
	local folder = Instance.new("Folder")
	folder.Name = "Greenery"
	folder.Parent = parent
	local random = Random.new(1100)
	local trees: { Vector3 } = {}

	local function isFree(position: Vector3): boolean
		for _, item in placed do
			if insideRect(item, position.X, position.Z, 35) then
				return false
			end
		end
		for _, rect in reserved do
			if insideRect(rect, position.X, position.Z, 8) then
				return false
			end
		end
		for _, other in trees do
			if (other - position).Magnitude < MIN_SPACING then
				return false
			end
		end
		return true
	end

	for _, patch in PATCHES do
		local count = 0
		local attempts = 0
		while count < patch.trees and attempts < patch.trees * 15 do
			attempts += 1
			local position = Vector3.new(
				patch.x + random:NextNumber(-patch.hx, patch.hx),
				0,
				patch.z + random:NextNumber(-patch.hz, patch.hz)
			)
			if isFree(position) then
				table.insert(trees, position)
				local palette = GREENS
				if random:NextNumber() < 0.08 then
					palette = AUTUMN
				end
				Build.tree(
					folder,
					position,
					random:NextNumber(1, 1.7),
					palette[random:NextInteger(1, #palette)]
				)
				count += 1
				if random:NextNumber() < 0.3 then
					local size = random:NextNumber(3, 5)
					Build.ball(
						folder,
						size,
						position
							+ Vector3.new(
								random:NextNumber(-4, 4),
								size / 2 - 0.4,
								random:NextNumber(-4, 4)
							),
						GREENS[random:NextInteger(1, #GREENS)],
						{ name = "Bush", material = Enum.Material.Grass }
					)
				end
			end
		end
	end
end

return Greenery
