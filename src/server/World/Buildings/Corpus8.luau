--!strict
-- Корпус 8: белая башня примерно в 16 этажей с синей надписью «КАІ» на фасаде, внизу невысокий
-- тёмно-розовый подиум, на крыше антенны. Внешний вид по фото reference/korpus-8/facade.jpg.
-- Надпись на фасаде по решению заказчика «КАІ» (кириллица, І украинская), а не «НАУ» как на фото.
-- Это только внешняя оболочка: интерьеры этажей добавляются в этапе 4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Theme = require(Shared.Theme)

local Build = require(script.Parent.Parent.Build)
local Facade = require(script.Parent.Facade)

local Corpus8 = {}

-- Насколько подиум выступает вперёд за башню; по нему аллея и граффити находят стену и вход.
Corpus8.PODIUM_FRONT = 26

local WHITE = Color3.fromRGB(240, 240, 238)
local GLASS = Color3.fromRGB(64, 98, 140)
local PODIUM = Color3.fromRGB(150, 96, 86)
local ROOF = Color3.fromRGB(120, 124, 132)
local PODIUM_FLOORS = 2
local PODIUM_FRONT = Corpus8.PODIUM_FRONT
local PODIUM_SIDE = 22
local PODIUM_BACK = 10

-- Буквы К, А, І: сетка 5x7, X = закрашенная клетка.
local LETTERS: { { string } } = {
	{ "X...X", "X..X.", "X.X..", "XX...", "X.X..", "X..X.", "X...X" },
	{ ".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
	{ ".XXX.", "..X..", "..X..", "..X..", "..X..", "..X..", ".XXX." },
}
local LETTER_GAP = 1.5 -- промежуток между буквами в ширинах клетки
local LETTER_CELL_HEIGHT = 7

local function decor(model: Instance, size: Vector3, cframe: CFrame, color: Color3, name: string)
	return Build.part(model, size, cframe, color, { name = name, canCollide = false })
end

local function buildFacades(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	floors: number
)
	Facade.rows(model, origin, width, depth, {
		firstFloor = PODIUM_FLOORS + 1,
		floors = floors,
		floorHeight = Campus.FLOOR_HEIGHT,
		glass = GLASS,
		pier = WHITE,
		columnWidth = 6,
		glassHeight = 6,
	})
end

-- Синие буквы «КАІ» на передней грани, между 7 и 13 этажами.
local function buildLetters(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	height: number
)
	local columns = 5
	local totalCells = #LETTERS * columns + (#LETTERS - 1) * LETTER_GAP
	local cellWidth = width * 0.82 / totalCells
	local bottom = height * 0.42
	local startX = -(totalCells * cellWidth) / 2
	for letterIndex, rows in LETTERS do
		local letterX = startX + (letterIndex - 1) * (columns + LETTER_GAP) * cellWidth
		for rowIndex, pattern in rows do
			local y = bottom + (#rows - rowIndex + 0.5) * LETTER_CELL_HEIGHT
			local col = 1
			while col <= columns do
				if string.sub(pattern, col, col) == "X" then
					local runEnd = col
					while runEnd < columns and string.sub(pattern, runEnd + 1, runEnd + 1) == "X" do
						runEnd += 1
					end
					local runWidth = (runEnd - col + 1) * cellWidth
					-- Локальная ось X смотрит влево от зрителя перед фасадом: зеркалим, чтобы читалось слева направо.
					local x = -(letterX + (col - 1) * cellWidth + runWidth / 2)
					decor(
						model,
						Vector3.new(runWidth, LETTER_CELL_HEIGHT, 0.9),
						origin * CFrame.new(x, y, -depth / 2 - 0.45),
						Theme.colors.primary,
						"Letter"
					)
					col = runEnd + 1
				else
					col += 1
				end
			end
		end
	end
end

local function buildPodium(model: Instance, origin: CFrame, width: number, depth: number)
	local height = PODIUM_FLOORS * Campus.FLOOR_HEIGHT
	local podiumWidth = width + PODIUM_SIDE * 2
	local podiumDepth = depth + PODIUM_FRONT + PODIUM_BACK
	local centerZ = (PODIUM_BACK - PODIUM_FRONT) / 2
	Build.part(
		model,
		Vector3.new(podiumWidth, height, podiumDepth),
		origin * CFrame.new(0, height / 2, centerZ),
		PODIUM,
		{ name = "Podium", material = Enum.Material.Brick }
	)
	Build.part(
		model,
		Vector3.new(podiumWidth + 1, 1, podiumDepth + 1),
		origin * CFrame.new(0, height + 0.5, centerZ),
		Color3.fromRGB(110, 70, 64),
		{ name = "PodiumRoof" }
	)
	-- Остекление и вход на передней стороне подиума.
	local frontZ = -(depth / 2 + PODIUM_FRONT)
	decor(
		model,
		Vector3.new(podiumWidth - 8, 6, 0.4),
		origin * CFrame.new(0, 7, frontZ - 0.1),
		GLASS,
		"PodiumGlass"
	)
	decor(
		model,
		Vector3.new(10, 9, 0.6),
		origin * CFrame.new(0, 4.5, frontZ - 0.3),
		Color3.fromRGB(30, 40, 60),
		"Door"
	)
	Build.part(
		model,
		Vector3.new(20, 1, 8),
		origin * CFrame.new(0, 11, frontZ - 4),
		Theme.colors.deep,
		{ name = "Canopy" }
	)
end

local function buildRoof(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	height: number
)
	Build.part(
		model,
		Vector3.new(width + 2, 1.5, depth + 2),
		origin * CFrame.new(0, height + 0.75, 0),
		ROOF,
		{ name = "Roof" }
	)
	Build.part(
		model,
		Vector3.new(width * 0.55, 10, depth * 0.6),
		origin * CFrame.new(width * 0.12, height + 6.5, 0),
		WHITE,
		{ name = "RoofHouse" }
	)
	for i = 1, 3 do
		local x = (i - 2) * width * 0.2 - width * 0.1
		local position = (origin * CFrame.new(x, height + 11 + 10, depth * 0.15)).Position
		Build.cylinder(model, 0.6, 20, position, Color3.fromRGB(190, 195, 205), "Y", {
			name = "Antenna",
			canCollide = false,
		})
	end
end

-- Строит корпус 8 в позиции item. Возвращает тело башни (к нему крепится подпись).
function Corpus8.build(parent: Instance, item: Campus.Placed): BasePart
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
		item.def.wall or WHITE,
		{ name = "Body", material = Enum.Material.Concrete }
	)
	buildPodium(model, origin, item.w, item.d)
	buildFacades(model, origin, item.w, item.d, item.def.floors)
	buildLetters(model, origin, item.w, item.d, height)
	buildRoof(model, origin, item.w, item.d, height)

	for _, offset in { Vector3.new(-30, 0, -54), Vector3.new(34, 0, -56), Vector3.new(-84, 0, -20) } do
		Build.tree(model, (origin * CFrame.new(offset)).Position, 1.2)
	end
	return body
end

return Corpus8
