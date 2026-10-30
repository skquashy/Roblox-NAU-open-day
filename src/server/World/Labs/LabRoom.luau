--!strict
-- Лабораторія факультету: порожнисте приміщення з дверима, пультом і ProximityPrompt «Грати». Внутрішнє оздоблення
-- задає функція dress (стійки, шлюз тощо для конкретної гри). Модель отримує тег Config.ROOM_TAG та
-- атрибути FacultyId і Radius; серверна система Minigames знаходить її за ними й чіпляє гру на пульт.
-- origin: центр на землі, -Z дивиться на двері. Зараз лабораторії стоять окремими павільйонами, пізніше їх
-- можна перенести всередину корпусів (етап інтер'єрів).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Parent.Build)

local LabRoom = {}

export type Dress = (model: Model, origin: CFrame, size: Vector3) -> ()

local WALL = 0.6
local DOOR_WIDTH = 8
local DOOR_HEIGHT = 9
local INSIDE = Color3.fromRGB(236, 238, 244)
local FLOOR = Color3.fromRGB(196, 200, 210)
local DARK = Color3.fromRGB(46, 50, 60)

local function bilingual(key: string): string
	return Locale.translate("uk", key) .. " / " .. Locale.translate("en", key)
end

-- Будує лабораторію size = (ширина, висота, глибина) і повертає модель.
function LabRoom.build(
	parent: Instance,
	origin: CFrame,
	facultyId: string,
	size: Vector3,
	accent: Color3,
	dress: Dress
): Model
	local model = Instance.new("Model")
	model.Name = "Lab_" .. facultyId
	model.Parent = parent
	local width, height, depth = size.X, size.Y, size.Z
	local frontZ = -depth / 2

	local function put(
		name: string,
		partSize: Vector3,
		offset: CFrame,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, partSize, origin * offset, color, opts)
	end

	-- Підлога, стіни, стеля й дах.
	put("Floor", Vector3.new(width, 0.6, depth), CFrame.new(0, 0.3, 0), FLOOR)
	put(
		"BackWall",
		Vector3.new(width, height, WALL),
		CFrame.new(0, height / 2, depth / 2 - WALL / 2),
		INSIDE
	)
	for _, side in { -1, 1 } do
		put(
			"SideWall",
			Vector3.new(WALL, height, depth),
			CFrame.new(side * (width / 2 - WALL / 2), height / 2, 0),
			INSIDE
		)
	end
	put(
		"Ceiling",
		Vector3.new(width - 2 * WALL, 0.5, depth - 2 * WALL),
		CFrame.new(0, height - 0.25, 0),
		INSIDE
	)
	put("Roof", Vector3.new(width + 1, 0.8, depth + 1), CFrame.new(0, height + 0.4, 0), DARK)
	put(
		"Trim",
		Vector3.new(width + 1.4, 1, depth + 1.4),
		CFrame.new(0, height - 0.6, 0),
		accent,
		{ canCollide = false }
	)

	-- Фасад із дверним отвором.
	local leftWidth = (width - DOOR_WIDTH) / 2
	for _, side in { -1, 1 } do
		put(
			"FrontWall",
			Vector3.new(leftWidth, height, WALL),
			CFrame.new(side * (DOOR_WIDTH / 2 + leftWidth / 2), height / 2, frontZ + WALL / 2),
			INSIDE
		)
	end
	put(
		"Header",
		Vector3.new(DOOR_WIDTH, height - DOOR_HEIGHT, WALL),
		CFrame.new(0, DOOR_HEIGHT + (height - DOOR_HEIGHT) / 2, frontZ + WALL / 2),
		INSIDE
	)
	put(
		"DoorCanopy",
		Vector3.new(DOOR_WIDTH + 3, 0.5, 4),
		CFrame.new(0, DOOR_HEIGHT + 0.3, frontZ - 1.8),
		accent,
		{ canCollide = false }
	)

	-- Вивіска над дверима: абревіатура факультету двома мовами.
	local board =
		put("Sign", Vector3.new(12, 2.6, 0.5), CFrame.new(0, height - 2.4, frontZ - 0.35), DARK)
	Build.text(
		board,
		Enum.NormalId.Front,
		bilingual("fac." .. facultyId .. ".abbr"),
		Color3.new(1, 1, 1),
		nil
	)

	-- Світильники на стелі.
	local lit = 0
	for _, z in { -depth / 4, depth / 4 } do
		for _, x in { -width / 3, 0, width / 3 } do
			local panel = put(
				"CeilingLight",
				Vector3.new(4, 0.15, 1.4),
				CFrame.new(x, height - 0.6, z),
				Color3.fromRGB(255, 248, 232),
				{ material = Enum.Material.Neon, canCollide = false }
			)
			lit += 1
			if lit % 2 == 1 then
				Build.glow(panel, Color3.fromRGB(255, 244, 222), 0.8, 22)
			end
		end
	end

	-- Пульт біля входу з підказкою «Грати».
	local console = put(
		"Console",
		Vector3.new(4.5, 3.2, 2.2),
		CFrame.new(-(width / 2 - 4), 1.6 + 0.6, frontZ + 4.5),
		DARK
	)
	local screen = put(
		"ConsoleScreen",
		Vector3.new(3.8, 1.6, 0.15),
		CFrame.new(-(width / 2 - 4), 3.9, frontZ + 3.4) * CFrame.Angles(math.rad(-20), 0, 0),
		Color3.fromRGB(34, 69, 151),
		{ canCollide = false }
	)
	Build.text(
		screen,
		Enum.NormalId.Front,
		bilingual("mg." .. facultyId .. ".title"),
		Color3.new(1, 1, 1),
		nil
	)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlayPrompt"
	prompt.ActionText = bilingual("ui.play")
	prompt.ObjectText = bilingual("mg." .. facultyId .. ".title")
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = console

	model:SetAttribute("FacultyId", facultyId)
	model:SetAttribute("Radius", math.max(width, depth) / 2 + 6)
	CollectionService:AddTag(model, Config.ROOM_TAG)
	dress(model, origin, size)
	return model
end

return LabRoom
