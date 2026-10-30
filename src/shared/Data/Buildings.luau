--!strict
-- Три ігрові корпуси з інтер'єрами: 1, 8 і 11. Решта корпусів кампусу зовні, без інтер'єрів.
-- Який факультет на якому поверсі: ПЛАН ДЛЯ ПЕРЕВІРКИ, а не факт про університет.
-- verified = true лише там, де корпус факультету підтверджено його файлом матеріалів.
-- Кількість поверхів і розміри будівель тут ігрові (оцінка), не за кресленнями. Гравцеві номер корпусу
-- факультету як факт не показуємо, поки verified = false.

export type Lab = {
	faculty: string, -- id з Data/Faculties
	floor: number, -- поверх усередині ігрової будівлі (1 = перший)
	verified: boolean,
}

export type Building = {
	number: number, -- номер корпусу КАІ
	floors: number, -- ігрова кількість поверхів
	labs: { Lab },
}

local list: { Building } = {
	{
		number = 1,
		floors = 4, -- оцінка за аерофото (reference/korpus-1): ~4 ряди вікон під синім дахом
		labs = {
			{ faculty = "gmf", floor = 1, verified = true },
			{ faculty = "fmfm", floor = 2, verified = false },
			{ faculty = "fpmv", floor = 3, verified = false },
		},
	},
	{
		number = 8,
		floors = 16, -- за фото reference/korpus-8: вежа приблизно на 16 поверхів
		labs = {
			{ faculty = "fabd", floor = 1, verified = false },
			{ faculty = "fknt", floor = 3, verified = false },
			{ faculty = "fnz", floor = 5, verified = false },
		},
	},
	{
		number = 11,
		floors = 4, -- оцінка за аерофото (reference/korpus-11): ~4 ряди вікон і великий зал на даху
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
