--!strict
-- Обстановка лаборатории ФКНТ для мини-игры «Кіберзахист»: шлюз «Інтернет» у боковой стене и четыре
-- серверные стойки вдоль задней стены. Детали с именами Gateway, Rack1..4, Rack<N>Fill и Rack<N>Lamp
-- использует Missions/fknt: сервер двигает пакеты от шлюза к стойкам и меняет шкалу здоровья.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Locale = require(Shared.Locale)

local Build = require(script.Parent.Parent.Build)

local Fknt = {}

Fknt.RACK_COUNT = 4
Fknt.BAR_WIDTH = 3.6

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

	-- Шлюз: светящаяся рама у боковой стены, из неё вылетают пакеты.
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

	-- Стойки у задней стены лицом к центру комнаты: корпус, ряды серверных блоков, шкала здоровья, лампа.
	local rackZ = depth / 2 - 2.4
	local pitch = 7
	for index = 1, Fknt.RACK_COUNT do
		local x = (index - (Fknt.RACK_COUNT + 1) / 2) * pitch
		local front = rackZ - 1.5
		put(
			"Rack" .. index,
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
			"Rack" .. index .. "Back",
			Vector3.new(Fknt.BAR_WIDTH + 0.3, 0.5, 0.15),
			CFrame.new(x, 8.2, front - 0.1),
			Color3.fromRGB(20, 22, 28),
			{ canCollide = false }
		)
		put(
			"Rack" .. index .. "Fill",
			Vector3.new(Fknt.BAR_WIDTH, 0.35, 0.2),
			CFrame.new(x, 8.2, front - 0.2),
			Color3.fromRGB(80, 220, 120),
			{ material = Enum.Material.Neon, canCollide = false }
		)
		put(
			"Rack" .. index .. "Lamp",
			Vector3.new(0.7, 0.7, 0.3),
			CFrame.new(x - 1.7, 7.3, front - 0.2),
			Color3.fromRGB(80, 220, 120),
			{ material = Enum.Material.Neon, canCollide = false }
		)
	end

	-- Мелочи для вида: кабельный лоток вдоль потолка над стойками и стол с монитором.
	put(
		"CableTray",
		Vector3.new(width - 4, 0.4, 1.2),
		CFrame.new(0, height - 1.4, rackZ),
		Color3.fromRGB(110, 116, 126),
		{ canCollide = false }
	)
	put(
		"Desk",
		Vector3.new(6, 1.6, 2.4),
		CFrame.new(-(width / 2 - 5), 1.4, depth / 6),
		Color3.fromRGB(150, 154, 160)
	)
	put(
		"DeskMonitor",
		Vector3.new(2.4, 1.6, 0.2),
		CFrame.new(-(width / 2 - 5), 3.2, depth / 6 + 0.6),
		Color3.fromRGB(34, 69, 151),
		{ material = Enum.Material.Neon, canCollide = false }
	)
end

return Fknt
