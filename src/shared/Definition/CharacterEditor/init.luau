--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
-- Modules
local EditorPageDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor/Page")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
type Option<V> = TypeUnionLib.Option<V>
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
type EditorDefinition = CharacterEditorType.EditorDefinition
type PageDefinition = CharacterEditorType.PageDefinition
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
local ROOT_KEY = EditorPageDefinition.ROOT_KEY
local PATH_DELIMITER = "/"
-- two widths of a body are the same one when they're this close, a width went through a division on its way here
local SCALE_EPSILON = 0.001
-- which pages there are + how much of a name is kept is the game's own, the tree of another game is never required
local EDITOR: EditorDefinition = GameDefinition.pick({
	shl1 = function(): EditorDefinition
		return require("@self/SHL1")
	end,
	shl2 = function(): EditorDefinition
		return require("@self/SHL2")
	end,
	shl3 = function(): EditorDefinition
		return require("@self/SHL3")
	end,
})
assert(CharacterEditorType.EditorDefinition(EDITOR))
TableUtil.deepFreeze(EDITOR)
-- Variables
local ItemPaths: { [string]: string } = {}
-- the colors of the game's palette by their hex, none in a game without one
local PaletteColors: { [string]: Color3? } = {}
-- References
-- Private Functions
local function getPathSegments(path: string): { string }
	local segments = path:split(PATH_DELIMITER)
	if segments[1] == "" then
		table.remove(segments, 1)
	end
	if segments[1] == ROOT_KEY then
		table.remove(segments, 1)
	end
	if segments[#segments] == "" then
		table.remove(segments)
	end
	return segments
end
local function getParentPath(path: string): Option<string>
	local segments = getPathSegments(path)
	if #segments == 0 then
		return Option.none()
	end
	table.remove(segments)
	return Option.some(table.concat(segments, PATH_DELIMITER))
end

-- Class
local Module = {}

do
	-- a path is read from the root down, under a root of another name no page would be at the end of any
	local root = EDITOR.Root
	assert(root.Type == "Default" and root.Key == ROOT_KEY, `the root page isn't "{ROOT_KEY}"`)
end

do
	-- a body that's never been sized has to be one of the sizes that can be picked
	local scale = EDITOR.Scale
	if scale then
		local default = scale.Default
		local isRatio = false
		for _, ratio in scale.WidthRatios do
			isRatio = isRatio or math.abs(default.Width / default.Height - ratio) < SCALE_EPSILON
		end
		assert(table.find(scale.Heights, default.Height) ~= nil and isRatio, `the default body scale isn't offered`)
	end
end

do
	-- a color a group starts out in is one a picker could have put there
	local palette = EDITOR.Palette
	if palette then
		for _, color in palette do
			local hex = color:ToHex()
			assert(PaletteColors[hex] == nil, `the palette holds #{hex} twice`)
			PaletteColors[hex] = color
		end
		local channelDefaults: { [TextureGroupKey]: Color3 } = EDITOR.ChannelDefaults or {}
		for key, color in channelDefaults do
			assert(
				PaletteColors[color:ToHex()] ~= nil,
				`the "{key}" group starts out in a color that's off the palette`
			)
		end
	end
end

Module.MAX_NAME_LENGTH = EDITOR.MaxNameLength
Module.MAX_BACKSTORY_LENGTH = EDITOR.MaxBackstoryLength
Module.SCALE_EPSILON = SCALE_EPSILON
-- nil in a game without body sizes
Module.SCALE = EDITOR.Scale
-- what a pattern picker offers, nil in a game without patterns
Module.PATTERN_CHOICES = EDITOR.PatternChoices
-- nil in a game whose powers are colored by a pick of their own
Module.POWER_COLOR_SOURCE = EDITOR.PowerColorSource
-- the only colors skin + what's worn come in, nil in a game where any color goes
Module.PALETTE = EDITOR.Palette
-- what a texture group of something newly worn starts out in when nothing worn beside it holds one, nil in a game
-- where an item starts out the way it was made
Module.CHANNEL_DEFAULTS = EDITOR.ChannelDefaults
-- what an identity goes by when its name was left empty, the name of the account goes where the %s is. nil in a game
-- where an empty name stays empty
Module.NAME_DEFAULTS = EDITOR.NameDefaults
Module.DETAIL_TEXTURE_GROUP_KEY = EditorPageDefinition.DETAIL_TEXTURE_GROUP_KEY

Module.DEFINITION = EDITOR.Root

function Module.getPage(path: string): Option<PageDefinition>
	local segments = getPathSegments(path)
	table.insert(segments, 1, ROOT_KEY)
	local function getPage(pageDef: PageDefinition, index: number): Option<PageDefinition>
		local segment = segments[index]
		local key = if pageDef.Type == "Item" then pageDef.DefinitionId else pageDef.Key
		if key ~= segment then
			return Option.none()
		end
		if index == #segments then
			return Option.some(pageDef)
		end
		if pageDef.Type == "Default" and pageDef.Children then
			for _, child in pageDef.Children do
				local childOpt = getPage(child, index + 1)
				if childOpt.IsSome then
					return childOpt
				end
			end
		end
		return Option.none()
	end

	return getPage(Module.DEFINITION, 1)
end

Module.getParentPath = getParentPath

function Module.getParentPage(path: string): Option<PageDefinition>
	return Option.flatten(Option.map(getParentPath(path), function(parentPath: string): Option<PageDefinition>
		return Module.getPage(parentPath)
	end))
end

function Module.getChildPath(path: string, pageDef: PageDefinition): string
	local segments = getPathSegments(path)
	table.insert(segments, if pageDef.Type == "Item" then pageDef.DefinitionId else pageDef.Key)
	return table.concat(segments, PATH_DELIMITER)
end
function Module.findFirstFolderPath(path: string): string
	do
		local page = Module.getPage(path)
		if page.IsSome and page.Value.Type == "Default" and page.Value.Children then
			return path
		end
	end
	local parentPathOpt = getParentPath(path)
	while parentPathOpt.IsSome do
		local parentPage = Module.getPage(parentPathOpt.Value)
		if parentPage.IsSome then
			if parentPage.Value.Type == "Default" and parentPage.Value.Children then
				return parentPathOpt.Value
			else
				parentPathOpt = getParentPath(parentPathOpt.Value)
			end
		else
			return ""
		end
	end
	return ""
end
function Module.findFirstFolderPage(path: string): Option<PageDefinition>
	return Module.getPage(Module.findFirstFolderPath(path))
end

-- the same page can be spelled with or without the root + slashes around it, this is the spelling paths are compared in
function Module.fixPath(path: string): string
	return table.concat(getPathSegments(path), PATH_DELIMITER)
end

-- the color of the game's palette that a color is, nil for one that's off it. compared as hex: a color that went
-- through a save or a remote may not be bit equal to its choice. any color is itself in a game without a palette
function Module.getPaletteColor(color: Color3): Color3?
	if EDITOR.Palette == nil then
		return color
	end
	return PaletteColors[color:ToHex()]
end

-- none for an item the editor doesn't offer (an artifact)
function Module.getItemPath(definitionId: string): Option<string>
	return Option.from(ItemPaths[definitionId])
end

Module.getMainTextureGroup = EditorPageDefinition.getMainTextureGroup

do
	local function indexItemPaths(pageDef: PageDefinition, path: string)
		if pageDef.Type == "Item" then
			ItemPaths[pageDef.DefinitionId] = path
		elseif pageDef.Type == "Default" and pageDef.Children then
			for _, child in pageDef.Children do
				indexItemPaths(child, Module.getChildPath(path, child))
			end
		end
	end
	indexItemPaths(Module.DEFINITION, "")
end

return Module
