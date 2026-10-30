--!strict
-- Точка входу клієнта KAI ROBLOX. Контролери лише ВІДОБРАЖАЮТЬ стан,
-- надісланий сервером, і надсилають запити. Нічого важливого клієнт не вирішує.

local NetClient = require(script.Lib.NetClient)

NetClient.setup() -- один раз чекаємо теку з ремоутами; далі NetClient.on не блокує

local Controllers = script.Controllers

local loaded: { [string]: any } = {}
for _, child in Controllers:GetChildren() do
	if child:IsA("ModuleScript") then
		loaded[child.Name] = require(child)
	end
end

-- init: підписки на ремоути та побудова інтерфейсу (без очікувань).
for _, controller in loaded do
	if typeof(controller.init) == "function" then
		controller.init()
	end
end

for _, controller in loaded do
	if typeof(controller.start) == "function" then
		task.spawn(controller.start)
	end
end

-- Усі підписки готові: просимо в сервера поточний стан.
NetClient.fire("RequestSnapshot")

print("[KAI-Roblox] client started")
