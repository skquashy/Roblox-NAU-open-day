--!strict
-- Сохранение прогресса игроков.
-- Реализовано вручную, потому что в этом архиве нет внешних пакетов (Wally).
-- Если захотите, можно заменить на ProfileStore: публичный API модуля (get/save/Loaded/Changed) останется тем же.
--
-- Что здесь сделано (см. правила надёжных сохранений Roblox):
--  * все вызовы DataStore идут через pcall с повторами и экспоненциальной паузой;
--  * чтение-изменение-запись только через UpdateAsync;
--  * блокировка сессии (JobId + время): один сервер владеет данными игрока;
--  * сохранение: автосейв, выход игрока, BindToClose;
--  * если загрузка не удалась, игрок НЕ играет с пустым профилем (кик), иначе следующий сейв затёр бы реальные данные.
--    Исключение: Roblox Studio без доступа к API: тогда профиль временный и не сохраняется.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Signal = require(Shared.Util.Signal)

local PlayerData = {}

-- Fire(player, profile) после успешной загрузки. Changed(player) при любом изменении профиля.
PlayerData.Loaded = Signal.new()
PlayerData.Changed = Signal.new()

type Entry = { profile: Types.Profile, ephemeral: boolean }

local KICK_MESSAGE =
	"Дані ще зберігаються або недоступні. Зайдіть знову за хвилину. / Your data is still saving or unavailable. Please rejoin in a minute."

local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
local entries: { [Player]: Entry } = {}
local inflight = 0

local function keyFor(userId: number): string
	return "Player_" .. tostring(userId)
end

local function deepCopy<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end
	local copy: { [any]: any } = {}
	for k, v in value :: any do
		copy[k] = deepCopy(v)
	end
	return copy :: any
end

local function newProfile(): Types.Profile
	return {
		version = Config.DATA_VERSION,
		lang = "",
		archetype = "",
		xp = 0,
		coins = 0,
		explored = {},
		minigames = {},
		quests = {},
		badges = {},
		inventory = {},
		hat = "",
		finaleDone = false,
		createdAt = os.time(),
	}
end

-- Миграции схемы. При изменении формата данных: увеличьте Config.DATA_VERSION
-- и добавьте шаг MIGRATIONS[старая_версия] = function(data) ... return data end.
local MIGRATIONS: { [number]: (any) -> any } = {}

local function migrate(data: any): Types.Profile
	if typeof(data) ~= "table" then
		return newProfile()
	end
	if typeof(data.version) ~= "number" then
		data.version = 1
	end
	while data.version < Config.DATA_VERSION do
		local step = MIGRATIONS[data.version]
		if not step then
			error("missing migration from v" .. tostring(data.version))
		end
		data = step(data)
		data.version += 1
	end
	-- Добавляем недостающие поля (на случай ручных правок или старых данных).
	local defaults: any = newProfile()
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function withRetry(attempts: number, fn: () -> any): (boolean, any)
	local pause = 1
	local lastError: any = nil
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		warn(("[PlayerData] attempt %d/%d failed: %s"):format(attempt, attempts, tostring(result)))
		if attempt < attempts then
			task.wait(pause)
			pause = math.min(pause * 2, 16)
		end
	end
	return false, lastError
end

local function isLockedByOther(old: any): boolean
	if typeof(old) ~= "table" or typeof(old.lock) ~= "table" then
		return false
	end
	local lock = old.lock
	if lock.jobId == game.JobId then
		return false
	end
	return typeof(lock.time) == "number" and os.time() - lock.time < Config.LOCK_TIMEOUT
end

-- Забирает блокировку и загружает профиль. Возвращает статус: "ok" | "locked" | "failed".
local function claim(player: Player): (string, Types.Profile?)
	local key = keyFor(player.UserId)
	local status = "failed"
	for _ = 1, Config.LOAD_ATTEMPTS do
		local locked = false
		local ok, result = withRetry(3, function()
			return store:UpdateAsync(key, function(old: any)
				locked = false
				if old ~= nil and isLockedByOther(old) then
					locked = true
					return nil -- отмена записи
				end
				local data: any = nil
				if typeof(old) == "table" then
					data = migrate(old.data)
				else
					data = newProfile()
				end
				return { lock = { jobId = game.JobId, time = os.time() }, data = data }
			end)
		end)
		if not ok then
			return "failed", nil
		end
		if locked then
			status = "locked"
			task.wait(3) -- возможно, старый сервер ещё освобождает данные
		elseif typeof(result) == "table" and typeof(result.data) == "table" then
			return "ok", result.data
		end
	end
	return status, nil
end

-- Записывает профиль. release = true снимает блокировку (выход игрока/закрытие сервера).
local function write(userId: number, profile: Types.Profile, release: boolean): boolean
	local snapshot = deepCopy(profile)
	inflight += 1
	local ok = withRetry(3, function()
		return store:UpdateAsync(keyFor(userId), function(old: any)
			if old ~= nil and isLockedByOther(old) then
				return nil -- данные теперь у другого сервера: не перезаписываем
			end
			local lock: any = nil
			if not release then
				lock = { jobId = game.JobId, time = os.time() }
			end
			return { lock = lock, data = snapshot }
		end)
	end)
	inflight -= 1
	return ok
end

function PlayerData.get(player: Player): Types.Profile?
	local entry = entries[player]
	if entry then
		return entry.profile
	end
	return nil
end

-- Вызывайте после любого изменения профиля: обновит интерфейс клиента.
function PlayerData.markChanged(player: Player)
	PlayerData.Changed:fire(player)
end

function PlayerData.save(player: Player, release: boolean): boolean
	local entry = entries[player]
	if not entry or entry.ephemeral then
		return true
	end
	return write(player.UserId, entry.profile, release)
end

local function startAutosave(player: Player)
	task.spawn(function()
		task.wait(player.UserId % Config.AUTOSAVE_INTERVAL) -- разносим сейвы по времени
		while entries[player] do
			PlayerData.save(player, false)
			task.wait(Config.AUTOSAVE_INTERVAL)
		end
	end)
end

local function loadPlayer(player: Player)
	local status, profile = claim(player)

	if player.Parent == nil then
		-- Игрок вышел во время загрузки: сразу освобождаем блокировку.
		if status == "ok" and profile then
			write(player.UserId, profile, true)
		end
		return
	end

	if status == "ok" and profile then
		entries[player] = { profile = profile, ephemeral = false }
	elseif RunService:IsStudio() then
		warn(
			"[PlayerData] DataStore недоступен в Studio: используется ВРЕМЕННЫЙ профиль (не сохраняется)."
		)
		entries[player] = { profile = newProfile(), ephemeral = true }
	else
		player:Kick(KICK_MESSAGE)
		return
	end

	PlayerData.Loaded:fire(player, entries[player].profile)
	startAutosave(player)
end

function PlayerData.init()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(loadPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local entry = entries[player]
		entries[player] = nil
		if entry and not entry.ephemeral then
			task.spawn(write, player.UserId, entry.profile, true)
		end
	end)

	game:BindToClose(function()
		for player, entry in entries do
			if not entry.ephemeral then
				task.spawn(write, player.UserId, entry.profile, true)
			end
		end
		local deadline = os.clock() + (RunService:IsStudio() and 5 or 25)
		while inflight > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

function PlayerData.start()
	-- Игроки, которые успели зайти до запуска системы (в Studio бывает).
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
end

return PlayerData
