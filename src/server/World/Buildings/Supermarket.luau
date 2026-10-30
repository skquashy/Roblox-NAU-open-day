--!strict
-- Супермаркет «Фора» с площадкой перед входом и парковкой. Здание полое: сквозь прозрачные витрины видны
-- торговый зал, стеллажи с товарами, холодильная стена, кассы и светильники. Снаружи тёмные панели,
-- деревянная обшивка у основания, зелёная вывеска с красным знаком, тамбур, навес с тележками, урны.
-- Использование названия согласовано с руководством магазина.
-- origin: центр здания на земле, -Z смотрит на площадку и проспект. Внимание: из-за поворота здания
-- локальная ось X идёт влево от зрителя перед фасадом, поэтому «вправо» на экране это меньший X.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Parent.Build)
local Vehicles = require(script.Parent.Parent.Vehicles)

local Supermarket = {}

local HEIGHT = 17
local WALL = 0.6
local FLOOR_TOP = 0.6
local DARK = Color3.fromRGB(66, 68, 74)
local WOOD = Color3.fromRGB(196, 138, 72)
local GREEN = Color3.fromRGB(60, 168, 72)
local RED = Color3.fromRGB(226, 48, 52)
local GLASS = Color3.fromRGB(210, 228, 236)
local FRAME = Color3.fromRGB(44, 48, 56)
local INSIDE = Color3.fromRGB(240, 238, 230)
local WHITE = Color3.fromRGB(245, 245, 242)
local PRODUCTS = {
	Color3.fromRGB(214, 60, 60),
	Color3.fromRGB(240, 190, 40),
	Color3.fromRGB(70, 120, 210),
	Color3.fromRGB(80, 170, 90),
	Color3.fromRGB(232, 65, 142),
	Color3.fromRGB(245, 245, 240),
}
local PITCH = 1.1 -- шаг товаров вдоль полки; самый широкий товар 1.0

type Context = { model: Model, origin: CFrame }

local function put(
	ctx: Context,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	options: Build.Options?
): Part
	local opts: Build.Options = options or {}
	opts.name = name
	return Build.part(ctx.model, size, ctx.origin * offset, color, opts)
end

-- Вывеска: зелёная плита с надписью, красный знак справа от надписи (на экране).
local function sign(ctx: Context, x: number, y: number, frontZ: number)
	local board =
		put(ctx, "SignBoard", Vector3.new(24, 5, 1), CFrame.new(x, y, frontZ - 0.5), GREEN)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.7, 0.9)
	label.Position = UDim2.fromScale(0.03, 0.05)
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextColor3 = Color3.new(1, 1, 1)
	label.FontFace = Font.new(
		"rbxasset://fonts/families/Montserrat.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	label.Text = Locale.translate("uk", "shop.fora")
	label.Parent = gui
	-- Знак стоит с меньшим локальным X, чтобы на экране оказаться правее надписи.
	local logoPosition = (ctx.origin * CFrame.new(x - 9, y, frontZ - 1.2)).Position
	Build.cylinder(
		ctx.model,
		4.2,
		0.4,
		logoPosition,
		RED,
		"Z",
		{ name = "LogoDisc", canCollide = false }
	)
	local spot = (ctx.origin * CFrame.new(x - 8.5, y + 0.4, frontZ - 1.5)).Position
	Build.cylinder(
		ctx.model,
		1.6,
		0.4,
		spot,
		Color3.fromRGB(250, 250, 250),
		"Z",
		{ name = "LogoSpot", canCollide = false }
	)
end

-- Товар: бутылка, банка, коробка или пакет. base: центр основания; ширина не больше 1.0, глубина не больше 0.7.
local function product(ctx: Context, base: Vector3, random: Random)
	local color = PRODUCTS[random:NextInteger(1, #PRODUCTS)]
	local kind = random:NextInteger(1, 4)
	local position = (ctx.origin * CFrame.new(base)).Position
	if kind == 1 then
		Build.cylinder(
			ctx.model,
			0.7,
			1.4,
			position + Vector3.new(0, 0.7, 0),
			color,
			"Y",
			{ name = "Bottle", canCollide = false }
		)
		Build.cylinder(
			ctx.model,
			0.4,
			0.3,
			position + Vector3.new(0, 1.55, 0),
			WHITE,
			"Y",
			{ name = "BottleCap", canCollide = false }
		)
	elseif kind == 2 then
		Build.cylinder(
			ctx.model,
			0.8,
			1.1,
			position + Vector3.new(0, 0.55, 0),
			color,
			"Y",
			{ name = "Can", canCollide = false }
		)
	elseif kind == 3 then
		put(
			ctx,
			"Box",
			Vector3.new(0.9, 1.3, 0.6),
			CFrame.new(base + Vector3.new(0, 0.65, 0)),
			color,
			{ canCollide = false }
		)
	else
		put(
			ctx,
			"Pack",
			Vector3.new(1, 1.4, 0.3),
			CFrame.new(base + Vector3.new(0, 0.7, 0)),
			color,
			{ canCollide = false }
		)
	end
end

-- Заполнение полки: count товаров вдоль X с шагом PITCH, центр ряда centerX.
local function shelfRow(
	ctx: Context,
	centerX: number,
	y: number,
	z: number,
	length: number,
	random: Random
)
	local count = math.floor(length / PITCH)
	for i = 0, count - 1 do
		product(ctx, Vector3.new(centerX - (count - 1) * PITCH / 2 + i * PITCH, y, z), random)
	end
end

-- Двусторонний стеллаж вдоль X: основание, задняя панель, три яруса полок с обеих сторон.
local function gondola(ctx: Context, x: number, z: number, length: number, random: Random)
	put(
		ctx,
		"GondolaBase",
		Vector3.new(length, 0.5, 3),
		CFrame.new(x, FLOOR_TOP + 0.25, z),
		Color3.fromRGB(190, 192, 198),
		{ canCollide = false }
	)
	put(
		ctx,
		"GondolaPanel",
		Vector3.new(length, 7, 0.2),
		CFrame.new(x, FLOOR_TOP + 3.5, z),
		Color3.fromRGB(150, 154, 160),
		{ canCollide = false }
	)
	for _, tier in { 0.9, 2.9, 4.9 } do
		for _, side in { -1, 1 } do
			local shelfZ = z + side * 0.85
			put(
				ctx,
				"Shelf",
				Vector3.new(length, 0.2, 1.3),
				CFrame.new(x, FLOOR_TOP + tier, shelfZ),
				Color3.fromRGB(176, 180, 186),
				{ canCollide = false }
			)
			shelfRow(ctx, x, FLOOR_TOP + tier + 0.1, shelfZ, length - 1, random)
		end
	end
end

-- Холодильная стена у задней стены: каркас, ярусы с бутылками, стеклянные дверцы.
local function fridge(ctx: Context, x: number, z: number, length: number, random: Random)
	local top = FLOOR_TOP + 8
	put(
		ctx,
		"FridgeBack",
		Vector3.new(length, 8, 0.3),
		CFrame.new(x, FLOOR_TOP + 4, z + 1.2),
		Color3.fromRGB(224, 228, 232),
		{ canCollide = false }
	)
	put(
		ctx,
		"FridgeTop",
		Vector3.new(length, 0.3, 2.6),
		CFrame.new(x, top, z),
		Color3.fromRGB(224, 228, 232),
		{ canCollide = false }
	)
	for _, tier in { 0.2, 2.2, 4.2, 6.2 } do
		put(
			ctx,
			"FridgeShelf",
			Vector3.new(length, 0.15, 2.3),
			CFrame.new(x, FLOOR_TOP + tier, z),
			Color3.fromRGB(235, 238, 240),
			{ canCollide = false }
		)
		local count = math.floor((length - 1) / PITCH)
		for i = 0, count - 1 do
			local color = PRODUCTS[random:NextInteger(1, #PRODUCTS)]
			local base =
				Vector3.new(x - (count - 1) * PITCH / 2 + i * PITCH, FLOOR_TOP + tier + 0.1, z)
			local position = (ctx.origin * CFrame.new(base)).Position
			Build.cylinder(
				ctx.model,
				0.7,
				1.5,
				position + Vector3.new(0, 0.75, 0),
				color,
				"Y",
				{ name = "Bottle", canCollide = false }
			)
		end
	end
	local glass = put(
		ctx,
		"FridgeGlass",
		Vector3.new(length, 7.8, 0.12),
		CFrame.new(x, FLOOR_TOP + 4, z - 1.3),
		GLASS,
		{ canCollide = false }
	)
	glass.Material = Enum.Material.Glass
	glass.Transparency = 0.75
end

-- Касса: стойка с лентой, терминал и стопка корзин.
local function checkout(ctx: Context, x: number, z: number)
	put(
		ctx,
		"CheckoutCounter",
		Vector3.new(8, 2.6, 1.8),
		CFrame.new(x, FLOOR_TOP + 1.3, z),
		Color3.fromRGB(70, 72, 78),
		{ canCollide = false }
	)
	put(
		ctx,
		"CheckoutBelt",
		Vector3.new(5, 0.2, 1.2),
		CFrame.new(x + 0.5, FLOOR_TOP + 2.7, z),
		Color3.fromRGB(30, 32, 36),
		{ canCollide = false }
	)
	put(
		ctx,
		"Terminal",
		Vector3.new(0.8, 1, 0.6),
		CFrame.new(x - 3, FLOOR_TOP + 3.2, z),
		Color3.fromRGB(40, 44, 52),
		{ canCollide = false }
	)
	put(
		ctx,
		"TerminalScreen",
		Vector3.new(0.6, 0.5, 0.05),
		CFrame.new(x - 3, FLOOR_TOP + 3.4, z - 0.32),
		Color3.fromRGB(70, 140, 190),
		{ material = Enum.Material.Neon, canCollide = false }
	)
	for i = 0, 2 do
		put(
			ctx,
			"Basket",
			Vector3.new(1.6, 0.6, 1.1),
			CFrame.new(x + 3, FLOOR_TOP + 0.3 + i * 0.4, z + 2),
			RED,
			{ canCollide = false }
		)
	end
end

-- Торговый зал: стеллажи, холодильники, кассы и светильники.
local function interior(ctx: Context, width: number, depth: number, random: Random)
	local frontZ = -depth / 2
	local backZ = depth / 2
	put(
		ctx,
		"FloorTiles",
		Vector3.new(width - 2 * WALL, 0.2, depth - 2 * WALL),
		CFrame.new(0, FLOOR_TOP - 0.1, 0),
		Color3.fromRGB(214, 214, 208)
	)
	for _, z in { frontZ + 11, frontZ + 17, frontZ + 23 } do
		gondola(ctx, -10, z, 26, random)
	end
	fridge(ctx, -15, backZ - WALL - 1.5, 20, random)
	for _, z in { frontZ + 8, frontZ + 14, frontZ + 20 } do
		checkout(ctx, 18, z)
	end
	-- Потолочные панели; свет излучают четыре из них, остальные просто светятся.
	local lit = 0
	for _, z in { frontZ + 8, 0, backZ - 8 } do
		for _, x in { -22, -11, 0, 11, 22 } do
			local panel = put(
				ctx,
				"CeilingLight",
				Vector3.new(4, 0.15, 1.4),
				CFrame.new(x, HEIGHT - 0.7, z),
				Color3.fromRGB(255, 248, 232),
				{ material = Enum.Material.Neon, canCollide = false }
			)
			lit += 1
			if lit % 4 == 1 then
				Build.glow(panel, Color3.fromRGB(255, 244, 222), 0.9, 22)
			end
		end
	end
end

-- Оболочка: пол, задняя и боковые стены, потолок и фасад из простенков и стёкол.
local function shell(ctx: Context, width: number, depth: number)
	local frontZ = -depth / 2
	put(
		ctx,
		"Floor",
		Vector3.new(width, FLOOR_TOP, depth),
		CFrame.new(0, FLOOR_TOP / 2, 0),
		Color3.fromRGB(150, 152, 158)
	)
	put(
		ctx,
		"BackWall",
		Vector3.new(width, HEIGHT, WALL),
		CFrame.new(0, HEIGHT / 2, depth / 2 - WALL / 2),
		DARK
	)
	for _, side in { -1, 1 } do
		put(
			ctx,
			"SideWall",
			Vector3.new(WALL, HEIGHT, depth),
			CFrame.new(side * (width / 2 - WALL / 2), HEIGHT / 2, 0),
			DARK
		)
	end
	put(
		ctx,
		"Ceiling",
		Vector3.new(width - 2 * WALL, 0.5, depth - 2 * WALL),
		CFrame.new(0, HEIGHT - 0.25, 0),
		INSIDE
	)
	put(
		ctx,
		"Roof",
		Vector3.new(width + 2, 1, depth + 2),
		CFrame.new(0, HEIGHT + 0.5, 0),
		Color3.fromRGB(104, 108, 116)
	)
	put(
		ctx,
		"Parapet",
		Vector3.new(width + 2.6, 2, depth + 2.6),
		CFrame.new(0, HEIGHT + 1, 0),
		DARK,
		{ canCollide = false }
	)
	-- Внутренняя облицовка стен светлая, чтобы зал не казался чёрным.
	put(
		ctx,
		"InnerBack",
		Vector3.new(width - 2 * WALL, HEIGHT - 1, 0.1),
		CFrame.new(0, HEIGHT / 2, depth / 2 - WALL - 0.05),
		INSIDE,
		{ canCollide = false }
	)
	for _, side in { -1, 1 } do
		put(
			ctx,
			"InnerSide",
			Vector3.new(0.1, HEIGHT - 1, depth - 2 * WALL),
			CFrame.new(side * (width / 2 - WALL - 0.05), HEIGHT / 2, 0),
			INSIDE,
			{ canCollide = false }
		)
	end

	-- Фасад: деревянный цоколь, верхняя балка под вывеской, простенки и стёкла.
	local wallZ = frontZ + WALL / 2
	put(
		ctx,
		"WoodBase",
		Vector3.new(width, 3.4, WALL),
		CFrame.new(0, 1.7, wallZ),
		WOOD,
		{ material = Enum.Material.Wood }
	)
	put(ctx, "Header", Vector3.new(width, 5, WALL), CFrame.new(0, HEIGHT - 2.5, wallZ), DARK)
	local bays = math.floor((width - 22) / 10)
	local startX = -width / 2 + 3
	for i = 0, bays - 1 do
		local x = startX + i * 10 + 5
		put(
			ctx,
			"ShopWindow",
			Vector3.new(9.2, 8.6, 0.15),
			CFrame.new(x, 7.7, wallZ),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.85, canCollide = false }
		)
	end
	for i = 0, bays do
		put(
			ctx,
			"Pillar",
			Vector3.new(0.8, 8.6, 0.9),
			CFrame.new(startX + i * 10, 7.7, frontZ - 0.1),
			FRAME
		)
	end
	-- Глухие участки фасада по краям и между витринами и тамбуром.
	put(ctx, "WallEdge", Vector3.new(3, 8.6, WALL), CFrame.new(-width / 2 + 1.5, 7.7, wallZ), DARK)
	local solidFrom = startX + bays * 10
	local vestibuleLeft = width / 2 - 15
	if vestibuleLeft > solidFrom then
		put(
			ctx,
			"WallMid",
			Vector3.new(vestibuleLeft - solidFrom, 8.6, WALL),
			CFrame.new((solidFrom + vestibuleLeft) / 2, 7.7, wallZ),
			DARK
		)
	end
	put(ctx, "WallRight", Vector3.new(3, 8.6, WALL), CFrame.new(width / 2 - 1.5, 7.7, wallZ), DARK)
end

-- Строит магазин width на depth: оболочку, зал, вывеску, тамбур, навес с тележками, урны.
function Supermarket.build(parent: Instance, origin: CFrame, width: number, depth: number)
	local model = Instance.new("Model")
	model.Name = "Supermarket_fora"
	model.Parent = parent
	local ctx: Context = { model = model, origin = origin }
	local random = Random.new(2007)
	local frontZ = -depth / 2

	shell(ctx, width, depth)
	interior(ctx, width, depth, random)
	sign(ctx, -width / 2 + 14, HEIGHT - 2.5, frontZ)

	-- Деревянная обшивка боковых стен снаружи.
	for _, side in { -1, 1 } do
		put(
			ctx,
			"WoodSide",
			Vector3.new(0.5, 3.4, depth),
			CFrame.new(side * (width / 2 + 0.25), 1.7, 0),
			WOOD,
			{ material = Enum.Material.Wood }
		)
	end

	-- Тамбур справа: стеклянная коробка с рамой, двумя створками дверей, ручками и надписью «Вхід».
	-- Стекло и двери твёрдые: пройти сквозь вход нельзя.
	local vestibuleX = width / 2 - 9
	local glassOptions: Build.Options = { material = Enum.Material.Glass, transparency = 0.55 }
	put(
		ctx,
		"Vestibule",
		Vector3.new(12, 9.5, 4),
		CFrame.new(vestibuleX, 4.75, frontZ - 2),
		GLASS,
		glassOptions
	)
	put(
		ctx,
		"VestibuleRoof",
		Vector3.new(13, 0.8, 5),
		CFrame.new(vestibuleX, 9.9, frontZ - 2.2),
		FRAME
	)
	for _, dx in { -6, 6 } do
		for _, dz in { 0, -4 } do
			put(
				ctx,
				"VestibulePost",
				Vector3.new(0.5, 9.5, 0.5),
				CFrame.new(vestibuleX + dx, 4.75, frontZ - 2 + dz / 2 * 1),
				FRAME
			)
		end
	end
	put(
		ctx,
		"DoorTopFrame",
		Vector3.new(12.4, 0.6, 0.5),
		CFrame.new(vestibuleX, 8.6, frontZ - 4.1),
		FRAME
	)
	put(
		ctx,
		"DoorCenter",
		Vector3.new(0.5, 8.4, 0.5),
		CFrame.new(vestibuleX, 4.3, frontZ - 4.1),
		FRAME
	)
	for _, dx in { -3, 3 } do
		put(
			ctx,
			"DoorLeaf",
			Vector3.new(5.2, 8, 0.2),
			CFrame.new(vestibuleX + dx, 4.3, frontZ - 4.2),
			GLASS,
			glassOptions
		)
		put(
			ctx,
			"DoorHandle",
			Vector3.new(0.25, 2.2, 0.35),
			CFrame.new(vestibuleX + dx * 0.25, 4.2, frontZ - 4.5),
			Color3.fromRGB(200, 204, 210)
		)
	end
	put(
		ctx,
		"DoorMat",
		Vector3.new(10, 0.1, 3),
		CFrame.new(vestibuleX, 0.05, frontZ - 6),
		Color3.fromRGB(60, 64, 70),
		{ canCollide = false }
	)
	local entranceSign = put(
		ctx,
		"EntranceSign",
		Vector3.new(7, 1.2, 0.3),
		CFrame.new(vestibuleX, 9.3, frontZ - 4.6),
		GREEN,
		{ canCollide = false }
	)
	Build.text(
		entranceSign,
		Enum.NormalId.Front,
		Locale.translate("uk", "shop.entrance"),
		Color3.new(1, 1, 1),
		nil
	)

	-- Крыша: кондиционеры и световой фонарь.
	for i = 0, 3 do
		put(
			ctx,
			"AirUnit",
			Vector3.new(4.5, 2.4, 3.5),
			CFrame.new(-width / 2 + 10 + i * 12, HEIGHT + 2.2, depth / 4),
			Color3.fromRGB(176, 180, 188),
			{ canCollide = false }
		)
	end
	put(
		ctx,
		"Skylight",
		Vector3.new(14, 0.5, 8),
		CFrame.new(width / 5, HEIGHT + 1.3, -depth / 5),
		Color3.fromRGB(170, 205, 230),
		{ material = Enum.Material.Glass, transparency = 0.4, canCollide = false }
	)

	-- Навес с тележками слева (на экране справа) и урны у фасада.
	local cartX = -width / 2 + 4
	put(ctx, "CartRoof", Vector3.new(8, 0.5, 3.5), CFrame.new(cartX, 4.6, frontZ - 4), GREEN)
	for _, x in { cartX - 3.6, cartX + 3.6 } do
		put(ctx, "CartPost", Vector3.new(0.3, 4.5, 0.3), CFrame.new(x, 2.3, frontZ - 4), FRAME)
	end
	for i = 0, 3 do
		put(
			ctx,
			"Cart",
			Vector3.new(2.2, 1.6, 1.4),
			CFrame.new(cartX - 2.8 + i * 1.9, 1.4, frontZ - 4),
			Color3.fromRGB(190, 194, 202),
			{ canCollide = false }
		)
	end
	local binColors =
		{ Color3.fromRGB(60, 168, 72), Color3.fromRGB(60, 100, 190), Color3.fromRGB(240, 200, 40) }
	for index, color in binColors do
		Build.cylinder(
			model,
			1.9,
			2.8,
			(origin * CFrame.new(-width / 2 + 17 + index * 2.4, 1.4, frontZ - 3)).Position,
			color,
			"Y",
			{ name = "Bin" }
		)
	end
	Build.bench(model, origin * CFrame.new(width / 2 - 24, 0.5, frontZ - 3))
end

-- Парковка: асфальт, разметка мест, часть мест занята машинами. center: центр, длинная сторона вдоль Z.
function Supermarket.buildLot(parent: Instance, center: Vector3, width: number, depth: number)
	local folder = Instance.new("Folder")
	folder.Name = "ParkingLot"
	folder.Parent = parent
	Build.part(
		folder,
		Vector3.new(width, 0.4, depth),
		CFrame.new(center.X, 0.2, center.Z),
		Color3.fromRGB(52, 56, 62),
		{ name = "Lot", material = Enum.Material.Asphalt, canCollide = false }
	)
	local slotDepth = 13
	local slotWidth = 6
	local aisle = width - slotDepth * 2
	local random = Random.new(77)
	local rows = math.floor(depth / slotWidth)
	for _, side in { -1, 1 } do
		local slotCenterX = center.X + side * (aisle / 2 + slotDepth / 2)
		for row = 0, rows - 1 do
			local z = center.Z - depth / 2 + slotWidth * (row + 0.5)
			Build.part(
				folder,
				Vector3.new(slotDepth, 0.05, 0.25),
				CFrame.new(slotCenterX, 0.43, z - slotWidth / 2),
				Color3.fromRGB(236, 238, 240),
				{ name = "SlotLine", canCollide = false }
			)
			if random:NextNumber() < 0.55 then
				local color = Vehicles.carColors[random:NextInteger(1, #Vehicles.carColors)]
				local position = Vector3.new(slotCenterX, 0.4, z)
				-- Машина стоит носом к проезду: длина вдоль оси X.
				Vehicles.car(
					folder,
					CFrame.lookAt(position, position + Vector3.new(-side, 0, 0)),
					color
				)
			end
		end
	end
end

return Supermarket
