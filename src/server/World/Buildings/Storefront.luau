--!strict
-- Магазинчик на первом этаже жилого дома: цоколь, витрина с подсветкой и товарами за стеклом, дверь,
-- полосатый навес, вывеска с названием (Locale shop.<вид>) и мелочи перед входом (цветы, столик, ящики).
-- origin: центр фасада на земле, -Z смотрит на улицу. Магазины вымышленные, без реальных брендов.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Parent.Build)

local Storefront = {}

type Style = { awning: Color3, stripe: Color3, sign: Color3 }

local STYLES: { [string]: Style } = {
	grocery = {
		awning = Color3.fromRGB(70, 150, 80),
		stripe = Color3.fromRGB(240, 240, 232),
		sign = Color3.fromRGB(40, 90, 50),
	},
	coffee = {
		awning = Color3.fromRGB(120, 78, 52),
		stripe = Color3.fromRGB(240, 226, 196),
		sign = Color3.fromRGB(60, 40, 30),
	},
	pharmacy = {
		awning = Color3.fromRGB(60, 160, 110),
		stripe = Color3.fromRGB(245, 245, 245),
		sign = Color3.fromRGB(235, 240, 238),
	},
	books = {
		awning = Color3.fromRGB(150, 50, 60),
		stripe = Color3.fromRGB(240, 226, 196),
		sign = Color3.fromRGB(70, 28, 36),
	},
	pizza = {
		awning = Color3.fromRGB(210, 60, 50),
		stripe = Color3.fromRGB(245, 245, 240),
		sign = Color3.fromRGB(150, 30, 28),
	},
	flowers = {
		awning = Color3.fromRGB(232, 65, 142),
		stripe = Color3.fromRGB(158, 223, 255),
		sign = Color3.fromRGB(110, 40, 80),
	},
	sweets = {
		awning = Color3.fromRGB(200, 60, 90),
		stripe = Color3.fromRGB(245, 230, 220),
		sign = Color3.fromRGB(110, 36, 54),
	},
	post = {
		awning = Color3.fromRGB(218, 40, 46),
		stripe = Color3.fromRGB(245, 245, 245),
		sign = Color3.fromRGB(180, 30, 36),
	},
}
Storefront.kinds =
	{ "grocery", "coffee", "pharmacy", "books", "pizza", "flowers", "sweets", "post" }

-- Бренды партнёров проекта по видам магазинов (названия по договорённости с заказчиком).
local BRANDS: { [string]: { string } } = {
	grocery = { "silpo", "atb", "novus" },
	coffee = { "aroma", "lvivcroissants" },
	pharmacy = { "podorozhnyk", "apteka911" },
	books = { "yeknyharnia", "starylev" },
	pizza = { "veterano", "celentano" },
	flowers = { "flowers" },
	sweets = { "roshen" },
	post = { "novaposhta" },
}

local STONE = Color3.fromRGB(150, 152, 158)
local FRAME = Color3.fromRGB(52, 56, 64)
local GLASS = Color3.fromRGB(236, 220, 176)
local PRODUCTS = {
	Color3.fromRGB(214, 60, 60),
	Color3.fromRGB(240, 190, 40),
	Color3.fromRGB(70, 120, 210),
	Color3.fromRGB(80, 170, 90),
	Color3.fromRGB(232, 65, 142),
	Color3.fromRGB(245, 245, 240),
}
local FLOWERS = {
	Color3.fromRGB(232, 65, 142),
	Color3.fromRGB(250, 210, 60),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(158, 100, 210),
}

local function buildProps(model: Model, origin: CFrame, width: number, kind: string, random: Random)
	local function part(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		options: Build.Options?
	)
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, size, origin * offset, color, opts)
	end
	local frontX = -width / 2 + 3
	if kind == "flowers" then
		for i = 0, 2 do
			local x = frontX + i * 3
			local position = (origin * CFrame.new(x, 0.9, -3.4)).Position
			Build.cylinder(
				model,
				1.6,
				1.8,
				position,
				Color3.fromRGB(90, 96, 104),
				"Y",
				{ name = "Bucket" }
			)
			for _ = 1, 5 do
				local offset =
					Vector3.new(random:NextNumber(-0.5, 0.5), 1.3, random:NextNumber(-0.5, 0.5))
				Build.ball(
					model,
					0.9,
					position + offset,
					FLOWERS[random:NextInteger(1, #FLOWERS)],
					{ name = "Flower", canCollide = false }
				)
			end
		end
	elseif kind == "coffee" then
		local position = (origin * CFrame.new(frontX + 1, 0, -4.5)).Position
		Build.cylinder(
			model,
			2.6,
			0.15,
			position + Vector3.new(0, 2.4, 0),
			Color3.fromRGB(230, 226, 214),
			"Y",
			{ name = "TableTop" }
		)
		Build.cylinder(
			model,
			0.3,
			2.4,
			position + Vector3.new(0, 1.2, 0),
			FRAME,
			"Y",
			{ name = "TableLeg" }
		)
		for _, dx in { -2, 2 } do
			Build.cylinder(
				model,
				1.3,
				1.6,
				position + Vector3.new(dx, 0.8, 0),
				Color3.fromRGB(120, 78, 52),
				"Y",
				{ name = "Stool" }
			)
		end
	elseif kind == "grocery" then
		for i = 0, 1 do
			part(
				"Crate",
				Vector3.new(2.4, 1.2, 1.6),
				CFrame.new(frontX + i * 3, 0.6, -3.2),
				Color3.fromRGB(170, 120, 70),
				{ material = Enum.Material.Wood }
			)
			for j = 0, 3 do
				Build.ball(
					model,
					0.8,
					(origin * CFrame.new(frontX + i * 3 - 0.9 + j * 0.6, 1.5, -3.2)).Position,
					PRODUCTS[(i * 4 + j) % #PRODUCTS + 1],
					{ name = "Fruit", canCollide = false }
				)
			end
		end
	elseif kind == "pizza" then
		part(
			"SignBoard",
			Vector3.new(2.2, 3.2, 0.2),
			CFrame.new(frontX + 1, 1.6, -3.4),
			Color3.fromRGB(34, 36, 40)
		)
		for i = 0, 2 do
			part(
				"MenuBar",
				Vector3.new(1.6 - i * 0.2, 0.2, 0.05),
				CFrame.new(frontX + 1, 2.4 - i * 0.6, -3.52),
				Color3.fromRGB(240, 226, 196),
				{ canCollide = false }
			)
		end
	elseif kind == "books" then
		part(
			"BookShelf",
			Vector3.new(3.2, 3.6, 1.1),
			CFrame.new(frontX + 1.4, 1.8, -3.2),
			Color3.fromRGB(150, 100, 60),
			{ material = Enum.Material.Wood }
		)
		for row = 0, 2 do
			for i = 0, 5 do
				part(
					"Book",
					Vector3.new(0.35, 0.8, 0.8),
					CFrame.new(frontX + 0.2 + i * 0.5, 0.95 + row * 1.1, -3.9),
					PRODUCTS[random:NextInteger(1, #PRODUCTS)],
					{ canCollide = false }
				)
			end
		end
	elseif kind == "pharmacy" then
		part(
			"CrossV",
			Vector3.new(0.9, 3, 0.4),
			CFrame.new(-width / 2 + 2, 8.6, -0.9),
			Color3.fromRGB(60, 190, 110),
			{ material = Enum.Material.Neon, canCollide = false }
		)
		part(
			"CrossH",
			Vector3.new(3, 0.9, 0.4),
			CFrame.new(-width / 2 + 2, 8.6, -0.9),
			Color3.fromRGB(60, 190, 110),
			{ material = Enum.Material.Neon, canCollide = false }
		)
	end
end

-- Строит магазин вида kind шириной width.
function Storefront.build(parent: Instance, origin: CFrame, width: number, kind: string)
	local style = STYLES[kind] or STYLES.grocery
	local model = Instance.new("Model")
	model.Name = "Shop_" .. kind
	model.Parent = parent
	local random = Random.new(math.floor(math.abs(origin.Position.X * 7 + origin.Position.Z)))

	local function part(
		name: string,
		size: Vector3,
		offset: CFrame,
		color: Color3,
		options: Build.Options?
	)
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, size, origin * offset, color, opts)
	end

	-- Цоколь и рамы витрины.
	part(
		"Base",
		Vector3.new(width, 1.2, 0.6),
		CFrame.new(0, 0.6, -0.3),
		STONE,
		{ material = Enum.Material.Concrete }
	)
	local doorWidth = 3.2
	local glassWidth = width - doorWidth - 2.4
	local glassX = -width / 2 + 0.8 + glassWidth / 2
	local doorX = width / 2 - 0.8 - doorWidth / 2

	-- Витрина: тёплое стекло, за ним две полки с товарами.
	part(
		"ShopWindow",
		Vector3.new(glassWidth, 5.4, 0.15),
		CFrame.new(glassX, 4.1, -1.3),
		GLASS,
		{ material = Enum.Material.Glass, transparency = 0.35, canCollide = false }
	)
	for _, shelfY in { 2.6, 4.6 } do
		part(
			"Shelf",
			Vector3.new(glassWidth - 0.6, 0.2, 0.9),
			CFrame.new(glassX, shelfY, -0.8),
			Color3.fromRGB(150, 100, 60),
			{ canCollide = false }
		)
		local count = math.floor((glassWidth - 1) / 1.1)
		for i = 0, count - 1 do
			part(
				"Product",
				Vector3.new(0.7, 0.9, 0.5),
				CFrame.new(glassX - (count - 1) * 0.55 + i * 1.1, shelfY + 0.55, -0.8),
				PRODUCTS[random:NextInteger(1, #PRODUCTS)],
				{ canCollide = false }
			)
		end
	end
	for _, postX in
		{
			glassX - glassWidth / 2 - 0.2,
			glassX + glassWidth / 2 + 0.2,
			doorX - doorWidth / 2 - 0.2,
		}
	do
		part("Frame", Vector3.new(0.4, 6.6, 0.5), CFrame.new(postX, 3.8, -1.35), FRAME)
	end
	part("FrameTop", Vector3.new(width - 0.8, 0.4, 0.5), CFrame.new(0, 7.1, -1.35), FRAME)

	-- Дверь со стеклом и ручкой.
	part(
		"Door",
		Vector3.new(doorWidth, 6.2, 0.2),
		CFrame.new(doorX, 3.7, -1.3),
		FRAME,
		{ canCollide = false }
	)
	part(
		"DoorGlass",
		Vector3.new(doorWidth - 0.8, 4.6, 0.25),
		CFrame.new(doorX, 4.3, -1.4),
		GLASS,
		{ material = Enum.Material.Glass, transparency = 0.35, canCollide = false }
	)
	part(
		"DoorHandle",
		Vector3.new(0.2, 1.2, 0.2),
		CFrame.new(doorX + doorWidth / 2 - 0.5, 3.8, -1.6),
		Color3.fromRGB(200, 204, 210),
		{ canCollide = false }
	)

	-- Вывеска и полосатый навес.
	local sign =
		part("Sign", Vector3.new(width - 1, 2.2, 0.5), CFrame.new(0, 8.6, -0.4), style.sign)
	local textColor = Color3.fromRGB(245, 240, 226)
	if kind == "pharmacy" then
		textColor = Color3.fromRGB(30, 110, 70)
	end
	local choices = BRANDS[kind] or BRANDS.grocery
	local brand = choices[random:NextInteger(1, #choices)]
	Build.text(
		sign,
		Enum.NormalId.Front,
		Locale.translate("uk", "shop.brand." .. brand),
		textColor,
		nil
	)
	local stripes = math.max(4, math.floor(width / 2.2))
	local stripeWidth = width / stripes
	for i = 0, stripes - 1 do
		local color = style.awning
		if i % 2 == 1 then
			color = style.stripe
		end
		part(
			"Awning",
			Vector3.new(stripeWidth, 0.3, 3.4),
			CFrame.new(-width / 2 + stripeWidth * (i + 0.5), 7.55, -2.5)
				* CFrame.Angles(math.rad(-12), 0, 0),
			color,
			{ canCollide = false }
		)
	end
	buildProps(model, origin, width, kind, random)
end

return Storefront
