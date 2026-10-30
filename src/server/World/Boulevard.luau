--!strict
-- Проспект Гузара: две проезжие части (по две полосы), посередине трамвайные пути с платформами и
-- павильонами остановки, разметка (пунктир, сплошные кромки, пешеходный переход), трамвай, автобус и машины.
-- Поперечный разрез проспекта, t от оси к северу (к кампусу):
--   31..14.6 проезжая часть | 14.6..9.6 платформа/газон | 9.6..-9.6 трамвайные пути | зеркально на юг.
-- Всё строится вдоль оси дороги (s) и поперёк (t), поэтому подходит для дороги под лёгким углом к оси X.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Build)
local Vehicles = require(script.Parent.Vehicles)

local Boulevard = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local FROM_X = -280
local TO_X = 490
local PLATFORM_LENGTH = 90
local CAR_TOP = 0.4 -- верх асфальта
local ASPHALT = Color3.fromRGB(58, 62, 70)
local PAINT = Color3.fromRGB(236, 238, 240)
local YELLOW = Color3.fromRGB(240, 200, 40)
local PLATFORM = Color3.fromRGB(196, 198, 204)
local GRASS = Color3.fromRGB(96, 156, 84)
local BLUE = Color3.fromRGB(34, 69, 151)
local DARK = Color3.fromRGB(44, 48, 56)
local STEEL = Color3.fromRGB(170, 174, 182)

-- Положение на дороге: s вдоль оси, t поперёк (плюс к северу).
type Frame = { origin: Vector3, direction: Vector3, north: Vector3 }

local function pointAt(frame: Frame, s: number, t: number, y: number): Vector3
	local p = frame.origin + frame.direction * s + frame.north * t
	return Vector3.new(p.X, y, p.Z)
end

-- Полоса: s от s0 до s1, t от t0 до t1, верхняя поверхность на высоте topY.
local function strip(
	parent: Instance,
	frame: Frame,
	s0: number,
	s1: number,
	t0: number,
	t1: number,
	topY: number,
	thickness: number,
	color: Color3,
	name: string,
	material: Enum.Material?
): Part
	local center = pointAt(frame, (s0 + s1) / 2, (t0 + t1) / 2, topY - thickness / 2)
	local forward = center + frame.direction
	return Build.part(
		parent,
		Vector3.new(math.abs(t1 - t0), thickness, math.abs(s1 - s0)),
		CFrame.lookAt(center, Vector3.new(forward.X, center.Y, forward.Z)),
		color,
		{ name = name, material = material, canCollide = false }
	)
end

local function paint(
	parent: Instance,
	frame: Frame,
	s0: number,
	s1: number,
	t0: number,
	t1: number,
	color: Color3
)
	strip(
		parent,
		frame,
		s0,
		s1,
		t0,
		t1,
		CAR_TOP + 0.06,
		0.05,
		color,
		"Marking",
		Enum.Material.SmoothPlastic
	)
end

-- Остановка: навес над платформой. t0 - середина платформы, side = 1 (север) или -1 (юг).
local function canopy(
	parent: Instance,
	frame: Frame,
	s: number,
	t0: number,
	side: number,
	length: number
)
	local function place(
		name: string,
		across: number,
		height: number,
		along: number,
		offsetS: number,
		offsetT: number,
		y: number,
		color: Color3,
		options: Build.Options?
	)
		local center = pointAt(frame, s + offsetS, t0 + offsetT, y)
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(
			parent,
			Vector3.new(across, height, along),
			CFrame.lookAt(
				center,
				Vector3.new(center.X + frame.direction.X, center.Y, center.Z + frame.direction.Z)
			),
			color,
			opts
		)
	end
	-- Крыша, столбы через каждые 9 студов, стеклянная стенка со стороны проезжей части.
	place("Roof", 5, 0.5, length, 0, 0, 9, BLUE, nil)
	local posts = math.floor(length / 9)
	for i = 0, posts do
		local offset = -length / 2 + i * length / posts
		for _, across in { -2, 2 } do
			place(
				"Post",
				0.4,
				8.5,
				0.4,
				offset,
				across,
				4.85,
				DARK,
				{ material = Enum.Material.Metal }
			)
		end
	end
	place(
		"BackGlass",
		0.15,
		5.5,
		length,
		0,
		side * 2.3,
		3.9,
		Color3.fromRGB(160, 200, 225),
		{ material = Enum.Material.Glass, transparency = 0.6, canCollide = false }
	)
	-- Лавки под навесом лицом к трамваю и урны по краям.
	local faceTo = -side
	for i = 0, 2 do
		local offset = -length / 2 + length * (i + 0.5) / 3
		local position = pointAt(frame, s + offset, t0 - side * 0.3, 0.6)
		local looking = position + frame.north * faceTo
		Build.bench(parent, CFrame.lookAt(position, Vector3.new(looking.X, position.Y, looking.Z)))
	end
	for _, offset in { -length / 2 + 1.5, length / 2 - 1.5 } do
		Build.bin(parent, pointAt(frame, s + offset, t0 + side * 1.4, 0.6))
	end
end

-- Контактная сеть: столбы на газоне между путями и проезжими частями, консоли над путями, контактный провод
-- на высоте токоприёмника трамвая и несущий провод выше с подвесами. Вдоль платформы столбов нет
-- (там навесы), провода там просто натянуты между столбами по краям остановки.
local WIRE_HEIGHT = 16.3 -- верх токоприёмника трамвая стоит на 16.2
local MESSENGER_HEIGHT = 18
local POLE_SPACING = 36

local function wire(
	parent: Instance,
	frame: Frame,
	length: number,
	t: number,
	y: number,
	thickness: number,
	name: string
)
	local center = pointAt(frame, length / 2, t, y)
	Build.part(
		parent,
		Vector3.new(thickness, thickness, length),
		CFrame.lookAt(
			center,
			Vector3.new(center.X + frame.direction.X, y, center.Z + frame.direction.Z)
		),
		Color3.fromRGB(60, 62, 66),
		{ name = name, canCollide = false }
	)
end

local function overhead(
	parent: Instance,
	frame: Frame,
	length: number,
	stopS: number,
	platformHalf: number
)
	local folder = Instance.new("Folder")
	folder.Name = "Overhead"
	folder.Parent = parent
	for _, track in { 4.6, -4.6 } do
		wire(folder, frame, length, track, WIRE_HEIGHT, 0.14, "ContactWire")
		wire(folder, frame, length, track, MESSENGER_HEIGHT, 0.1, "MessengerWire")
	end
	local steel = Color3.fromRGB(96, 100, 108)
	local index = 0
	local s = 20
	while s < length - 20 do
		index += 1
		-- Столбы по очереди на северной и южной стороне, каждый держит ближайший путь.
		local side = 1
		if index % 2 == 0 then
			side = -1
		end
		if math.abs(s - stopS) > platformHalf + 6 then
			local poleT = side * 12.1
			local base = pointAt(frame, s, poleT, 0)
			Build.cylinder(
				folder,
				0.6,
				19,
				base + Vector3.new(0, 9.5, 0),
				steel,
				"Y",
				{ name = "Pole" }
			)
			-- Консоль над путём и подвес контактного провода.
			local armT = (poleT + side * 4.6) / 2
			local arm = pointAt(frame, s, armT, MESSENGER_HEIGHT + 0.4)
			Build.part(
				folder,
				Vector3.new(7.8, 0.25, 0.25),
				CFrame.lookAt(
					arm,
					Vector3.new(arm.X + frame.direction.X, arm.Y, arm.Z + frame.direction.Z)
				),
				steel,
				{ name = "Arm", canCollide = false }
			)
			local hanger = pointAt(frame, s, side * 4.6, (WIRE_HEIGHT + MESSENGER_HEIGHT) / 2)
			Build.part(
				folder,
				Vector3.new(0.1, MESSENGER_HEIGHT - WIRE_HEIGHT, 0.1),
				CFrame.new(hanger),
				steel,
				{ name = "Hanger", canCollide = false }
			)
		end
		s += POLE_SPACING
	end
end

-- Строит проспект; остановка и переход в точке stopX (мировая X, перед корпусом 1). Возвращает область остановки (для запрета мебели и деревьев).
function Boulevard.build(parent: Instance, stopX: number): Rect?
	local road = Campus.roadById("guzara")
	if not road then
		return nil
	end
	local direction, north = Campus.roadFrame(road)
	local origin = Campus.roadAtX(road, FROM_X)
	local frame: Frame = { origin = origin, direction = direction, north = north }
	local length = (TO_X - FROM_X) / direction.X
	local stopS = (stopX - FROM_X) / direction.X

	local folder = Instance.new("Folder")
	folder.Name = "Boulevard"
	folder.Parent = parent

	-- Асфальт двух проезжих частей и трамвайная насыпь.
	for _, side in { 1, -1 } do
		strip(
			folder,
			frame,
			0,
			length,
			side * 14.6,
			side * 31,
			CAR_TOP,
			0.4,
			ASPHALT,
			"Asphalt",
			Enum.Material.Asphalt
		)
		strip(
			folder,
			frame,
			0,
			length,
			side * 9.6,
			side * 14.6,
			CAR_TOP + 0.05,
			0.4,
			GRASS,
			"MedianGrass",
			Enum.Material.Grass
		)
	end
	strip(
		folder,
		frame,
		0,
		length,
		-9.6,
		9.6,
		CAR_TOP + 0.1,
		0.4,
		Color3.fromRGB(94, 88, 82),
		"TramBed",
		Enum.Material.Pebble
	)

	-- Рельсы двух путей, расстояние между рельсами 3.2.
	for _, track in { 4.6, -4.6 } do
		for _, rail in { -1.6, 1.6 } do
			strip(
				folder,
				frame,
				0,
				length,
				track + rail - 0.2,
				track + rail + 0.2,
				CAR_TOP + 0.4,
				0.3,
				STEEL,
				"Rail",
				Enum.Material.Metal
			)
		end
	end

	-- Разметка: пунктир по оси полос, сплошные линии вдоль бордюров.
	for _, side in { 1, -1 } do
		local laneCenter = side * 22.8
		local s = 0
		while s < length do
			paint(
				folder,
				frame,
				s,
				math.min(s + 5, length),
				laneCenter - 0.15,
				laneCenter + 0.15,
				PAINT
			)
			s += 12
		end
		paint(folder, frame, 0, length, side * 30.4 - 0.15, side * 30.4 + 0.15, PAINT)
		paint(folder, frame, 0, length, side * 15.2 - 0.15, side * 15.2 + 0.15, PAINT)
	end

	-- Пешеходный переход через оба проезда и путь, рядом с остановкой.
	local crossS = stopS
	for _, side in { 1, -1 } do
		for i = 0, 5 do
			local t = side * (15.6 + i * 2.5)
			paint(folder, frame, crossS - 3, crossS + 3, t, t + side * 1.3, PAINT)
		end
	end
	strip(
		folder,
		frame,
		crossS - 3,
		crossS + 3,
		-9.6,
		9.6,
		CAR_TOP + 0.2,
		0.3,
		PLATFORM,
		"TramCrossing",
		Enum.Material.Pavement
	)
	-- Стоп-линии перед переходом.
	for _, side in { 1, -1 } do
		paint(folder, frame, crossS - 9, crossS - 8, side * 15.6, side * 22, PAINT)
		paint(folder, frame, crossS + 8, crossS + 9, side * 23, side * 30, PAINT)
	end

	-- Платформы по обе стороны путей с жёлтой кромкой и навесами.
	local half = PLATFORM_LENGTH / 2
	for _, side in { 1, -1 } do
		strip(
			folder,
			frame,
			stopS - half,
			stopS + half,
			side * 9.6,
			side * 14.6,
			0.6,
			0.3,
			PLATFORM,
			"Platform",
			Enum.Material.Pavement
		)
		strip(
			folder,
			frame,
			stopS - half,
			stopS + half,
			side * 9.6,
			side * 10.3,
			0.65,
			0.1,
			YELLOW,
			"PlatformEdge",
			Enum.Material.SmoothPlastic
		)
	end
	canopy(folder, frame, stopS - 22, 12.1, 1, 34)
	canopy(folder, frame, stopS + 22, -12.1, -1, 34)

	-- Трамвай на северном пути, автобус и несколько машин в потоке (все стоят).
	local function onRoad(s: number, t: number, y: number): CFrame
		local position = pointAt(frame, s, t, y)
		return CFrame.lookAt(position, position + frame.direction)
	end
	Vehicles.tram(folder, onRoad(stopS, 4.6, 0.8))
	overhead(folder, frame, length, stopS, half)
	Vehicles.bus(folder, onRoad(stopS - 70, 27, CAR_TOP))
	local random = Random.new(401)
	local carSlots =
		{ { -150, 18.5 }, { -110, 27 }, { -60, -18.5 }, { 120, -27 }, { 40, 18.5 }, { 170, 27 } }
	for _, slot in carSlots do
		local color = Vehicles.carColors[random:NextInteger(1, #Vehicles.carColors)]
		local t = slot[2]
		local cf = onRoad(stopS + slot[1], t, CAR_TOP)
		if t < 0 then
			cf = cf * CFrame.Angles(0, math.pi, 0) -- встречная полоса: машины едут в другую сторону
		end
		Vehicles.car(folder, cf, color)
	end

	-- Название остановки на южной платформе.
	local signPosition = pointAt(frame, stopS + 40, -13, 0.6)
	Build.cylinder(
		folder,
		0.35,
		11,
		signPosition + Vector3.new(0, 5.5, 0),
		DARK,
		"Y",
		{ name = "SignPole" }
	)
	local plate = Build.part(
		folder,
		Vector3.new(3.6, 3.6, 0.3),
		CFrame.lookAt(
			signPosition + Vector3.new(0, 10, 0),
			signPosition + Vector3.new(0, 10, 0) + frame.north
		),
		BLUE,
		{ name = "SignPlate", canCollide = false }
	)
	Build.text(
		plate,
		Enum.NormalId.Front,
		Locale.translate("uk", "tram.sign"),
		Color3.new(1, 1, 1),
		nil
	)
	local board = Build.part(
		folder,
		Vector3.new(6, 1.4, 0.2),
		CFrame.lookAt(
			signPosition + Vector3.new(0, 7.6, 0),
			signPosition + Vector3.new(0, 7.6, 0) + frame.north
		),
		Color3.fromRGB(240, 242, 245),
		{ name = "NameBoard", canCollide = false }
	)
	Build.text(
		board,
		Enum.NormalId.Front,
		Locale.translate("uk", "tram.stop") .. " / " .. Locale.translate("en", "tram.stop"),
		DARK,
		nil
	)

	local center = pointAt(frame, stopS, 0, 0)
	return { x = center.X, z = center.Z, hx = half + 4, hz = 37 }
end

return Boulevard
