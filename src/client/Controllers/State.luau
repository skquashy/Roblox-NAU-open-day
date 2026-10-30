--!strict
-- Хранит последнее состояние от сервера (Snapshot) и выбирает язык при первом входе.

local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Signal = require(Shared.Util.Signal)

local Lib = script.Parent.Parent.Lib
local NetClient = require(Lib.NetClient)
local Lang = require(Lib.Lang)

local State = {
	snapshot = nil :: Types.Snapshot?,
	Changed = Signal.new(), -- fire(snapshot)
}

local languageSent = false

local function detectLanguage(): string
	local ok, localeId = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if ok and typeof(localeId) == "string" and string.sub(localeId, 1, 2) == "en" then
		return "en"
	end
	return "uk"
end

function State.init()
	NetClient.on("Snapshot", function(snapshot: Types.Snapshot)
		State.snapshot = snapshot
		if snapshot.lang ~= "" then
			Lang.set(snapshot.lang)
		elseif not languageSent then
			-- Первый вход: подбираем язык по настройкам Roblox и сохраняем выбор на сервере.
			languageSent = true
			local detected = detectLanguage()
			Lang.set(detected)
			NetClient.fire("SetLanguage", detected)
		end
		State.Changed:fire(snapshot)
	end)
end

return State
