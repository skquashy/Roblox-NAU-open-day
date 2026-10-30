--!strict
-- Квести описані даними. Сервер сам вирішує, коли ціль виконано.
-- kind:
-- explore_count  - досліджено N факультетів
-- minigame       - пройдено мінігру факультету target
-- minigame_count - пройдено N різних мініігор
-- finale         - пройти церемонію
-- Квести про світ (діалоги, предмети, місця) додадуться разом із кампусом.

local Faculties = require(script.Parent.Faculties)

export type QuestDef = {
	id: string,
	kind: string,
	target: string,
	count: number,
	xp: number,
	coins: number,
	titleKey: string,
	itemReward: string?,
}

local list: { QuestDef } = {
	{
		id = "first_steps",
		kind = "explore_count",
		target = "",
		count = 1,
		xp = 30,
		coins = 10,
		titleKey = "quest.first_steps",
	},
}

for _, faculty in Faculties.list do
	local reward: string? = nil
	if faculty.id == "akf" then
		reward = "helmet"
	end
	table.insert(list, {
		id = "play_" .. faculty.id,
		kind = "minigame",
		target = faculty.id,
		count = 1,
		xp = 60,
		coins = 25,
		titleKey = "quest.play_" .. faculty.id,
		itemReward = reward,
	})
end

table.insert(list, {
	id = "play_three",
	kind = "minigame_count",
	target = "",
	count = 3,
	xp = 80,
	coins = 40,
	titleKey = "quest.play_three",
})
table.insert(list, {
	id = "explore_all",
	kind = "explore_count",
	target = "",
	count = #Faculties.list,
	xp = 150,
	coins = 80,
	titleKey = "quest.explore_all",
	itemReward = "jacket",
})
table.insert(list, {
	id = "graduate",
	kind = "finale",
	target = "",
	count = 1,
	xp = 100,
	coins = 50,
	titleKey = "quest.graduate",
})

local byId: { [string]: QuestDef } = {}
for _, quest in list do
	byId[quest.id] = quest
end

return {
	list = list,
	byId = byId,
}
