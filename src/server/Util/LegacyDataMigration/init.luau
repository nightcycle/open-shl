--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local CONSTANTS = require("@self/CONSTANTS")
-- Types
export type TextureGroup = {
	BrickColor: BrickColor,
	Material: Enum.Material?,
}

export type Item = {
	Name: string,
	Primary: TextureGroup?,
	Secondary: TextureGroup?,
	EyeTransparency: number?,
}

export type Power = {
	Name: string,
	MasterColor: BrickColor?,
}

export type SharedValues = {
	Powers: { Power },
	Alignment: string,
	CharacterID: string,
	DeathAnimation: string,
	TransformationAnimation: string,
}

export type Identity = {
	SharedValues: SharedValues,
	UniqueValues: {
		Backstory: string,
		Nombre: string,
	},
	SkinColor: BrickColor,
	Items: { Item },
}

export type Outfit = {
	Items: { Item },
}

export type StarterSuit = {
	SecretIdentity: Identity,
	SuperIdentity: Identity,
}

-- Constants
local COLORS: { [string]: BrickColor } = CONSTANTS.COLORS
local COLOR_ALIASES: { [string]: BrickColor } = CONSTANTS.COLOR_ALIASES
local MATERIALS: { [string]: Enum.Material } = CONSTANTS.MATERIALS
local ITEM_GROUPS: { [string]: { [string]: { [string]: string } } } = CONSTANTS.ITEMS
-- Variables
local ItemIds: { [string]: string } = {}
local KnownItemCodes: { [string]: boolean } = {}
local MaterialNames: { [string]: Enum.Material } = {}
-- References
-- Private Functions
local function normalizeItemName(value: string): string
	return (value:lower():gsub("%W", ""))
end

for _, categories in ITEM_GROUPS do
	for _, items in categories do
		for code, id in items do
			KnownItemCodes[code] = true
			if id ~= "" then
				ItemIds[code] = id
				ItemIds[id] = id
				local key = assert(id:match("^[^_]+_[^_]+_(.+)$"), `Invalid item definition ID: {id}`)
				ItemIds[normalizeItemName(key)] = id
			end
		end
	end
end
table.freeze(ItemIds)
table.freeze(KnownItemCodes)
for _, material in Enum.Material:GetEnumItems() do
	MaterialNames[material.Name] = material :: Enum.Material
end
table.freeze(MaterialNames)

local colorFromName = (BrickColor.new :: unknown) :: (string) -> BrickColor

local isArray = Type.array(Type.any)
local isItem = Type.intersection(
	isArray,
	Type.union(
		Type.strictArray(Type.string, Type.optional(Type.string), Type.optional(Type.string)),
		Type.strictArray(Type.string, Type.string, Type.string, Type.string, Type.string),
		Type.strictArray(Type.string, Type.string, Type.string, Type.numberConstrained(0, 1), Type.string, Type.string)
	)
)
local isPower = Type.intersection(Type.array(Type.string), Type.strictArray(Type.string, Type.optional(Type.string)))
local isSharedValues = Type.intersection(
	isArray,
	Type.strictArray(Type.array(isPower), Type.string, Type.string, Type.string, Type.string)
)
local isUniqueValues = Type.intersection(Type.array(Type.string), Type.strictArray(Type.string, Type.string))
local isIdentity = Type.intersection(
	isArray,
	Type.interface({
		[1] = isSharedValues,
		[2] = isUniqueValues,
		[3] = Type.string,
	})
)
local isStarterSuit = Type.intersection(isArray, Type.strictArray(isIdentity, isIdentity))

local function decode(value: string): string
	assert(not value:match("^[imp]%d"), `Unresolved legacy code: {value}`)
	return if value == "nons" then CONSTANTS.NONE else value
end

local function decodeColor(value: string): BrickColor
	local mapped = COLORS[value] or COLOR_ALIASES[value]
	if mapped then
		return mapped
	end
	local colorNumber = value:match("^b(%d+)$")
	if colorNumber then
		local number = tonumber(colorNumber)
		local color = if number then COLORS[`b{number}`] else nil
		assert(color, `Unknown BrickColor code: {value}`)
		return color
	end
	local color = colorFromName(value)
	assert(color.Name == value, `Unknown BrickColor name: {value}`)
	return color
end

local function decodeMaterial(value: string): Enum.Material
	local mapped = MATERIALS[value]
	if mapped then
		return mapped
	end
	assert(not value:match("^m%d"), `Unresolved legacy code: {value}`)
	return assert(MaterialNames[value], `Unknown material name: {value}`)
end

local function readTextureGroup(values: { unknown }, index: number): TextureGroup?
	if values[index] == nil then
		return nil
	end
	local material = values[index + 1] :: string?
	return {
		BrickColor = decodeColor(values[index] :: string),
		Material = if material ~= nil then decodeMaterial(material) else nil,
	}
end

local function convertItem(raw: unknown, path: string): Item?
	local success, message = isItem(raw)
	assert(success, `{path}: {message}`)
	local values = raw :: { unknown }
	local name = values[1] :: string
	local id = ItemIds[name] or ItemIds[normalizeItemName(name)]
	if not id then
		assert(not name:match("^i%d") or KnownItemCodes[name], `{path}: Unresolved legacy code: {name}`)
		return nil
	end
	local item: Item = {
		Name = id,
		Primary = readTextureGroup(values, 2),
	}
	if #values == 5 then
		item.Secondary = readTextureGroup(values, 4)
	elseif #values == 6 then
		item.EyeTransparency = values[4] :: number
		item.Secondary = readTextureGroup(values, 5)
	end
	return item
end

local function convertItems(values: { unknown }, start: number, path: string): { Item }
	local items: { Item } = {}
	for index = start, #values do
		local item = convertItem(values[index], `{path}[{index}]`)
		if item then
			table.insert(items, item)
		end
	end
	return items
end

local function convertIdentity(raw: unknown, path: string): Identity
	local values = raw :: { unknown }
	local shared = values[1] :: { unknown }
	local unique = values[2] :: { string }
	local powers: { Power } = {}
	for _, power in shared[1] :: { { string } } do
		table.insert(powers, {
			Name = decode(power[1]),
			MasterColor = if power[2] ~= nil then decodeColor(power[2]) else nil,
		})
	end
	return {
		SharedValues = {
			Powers = powers,
			Alignment = decode(shared[2] :: string),
			CharacterID = decode(shared[3] :: string),
			DeathAnimation = decode(shared[4] :: string),
			TransformationAnimation = decode(shared[5] :: string),
		},
		UniqueValues = {
			Backstory = decode(unique[1]),
			Nombre = decode(unique[2]),
		},
		SkinColor = decodeColor(values[3] :: string),
		Items = convertItems(values, 4, path),
	}
end

-- Class
local Module = {}

Module.convertOutfit = function(raw: unknown): Outfit
	local success, message = isArray(raw)
	assert(success, `outfit: {message}`)
	return { Items = convertItems(raw :: { unknown }, 1, "outfit") }
end

Module.convertStarterSuit = function(raw: unknown): StarterSuit
	local success, message = isStarterSuit(raw)
	assert(success, `starter-suit: {message}`)
	local values = raw :: { unknown }
	return {
		SecretIdentity = convertIdentity(values[1], "starter-suit[1]"),
		SuperIdentity = convertIdentity(values[2], "starter-suit[2]"),
	}
end

return Module
