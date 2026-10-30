--!strict
-- Спільний помічник для фасадів: вікна стрічками по поверхах і простінки на чотирьох гранях будівлі.
-- origin: CFrame центра будівлі на землі, -Z дивиться на вхід. Усі деталі без колізії (оболонка стоїть поруч).

local Build = require(script.Parent.Parent.Build)

local Facade = {}

export type Options = {
	firstFloor: number, -- перший поверх із вікнами (1 = перший)
	floors: number, -- усього поверхів
	floorHeight: number,
	glass: Color3,
	pier: Color3,
	columnWidth: number, -- крок простінків у стадах
	glassHeight: number, -- висота стрічки вікон
	skipBack: boolean?, -- не будувати задню грань (якщо вона збігається з гранню сусіднього об'єму)
}

function Facade.rows(
	model: Instance,
	origin: CFrame,
	width: number,
	depth: number,
	options: Options
)
	local floorHeight = options.floorHeight
	local columns = math.max(4, math.floor(width / options.columnWidth))
	local sides = {
		{ x = 0, z = -depth / 2, span = width, along = "x" },
		{ x = 0, z = depth / 2, span = width, along = "x" },
		{ x = -width / 2, z = 0, span = depth, along = "z" },
		{ x = width / 2, z = 0, span = depth, along = "z" },
	}
	for _, side in sides do
		if options.skipBack and side.along == "x" and side.z > 0 then
			continue
		end
		-- Напрямок назовні від грані (для зсуву вперед).
		local outX, outZ = 0, 0
		if side.along == "x" and side.z < 0 then
			outZ = -1
		elseif side.along == "x" then
			outZ = 1
		elseif side.x < 0 then
			outX = -1
		else
			outX = 1
		end
		for floor = options.firstFloor, options.floors do
			local y = (floor - 1) * floorHeight + floorHeight / 2 + 0.5
			local size = Vector3.new(0.4, options.glassHeight, side.span - 4)
			if side.along == "x" then
				size = Vector3.new(side.span - 4, options.glassHeight, 0.4)
			end
			local pos = Vector3.new(side.x + outX * 0.1, y, side.z + outZ * 0.1)
			Build.part(model, size, origin * CFrame.new(pos), options.glass, {
				name = "WindowRow",
				material = Enum.Material.Glass,
				transparency = 0.2,
				canCollide = false,
			})
		end
		-- Простінки між вікнами по всій висоті засклених частин.
		local pierBottom = (options.firstFloor - 1) * floorHeight
		local pierHeight = options.floors * floorHeight - pierBottom
		local pierY = pierBottom + pierHeight / 2
		for i = 0, columns do
			local t = (i / columns - 0.5) * (side.span - 4)
			local pos = Vector3.new(side.x, pierY, side.z)
			local size = Vector3.new(0.9, pierHeight, 0.5)
			if side.along == "x" then
				pos += Vector3.new(t, 0, outZ * 0.12)
			else
				pos += Vector3.new(outX * 0.12, 0, t)
				size = Vector3.new(0.5, pierHeight, 0.9)
			end
			Build.part(model, size, origin * CFrame.new(pos), options.pier, {
				name = "Pier",
				canCollide = false,
			})
		end
	end
end

return Facade
