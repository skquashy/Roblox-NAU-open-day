--!strict
-- Проверки входных данных от клиента. Любой аргумент RemoteEvent враждебен,
-- пока не проверен: тип -> диапазон -> права -> правдоподобность.

local Guard = {}

function Guard.str(value: unknown, maxLen: number): string?
	if typeof(value) ~= "string" then
		return nil
	end
	if #value == 0 or #value > maxLen then
		return nil
	end
	return value
end

function Guard.int(value: unknown, lo: number, hi: number): number?
	if typeof(value) ~= "number" then
		return nil
	end
	if value ~= value then -- NaN
		return nil
	end
	if value < lo or value > hi then -- заодно отсекает math.huge
		return nil
	end
	if value ~= math.floor(value) then
		return nil
	end
	return value
end

-- Возвращает таблицу, только если это чистый массив 1..n (n <= maxLen).
function Guard.arr(value: unknown, maxLen: number): { any }?
	if typeof(value) ~= "table" then
		return nil
	end
	local tbl = value :: { [any]: any }
	local n = 0
	for key in tbl do
		if typeof(key) ~= "number" then
			return nil
		end
		n += 1
		if n > maxLen then
			return nil
		end
	end
	for i = 1, n do
		if tbl[i] == nil then
			return nil
		end
	end
	return tbl :: { any }
end

return Guard
