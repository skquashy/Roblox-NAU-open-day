--!strict
-- 9 факультетів КАІ за списком приймальної комісії (pk.kai.edu.ua/fakultety). Порядок як на сайті.
-- Тексти (назва, опис) лежать у Locale/*.luau під ключами fac.<id>.name та fac.<id>.info.
-- id = рядкова абревіатура латиницею. Грає одна спільна мінігра на факультет.

export type Faculty = {
	id: string,
	color: Color3, -- акцент факультету на картках і табло
	minigame: string, -- id мінігри (src/server/Minigames); модуль з'явиться на етапі мініігор
}

local list: { Faculty } = {
	{ id = "akf", color = Color3.fromRGB(52, 120, 246), minigame = "akf" },
	{ id = "gmf", color = Color3.fromRGB(232, 65, 142), minigame = "gmf" },
	{ id = "faet", color = Color3.fromRGB(0, 170, 200), minigame = "faet" },
	{ id = "fabd", color = Color3.fromRGB(230, 130, 60), minigame = "fabd" },
	{ id = "fknt", color = Color3.fromRGB(226, 48, 52), minigame = "fknt" },
	{ id = "fmfm", color = Color3.fromRGB(240, 170, 30), minigame = "fmfm" },
	{ id = "fnz", color = Color3.fromRGB(70, 180, 90), minigame = "fnz" },
	{ id = "fpmv", color = Color3.fromRGB(170, 70, 70), minigame = "fpmv" },
	{ id = "ftl", color = Color3.fromRGB(90, 120, 140), minigame = "ftl" },
}

local byId: { [string]: Faculty } = {}
for _, faculty in list do
	byId[faculty.id] = faculty
end

return {
	list = list,
	byId = byId,
}
