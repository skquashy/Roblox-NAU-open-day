--!strict
-- Типы, общие для клиента и сервера.

export type MinigameStat = { best: number, plays: number, passes: number }
export type QuestState = { progress: number, done: boolean }

-- Профиль игрока, который хранится в DataStore (только JSON-совместимые значения).
export type Profile = {
	version: number,
	lang: string, -- "uk" | "en" | "" (ещё не выбран)
	archetype: string, -- "" = ещё не выбран
	xp: number,
	coins: number,
	explored: { [string]: boolean },
	minigames: { [string]: MinigameStat },
	quests: { [string]: QuestState },
	badges: { [string]: boolean },
	inventory: { [string]: number },
	hat: string, -- надетая косметика, "" = нет
	finaleDone: boolean,
	createdAt: number,
}

export type QuestView = { id: string, progress: number, target: number, done: boolean }

-- То, что сервер отправляет клиенту для отрисовки интерфейса.
export type Snapshot = {
	lang: string,
	archetype: string,
	xp: number,
	coins: number,
	explored: { string },
	exploredCount: number,
	quests: { QuestView },
	badges: { string },
	inventory: { [string]: number },
	hat: string,
	minigames: { [string]: MinigameStat },
	finaleDone: boolean,
}

-- Описание мини-игры (реализации лежат на сервере в src/server/Minigames).
export type Minigame = {
	id: string,
	kind: string, -- choice | multi | order | pairs | pick | toggle | allocate
	titleKey: string,
	hintKey: string,
	duration: (difficulty: number) -> number,
	generate: (difficulty: number, rng: Random) -> (any, any),
	evaluate: (secret: any, answer: unknown) -> number,
}

-- "Живая миссия": мини-игра в реальном времени, которую ведёт сервер (src/server/Missions).
-- Игрок действует в 3D-комнате (клики по объектам, зажатие подсказок), сервер сам считает результат.
export type MissionContext = {
	player: Player,
	room: Model,
	difficulty: number,
	rng: Random,
	toast: (key: string, args: { string }?) -> (),
	push: (state: { [string]: any }) -> (),
}

export type MissionRun = {
	tick: (dt: number) -> (),
	score: () -> number, -- 0..1; вызывается один раз в конце
	stop: () -> (), -- убрать все объекты миссии
}

export type Mission = {
	id: string,
	titleKey: string,
	hintKey: string,
	duration: (difficulty: number) -> number,
	start: (ctx: MissionContext) -> MissionRun?,
}

return {}
