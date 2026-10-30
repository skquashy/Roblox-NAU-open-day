--!strict
-- Павильоны с лабораториями мини-игр. Пока интерьеры корпусов не готовы, лаборатория ФКНТ стоит отдельным
-- павильоном рядом с аллеей к корпусу 8: дверь смотрит на аллею, от двери к аллее ведёт дорожка.
-- Позже лаборатории переедут внутрь корпусов (этап интерьеров), а игры и сервер останутся теми же.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Faculties = require(Shared.Data.Faculties)

local Build = require(script.Parent.Parent.Build)
local Fknt = require(script.Parent.Fknt)
local LabRoom = require(script.Parent.LabRoom)

local Pavilions = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local SIZE = Vector3.new(36, 12, 28) -- ширина (вдоль стены двери), высота, глубина
local PATH_WIDTH = 8

-- Строит павильоны и возвращает занятые ими области (чтобы деревья и мебель не вставали на них).
function Pavilions.build(parent: Instance, placed: { Campus.Placed }): { Rect }
	local rects: { Rect } = {}
	for _, item in placed do
		if item.def.id == "c8" then
			-- Павильон ФКНТ западнее башни, дверь на восток, к аллее корпуса 8.
			local center = Vector3.new(item.x - 95, 0, item.z)
			local facing = Vector3.new(1, 0, 0)
			local origin = CFrame.lookAt(center, center + facing)
			local faculty = Faculties.byId.fknt
			LabRoom.build(parent, origin, "fknt", SIZE, faculty.color, Fknt.dress)
			-- Дорожка от двери до аллеи (аллея в 40 студах от центра павильона).
			local doorX = center.X + SIZE.Z / 2
			local alleyX = item.x + item.face.X * (item.hx + 26 + 14)
			local length = math.max(alleyX - doorX, 4)
			Build.part(
				parent,
				Vector3.new(length, 0.5, PATH_WIDTH),
				CFrame.new(doorX + length / 2, 0.25, center.Z),
				Color3.fromRGB(158, 160, 166),
				{ name = "LabPath", material = Enum.Material.Pavement }
			)
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
