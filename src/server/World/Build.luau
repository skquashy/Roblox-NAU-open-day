--!strict
-- Помічники для побудови світу кодом (low-poly, у дусі Roblox).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)

local Build = {}

export type Options = {
	material: Enum.Material?,
	transparency: number?,
	shape: Enum.PartType?,
	canCollide: boolean?,
	reflectance: number?,
	name: string?,
}

function Build.part(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: Options?
): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.Color = color
	if options then
		if options.material then
			p.Material = options.material
		end
		if options.transparency then
			p.Transparency = options.transparency
		end
		if options.shape then
			p.Shape = options.shape
		end
		if options.canCollide ~= nil then
			p.CanCollide = options.canCollide
		end
		if options.reflectance then
			p.Reflectance = options.reflectance
		end
		if options.name then
			p.Name = options.name
		end
	end
	p.CFrame = cframe
	p.Parent = parent
	return p
end

-- Циліндр. axis: "Y" (стоїть), "Z" або "X" (лежить). Розмір: діаметр і висота (довжина вздовж осі).
function Build.cylinder(
	parent: Instance,
	diameter: number,
	length: number,
	position: Vector3,
	color: Color3,
	axis: string?,
	options: Options?
): Part
	local cframe = CFrame.new(position)
	if axis == nil or axis == "Y" then
		cframe = cframe * CFrame.Angles(0, 0, math.rad(90))
	elseif axis == "Z" then
		cframe = cframe * CFrame.Angles(0, math.rad(90), 0)
	end
	local opts: Options = options or {}
	opts.shape = Enum.PartType.Cylinder
	return Build.part(parent, Vector3.new(length, diameter, diameter), cframe, color, opts)
end

function Build.ball(
	parent: Instance,
	diameter: number,
	position: Vector3,
	color: Color3,
	options: Options?
): Part
	local opts: Options = options or {}
	opts.shape = Enum.PartType.Ball
	return Build.part(
		parent,
		Vector3.new(diameter, diameter, diameter),
		CFrame.new(position),
		color,
		opts
	)
end

function Build.glow(target: BasePart, color: Color3, brightness: number, range: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Parent = target
	return light
end

local PIXELS_PER_STUD = 16

-- Напис на грані деталі (SurfaceGui). Тло прозоре, якщо bg не задано.
function Build.text(
	target: BasePart,
	face: Enum.NormalId,
	text: string,
	textColor: Color3,
	bg: Color3?
)
	local width = target.Size.X
	local height = target.Size.Y
	if face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		width = target.Size.Z
	elseif face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		height = target.Size.Z
	end
	local px = math.min(PIXELS_PER_STUD, 2000 / math.max(width, height))
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = Vector2.new(width * px, height * px)
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	if bg then
		label.BackgroundTransparency = 0
		label.BackgroundColor3 = bg
	end
	label.TextColor3 = textColor
	label.TextScaled = true
	label.TextWrapped = true
	label.FontFace = Theme.font(Enum.FontWeight.Bold)
	label.Text = text
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.1, 0)
	padding.PaddingBottom = UDim.new(0.1, 0)
	padding.Parent = label
end

-- Кімната: підлога, стеля і чотири стіни. Підлога: верх на висоті origin.Y. Повертає модель.
function Build.room(
	parent: Instance,
	origin: Vector3,
	width: number,
	height: number,
	depth: number,
	floorColor: Color3,
	wallColor: Color3,
	ceilingColor: Color3,
	floorMaterial: Enum.Material?,
	wallMaterial: Enum.Material?
): Model
	local model = Instance.new("Model")
	model.Name = "Room"
	model.Parent = parent
	Build.part(
		model,
		Vector3.new(width, 1, depth),
		CFrame.new(origin + Vector3.new(0, -0.5, 0)),
		floorColor,
		{ material = floorMaterial, name = "Floor" }
	)
	Build.part(
		model,
		Vector3.new(width, 1, depth),
		CFrame.new(origin + Vector3.new(0, height + 0.5, 0)),
		ceilingColor,
		{ name = "Ceiling" }
	)
	local wallOptions: Options = { material = wallMaterial }
	Build.part(
		model,
		Vector3.new(width, height, 1),
		CFrame.new(origin + Vector3.new(0, height / 2, -depth / 2 - 0.5)),
		wallColor,
		wallOptions
	)
	Build.part(
		model,
		Vector3.new(width, height, 1),
		CFrame.new(origin + Vector3.new(0, height / 2, depth / 2 + 0.5)),
		wallColor,
		wallOptions
	)
	Build.part(
		model,
		Vector3.new(1, height, depth),
		CFrame.new(origin + Vector3.new(-width / 2 - 0.5, height / 2, 0)),
		wallColor,
		wallOptions
	)
	Build.part(
		model,
		Vector3.new(1, height, depth),
		CFrame.new(origin + Vector3.new(width / 2 + 0.5, height / 2, 0)),
		wallColor,
		wallOptions
	)
	return model
end

-- Вікна на фасаді. faceCFrame: центр грані, -Z дивиться назовні.
function Build.facade(
	parent: Instance,
	faceCFrame: CFrame,
	width: number,
	height: number,
	cols: number,
	rows: number
)
	local cellW = width / cols
	local cellH = height / rows
	for c = 1, cols do
		for r = 1, rows do
			local x = -width / 2 + cellW * (c - 0.5)
			local y = -height / 2 + cellH * (r - 0.5)
			Build.part(
				parent,
				Vector3.new(cellW * 0.78, cellH * 0.72, 0.3),
				faceCFrame * CFrame.new(x, y, -0.1),
				Color3.fromRGB(90, 150, 210),
				{
					material = Enum.Material.Glass,
					transparency = 0.3,
					reflectance = 0.15,
					name = "Window",
				}
			)
		end
	end
end

-- crown: колір крони (за замовчуванням зелений), для осіннього парку передаються жовтий і помаранчевий.
function Build.tree(parent: Instance, position: Vector3, scale: number, crown: Color3?)
	local crownColor = crown or Color3.fromRGB(62, 140, 70)
	Build.cylinder(
		parent,
		1.4 * scale,
		6 * scale,
		position + Vector3.new(0, 3 * scale, 0),
		Color3.fromRGB(110, 78, 50),
		"Y",
		{ name = "Trunk" }
	)
	Build.ball(
		parent,
		9 * scale,
		position + Vector3.new(0, 9 * scale, 0),
		crownColor,
		{ name = "Crown", material = Enum.Material.Grass }
	)
	Build.ball(
		parent,
		6 * scale,
		position + Vector3.new(2 * scale, 12 * scale, 1 * scale),
		crownColor:Lerp(Color3.new(1, 1, 1), 0.12),
		{ name = "Crown2", material = Enum.Material.Grass }
	)
end

-- Паркова лава: дерев'яні рейки на сидінні та спинці, темні металеві боковини з підлокітниками.
-- cframe: центр на землі, -Z дивиться туди, куди «дивиться» той, хто сидить (спинка ззаду, біля +Z).
function Build.bench(parent: Instance, cframe: CFrame)
	local LEAN = math.rad(10) -- спинка та задні стояки відхилені назад (до +Z)
	local wood = Color3.fromRGB(151, 102, 62)
	local metal = Color3.fromRGB(46, 50, 58)
	local woodOptions: Options = { material = Enum.Material.Wood, name = "BenchSlat" }
	for _, z in { -0.75, 0, 0.75 } do
		Build.part(
			parent,
			Vector3.new(7, 0.25, 0.6),
			cframe * CFrame.new(0, 1.5, z),
			wood,
			woodOptions
		)
	end
	for _, y in { 2.2, 2.85, 3.5 } do
		Build.part(
			parent,
			Vector3.new(7, 0.4, 0.2),
			cframe * CFrame.new(0, y, 1.15 + (y - 1.7) * math.tan(LEAN)) * CFrame.Angles(LEAN, 0, 0),
			wood,
			woodOptions
		)
	end
	for _, x in { -3.2, 3.2 } do
		Build.part(
			parent,
			Vector3.new(0.3, 1.5, 0.3),
			cframe * CFrame.new(x, 0.75, -0.9),
			metal,
			{ material = Enum.Material.Metal, name = "BenchLegFront" }
		)
		Build.part(
			parent,
			Vector3.new(0.3, 3.4, 0.3),
			cframe * CFrame.new(x, 1.7, 1.15) * CFrame.Angles(LEAN, 0, 0),
			metal,
			{ material = Enum.Material.Metal, name = "BenchLegBack" }
		)
		Build.part(
			parent,
			Vector3.new(0.3, 0.2, 2.4),
			cframe * CFrame.new(x, 2.2, -0.1),
			metal,
			{ material = Enum.Material.Metal, name = "BenchArm" }
		)
	end
end

-- Урна: темний циліндр із кришкою.
function Build.bin(parent: Instance, position: Vector3)
	Build.cylinder(
		parent,
		1.9,
		2.6,
		position + Vector3.new(0, 1.3, 0),
		Color3.fromRGB(58, 62, 68),
		"Y",
		{ name = "Bin" }
	)
	Build.cylinder(
		parent,
		2.1,
		0.35,
		position + Vector3.new(0, 2.75, 0),
		Color3.fromRGB(38, 40, 46),
		"Y",
		{ name = "BinLid" }
	)
	Build.cylinder(
		parent,
		1.95,
		0.3,
		position + Vector3.new(0, 1.6, 0),
		Color3.fromRGB(150, 154, 160),
		"Y",
		{ name = "BinBand", canCollide = false }
	)
end

-- Ліхтар. lit = false: без джерела світла (для довгих рядів уздовж вулиць, щоб не навантажувати освітлення).
function Build.lamp(parent: Instance, position: Vector3, lit: boolean?)
	Build.cylinder(
		parent,
		0.5,
		9,
		position + Vector3.new(0, 4.5, 0),
		Color3.fromRGB(50, 55, 65),
		"Y",
		{ name = "LampPole" }
	)
	local bulb = Build.ball(
		parent,
		1.6,
		position + Vector3.new(0, 9.4, 0),
		Color3.fromRGB(255, 240, 200),
		{ material = Enum.Material.Neon, name = "LampBulb" }
	)
	if lit ~= false then
		Build.glow(bulb, Color3.fromRGB(255, 235, 190), 1, 24)
	end
end

return Build
