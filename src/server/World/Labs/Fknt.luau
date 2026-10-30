--!strict
-- Обстановка лабораторії ФКНТ для мінігри «Кіберзахист»: у центрі голографічна мережа (хаб і шість вузлів
-- з променями), перед нею три великі кнопки (патч, блок IP, перезапуск) і табло статусу, біля стін серверні
-- стійки та шлюз «Інтернет». Деталі з іменами Hub, Node1..6, Beam1..6, ButtonPatch/Block/Restart і
-- StatusLabel використовує Missions/fknt: сервер ставить загрози на вузли, фарбує промені, читає натискання кнопок.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Parent.Build)

local Fknt = {}

Fknt.NODE_COUNT = 6
Fknt.RACK_COUNT = 4
Fknt.BEAM_COLOR = Color3.fromRGB(70, 190, 255)

local TABLE_Z = 3 -- центр голограми відносно середини павільйону
local NODE_RING = 4.6
local NODE_HEIGHT = 5.6
local BUTTONS = {
	{
		name = "ButtonPatch",
		key = "mg.fknt.btn.patch",
		action = "patch",
		color = Color3.fromRGB(34, 69, 151),
		x = -6.5,
	},
	{
		name = "ButtonBlock",
		key = "mg.fknt.btn.block",
		action = "block",
		color = Color3.fromRGB(200, 40, 50),
		x = 0,
	},
	{
		name = "ButtonRestart",
		key = "mg.fknt.btn.restart",
		action = "restart",
		color = Color3.fromRGB(44, 48, 56),
		x = 6.5,
	},
}

local function bilingual(key: string): string
	return Locale.translate("uk", key) .. " / " .. Locale.translate("en", key)
end

function Fknt.dress(model: Model, origin: CFrame, size: Vector3)
	local width, height, depth = size.X, size.Y, size.Z
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

	-- Шлюз «Інтернет» у бічній стіні: світна рама (декорація, пакети більше не летять).
	local gatewayX = width / 2 - 1.6
	put(
		"Gateway",
		Vector3.new(0.5, 6, 5),
		CFrame.new(gatewayX, 4.6, 0),
		Color3.fromRGB(38, 124, 235),
		{ material = Enum.Material.Neon, transparency = 0.35, canCollide = false }
	)
	for _, z in { -2.8, 2.8 } do
		put(
			"GatewayPost",
			Vector3.new(0.7, 7, 0.6),
			CFrame.new(gatewayX, 4.1, z),
			Color3.fromRGB(34, 69, 151)
		)
	end
	put(
		"GatewayTop",
		Vector3.new(0.7, 0.6, 6.2),
		CFrame.new(gatewayX, 7.6, 0),
		Color3.fromRGB(34, 69, 151)
	)
	local gatewaySign = put(
		"GatewaySign",
		Vector3.new(6, 1.4, 0.2),
		CFrame.new(gatewayX - 0.2, 8.6, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color3.fromRGB(20, 30, 60),
		{ canCollide = false }
	)
	Build.text(
		gatewaySign,
		Enum.NormalId.Front,
		bilingual("mg.fknt.gateway"),
		Color3.new(1, 1, 1),
		nil
	)

	-- Серверні стійки біля задньої стіни (декор, обличчям до центру кімнати).
	local rackZ = depth / 2 - 2.4
	for index = 1, Fknt.RACK_COUNT do
		local x = (index - (Fknt.RACK_COUNT + 1) / 2) * 7 * 1.35
		local front = rackZ - 1.5
		put(
			"RackDecor",
			Vector3.new(4.4, 9, 3),
			CFrame.new(x, 4.5 + 0.6, rackZ),
			Color3.fromRGB(40, 44, 52)
		)
		for unit = 0, 4 do
			put(
				"RackUnit",
				Vector3.new(4, 0.9, 0.12),
				CFrame.new(x, 1.6 + unit * 1.1, front - 0.06),
				Color3.fromRGB(70, 76, 90),
				{ canCollide = false }
			)
			put(
				"RackLed",
				Vector3.new(0.3, 0.2, 0.05),
				CFrame.new(x + 1.5, 1.6 + unit * 1.1, front - 0.15),
				Color3.fromRGB(80, 220, 120),
				{ material = Enum.Material.Neon, canCollide = false }
			)
		end
		put(
			"RackTopGlow",
			Vector3.new(3.6, 0.3, 0.15),
			CFrame.new(x, 8.2, front - 0.1),
			Color3.fromRGB(80, 220, 120),
			{ material = Enum.Material.Neon, canCollide = false }
		)
	end

	-- Стіл-проєктор і голографічна мережа: хаб у центрі та шість вузлів по кільцю, від хаба до кожного промінь.
	local hub = Vector3.new(0, NODE_HEIGHT, TABLE_Z)
	Build.cylinder(
		model,
		13,
		3,
		(origin * CFrame.new(0, 1.5 + 0.6, TABLE_Z)).Position,
		Color3.fromRGB(30, 34, 44),
		"Y",
		{ name = "TableBase" }
	)
	local plane = Build.cylinder(
		model,
		12,
		0.15,
		(origin * CFrame.new(0, 3.7, TABLE_Z)).Position,
		Fknt.BEAM_COLOR,
		"Y",
		{
			name = "HoloPlane",
			material = Enum.Material.Neon,
			transparency = 0.75,
			canCollide = false,
		}
	)
	Build.glow(plane, Fknt.BEAM_COLOR, 0.8, 24)
	put(
		"Hub",
		Vector3.new(1.8, 1.8, 1.8),
		CFrame.new(hub),
		Fknt.BEAM_COLOR,
		{ material = Enum.Material.Neon, shape = Enum.PartType.Ball, canCollide = false }
	)
	for index = 1, Fknt.NODE_COUNT do
		local angle = (index - 1) / Fknt.NODE_COUNT * math.pi * 2
		local node = Vector3.new(
			math.cos(angle) * NODE_RING,
			NODE_HEIGHT + math.sin(angle * 2) * 0.6,
			TABLE_Z + math.sin(angle) * NODE_RING
		)
		put(
			"Node" .. index,
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(node),
			Color3.fromRGB(150, 220, 255),
			{ material = Enum.Material.Neon, shape = Enum.PartType.Ball, canCollide = false }
		)
		local middle = (hub + node) / 2
		put(
			"Beam" .. index,
			Vector3.new(0.18, 0.18, (node - hub).Magnitude),
			CFrame.lookAt(middle, node),
			Fknt.BEAM_COLOR,
			{ material = Enum.Material.Neon, canCollide = false }
		)
	end

	-- Три кнопки перед голограмою, кожна зі своєю підказкою «Взаємодіяти» (вмикається лише в грі).
	for _, button in BUTTONS do
		local part = put(
			button.name,
			Vector3.new(5, 3.2, 3),
			CFrame.new(button.x, 1.6 + 0.6, -7),
			button.color,
			{ material = Enum.Material.SmoothPlastic }
		)
		part:SetAttribute("Action", button.action)
		Build.text(part, Enum.NormalId.Front, bilingual(button.key), Color3.new(1, 1, 1), nil)
		put(
			button.name .. "Glow",
			Vector3.new(5.4, 0.3, 3.4),
			CFrame.new(button.x, 0.75, -7),
			Fknt.BEAM_COLOR,
			{ material = Enum.Material.Neon, canCollide = false }
		)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ActionPrompt"
		prompt.ActionText = bilingual("ui.interact")
		prompt.ObjectText = bilingual(button.key)
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = part
	end

	-- Табло статусу над столом.
	local board = put(
		"StatusBoard",
		Vector3.new(16, 2.6, 0.3),
		CFrame.new(0, height - 4.2, TABLE_Z + 7),
		Color3.fromRGB(12, 20, 40),
		{ canCollide = false }
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "StatusLabel"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.TextColor3 = Fknt.BEAM_COLOR
	label.Text = bilingual("mg.fknt.title")
	label.Parent = gui

	-- Стіл із монітором для вигляду.
	put(
		"Desk",
		Vector3.new(6, 1.6, 2.4),
		CFrame.new(-(width / 2 - 5), 1.4, depth / 6 + 2),
		Color3.fromRGB(150, 154, 160)
	)
	put(
		"DeskMonitor",
		Vector3.new(2.4, 1.6, 0.2),
		CFrame.new(-(width / 2 - 5), 3.2, depth / 6 + 2.6),
		Color3.fromRGB(34, 69, 151),
		{ material = Enum.Material.Neon, canCollide = false }
	)
end

return Fknt
