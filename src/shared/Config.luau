--!strict
-- Налаштовувані значення гри. ВАЖЛИВО: цей модуль реплікується клієнтам,
-- тут не має бути нічого секретного. Сервер ніколи не довіряє значенням,
-- які клієнт «повідомляє» сам: усі перевірки робляться на сервері.

return table.freeze({
	-- Збереження
	DATASTORE_NAME = "KAIRoblox_v1",
	DATA_VERSION = 1,
	AUTOSAVE_INTERVAL = 60, -- секунд
	LOCK_TIMEOUT = 150, -- через скільки секунд блокування сесії вважається протухлим
	LOAD_ATTEMPTS = 4,

	-- Прогрес
	MAX_LEVEL = 30,
	XP_BASE = 100, -- XP, потрібний для переходу 1 -> 2
	XP_STEP = 40, -- наскільки зростає вимога з кожним рівнем
	EXPLORE_XP = 25,
	EXPLORE_COINS = 10,

	-- Мініігри
	PASS_SCORE = 0.6,
	MINIGAME_BASE_COINS = 40,
	MINIGAME_BASE_XP = 60,
	MIN_MINIGAME_SECONDS = 1.5, -- швидше за це відповідь вважається неможливою
	MINIGAME_GRACE_SECONDS = 4, -- допуск на мережеву затримку

	-- Взаємодія зі світом (у стадах)
	INTERACT_DISTANCE = 22,
	PANEL_DISTANCE = 45,

	ROOM_TAG = "KAI_Lab", -- тег CollectionService на моделі лабораторії мінігри (ставить сервер)
	ROOM_LEAVE_MARGIN = 10, -- на скільки стадів вийти за радіус лабораторії, щоб гру було скасовано

	-- Фінал
	FINALE_REQUIRED = 9, -- скільки факультетів потрібно дослідити (за числом у Data/Faculties)
	FINALE_XP = 200,
	FINALE_COINS = 100,
	VISIT_CODE_PREFIX = "KAI-OPEN",
	-- Посилання «Ваш наступний крок». Показуються гравцеві ЛИШЕ якщо платформа
	-- дозволена для його акаунта через PolicyService. Порожній url = посилання не показується.
	NEXT_STEP_LINKS = {
		{ platform = "YouTube", url = "" },
		{ platform = "Facebook", url = "" },
		{ platform = "Discord", url = "" },
	} :: { { platform: string, url: string } },

	-- ID справжніх бейджів Roblox (створюються в Creator Dashboard). 0 = не видавати.
	ROBLOX_BADGE_IDS = {} :: { [string]: number },

	-- Шрифт Geologica: завантажте сімейство шрифтів у Creator Dashboard (Font Family)
	-- і впишіть сюди число з rbxassetid://<число>. Порожньо = запасний шрифт Roblox.
	GEOLOGICA_FONT_ID = "",

	-- ID завантажених зображень графіті (Creator Dashboard, Decal): reference/graffiti. Порожньо = не малювати.
	GRAFFITI_IDS = { slogan = "79537687992016", stickers = "126584870603070" } :: { [string]: string },

	-- Мова
	DEFAULT_LANGUAGE = "uk",
})
