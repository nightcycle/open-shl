--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type ThemeDefinition = BaseType.ThemeDefinition
export type ThemeSurface = BaseType.ThemeSurface
-- Constants
local DEFAULT_ID = "modern"
local DEFINITIONS: { ThemeDefinition } = {
	{
		Id = DEFAULT_ID,
		Name = "Modern",
		-- free, everybody owns it
		Price = 0,
		Currency = PseudoEnum.Currency.Credits,
		Palette = {
			Floor = { Color = Color3.fromRGB(135, 134, 136), Material = Enum.Material.Concrete },
			Invisilight = { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
			Lighting = { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
			Roof = { Color = Color3.fromRGB(135, 134, 136), Material = Enum.Material.Concrete },
			Wall = { Color = Color3.fromRGB(171, 168, 158), Material = Enum.Material.Concrete },
			Window = { Color = Color3.fromRGB(9, 137, 207), Material = Enum.Material.SmoothPlastic },
			WaterSmooth = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
			Metal = { Color = Color3.fromRGB(171, 168, 158), Material = Enum.Material.Concrete },
			Stone = { Color = Color3.fromRGB(33, 33, 33), Material = Enum.Material.Slate },
			WaterRipple = { Color = Color3.fromRGB(13, 105, 172), Material = Enum.Material.Foil },
		},
	},
	{
		Id = "dungeon",
		Name = "Dungeon",
		Price = 50,
		Currency = PseudoEnum.Currency.Gems,
		Palette = {
			Floor = { Color = Color3.fromRGB(105, 102, 92), Material = Enum.Material.Cobblestone },
			Invisilight = { Color = Color3.fromRGB(218, 178, 75), Material = Enum.Material.Neon },
			Lighting = { Color = Color3.fromRGB(218, 178, 75), Material = Enum.Material.Neon },
			Roof = { Color = Color3.fromRGB(75, 67, 75), Material = Enum.Material.Slate },
			Wall = { Color = Color3.fromRGB(75, 67, 75), Material = Enum.Material.Slate },
			Window = { Color = Color3.fromRGB(30, 30, 30), Material = Enum.Material.SmoothPlastic },
			WaterSmooth = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
			Metal = { Color = Color3.fromRGB(86, 66, 54), Material = Enum.Material.Wood },
			Stone = { Color = Color3.fromRGB(75, 67, 75), Material = Enum.Material.Slate },
			WaterRipple = { Color = Color3.fromRGB(189, 181, 69), Material = Enum.Material.Foil },
		},
	},
	{
		Id = "sterile",
		Name = "Sterile",
		Price = 3_500,
		Currency = PseudoEnum.Currency.Credits,
		Palette = {
			Floor = { Color = Color3.fromRGB(136, 139, 140), Material = Enum.Material.DiamondPlate },
			Invisilight = { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
			Lighting = { Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon },
			Roof = { Color = Color3.fromRGB(135, 134, 136), Material = Enum.Material.Concrete },
			Wall = { Color = Color3.fromRGB(244, 244, 244), Material = Enum.Material.SmoothPlastic },
			Window = { Color = Color3.fromRGB(9, 137, 207), Material = Enum.Material.SmoothPlastic },
			WaterSmooth = { Color = Color3.fromRGB(189, 243, 255), Material = Enum.Material.Neon },
			Metal = { Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Metal },
			Stone = { Color = Color3.fromRGB(33, 33, 33), Material = Enum.Material.Slate },
			WaterRipple = { Color = Color3.fromRGB(50, 50, 50), Material = Enum.Material.Foil },
		},
	},
	{
		Id = "techno",
		Name = "Techno",
		Price = 5_000,
		Currency = PseudoEnum.Currency.Credits,
		Palette = {
			Floor = { Color = Color3.fromRGB(136, 139, 140), Material = Enum.Material.DiamondPlate },
			Invisilight = { Color = Color3.fromRGB(0, 255, 0), Material = Enum.Material.Neon },
			Lighting = { Color = Color3.fromRGB(0, 255, 0), Material = Enum.Material.Neon },
			Roof = { Color = Color3.fromRGB(135, 134, 136), Material = Enum.Material.Concrete },
			Wall = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.Metal },
			Window = { Color = Color3.fromRGB(9, 137, 207), Material = Enum.Material.SmoothPlastic },
			WaterSmooth = { Color = Color3.fromRGB(101, 255, 106), Material = Enum.Material.Neon },
			Metal = { Color = Color3.fromRGB(0, 255, 0), Material = Enum.Material.Metal },
			Stone = { Color = Color3.fromRGB(33, 33, 33), Material = Enum.Material.Slate },
			WaterRipple = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.Foil },
		},
	},
	{
		Id = "steampunk",
		Name = "Steampunk",
		Price = 70,
		Currency = PseudoEnum.Currency.Gems,
		Palette = {
			Floor = { Color = Color3.fromRGB(108, 88, 75), Material = Enum.Material.WoodPlanks },
			Invisilight = { Color = Color3.fromRGB(250, 255, 205), Material = Enum.Material.Neon },
			Lighting = { Color = Color3.fromRGB(250, 255, 205), Material = Enum.Material.Neon },
			Roof = { Color = Color3.fromRGB(135, 134, 136), Material = Enum.Material.Concrete },
			Wall = { Color = Color3.fromRGB(74, 56, 46), Material = Enum.Material.Wood },
			Window = { Color = Color3.fromRGB(9, 137, 207), Material = Enum.Material.SmoothPlastic },
			WaterSmooth = { Color = Color3.fromRGB(17, 17, 17), Material = Enum.Material.SmoothPlastic },
			Metal = { Color = Color3.fromRGB(211, 174, 105), Material = Enum.Material.Metal },
			Stone = { Color = Color3.fromRGB(86, 70, 59), Material = Enum.Material.Slate },
			WaterRipple = { Color = Color3.fromRGB(13, 105, 172), Material = Enum.Material.Foil },
		},
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.DEFAULT_ID = DEFAULT_ID

Module.get = function(id: string): Result<ThemeDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no theme "{id}"`)
end

Module.list = function(): { ThemeDefinition }
	return DEFINITIONS
end

return Module
