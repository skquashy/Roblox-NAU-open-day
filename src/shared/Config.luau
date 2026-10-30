--!strict
-- Настраиваемые значения игры. ВАЖНО: этот модуль реплицируется клиентам,
-- здесь не должно быть ничего секретного. Сервер никогда не доверяет значениям,
-- которые клиент "сообщает" сам: все проверки делаются на сервере.

return table.freeze({
	-- Сохранения
	DATASTORE_NAME = "KAIRoblox_v1",
	DATA_VERSION = 1,
	AUTOSAVE_INTERVAL = 60, -- секунд
	LOCK_TIMEOUT = 150, -- через сколько секунд блокировка сессии считается протухшей
	LOAD_ATTEMPTS = 4,

	-- Прогресс
	MAX_LEVEL = 30,
	XP_BASE = 100, -- XP, нужный для перехода 1 -> 2
	XP_STEP = 40, -- на сколько растёт требование с каждым уровнем
	EXPLORE_XP = 25,
	EXPLORE_COINS = 10,

	-- Мини-игры
	PASS_SCORE = 0.6,
	MINIGAME_BASE_COINS = 40,
	MINIGAME_BASE_XP = 60,
	MIN_MINIGAME_SECONDS = 1.5, -- быстрее этого ответ считается невозможным
	MINIGAME_GRACE_SECONDS = 4, -- допуск на сетевую задержку

	-- Взаимодействие с миром (в студах)
	INTERACT_DISTANCE = 22,
	PANEL_DISTANCE = 45,

	ROOM_TAG = "KAI_Lab", -- тег CollectionService на модели лаборатории мини-игры (ставит сервер)
	ROOM_LEAVE_MARGIN = 10, -- на сколько студов выйти за радиус лаборатории, чтобы игра отменилась

	-- Финал
	FINALE_REQUIRED = 9, -- сколько факультетов нужно исследовать (по числу в Data/Faculties)
	FINALE_XP = 200,
	FINALE_COINS = 100,
	VISIT_CODE_PREFIX = "KAI-OPEN",
	-- Ссылки "Ваш следующий шаг". Показываются игроку ТОЛЬКО если платформа
	-- разрешена для его аккаунта через PolicyService. Пустой url = ссылка не показывается.
	NEXT_STEP_LINKS = {
		{ platform = "YouTube", url = "" },
		{ platform = "Facebook", url = "" },
		{ platform = "Discord", url = "" },
	} :: { { platform: string, url: string } },

	-- ID настоящих бейджей Roblox (создаются в Creator Dashboard). 0 = не выдавать.
	ROBLOX_BADGE_IDS = {} :: { [string]: number },

	-- Шрифт Geologica: загрузите семейство шрифтов в Creator Dashboard (Font Family)
	-- и впишите сюда число из rbxassetid://<число>. Пусто = запасной шрифт Roblox.
	GEOLOGICA_FONT_ID = "",

	-- ID загруженных картинок граффити (Creator Dashboard, Decal): reference/graffiti. Пусто = не рисовать.
	GRAFFITI_IDS = { slogan = "79537687992016", stickers = "126584870603070" } :: { [string]: string },

	-- Язык
	DEFAULT_LANGUAGE = "uk",
})
