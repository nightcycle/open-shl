--!strict
-- Services
-- Packages
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local RandomMisc = require("@game/ReplicatedStorage/Shared/Random/Misc")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.HiddenTag = function(seed: number?): AppearanceType.HiddenTag
	return RandomMisc.literal(seed, { "Hood", "Mask", "MouthCover", "Hair" }) :: AppearanceType.HiddenTag
end

Module.TransitionType = function(seed: number?): AppearanceType.TransitionType
	return RandomMisc.literal(seed, { "Death", "Transformation" }) :: AppearanceType.TransitionType
end

Module.TransitionOfType = function(
	transitionType: AppearanceType.TransitionType,
	seed: number?
): AppearanceType.Transition
	return {}
end

Module.Transition = function(seed: number?): AppearanceType.Transition
	local rng = Random.new(seed)
	return Module.TransitionOfType(Module.TransitionType(RandomUtil.newSeed(rng)), RandomUtil.newSeed(rng))
end

Module.ItemGroup = function(group: AppearanceType.ItemGroup, category: string, seed: number?): AppearanceType.ItemGroup
	return RandomMisc.literal(seed, { "clothing", "costume", "cosmetics", "body" }) :: AppearanceType.ItemGroup
end

Module.ItemCategoryOfGroup = function(group: AppearanceType.ItemGroup, seed: number?): string
	return RandomMisc.literal(seed, ItemDefinition.listCategories(group)) :: AppearanceType.ItemGroup
end

Module.ItemDefinitionOfCategory = function(
	group: AppearanceType.ItemGroup,
	category: string,
	seed: number?
): AppearanceType.ItemDefinition
	return RandomMisc.literal(seed, ItemDefinition.list(group, category)) :: AppearanceType.ItemDefinition
end

Module.ItemDefinitionOfGroup = function(group: AppearanceType.ItemGroup, seed: number?): AppearanceType.ItemDefinition
	return RandomMisc.literal(seed, ItemDefinition.list(group)) :: AppearanceType.ItemDefinition
end

Module.ItemDefinition = function(seed: number?): AppearanceType.ItemDefinition
	return RandomMisc.literal(seed, ItemDefinition.list()) :: AppearanceType.ItemDefinition
end

Module.ItemOfCategory = function(group: AppearanceType.ItemGroup, category: string, seed: number?): AppearanceType.Item
	local itemDef = Module.ItemDefinitionOfCategory(group, category, seed)
	return {
		DefinitionId = itemDef.Id,
	}
end

Module.ItemOfGroup = function(group: AppearanceType.ItemGroup, seed: number?): AppearanceType.Item
	local itemDef = Module.ItemDefinitionOfGroup(group, seed)
	return {
		DefinitionId = itemDef.Id,
	}
end

Module.Item = function(seed: number?): AppearanceType.Item
	local itemDef = Module.ItemDefinition(seed)
	return {
		DefinitionId = itemDef.Id,
	}
end

Module.Appearance = function(seed: number?): AppearanceType.Appearance
	local rng = Random.new(seed)
	return FreezeUtil.delta(AppearanceConstructor.new(), function(t)
		t.HiddenTags =
			RandomMisc.set(RandomUtil.newSeed(rng), Module.HiddenTag, rng:NextInteger(0, 5)) :: { AppearanceType.HiddenTag }
		t.Transitions = {
			Death = Module.TransitionOfType("Death", RandomUtil.newSeed(rng)),
			Transformation = Module.TransitionOfType("Transformation", RandomUtil.newSeed(rng)),
		}
		local items = {}

		for i = 1, rng:NextInteger(0, 12) do
			table.insert(items, Module.ItemOfGroup("costume", RandomUtil.newSeed(rng)))
		end

		t.Items = items
		return t
	end)
end

return Module
