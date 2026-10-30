--!strict
-- Три игровых корпуса с интерьерами: 1, 8 и 11. Остальные корпуса кампуса снаружи, без интерьеров.
-- Какой факультет на каком этаже: ПЛАН ДЛЯ ПРОВЕРКИ, а не факт об университете.
-- verified = true только там, где корпус факультета подтверждён его файлом материалов.
-- Число этажей и размеры зданий здесь игровые (оценка), не по чертежам. Игроку номер корпуса
-- факультета как факт не показываем, пока verified = false.

export type Lab = {
	faculty: string, -- id из Data/Faculties
	floor: number, -- этаж внутри игрового здания (1 = первый)
	verified: boolean,
}

export type Building = {
	number: number, -- номер корпуса КАІ
	floors: number, -- игровое число этажей
	labs: { Lab },
}

local list: { Building } = {
	{
		number = 1,
		floors = 4, -- оценка по аэрофото (reference/korpus-1): ~4 ряда окон под синей крышей
		labs = {
			{ faculty = "gmf", floor = 1, verified = true },
			{ faculty = "fmfm", floor = 2, verified = false },
			{ faculty = "fpmv", floor = 3, verified = false },
		},
	},
	{
		number = 8,
		floors = 16, -- по фото reference/korpus-8: башня примерно в 16 этажей
		labs = {
			{ faculty = "fabd", floor = 1, verified = false },
			{ faculty = "fknt", floor = 3, verified = false },
			{ faculty = "fnz", floor = 5, verified = false },
		},
	},
	{
		number = 11,
		floors = 4, -- оценка по аэрофото (reference/korpus-11): ~4 ряда окон и большой зал на крыше
		labs = {
			{ faculty = "ftl", floor = 1, verified = true },
			{ faculty = "akf", floor = 2, verified = false },
			{ faculty = "faet", floor = 3, verified = false },
		},
	},
}

local byNumber: { [number]: Building } = {}
local byFaculty: { [string]: { building: number, floor: number } } = {}
for _, building in list do
	byNumber[building.number] = building
	for _, lab in building.labs do
		byFaculty[lab.faculty] = { building = building.number, floor = lab.floor }
	end
end

return {
	list = list,
	byNumber = byNumber,
	byFaculty = byFaculty,
}
