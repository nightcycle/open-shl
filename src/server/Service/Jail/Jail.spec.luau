--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local CustodyUtil = require("@game/ServerScriptService/Server/Service/Jail/Custody")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type TestMap = SimpleTest.TestMap
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
local COLOR = Color3.fromRGB(218, 133, 65)
-- Variables
-- References
-- Private Functions
local function newSpot(position: Vector3): BasePart
	local spot = Instance.new("Part")
	spot.Position = position
	return spot
end
-- Class
local Tests: TestMap = {
	-- whoever comes in is put where the fewest are, the first of them
	Cell = SpecUtil.newScenario(function()
		assert(CustodyUtil.getCellIndex({ 0, 0, 0 }) == 1, `the first in isn't in the first cell`)
		assert(CustodyUtil.getCellIndex({ 1, 0, 0 }) == 2, `the second is with the first`)
		assert(CustodyUtil.getCellIndex({ 1, 1, 1 }) == 1, `full all round doesn't start over`)
		assert(CustodyUtil.getCellIndex({ 2, 1, 1 }) == 2, `it isn't the first of the emptiest`)
		assert(CustodyUtil.getCellIndex({ 1, 1, 0 }) == 3, `the one that's free is passed over`)
		assert(CustodyUtil.getCellIndex({ 4 }) == 1, `a jail of one cell`)
	end),

	-- the cells are counted off the same way every time, whichever way the engine lists them
	Order = SpecUtil.newScenario(function()
		local positions = {
			Vector3.new(-5, 10, 3),
			Vector3.new(-9, 10, 7),
			Vector3.new(-9, 10, 3),
			Vector3.new(-9, 20, 3),
			Vector3.new(0, 0, 0),
		}
		local expected = { positions[3], positions[4], positions[2], positions[1], positions[5] }
		local spots: { BasePart } = {}
		local reversed: { BasePart } = {}
		for index, position in positions do
			table.insert(spots, newSpot(position))
			table.insert(reversed, newSpot(positions[#positions + 1 - index]))
		end
		CustodyUtil.sort(spots)
		CustodyUtil.sort(reversed)
		for index, position in expected do
			assert(spots[index].Position == position, `spot {index} is at {spots[index].Position}`)
			assert(reversed[index].Position == position, `listed the other way, spot {index} is somewhere else`)
		end
	end),

	-- only further than the radius is out
	Out = SpecUtil.newScenario(function()
		local center = Vector3.new(-385, 231, 1091)
		assert(not CustodyUtil.getIfOut(center, center, 608), `the middle is out`)
		assert(not CustodyUtil.getIfOut(center + Vector3.new(608, 0, 0), center, 608), `on the line is out`)
		assert(CustodyUtil.getIfOut(center + Vector3.new(608.1, 0, 0), center, 608), `past the line isn't`)
		assert(CustodyUtil.getIfOut(center + Vector3.new(0, 609, 0), center, 608), `straight up doesn't count`)
		assert(not CustodyUtil.getIfOut(center + Vector3.new(400, 400, 0), center, 608), `566 studs off is out`)
	end),

	-- what the held are put in: each piece in the one color wherever it takes one, nothing of it to write to
	Costume = SpecUtil.newScenario(function()
		local ids: { string } = {}
		for _, definition in ItemAppearanceDefinition.list("clothing") do
			if definition.Type == "Model" and #definition.TextureGroups > 0 and #ids < 2 then
				table.insert(ids, definition.Id)
			end
		end
		assert(#ids > 0, `the game has no clothing that takes a color`)
		local costume = CustodyUtil.newCostume("Secret", ids, COLOR)
		assert(costume.IdentityKey == "Secret" and costume.IsPowerless, `it isn't the powerless civilian`)
		assert(#costume.Items == #ids, `a piece is missing`)
		assert(table.isfrozen(costume) and table.isfrozen(costume.Items), `it can be written to`)
		for index, item in costume.Items do
			assert(item.DefinitionId == ids[index], `piece {index} is {item.DefinitionId}`)
			local definitionRes = ItemAppearanceDefinition.get(item.DefinitionId)
			assert(definitionRes.IsOk, definitionRes.Value)
			for _, key: TextureGroupKey in definitionRes.Value.TextureGroups do
				local group = item.TextureGroups[key]
				assert(group and group.Color == COLOR, `the {key} of {item.DefinitionId} isn't in the color`)
			end
			assert(table.isfrozen(item) and table.isfrozen(item.TextureGroups), `a piece can be written to`)
		end
	end),
}

-- only a game that holds somebody has anything to hold this to
return if GameDefinition.FEATURES.Teams then Tests else {} :: TestMap
