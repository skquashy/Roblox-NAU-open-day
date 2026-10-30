--!strict
-- Невидимий бар'єр по периметру кампусу: гравець не може вийти за його межі, а місто за бар'єром залишається
-- видимим. Південна стіна йде вздовж проспекту Гузара по зовнішньому краю південного тротуару.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Campus = require(Shared.Data.Campus)

local Build = require(script.Parent.Build)

local Boundary = {}

local MIN_X = -265
local MAX_X = 470
local NORTH_MARGIN = 80 -- на північ від найпівнічнішої споруди
local SOUTH_EDGE = 7.5 -- ширина тротуару за проїжджою частиною; бар'єр стоїть біля його краю
local HEIGHT = 500
local THICKNESS = 6

local function wall(folder: Instance, a: Vector3, b: Vector3, name: string)
	local length = (b - a).Magnitude
	local middle = (a + b) / 2
	Build.part(
		folder,
		Vector3.new(THICKNESS, HEIGHT, length + THICKNESS),
		CFrame.lookAt(
			Vector3.new(middle.X, HEIGHT / 2, middle.Z),
			Vector3.new(b.X, HEIGHT / 2, b.Z)
		),
		Color3.new(1, 1, 1),
		{ name = name, transparency = 1, canCollide = true }
	)
end

function Boundary.build(parent: Instance, placed: { Campus.Placed })
	local road = Campus.roadById("guzara")
	if not road then
		return
	end
	local minZ = math.huge
	for _, item in placed do
		minZ = math.min(minZ, item.z - item.hz)
	end
	minZ -= NORTH_MARGIN
	local _, north = Campus.roadFrame(road)
	local south = -north
	local offset = road.width / 2 + SOUTH_EDGE
	local southWest = Campus.roadAtX(road, MIN_X) + south * offset
	local southEast = Campus.roadAtX(road, MAX_X) + south * offset
	local folder = Instance.new("Folder")
	folder.Name = "Boundary"
	folder.Parent = parent
	local northWest = Vector3.new(MIN_X, 0, minZ)
	local northEast = Vector3.new(MAX_X, 0, minZ)
	wall(folder, northWest, northEast, "WallNorth")
	wall(folder, northEast, Vector3.new(southEast.X, 0, southEast.Z), "WallEast")
	wall(
		folder,
		Vector3.new(southEast.X, 0, southEast.Z),
		Vector3.new(southWest.X, 0, southWest.Z),
		"WallSouth"
	)
	wall(folder, Vector3.new(southWest.X, 0, southWest.Z), northWest, "WallWest")
end

return Boundary
