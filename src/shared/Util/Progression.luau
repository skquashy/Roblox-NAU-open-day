--!strict
-- Крива рівнів. Чиста функція: використовується і сервером (джерело істини),
-- і клієнтом (лише для відображення).

local Config = require(script.Parent.Parent.Config)

local Progression = {}

function Progression.xpForNext(level: number): number
	return Config.XP_BASE + Config.XP_STEP * (level - 1)
end

-- Повертає: рівень, XP всередині рівня, XP потрібний до наступного.
function Progression.levelInfo(xp: number): (number, number, number)
	local level = 1
	local remaining = math.max(0, xp)
	while level < Config.MAX_LEVEL do
		local need = Progression.xpForNext(level)
		if remaining < need then
			return level, remaining, need
		end
		remaining -= need
		level += 1
	end
	return level, 0, 0
end

return Progression
