--!strict
-- Локалізація. Увесь текст гри береться ЛИШЕ звідси, за ключами.
-- Ключ виду "@ui.close" усередині даних/аргументів означає «це ключ, а не готовий текст».
-- Параметри в рядках: {1}, {2} ... підставляються з масиву args.

local Config = require(script.Parent.Config)

local tables: { [string]: { [string]: string } } = {
	uk = require(script.uk),
	en = require(script.en),
}

local Locale = {}

Locale.languages = { "uk", "en" }

function Locale.isSupported(lang: string): boolean
	return tables[lang] ~= nil
end

function Locale.translate(lang: string, key: string, args: { string }?): string
	local dict = tables[lang] or tables[Config.DEFAULT_LANGUAGE]
	local text = dict[key] or tables.en[key]
	if text == nil then
		return key
	end
	if args then
		local params: { string } = args
		local result = string.gsub(text, "{(%d+)}", function(index: string): string
			local value = params[tonumber(index) :: number]
			if value == nil then
				return ""
			end
			if string.sub(value, 1, 1) == "@" then
				return Locale.translate(lang, string.sub(value, 2), nil)
			end
			return value
		end)
		return result
	end
	return text
end

-- Якщо рядок починається з "@" - це ключ, інакше - готовий текст.
function Locale.text(lang: string, value: string, args: { string }?): string
	if string.sub(value, 1, 1) == "@" then
		return Locale.translate(lang, string.sub(value, 2), args)
	end
	return value
end

-- Для перевірки скриптом scripts/check_locale.py та для налагодження.
function Locale.keys(lang: string): { string }
	local out = {}
	for key in tables[lang] do
		table.insert(out, key)
	end
	return out
end

return Locale
