--!strict
-- Точка входу сервера KAI ROBLOX. Двофазний запуск:
-- спочатку створюються ремоути, потім init() у ВСІХ систем, потім start() у всіх.

local NetServer = require(script.Lib.NetServer)

NetServer.setup()

local Systems = script.Systems

local loaded: { [string]: any } = {}
for _, child in Systems:GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if ok then
			loaded[child.Name] = result
		else
			warn("[KAI-Roblox] require failed for " .. child.Name .. ": " .. tostring(result))
		end
	end
end

-- Помилка в одній системі не повинна зупиняти решту: логуємо й ідемо далі.
for name, system in loaded do
	if typeof(system.init) == "function" then
		local ok, err = pcall(system.init)
		if not ok then
			warn("[KAI-Roblox] init failed in " .. name .. ": " .. tostring(err))
		end
	end
end

for name, system in loaded do
	if typeof(system.start) == "function" then
		task.spawn(function()
			local ok, err = pcall(system.start)
			if not ok then
				warn("[KAI-Roblox] start failed in " .. name .. ": " .. tostring(err))
			end
		end)
	end
end

print("[KAI-Roblox] server started")
