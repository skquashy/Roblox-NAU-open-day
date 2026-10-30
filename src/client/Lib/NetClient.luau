--!strict
-- Клиентская обёртка над RemoteEvent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local NetClient = {}

local events: { [string]: RemoteEvent } = {}

function NetClient.setup()
	local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER)
	for name in Remotes.toServer do
		events[name] = folder:WaitForChild(name) :: RemoteEvent
	end
	for _, name in Remotes.toClient do
		events[name] = folder:WaitForChild(name) :: RemoteEvent
	end
end

function NetClient.fire(name: string, ...: any)
	local event = events[name]
	if event then
		event:FireServer(...)
	end
end

function NetClient.on(name: string, handler: (...any) -> ())
	local event = events[name]
	assert(event, "Unknown remote: " .. name)
	event.OnClientEvent:Connect(handler)
end

return NetClient
