--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local IdentityConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RandomMisc = require("@game/ReplicatedStorage/Shared/Random/Misc")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterRollType = require("@game/ServerScriptService/Server/Type/CharacterRoll")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Item = AppearanceType.Item
type TextureGroupKey = AppearanceType.TextureGroupKey
type Character = CharacterType.Character
type Power = CharacterType.Power
type Identity = IdentityType.Identity
type Entry = CharacterRollType.Entry
type PowerKind = CharacterRollType.PowerKind
type Source = CharacterRollType.Source
type Tables = CharacterRollType.Tables
type WeightedColor = CharacterRollType.WeightedColor
-- the entries of the catalogue that hold an item of a category, which is what one shelf of it offers
type Shelves = { [string]: { Entry } }
type Colors = { [TextureGroupKey]: Color3 }
-- Constants
local CATEGORY_FORMAT = "%s/%s"
-- where in the library the things a character is dealt sit
local HAIR_CATEGORY = "cosmetics/hair"
local FACIAL_HAIR_CATEGORY = "cosmetics/facial-hair"
local EYES_CATEGORY = "cosmetics/eyes"
local MOUTH_CATEGORY = "cosmetics/mouth"
local HEAD_CATEGORY = "costume/suit-head"
-- the torso leads: a suit is dealt as the one its torso piece is of
local BODY_CATEGORIES = table.freeze({
	"costume/suit-torso",
	"costume/suit-left-arm",
	"costume/suit-right-arm",
	"costume/suit-left-leg",
	"costume/suit-right-leg",
})
local EMBLEM_CATEGORY = "costume/emblems"
local CAPE_CATEGORY = "costume/capes"
local SHIRT_CATEGORY = "clothing/shirts"
local PANTS_CATEGORY = "clothing/pants"
local GLASSES_CATEGORY = "clothing/glasses"
local HAT_CATEGORY = "clothing/hats"
-- a secondary color that isn't the opposite is the primary, dimmed to so many hundredths of itself
local DIM_STEP_COUNT = 100
-- the layer under a suit is a grey, in tenths of white: a light one under dark colors + a dark one under light colors
local BASE_STEP_COUNT = 10
local MAX_DARK_BRIGHTNESS = 0.5
local LIGHT_BASE_STEPS = NumberRange.new(5, 10)
local DARK_BASE_STEPS = NumberRange.new(1, 5)
local MAX_NAME_LENGTH = CharacterEditorDefinition.MAX_NAME_LENGTH
local MAX_BACKSTORY_LENGTH = CharacterEditorDefinition.MAX_BACKSTORY_LENGTH
-- nil in a game whose bodies come in one size
local SCALE = CharacterEditorDefinition.SCALE
-- Variables
-- References
-- Private Functions
local function toColor(channels: CharacterRollType.Channels): Color3
	return Color3.fromRGB(channels[1], channels[2], channels[3])
end

local function getIfDrawn(rng: Random, chance: number): boolean
	return rng:NextNumber() < chance
end

local function drawWeighted(rng: Random, colors: { WeightedColor }): Color3
	local total = 0
	for _, color in colors do
		total += color.Weight
	end
	local ticket = rng:NextInteger(1, total)
	for _, color in colors do
		ticket -= color.Weight
		if ticket <= 0 then
			return toColor(color.Color)
		end
	end
	return toColor(colors[#colors].Color)
end

local function getCategory(itemId: string): string?
	local indexRes = ItemAppearanceDefinition.getIndex(itemId)
	if indexRes.IsErr then
		return nil
	end
	return string.format(CATEGORY_FORMAT, indexRes.Value.Group, indexRes.Value.Category)
end

local function getItemId(entry: Entry, category: string): string?
	for _, itemId in entry.ItemIds do
		if getCategory(itemId) == category then
			return itemId
		end
	end
	return nil
end

local function getShelves(entries: { Entry }): Shelves
	local shelves: Shelves = {}
	for _, entry in entries do
		for _, itemId in entry.ItemIds do
			local category = getCategory(itemId)
			if not category then
				continue
			end
			local shelf = shelves[category] or {}
			shelves[category] = shelf
			if not table.find(shelf, entry) then
				table.insert(shelf, entry)
			end
		end
	end
	return shelves
end

-- one of what the player owns on a shelf. somebody who owns nothing on it is dealt from all of it, + what's never
-- rolled is left out either way: a shelf can come up empty for somebody who only owns that
local function draw(rng: Random, source: Source, shelves: Shelves, category: string): Entry?
	local shelf: { Entry } = shelves[category] or {}
	local isAnyOwned = false
	for _, entry in shelf do
		isAnyOwned = isAnyOwned or entry.IsOwned
	end
	local choices: { Entry } = {}
	for _, entry in shelf do
		local isRolled = entry.IsOwned or not isAnyOwned
		for _, itemId in entry.ItemIds do
			isRolled = isRolled and table.find(source.Tables.NeverRolled, itemId) == nil
		end
		if isRolled then
			table.insert(choices, entry)
		end
	end
	if #choices == 0 then
		return nil
	end
	return choices[rng:NextInteger(1, #choices)]
end

-- the item of an entry that sits in a category, in the colors of the groups it has
local function newItem(entry: Entry?, category: string, colors: Colors): Item?
	local itemId = if entry then getItemId(entry, category) else nil
	if not itemId then
		return nil
	end
	local definitionRes = ItemAppearanceDefinition.get(itemId)
	if definitionRes.IsErr then
		return nil
	end
	local item: Item = {
		DefinitionId = itemId,
		TextureGroups = {},
	}
	for _, key: TextureGroupKey in definitionRes.Value.TextureGroups do
		local color = colors[key]
		if color then
			item.TextureGroups[key] = TextureGroupConstructor.new(color)
		end
	end
	return item
end

local function insertItem(items: { Item }, entry: Entry?, category: string, colors: Colors): Item?
	local item = newItem(entry, category, colors)
	if item then
		table.insert(items, item)
	end
	return item
end

local function clip(text: string, maxLength: number): string
	local cutOff = utf8.offset(text, maxLength + 1)
	return if cutOff then string.sub(text, 1, cutOff - 1) else text
end

local function getIfFitting(text: string, maxLength: number): boolean
	local length = utf8.len(text)
	return length ~= nil and length <= maxLength
end

-- a name that's too long loses what was put around it first: the suffix, then the title, then the second surname
local function newCivilianName(rng: Random, tables: Tables): string
	local chances = tables.Chances
	local firstName = RandomMisc.literal(RandomUtil.newSeed(rng), tables.FirstNames)
	local lastName = RandomMisc.literal(RandomUtil.newSeed(rng), tables.LastNames)
	local name = `{firstName} {lastName}`
	local longLastName = if getIfDrawn(rng, chances.HyphenatedLastName)
		then `{name}-{RandomMisc.literal(RandomUtil.newSeed(rng), tables.LastNames)}`
		else name
	local title = if getIfDrawn(rng, chances.Title)
		then `{RandomMisc.literal(RandomUtil.newSeed(rng), tables.Titles)} `
		else ""
	local suffix = if getIfDrawn(rng, chances.Suffix)
		then ` {RandomMisc.literal(RandomUtil.newSeed(rng), tables.Suffixes)}`
		else ""
	for _, candidate in { `{title}{longLastName}{suffix}`, `{title}{longLastName}`, longLastName, name } do
		if getIfFitting(candidate, MAX_NAME_LENGTH) then
			return candidate
		end
	end
	return clip(name, MAX_NAME_LENGTH)
end

-- a hero goes by an adjective + a noun, now + then the adjective is the color they wear
local function newAlias(rng: Random, tables: Tables, colorName: string): string
	local adjective = RandomMisc.literal(RandomUtil.newSeed(rng), tables.AliasAdjectives)
	if getIfDrawn(rng, tables.Chances.ColorAlias) then
		adjective = colorName
	end
	return clip(`{adjective} {RandomMisc.literal(RandomUtil.newSeed(rng), tables.AliasNouns)}`, MAX_NAME_LENGTH)
end

-- where they come from + what set them off. one that runs long ends with its last whole word
local function newBackstory(rng: Random, tables: Tables): string
	local origin = RandomMisc.literal(RandomUtil.newSeed(rng), tables.Origins)
	local motivation = RandomMisc.literal(RandomUtil.newSeed(rng), tables.Motivations)
	local backstory = `{origin} {motivation}`
	if getIfFitting(backstory, MAX_BACKSTORY_LENGTH) then
		return backstory
	end
	-- one character more than fits: a word that ends right at the limit is still whole
	local clipped = clip(backstory, MAX_BACKSTORY_LENGTH + 1)
	return string.match(clipped, "^(.*%S)%s+%S*$") or clip(backstory, MAX_BACKSTORY_LENGTH)
end

local function getKind(tables: Tables, powerId: string): PowerKind?
	local definitionRes = PowerDefinition.get(powerId)
	if definitionRes.IsErr then
		return nil
	end
	for _, kind in tables.PowerKinds do
		if table.find(kind.Groups, definitionRes.Value.Group) then
			return kind
		end
	end
	return nil
end

-- so many of each kind out of what a new player may be dealt, each of them once. a kind that's short gives what it has
local function newPowers(rng: Random, tables: Tables): { Power }
	local powers: { Power } = {}
	for _, kind in tables.PowerKinds do
		local choices: { string } = {}
		for _, powerId in tables.StarterPowerIds do
			if getKind(tables, powerId) == kind and not table.find(choices, powerId) then
				table.insert(choices, powerId)
			end
		end
		for _ = 1, math.min(kind.Count, #choices) do
			table.insert(powers, { Id = table.remove(choices, rng:NextInteger(1, #choices)) :: string })
		end
	end
	return powers
end

-- the power an item calls for takes the place of the first power of its kind, unless it's carried already or the
-- character has none of that kind to give up
local function forcePower(tables: Tables, powers: { Power }, itemId: string)
	for _, forcedPower in tables.ForcedPowers do
		local kind = getKind(tables, forcedPower.PowerId)
		if forcedPower.ItemId ~= itemId or not kind then
			continue
		end
		local index: number? = nil
		for powerIndex, power in powers do
			if power.Id == forcedPower.PowerId then
				return
			end
			if not index and getKind(tables, power.Id) == kind then
				index = powerIndex
			end
		end
		if index then
			powers[index] = { Id = forcedPower.PowerId }
		end
	end
end
-- Class
local Module = {}

-- a character the way the game deals one to somebody who asks for a new one: a hero in one suit of two colors with a
-- civilian in plain clothes behind it, out of what the source says is owned. it comes without an id
Module.Character = function(source: Source, seed: number?): Character
	local rng = Random.new(seed)
	local tables = source.Tables
	local chances = tables.Chances
	local shelves = getShelves(source.Entries)

	local primary = RandomMisc.literal(RandomUtil.newSeed(rng), tables.Primaries)
	local primaryColor = toColor(primary.Color)
	local secondaryColor = primaryColor
	if getIfDrawn(rng, chances.OppositeSecondary) then
		for _, other in tables.Primaries do
			if other.Name == primary.Opposite then
				secondaryColor = toColor(other.Color)
			end
		end
	else
		local dim = rng:NextInteger(1, DIM_STEP_COUNT) / DIM_STEP_COUNT
		secondaryColor = Color3.new(primaryColor.R * dim, primaryColor.G * dim, primaryColor.B * dim)
	end
	local brightness = (
		primaryColor.R
		+ primaryColor.G
		+ primaryColor.B
		+ secondaryColor.R
		+ secondaryColor.G
		+ secondaryColor.B
	) / 6
	local baseSteps = if brightness <= MAX_DARK_BRIGHTNESS then LIGHT_BASE_STEPS else DARK_BASE_STEPS
	local base = rng:NextInteger(baseSteps.Min, baseSteps.Max) / BASE_STEP_COUNT
	local suitColors: Colors = {
		Primary = primaryColor,
		Secondary = secondaryColor,
		Tertiary = Color3.new(base, base, base),
	}

	-- what both identities wear: they're one person
	local skinColor = drawWeighted(rng, tables.SkinColors)
	local hairColors: Colors = { Hair = drawWeighted(rng, tables.HairColors) }
	local sharedItems: { Item } = {}
	insertItem(sharedItems, draw(rng, source, shelves, HAIR_CATEGORY), HAIR_CATEGORY, hairColors)
	if getIfDrawn(rng, chances.FacialHair) then
		insertItem(sharedItems, draw(rng, source, shelves, FACIAL_HAIR_CATEGORY), FACIAL_HAIR_CATEGORY, hairColors)
	end
	insertItem(
		sharedItems,
		draw(rng, source, shelves, EYES_CATEGORY),
		EYES_CATEGORY,
		{ Primary = drawWeighted(rng, tables.EyeColors) }
	)
	insertItem(sharedItems, draw(rng, source, shelves, MOUTH_CATEGORY), MOUTH_CATEGORY, {})

	local mainItems = table.clone(sharedItems)
	local suit = draw(rng, source, shelves, BODY_CATEGORIES[1])
	for _, category in BODY_CATEGORIES do
		insertItem(mainItems, suit, category, suitColors)
	end
	-- the head is dealt on its own, it's mostly the helmet of another suit
	if getIfDrawn(rng, chances.HeadPiece) then
		insertItem(mainItems, draw(rng, source, shelves, HEAD_CATEGORY), HEAD_CATEGORY, suitColors)
	end
	if getIfDrawn(rng, chances.Emblem) then
		insertItem(mainItems, draw(rng, source, shelves, EMBLEM_CATEGORY), EMBLEM_CATEGORY, suitColors)
	end
	local powers = newPowers(rng, tables)
	if getIfDrawn(rng, chances.Cape) then
		local cape = insertItem(
			mainItems,
			draw(rng, source, shelves, CAPE_CATEGORY),
			CAPE_CATEGORY,
			{ Primary = secondaryColor }
		)
		if cape then
			forcePower(tables, powers, cape.DefinitionId)
		end
	end
	while #powers > PowerDefinition.DEFAULT_LIMIT do
		table.remove(powers)
	end

	local secretItems = table.clone(sharedItems)
	insertItem(secretItems, draw(rng, source, shelves, SHIRT_CATEGORY), SHIRT_CATEGORY, {
		Primary = toColor(RandomMisc.literal(RandomUtil.newSeed(rng), tables.ShirtColors).Color),
		Secondary = toColor(RandomMisc.literal(RandomUtil.newSeed(rng), tables.DetailColors).Color),
	})
	insertItem(secretItems, draw(rng, source, shelves, PANTS_CATEGORY), PANTS_CATEGORY, {
		Primary = toColor(RandomMisc.literal(RandomUtil.newSeed(rng), tables.PantsColors).Color),
		Secondary = toColor(RandomMisc.literal(RandomUtil.newSeed(rng), tables.DetailColors).Color),
	})
	if getIfDrawn(rng, chances.Glasses) then
		insertItem(secretItems, draw(rng, source, shelves, GLASSES_CATEGORY), GLASSES_CATEGORY, {})
	end
	if getIfDrawn(rng, chances.Hat) then
		insertItem(secretItems, draw(rng, source, shelves, HAT_CATEGORY), HAT_CATEGORY, {})
	end

	local backstory = newBackstory(rng, tables)
	local function newIdentity(name: string, items: { Item }): Identity
		local identity = TableUtil.deepCopy(IdentityConstructor.new())
		identity.Profile.Name = name
		identity.Profile.Backstory = backstory
		identity.Appearance.Items = items
		identity.Appearance.SkinColor = skinColor
		identity.Appearance.Scale = if SCALE then SCALE.Default else nil
		return identity
	end
	local out: Character = {
		Id = "",
		Powers = powers,
		Identities = {
			Main = newIdentity(newAlias(rng, tables, primary.Name), mainItems),
			Secret = newIdentity(newCivilianName(rng, tables), secretItems),
		},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
