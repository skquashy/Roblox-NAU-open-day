--!strict
local Faculties = require(script.Parent.Faculties)

export type BadgeDef = {
	id: string,
	nameKey: string,
	descKey: string,
	icon: string,
}

local list: { BadgeDef } = {
	{
		id = "first_steps",
		nameKey = "badge.first_steps.name",
		descKey = "badge.first_steps.desc",
		icon = "👣",
	},
	{
		id = "explorer",
		nameKey = "badge.explorer.name",
		descKey = "badge.explorer.desc",
		icon = "🧭",
	},
	{
		id = "level_5",
		nameKey = "badge.level_5.name",
		descKey = "badge.level_5.desc",
		icon = "⭐",
	},
	{
		id = "graduate",
		nameKey = "badge.graduate.name",
		descKey = "badge.graduate.desc",
		icon = "🎓",
	},
}

local facultyIcons: { [string]: string } = {
	akf = "🚀",
	gmf = "🎭",
	faet = "📡",
	fabd = "🏛",
	fknt = "💻",
	fmfm = "📈",
	fnz = "🩺",
	fpmv = "⚖",
	ftl = "🚚",
}

for _, faculty in Faculties.list do
	table.insert(list, {
		id = "faculty_" .. faculty.id,
		nameKey = "badge.faculty_" .. faculty.id .. ".name",
		descKey = "badge.faculty.desc",
		icon = facultyIcons[faculty.id] or "🏅",
	})
end

local byId: { [string]: BadgeDef } = {}
for _, badge in list do
	byId[badge.id] = badge
end

return {
	list = list,
	byId = byId,
}
