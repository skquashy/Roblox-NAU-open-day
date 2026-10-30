--!strict
-- Площадь перед корпусом 1: мощёная площадка и точка появления, мини-парк, памятник-самолёт Ан-26 на постаменте
-- (справа от входа, как на аэрофото), скамьи, фонари и деревья вдоль улиц.
-- Расстояние от корпуса 1 до проспекта Гузара всего около 69 стопов, поэтому площадь неглубокая.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Build)
local An26 = require(script.Parent.An26)
local Kiosk = require(script.Parent.Kiosk)
local Graffiti = require(script.Parent.Graffiti)
local Park = require(script.Parent.Park)
local Sidewalks = require(script.Parent.Sidewalks)
local Boulevard = require(script.Parent.Boulevard)
local Greenery = require(script.Parent.Greenery)
local Supermarket = require(script.Parent.Buildings.Supermarket)

local Square = {}

local PAVING = Color3.fromRGB(196, 200, 208)
local PLAZA_WIDTH = 120
local PLAZA_DEPTH = 32
local PLAZA_OFFSET = 45 -- от фасада корпуса 1 до центра площади
local MONUMENT_OFFSET_X = 100 -- вправо от оси входа
local MONUMENT_OFFSET_Z = 38
local PLANE_SCALE = 2.2
local TREE_MARGIN = 45 -- расстояние от зданий, ближе которого деревья не ставим
local TREE_SPACING = 60

type Rect = { x: number, z: number, hx: number, hz: number }

local function insideRect(rect: Rect, x: number, z: number, margin: number): boolean
	return math.abs(x - rect.x) < rect.hx + margin and math.abs(z - rect.z) < rect.hz + margin
end

local function buildMonument(parent: Instance, x: number, z: number)
	Build.part(
		parent,
		Vector3.new(46, 2, 46),
		CFrame.new(x, 1, z),
		Color3.fromRGB(160, 163, 171),
		{ material = Enum.Material.Concrete, name = "Step1" }
	)
	Build.part(
		parent,
		Vector3.new(38, 2, 38),
		CFrame.new(x, 3, z),
		Color3.fromRGB(150, 153, 161),
		{ material = Enum.Material.Concrete, name = "Step2" }
	)
	local pedestal = Build.part(
		parent,
		Vector3.new(24, 8, 24),
		CFrame.new(x, 8, z),
		Color3.fromRGB(140, 78, 64),
		{ material = Enum.Material.Brick, name = "Pedestal" }
	)
	Build.text(
		pedestal,
		Enum.NormalId.Back, -- надпись смотрит на площадь и проспект (на юг), а не на здание
		Locale.translate("uk", "monument.plaque"),
		Color3.fromRGB(240, 220, 190),
		nil
	)
	An26.build(
		parent,
		CFrame.new(x, 12 + An26.GROUND_DROP * PLANE_SCALE, z) * CFrame.Angles(0, math.rad(25), 0),
		PLANE_SCALE
	)
	for _, offset in { Vector3.new(-36, 0, 0), Vector3.new(36, 0, 0), Vector3.new(0, 0, -36) } do
		local position = Vector3.new(x + offset.X, 0, z + offset.Z)
		Build.bench(parent, CFrame.lookAt(position, Vector3.new(x, 0, z)))
	end
end

-- Деревья вдоль улиц, не ближе TREE_MARGIN к зданиям и не на площади с памятником.
local function buildTrees(parent: Instance, placed: { Campus.Placed }, reserved: { Rect })
	local folder = Instance.new("Folder")
	folder.Name = "Trees"
	folder.Parent = parent
	for _, road in Campus.roads do
		local a = Campus.toWorld(road.a.X, road.a.Y)
		local b = Campus.toWorld(road.b.X, road.b.Y)
		local direction = (b - a).Unit
		local normal = Vector3.new(-direction.Z, 0, direction.X)
		local length = (b - a).Magnitude
		local distance = 40
		while distance < length - 40 do
			for _, side in { -1, 1 } do
				local jitter = math.sin(distance * 0.37 + side * 1.7)
				local position = a
					+ direction * (distance + jitter * 12)
					+ normal * side * (road.width / 2 + 14)
				local free = true
				for _, item in placed do
					if insideRect(item, position.X, position.Z, TREE_MARGIN) then
						free = false
					end
				end
				for _, rect in reserved do
					if insideRect(rect, position.X, position.Z, 12) then
						free = false
					end
				end
				if free then
					Build.tree(
						folder,
						Vector3.new(position.X, 0, position.Z),
						1.1 + (jitter + 1) * 0.15
					)
				end
			end
			distance += TREE_SPACING
		end
	end
end

-- Строит площадь перед корпусом entrance и возвращает точку появления игроков.
function Square.build(
	parent: Instance,
	placed: { Campus.Placed },
	entrance: Campus.Placed?
): Vector3
	local reserved: { Rect } = {}
	local spawn = Vector3.new(0, 0.5, 120)
	if entrance then
		local plazaZ = entrance.z + entrance.hz + PLAZA_OFFSET
		Build.part(
			parent,
			Vector3.new(PLAZA_WIDTH, 0.5, PLAZA_DEPTH),
			CFrame.new(entrance.x, 0.25, plazaZ),
			PAVING,
			{ name = "Plaza", material = Enum.Material.Pavement }
		)
		spawn = Vector3.new(entrance.x, 0.5, plazaZ)
		for _, dx in { -PLAZA_WIDTH / 2 + 4, PLAZA_WIDTH / 2 - 4 } do
			for _, dz in { -PLAZA_DEPTH / 2 + 3, PLAZA_DEPTH / 2 - 3 } do
				Build.lamp(parent, Vector3.new(entrance.x + dx, 0.5, plazaZ + dz))
			end
		end
		local monumentX = entrance.x + MONUMENT_OFFSET_X
		local monumentZ = entrance.z + entrance.hz + MONUMENT_OFFSET_Z
		buildMonument(parent, monumentX, monumentZ)
		table.insert(
			reserved,
			{ x = entrance.x, z = plazaZ, hx = PLAZA_WIDTH / 2, hz = PLAZA_DEPTH / 2 }
		)
		table.insert(reserved, { x = monumentX, z = monumentZ, hx = 24, hz = 24 })

		-- Мини-парк слева от корпуса 1, между ним и корпусом 11; дорожки ведут к площади и к входу корпуса 11.
		local connectNorth = Vector3.new(entrance.x - 86, 0, entrance.z - 120)
		for _, item in placed do
			if item.def.id == "c11" then
				connectNorth = Vector3.new(item.x - 12, 0, item.z + item.hz + 18)
			end
		end
		-- Киоск «Кулиничі» у юго-западного угла площади, фасад смотрит на юг, к дорожке парка.
		local kioskPosition = Vector3.new(entrance.x - 126, 0, entrance.z + 57)
		local kioskRect =
			Kiosk.build(parent, CFrame.lookAt(kioskPosition, kioskPosition + Vector3.new(0, 0, 1)))
		table.insert(reserved, kioskRect)

		local parkCenter = Vector3.new(entrance.x - 184, 0, entrance.z - 13)
		local connectEast = Vector3.new(entrance.x - PLAZA_WIDTH / 2, 0, plazaZ)
		table.insert(
			reserved,
			Park.build(parent, parkCenter, connectEast, connectNorth, { kioskRect })
		)
	end
	local stopX = 74
	if entrance then
		stopX = entrance.x
	end
	local stopRect = Boulevard.build(parent, stopX)
	if stopRect then
		table.insert(reserved, stopRect)
	end

	-- Супермаркет «Фора» к востоку от корпуса 8: фасад на проспект, площадка перед входом и парковка западнее.
	for _, item in placed do
		if item.def.id == "c8" then
			local storeX, storeZ = item.x + 116, item.z + 75
			local forecourtZ = storeZ + 20 + 15.5
			Supermarket.build(
				parent,
				CFrame.lookAt(Vector3.new(storeX, 0, storeZ), Vector3.new(storeX, 0, storeZ + 1)),
				56,
				40
			)
			Build.part(
				parent,
				Vector3.new(56, 0.5, 31),
				CFrame.new(storeX, 0.25, forecourtZ),
				PAVING,
				{ name = "Forecourt", material = Enum.Material.Pavement }
			)
			Supermarket.buildLot(parent, Vector3.new(item.x + 58, 0, item.z + 77), 46, 95)
			table.insert(reserved, { x = storeX, z = storeZ + 18, hx = 30, hz = 33 })
			table.insert(reserved, { x = item.x + 58, z = item.z + 77, hx = 24, hz = 49 })
		end
	end
	Sidewalks.build(parent, placed, reserved)
	Graffiti.build(parent, placed)
	Greenery.build(parent, placed, reserved)
	buildTrees(parent, placed, reserved)
	return spawn
end

return Square
