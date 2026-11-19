--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
-- nil in a game where any color goes
local PALETTE: { Color3 }? = CharacterEditorDefinition.PALETTE
local CHANNEL_DEFAULTS: { [TextureGroupKey]: Color3 } = CharacterEditorDefinition.CHANNEL_DEFAULTS or table.freeze({})
-- Variables
-- References
-- Private Functions
local function getDistance(a: Color3, b: Color3): number
	return (a.R - b.R) ^ 2 + (a.G - b.G) ^ 2 + (a.B - b.B) ^ 2
end

-- the color of the palette that's closest to one that's off it
local function getNearest(palette: { Color3 }, color: Color3): Color3
	local nearest = palette[1]
	for _, choice in palette do
		if getDistance(choice, color) < getDistance(nearest, color) then
			nearest = choice
		end
	end
	return nearest
end

-- a color that's off the palette is the one its group starts out in. what starts out in no color of the game's, the
-- skin, is the closest one the palette has
local function fix(palette: { Color3 }, color: Color3, key: TextureGroupKey?): Color3
	return CharacterEditorDefinition.getPaletteColor(color)
		or (if key then CHANNEL_DEFAULTS[key] else nil)
		or getNearest(palette, color)
end

-- the groups an item holds in a color that's off the palette, each in the color it's held to. a group it holds
-- nothing for is worn the way the item was made, which is up to whoever made it
local function getFixedGroups(palette: { Color3 }, item: Item): { [TextureGroupKey]: TextureGroup }
	local out: { [TextureGroupKey]: TextureGroup } = {}
	for key: TextureGroupKey, group in item.TextureGroups do
		if not group then
			continue
		end
		local color = fix(palette, group.Color, key)
		if color ~= group.Color then
			out[key] = FreezeUtil.delta(group, function(t: TextureGroup): TextureGroup
				t.Color = color
				return t
			end)
		end
	end
	return out
end
-- Class
-- a game with a palette has its skin + everything that's worn in one of its colors. a picker offers no other, what a
-- client hands in can still be any color at all
local Util = {}

-- nothing here does anything in a game where this is false
Util.IS_ANY = PALETTE ~= nil

-- the look with every color of it held to the palette. the very look comes back when all of them are on it already
function Util.apply(appearance: Appearance): Appearance
	local palette = PALETTE
	if not palette or #palette == 0 then
		return appearance
	end
	local skinColor = fix(palette, appearance.SkinColor)
	local groups: { [number]: { [TextureGroupKey]: TextureGroup } } = {}
	for index, item in appearance.Items do
		local fixedGroups = getFixedGroups(palette, item)
		if next(fixedGroups) ~= nil then
			groups[index] = fixedGroups
		end
	end
	if skinColor == appearance.SkinColor and next(groups) == nil then
		return appearance
	end
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		t.SkinColor = skinColor
		for index, fixedGroups in groups do
			for key: TextureGroupKey, group in fixedGroups do
				t.Items[index].TextureGroups[key] = group
			end
		end
		return t
	end)
end

return Util
