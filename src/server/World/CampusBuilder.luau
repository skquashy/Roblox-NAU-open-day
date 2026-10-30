--!strict
-- Кампус КАІ кодом: земля, вулиці, площа, будівлі-заготовки (коробки з вікнами та номером корпусу).
-- Корпуси 1, 8 і 11 потім замінюються детальними моделями (World/Buildings/*), решта лишаються блоками.
-- Положення беруться з Shared/Data/Campus (план-схема території).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Build)
local Corpus1 = require(script.Parent.Buildings.Corpus1)
local Corpus8 = require(script.Parent.Buildings.Corpus8)
local Corpus11 = require(script.Parent.Buildings.Corpus11)
local Avenue = require(script.Parent.Avenue)
local Boundary = require(script.Parent.Boundary)
local Skyline = require(script.Parent.Skyline)
local Square = require(script.Parent.Square)

-- Корпуси з детальними моделями; інші будівлі будуються блоками-заготовками.
local DETAILED: { [string]: (Instance, Campus.Placed) -> BasePart } = {
	c1 = Corpus1.build,
	c8 = Corpus8.build,
	c11 = Corpus11.build,
}

local CampusBuilder = {}

export type Anchors = {
	spawn: Vector3,
	center: Vector3, -- центр кампусу: навколо нього будується міська панорама
}

local GROUND_MARGIN = 360
local ASPHALT = Color3.fromRGB(58, 62, 70)
local GRASS = Color3.fromRGB(96, 156, 84)
local WALL = Color3.fromRGB(222, 214, 198)
local ROOF = Color3.fromRGB(110, 114, 122)

local function buildGround(parent: Instance, placed: { Campus.Placed })
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, item in placed do
		minX = math.min(minX, item.x - item.hx)
		maxX = math.max(maxX, item.x + item.hx)
		minZ = math.min(minZ, item.z - item.hz)
		maxZ = math.max(maxZ, item.z + item.hz)
	end
	for _, road in Campus.roads do
		for _, point in { road.a, road.b } do
			local world = Campus.toWorld(point.X, point.Y)
			minX = math.min(minX, world.X)
			maxX = math.max(maxX, world.X)
			minZ = math.min(minZ, world.Z)
			maxZ = math.max(maxZ, world.Z)
		end
	end
	local width = maxX - minX + GROUND_MARGIN * 2
	local depth = maxZ - minZ + GROUND_MARGIN * 2
	Build.part(
		parent,
		Vector3.new(width, 2, depth),
		CFrame.new((minX + maxX) / 2, -1, (minZ + maxZ) / 2),
		GRASS,
		{ name = "Ground", material = Enum.Material.Grass }
	)
end

local function buildRoads(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Roads"
	folder.Parent = parent
	for _, road in Campus.roads do
		if road.id == "guzara" then
			continue -- проспект із розміткою та трамваєм будує Boulevard
		end
		local a = Campus.toWorld(road.a.X, road.a.Y)
		local b = Campus.toWorld(road.b.X, road.b.Y)
		local length = (b - a).Magnitude
		local middle = (a + b) / 2
		Build.part(
			folder,
			Vector3.new(road.width, 0.4, length),
			CFrame.lookAt(middle + Vector3.new(0, 0.2, 0), b + Vector3.new(0, 0.2, 0)),
			ASPHALT,
			{ name = "Road_" .. road.id, material = Enum.Material.Asphalt }
		)
	end
end

local function buildLabel(parent: BasePart, item: Campus.Placed, height: number)
	local number = item.def.number
	if number == nil then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height / 2 + 14, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 260
	gui.Parent = parent
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.3
	text.TextScaled = true
	text.Text = Locale.translate("uk", "building.name", { tostring(number) })
		.. " / "
		.. Locale.translate("en", "building.name", { tostring(number) })
	text.Parent = gui
end

-- Будівля-заготовка: коробка, плаский дах, вікна на стороні входу.
local function buildBlock(parent: Instance, item: Campus.Placed)
	local def = item.def
	local height = def.floors * Campus.FLOOR_HEIGHT
	local model = Instance.new("Model")
	model.Name = "Building_" .. def.id
	model.Parent = parent

	local facing = Vector3.new(item.face.X, 0, item.face.Z)
	local center = Vector3.new(item.x, height / 2, item.z)
	local base = CFrame.lookAt(center, center + facing)
	local body = Build.part(
		model,
		Vector3.new(item.w, height, item.d),
		base,
		def.wall or WALL,
		{ name = "Body", material = Enum.Material.Concrete }
	)
	Build.part(
		model,
		Vector3.new(item.w + 1, 1.2, item.d + 1),
		base * CFrame.new(0, height / 2 + 0.6, 0),
		def.roof or ROOF,
		{ name = "Roof", material = Enum.Material.Metal }
	)
	-- lookAt спрямовує -Z на вхід: передня грань знаходиться в -Z, вікна малюємо на ній.
	local frontFace = base * CFrame.new(0, 0, -item.d / 2)
	local cols = math.max(2, math.floor(item.w / 9))
	Build.facade(model, frontFace, item.w - 4, height - 6, cols, def.floors)
	buildLabel(body, item, height)
end

function CampusBuilder.build(parent: Instance): Anchors
	local placed = Campus.layout()
	buildGround(parent, placed)
	buildRoads(parent)

	local entrance: Campus.Placed? = nil
	for _, item in placed do
		local detailed = DETAILED[item.def.id]
		if detailed then
			local body = detailed(parent, item)
			buildLabel(body, item, item.def.floors * Campus.FLOOR_HEIGHT)
		else
			buildBlock(parent, item)
		end
		if item.def.id == "c1" then
			entrance = item
		end
	end

	-- Площа, пам'ятник-літак і озеленіння.
	local spawn = Square.build(parent, placed, entrance)

	-- Центр кампусу за будівлями та міська панорама навколо нього замість порожнього горизонту.
	local sum = Vector3.zero
	for _, item in placed do
		sum += Vector3.new(item.x, 0, item.z)
	end
	local center = sum / math.max(#placed, 1)
	Skyline.build(parent, center)
	Avenue.build(parent)
	Boundary.build(parent, placed)
	return { spawn = spawn, center = center }
end

return CampusBuilder
