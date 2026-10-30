--!strict
-- Будує кампус під час запуску сервера: освітлення, земля, вулиці, будівлі (World/CampusBuilder), точка появи.
-- Якщо побудова впала, ставить плоску землю та точку появи, щоб гра все одно запускалася.

local Lighting = game:GetService("Lighting")

local World = script.Parent.Parent.World
local Build = require(World.Build)
local CampusBuilder = require(World.CampusBuilder)

local WorldBuilder = {}

local function setupLighting()
	-- Післяобіднє тепле сонце: довгі м'які тіні, золотисте світло на будівлях.
	Lighting.ClockTime = 16
	-- Technology = Future задано в default.project.json (зі скрипта його змінювати не можна).
	Lighting.Brightness = 2.8
	Lighting.Ambient = Color3.fromRGB(78, 84, 98)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 128, 144)
	Lighting.ShadowSoftness = 0.2
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	if not Lighting:FindFirstChild("KAIAtmosphere") then
		-- Імла розмиває далекі будинки: панорама міста м'яко тоне в повітрі.
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "KAIAtmosphere"
		atmosphere.Density = 0.3
		atmosphere.Offset = 0.1
		atmosphere.Haze = 1.4
		atmosphere.Glare = 0.2
		atmosphere.Color = Color3.fromRGB(199, 215, 235)
		atmosphere.Decay = Color3.fromRGB(165, 178, 205)
		atmosphere.Parent = Lighting
	end
	if not Lighting:FindFirstChild("KAIColor") then
		local color = Instance.new("ColorCorrectionEffect")
		color.Name = "KAIColor"
		color.Saturation = 0.1
		color.Contrast = 0.05
		color.TintColor = Color3.fromRGB(255, 248, 238)
		color.Parent = Lighting
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "KAIBloom"
		bloom.Intensity = 0.15
		bloom.Size = 22
		bloom.Threshold = 2.2
		bloom.Parent = Lighting
		local rays = Instance.new("SunRaysEffect")
		rays.Name = "KAIRays"
		rays.Intensity = 0.03
		rays.Parent = Lighting
	end
end

local function addSpawn(parent: Instance, position: Vector3)
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = position
	spawn.Neutral = true
	spawn.Transparency = 0.6
	spawn.Color = Color3.fromRGB(38, 124, 235)
	spawn.Parent = parent
end

local function buildFallback(folder: Folder)
	folder:ClearAllChildren()
	Build.part(
		folder,
		Vector3.new(700, 2, 700),
		CFrame.new(0, -1, 0),
		Color3.fromRGB(96, 156, 84),
		{ name = "Ground" }
	)
	addSpawn(folder, Vector3.new(0, 0.5, 0))
end

function WorldBuilder.init()
	setupLighting()
	-- Шаблонний Baseplate лежить на тій самій висоті, що й наша земля: поверхні блимають (z-fighting).
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	local old = workspace:FindFirstChild("Campus")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Campus"
	folder.Parent = workspace

	local ok, result = pcall(CampusBuilder.build, folder)
	if ok then
		addSpawn(folder, result.spawn)
	else
		warn("[KAI-Roblox] Campus build failed (using flat ground): " .. tostring(result))
		buildFallback(folder)
	end
end

return WorldBuilder
