--!strict
-- Єдиний список RemoteEvent. Створюються ЛИШЕ сервером (NetServer.setup).
-- Додати ремоут = додати один рядок тут + обробник/слухач.
-- rate/burst: допустима частота викликів клієнта на секунду (захист від спаму).
-- Список заповнюється в міру перенесення систем (етап «ядро сервера»).

local Remotes = {}

Remotes.FOLDER = "Remotes"

Remotes.toServer = {
	SetLanguage = { rate = 1, burst = 4 },
	SelectArchetype = { rate = 1, burst = 4 },
	RequestSnapshot = { rate = 1, burst = 3 },
	BuyItem = { rate = 2, burst = 5 },
	EquipItem = { rate = 3, burst = 6 },
	MinigameStart = { rate = 1, burst = 3 },
	MinigameCancel = { rate = 1, burst = 3 },
} :: { [string]: { rate: number, burst: number } }

Remotes.toClient = {
	"Snapshot",
	"Toast",
	"MinigamePrompt",
	"MissionState",
	"MissionResult",
} :: { string }

return Remotes
