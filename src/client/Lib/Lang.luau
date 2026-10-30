--!strict
-- Поточна мова інтерфейсу та прив'язка текстів до ключів локалізації.
-- bind(instance, key) оновлює Text автоматично під час зміни мови.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Locale = require(Shared.Locale)
local Signal = require(Shared.Util.Signal)

type Binding = { key: string, args: { string }?, property: string }

local Lang = {}

Lang.changed = Signal.new()

local current: string = Config.DEFAULT_LANGUAGE
local bound: { [Instance]: Binding } = {}

function Lang.get(): string
	return current
end

function Lang.t(key: string, args: { string }?): string
	return Locale.translate(current, key, args)
end

-- Значення з "@" на початку вважається ключем, інакше це готовий текст.
function Lang.text(value: string, args: { string }?): string
	return Locale.text(current, value, args)
end

function Lang.set(lang: string)
	if lang == current or not Locale.isSupported(lang) then
		return
	end
	current = lang
	for instance, binding in bound do
		(instance :: any)[binding.property] = Locale.translate(current, binding.key, binding.args)
	end
	Lang.changed:fire(lang)
end

function Lang.bind(instance: Instance, key: string, args: { string }?, property: string?)
	local prop = property or "Text"
	bound[instance] = { key = key, args = args, property = prop };
	(instance :: any)[prop] = Locale.translate(current, key, args)
	instance.Destroying:Connect(function()
		bound[instance] = nil
	end)
end

return Lang
