--!strict
-- Единый список RemoteEvent. Создаются ТОЛЬКО сервером (NetServer.setup).
-- Добавить ремоут = добавить одну строку здесь + обработчик/слушатель.
-- rate/burst: допустимая частота вызовов клиента в секунду (защита от спама).
-- Список заполняется по мере переноса систем (этап "ядро сервера").

local Remotes = {}

Remotes.FOLDER = "Remotes"

Remotes.toServer = {
	SetLanguage = { rate = 1, burst = 4 },
	SelectArchetype = { rate = 1, burst = 4 },
	RequestSnapshot = { rate = 1, burst = 3 },
	BuyItem = { rate = 2, burst = 5 },
	EquipItem = { rate = 3, burst = 6 },
} :: { [string]: { rate: number, burst: number } }

Remotes.toClient = {
	"Snapshot",
	"Toast",
} :: { string }

return Remotes
