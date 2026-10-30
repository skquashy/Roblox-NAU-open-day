--!strict
-- Самолёт-памятник Ан-26 (двухмоторный турбовинтовой высокоплан) в сине-жёлтой окраске, как на площади КАІ.
-- Собран из деталей Roblox, без внешних ассетов. Размеры в «метрах» реального самолёта (размах 29,2),
-- затем умножаются на scale. cframe: ось фюзеляжа в центре, нос смотрит в -Z.
-- Колёса стоят на GROUND_DROP * scale ниже оси фюзеляжа.

local Build = require(script.Parent.Build)

local An26 = {}

An26.GROUND_DROP = 2.9

local WHITE = Color3.fromRGB(238, 240, 244)
local BLUE = Color3.fromRGB(0, 87, 183)
local YELLOW = Color3.fromRGB(255, 213, 0)
local GLASS = Color3.fromRGB(28, 44, 70)
local DARK = Color3.fromRGB(34, 36, 40)
local METAL = Color3.fromRGB(150, 154, 162)

local FUSE_D = 2.9

function An26.build(parent: Instance, cframe: CFrame, scale: number): Model
	local model = Instance.new("Model")
	model.Name = "An26"
	model.Parent = parent

	local function at(x: number, y: number, z: number): CFrame
		return cframe * CFrame.new(x * scale, y * scale, z * scale)
	end
	local function sz(x: number, y: number, z: number): Vector3
		return Vector3.new(x * scale, y * scale, z * scale)
	end
	local function box(
		name: string,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.name = name
		return Build.part(model, size, cf, color, opts)
	end
	-- Цилиндр вдоль оси Z (фюзеляж, гондолы) и вдоль оси X (колёса)
	local function zCyl(
		name: string,
		d: number,
		length: number,
		x: number,
		y: number,
		z: number,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.shape = Enum.PartType.Cylinder
		return box(
			name,
			sz(length, d, d),
			at(x, y, z) * CFrame.Angles(0, math.rad(90), 0),
			color,
			opts
		)
	end
	local function xCyl(
		name: string,
		d: number,
		length: number,
		x: number,
		y: number,
		z: number,
		color: Color3,
		options: Build.Options?
	): Part
		local opts: Build.Options = options or {}
		opts.shape = Enum.PartType.Cylinder
		return box(name, sz(length, d, d), at(x, y, z), color, opts)
	end

	-- Синяя и жёлтая полосы вдоль борта
	local bands = {
		{ y = -0.5, h = 0.62, color = BLUE },
		{ y = 0.06, h = 0.26, color = YELLOW },
	}
	local function stripes(zc: number, length: number, r: number, yc: number)
		for _, band in bands do
			local x = math.sqrt(math.max(r * r - band.y * band.y, 0.04)) + 0.02
			for _, sx in { -1, 1 } do
				box(
					"Stripe",
					sz(0.06, band.h, length),
					at(sx * x, yc + band.y, zc),
					band.color,
					{ canCollide = false }
				)
			end
		end
	end

	-- Участок фюзеляжа из ступенчатых цилиндров. y1: подъём оси к концу участка. smooth: скругление (нос).
	local function section(
		z0: number,
		z1: number,
		d0: number,
		d1: number,
		y1: number,
		steps: number,
		smooth: boolean
	)
		for i = 1, steps do
			local t0 = (i - 1) / steps
			local t1 = i / steps
			local k = (t0 + t1) / 2
			if smooth then
				k = k * k
			end
			local d = d0 + (d1 - d0) * k
			local a = z0 + (z1 - z0) * t0
			local b = z0 + (z1 - z0) * t1
			local zc = (a + b) / 2
			local length = math.abs(b - a) + 0.04
			local yc = y1 * k
			zCyl("Fuselage", d, length, 0, yc, zc, WHITE)
			if d / 2 > 1.05 then
				stripes(zc, length, d / 2, yc)
			end
		end
	end

	-- Фюзеляж: нос, центральная часть, хвостовой конус
	section(-4.2, 8, FUSE_D, FUSE_D, 0, 1, false)
	section(-4.2, -7.4, FUSE_D, 1.3, 0, 6, true)
	section(8, 13.2, FUSE_D, 0.55, 0.55, 8, false)
	Build.ball(
		model,
		1.3 * scale,
		at(0, 0, -7.4).Position,
		WHITE,
		{ name = "NoseCap", canCollide = false }
	)
	Build.ball(
		model,
		0.55 * scale,
		at(0, 0.55, 13.3).Position,
		DARK,
		{ name = "TailCap", canCollide = false }
	)
	Build.ball(model, 1.35 * scale, at(0, -0.65, -6.2).Position, GLASS, {
		name = "NoseGlazing",
		material = Enum.Material.Glass,
		transparency = 0.1,
		canCollide = false,
	})

	-- Кабина экипажа: лобовые и боковые стёкла
	for _, sx in { -1, 1 } do
		box(
			"Windshield",
			sz(0.85, 0.12, 0.75),
			at(sx * 0.55, 1.3, -4.8) * CFrame.Angles(math.rad(-25), 0, math.rad(-sx * 22)),
			GLASS,
			{ material = Enum.Material.Glass, canCollide = false }
		)
		box(
			"CockpitWindow",
			sz(0.06, 0.5, 0.7),
			at(sx * 1.32, 0.65, -4.6),
			GLASS,
			{ material = Enum.Material.Glass, canCollide = false }
		)
	end

	-- Иллюминаторы салона
	for i = 0, 5 do
		for _, sx in { -1, 1 } do
			box(
				"Window",
				sz(0.06, 0.42, 0.42),
				at(sx * 1.28, 0.55, -2.4 + i * 1.5),
				GLASS,
				{ material = Enum.Material.Glass, canCollide = false }
			)
		end
	end

	-- Крыло: центроплан и пять трапециевидных секций на каждую консоль (высокоплан)
	box("WingCenter", sz(6, 0.5, 4.6), at(0, 1.35, 0.2), WHITE)
	local panels = 5
	local panelWidth = 11.6 / panels
	for i = 1, panels do
		local t = (i - 0.5) / panels
		local chord = 4.6 - 2.6 * t
		local thickness = 0.5 - 0.2 * t
		local x = 3 + panelWidth * (i - 0.5)
		for _, sx in { -1, 1 } do
			local panel = box(
				"Wing",
				sz(panelWidth + 0.04, thickness, chord),
				at(sx * x, 1.35, 2.5 - chord / 2),
				WHITE
			)
			if i == panels then
				panel.Color = BLUE
			end
		end
	end

	-- Двигатели: гондолы, воздухозаборники, обтекатели и четырёхлопастные винты
	for _, sx in { -1, 1 } do
		local ex = sx * 5
		zCyl("Nacelle", 1.25, 5.6, ex, 0.85, -1.6, WHITE)
		zCyl("NacelleBlue", 1.28, 0.7, ex, 0.85, -3.3, BLUE)
		zCyl("NacelleYellow", 1.3, 0.22, ex, 0.85, -2.75, YELLOW)
		box("Intake", sz(0.6, 0.25, 0.6), at(ex, 0.3, -3.9), DARK, { canCollide = false })
		Build.ball(
			model,
			1 * scale,
			at(ex, 0.85, -4.7).Position,
			BLUE,
			{ name = "Spinner", canCollide = false }
		)
		for k = 0, 3 do
			local spin = at(ex, 0.85, -4.95) * CFrame.Angles(0, 0, math.rad(k * 90 + 18))
			box(
				"Blade",
				sz(0.32, 1.15, 0.07),
				spin * CFrame.new(0, 1.075 * scale, 0),
				DARK,
				{ canCollide = false }
			)
			box(
				"BladeTip",
				sz(0.32, 0.3, 0.075),
				spin * CFrame.new(0, 1.8 * scale, 0),
				YELLOW,
				{ canCollide = false }
			)
		end

		-- Основная стойка шасси со сдвоенными колёсами
		box("MainStrut", sz(0.28, 2.45, 0.28), at(ex, -1, -0.4), METAL)
		box("MainAxle", sz(1.3, 0.2, 0.2), at(ex, -2.25, -0.4), METAL)
		for _, off in { -0.4, 0.4 } do
			xCyl("MainWheel", 1.3, 0.45, ex + off, -2.25, -0.4, DARK)
			xCyl("MainHub", 0.6, 0.5, ex + off, -2.25, -0.4, METAL, { canCollide = false })
		end
	end

	-- Носовая стойка
	box("NoseStrut", sz(0.2, 1.2, 0.2), at(0, -1.9, -5.2), METAL)
	for _, off in { -0.28, 0.28 } do
		xCyl("NoseWheel", 0.9, 0.3, off, -2.45, -5.2, DARK)
	end

	-- Хвостовое оперение: киль с сине-жёлтой отделкой и стабилизатор
	local fin = at(0, 3.1, 11.1) * CFrame.Angles(math.rad(16), 0, 0)
	box("Fin", sz(0.4, 4.6, 3.4), fin, WHITE)
	box(
		"FinCap",
		sz(0.42, 1.1, 2.5),
		fin * CFrame.new(0, 1.9 * scale, 0),
		BLUE,
		{ canCollide = false }
	)
	box(
		"FinStripe",
		sz(0.44, 0.22, 3.0),
		fin * CFrame.new(0, 0.9 * scale, 0),
		YELLOW,
		{ canCollide = false }
	)
	for i = 1, 2 do
		local t = (i - 0.5) / 2
		local chord = 2.1 - 0.8 * t
		local x = 0.5 + 2.15 * (i - 0.5)
		for _, sx in { -1, 1 } do
			box("Stabilizer", sz(2.19, 0.2, chord), at(sx * x, 0.35, 13 - chord / 2), WHITE)
		end
	end

	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	return model
end

return An26
