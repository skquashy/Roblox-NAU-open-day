--!strict
-- Житловий будинок: віконні стрічки з простінками, балкони зі скляними огорожами, парапет і надбудови на даху,
-- цоколь. На першому поверсі або магазини (Storefront), або під'їзд із козирком.
-- origin: центр будинку на землі, -Z дивиться на вулицю/кампус. Розміри та поверховість задаються ззовні.

local Build = require(script.Parent.Parent.Build)
local Facade = require(script.Parent.Facade)
local Storefront = require(script.Parent.Storefront)

local Apartment = {}

export type Options = {
	wall: Color3,
	shops: boolean, -- true: на першому поверсі магазини по всій ширині фасаду
	random: Random,
}

local FLOOR_HEIGHT = 10
local STONE = Color3.fromRGB(150, 152, 158)
local GLASS = Color3.fromRGB(78, 104, 140)
local BALCONY = Color3.fromRGB(205, 206, 206)
local ROOF = Color3.fromRGB(104, 108, 116)

Apartment.FLOOR_HEIGHT = FLOOR_HEIGHT

local function buildRoof(model: Model, origin: CFrame, width: number, depth: number, height: number)
	local function part(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		material: Enum.Material?
	)
		return Build.part(
			model,
			size,
			origin * offset,
			color,
			{ name = name, material = material, canCollide = false }
		)
	end
	part("Parapet", Vector3.new(width + 1, 1, depth + 1), CFrame.new(0, height + 0.5, 0), ROOF)
	part(
		"LiftHouse",
		Vector3.new(width * 0.18, 5, depth * 0.3),
		CFrame.new(width * 0.25, height + 3.5, 0),
		STONE,
		Enum.Material.Concrete
	)
	for _, x in { -width * 0.25, -width * 0.15 } do
		Build.cylinder(
			model,
			1.4,
			4,
			(origin * CFrame.new(x, height + 3, depth * 0.2)).Position,
			Color3.fromRGB(120, 116, 112),
			"Y",
			{ name = "Chimney", canCollide = false }
		)
	end
	Build.cylinder(
		model,
		0.25,
		7,
		(origin * CFrame.new(width * 0.3, height + 9.5, 0)).Position,
		Color3.fromRGB(190, 194, 202),
		"Y",
		{ name = "Antenna", canCollide = false }
	)
end

-- Балкони на лицьовому боці: плита й скляна огорожа, починаючи з третього поверху.
local function buildBalconies(
	model: Model,
	origin: CFrame,
	width: number,
	depth: number,
	floors: number
)
	local columns = math.max(2, math.floor(width / 18))
	for floor = 3, floors do
		local y = (floor - 1) * FLOOR_HEIGHT
		for i = 1, columns do
			local x = -width / 2 + width * (i - 0.5) / columns
			Build.part(
				model,
				Vector3.new(5.5, 0.5, 3),
				origin * CFrame.new(x, y + 0.25, -depth / 2 - 1.5),
				BALCONY,
				{ name = "BalconySlab", canCollide = false }
			)
			Build.part(
				model,
				Vector3.new(5.5, 1.4, 0.15),
				origin * CFrame.new(x, y + 1.2, -depth / 2 - 2.95),
				Color3.fromRGB(150, 190, 215),
				{
					name = "BalconyGlass",
					material = Enum.Material.Glass,
					transparency = 0.45,
					canCollide = false,
				}
			)
		end
	end
end

-- Під'їзд: двері, козирок, сходи.
local function buildEntrance(model: Model, origin: CFrame, depth: number)
	local frontZ = -depth / 2
	Build.part(
		model,
		Vector3.new(5, 7, 0.5),
		origin * CFrame.new(0, 3.5, frontZ - 0.4),
		Color3.fromRGB(40, 60, 100),
		{ name = "Door", canCollide = false }
	)
	Build.part(
		model,
		Vector3.new(9, 0.6, 4),
		origin * CFrame.new(0, 8, frontZ - 2),
		Color3.fromRGB(104, 108, 116),
		{ name = "Canopy" }
	)
	Build.part(
		model,
		Vector3.new(8, 0.6, 3),
		origin * CFrame.new(0, 0.3, frontZ - 1.5),
		STONE,
		{ name = "Steps", material = Enum.Material.Concrete }
	)
end

-- Будує будинок завширшки width, завглибшки depth і floors поверхів. Повертає модель.
function Apartment.build(
	parent: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	floors: number,
	options: Options
): Model
	local model = Instance.new("Model")
	model.Name = "Apartment"
	model.Parent = parent
	local height = floors * FLOOR_HEIGHT

	Build.part(
		model,
		Vector3.new(width, height, depth),
		origin * CFrame.new(0, height / 2, 0),
		options.wall,
		{ name = "Body", material = Enum.Material.Concrete }
	)
	-- Цоколь виступає трохи далі за стіни по всьому периметру.
	Build.part(
		model,
		Vector3.new(width + 0.8, 2.4, depth + 0.8),
		origin * CFrame.new(0, 1.2, 0),
		STONE,
		{ name = "Plinth", material = Enum.Material.Concrete }
	)
	-- Якщо магазинів немає, вікна йдуть з першого поверху; інакше перший поверх віддано під вітрини.
	local firstWindowFloor = 1
	if options.shops then
		firstWindowFloor = 2
	end
	Facade.rows(model, origin, width, depth, {
		firstFloor = firstWindowFloor,
		floors = floors,
		floorHeight = FLOOR_HEIGHT,
		glass = GLASS,
		pier = options.wall:Lerp(Color3.new(1, 1, 1), 0.35),
		columnWidth = 6,
		glassHeight = 5,
	})
	buildBalconies(model, origin, width, depth, floors)
	buildRoof(model, origin, width, depth, height)

	if options.shops then
		local count = math.max(2, math.floor((width - 6) / 14))
		local shopWidth = (width - 6) / count
		for i = 0, count - 1 do
			local x = -width / 2 + 3 + shopWidth * (i + 0.5)
			local kind = Storefront.kinds[options.random:NextInteger(1, #Storefront.kinds)]
			Storefront.build(model, origin * CFrame.new(x, 0, -depth / 2), shopWidth, kind)
		end
	else
		buildEntrance(model, origin, depth)
	end
	return model
end

return Apartment
