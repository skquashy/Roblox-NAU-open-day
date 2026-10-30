--!strict
-- Павільйони з лабораторіями мініігор. Поки інтер'єри корпусів не готові, лабораторія ФКНТ стоїть окремим
-- павільйоном біля алеї до корпусу 8: двері дивляться на алею, від дверей до алеї веде доріжка.
-- Пізніше лабораторії переїдуть усередину корпусів (етап інтер'єрів), а ігри та сервер залишаться тими самими.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Faculties = require(Shared.Data.Faculties)

local Build = require(script.Parent.Parent.Build)
local Fknt = require(script.Parent.Fknt)
local LabRoom = require(script.Parent.LabRoom)

local Pavilions = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local SIZE = Vector3.new(36, 15, 28) -- ширина (вздовж стіни дверей), висота, глибина
local PATH_WIDTH = 8
local PATH_TOP = 0.47 -- трохи вище за алею (0.46)

-- Будує павільйони та повертає зайняті ними області (щоб дерева й меблі не вставали на них).
function Pavilions.build(parent: Instance, placed: { Campus.Placed }): { Rect }
	local rects: { Rect } = {}
	for _, item in placed do
		if item.def.id == "c8" then
			-- Павільйон ФКНТ західніше вежі, двері на схід до алеї корпусу 8. Він зсунутий на південь від кінця алеї,
			-- щоб доріжка від дверей зустрічала алею збоку, а не на її торці.
			local center = Vector3.new(item.x - 95, 0, item.z + 16)
			local facing = Vector3.new(1, 0, 0)
			local origin = CFrame.lookAt(center, center + facing)
			local faculty = Faculties.byId.fknt
			LabRoom.build(parent, origin, "fknt", SIZE, faculty.color, Fknt.dress)
			-- Доріжка від дверей до осі алеї: плитка тієї самої висоти, що в алеї (на 1 см вище, щоб за
			-- перекриття поверхні не блимали), бордюри по краях до самої кромки алеї.
			local doorX = center.X + SIZE.Z / 2
			local alleyX = item.x + item.face.X * (item.hx + 26 + 14)
			local length = math.max(alleyX - doorX, 4)
			Build.part(
				parent,
				Vector3.new(length, 0.5, PATH_WIDTH),
				CFrame.new(doorX + length / 2, PATH_TOP - 0.25, center.Z),
				Color3.fromRGB(158, 160, 166),
				{ name = "LabPath", material = Enum.Material.Pavement }
			)
			local curbLength = length - 4
			for _, side in { -1, 1 } do
				Build.part(
					parent,
					Vector3.new(curbLength, 0.6, 0.6),
					CFrame.new(
						doorX + curbLength / 2,
						PATH_TOP + 0.1 - 0.3,
						center.Z + side * (PATH_WIDTH / 2 - 0.3)
					),
					Color3.fromRGB(206, 208, 212),
					{ name = "LabPathCurb", canCollide = false }
				)
			end
			table.insert(
				rects,
				{ x = center.X, z = center.Z, hx = SIZE.Z / 2 + 6, hz = SIZE.X / 2 + 6 }
			)
			table.insert(
				rects,
				{ x = doorX + length / 2, z = center.Z, hx = length / 2, hz = PATH_WIDTH / 2 + 2 }
			)
		end
	end
	return rects
end

return Pavilions
