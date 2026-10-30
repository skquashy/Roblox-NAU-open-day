--!strict
-- Фірмовий стиль КАІ для інтерфейсу та вивісок. Кольори з брифа: #267CEB, #224597, #9EDFFF,
-- акцент #E8418E. Нейтральні кольори (ink, white, mist) похідні: додані лише для читабельності.

local Config = require(script.Parent.Config)

local FALLBACK_FAMILY = "rbxasset://fonts/families/BuilderSans.json"

local Theme = {}

Theme.colors = table.freeze({
	primary = Color3.fromHex("#267CEB"),
	deep = Color3.fromHex("#224597"),
	sky = Color3.fromHex("#9EDFFF"),
	accent = Color3.fromHex("#E8418E"),
	white = Color3.fromHex("#FFFFFF"),
	ink = Color3.fromHex("#0E1B3D"),
	mist = Color3.fromHex("#EAF4FF"),
})

-- Шрифт Geologica, якщо його ID вписано в Config.GEOLOGICA_FONT_ID, інакше запасний.
function Theme.font(weight: Enum.FontWeight?): Font
	local family = FALLBACK_FAMILY
	if Config.GEOLOGICA_FONT_ID ~= "" then
		family = "rbxassetid://" .. Config.GEOLOGICA_FONT_ID
	end
	return Font.new(family, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

return Theme
