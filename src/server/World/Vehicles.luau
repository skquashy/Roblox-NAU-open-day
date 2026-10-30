--!strict
-- Неподвижные машины для декора: легковая, автобус и трамвай. cframe: центр на земле, -Z смотрит вперёд.
-- Это статичные модели: они нигде не едут. Номерных знаков и реальных марок нет.

local Build = require(script.Parent.Build)

local Vehicles = {}

local DARK = Color3.fromRGB(34, 38, 46)
local GLASS = Color3.fromRGB(40, 56, 76)
local STEEL = Color3.fromRGB(170, 174, 182)
local HEADLIGHT = Color3.fromRGB(255, 244, 214)
local TAILLIGHT = Color3.fromRGB(200, 40, 40)

local CAR_COLORS = {
	Color3.fromRGB(214, 60, 60),
	Color3.fromRGB(60, 100, 190),
	Color3.fromRGB(235, 235, 232),
	Color3.fromRGB(40, 44, 52),
	Color3.fromRGB(190, 192, 198),
	Color3.fromRGB(70, 140, 90),
	Color3.fromRGB(230, 190, 60),
}
Vehicles.carColors = CAR_COLORS

local function maker(model: Model, cframe: CFrame)
	return function(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, size, cframe * offset, color, opts)
	end
end

-- Колесо: цилиндр, ось которого направлена поперёк машины (локальная ось X), поэтому берём полный cframe
-- машины, а не только позицию: иначе у машин, стоящих вдоль дороги, колёса оказывались бы повёрнуты боком.
local function wheel(
	model: Model,
	cframe: CFrame,
	x: number,
	y: number,
	z: number,
	diameter: number
)
	Build.part(model, Vector3.new(1, diameter, diameter), cframe * CFrame.new(x, y, z), DARK, {
		name = "Wheel",
		shape = Enum.PartType.Cylinder,
		canCollide = false,
	})
end

-- Легковая машина: кузов, салон со стёклами, фары, колёса.
function Vehicles.car(parent: Instance, cframe: CFrame, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = parent
	local part = maker(model, cframe)
	part(
		"Body",
		Vector3.new(5.4, 1.8, 12.5),
		CFrame.new(0, 2, 0),
		color,
		{ material = Enum.Material.Metal }
	)
	part(
		"Cabin",
		Vector3.new(4.6, 1.7, 6.4),
		CFrame.new(0, 3.65, 0.6),
		color,
		{ material = Enum.Material.Metal }
	)
	part(
		"Windows",
		Vector3.new(4.7, 1.2, 5.6),
		CFrame.new(0, 3.7, 0.6),
		GLASS,
		{ material = Enum.Material.Glass, transparency = 0.2, canCollide = false }
	)
	part("Bumper", Vector3.new(5.5, 0.8, 12.6), CFrame.new(0, 1.1, 0), DARK, { canCollide = false })
	for _, x in { -1.9, 1.9 } do
		part(
			"Headlight",
			Vector3.new(1, 0.6, 0.15),
			CFrame.new(x, 2.3, -6.3),
			HEADLIGHT,
			{ material = Enum.Material.Neon, canCollide = false }
		)
		part(
			"Taillight",
			Vector3.new(1, 0.6, 0.15),
			CFrame.new(x, 2.3, 6.3),
			TAILLIGHT,
			{ canCollide = false }
		)
	end
	for _, x in { -2.5, 2.5 } do
		for _, z in { -4, 4 } do
			wheel(model, cframe, x, 1.2, z, 2.4)
		end
	end
	return model
end

-- Автобус: жёлтый кузов, лента окон, двери, фары.
function Vehicles.bus(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Bus"
	model.Parent = parent
	local part = maker(model, cframe)
	local yellow = Color3.fromRGB(240, 200, 40)
	part(
		"Body",
		Vector3.new(7.4, 7.6, 30),
		CFrame.new(0, 5.2, 0),
		yellow,
		{ material = Enum.Material.Metal }
	)
	part("Roof", Vector3.new(6.8, 0.6, 29), CFrame.new(0, 9.3, 0), Color3.fromRGB(220, 222, 226))
	part("Skirt", Vector3.new(7.5, 1, 30), CFrame.new(0, 1.6, 0), DARK, { canCollide = false })
	for _, side in { -1, 1 } do
		part(
			"Windows",
			Vector3.new(0.2, 2.6, 26),
			CFrame.new(side * 3.75, 6.6, 0),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.2, canCollide = false }
		)
		for _, z in { -9, 6 } do
			part(
				"Door",
				Vector3.new(0.25, 5.2, 3),
				CFrame.new(side * 3.8, 4.6, z),
				Color3.fromRGB(60, 64, 72),
				{ canCollide = false }
			)
		end
	end
	for _, end_ in { -1, 1 } do
		part(
			"Windshield",
			Vector3.new(6.2, 3, 0.2),
			CFrame.new(0, 7, end_ * 15.05),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.2, canCollide = false }
		)
		for _, x in { -2.6, 2.6 } do
			part(
				"Light",
				Vector3.new(1, 0.7, 0.2),
				CFrame.new(x, 3, end_ * 15.05),
				end_ < 0 and HEADLIGHT or TAILLIGHT,
				{ material = Enum.Material.Neon, canCollide = false }
			)
		end
	end
	for _, x in { -3.2, 3.2 } do
		for _, z in { -9, 9 } do
			wheel(model, cframe, x, 1.6, z, 3.2)
		end
	end
	return model
end

-- Трамвай: длина 52, ширина 9, бело-синий, с пантографом.
function Vehicles.tram(parent: Instance, cframe: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "Tram"
	model.Parent = parent
	local part = maker(model, cframe)
	local body = Color3.fromRGB(240, 242, 245)
	local blue = Color3.fromRGB(34, 69, 151)
	part(
		"Body",
		Vector3.new(9, 7.6, 52),
		CFrame.new(0, 6.6, 0),
		body,
		{ material = Enum.Material.Metal }
	)
	part("Stripe", Vector3.new(9.1, 1.6, 52.1), CFrame.new(0, 3.5, 0), blue)
	part("Roof", Vector3.new(8, 0.6, 52), CFrame.new(0, 10.7, 0), Color3.fromRGB(150, 154, 160))
	part("Skirt", Vector3.new(8.4, 1.2, 52), CFrame.new(0, 2.4, 0), DARK, { canCollide = false })
	for _, side in { -1, 1 } do
		part(
			"Windows",
			Vector3.new(0.2, 2.8, 46),
			CFrame.new(side * 4.55, 7.4, 0),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.2, canCollide = false }
		)
		for _, z in { -16, 0, 16 } do
			part(
				"DoorPanel",
				Vector3.new(0.25, 5.6, 3.6),
				CFrame.new(side * 4.6, 5.6, z),
				blue,
				{ canCollide = false }
			)
		end
	end
	for _, end_ in { -1, 1 } do
		part(
			"Windshield",
			Vector3.new(7.4, 3, 0.2),
			CFrame.new(0, 7.8, end_ * 26.05),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.2, canCollide = false }
		)
		for _, x in { -3, 3 } do
			part(
				"Light",
				Vector3.new(0.9, 0.9, 0.2),
				CFrame.new(x, 3.6, end_ * 26.05),
				HEADLIGHT,
				{ material = Enum.Material.Neon, canCollide = false }
			)
		end
		part(
			"Bogie",
			Vector3.new(6, 1.4, 9),
			CFrame.new(0, 1.5, end_ * 18),
			DARK,
			{ canCollide = false }
		)
	end
	part(
		"PantographBase",
		Vector3.new(3, 0.4, 3),
		CFrame.new(0, 11.2, 8),
		DARK,
		{ canCollide = false }
	)
	part(
		"PantographArmA",
		Vector3.new(0.3, 0.3, 6),
		CFrame.new(0, 13.2, 6.2) * CFrame.Angles(math.rad(-35), 0, 0),
		DARK,
		{ canCollide = false }
	)
	part(
		"PantographArmB",
		Vector3.new(0.3, 0.3, 6),
		CFrame.new(0, 13.2, 10.2) * CFrame.Angles(math.rad(35), 0, 0),
		DARK,
		{ canCollide = false }
	)
	part(
		"PantographBar",
		Vector3.new(3.4, 0.25, 0.4),
		CFrame.new(0, 15.3, 8.2),
		STEEL,
		{ canCollide = false }
	)
	return model
end

return Vehicles
