--!strict
-- Типи, спільні для клієнта та сервера.

export type MinigameStat = { best: number, plays: number, passes: number }
export type QuestState = { progress: number, done: boolean }

-- Профіль гравця, що зберігається в DataStore (лише JSON-сумісні значення).
export type Profile = {
	version: number,
	lang: string, -- "uk" | "en" | "" (ще не вибрано)
	archetype: string, -- "" = ще не вибрано
	xp: number,
	coins: number,
	explored: { [string]: boolean },
	minigames: { [string]: MinigameStat },
	quests: { [string]: QuestState },
	badges: { [string]: boolean },
	inventory: { [string]: number },
	hat: string, -- одягнена косметика, "" = немає
	finaleDone: boolean,
	createdAt: number,
}

export type QuestView = { id: string, progress: number, target: number, done: boolean }

-- Те, що сервер надсилає клієнту для відмальовування інтерфейсу.
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

-- Опис мінігри (реалізації лежать на сервері в src/server/Minigames).
export type Minigame = {
	id: string,
	kind: string, -- choice | multi | order | pairs | pick | toggle | allocate
	titleKey: string,
	hintKey: string,
	duration: (difficulty: number) -> number,
	generate: (difficulty: number, rng: Random) -> (any, any),
	evaluate: (secret: any, answer: unknown) -> number,
}

-- «Жива місія»: мінігра в реальному часі, яку веде сервер (src/server/Missions).
-- Гравець діє в 3D-кімнаті (кліки по об'єктах, утримання підказок), сервер сам рахує результат.
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
	score: () -> number, -- 0..1; викликається один раз наприкінці
	stop: () -> (), -- прибрати всі об'єкти місії
	isOver: (() -> boolean)?, -- місія закінчилася раніше часу (наприклад, безпека впала до нуля)
}

export type Mission = {
	id: string,
	titleKey: string,
	hintKey: string,
	duration: (difficulty: number) -> number,
	start: (ctx: MissionContext) -> MissionRun?,
}

return {}
