--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
local CONSTANTS = require("@self/CONSTANTS")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type BaseInventory = BaseType.BaseInventory
type BaseLayout = BaseType.BaseLayout
type PlacedFurniture = BaseType.PlacedFurniture

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

-- { name, hair, masks, hoods, mouth covers }: the artifact a player wore last, "None" for none, + whether each of
-- those was left showing under it
export type WornArtifact = { string | boolean }

-- Constants
local COLORS: { [string]: BrickColor } = CONSTANTS.COLORS
local COLOR_ALIASES: { [string]: BrickColor } = CONSTANTS.COLOR_ALIASES
local MATERIALS: { [string]: Enum.Material } = CONSTANTS.MATERIALS
local ITEM_GROUPS: { [string]: { [string]: { [string]: string } } } = CONSTANTS.ITEMS
local ITEM_ALIASES: { [string]: string } = CONSTANTS.ITEM_ALIASES
local POWERS: { [string]: string } = CONSTANTS.POWERS
local DEATH_STYLES: { [string]: string } = CONSTANTS.DEATH_STYLES
local TRANSFORMATION_STYLES: { [string]: string } = CONSTANTS.TRANSFORMATION_STYLES
local FACE_SLOTS: { AppearanceType.FaceSlot } = table.freeze({ "Eyebrows" :: AppearanceType.FaceSlot, "Eyes", "Mouth" })
local ITEM_NAMES: { [string]: string } = CONSTANTS.ITEM_NAMES
local ARTIFACT_ALIASES: { [string]: string } = CONSTANTS.ARTIFACT_ALIASES
local ARTIFACT_GROUP: AppearanceType.ItemGroup = "costume"
local ARTIFACT_CATEGORY = "artifacts"
-- what the old game stored in place of a slot, an identity or an artifact that wasn't there
local NOTHING = "None"
-- in the order a worn artifact lists what it left showing
local HIDDEN_TAGS: { AppearanceType.HiddenTag } =
	table.freeze({ "Hair" :: AppearanceType.HiddenTag, "Mask", "Hood", "MouthCover" })
local MAX_TEXT_LENGTH: number = CONSTANTS.MAX_TEXT_LENGTH
-- no save held more slots or a hero more powers than the passes for them unlock, one a client tampered with can
local MAX_SLOT_COUNT = ProductDefinition.getCharacterSlotCount({ "ExtraCharacterSlots" })
local MAX_POWER_COUNT = PowerDefinition.PASS_LIMIT
local PLACEMENT = FurnitureDefinition.PLACEMENT
-- the pieces of a base that show something, it's stored behind their CFrame
local SUIT_DISPLAY_NAME = "Suit Display"
local PEDESTAL_NAMES = table.freeze({ "Round Artifact Pedestal", "Square Artifact Pedestal" })
-- Variables
local ItemIds: { [string]: string } = {}
local MaterialNames: { [string]: Enum.Material } = {}
-- every text of a save went through the coder of the old game, one that was a word of it ("Ice", "Tornado") is
-- stored as the code of that word
local CodedTexts: { [string]: string } = {}
-- the three below are keyed by the name the old game stored them under
local ArtifactIds: { [string]: string } = {}
local FurnitureIds: { [string]: string } = {}
local ThemeIds: { [string]: string } = {}
-- References
-- Private Functions
local function normalizeItemName(value: string): string
	return (value:lower():gsub("%W", ""))
end

for _, categories in ITEM_GROUPS do
	for _, items in categories do
		for code, id in items do
			if id ~= "" then
				ItemIds[code] = id
				ItemIds[id] = id
				local key = assert(id:match("^[^_]+_[^_]+_(.+)$"), `Invalid item definition ID: {id}`)
				local name = key
				-- Every face slot holds the same keys, legacy told them apart by the slot in the name.
				for _, slot: AppearanceType.FaceSlot in FACE_SLOTS do
					if ItemAppearanceDefinition.getFaceId(slot, key) == id then
						name ..= slot
					end
				end
				ItemIds[normalizeItemName(name)] = id
			end
		end
	end
end
for name, id in ITEM_ALIASES do
	ItemIds[normalizeItemName(name)] = id
end
table.freeze(ItemIds)
for _, material in Enum.Material:GetEnumItems() do
	MaterialNames[material.Name] = material :: Enum.Material
end
table.freeze(MaterialNames)
do
	-- a power is listed under its code + under the name of its tool, the name is what the code stood for
	local powerNames: { [string]: string } = {}
	for name, id in POWERS do
		if not name:match("^p%d") then
			powerNames[id] = name
		end
	end
	for code, id in POWERS do
		if code:match("^p%d") then
			CodedTexts[code] = powerNames[id]
		end
	end
end
for code, material in MATERIALS do
	CodedTexts[code] = material.Name
end
for code, color in COLORS do
	CodedTexts[code] = color.Name
end
for code, name in ITEM_NAMES do
	CodedTexts[code] = name
end
table.freeze(CodedTexts)
for _, itemDef in ItemAppearanceDefinition.list(ARTIFACT_GROUP, ARTIFACT_CATEGORY) do
	if itemDef.Name then
		ArtifactIds[itemDef.Name] = itemDef.Id
	end
end
for name, id in ARTIFACT_ALIASES do
	ArtifactIds[name] = id
end
table.freeze(ArtifactIds)
for _, definition in FurnitureDefinition.list() do
	FurnitureIds[definition.Name] = definition.Id
end
table.freeze(FurnitureIds)
for _, definition in ThemeDefinition.list() do
	ThemeIds[definition.Name] = definition.Id
end
table.freeze(ThemeIds)

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
-- the two styles at its end can be missing: a slot the old game added for the slots pass could lose them on its way
-- through a client
local isSharedValues = Type.intersection(
	isArray,
	Type.strictArray(
		Type.array(isPower),
		Type.string,
		Type.string,
		Type.optional(Type.string),
		Type.optional(Type.string)
	)
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
-- a slot of a save: its id, then the secret + the super identity
local isSlot = Type.intersection(isArray, Type.strictArray(Type.string, isIdentity, isIdentity))
-- a piece of a base: its pad, its name, the 12 numbers of its CFrame on the pad + sometimes what it displayed. the
-- pad isn't checked here, a save can hold it as a text
local isPiece = Type.interface({
	[2] = Type.string,
	[3] = Type.strictArray(table.unpack(table.create(12, Type.number))),
})
local isAlignment = Type.literal(table.unpack(PseudoEnum.getEnumItems("Alignment")))

-- json has null where a list had a hole, so a list that's read back can skip an index
local function getLength(list: { [number]: unknown }): number
	local length = 0
	for index in list do
		length = math.max(length, index)
	end
	return length
end

-- what's said about a value that was left out, a save can hold anything in any length
local function describe(value: unknown): string
	if type(value) == "string" then
		return `"{value:sub(1, 40)}"`
	end
	return `a {typeof(value)}`
end

-- a color the old game couldn't place came out as the grey a BrickColor falls back to
local function decodeColor(value: string): BrickColor
	return COLORS[value] or COLOR_ALIASES[value] or colorFromName(value)
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
	local material: Enum.Material? = nil
	if values[index + 1] ~= nil then
		local decoded = decodeMaterial(values[index + 1] :: string)
		if decoded.IsErr then
			return Result.err(`{path}[{index + 1}]: {decoded.Value}`)
		end
		material = decoded.Value
	end
	return Result.ok({
		BrickColor = decodeColor(values[index] :: string),
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
	-- the old game dressed a character in what it still had + skipped the rest, an item it dropped along the way
	-- can still be in a save
	if not id then
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

local function convertPower(power: { string }, path: string): Result<Power?, string>
	local name = power[1]
	local id: string? = POWERS[name]
	if not id then
		-- Legacy skipped a power it no longer had, the rest of the character is kept.
		return Result.ok(nil :: Power?)
	end
	local definition = PowerDefinition.get(id)
	if definition.IsErr then
		return Result.err(`{path}[1]: {definition.Value}`)
	end
	local color: BrickColor? = nil
	-- Legacy only applied a saved color to the powers that can be recolored.
	if power[2] ~= nil and definition.Value.ColorGroups.Primary then
		color = decodeColor(power[2])
	end
	return Result.ok({
		Name = definition.Value.Id,
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
	local powerNames: { [string]: boolean } = {}
	for index, power in shared[1] :: { { string } } do
		local converted = convertPower(power, `{path}[1][1][{index}]`)
		if converted.IsErr then
			return converted
		end
		-- Power skins are keyed by power, so a repeated power can only be kept once.
		if converted.Value and not powerNames[converted.Value.Name] and #powers < MAX_POWER_COUNT then
			powerNames[converted.Value.Name] = true
			table.insert(powers, converted.Value)
		end
	end
	local items = convertItems(values, 4, path)
	if items.IsErr then
		return items
	end
	return Result.ok({
		SharedValues = {
			Powers = powers,
			Alignment = shared[2] :: string,
			CharacterID = shared[3] :: string,
			DeathAnimation = (shared[4] or CONSTANTS.NONE) :: string,
			TransformationAnimation = (shared[5] or CONSTANTS.NONE) :: string,
		},
		UniqueValues = {
			Backstory = unique[1],
			Nombre = unique[2],
		},
		SkinColor = decodeColor(values[3] :: string),
		Items = items.Value,
	})
end

-- nothing a player typed turns a character down: a text that can't be read comes out empty + one that's too long
-- is cut where the old game would have cut it
local function convertProfileText(value: string): string
	if value == CONSTANTS.NONE or value == "nons" then
		return ""
	end
	local text = CodedTexts[value] or value
	local length = utf8.len(text)
	if not length then
		return ""
	end
	local cutOff = if length > MAX_TEXT_LENGTH then utf8.offset(text, MAX_TEXT_LENGTH + 1) else nil
	return if cutOff then string.sub(text, 1, cutOff - 1) else text
end

-- an alignment, a death or a transformation this game has no name for reads as if none was picked, a character
-- isn't turned down over it
local function convertAlignment(value: string): PseudoEnum.Alignment
	local alignment = value:gsub("%s+", "")
	return if isAlignment(alignment) then alignment :: PseudoEnum.Alignment else PseudoEnum.Alignment.TrueNeutral
end

local function convertDeathTransition(value: string): AppearanceType.DeathTransition?
	local style: string? = DEATH_STYLES[value]
	if not style then
		return nil
	end
	local transition: AppearanceType.DeathTransition = {
		Style = style :: PseudoEnum.DeathStyle,
	}
	return transition
end

local function convertTransformationTransition(value: string): AppearanceType.TransformationTransition?
	local style: string? = TRANSFORMATION_STYLES[value]
	if not style then
		return nil
	end
	local transition: AppearanceType.TransformationTransition = {
		Style = style :: PseudoEnum.TransformationStyle,
	}
	return transition
end

local function convertPowerSkins(powers: { Power }): { [string]: IdentityType.PowerSkin }
	local skins: { [string]: IdentityType.PowerSkin } = {}
	for _, power in powers do
		-- A power without a saved color keeps the default of its definition.
		if power.MasterColor then
			skins[power.Name] = {
				Id = power.Name,
				ColorGroups = {
					Primary = power.MasterColor.Color,
				},
			}
		end
	end
	return skins
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

local function convertAppearanceItem(
	item: Item,
	definition: AppearanceType.ItemDefinition
): Result<AppearanceType.Item, string>
	local converted: AppearanceType.Item = {
		DefinitionId = item.Name,
		TextureGroups = {},
	}
	-- A face is an image, it has no template and no texture groups to fill.
	if definition.Type == "Face" then
		return Result.ok(converted)
	end
	local template = ItemAppearanceDefinition.getTemplate(item.Name)
	if template.IsErr then
		return template
	end
	local groups = definition.TextureGroups
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
	-- Skin parts are left out, they fall back to the SkinColor of the appearance.
	return Result.ok(converted)
end

local function convertAppearanceItems(legacyItems: { Item }): Result<{ AppearanceType.Item }, string>
	local items: { AppearanceType.Item } = {}
	local itemIndexes: { [string]: number } = {}
	for index, item in legacyItems do
		local definition = ItemAppearanceDefinition.get(item.Name)
		if definition.IsErr then
			return Result.err(`item [{index}] ({item.Name}): {definition.Value}`)
		end
		local converted = convertAppearanceItem(item, definition.Value)
		if converted.IsErr then
			return Result.err(`item [{index}] ({item.Name}): {converted.Value}`)
		end
		-- An item is worn once and a face slot holds one item, the newest stays like AppearanceConstructor.fix.
		local key: string = if definition.Value.Type == "Face" then definition.Value.Slot else item.Name
		local itemIndex: number? = itemIndexes[key]
		if itemIndex then
			items[itemIndex] = converted.Value
			continue
		end
		itemIndexes[key] = #items + 1
		table.insert(items, converted.Value)
	end
	return Result.ok(items)
end

local function convertFinalIdentity(identity: Identity): Result<IdentityType.Identity, string>
	local items = convertAppearanceItems(identity.Items)
	if items.IsErr then
		return items
	end
	return Result.ok({
		Profile = {
			Name = convertProfileText(identity.UniqueValues.Nombre),
			Backstory = convertProfileText(identity.UniqueValues.Backstory),
			Alignment = convertAlignment(identity.SharedValues.Alignment),
		},
		PowerSkins = convertPowerSkins(identity.SharedValues.Powers),
		Appearance = {
			Items = items.Value,
			SkinColor = identity.SkinColor.Color,
			-- An unset style is left out, a missing transition plays the legacy default.
			Transitions = {
				Death = convertDeathTransition(identity.SharedValues.DeathAnimation),
				Transformation = convertTransformationTransition(identity.SharedValues.TransformationAnimation),
			},
			HiddenTags = {},
		},
	})
end

-- the two identities sit next to each other in a starter suit + in a slot, a slot has its id in front of them
local function convertCharacter(values: { unknown }, path: string, start: number): Result<Character, string>
	local secret = convertIdentity(values[start], `{path}[{start}]`)
	if secret.IsErr then
		return secret
	end
	local super = convertIdentity(values[start + 1], `{path}[{start + 1}]`)
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
	-- Both identities carry a copy of the shared values, the powers are read from the super one.
	local powers: { CharacterType.Power } = {}
	for _, power in super.Value.SharedValues.Powers do
		table.insert(powers, { Id = power.Name })
	end
	local character: Character = {
		Id = id,
		Powers = powers,
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

-- each identity carries a copy of the id of its slot. the old game wrote it over them every time it loaded a save, the
-- copies can be behind + the slots it added for the slots pass came without one
local function fillId(identity: unknown, id: unknown): unknown
	if type(identity) ~= "table" or type((identity :: { unknown })[1]) ~= "table" then
		return identity
	end
	local out = table.clone(identity :: { unknown })
	local shared = table.clone(out[1] :: { unknown })
	shared[3] = id
	out[1] = shared
	return out
end

local function convertSlot(raw: unknown): Result<Character, string>
	if raw == NOTHING or (type(raw) == "table" and (raw :: { unknown })[2] == NOTHING) then
		return Result.err(`nothing was saved to it`)
	end
	local slot = raw
	if type(raw) == "table" then
		local filled = table.clone(raw :: { unknown })
		filled[2] = fillId(filled[2], filled[1])
		filled[3] = fillId(filled[3], filled[1])
		slot = filled
	end
	local success, message = isSlot(slot)
	if not success then
		return Result.err(`{message}`)
	end
	local values = slot :: { unknown }
	local id = values[1] :: string
	-- a slot is found by its id + the id is stored with it
	if id == "" or utf8.len(id) == nil then
		return Result.err(`it has no id that can be read`)
	end
	return convertCharacter(values, "slot", 2)
end

-- the old game checked if a piece was on its pad one step of the mouse late, so a piece that was put down at the
-- edge can hang over it. left out it would be gone for good, it's moved in to the closest spot of the grid instead
local function slideOntoPad(furnitureId: string, cframe: CFrame): Result<CFrame, string>
	local extentsRes = FurnitureDefinition.getExtents(furnitureId)
	if extentsRes.IsErr then
		return extentsRes
	end
	local extents = extentsRes.Value
	local right, look = cframe.RightVector, cframe.LookVector
	-- how far the footprint reaches from the piece along each side of the pad, turned the way the piece is
	local reach = Vector2.new(
		math.abs(right.X) * extents.X + math.abs(look.X) * extents.Z,
		math.abs(right.Z) * extents.X + math.abs(look.Z) * extents.Z
	) / 2
	local room = PLACEMENT.PAD_SIZE / 2 + Vector2.new(PLACEMENT.PAD_MARGIN, PLACEMENT.PAD_MARGIN) - reach
	local maxX = math.floor(room.X / PLACEMENT.GRID_SIZE) * PLACEMENT.GRID_SIZE
	local maxZ = math.floor(room.Y / PLACEMENT.GRID_SIZE) * PLACEMENT.GRID_SIZE
	local slid = cframe.Rotation
		+ Vector3.new(math.max(-maxX, math.min(maxX, cframe.X)), cframe.Y, math.max(-maxZ, math.min(maxZ, cframe.Z)))
	-- a piece that's bigger than its pad has no spot on it
	local inBoundsRes = FurnitureDefinition.getIfInBounds(furnitureId, slid)
	if inBoundsRes.IsErr then
		return inBoundsRes
	end
	if not inBoundsRes.Value then
		return Result.err(`it doesn't fit on its pad`)
	end
	return Result.ok(slid)
end

-- a line is added to changes for whatever of the piece didn't make it over the way it was
local function convertPiece(
	raw: unknown,
	inventory: BaseInventory,
	artifactIds: { string },
	id: string,
	changes: { string }
): Result<PlacedFurniture, string>
	local success, message = isPiece(raw)
	if not success then
		return Result.err(`{message}`)
	end
	local values = raw :: { any }
	local zoneId = tonumber(values[1])
	if not BaseType.ZoneId(zoneId) then
		return Result.err(`it stands on no pad`)
	end
	local name = values[2] :: string
	local furnitureId = FurnitureIds[name]
	if not furnitureId then
		return Result.err(`{describe(name)} isn't a piece of furniture`)
	end
	-- the old game placed whatever a client asked for, here a piece takes owning it
	if not table.find(inventory.FurnitureIds, furnitureId) then
		return Result.err(`"{name}" isn't owned`)
	end
	local saved: CFrame = (CFrame.new :: any)(table.unpack(values[3]))
	-- a piece stands upright on its pad + is turned in steps. where on the pad it stood is kept to the number: the
	-- old game put a piece on a grid of the world, rounding it onto the one of its pad could pull apart what was
	-- lined up
	local cframe = CFrame.new(saved.X, PLACEMENT.PAD_HEIGHT_OFFSET, saved.Z)
		* CFrame.Angles(0, math.rad(BaseUtil.getRotationDeg(saved)), 0)
	local inBoundsRes = FurnitureDefinition.getIfInBounds(furnitureId, cframe)
	if inBoundsRes.IsErr then
		return inBoundsRes
	end
	if not inBoundsRes.Value then
		local slidRes = slideOntoPad(furnitureId, cframe)
		if slidRes.IsErr then
			return Result.err(`"{name}": {slidRes.Value}`)
		end
		cframe = slidRes.Value
		table.insert(changes, `the spot of "{name}", it hung over its pad + was moved back onto it`)
	end
	local piece: PlacedFurniture = {
		Id = id,
		FurnitureId = furnitureId,
		ZoneId = zoneId :: number,
		CFrame = cframe,
	}
	local shown: unknown = values[4]
	if type(shown) ~= "string" or shown == "" or utf8.len(shown) == nil then
		return Result.ok(piece)
	end
	if name == SUIT_DISPLAY_NAME then
		-- kept even when its hero didn't make it over, a base knows what to show on a display that outlived its hero
		piece.CharacterId = shown
	elseif table.find(PEDESTAL_NAMES, name) then
		local artifactId: string? = ArtifactIds[shown]
		-- on a pedestal an artifact takes owning it as much as on a hero
		if artifactId and table.find(artifactIds, artifactId) then
			piece.ArtifactId = artifactId
		else
			table.insert(changes, `the {describe(shown)} it showed isn't owned`)
		end
	end
	return Result.ok(piece)
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
	return convertCharacter(raw :: { unknown }, "starter-suit", 1)
end

-- everything below takes what a store of the old game held + answers with what made it over, next to a line for
-- each thing that didn't. a save is never turned down as a whole over a part of it

Module.toCharacters = function(slots: { [number]: unknown }): ({ Character }, { string })
	local characters: { Character } = {}
	local problems: { string } = {}
	local length = getLength(slots)
	if length > MAX_SLOT_COUNT then
		table.insert(problems, `slots {MAX_SLOT_COUNT + 1} to {length}: a save holds up to {MAX_SLOT_COUNT}`)
	end
	for index = 1, math.min(length, MAX_SLOT_COUNT) do
		local characterRes = convertSlot(slots[index])
		if characterRes.IsErr then
			table.insert(problems, `slot {index}: {characterRes.Value}`)
			continue
		end
		local isIdTaken = false
		for _, other in characters do
			isIdTaken = isIdTaken or other.Id == characterRes.Value.Id
		end
		if isIdTaken then
			table.insert(problems, `slot {index}: an earlier slot has its id`)
			continue
		end
		table.insert(characters, characterRes.Value)
	end
	return characters, problems
end

Module.toArtifactIds = function(names: { [number]: unknown }): ({ string }, { string })
	local artifactIds: { string } = {}
	local problems: { string } = {}
	for index = 1, getLength(names) do
		local name = names[index]
		local artifactId: string? = if type(name) == "string" then ArtifactIds[name] else nil
		if not artifactId then
			table.insert(problems, `artifact {index}: {describe(name)} isn't an artifact`)
		-- the old game could grant an artifact twice
		elseif not table.find(artifactIds, artifactId) then
			table.insert(artifactIds, artifactId)
		end
	end
	return artifactIds, problems
end

-- the old game kept one worn artifact per player + put it on whichever hero they played. here an artifact is an item
-- of a hero, so it's handed the one that should wear it
Module.wearArtifact = function(
	character: Character,
	wornArtifact: WornArtifact,
	artifactIds: { string }
): Result<Character, string>
	local name = wornArtifact[1] :: string
	if name == NOTHING then
		return Result.ok(character)
	end
	local artifactId: string? = ArtifactIds[name]
	if not artifactId then
		return Result.err(`{describe(name)} isn't an artifact`)
	end
	-- the old game let anybody wear any artifact, here it takes owning it
	if not table.find(artifactIds, artifactId) then
		return Result.err(`"{name}" isn't owned`)
	end
	return Result.ok(FreezeUtil.delta(character, function(t: Character): Character
		local appearance = t.Identities.Main.Appearance
		table.insert(appearance.Items, {
			DefinitionId = artifactId,
			TextureGroups = {},
		})
		for index, tag in HIDDEN_TAGS do
			if wornArtifact[index + 1] == false then
				table.insert(appearance.HiddenTags, tag)
			end
		end
		return t
	end))
end

-- the old game kept the furniture + the themes a player bought in one list
Module.toInventory = function(names: { string }): (BaseInventory, { string })
	local problems: { string } = {}
	local inventory = FreezeUtil.delta(BaseConstructor.newInventory(), function(t: BaseInventory): BaseInventory
		for index, name in names do
			local furnitureId: string?, themeId: string? = FurnitureIds[name], ThemeIds[name]
			if furnitureId then
				if not table.find(t.FurnitureIds, furnitureId) then
					table.insert(t.FurnitureIds, furnitureId)
				end
			elseif themeId then
				if not table.find(t.ThemeIds, themeId) then
					table.insert(t.ThemeIds, themeId)
				end
			else
				table.insert(problems, `purchase {index}: {describe(name)} is neither furniture nor a theme`)
			end
		end
		return t
	end)
	return inventory, problems
end

-- entries holds the name of the theme, a title that was never used + every piece that was placed. the inventory + the
-- artifacts are what the player owns here, the old game didn't ask if a theme, a piece or what it showed was owned
Module.toBaseLayout = function(
	entries: { [number]: unknown },
	inventory: BaseInventory,
	artifactIds: { string }
): (BaseLayout, { string })
	local problems: { string } = {}
	local layout = FreezeUtil.delta(BaseConstructor.new(), function(t: BaseLayout): BaseLayout
		local themeName = entries[1]
		local themeId: string? = if type(themeName) == "string" then ThemeIds[themeName] else nil
		if themeId and table.find(inventory.ThemeIds, themeId) then
			t.ThemeId = themeId
		else
			table.insert(problems, `theme: {describe(themeName)} isn't owned`)
		end
		for index = 3, getLength(entries) do
			local changes: { string } = {}
			local pieceRes =
				convertPiece(entries[index], inventory, artifactIds, `imported-{#t.Furniture + 1}`, changes)
			if pieceRes.IsErr then
				table.insert(problems, `piece {index - 2}: {pieceRes.Value}`)
			elseif #t.Furniture >= PLACEMENT.MAX_PLACED then
				table.insert(problems, `piece {index - 2}: a base holds up to {PLACEMENT.MAX_PLACED} pieces`)
			else
				table.insert(t.Furniture, pieceRes.Value)
				for _, change in changes do
					table.insert(problems, `piece {index - 2}: {change}`)
				end
			end
		end
		return t
	end)
	return layout, problems
end

return Module
