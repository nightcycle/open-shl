--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
type Item = AppearanceType.Item
type TextureGroupKey = AppearanceType.TextureGroupKey
type Costume = AvatarService.Costume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what being held comes to that's the same whoever it is: nothing in here knows a player or the jail of a game
local Util = {}

-- the cells in an order that's the same every time: the engine promises none for what wears a tag. west to east,
-- south to north, the lower floor first
function Util.sort(spots: { BasePart })
	table.sort(spots, function(a: BasePart, b: BasePart): boolean
		local positionA, positionB = a.Position, b.Position
		if positionA.X ~= positionB.X then
			return positionA.X < positionB.X
		elseif positionA.Z ~= positionB.Z then
			return positionA.Z < positionB.Z
		end
		return positionA.Y < positionB.Y
	end)
end

-- the cell somebody who comes in is put into: the one that holds the fewest, the first of them. the old place put
-- everybody into the same one
function Util.getCellIndex(occupancy: { number }): number
	local cellIndex = 1
	for index, count in occupancy do
		if count < occupancy[cellIndex] then
			cellIndex = index
		end
	end
	return cellIndex
end

-- if somebody got far enough from the middle of it to be let go
function Util.getIfOut(position: Vector3, centerPosition: Vector3, radius: number): boolean
	return (position - centerPosition).Magnitude > radius
end

-- what the held are put in: who they are in it, its pieces in the one color wherever a piece takes one, + no powers
function Util.newCostume(identityKey: IdentityKey, itemIds: { string }, color: Color3): Costume
	local items: { Item } = {}
	for _, id in itemIds do
		local definitionRes = ItemAppearanceDefinition.get(id)
		assert(definitionRes.IsOk, definitionRes.Value)
		local item: Item = {
			DefinitionId = id,
			TextureGroups = {},
		}
		for _, key: TextureGroupKey in definitionRes.Value.TextureGroups do
			item.TextureGroups[key] = TextureGroupConstructor.new(color)
		end
		table.insert(items, item)
	end
	local costume: Costume = {
		IdentityKey = identityKey,
		Items = items,
		IsPowerless = true,
	}
	TableUtil.deepFreeze(costume)
	return costume
end

return Util
