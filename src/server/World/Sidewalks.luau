--!strict
-- Тротуары вдоль проспекта Гузара и аллея от тротуара к корпусу 8, вдоль них скамьи, урны и фонари
-- в духе референса reference/campus-style-reference.webp: светлая плитка с бордюром, деревянные скамьи
-- на металлических боковинах. Мебель не ставится на здания, площадь, парк и киоск.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Build)
local Corpus8 = require(script.Parent.Buildings.Corpus8)

local Sidewalks = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local SIDEWALK_WIDTH = 7.5 -- от кромки проезжей части
local ALLEY_WIDTH = 8
local PAVING = Color3.fromRGB(158, 160, 166)
local CURB = Color3.fromRGB(206, 208, 212)
local SIDEWALK_TOP = 0.5
local ALLEY_TOP = 0.46 -- ниже тротуара, чтобы в месте стыка поверхности не совпадали
local FROM_X = -260 -- участок проспекта, вдоль которого строим тротуар
local TO_X = 460
local BENCH_SPACING = 70
local LAMP_SPACING = 45
local FURNITURE_MARGIN = 40

local function strip(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	width: number,
	topY: number,
	color: Color3,
	name: string
)
	local length = (b - a).Magnitude
	local middle = (a + b) / 2
	Build.part(
		parent,
		Vector3.new(width, 0.5, length),
		CFrame.lookAt(
			Vector3.new(middle.X, topY - 0.25, middle.Z),
			Vector3.new(b.X, topY - 0.25, b.Z)
		),
		color,
		{ name = name, material = Enum.Material.Pavement }
	)
end

local function insideRect(rect: Rect, x: number, z: number, margin: number): boolean
	return math.abs(x - rect.x) < rect.hx + margin and math.abs(z - rect.z) < rect.hz + margin
end

local function isFree(placed: { Campus.Placed }, reserved: { Rect }, position: Vector3): boolean
	for _, item in placed do
		if insideRect(item, position.X, position.Z, FURNITURE_MARGIN) then
			return false
		end
	end
	for _, rect in reserved do
		if insideRect(rect, position.X, position.Z, 6) then
			return false
		end
	end
	return true
end

-- Мебель вдоль отрезка a-b с одной стороны (side = -1 или 1). offset: расстояние от оси отрезка.
local function furnish(
	parent: Instance,
	placed: { Campus.Placed },
	reserved: { Rect },
	a: Vector3,
	b: Vector3,
	side: number,
	offset: number
)
	local direction = (b - a).Unit
	local normal = Vector3.new(-direction.Z, 0, direction.X) * side
	local length = (b - a).Magnitude
	local function point(distance: number): Vector3
		return a + direction * distance + normal * offset
	end
	local distance = BENCH_SPACING / 2
	while distance < length do
		local position = point(distance)
		if isFree(placed, reserved, position) then
			-- Скамья смотрит на ось тротуара (сидящий видит проход), урна рядом.
			Build.bench(parent, CFrame.lookAt(position, position - normal))
			Build.bin(parent, point(distance + 6))
		end
		distance += BENCH_SPACING
	end
	distance = LAMP_SPACING / 2
	while distance < length do
		local position = point(distance)
		if isFree(placed, reserved, position) then
			Build.lamp(parent, position, false)
		end
		distance += LAMP_SPACING
	end
end

-- Строит тротуар вдоль проспекта Гузара (северная сторона с мебелью, южная пустая) и аллею к корпусу 8.
function Sidewalks.build(parent: Instance, placed: { Campus.Placed }, reserved: { Rect })
	local folder = Instance.new("Folder")
	folder.Name = "Sidewalks"
	folder.Parent = parent

	local guzara: Campus.Road? = nil
	for _, road in Campus.roads do
		if road.id == "guzara" then
			guzara = road
		end
	end
	if not guzara then
		return
	end
	local roadA = Campus.toWorld(guzara.a.X, guzara.a.Y)
	local roadB = Campus.toWorld(guzara.b.X, guzara.b.Y)
	local direction = (roadB - roadA).Unit
	local normal = Vector3.new(-direction.Z, 0, direction.X) -- на север (в сторону кампуса)
	if normal.Z > 0 then
		normal = -normal
	end
	local function onRoad(x: number): Vector3
		return roadA + direction * ((x - roadA.X) / direction.X)
	end
	local start = onRoad(FROM_X)
	local finish = onRoad(TO_X)
	local sidewalkOffset = guzara.width / 2 + SIDEWALK_WIDTH / 2
	for _, side in { 1, -1 } do
		local a = start + normal * side * sidewalkOffset
		local b = finish + normal * side * sidewalkOffset
		strip(folder, a, b, SIDEWALK_WIDTH, SIDEWALK_TOP, PAVING, "Sidewalk")
		local curbA = start + normal * side * (guzara.width / 2 + 0.3)
		local curbB = finish + normal * side * (guzara.width / 2 + 0.3)
		strip(folder, curbA, curbB, 0.6, SIDEWALK_TOP + 0.1, CURB, "Curb")
	end
	local northA = start + normal * (guzara.width / 2 + SIDEWALK_WIDTH - 1.5)
	local northB = finish + normal * (guzara.width / 2 + SIDEWALK_WIDTH - 1.5)
	-- Мебель стоит ближе к зданиям, у внешней кромки северного тротуара, смотрит на проезжую часть.
	furnish(folder, placed, reserved, northA, northB, 1, 0)

	-- Аллея от тротуара к входу корпуса 8: прямая линия с севера на юг перед подиумом башни.
	for _, item in placed do
		if item.def.id == "c8" then
			local reach = item.hx + Corpus8.PODIUM_FRONT + 14
			local endPoint =
				Vector3.new(item.x + item.face.X * reach, 0, item.z + item.face.Z * reach)
			local sidewalkEdge = onRoad(endPoint.X)
				+ normal * (guzara.width / 2 + SIDEWALK_WIDTH - 0.5)
			local a = Vector3.new(endPoint.X, 0, sidewalkEdge.Z)
			strip(folder, a, endPoint, ALLEY_WIDTH, ALLEY_TOP, PAVING, "Alley")
			for _, edge in { -1, 1 } do
				local direction2 = (endPoint - a).Unit
				local side = Vector3.new(-direction2.Z, 0, direction2.X)
					* edge
					* (ALLEY_WIDTH / 2 - 0.3)
				strip(folder, a + side, endPoint + side, 0.6, ALLEY_TOP + 0.1, CURB, "AlleyCurb")
			end
			-- Мебель по обеим сторонам аллеи, чередуя стороны.
			furnish(folder, placed, reserved, a, endPoint, 1, ALLEY_WIDTH / 2 + 2)
			furnish(folder, placed, reserved, a, endPoint, -1, ALLEY_WIDTH / 2 + 2)
		end
	end
end

return Sidewalks
