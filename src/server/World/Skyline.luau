--!strict
-- Тло навколо кампусу: замість порожнього горизонту (моря) міська панорама Києва: кільця житлових і офісних
-- будинків на різній відстані та кілька впізнаваних силуетів (телевежа, дзвіниця із золотими банями,
-- монумент). Це декорація, розташування орієнтирів не топографічне.
-- Усе лежить у моделі з ModelStreamingMode = Persistent: інакше StreamingEnabled не показує далекі об'єкти.

local Build = require(script.Parent.Build)
local Apartment = require(script.Parent.Buildings.Apartment)

local Skyline = {}

local PALETTE = {
	Color3.fromRGB(222, 210, 184),
	Color3.fromRGB(170, 185, 200),
	Color3.fromRGB(235, 235, 230),
	Color3.fromRGB(190, 130, 110),
	Color3.fromRGB(150, 152, 158),
	Color3.fromRGB(226, 205, 140),
	Color3.fromRGB(170, 100, 80),
	Color3.fromRGB(180, 180, 176),
}
local WINDOWS = Color3.fromRGB(80, 104, 138)
local FLOOR_BAND = 26 -- через скільки стадів по висоті темна смуга вікон

-- Кільце будинків навколо center: count штук на відстані від minRadius до maxRadius.
local function ring(
	model: Model,
	random: Random,
	center: Vector3,
	count: number,
	minRadius: number,
	maxRadius: number,
	minHeight: number,
	maxHeight: number,
	maxWidth: number
)
	for i = 1, count do
		if random:NextNumber() > 0.12 then -- іноді пропуски, щоб кільце не було стіною
			local angle = (i + random:NextNumber(-0.4, 0.4)) / count * math.pi * 2
			local radius = random:NextNumber(minRadius, maxRadius)
			local width = random:NextNumber(maxWidth * 0.5, maxWidth)
			local depth = random:NextNumber(maxWidth * 0.4, maxWidth * 0.8)
			local height = random:NextNumber(minHeight, maxHeight)
			local position = center
				+ Vector3.new(math.cos(angle) * radius, height / 2, math.sin(angle) * radius)
			local cframe = CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
			local color = PALETTE[random:NextInteger(1, #PALETTE)]
			Build.part(
				model,
				Vector3.new(width, height, depth),
				cframe,
				color,
				{ name = "Tower", material = Enum.Material.Concrete, canCollide = false }
			)
			Build.part(
				model,
				Vector3.new(width + 3, 8, depth + 3),
				cframe * CFrame.new(0, -height / 2 + 4, 0),
				Color3.fromRGB(112, 108, 104),
				{ name = "Plinth", material = Enum.Material.Concrete, canCollide = false }
			)
			local bands = math.floor(height / FLOOR_BAND)
			for k = 1, bands do
				local y = -height / 2 + (k - 0.5) * (height / bands)
				Build.part(
					model,
					Vector3.new(width + 0.6, 7, depth + 0.6),
					cframe * CFrame.new(0, y, 0),
					WINDOWS,
					{ name = "Windows", canCollide = false }
				)
			end
			if random:NextNumber() < 0.4 then
				Build.part(
					model,
					Vector3.new(width * 0.5, 10, depth * 0.5),
					cframe * CFrame.new(0, height / 2 + 5, 0),
					Color3.fromRGB(120, 124, 132),
					{ name = "RoofHouse", canCollide = false }
				)
			end
		end
	end
end

-- Кільце детальних житлових будинків фасадом до центру кампусу (з балконами, цоколем і під'їздами).
local function nearRing(
	model: Model,
	random: Random,
	center: Vector3,
	count: number,
	minRadius: number,
	maxRadius: number
)
	for i = 1, count do
		if random:NextNumber() > 0.1 then
			local angle = (i + random:NextNumber(-0.3, 0.3)) / count * math.pi * 2
			local radius = random:NextNumber(minRadius, maxRadius)
			local ground = Vector3.new(
				center.X + math.cos(angle) * radius,
				0,
				center.Z + math.sin(angle) * radius
			)
			local origin = CFrame.lookAt(ground, Vector3.new(center.X, 0, center.Z))
			Apartment.build(
				model,
				origin,
				random:NextNumber(40, 70),
				random:NextNumber(30, 40),
				random:NextInteger(5, 9),
				{ wall = PALETTE[random:NextInteger(1, #PALETTE)], shops = false, random = random }
			)
		end
	end
end

-- Телевежа: звужений стрижень із двома оглядовими майданчиками та антеною.
local function tvTower(model: Model, base: Vector3)
	local steel = Color3.fromRGB(190, 194, 202)
	local heights = { 120, 100, 80, 60 }
	local widths = { 26, 18, 12, 8 }
	local y = 0
	for index, height in heights do
		Build.part(
			model,
			Vector3.new(widths[index], height, widths[index]),
			CFrame.new(base + Vector3.new(0, y + height / 2, 0)),
			steel,
			{ name = "TvTower", material = Enum.Material.Metal, canCollide = false }
		)
		y += height
	end
	for _, level in { 210, 300 } do
		Build.cylinder(
			model,
			44,
			14,
			base + Vector3.new(0, level, 0),
			Color3.fromRGB(210, 212, 218),
			"Y",
			{ name = "TvPlatform", canCollide = false }
		)
	end
	Build.cylinder(
		model,
		3,
		120,
		base + Vector3.new(0, y + 60, 0),
		Color3.fromRGB(220, 60, 60),
		"Y",
		{ name = "TvAntenna", canCollide = false }
	)
end

-- Дзвіниця із золотою банею та два менші храми.
local function bellTower(model: Model, base: Vector3)
	local wall = Color3.fromRGB(240, 238, 228)
	local gold = Color3.fromRGB(232, 184, 56)
	Build.part(
		model,
		Vector3.new(34, 130, 34),
		CFrame.new(base + Vector3.new(0, 65, 0)),
		wall,
		{ name = "BellTower", canCollide = false }
	)
	Build.ball(model, 40, base + Vector3.new(0, 150, 0), gold, {
		name = "BellDome",
		material = Enum.Material.Metal,
		canCollide = false,
	})
	for _, offset in { Vector3.new(-90, 0, 40), Vector3.new(80, 0, -30) } do
		Build.part(
			model,
			Vector3.new(50, 50, 50),
			CFrame.new(base + offset + Vector3.new(0, 25, 0)),
			wall,
			{ name = "Church", canCollide = false }
		)
		Build.ball(model, 36, base + offset + Vector3.new(0, 66, 0), gold, {
			name = "ChurchDome",
			material = Enum.Material.Metal,
			canCollide = false,
		})
	end
end

-- Монумент: постамент і витягнута фігура з піднятою рукою.
local function monument(model: Model, base: Vector3)
	local stone = Color3.fromRGB(150, 153, 160)
	local steel = Color3.fromRGB(196, 202, 210)
	Build.part(
		model,
		Vector3.new(70, 80, 70),
		CFrame.new(base + Vector3.new(0, 40, 0)),
		stone,
		{ name = "MonumentBase", canCollide = false }
	)
	Build.part(
		model,
		Vector3.new(20, 90, 14),
		CFrame.new(base + Vector3.new(0, 125, 0)),
		steel,
		{ name = "MonumentFigure", material = Enum.Material.Metal, canCollide = false }
	)
	Build.ball(model, 16, base + Vector3.new(0, 180, 0), steel, {
		name = "MonumentHead",
		material = Enum.Material.Metal,
		canCollide = false,
	})
	Build.part(
		model,
		Vector3.new(4, 60, 4),
		CFrame.new(base + Vector3.new(-14, 190, 0)) * CFrame.Angles(0, 0, math.rad(25)),
		steel,
		{ name = "MonumentSword", material = Enum.Material.Metal, canCollide = false }
	)
end

-- Будує панораму навколо точки center (центр кампусу). Повертає модель.
function Skyline.build(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Skyline"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = parent

	-- Земля за межами кампусу: велика площина трохи нижче за кампусну траву.
	Build.part(
		model,
		Vector3.new(7000, 2, 7000),
		CFrame.new(center.X, -1.05, center.Z),
		Color3.fromRGB(112, 142, 102),
		{ name = "Outskirts" }
	)

	local random = Random.new(2026)
	nearRing(model, random, center, 28, 620, 820) -- ближні детальні будинки (5-9 поверхів)
	ring(model, random, center, 90, 900, 1300, 60, 180, 110) -- середній пояс
	ring(model, random, center, 120, 1350, 2300, 110, 320, 140) -- далекі висотки

	tvTower(model, center + Vector3.new(-1500, 0, -1900))
	bellTower(model, center + Vector3.new(1250, 0, -1650))
	monument(model, center + Vector3.new(2000, 0, 450))
	return model
end

return Skyline
