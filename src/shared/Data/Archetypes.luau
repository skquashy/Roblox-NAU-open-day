--!strict
-- Шість образів зі скриншота. Наразі образ = кольоровий головний убір-заглушка.
-- Пізніше можна замінити на справжні асети (HumanoidDescription) у Systems/Preferences.

export type Archetype = {
	id: string,
	nameKey: string,
	icon: string,
	color: Color3,
	hatShape: Enum.PartType,
	hatSize: Vector3,
}

local list: { Archetype } = {
	{
		id = "pilot",
		nameKey = "arch.pilot",
		icon = "✈",
		color = Color3.fromRGB(70, 90, 140),
		hatShape = Enum.PartType.Block,
		hatSize = Vector3.new(2.1, 0.6, 2.1),
	},
	{
		id = "engineer",
		nameKey = "arch.engineer",
		icon = "🔧",
		color = Color3.fromRGB(245, 200, 30),
		hatShape = Enum.PartType.Ball,
		hatSize = Vector3.new(2.3, 2.3, 2.3),
	},
	{
		id = "scientist",
		nameKey = "arch.scientist",
		icon = "🔬",
		color = Color3.fromRGB(235, 240, 245),
		hatShape = Enum.PartType.Cylinder,
		hatSize = Vector3.new(0.4, 2.2, 2.2),
	},
	{
		id = "designer",
		nameKey = "arch.designer",
		icon = "🎨",
		color = Color3.fromRGB(60, 50, 50),
		hatShape = Enum.PartType.Cylinder,
		hatSize = Vector3.new(0.35, 2.4, 2.4),
	},
	{
		id = "programmer",
		nameKey = "arch.programmer",
		icon = "💻",
		color = Color3.fromRGB(40, 190, 170),
		hatShape = Enum.PartType.Block,
		hatSize = Vector3.new(2.3, 0.5, 1.2),
	},
	{
		id = "business",
		nameKey = "arch.business",
		icon = "💼",
		color = Color3.fromRGB(25, 40, 90),
		hatShape = Enum.PartType.Block,
		hatSize = Vector3.new(1.4, 0.5, 1.4),
	},
}

local byId: { [string]: Archetype } = {}
for _, archetype in list do
	byId[archetype.id] = archetype
end

return {
	list = list,
	byId = byId,
}
