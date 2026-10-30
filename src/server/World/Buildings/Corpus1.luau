--!strict
-- Корпус 1 (Центр вступника): довга чотириповерхова будівля вздовж проспекту Любомира Гузара: протяжний
-- корпус із синім скатним дахом, виступний центральний павільйон із колонадою та два задні крила
-- (ліве коротше, праве довше), як на план-схемі reference/campus-plan.webp. Кольори та дах за аерофото
-- reference/korpus-1/aerial-0m21s.png. Форма в плані приблизна: аерофото показує лише частину.
-- Це лише зовнішня оболонка: інтер'єри поверхів додаються на етапі 4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Parent.Build)
local Facade = require(script.Parent.Facade)

local Corpus1 = {}

local GLASS = Color3.fromRGB(72, 88, 112)
local PIER = Color3.fromRGB(226, 218, 200)
local COLUMN = Color3.fromRGB(240, 236, 226)
local WING_WIDTH = 34
local MAIN_DEPTH = 40 -- глибина протяжного корпусу; центральний павільйон глибший на item.d - MAIN_DEPTH
local PAVILION_WIDTH = 52
local LEFT_WING = { offset = 85, length = 44 } -- зсув від центру по локальній осі X (глядач бачить ліворуч)
local RIGHT_WING = { offset = -80, length = 60 }
local SLOPE = math.rad(16)
local GABLE_STEPS = 5

-- Скатний дах: два скати з коником уздовж локальної осі X. cf: центр основи даху.
local function gableRoof(
	model: Instance,
	cf: CFrame,
	length: number,
	span: number,
	color: Color3,
	wallColor: Color3
)
	local ridge = math.tan(SLOPE) * span / 2
	local slabLength = span / 2 / math.cos(SLOPE) + 0.8
	local slabY = ridge / 2 + 0.4
	for _, sign in { 1, -1 } do
		Build.part(
			model,
			Vector3.new(length + 2, 0.8, slabLength),
			cf * CFrame.new(0, slabY, sign * span / 4) * CFrame.Angles(sign * SLOPE, 0, 0),
			color,
			{ name = "Roof", material = Enum.Material.Metal }
		)
	end
	-- Фронтони на торцях сходинками (WedgePart повернути навмання не можна, сходинки надійніші).
	local stepHeight = ridge / GABLE_STEPS
	for _, endSign in { 1, -1 } do
		for i = 0, GABLE_STEPS - 1 do
			Build.part(
				model,
				Vector3.new(0.6, stepHeight, span * (1 - (i + 1) / GABLE_STEPS)),
				cf * CFrame.new(endSign * (length / 2 - 0.3), (i + 0.5) * stepHeight, 0),
				wallColor,
				{ name = "Gable", material = Enum.Material.Concrete }
			)
		end
	end
end

-- Центральний вхід: майданчик, шість колон і антаблемент над ними.
local function buildPortico(model: Instance, origin: CFrame, depth: number)
	local frontZ = -depth / 2
	local columnHeight = 3 * Campus.FLOOR_HEIGHT
	Build.part(
		model,
		Vector3.new(48, 1, 20),
		origin * CFrame.new(0, 0.5, frontZ - 8),
		Color3.fromRGB(190, 190, 195),
		{ name = "PorticoFloor", material = Enum.Material.Concrete }
	)
	for i = 0, 5 do
		local x = -18 + i * 7.2
		Build.cylinder(
			model,
			2.2,
			columnHeight,
			(origin * CFrame.new(x, 1 + columnHeight / 2, frontZ - 13)).Position,
			COLUMN,
			"Y",
			{ name = "Column" }
		)
	end
	Build.part(
		model,
		Vector3.new(46, 3, 18),
		origin * CFrame.new(0, 1 + columnHeight + 1.5, frontZ - 7),
		COLUMN,
		{ name = "Entablature", material = Enum.Material.Concrete }
	)
	Build.part(
		model,
		Vector3.new(12, 12, 0.6),
		origin * CFrame.new(0, 7, frontZ - 0.45),
		Color3.fromRGB(34, 69, 151),
		{ name = "Door", canCollide = false }
	)
end

local function buildWing(
	model: Instance,
	origin: CFrame,
	side: number,
	centerZ: number,
	length: number,
	height: number,
	roofColor: Color3
)
	local wingOrigin = origin * CFrame.new(side, 0, centerZ)
	Build.part(
		model,
		Vector3.new(WING_WIDTH, height, length),
		wingOrigin * CFrame.new(0, height / 2, 0),
		PIER,
		{ name = "Wing", material = Enum.Material.Concrete }
	)
	Facade.rows(model, wingOrigin, WING_WIDTH, length, {
		firstFloor = 1,
		floors = 4,
		floorHeight = Campus.FLOOR_HEIGHT,
		glass = GLASS,
		pier = PIER,
		columnWidth = 6,
		glassHeight = 6,
	})
	-- Коник крила йде вздовж його довжини (вісь Z), тому повертаємо основу даху на 90 градусів.
	gableRoof(
		model,
		wingOrigin * CFrame.new(0, height, 0) * CFrame.Angles(0, math.rad(90), 0),
		length,
		WING_WIDTH,
		roofColor,
		PIER
	)
end

-- Будує корпус 1 у позиції item. Повертає тіло будівлі (до нього кріпиться підпис).
function Corpus1.build(parent: Instance, item: Campus.Placed): BasePart
	local height = item.def.floors * Campus.FLOOR_HEIGHT
	local roofColor = item.def.roof or Color3.fromRGB(38, 124, 235)
	local wallColor = item.def.wall or PIER
	local model = Instance.new("Model")
	model.Name = "Building_" .. item.def.id
	model.Parent = parent

	local ground = Vector3.new(item.x, 0, item.z)
	local facing = Vector3.new(item.face.X, 0, item.face.Z)
	local origin = CFrame.lookAt(ground, ground + facing)
	local windows: Facade.Options = {
		firstFloor = 1,
		floors = item.def.floors,
		floorHeight = Campus.FLOOR_HEIGHT,
		glass = GLASS,
		pier = PIER,
		columnWidth = 6,
		glassHeight = 6,
	}

	-- Протяжний корпус: задня грань на одній лінії з павільйоном, передня відступає.
	local mainZ = item.d / 2 - MAIN_DEPTH / 2
	local mainOrigin = origin * CFrame.new(0, 0, mainZ)
	local body = Build.part(
		model,
		Vector3.new(item.w, height, MAIN_DEPTH),
		mainOrigin * CFrame.new(0, height / 2, 0),
		wallColor,
		{ name = "Body", material = Enum.Material.Concrete }
	)
	Facade.rows(model, mainOrigin, item.w, MAIN_DEPTH, windows)
	gableRoof(
		model,
		mainOrigin * CFrame.new(0, height, 0),
		item.w,
		MAIN_DEPTH,
		roofColor,
		wallColor
	)

	-- Центральний павільйон виступає вперед; його дах перпендикулярний основному.
	Build.part(
		model,
		Vector3.new(PAVILION_WIDTH, height, item.d),
		origin * CFrame.new(0, height / 2, 0),
		wallColor,
		{ name = "Pavilion", material = Enum.Material.Concrete }
	)
	local pavilionWindows = table.clone(windows)
	pavilionWindows.skipBack = true
	Facade.rows(model, origin, PAVILION_WIDTH, item.d, pavilionWindows)
	gableRoof(
		model,
		origin * CFrame.new(0, height, 0) * CFrame.Angles(0, math.rad(90), 0),
		item.d,
		PAVILION_WIDTH,
		roofColor,
		wallColor
	)
	buildPortico(model, origin, item.d)

	local backZ = item.d / 2
	buildWing(
		model,
		origin,
		LEFT_WING.offset,
		backZ + LEFT_WING.length / 2,
		LEFT_WING.length,
		height,
		roofColor
	)
	buildWing(
		model,
		origin,
		RIGHT_WING.offset,
		backZ + RIGHT_WING.length / 2,
		RIGHT_WING.length,
		height,
		roofColor
	)

	for _, offset in
		{
			Vector3.new(-110, 0, -30),
			Vector3.new(110, 0, -30),
			Vector3.new(0, 0, item.d / 2 + 60),
		}
	do
		Build.tree(model, (origin * CFrame.new(offset)).Position, 1.2)
	end
	return body
end

return Corpus1
