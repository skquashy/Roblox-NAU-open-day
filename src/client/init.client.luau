--!strict
-- Точка входа клиента KAI ROBLOX. Контроллеры только ОТОБРАЖАЮТ состояние,
-- присланное сервером, и отправляют запросы. Ничего важного клиент не решает.

local NetClient = require(script.Lib.NetClient)

NetClient.setup() -- один раз ждём папку с ремоутами; дальше NetClient.on не блокирует

local Controllers = script.Controllers

local loaded: { [string]: any } = {}
for _, child in Controllers:GetChildren() do
	if child:IsA("ModuleScript") then
		loaded[child.Name] = require(child)
	end
end

-- init: подписки на ремоуты и построение интерфейса (без ожиданий).
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

-- Все подписки готовы: просим у сервера текущее состояние.
NetClient.fire("RequestSnapshot")

print("[KAI-Roblox] client started")
