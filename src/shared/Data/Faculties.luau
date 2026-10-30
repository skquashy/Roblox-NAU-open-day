--!strict
-- 9 факультетов КАІ по списку приймальної комісії (pk.kai.edu.ua/fakultety). Порядок как на сайте.
-- Тексты (название, описание) лежат в Locale/*.luau под ключами fac.<id>.name и fac.<id>.info.
-- id = строчная аббревиатура латиницей. Играет одна общая мини-игра на факультет.

export type Faculty = {
	id: string,
	color: Color3, -- акцент факультета на карточках и табло
	minigame: string, -- id мини-игры (src/server/Minigames); модуль появится в этапе мини-игр
}

local list: { Faculty } = {
	{ id = "akf", color = Color3.fromRGB(52, 120, 246), minigame = "akf" },
	{ id = "gmf", color = Color3.fromRGB(232, 65, 142), minigame = "gmf" },
	{ id = "faet", color = Color3.fromRGB(0, 170, 200), minigame = "faet" },
	{ id = "fabd", color = Color3.fromRGB(230, 130, 60), minigame = "fabd" },
	{ id = "fknt", color = Color3.fromRGB(150, 90, 230), minigame = "fknt" },
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
