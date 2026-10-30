--!strict
-- Графіті на стінах: зображення «Вище НАУ тільки небо» та набір стікерів (файли в reference/graffiti).
-- Roblox не бере зображення з проєкту: завантажте PNG у Creator Dashboard (Decal) і впишіть ID у
-- Config.GRAFFITI_IDS. Поки ID порожні, графіті не будуються.
-- Зображення виводиться на тонкій невидимій деталі через SurfaceGui, тло PNG прозоре.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)
local Config = require(Shared.Config)

local Build = require(script.Parent.Build)
local Corpus8 = require(script.Parent.Buildings.Corpus8)

local Graffiti = {}

-- Розміри зображень (ширина на висоту) в пікселях: slogan 500x500, stickers 580x430.
local ASPECT: { [string]: number } = { slogan = 1, stickers = 580 / 430 }
-- Великий слоган затемнений і трохи прозорий, щоб виглядати фарбою на стіні, а не наклейкою.
local TINT: { [string]: Color3 } = { slogan = Color3.fromRGB(120, 126, 140) }
local FADE: { [string]: number } = { slogan = 0.15 }
-- На скільки стадів зображення винесено від стіни: біля гладкого цегляного подіуму майже впритул, біля фасадів зі віконними
-- стрічками та простінками (виступають на 0.4) трохи далі, інакше зображення потоне у вікнах.
local OUTSET_WALL = 0.06
local OUTSET_FACADE = 0.5

-- Одне зображення. cframe: центр на стіні, -Z дивиться назовні. height: висота в стадах.
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

-- Ставить графіті на стіни корпусів 1, 8 і 11 (як на референсі: цоколь вежі та торці будівель).
function Graffiti.build(parent: Instance, placed: { Campus.Placed })
	local folder = Instance.new("Folder")
	folder.Name = "Graffiti"
	folder.Parent = parent
	for _, item in placed do
		local id = item.def.id
		if id == "c8" then
			-- Цегляний подіум вежі: ліворуч і праворуч від входу.
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
			-- Західний торець корпусу 1 (дивиться на парк).
			local center = Vector3.new(item.x - item.w / 2 - OUTSET_FACADE, 16, item.z - 6)
			add(folder, "stickers", CFrame.lookAt(center, center + Vector3.new(-1, 0, 0)), 20)
		elseif id == "c11" then
			-- Західний торець корпусу 11, правіше за сходову смугу.
			local center = Vector3.new(item.x - item.w / 2 - OUTSET_FACADE, 16, item.z + 17)
			add(folder, "slogan", CFrame.lookAt(center, center + Vector3.new(-1, 0, 0)), 24)
		end
	end
end

return Graffiti
