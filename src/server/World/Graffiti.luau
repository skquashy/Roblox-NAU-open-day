--!strict
-- Граффити на стенах: картинки «Вище НАУ тільки небо» и набор стикеров (файлы в reference/graffiti).
-- Роблокс не берёт картинки из проекта: загрузите PNG в Creator Dashboard (Decal) и впишите ID в
-- Config.GRAFFITI_IDS. Пока ID пусты, граффити не строятся.
-- Картинка выводится на тонкой невидимой детали через SurfaceGui, фон PNG прозрачный.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Config = require(Shared.Config)

local Build = require(script.Parent.Build)
local Corpus8 = require(script.Parent.Buildings.Corpus8)

local Graffiti = {}

-- Размеры картинок (ширина на высоту) в пикселях: slogan 500x500, stickers 580x430.
local ASPECT: { [string]: number } = { slogan = 1, stickers = 580 / 430 }
-- Большой слоган затемнён и чуть прозрачен, чтобы выглядеть краской на стене, а не наклейкой.
local TINT: { [string]: Color3 } = { slogan = Color3.fromRGB(120, 126, 140) }
local FADE: { [string]: number } = { slogan = 0.15 }
-- На сколько стопов картинка вынесена от стены: у гладкого кирпичного подиума почти вплотную, у фасадов с оконными
-- лентами и простенками (выступают на 0.4) чуть дальше, иначе картинка утонет в окнах.
local OUTSET_WALL = 0.06
local OUTSET_FACADE = 0.5

-- Одна картинка. cframe: центр на стене, -Z смотрит наружу. height: высота в студах.
local function add(parent: Instance, key: string, cframe: CFrame, height: number)
	local assetId = Config.GRAFFITI_IDS[key]
	if assetId == nil or assetId == "" then
		return
	end
	local panel = Build.part(
		parent,
		Vector3.new(height * ASPECT[key], height, 0.1),
		cframe,
		Color3.new(1, 1, 1),
		{ name = "Graffiti_" .. key, transparency = 1, canCollide = false }
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.Parent = panel
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = "rbxassetid://" .. assetId
	image.ImageColor3 = TINT[key] or Color3.new(1, 1, 1)
	image.ImageTransparency = FADE[key] or 0
	image.Parent = gui
end

-- Ставит граффити на стены корпусов 1, 8 и 11 (как на референсе: цоколь башни и торцы зданий).
function Graffiti.build(parent: Instance, placed: { Campus.Placed })
	local folder = Instance.new("Folder")
	folder.Name = "Graffiti"
	folder.Parent = parent
	for _, item in placed do
		local id = item.def.id
		if id == "c8" then
			-- Кирпичный подиум башни: слева и справа от входа.
			local wallX = item.x + item.face.X * (item.hx + Corpus8.PODIUM_FRONT)
			local outward = item.face * OUTSET_WALL
			for index, offset in { -30, 30 } do
				local key = "slogan"
				if index == 2 then
					key = "stickers"
				end
				local center = Vector3.new(wallX + outward.X, 11, item.z + offset + outward.Z)
				add(folder, key, CFrame.lookAt(center, center + item.face), 18)
			end
		elseif id == "c1" then
			-- Западный торец корпуса 1 (смотрит на парк).
			local center = Vector3.new(item.x - item.w / 2 - OUTSET_FACADE, 16, item.z - 6)
			add(folder, "stickers", CFrame.lookAt(center, center + Vector3.new(-1, 0, 0)), 20)
		elseif id == "c11" then
			-- Западный торец корпуса 11, правее лестничной полосы.
			local center = Vector3.new(item.x - item.w / 2 - OUTSET_FACADE, 16, item.z + 17)
			add(folder, "slogan", CFrame.lookAt(center, center + Vector3.new(-1, 0, 0)), 24)
		end
	end
end

return Graffiti
