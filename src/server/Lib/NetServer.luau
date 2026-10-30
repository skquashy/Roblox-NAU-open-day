--!strict
-- Серверна обгортка над RemoteEvent: створення в одному місці, обмеження частоти,
-- єдина точка надсилання. Ремоути НІКОЛИ не створюються деінде.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local NetServer = {}

local events: { [string]: RemoteEvent } = {}

type Bucket = { tokens: number, last: number }
local buckets: { [Player]: { [string]: Bucket } } = {}

local function allow(player: Player, key: string, ratePerSec: number, burst: number): boolean
	local now = os.clock()
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local bucket = playerBuckets[key]
	if not bucket then
		bucket = { tokens = burst, last = now }
		playerBuckets[key] = bucket
	end
	bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * ratePerSec)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

local function create(name: string, folder: Folder)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	events[name] = event
end

function NetServer.setup()
	local folder = Instance.new("Folder")
	folder.Name = Remotes.FOLDER
	for name in Remotes.toServer do
		create(name, folder)
	end
	for _, name in Remotes.toClient do
		create(name, folder)
	end
	folder.Parent = ReplicatedStorage
	Players.PlayerRemoving:Connect(function(player: Player)
		buckets[player] = nil
	end)
end

-- Підписка на ремоут від клієнта. Частота обмежується автоматично.
function NetServer.on(name: string, handler: (player: Player, ...any) -> ())
	local event = events[name]
	local limits = Remotes.toServer[name]
	assert(event and limits, "Unknown client remote: " .. name)
	event.OnServerEvent:Connect(function(player: Player, ...: any)
		if not allow(player, name, limits.rate, limits.burst) then
			return
		end
		handler(player, ...)
	end)
end

function NetServer.fire(player: Player, name: string, ...: any)
	local event = events[name]
	if event and player.Parent == Players then
		event:FireClient(player, ...)
	end
end

return NetServer
