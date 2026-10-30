--!strict
-- Предметы: квестовые (выдаются сервером) и косметика (покупается за монеты).

export type ItemDef = {
	id: string,
	category: string, -- "quest" | "cosmetic"
	nameKey: string,
	icon: string,
	price: number, -- только для cosmetic
	hatShape: Enum.PartType?,
	hatSize: Vector3?,
	hatColor: Color3?,
}

local list: { ItemDef } = {
	{ id = "helmet", category = "quest", nameKey = "item.helmet", icon = "🪖", price = 0 },
	{ id = "jacket", category = "quest", nameKey = "item.jacket", icon = "🧥", price = 0 },
	{
		id = "hat_blue",
		category = "cosmetic",
		nameKey = "item.hat_blue",
		icon = "🧢",
		price = 80,
		hatShape = Enum.PartType.Cylinder,
		hatSize = Vector3.new(0.5, 2.2, 2.2),
		hatColor = Color3.fromRGB(40, 110, 230),
	},
	{
		id = "hat_gold",
		category = "cosmetic",
		nameKey = "item.hat_gold",
		icon = "👑",
		price = 200,
		hatShape = Enum.PartType.Block,
		hatSize = Vector3.new(2, 0.7, 2),
		hatColor = Color3.fromRGB(245, 190, 40),
	},
	{
		id = "hat_green",
		category = "cosmetic",
		nameKey = "item.hat_green",
		icon = "🎩",
		price = 120,
		hatShape = Enum.PartType.Ball,
		hatSize = Vector3.new(2.2, 2.2, 2.2),
		hatColor = Color3.fromRGB(60, 180, 100),
	},
	{
		id = "hat_red",
		category = "cosmetic",
		nameKey = "item.hat_red",
		icon = "🎓",
		price = 150,
		hatShape = Enum.PartType.Block,
		hatSize = Vector3.new(2.4, 0.4, 2.4),
		hatColor = Color3.fromRGB(215, 60, 60),
	},
}

local byId: { [string]: ItemDef } = {}
for _, item in list do
	byId[item.id] = item
end

return {
	list = list,
	byId = byId,
}
