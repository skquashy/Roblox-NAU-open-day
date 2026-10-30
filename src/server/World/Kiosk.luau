--!strict
-- Магазин «Кулиничі»: невеликий кіоск на території кампусу (розміщення погоджено
-- з менеджерами магазину). За фото reference/kulynychi.webp: темно-сірі панелі, дерев'яні рейки,
-- великі вікна, вивіска з назвою, жовті стільці на терасі. Всередині видно крізь прозоре скло:
-- прилавок із вітриною випічки, кавомашина, холодильник із напоями та полиці.
-- Логотип-герб із фото не відтворюється: замість нього простий круглий знак; справжній логотип можна
-- додати зображенням, коли буде PNG з дозволом на використання.
-- Усередину кіоска гравець не заходить: вікна й двері скляні, але непрохідні.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Build)

local Kiosk = {}

export type Rect = { x: number, z: number, hx: number, hz: number }

local WIDTH = 22
local DEPTH = 12
local HEIGHT = 10
local FLOOR = 0.4
local WALL = 0.6
local DARK = Color3.fromRGB(62, 66, 72)
local DARKER = Color3.fromRGB(48, 50, 56)
local WOOD = Color3.fromRGB(200, 140, 70)
local GLASS = Color3.fromRGB(196, 220, 232)
local CREAM = Color3.fromRGB(244, 236, 206)
local YELLOW = Color3.fromRGB(240, 204, 40)
local INNER_FLOOR = FLOOR + 0.1
local BOTTLES = {
	Color3.fromRGB(240, 150, 40),
	Color3.fromRGB(90, 160, 70),
	Color3.fromRGB(200, 50, 50),
	Color3.fromRGB(60, 110, 200),
	Color3.fromRGB(230, 210, 60),
}
local PACKS = {
	Color3.fromRGB(214, 60, 60),
	Color3.fromRGB(240, 190, 40),
	Color3.fromRGB(70, 120, 210),
	Color3.fromRGB(80, 170, 90),
	Color3.fromRGB(232, 65, 142),
}

type Context = { model: Model, origin: CFrame }

local function item(
	ctx: Context,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	return Build.part(ctx.model, size, ctx.origin * offset, color, {
		name = name,
		canCollide = false,
		material = material or Enum.Material.SmoothPlastic,
	})
end

local function disc(
	ctx: Context,
	name: string,
	diameter: number,
	height: number,
	position: Vector3,
	color: Color3
)
	Build.cylinder(
		ctx.model,
		diameter,
		height,
		(ctx.origin * CFrame.new(position)).Position,
		color,
		"Y",
		{ name = name, canCollide = false }
	)
end

local function up(base: Vector3, y: number): Vector3
	return base + Vector3.new(0, y, 0)
end

-- Продукти. base: точка на поверхні, куди ставимо (низ предмета, центр основи). Розмір кожного
-- предмета не більший за його footprint з KINDS, тому сусіди в ряду не перетинаються.
local function bun(ctx: Context, base: Vector3, _random: Random)
	disc(ctx, "Bun", 1.5, 0.6, up(base, 0.3), Color3.fromRGB(214, 160, 90))
	disc(ctx, "BunTop", 1.15, 0.3, up(base, 0.75), Color3.fromRGB(190, 130, 66))
	local seeds = {
		Vector3.new(-0.25, 0, -0.1),
		Vector3.new(0.25, 0, 0.05),
		Vector3.new(0, 0, 0.3),
		Vector3.new(-0.1, 0, 0.2),
	}
	for _, seed in seeds do
		item(
			ctx,
			"Sesame",
			Vector3.new(0.1, 0.06, 0.1),
			CFrame.new(up(base, 0.93) + seed),
			Color3.fromRGB(250, 240, 210)
		)
	end
end

local function croissant(ctx: Context, base: Vector3, _random: Random)
	local color = Color3.fromRGB(222, 170, 70)
	local dark = Color3.fromRGB(196, 140, 52)
	item(ctx, "Croissant", Vector3.new(1, 0.6, 0.7), CFrame.new(up(base, 0.3)), color)
	for _, sign in { -1, 1 } do
		item(
			ctx,
			"CroissantMid",
			Vector3.new(0.9, 0.55, 0.6),
			CFrame.new(up(base, 0.28) + Vector3.new(sign * 0.85, 0, 0.18))
				* CFrame.Angles(0, sign * math.rad(25), 0),
			dark
		)
		item(
			ctx,
			"CroissantTip",
			Vector3.new(0.6, 0.4, 0.45),
			CFrame.new(up(base, 0.2) + Vector3.new(sign * 1.35, 0, 0.5))
				* CFrame.Angles(0, sign * math.rad(50), 0),
			color
		)
	end
end

local function donut(ctx: Context, base: Vector3, random: Random)
	disc(ctx, "Donut", 1.6, 0.45, up(base, 0.225), Color3.fromRGB(170, 110, 60))
	disc(ctx, "DonutGlaze", 1.6, 0.15, up(base, 0.525), Color3.fromRGB(232, 120, 170))
	disc(ctx, "DonutHole", 0.5, 0.2, up(base, 0.63), Color3.fromRGB(40, 30, 28))
	local sprinkles = {
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(80, 170, 230),
		Color3.fromRGB(250, 220, 60),
	}
	for i = 1, 6 do
		local angle = i / 6 * math.pi * 2
		local radius = 0.55 + random:NextNumber(0, 0.1)
		item(
			ctx,
			"Sprinkle",
			Vector3.new(0.14, 0.05, 0.05),
			CFrame.new(
				up(base, 0.64) + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			) * CFrame.Angles(0, angle, 0),
			sprinkles[(i % #sprinkles) + 1]
		)
	end
end

local function cake(ctx: Context, base: Vector3, _random: Random)
	local sponge = Color3.fromRGB(120, 70, 50)
	local cream = Color3.fromRGB(250, 240, 215)
	item(ctx, "CakeSponge", Vector3.new(1.6, 0.4, 1.2), CFrame.new(up(base, 0.2)), sponge)
	item(ctx, "CakeCream", Vector3.new(1.6, 0.15, 1.2), CFrame.new(up(base, 0.475)), cream)
	item(ctx, "CakeSpongeTop", Vector3.new(1.6, 0.4, 1.2), CFrame.new(up(base, 0.75)), sponge)
	disc(ctx, "CakeTopCream", 0.9, 0.15, up(base, 1.025), cream)
	Build.ball(
		ctx.model,
		0.35,
		(ctx.origin * CFrame.new(up(base, 1.28))).Position,
		Color3.fromRGB(200, 30, 50),
		{ name = "Cherry", canCollide = false }
	)
end

local function sandwich(ctx: Context, base: Vector3, _random: Random)
	local bread = Color3.fromRGB(226, 190, 120)
	item(ctx, "Bread", Vector3.new(2, 0.3, 1.1), CFrame.new(up(base, 0.15)), bread)
	item(
		ctx,
		"Salad",
		Vector3.new(2.15, 0.15, 1.2),
		CFrame.new(up(base, 0.375)),
		Color3.fromRGB(100, 170, 70)
	)
	item(
		ctx,
		"Tomato",
		Vector3.new(1.9, 0.15, 1),
		CFrame.new(up(base, 0.525)),
		Color3.fromRGB(210, 60, 50)
	)
	item(
		ctx,
		"Ham",
		Vector3.new(2, 0.18, 1.1),
		CFrame.new(up(base, 0.69)),
		Color3.fromRGB(230, 140, 140)
	)
	item(ctx, "BreadTop", Vector3.new(2, 0.3, 1.1), CFrame.new(up(base, 0.93)), bread)
end

local function cup(ctx: Context, base: Vector3, _random: Random)
	disc(ctx, "Cup", 0.9, 1.2, up(base, 0.6), Color3.fromRGB(245, 245, 245))
	disc(ctx, "CupSleeve", 0.95, 0.5, up(base, 0.5), Color3.fromRGB(150, 100, 60))
	disc(ctx, "CupLid", 1, 0.12, up(base, 1.26), Color3.fromRGB(50, 50, 55))
end

local function bottle(ctx: Context, base: Vector3, random: Random)
	local color = BOTTLES[random:NextInteger(1, #BOTTLES)]
	disc(ctx, "Bottle", 0.75, 1, up(base, 0.5), color)
	disc(ctx, "BottleLabel", 0.78, 0.4, up(base, 0.5), Color3.fromRGB(245, 245, 240))
	disc(ctx, "BottleShoulder", 0.5, 0.25, up(base, 1.125), color)
	disc(ctx, "BottleNeck", 0.28, 0.15, up(base, 1.325), color)
	disc(ctx, "BottleCap", 0.38, 0.15, up(base, 1.475), Color3.fromRGB(245, 245, 245))
end

local function can(ctx: Context, base: Vector3, random: Random)
	local color = BOTTLES[random:NextInteger(1, #BOTTLES)]
	disc(ctx, "Can", 0.85, 1.2, up(base, 0.6), Color3.fromRGB(200, 204, 210))
	disc(ctx, "CanBand", 0.87, 0.7, up(base, 0.6), color)
	disc(ctx, "CanTop", 0.7, 0.1, up(base, 1.25), Color3.fromRGB(170, 174, 180))
end

local function juiceBox(ctx: Context, base: Vector3, random: Random)
	local color = PACKS[random:NextInteger(1, #PACKS)]
	item(ctx, "JuiceBox", Vector3.new(0.9, 1.3, 0.6), CFrame.new(up(base, 0.65)), color)
	item(
		ctx,
		"JuiceLabel",
		Vector3.new(0.6, 0.5, 0.03),
		CFrame.new(up(base, 0.7) + Vector3.new(0, 0, -0.31)),
		Color3.fromRGB(250, 250, 245)
	)
	item(
		ctx,
		"Straw",
		Vector3.new(0.08, 0.5, 0.08),
		CFrame.new(up(base, 1.5) + Vector3.new(0.2, 0, 0)),
		Color3.fromRGB(240, 240, 240)
	)
end

local function pack(ctx: Context, base: Vector3, random: Random)
	local color = PACKS[random:NextInteger(1, #PACKS)]
	item(ctx, "Pack", Vector3.new(1.2, 1.4, 0.35), CFrame.new(up(base, 0.7)), color)
	item(
		ctx,
		"PackLabel",
		Vector3.new(0.7, 0.5, 0.03),
		CFrame.new(up(base, 0.8) + Vector3.new(0, 0, -0.19)),
		Color3.fromRGB(250, 250, 245)
	)
	for _, y in { 0.02, 1.38 } do
		item(
			ctx,
			"PackSeal",
			Vector3.new(1.2, 0.08, 0.4),
			CFrame.new(up(base, y)),
			Color3.fromRGB(200, 204, 210)
		)
	end
end

local function noodles(ctx: Context, base: Vector3, random: Random)
	local color = PACKS[random:NextInteger(1, #PACKS)]
	disc(ctx, "NoodleCup", 1.3, 1.1, up(base, 0.55), color)
	disc(ctx, "NoodleBand", 1.33, 0.35, up(base, 0.55), Color3.fromRGB(250, 250, 245))
	disc(ctx, "NoodleLid", 1.4, 0.1, up(base, 1.15), Color3.fromRGB(235, 235, 230))
end

type Kind = { width: number, build: (ctx: Context, base: Vector3, random: Random) -> () }

-- width: ширина місця, яке займає, по осі X; сусідні предмети ставляться із проміжком GAP.
local KINDS: { [string]: Kind } = {
	bun = { width = 1.6, build = bun },
	croissant = { width = 3.0, build = croissant },
	donut = { width = 1.7, build = donut },
	cake = { width = 1.7, build = cake },
	sandwich = { width = 2.2, build = sandwich },
	bottle = { width = 0.85, build = bottle },
	can = { width = 0.95, build = can },
	juice = { width = 1.0, build = juiceBox },
	pack = { width = 1.3, build = pack },
	noodles = { width = 1.4, build = noodles },
}
local SNACKS = { "bottle", "can", "juice", "pack", "noodles" }
local GAP = 0.25

-- Ставить предмети поруч у ряд із центром centerX: ширина ряду не більша за maxWidth, предмети не перетинаються.
-- names: заданий порядок; якщо nil, беремо випадкові снеки й напої, поки ряд не заповниться.
local function fillRow(
	ctx: Context,
	names: { string }?,
	centerX: number,
	z: number,
	y: number,
	maxWidth: number,
	random: Random
)
	local chosen: { string } = {}
	local total = 0
	local index = 0
	while true do
		index += 1
		local name = SNACKS[random:NextInteger(1, #SNACKS)]
		if names then
			if index > #names then
				break
			end
			name = names[index]
		end
		local width = KINDS[name].width
		local extra = width
		if #chosen > 0 then
			extra = width + GAP
		end
		if total + extra > maxWidth then
			break
		end
		table.insert(chosen, name)
		total += extra
	end
	local x = centerX - total / 2
	for _, name in chosen do
		local kind = KINDS[name]
		kind.build(ctx, Vector3.new(x + kind.width / 2, y, z), random)
		x += kind.width + GAP
	end
end

local function chair(parent: Instance, origin: CFrame, x: number, z: number, yaw: number)
	local base = origin * CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	Build.part(
		parent,
		Vector3.new(1.4, 0.2, 1.4),
		base * CFrame.new(0, 1.6, 0),
		YELLOW,
		{ name = "ChairSeat" }
	)
	Build.part(
		parent,
		Vector3.new(1.4, 1.4, 0.2),
		base * CFrame.new(0, 2.4, 0.6),
		YELLOW,
		{ name = "ChairBack" }
	)
	for _, lx in { -0.6, 0.6 } do
		for _, lz in { -0.6, 0.6 } do
			Build.part(
				parent,
				Vector3.new(0.2, 1.5, 0.2),
				base * CFrame.new(lx, 0.75, lz),
				DARKER,
				{ name = "ChairLeg" }
			)
		end
	end
end

-- Внутрішнє оздоблення: полиці з напоями та снеками, холодильник, прилавок із вітриною та кавомашиною.
-- Розміри підібрано так, що полиці, холодильник і прилавок не перетинаються: холодильник у лівому задньому
-- куті (x від -10.4 до -6), полиці правіше (x від -4.6 до 10.2), прилавок перед полицями (z від -1.4 до 1.8).
local function buildInterior(ctx: Context, random: Random)
	local function box(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3,
		material: Enum.Material?
	): Part
		return item(ctx, name, size, CFrame.new(offset), color, material)
	end
	local steel = Color3.fromRGB(200, 204, 210)

	-- Стелаж уздовж задньої стіни: боковини, три полиці, на кожній ряд напоїв і снеків.
	local shelfX, shelfWidth = 2.8, 14.8
	local backZ = DEPTH / 2 - WALL
	for _, sideX in { shelfX - shelfWidth / 2, shelfX + shelfWidth / 2 } do
		box(
			"ShelfSide",
			Vector3.new(0.2, 6, 1.8),
			Vector3.new(sideX, INNER_FLOOR + 5.2, backZ - 0.9),
			DARKER
		)
	end
	for _, shelfY in { 3.2, 5.2, 7.2 } do
		box(
			"Shelf",
			Vector3.new(shelfWidth, 0.25, 1.8),
			Vector3.new(shelfX, shelfY, backZ - 0.9),
			WOOD,
			Enum.Material.WoodPlanks
		)
		fillRow(ctx, nil, shelfX, backZ - 0.9, shelfY + 0.125, shelfWidth - 0.6, random)
	end
	-- Дошка меню над стелажем: кольорові смужки замість тексту.
	box(
		"MenuBoard",
		Vector3.new(13.5, 1, 0.1),
		Vector3.new(shelfX, 9.5, backZ - 0.05),
		Color3.fromRGB(30, 32, 36)
	)
	local menuLines = { 5, 3.5, 6, 4 }
	for index, width in menuLines do
		local column = (index - 1) % 2
		local x = shelfX - 6 + width / 2 + column * 6.5
		local y = 9.75 - math.floor((index - 1) / 2) * 0.45
		box("MenuLine", Vector3.new(width, 0.12, 0.05), Vector3.new(x, y, backZ - 0.14), CREAM)
	end

	-- Холодильник у лівому задньому куті: каркас із відкритим фронтом, полиці з пляшками, скляні дверцята.
	local fridgeX, fridgeZ = -8.2, 4.2
	local fridgeBottom = INNER_FLOOR
	box(
		"FridgeBack",
		Vector3.new(4.4, 6.4, 0.2),
		Vector3.new(fridgeX, fridgeBottom + 3.2, fridgeZ + 1.1),
		steel
	)
	for _, sideX in { fridgeX - 2.1, fridgeX + 2.1 } do
		box(
			"FridgeSide",
			Vector3.new(0.2, 6.4, 2.4),
			Vector3.new(sideX, fridgeBottom + 3.2, fridgeZ),
			steel
		)
	end
	box(
		"FridgeTop",
		Vector3.new(4.4, 0.2, 2.4),
		Vector3.new(fridgeX, fridgeBottom + 6.5, fridgeZ),
		steel
	)
	box(
		"FridgeBottom",
		Vector3.new(4.4, 0.2, 2.4),
		Vector3.new(fridgeX, fridgeBottom + 0.1, fridgeZ),
		steel
	)
	for _, boardY in { 1.2, 2.9, 4.6 } do
		box(
			"FridgeShelf",
			Vector3.new(4, 0.1, 2.2),
			Vector3.new(fridgeX, fridgeBottom + boardY, fridgeZ),
			Color3.fromRGB(230, 232, 236)
		)
		for _, rowZ in { fridgeZ - 0.6, fridgeZ + 0.6 } do
			for i = 0, 3 do
				bottle(
					ctx,
					Vector3.new(fridgeX - 1.425 + i * 0.95, fridgeBottom + boardY + 0.05, rowZ),
					random
				)
			end
		end
	end
	local led = box(
		"FridgeLight",
		Vector3.new(4, 0.12, 0.1),
		Vector3.new(fridgeX, fridgeBottom + 6.3, fridgeZ - 1.1),
		Color3.fromRGB(180, 230, 255),
		Enum.Material.Neon
	)
	Build.glow(led, Color3.fromRGB(180, 230, 255), 0.5, 10)
	local fridgeGlass = box(
		"FridgeGlass",
		Vector3.new(4.2, 6.2, 0.12),
		Vector3.new(fridgeX, fridgeBottom + 3.2, fridgeZ - 1.25),
		Color3.fromRGB(190, 220, 235),
		Enum.Material.Glass
	)
	fridgeGlass.Transparency = 0.7
	box(
		"FridgeHandle",
		Vector3.new(0.15, 2.4, 0.15),
		Vector3.new(fridgeX + 1.8, fridgeBottom + 3.2, fridgeZ - 1.4),
		DARKER
	)

	-- Прилавок: тумба з дерев'яними панелями та темною стільницею.
	local counterX, counterZ = 4.6, 0.2
	local topY = INNER_FLOOR + 3.5
	box(
		"Counter",
		Vector3.new(11.2, 3.3, 3.2),
		Vector3.new(counterX, INNER_FLOOR + 1.65, counterZ),
		Color3.fromRGB(120, 84, 56),
		Enum.Material.WoodPlanks
	)
	box(
		"CounterToeKick",
		Vector3.new(11.2, 0.3, 3.3),
		Vector3.new(counterX, INNER_FLOOR + 0.15, counterZ),
		DARKER
	)
	box(
		"CounterTop",
		Vector3.new(11.6, 0.2, 3.5),
		Vector3.new(counterX, topY - 0.1, counterZ),
		Color3.fromRGB(70, 72, 78)
	)

	-- Вітрина: скляна рамка, два ряди випічки на лотках без перетинів.
	local caseX, caseWidth, caseDepth = 2.9, 8, 2.8
	local caseHeight = 2.2
	local rows = {
		{ z = counterZ + 0.7, names = { "croissant", "cake", "cake" } },
		{ z = counterZ - 0.7, names = { "bun", "donut", "bun", "donut" } },
	}
	for _, row in rows do
		box(
			"Tray",
			Vector3.new(caseWidth - 0.8, 0.08, 1.3),
			Vector3.new(caseX, topY + 0.04, row.z),
			Color3.fromRGB(240, 232, 216)
		)
		fillRow(ctx, row.names, caseX, row.z, topY + 0.08, caseWidth - 0.8, random)
	end
	for _, cornerX in { caseX - caseWidth / 2, caseX + caseWidth / 2 } do
		for _, cornerZ in { counterZ - caseDepth / 2, counterZ + caseDepth / 2 } do
			box(
				"CasePost",
				Vector3.new(0.15, caseHeight, 0.15),
				Vector3.new(cornerX, topY + caseHeight / 2, cornerZ),
				steel
			)
		end
	end
	box(
		"CaseTopFrame",
		Vector3.new(caseWidth + 0.15, 0.12, caseDepth + 0.15),
		Vector3.new(caseX, topY + caseHeight, counterZ),
		steel
	)
	local caseGlass = box(
		"CaseGlass",
		Vector3.new(caseWidth, caseHeight - 0.2, 0.1),
		Vector3.new(caseX, topY + caseHeight / 2, counterZ - caseDepth / 2),
		Color3.fromRGB(196, 220, 232),
		Enum.Material.Glass
	)
	caseGlass.Transparency = 0.8

	-- Кавомашина праворуч і стаканчики перед нею; каса ліворуч.
	local machineX, machineZ = 9, 1
	box(
		"CoffeeBody",
		Vector3.new(2.4, 2.2, 1.6),
		Vector3.new(machineX, topY + 1.1, machineZ),
		Color3.fromRGB(40, 42, 48)
	)
	box(
		"CoffeeTop",
		Vector3.new(2.5, 0.25, 1.7),
		Vector3.new(machineX, topY + 2.3, machineZ),
		steel
	)
	for _, spoutX in { machineX - 0.5, machineX + 0.5 } do
		disc(ctx, "CoffeeSpout", 0.25, 0.5, Vector3.new(spoutX, topY + 1.5, machineZ - 0.7), steel)
	end
	box(
		"CoffeeLight",
		Vector3.new(0.35, 0.35, 0.05),
		Vector3.new(machineX, topY + 1.8, machineZ - 0.82),
		Color3.fromRGB(220, 50, 50),
		Enum.Material.Neon
	)
	box(
		"DripTray",
		Vector3.new(2, 0.12, 0.7),
		Vector3.new(machineX, topY + 0.06, machineZ - 1.05),
		steel
	)
	for i = 0, 2 do
		cup(ctx, Vector3.new(7.55 + i * 1.05, topY, -0.7), random)
	end
	box("Register", Vector3.new(1.4, 0.9, 1.1), Vector3.new(0.3, topY + 0.45, 0.9), DARKER)
	box(
		"RegisterScreen",
		Vector3.new(1, 0.7, 0.1),
		Vector3.new(0.3, topY + 1.2, 0.5),
		Color3.fromRGB(70, 140, 190),
		Enum.Material.Neon
	)
	box(
		"CardTerminal",
		Vector3.new(0.5, 0.15, 0.8),
		Vector3.new(0.3, topY + 0.07, -0.6),
		Color3.fromRGB(150, 154, 160)
	)
	box(
		"NapkinBox",
		Vector3.new(0.9, 0.6, 0.6),
		Vector3.new(-0.6, topY + 0.3, -1.0),
		Color3.fromRGB(230, 230, 225)
	)

	-- Тепле світло всередині, щоб товари було видно крізь вікна.
	local lamp = Build.part(
		ctx.model,
		Vector3.new(4, 0.15, 1),
		ctx.origin * CFrame.new(0, FLOOR + HEIGHT - 0.6, 0),
		Color3.fromRGB(255, 244, 214),
		{ name = "CeilingLight", material = Enum.Material.Neon, canCollide = false }
	)
	Build.glow(lamp, Color3.fromRGB(255, 236, 200), 1.2, 18)
end

-- Будує кіоск: origin на землі в центрі, -Z дивиться на вхід. Повертає зайняту область (у світі).
function Kiosk.build(parent: Instance, origin: CFrame): Rect
	local model = Instance.new("Model")
	model.Name = "Kiosk_kulynychi"
	model.Parent = parent
	local ctx: Context = { model = model, origin = origin }

	local frontZ = -DEPTH / 2
	local function part(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, size, origin * CFrame.new(offset), color, opts)
	end

	-- Оболонка: підлога, задня та бокові стіни, стеля, дах. Передня стіна збирається з простінків і стекол.
	part(
		"Floor",
		Vector3.new(WIDTH + 2, FLOOR, DEPTH + 2),
		Vector3.new(0, FLOOR / 2, 0),
		Color3.fromRGB(150, 152, 158),
		{ material = Enum.Material.Pavement }
	)
	part(
		"FloorInner",
		Vector3.new(WIDTH - 2 * WALL, 0.1, DEPTH - 2 * WALL),
		Vector3.new(0, FLOOR + 0.05, 0),
		Color3.fromRGB(214, 208, 198)
	)
	part(
		"BackWall",
		Vector3.new(WIDTH, HEIGHT, WALL),
		Vector3.new(0, FLOOR + HEIGHT / 2, DEPTH / 2 - WALL / 2),
		DARK
	)
	for _, side in { -1, 1 } do
		part(
			"SideWall",
			Vector3.new(WALL, HEIGHT, DEPTH),
			Vector3.new(side * (WIDTH / 2 - WALL / 2), FLOOR + HEIGHT / 2, 0),
			DARK
		)
	end
	part(
		"Ceiling",
		Vector3.new(WIDTH, 0.5, DEPTH),
		Vector3.new(0, FLOOR + HEIGHT - 0.25, 0),
		DARKER
	)
	part(
		"Roof",
		Vector3.new(WIDTH + 3, 1, DEPTH + 3),
		Vector3.new(0, FLOOR + HEIGHT + 0.5, 0),
		DARKER
	)
	-- Стіна над вікнами та під ними (отвір дверей залишається скляним).
	local frontWallZ = frontZ + WALL / 2
	part(
		"Header",
		Vector3.new(WIDTH, 4, WALL),
		Vector3.new(0, FLOOR + 8.4 - FLOOR, frontWallZ),
		DARK
	)
	part(
		"LowWallLeft",
		Vector3.new(5.6, 2.2, WALL),
		Vector3.new(-8.2, FLOOR + 1.1, frontWallZ),
		DARK
	)
	part(
		"LowWallRight",
		Vector3.new(13, 2.2, WALL),
		Vector3.new(4.5, FLOOR + 1.1, frontWallZ),
		DARK
	)

	-- Вивіска з назвою та круглим знаком ліворуч.
	local sign = part(
		"Sign",
		Vector3.new(WIDTH - 1, 2.8, 0.6),
		Vector3.new(0, FLOOR + HEIGHT - 1.7, frontZ - 0.3),
		DARKER
	)
	Build.text(sign, Enum.NormalId.Front, Locale.translate("uk", "shop.kulynychi.name"), CREAM, nil)
	local badgeZ = frontZ - 0.8
	Build.cylinder(
		model,
		3.4,
		0.4,
		(origin * CFrame.new(-WIDTH / 2 + 2.4, FLOOR + HEIGHT - 1.7, badgeZ)).Position,
		Color3.fromRGB(226, 178, 52),
		"Z",
		{ name = "BadgeRing", canCollide = false }
	)
	Build.cylinder(
		model,
		2.8,
		0.5,
		(origin * CFrame.new(-WIDTH / 2 + 2.4, FLOOR + HEIGHT - 1.7, badgeZ - 0.05)).Position,
		Color3.fromRGB(34, 69, 151),
		"Z",
		{ name = "BadgeDisc", canCollide = false }
	)

	-- Дерев'яні рейки: нижня смуга (крім отвору дверей) і верхня під вивіскою.
	local wallZ = frontZ - 0.25
	part("WoodLowLeft", Vector3.new(5.6, 2.2, 0.5), Vector3.new(-8.2, FLOOR + 1.1, wallZ), WOOD)
	part("WoodLowRight", Vector3.new(13, 2.2, 0.5), Vector3.new(4.5, FLOOR + 1.1, wallZ), WOOD)
	part("WoodTop", Vector3.new(WIDTH, 1, 0.5), Vector3.new(0, FLOOR + 6.9, wallZ), WOOD)

	-- Вікна та двері: прозоре скло, між ними сірі простінки.
	local glassY = FLOOR + 4.5
	local openings = {
		{ x = -8.25, width = 4.5 },
		{ x = 3.1, width = 9 },
		{ x = 9.6, width = 2.8 },
	}
	for _, opening in openings do
		part(
			"Window",
			Vector3.new(opening.width, 3.8, 0.2),
			Vector3.new(opening.x, glassY, frontZ - 0.1),
			GLASS,
			{ material = Enum.Material.Glass, transparency = 0.7, reflectance = 0.05 }
		)
	end
	for _, pillarX in { -5.7, -1.7, 7.9 } do
		part(
			"Pillar",
			Vector3.new(0.6, 6.4, 0.7),
			Vector3.new(pillarX, FLOOR + 3.2, frontZ - 0.35),
			Color3.fromRGB(70, 74, 80)
		)
	end
	part(
		"Door",
		Vector3.new(3.4, 6, 0.2),
		Vector3.new(-3.7, FLOOR + 3, frontZ - 0.1),
		GLASS,
		{ material = Enum.Material.Glass, transparency = 0.7 }
	)
	part(
		"DoorHandle",
		Vector3.new(0.3, 1.2, 0.3),
		Vector3.new(-2.5, FLOOR + 3, frontZ - 0.65),
		Color3.fromRGB(140, 80, 60),
		{ canCollide = false }
	)

	buildInterior(ctx, Random.new(1995))

	-- Тераса: столик і два жовті стільці обличчям до столу, урна ліворуч біля стіни.
	local terraceZ = frontZ - 4.5
	local tableX = 4
	part("TableTop", Vector3.new(2.6, 0.2, 2.6), Vector3.new(tableX, 2.6, terraceZ), WOOD)
	part("TableLeg", Vector3.new(0.4, 2.4, 0.4), Vector3.new(tableX, 1.4, terraceZ), DARKER)
	chair(model, origin, tableX - 2.6, terraceZ, math.rad(-90))
	chair(model, origin, tableX + 2.6, terraceZ, math.rad(90))
	part(
		"Bin",
		Vector3.new(1.8, 3.2, 1.8),
		Vector3.new(-WIDTH / 2 - 1.5, 1.6, frontZ - 1.5),
		Color3.fromRGB(150, 154, 160)
	)

	-- Місце для продавця-NPC біля входу.
	local spot = Build.part(
		model,
		Vector3.new(3, 0.2, 3),
		origin * CFrame.new(-3.7, 0.5, frontZ - 3.5),
		Color3.new(1, 1, 1),
		{ name = "NpcSpot_shop_1", transparency = 1, canCollide = false }
	)
	spot:SetAttribute("NpcSpot", "shop_1")

	local position = origin.Position
	return { x = position.X, z = position.Z, hx = WIDTH / 2 + 4, hz = DEPTH / 2 + 8 }
end

return Kiosk
