--!strict
-- Парк між корпусами 1 і 11 (як на аерофото: осінні дерева, округлі кущі, доріжки, лави):
-- овальна доріжка з перехрестям навколо фонтану та клумби, альтанка, лави по колу, ліхтарі,
-- доріжки до площі та до корпусу 11. NPC з'являться пізніше: місця для них позначено невидимими
-- деталями в теці NpcSpots.

local Build = require(script.Parent.Build)

local Park = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local LOOP_RX = 48 -- піввісі овалу доріжки
local LOOP_RZ = 80
local PATH_WIDTH = 6
local PATH_COLOR = Color3.fromRGB(168, 164, 156)
local REGION_HX = 62 -- половина розміру парку, в межах якого ростуть дерева й кущі
local REGION_HZ = 95
local SEGMENTS = 36
local FOUNTAIN_RADIUS = 11 -- доріжки-перехрестя закінчуються на цій відстані від центру
local TREE_KEEP_OUT = 9 -- відстань від доріжок, ближче якої дерева не ставимо
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
	-- Клумба кільцем: кольори КАІ (рожевий акцент і світло-блакитний).
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

-- Альтанка: дерев'яна підлога, чотири стовпи, двоступеневий дах, дві лави всередині.
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

-- Будує парк із центром у center. avoid: зайняті прямокутники (кіоск), де не ростуть дерева.
-- Повертає прямокутник, який зайнято парком.
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

	-- Овальна доріжка та точки на ній (для перевірки відстані до дерев).
	local pathPoints: { Vector3 } = {}
	for i = 0, SEGMENTS - 1 do
		local a = loopPoint(center, i / SEGMENTS * math.pi * 2, 0)
		local b = loopPoint(center, (i + 1) / SEGMENTS * math.pi * 2, 0)
		pathSegment(folder, a, b)
		table.insert(pathPoints, a)
	end
	-- Перехрестя: доріжка через парк із заходу на схід, обходить фонтан.
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
	-- Доріжки від овалу до площі (південний схід) і до корпусу 11 (північ).
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

	-- Лави по колу обличчям до фонтану, ліхтарі між ними. Їхні позиції запам'ятовуємо: дерева й кущі не повинні
	-- виростати всередині лави (лава 7 стадів завдовжки).
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

	-- Осінні дерева й кущі: випадково, але кожен запуск однаково.
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
		-- Фонтан і альтанка стоять на відкритому майданчику.
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

	-- Місця для майбутніх NPC: невидимі мітки біля фонтану та біля альтанки.
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
