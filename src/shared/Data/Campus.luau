--!strict
-- Кампус КАІ за офіційною план-схемою території (ізометрія, зображення 2000x1322,
-- файл reference/campus-plan.webp). Положення будівель задано в ПІКСЕЛЯХ схеми (центр будівлі),
-- у стади переводить Campus.toWorld. Розміри та поверховість приблизні (за схемою та фото);
-- для корпусів 1, 8 і 11 поверховість узято за аерофото та фото (див. docs/PLAN.md).
-- У грі побудовано лише корпуси 1, 8 і 11; інші будівлі схеми не будуються.
-- Гуртожитки в гру не входять. Який факультет у якому корпусі: Data/Buildings.luau.

export type Def = {
	id: string,
	kind: string, -- main | academic | tower | hangar | culture | food | library | medical | sports | stadium
	number: number?, -- номер навчального корпусу за схемою
	px: number,
	py: number,
	w: number, -- ширина фасаду в базових одиницях (у стади множиться на SIZE)
	d: number, -- глибина в базових одиницях
	floors: number,
	face: string?, -- "N" | "S" | "E" | "W"; за замовчуванням вхід дивиться до центру кампусу
	fixed: boolean?, -- не зсувати під час розведення будівель, що перетинаються
	wall: Color3?, -- колір стін (за фото), інакше стандартний
	roof: Color3?, -- колір даху (за фото), інакше стандартний
}

export type Placed = {
	def: Def,
	x: number,
	z: number,
	w: number, -- підсумкові розміри в стадах
	d: number,
	hx: number, -- половина розміру по X з урахуванням повороту
	hz: number,
	face: Vector3,
}

-- Дорога прямим відрізком між двома точками схеми (пікселі); ширина в стадах.
export type Road = {
	id: string,
	a: Vector2,
	b: Vector2,
	width: number,
}

local Campus = {}

-- Вхід гри на кампус іде з боку проспекту Любомира Гузара (південь, +Z).
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
		wall = Color3.fromRGB(214, 205, 188), -- світлий бежево-сірий
		roof = Color3.fromRGB(38, 124, 235), -- яскраво-синій дах корпусу 1
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
		face = "W", -- фасад з літерами КАІ повернуто на 90 градусів ліворуч (на захід),
		wall = Color3.fromRGB(240, 240, 238), -- біла вежа
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
		wall = Color3.fromRGB(226, 214, 188), -- бежево-кремовий
		roof = Color3.fromRGB(128, 132, 138), -- сірий металевий дах залу
	},
} :: { Def }

-- Основні вулиці за схемою (положення оцінено за зображенням, не за геодезією).
Campus.roads = {
	-- Проспект: дві проїжджі частини та трамвайна лінія посередині (див. World/Boulevard).
	{ id = "guzara", a = Vector2.new(383, 1009), b = Vector2.new(2003, 569), width = 62 },
	{ id = "garmatna", a = Vector2.new(850, 480), b = Vector2.new(1030, 790), width = 22 },
	{ id = "nizhynska", a = Vector2.new(640, 500), b = Vector2.new(760, 890), width = 22 },
	{ id = "vidradnyi", a = Vector2.new(560, 390), b = Vector2.new(790, 120), width = 28 },
} :: { Road }

-- Переведення пікселів схеми в стади. Вісь A йде вздовж проспекту Гузара, вісь B - углиб кампусу.
local ORIGIN_X, ORIGIN_Y = 1180, 470
local AX, AY = 0.968, -0.252
local BX, BY = -0.34, -0.94
-- Масштаб під персонажа Roblox (5 стадів = зріст людини): будівлі та відстані збільшено в 2.4 раза.
local SIZE = 2.4
local SCALE_X, SCALE_Z = 0.30 * SIZE, 0.39 * SIZE -- стадів на піксель (вздовж проспекту / углиб, з поправкою на ракурс)
local GAP = 14

Campus.SIZE = SIZE
Campus.FLOOR_HEIGHT = 12 -- стадів на поверх

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

-- Напрямок дороги (від a до b) і нормаль у бік кампусу (на північ, до -Z).
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

-- Точка на осі дороги із заданою світовою координатою X (для доріг, що йдуть уздовж осі X).
function Campus.roadAtX(road: Road, x: number): Vector3
	local a = Campus.toWorld(road.a.X, road.a.Y)
	local direction = Campus.roadFrame(road)
	return a + direction * ((x - a.X) / direction.X)
end

-- Позиції всіх будівель: переведення з пікселів, вибір боку входу, розведення перетинів.
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
