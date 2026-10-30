--!strict
-- Текущий язык интерфейса и привязка текстов к ключам локализации.
-- bind(instance, key) обновляет Text автоматически при смене языка.

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

-- Значение с "@" в начале считается ключом, иначе это готовый текст.
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
