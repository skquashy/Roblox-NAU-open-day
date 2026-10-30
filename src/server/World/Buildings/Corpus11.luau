--!strict
-- Корпус 11 (Ангар): довга чотириповерхова будівля бежево-кремового кольору з рядами вікон, темними
-- вертикальними смугами скління сходів і великим залом на даху з пологим сірим металевим
-- дахом і зеленуватою стрічкою скління. Зовнішній вигляд за аерофото reference/korpus-11/aerial-0m18s.png.
-- Вхід по центру передньої сторони доданий для гри (на фото він не видний).
-- Це лише зовнішня оболонка: інтер'єри поверхів додаються на етапі 4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Theme = require(Shared.Theme)

local Build = require(script.Parent.Parent.Build)
local Facade = require(script.Parent.Facade)

local Corpus11 = {}

local GLASS = Color3.fromRGB(62, 74, 92)
local PIER = Color3.fromRGB(206, 194, 168)
local STAIR_GLASS = Color3.fromRGB(40, 50, 66)
local HALL_WALL = Color3.fromRGB(150, 156, 164)
local HALL_GLASS = Color3.fromRGB(110, 170, 150)
local HALL_ROOF = Color3.fromRGB(128, 132, 138)
local HALL_HEIGHT = 16
local HALL_GLASS_HEIGHT = 5
local SLOPE = math.rad(7)

local function decor(model: Instance, size: Vector3, cframe: CFrame, color: Color3, name: string)
	return Build.part(model, size, cframe, color, { name = name, canCollide = false })
end

-- Вертикальні темні смуги скління сходів: по краях передньої та задньої сторін.
local function buildStairStrips(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	height: number
)
	for _, x in { -width / 2 + 8, width / 2 - 8 } do
		for _, z in { -depth / 2 - 0.4, depth / 2 + 0.4 } do
			decor(
				model,
				Vector3.new(5, height - 2, 0.8),
				origin * CFrame.new(x, height / 2, z),
				STAIR_GLASS,
				"StairStrip"
			)
		end
	end
	for _, x in { -width / 2 - 0.4, width / 2 + 0.4 } do
		decor(
			model,
			Vector3.new(0.8, height - 2, 6),
			origin * CFrame.new(x, height / 2, 0),
			STAIR_GLASS,
			"StairStrip"
		)
	end
end

-- Зал на даху: стіни, стрічка скління вгорі та пологий двосхилий дах.
local function buildHall(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	height: number
)
	local hallWidth = width * 0.8
	local hallDepth = depth * 0.62
	local baseY = height + 1.2
	local topY = baseY + HALL_HEIGHT
	Build.part(
		model,
		Vector3.new(hallWidth, HALL_HEIGHT, hallDepth),
		origin * CFrame.new(0, baseY + HALL_HEIGHT / 2, 0),
		HALL_WALL,
		{ name = "Hall", material = Enum.Material.Metal }
	)
	local bandY = topY - HALL_GLASS_HEIGHT / 2 - 1
	for _, z in { -hallDepth / 2 - 0.1, hallDepth / 2 + 0.1 } do
		Build.part(
			model,
			Vector3.new(hallWidth - 4, HALL_GLASS_HEIGHT, 0.4),
			origin * CFrame.new(0, bandY, z),
			HALL_GLASS,
			{
				name = "HallGlass",
				material = Enum.Material.Glass,
				transparency = 0.35,
				canCollide = false,
			}
		)
	end
	for _, x in { -hallWidth / 2 - 0.1, hallWidth / 2 + 0.1 } do
		Build.part(
			model,
			Vector3.new(0.4, HALL_GLASS_HEIGHT, hallDepth - 4),
			origin * CFrame.new(x, bandY, 0),
			HALL_GLASS,
			{
				name = "HallGlass",
				material = Enum.Material.Glass,
				transparency = 0.35,
				canCollide = false,
			}
		)
	end
	-- Два скати назустріч одне одному, коник уздовж довгого боку.
	local ridge = math.tan(SLOPE) * hallDepth / 2
	local slabLength = hallDepth / 2 / math.cos(SLOPE) + 1
	local slabY = topY + ridge / 2 + 0.6
	Build.part(
		model,
		Vector3.new(hallWidth + 2, 1.2, slabLength),
		origin * CFrame.new(0, slabY, hallDepth / 4) * CFrame.Angles(SLOPE, 0, 0),
		HALL_ROOF,
		{ name = "HallRoof", material = Enum.Material.Metal }
	)
	Build.part(
		model,
		Vector3.new(hallWidth + 2, 1.2, slabLength),
		origin * CFrame.new(0, slabY, -hallDepth / 4) * CFrame.Angles(-SLOPE, 0, 0),
		HALL_ROOF,
		{ name = "HallRoof", material = Enum.Material.Metal }
	)
end

local function buildEntrance(model: Instance, origin: CFrame, depth: number)
	local frontZ = -depth / 2
	decor(
		model,
		Vector3.new(12, 9, 0.6),
		origin * CFrame.new(0, 4.5, frontZ - 0.45),
		Color3.fromRGB(30, 40, 60),
		"Door"
	)
	Build.part(
		model,
		Vector3.new(22, 1, 8),
		origin * CFrame.new(0, 10.5, frontZ - 4),
		Theme.colors.deep,
		{ name = "Canopy" }
	)
	Build.part(
		model,
		Vector3.new(18, 1, 4),
		origin * CFrame.new(0, 0.5, frontZ - 2),
		Color3.fromRGB(190, 190, 195),
		{ name = "Steps", material = Enum.Material.Concrete }
	)
end

-- Вентиляційні короби на пласкій частині даху з обох боків від залу.
local function buildVents(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	height: number
)
	local z = depth / 2 - 2.5
	for i = 0, 3 do
		local x = -width / 2 + 12 + i * (width - 24) / 3
		for _, side in { -z, z } do
			decor(
				model,
				Vector3.new(3, 2, 2),
				origin * CFrame.new(x, height + 2.2, side),
				Color3.fromRGB(170, 174, 182),
				"Vent"
			)
		end
	end
end

-- Будує корпус 11 у позиції item. Повертає тіло будівлі (до нього кріпиться підпис).
function Corpus11.build(parent: Instance, item: Campus.Placed): BasePart
	local height = item.def.floors * Campus.FLOOR_HEIGHT
	local model = Instance.new("Model")
	model.Name = "Building_" .. item.def.id
	model.Parent = parent

	local ground = Vector3.new(item.x, 0, item.z)
	local facing = Vector3.new(item.face.X, 0, item.face.Z)
	local origin = CFrame.lookAt(ground, ground + facing)

	local body = Build.part(
		model,
		Vector3.new(item.w, height, item.d),
		origin * CFrame.new(0, height / 2, 0),
		item.def.wall or PIER,
		{ name = "Body", material = Enum.Material.Concrete }
	)
	Build.part(
		model,
		Vector3.new(item.w + 1, 1.2, item.d + 1),
		origin * CFrame.new(0, height + 0.6, 0),
		item.def.roof or HALL_ROOF,
		{ name = "Roof", material = Enum.Material.Metal }
	)
	Facade.rows(model, origin, item.w, item.d, {
		firstFloor = 1,
		floors = item.def.floors,
		floorHeight = Campus.FLOOR_HEIGHT,
		glass = GLASS,
		pier = PIER,
		columnWidth = 5,
		glassHeight = 6,
	})
	buildStairStrips(model, origin, item.w, item.d, height)
	buildHall(model, origin, item.w, item.d, height)
	buildEntrance(model, origin, item.d)
	buildVents(model, origin, item.w, item.d, height)

	for _, offset in { Vector3.new(-62, 0, -48), Vector3.new(62, 0, -48), Vector3.new(-80, 0, 10) } do
		Build.tree(model, (origin * CFrame.new(offset)).Position, 1.2)
	end
	return body
end

return Corpus11
