--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local CONSTANTS = require("@self/CONSTANTS")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Result<V, E> = TypeUnionLib.Result<V, E>

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
local isAlignment = Type.literal(table.unpack(PseudoEnum.getEnumItems("Alignment")))

local function decode(value: string): Result<string, string>
	if value:match("^[imp]%d") then
		return Result.err(`Unresolved legacy code: {value}`)
	end
	return Result.ok(if value == "nons" then CONSTANTS.NONE else value)
end

local function decodeColor(value: string): Result<BrickColor, string>
	local mapped = COLORS[value] or COLOR_ALIASES[value]
	if mapped then
		return Result.ok(mapped)
	end
	local colorNumber = value:match("^b(%d+)$")
	if colorNumber then
		local number = tonumber(colorNumber)
		local color = if number then COLORS[`b{number}`] else nil
		if not color then
			return Result.err(`Unknown BrickColor code: {value}`)
		end
		return Result.ok(color)
	end
	local color = colorFromName(value)
	if color.Name ~= value then
		return Result.err(`Unknown BrickColor name: {value}`)
	end
	return Result.ok(color)
end

local function decodeMaterial(value: string): Result<Enum.Material, string>
	local mapped = MATERIALS[value]
	if mapped then
		return Result.ok(mapped)
	end
	if value:match("^m%d") then
		return Result.err(`Unresolved legacy code: {value}`)
	end
	local material = MaterialNames[value]
	if not material then
		return Result.err(`Unknown material name: {value}`)
	end
	return Result.ok(material)
end

local function readTextureGroup(values: { unknown }, index: number, path: string): Result<TextureGroup?, string>
	if values[index] == nil then
		return Result.ok(nil :: TextureGroup?)
	end
	local color = decodeColor(values[index] :: string)
	if color.IsErr then
		return Result.err(`{path}[{index}]: {color.Value}`)
	end
	local material: Enum.Material? = nil
	if values[index + 1] ~= nil then
		local decoded = decodeMaterial(values[index + 1] :: string)
		if decoded.IsErr then
			return Result.err(`{path}[{index + 1}]: {decoded.Value}`)
		end
		material = decoded.Value
	end
	return Result.ok({
		BrickColor = color.Value,
		Material = material,
	})
end

local function convertItem(raw: unknown, path: string): Result<Item?, string>
	local success, message = isItem(raw)
	if not success then
		return Result.err(`{path}: {message}`)
	end
	local values = raw :: { unknown }
	local name = values[1] :: string
	local id = ItemIds[name] or ItemIds[normalizeItemName(name)]
	if not id then
		if name:match("^i%d") and not KnownItemCodes[name] then
			return Result.err(`{path}: Unresolved legacy code: {name}`)
		end
		return Result.ok(nil :: Item?)
	end
	local primary = readTextureGroup(values, 2, path)
	if primary.IsErr then
		return primary
	end
	local item: Item = {
		Name = id,
		Primary = primary.Value,
	}
	if #values == 5 or #values == 6 then
		local secondary = readTextureGroup(values, if #values == 5 then 4 else 5, path)
		if secondary.IsErr then
			return secondary
		end
		item.Secondary = secondary.Value
		if #values == 6 then
			item.EyeTransparency = values[4] :: number
		end
	end
	return Result.ok(item)
end

local function convertItems(values: { unknown }, start: number, path: string): Result<{ Item }, string>
	local items: { Item } = {}
	for index = start, #values do
		local item = convertItem(values[index], `{path}[{index}]`)
		if item.IsErr then
			return item
		end
		if item.Value then
			table.insert(items, item.Value)
		end
	end
	return Result.ok(items)
end

local function convertPower(power: { string }, path: string): Result<Power, string>
	local name = decode(power[1])
	if name.IsErr then
		return Result.err(`{path}[1]: {name.Value}`)
	end
	local color: BrickColor? = nil
	if power[2] ~= nil then
		local decoded = decodeColor(power[2])
		if decoded.IsErr then
			return Result.err(`{path}[2]: {decoded.Value}`)
		end
		color = decoded.Value
	end
	return Result.ok({
		Name = name.Value,
		MasterColor = color,
	})
end

local function convertIdentity(raw: unknown, path: string): Result<Identity, string>
	local success, message = isIdentity(raw)
	if not success then
		return Result.err(`{path}: {message}`)
	end
	local values = raw :: { unknown }
	local shared = values[1] :: { unknown }
	local unique = values[2] :: { string }
	local powers: { Power } = {}
	for index, power in shared[1] :: { { string } } do
		local converted = convertPower(power, `{path}[1][1][{index}]`)
		if converted.IsErr then
			return converted
		end
		table.insert(powers, converted.Value)
	end
	local alignment = decode(shared[2] :: string)
	if alignment.IsErr then
		return Result.err(`{path}[1][2]: {alignment.Value}`)
	end
	local id = decode(shared[3] :: string)
	if id.IsErr then
		return Result.err(`{path}[1][3]: {id.Value}`)
	end
	local death = decode(shared[4] :: string)
	if death.IsErr then
		return Result.err(`{path}[1][4]: {death.Value}`)
	end
	local transformation = decode(shared[5] :: string)
	if transformation.IsErr then
		return Result.err(`{path}[1][5]: {transformation.Value}`)
	end
	local backstory = decode(unique[1])
	if backstory.IsErr then
		return Result.err(`{path}[2][1]: {backstory.Value}`)
	end
	local name = decode(unique[2])
	if name.IsErr then
		return Result.err(`{path}[2][2]: {name.Value}`)
	end
	local skin = decodeColor(values[3] :: string)
	if skin.IsErr then
		return Result.err(`{path}[3]: {skin.Value}`)
	end
	local items = convertItems(values, 4, path)
	if items.IsErr then
		return items
	end
	return Result.ok({
		SharedValues = {
			Powers = powers,
			Alignment = alignment.Value,
			CharacterID = id.Value,
			DeathAnimation = death.Value,
			TransformationAnimation = transformation.Value,
		},
		UniqueValues = {
			Backstory = backstory.Value,
			Nombre = name.Value,
		},
		SkinColor = skin.Value,
		Items = items.Value,
	})
end

local function convertProfileText(value: string): string
	return if value == CONSTANTS.NONE or value == "nons" then "" else value
end

local function convertAlignment(value: string): Result<PseudoEnum.Alignment, string>
	if value == CONSTANTS.NONE or value == "nons" or value == "Neutral" then
		return Result.ok(
				PseudoEnum.Alignment.TrueNeutral :: PseudoEnum.Alignment
			) :: TypeUnionLib.Ok<PseudoEnum.Alignment>
	end
	local alignment = value:gsub("%s+", "")
	local success, message = isAlignment(alignment)
	if not success then
		return Result.err(`Invalid legacy alignment "{value}": {message}`)
	end
	return Result.ok(alignment :: PseudoEnum.Alignment) :: TypeUnionLib.Ok<PseudoEnum.Alignment>
end

local function convertTextureGroup(
	template: Instance,
	group: AppearanceType.TextureGroupKey,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Result<AppearanceType.TextureGroup, string>
	local defaultMaterial: Enum.Material? = nil
	local defaultTransparency: number? = nil
	local instances = template:GetDescendants()
	table.insert(instances, 1, template)
	for _, instance in instances do
		if not instance:IsA("BasePart") or instance:GetAttribute("TextureGroup") ~= group then
			continue
		end
		-- One modern texture group cannot preserve conflicting per-part defaults.
		if material == nil and defaultMaterial ~= nil and defaultMaterial ~= instance.Material then
			return Result.err(`{template.Name}.{group} has mixed default materials; a saved material is required`)
		end
		if transparency == nil and defaultTransparency ~= nil and defaultTransparency ~= instance.Transparency then
			return Result.err(
				`{template.Name}.{group} has mixed default transparency; a saved transparency is required`
			)
		end
		defaultMaterial = instance.Material
		defaultTransparency = instance.Transparency
	end
	local finalMaterial = material or defaultMaterial
	local finalTransparency = if transparency ~= nil then transparency else defaultTransparency
	if finalMaterial == nil or finalTransparency == nil then
		return Result.err(`Missing template texture group: {template.Name}.{group}`)
	end
	return Result.ok({
		Color = color,
		Material = finalMaterial,
		Transparency = finalTransparency,
	})
end

local function convertAppearanceItem(item: Item, skinColor: BrickColor): Result<AppearanceType.Item, string>
	local ItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
	local definition = ItemDefinition.get(item.Name)
	if definition.IsErr then
		return definition
	end
	local template = ItemDefinition.getTemplate(item.Name)
	if template.IsErr then
		return template
	end
	local groups = definition.Value.TextureGroups
	local converted: AppearanceType.Item = {
		DefinitionId = item.Name,
		TextureGroups = {},
	}
	if item.Primary then
		local group: AppearanceType.TextureGroupKey? = if table.find(groups, "Primary")
			then "Primary"
			elseif table.find(groups, "Hair") then "Hair"
			else nil
		if group then
			local texture =
				convertTextureGroup(template.Value, group, item.Primary.BrickColor.Color, item.Primary.Material, nil)
			if texture.IsErr then
				return texture
			end
			converted.TextureGroups[group] = texture.Value
		end
	end
	-- Lens settings can only migrate once the mask template exposes Secondary.
	if item.Secondary and table.find(groups, "Secondary") then
		local texture = convertTextureGroup(
			template.Value,
			"Secondary",
			item.Secondary.BrickColor.Color,
			item.Secondary.Material,
			item.EyeTransparency
		)
		if texture.IsErr then
			return texture
		end
		converted.TextureGroups["Secondary" :: AppearanceType.TextureGroupKey] = texture.Value
	end
	if table.find(groups, "Skin") then
		local texture = convertTextureGroup(template.Value, "Skin", skinColor.Color, nil, nil)
		if texture.IsErr then
			return texture
		end
		converted.TextureGroups["Skin" :: AppearanceType.TextureGroupKey] = texture.Value
	end
	return Result.ok(converted)
end

local function convertFinalIdentity(identity: Identity): Result<IdentityType.Identity, string>
	local alignment = convertAlignment(identity.SharedValues.Alignment)
	if alignment.IsErr then
		return alignment
	end
	local items: { AppearanceType.Item } = {}
	for index, item in identity.Items do
		local converted = convertAppearanceItem(item, identity.SkinColor)
		if converted.IsErr then
			return Result.err(`item [{index}] ({item.Name}): {converted.Value}`)
		end
		table.insert(items, converted.Value)
	end
	return Result.ok({
		Profile = {
			Name = convertProfileText(identity.UniqueValues.Nombre),
			Backstory = convertProfileText(identity.UniqueValues.Backstory),
			Alignment = alignment.Value,
		},
		PowerSkins = {},
		Appearance = {
			Items = items,
			-- Transition currently has no fields for legacy animation styles.
			Transitions = {},
			HiddenTags = {},
		},
	})
end

-- Class
local Module = {}

Module.convertOutfit = function(raw: unknown): Result<Outfit, string>
	local success, message = isArray(raw)
	if not success then
		return Result.err(`outfit: {message}`)
	end
	local items = convertItems(raw :: { unknown }, 1, "outfit")
	if items.IsErr then
		return items
	end
	return Result.ok({ Items = items.Value })
end

Module.toCharacter = function(raw: unknown): Result<CharacterType.Character, string>
	local success, message = isStarterSuit(raw)
	if not success then
		return Result.err(`starter-suit: {message}`)
	end
	local values = raw :: { unknown }
	local secret = convertIdentity(values[1], "starter-suit[1]")
	if secret.IsErr then
		return secret
	end
	local super = convertIdentity(values[2], "starter-suit[2]")
	if super.IsErr then
		return super
	end
	local id = super.Value.SharedValues.CharacterID
	if id ~= secret.Value.SharedValues.CharacterID then
		return Result.err("Legacy identity CharacterIDs do not match")
	end
	local main = convertFinalIdentity(super.Value)
	if main.IsErr then
		return Result.err(`SuperIdentity: {main.Value}`)
	end
	local civilian = convertFinalIdentity(secret.Value)
	if civilian.IsErr then
		return Result.err(`SecretIdentity: {civilian.Value}`)
	end
	local character: CharacterType.Character = {
		Id = id,
		Powers = {},
		Identities = {
			Main = main.Value,
			Secret = civilian.Value,
		},
	}
	local valid, validationMessage = CharacterType.Character(character)
	if not valid then
		return Result.err(`Converted character failed validation: {validationMessage}`)
	end
	TableUtil.deepFreeze(character)
	return Result.ok(character)
end

return Module
