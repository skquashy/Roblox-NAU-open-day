--!strict
-- Точка входа сервера KAI ROBLOX. Двухфазный запуск:
-- сначала создаются ремоуты, затем init() у ВСЕХ систем, затем start() у всех.

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

-- Ошибка в одной системе не должна останавливать остальные: логируем и идём дальше.
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
