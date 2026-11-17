--!strict
-- Services
-- Packages
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local ItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RandomMisc = require("@game/ReplicatedStorage/Shared/Random/Misc")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
-- Constants
local ITEM_GROUPS: { AppearanceType.ItemGroup } = table.freeze({
	"clothing" :: AppearanceType.ItemGroup,
	"costume",
	"cosmetics",
	"body",
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.TextureGroupKey = function(seed: number?): AppearanceType.TextureGroupKey
	return RandomMisc.literal(seed, {
		"Primary",
		"Secondary",
		"Tertiary",
		"Hair",
		"Skin",
	}) :: AppearanceType.TextureGroupKey
end

Module.HiddenTag = function(seed: number?): AppearanceType.HiddenTag
	return RandomMisc.literal(seed, { "Hood", "Mask", "MouthCover", "Hair" }) :: AppearanceType.HiddenTag
end

Module.FaceSlot = function(seed: number?): AppearanceType.FaceSlot
	return RandomMisc.literal(seed, { "Eyebrows", "Eyes", "Mouth" }) :: AppearanceType.FaceSlot
end

Module.SkinColor = function(seed: number?): Color3
	local rng = Random.new(seed)
	-- kept within believable skin tones so a preview still reads as a person
	return Color3.fromHSV(rng:NextNumber(0.04, 0.1), rng:NextNumber(0.2, 0.6), rng:NextNumber(0.35, 1))
end

Module.TransitionType = function(seed: number?): AppearanceType.TransitionType
	return RandomMisc.literal(seed, PseudoEnum.getEnumItems("TransitionType")) :: AppearanceType.TransitionType
end

Module.DeathTransition = function(seed: number?): AppearanceType.DeathTransition
	return table.freeze({
		Style = RandomMisc.literal(seed, PseudoEnum.getEnumItems("DeathStyle")) :: PseudoEnum.DeathStyle,
	})
end

Module.TransformationTransition = function(seed: number?): AppearanceType.TransformationTransition
	return table.freeze({
		Style = RandomMisc.literal(seed, PseudoEnum.getEnumItems("TransformationStyle")) :: PseudoEnum.TransformationStyle,
	})
end

Module.TransitionOfType = function(
	transitionType: AppearanceType.TransitionType,
	seed: number?
): AppearanceType.Transition
	if transitionType == PseudoEnum.TransitionType.Death then
		return Module.DeathTransition(seed)
	else
		return Module.TransformationTransition(seed)
	end
end

Module.Transition = function(seed: number?): AppearanceType.Transition
	local rng = Random.new(seed)
	return Module.TransitionOfType(Module.TransitionType(RandomUtil.newSeed(rng)), RandomUtil.newSeed(rng))
end

Module.ItemGroup = function(seed: number?): AppearanceType.ItemGroup
	-- a group with nothing in the library (body) can't produce an item
	local groups: { AppearanceType.ItemGroup } = {}
	for _, group: AppearanceType.ItemGroup in ITEM_GROUPS do
		if #ItemDefinition.listCategories(group) > 0 then
			table.insert(groups, group)
		end
	end
	return RandomMisc.literal(seed, groups) :: AppearanceType.ItemGroup
end

Module.ItemCategoryOfGroup = function(group: AppearanceType.ItemGroup, seed: number?): string
	return RandomMisc.literal(seed, ItemDefinition.listCategories(group))
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

Module.TextureGroup = function(seed: number?): AppearanceType.TextureGroup
	local rng = Random.new(seed)
	return TextureGroupConstructor.new(
		Color3.fromRGB(rng:NextInteger(0, 255), rng:NextInteger(0, 255), rng:NextInteger(0, 255)),
		RandomMisc.literal(RandomUtil.newSeed(rng), Enum.Material:GetEnumItems()),
		rng:NextNumber() < 0.9 and 0 or rng:NextNumber() * 0.7
	)
end

Module.ItemOfCategory = function(group: AppearanceType.ItemGroup, category: string, seed: number?): AppearanceType.Item
	local rng = Random.new(seed)
	local itemDef = Module.ItemDefinitionOfCategory(group, category, RandomUtil.newSeed(rng))
	return FreezeUtil.delta(ItemConstructor.new(itemDef.Id), function(item)
		for _, k in itemDef.TextureGroups do
			item.TextureGroups[k :: AppearanceType.TextureGroupKey] = Module.TextureGroup(RandomUtil.newSeed(rng))
		end
		return item
	end)
end

Module.ItemOfGroup = function(group: AppearanceType.ItemGroup, seed: number?): AppearanceType.Item
	local rng = Random.new(seed)
	local category = Module.ItemCategoryOfGroup(group, RandomUtil.newSeed(rng))
	return Module.ItemOfCategory(group, category, RandomUtil.newSeed(rng))
end

Module.Item = function(seed: number?): AppearanceType.Item
	local rng = Random.new(seed)
	local group: AppearanceType.ItemGroup = Module.ItemGroup(RandomUtil.newSeed(rng))
	return Module.ItemOfGroup(group, RandomUtil.newSeed(rng))
end

Module.Appearance = function(isSuper: boolean, seed: number?): AppearanceType.Appearance
	local rng = Random.new(seed)
	return AppearanceConstructor.fix(FreezeUtil.delta(AppearanceConstructor.new(), function(t)
		t.HiddenTags =
			RandomMisc.set(RandomUtil.newSeed(rng), Module.HiddenTag, rng:NextInteger(0, 5)) :: { AppearanceType.HiddenTag }
		t.SkinColor = Module.SkinColor(RandomUtil.newSeed(rng))
		t.Transitions = {
			Death = Module.DeathTransition(RandomUtil.newSeed(rng)),
			Transformation = Module.TransformationTransition(RandomUtil.newSeed(rng)),
		}
		local items = {}

		-- for i = 1, rng:NextInteger(0, 12) do
		if isSuper then
			for _, cat in ItemDefinition.listCategories("costume") do
				if cat == "artifacts" then
					continue
				end
				if rng:NextNumber() < 0.2 then
					continue
				end
				table.insert(items, Module.ItemOfCategory("costume", cat, RandomUtil.newSeed(rng)))
			end
		else
			for _, cat in ItemDefinition.listCategories("clothing") do
				if rng:NextNumber() < 0.2 then
					continue
				end
				table.insert(items, Module.ItemOfCategory("clothing", cat, RandomUtil.newSeed(rng)))
			end
		end
		-- cosmetics include the face, one category per slot
		for _, cat in ItemDefinition.listCategories("cosmetics") do
			if rng:NextNumber() < 0.2 then
				continue
			end
			table.insert(items, Module.ItemOfCategory("cosmetics", cat, RandomUtil.newSeed(rng)))
		end
		-- end

		t.Items = items
		return t
	end))
end

return Module
