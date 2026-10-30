--!strict
-- Кампус КАІ по официальной план-схеме территории (изометрия, картинка 2000x1322,
-- файл reference/campus-plan.webp). Положение зданий задано в ПИКСЕЛЯХ схемы (центр здания),
-- в студы переводит Campus.toWorld. Размеры и этажность приблизительные (по схеме и фото);
-- для корпусов 1, 8 и 11 этажность взята по аэрофото и фото (см. docs/PLAN.md).
-- В игре построены только корпуса 1, 8 и 11; остальные здания схемы не строятся (решение заказчика).
-- Общежития в игру не входят. Какой факультет в каком корпусе: Data/Buildings.luau.

export type Def = {
	id: string,
	kind: string, -- main | academic | tower | hangar | culture | food | library | medical | sports | stadium
	number: number?, -- номер навчального корпусу по схеме
	px: number,
	py: number,
	w: number, -- ширина фасада в базовых единицах (в студы умножается на SIZE)
	d: number, -- глубина в базовых единицах
	floors: number,
	face: string?, -- "N" | "S" | "E" | "W"; по умолчанию вход смотрит к центру кампуса
	fixed: boolean?, -- не сдвигать при разведении пересекающихся зданий
	wall: Color3?, -- цвет стен (по фото), иначе стандартный
	roof: Color3?, -- цвет крыши (по фото), иначе стандартный
}

export type Placed = {
	def: Def,
	x: number,
	z: number,
	w: number, -- итоговые размеры в студах
	d: number,
	hx: number, -- половина размера по X с учётом поворота
	hz: number,
	face: Vector3,
}

-- Дорога прямым отрезком между двумя точками схемы (пиксели); ширина в студах.
export type Road = {
	id: string,
	a: Vector2,
	b: Vector2,
	width: number,
}

local Campus = {}

-- Вход игры на кампус идёт со стороны проспекта Любомира Гузара (юг, +Z).
Campus.list = {
	{
		id = "c1",
		kind = "main",
		number = 1,
		px = 1340,
		py = 610,
		w = 92,
		d = 22,
		floors = 4,
		face = "S",
		fixed = true,
		wall = Color3.fromRGB(214, 205, 188), -- светлый бежево-серый
		roof = Color3.fromRGB(38, 124, 235), -- ярко-синяя крыша корпуса 1
	},
	{
		id = "c8",
		kind = "tower",
		number = 8,
		px = 1650,
		py = 480,
		w = 36,
		d = 18,
		floors = 16,
		face = "W", -- фасад с буквами КАІ повёрнут на 90 градусов влево (на запад), по просьбе заказчика
		wall = Color3.fromRGB(240, 240, 238), -- белая башня
		roof = Color3.fromRGB(120, 124, 132),
	},
	{
		id = "c11",
		kind = "hangar",
		number = 11,
		px = 1180,
		py = 470,
		w = 54,
		d = 26,
		floors = 4,
		face = "S",
		fixed = true,
		wall = Color3.fromRGB(226, 214, 188), -- бежево-кремовый
		roof = Color3.fromRGB(128, 132, 138), -- серая металлическая крыша зала
	},
} :: { Def }

-- Основные улицы по схеме (положение оценено по картинке, не по геодезии).
Campus.roads = {
	-- Проспект: две проезжие части и трамвайная линия посередине (см. World/Boulevard).
	{ id = "guzara", a = Vector2.new(383, 1009), b = Vector2.new(2003, 569), width = 62 },
	{ id = "garmatna", a = Vector2.new(850, 480), b = Vector2.new(1030, 790), width = 22 },
	{ id = "nizhynska", a = Vector2.new(640, 500), b = Vector2.new(760, 890), width = 22 },
	{ id = "vidradnyi", a = Vector2.new(560, 390), b = Vector2.new(790, 120), width = 28 },
} :: { Road }

-- Перевод пикселей схемы в студы. Ось A идёт вдоль проспекта Гузара, ось B - вглубь кампуса.
local ORIGIN_X, ORIGIN_Y = 1180, 470
local AX, AY = 0.968, -0.252
local BX, BY = -0.34, -0.94
-- Масштаб под персонажа Roblox (5 студов = рост человека): здания и расстояния увеличены в 2.4 раза.
local SIZE = 2.4
local SCALE_X, SCALE_Z = 0.30 * SIZE, 0.39 * SIZE -- студов на пиксель (вдоль проспекта / вглубь, с поправкой на ракурс)
local GAP = 14

Campus.SIZE = SIZE
Campus.FLOOR_HEIGHT = 12 -- студов на этаж

local FACES: { [string]: Vector3 } = {
	N = Vector3.new(0, 0, -1),
	S = Vector3.new(0, 0, 1),
	E = Vector3.new(1, 0, 0),
	W = Vector3.new(-1, 0, 0),
}

function Campus.toWorld(px: number, py: number): Vector3
	local dx = px - ORIGIN_X
	local dy = py - ORIGIN_Y
	local det = AX * BY - AY * BX
	local alpha = (dx * BY - dy * BX) / det
	local beta = (AX * dy - AY * dx) / det
	return Vector3.new(alpha * SCALE_X, 0, -beta * SCALE_Z)
end

function Campus.roadById(id: string): Road?
	for _, road in Campus.roads do
		if road.id == id then
			return road
		end
	end
	return nil
end

-- Направление дороги (от a к b) и нормаль в сторону кампуса (на север, к -Z).
function Campus.roadFrame(road: Road): (Vector3, Vector3)
	local a = Campus.toWorld(road.a.X, road.a.Y)
	local b = Campus.toWorld(road.b.X, road.b.Y)
	local direction = (b - a).Unit
	local north = Vector3.new(-direction.Z, 0, direction.X)
	if north.Z > 0 then
		north = -north
	end
	return direction, north
end

-- Точка на оси дороги с заданной мировой координатой X (для дорог, идущих вдоль оси X).
function Campus.roadAtX(road: Road, x: number): Vector3
	local a = Campus.toWorld(road.a.X, road.a.Y)
	local direction = Campus.roadFrame(road)
	return a + direction * ((x - a.X) / direction.X)
end

-- Позиции всех зданий: перевод из пикселей, выбор стороны входа, разведение пересечений.
function Campus.layout(): { Placed }
	local items: { Placed } = {}
	local hubX, hubZ = 0, 0
	for _, def in Campus.list do
		local pos = Campus.toWorld(def.px, def.py)
		if def.id == "c11" then
			hubX, hubZ = pos.X, pos.Z
		end
		table.insert(items, {
			def = def,
			x = pos.X,
			z = pos.Z,
			w = def.w * SIZE,
			d = def.d * SIZE,
			hx = 0,
			hz = 0,
			face = Vector3.zAxis,
		})
	end

	for _, item in items do
		local key = item.def.face
		if key == nil then
			local dx = hubX - item.x
			local dz = hubZ - item.z
			if math.abs(dx) > math.abs(dz) then
				key = "W"
				if dx > 0 then
					key = "E"
				end
			else
				key = "N"
				if dz > 0 then
					key = "S"
				end
			end
		end
		item.face = FACES[key :: string]
		item.hx = item.w / 2
		item.hz = item.d / 2
		if key == "E" or key == "W" then
			item.hx = item.d / 2
			item.hz = item.w / 2
		end
	end

	for _ = 1, 80 do
		local moved = false
		for i = 1, #items do
			for j = i + 1, #items do
				local a, b = items[i], items[j]
				local ox = a.hx + b.hx + GAP - math.abs(a.x - b.x)
				local oz = a.hz + b.hz + GAP - math.abs(a.z - b.z)
				if ox > 0 and oz > 0 then
					moved = true
					local wa, wb = 0.5, 0.5
					if a.def.fixed then
						wa, wb = 0, 1
					elseif b.def.fixed then
						wa, wb = 1, 0
					end
					if ox < oz then
						local dir = 1
						if a.x < b.x then
							dir = -1
						end
						a.x += dir * ox * wa
						b.x -= dir * ox * wb
					else
						local dir = 1
						if a.z < b.z then
							dir = -1
						end
						a.z += dir * oz * wa
						b.z -= dir * oz * wb
					end
				end
			end
		end
		if not moved then
			break
		end
	end
	return items
end

return Campus
