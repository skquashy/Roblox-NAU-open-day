--!strict
-- Парк между корпусами 1 и 11 (как на аэрофото: осенние деревья, округлые кусты, дорожки, скамьи):
-- овальная дорожка с перекрёстком вокруг фонтана и клумбы, беседка, скамьи по кругу, фонари,
-- дорожки к площади и к корпусу 11. NPC появятся позже: места для них отмечены невидимыми
-- деталями в папке NpcSpots.

local Build = require(script.Parent.Build)

local Park = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local LOOP_RX = 48 -- полуоси овала дорожки
local LOOP_RZ = 80
local PATH_WIDTH = 6
local PATH_COLOR = Color3.fromRGB(168, 164, 156)
local REGION_HX = 62 -- половина размера парка, в пределах которого растут деревья и кусты
local REGION_HZ = 95
local SEGMENTS = 36
local FOUNTAIN_RADIUS = 11 -- дорожки-перекрёстки заканчиваются на этом расстоянии от центра
local TREE_KEEP_OUT = 9 -- расстояние от дорожек, ближе которого деревья не ставим
local AUTUMN = {
	Color3.fromRGB(226, 178, 52),
	Color3.fromRGB(214, 122, 40),
	Color3.fromRGB(186, 96, 44),
	Color3.fromRGB(108, 150, 64),
	Color3.fromRGB(150, 168, 58),
}
local BUSH = {
	Color3.fromRGB(70, 132, 66),
	Color3.fromRGB(58, 118, 62),
	Color3.fromRGB(84, 146, 72),
}

local function pathSegment(parent: Instance, a: Vector3, b: Vector3)
	local length = (b - a).Magnitude
	if length < 0.5 then
		return
	end
	local middle = (a + b) / 2 + Vector3.new(0, 0.15, 0)
	Build.part(
		parent,
		Vector3.new(PATH_WIDTH, 0.3, length + 0.6),
		CFrame.lookAt(middle, b + Vector3.new(0, 0.15, 0)),
		PATH_COLOR,
		{ name = "Path", material = Enum.Material.Pavement }
	)
end

local function loopPoint(center: Vector3, angle: number, extra: number): Vector3
	return center
		+ Vector3.new(math.cos(angle) * (LOOP_RX + extra), 0, math.sin(angle) * (LOOP_RZ + extra))
end

local function buildFountain(parent: Instance, center: Vector3)
	local stone = Color3.fromRGB(150, 153, 161)
	Build.cylinder(
		parent,
		18,
		2,
		center + Vector3.new(0, 1, 0),
		stone,
		"Y",
		{ name = "FountainBase" }
	)
	local water = Build.cylinder(
		parent,
		15,
		2.2,
		center + Vector3.new(0, 1.1, 0),
		Color3.fromRGB(120, 190, 230),
		"Y",
		{ name = "FountainWater", material = Enum.Material.Glass, transparency = 0.35 }
	)
	water.CanCollide = false
	Build.cylinder(
		parent,
		2.6,
		7,
		center + Vector3.new(0, 3.5, 0),
		stone,
		"Y",
		{ name = "FountainPillar" }
	)
	Build.cylinder(
		parent,
		8,
		1,
		center + Vector3.new(0, 7.2, 0),
		stone,
		"Y",
		{ name = "FountainBowl" }
	)
	local jet =
		Build.ball(parent, 2.4, center + Vector3.new(0, 8.4, 0), Color3.fromRGB(150, 215, 255), {
			name = "FountainJet",
			material = Enum.Material.Neon,
			canCollide = false,
		})
	Build.glow(jet, Color3.fromRGB(150, 215, 255), 0.6, 18)
	-- Клумба кольцом: цвета КАІ (розовый акцент и светло-голубой).
	for i = 0, 15 do
		local angle = i / 16 * math.pi * 2
		local color = Color3.fromRGB(232, 65, 142)
		if i % 2 == 1 then
			color = Color3.fromRGB(158, 223, 255)
		end
		Build.ball(
			parent,
			2,
			center + Vector3.new(math.cos(angle) * 13, 1, math.sin(angle) * 13),
			color,
			{ name = "Flower", canCollide = false }
		)
	end
end

-- Беседка: деревянный пол, четыре столба, двухступенчатая крыша, две скамьи внутри.
local function buildGazebo(parent: Instance, center: Vector3)
	local wood = Color3.fromRGB(170, 130, 90)
	local roof = Color3.fromRGB(126, 72, 60)
	Build.part(
		parent,
		Vector3.new(15, 0.6, 15),
		CFrame.new(center + Vector3.new(0, 0.3, 0)),
		wood,
		{ name = "GazeboFloor", material = Enum.Material.WoodPlanks }
	)
	for _, x in { -6.5, 6.5 } do
		for _, z in { -6.5, 6.5 } do
			Build.part(
				parent,
				Vector3.new(0.9, 9, 0.9),
				CFrame.new(center + Vector3.new(x, 5.1, z)),
				wood,
				{ name = "GazeboPost", material = Enum.Material.Wood }
			)
		end
	end
	Build.part(
		parent,
		Vector3.new(18, 0.8, 18),
		CFrame.new(center + Vector3.new(0, 9.9, 0)),
		roof,
		{ name = "GazeboRoof", material = Enum.Material.Metal }
	)
	Build.part(
		parent,
		Vector3.new(11, 0.8, 11),
		CFrame.new(center + Vector3.new(0, 10.7, 0)),
		roof,
		{ name = "GazeboRoofTop", material = Enum.Material.Metal }
	)
	Build.bench(parent, CFrame.lookAt(center + Vector3.new(0, 0.6, -5), center))
	Build.bench(parent, CFrame.lookAt(center + Vector3.new(0, 0.6, 5), center))
end

-- Строит парк с центром в center. avoid: занятые прямоугольники (киоск), где не растут деревья.
-- Возвращает прямоугольник, который занят парком.
function Park.build(
	parent: Instance,
	center: Vector3,
	connectEast: Vector3,
	connectNorth: Vector3,
	avoid: { Rect }
): Rect
	local folder = Instance.new("Folder")
	folder.Name = "Park"
	folder.Parent = parent

	-- Овальная дорожка и точки на ней (для проверки расстояния до деревьев).
	local pathPoints: { Vector3 } = {}
	for i = 0, SEGMENTS - 1 do
		local a = loopPoint(center, i / SEGMENTS * math.pi * 2, 0)
		local b = loopPoint(center, (i + 1) / SEGMENTS * math.pi * 2, 0)
		pathSegment(folder, a, b)
		table.insert(pathPoints, a)
	end
	-- Перекрёсток: дорожка через парк с запада на восток, обходит фонтан.
	local westEnd = loopPoint(center, math.pi, 0)
	local eastEnd = loopPoint(center, 0, 0)
	local westInner = center + Vector3.new(-FOUNTAIN_RADIUS - 2, 0, 0)
	local eastInner = center + Vector3.new(FOUNTAIN_RADIUS + 2, 0, 0)
	pathSegment(folder, westEnd, westInner)
	pathSegment(folder, eastInner, eastEnd)
	for step = 1, 4 do
		local t = step / 5
		table.insert(pathPoints, westEnd:Lerp(westInner, t))
		table.insert(pathPoints, eastInner:Lerp(eastEnd, t))
	end
	-- Дорожки от овала к площади (юго-восток) и к корпусу 11 (север).
	local south = loopPoint(center, math.pi / 2, 0)
	local southMid = Vector3.new((south.X + connectEast.X) / 2, 0, south.Z + 14)
	pathSegment(folder, south, southMid)
	pathSegment(folder, southMid, connectEast)
	local north = loopPoint(center, -math.pi / 2, 0)
	pathSegment(folder, north, connectNorth)
	for _, point in { south, southMid, connectEast, connectNorth } do
		table.insert(pathPoints, point)
	end

	buildFountain(folder, center)
	buildGazebo(folder, center + Vector3.new(0, 0, -45))

	-- Скамьи по кругу лицом к фонтану, фонари между ними. Их позиции запоминаем: деревья и кусты не должны
	-- вырастать внутри скамьи (скамья 7 студов в длину).
	local furniture: { Vector3 } = {}
	for i = 0, 11 do
		local angle = (i + 0.5) / 12 * math.pi * 2
		local position = loopPoint(center, angle, 6)
		Build.bench(folder, CFrame.lookAt(position, Vector3.new(center.X, 0, center.Z)))
		table.insert(furniture, position)
	end
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2 + math.pi / 6
		local position = loopPoint(center, angle, 4)
		Build.lamp(folder, position)
		table.insert(furniture, position)
	end

	-- Осенние деревья и кусты: случайно, но каждый запуск одинаково.
	local random = Random.new(1933)
	local function isFree(position: Vector3, margin: number): boolean
		for _, point in pathPoints do
			if (Vector3.new(point.X, 0, point.Z) - position).Magnitude < margin then
				return false
			end
		end
		for _, point in furniture do
			if (Vector3.new(point.X, 0, point.Z) - position).Magnitude < margin + 4.5 then
				return false
			end
		end
		for _, rect in avoid do
			if
				math.abs(position.X - rect.x) < rect.hx + 6
				and math.abs(position.Z - rect.z) < rect.hz + 6
			then
				return false
			end
		end
		-- Фонтан и беседка стоят на открытой площадке.
		local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
		if flat.Magnitude < 20 then
			return false
		end
		local gazebo = Vector3.new(position.X - center.X, 0, position.Z - (center.Z - 45))
		return gazebo.Magnitude > 14
	end
	local function scatter(count: number, margin: number, place: (position: Vector3) -> ())
		local placed = 0
		local attempts = 0
		while placed < count and attempts < count * 20 do
			attempts += 1
			local position = Vector3.new(
				center.X + random:NextNumber(-REGION_HX, REGION_HX),
				0,
				center.Z + random:NextNumber(-REGION_HZ, REGION_HZ)
			)
			if isFree(position, margin) then
				place(position)
				placed += 1
			end
		end
	end
	scatter(45, TREE_KEEP_OUT, function(position: Vector3)
		Build.tree(
			folder,
			position,
			random:NextNumber(0.9, 1.3),
			AUTUMN[random:NextInteger(1, #AUTUMN)]
		)
	end)
	scatter(55, 5, function(position: Vector3)
		local size = random:NextNumber(3.5, 6)
		Build.ball(
			folder,
			size,
			position + Vector3.new(0, size / 2 - 0.4, 0),
			BUSH[random:NextInteger(1, #BUSH)],
			{ name = "Bush", material = Enum.Material.Grass }
		)
	end)

	-- Места для будущих NPC: невидимые метки у фонтана и у беседки.
	local spots = Instance.new("Folder")
	spots.Name = "NpcSpots"
	spots.Parent = folder
	local spotOffsets = {
		Vector3.new(-18, 0, 0),
		Vector3.new(18, 0, 0),
		Vector3.new(0, 0, 20),
		Vector3.new(0, 0, -34),
	}
	for index, offset in spotOffsets do
		local spot = Build.part(
			spots,
			Vector3.new(3, 0.2, 3),
			CFrame.new(center + offset + Vector3.new(0, 0.1, 0)),
			Color3.new(1, 1, 1),
			{ name = "NpcSpot_park_" .. tostring(index), transparency = 1, canCollide = false }
		)
		spot:SetAttribute("NpcSpot", "park_" .. tostring(index))
	end

	return { x = center.X, z = center.Z, hx = REGION_HX + 10, hz = REGION_HZ + 10 }
end

return Park
