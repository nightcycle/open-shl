--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Appearance = AppearanceType.Appearance
type TextureGroupKey = AppearanceType.TextureGroupKey
type HiddenTag = AppearanceType.HiddenTag
type FaceSlot = AppearanceType.FaceSlot
-- Constants
local DEFAULT_SKIN_COLOR = Color3.fromRGB(159, 161, 172) -- "Fossil"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.fix = function(appearance: Appearance): Appearance
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		local usedIds: { [string]: true? } = {}
		local usedSlots: { [FaceSlot]: true? } = {}
		-- walks backwards so the newest copy of an item / face slot is the one that stays
		for i = #t.Items, 1, -1 do
			local item = t.Items[i]
			local itemDefRes = ItemAppearanceDefinition.get(item.DefinitionId)
			if itemDefRes.IsErr or usedIds[item.DefinitionId] then
				table.remove(t.Items, i)
				continue
			end
			local itemDef = itemDefRes.Value
			if itemDef.Type == "Face" then
				if usedSlots[itemDef.Slot] then
					table.remove(t.Items, i)
					continue
				end
				usedSlots[itemDef.Slot] = true
			end
			usedIds[item.DefinitionId] = true
			-- only the groups the definition lists can be worn, a face item lists none
			for key: TextureGroupKey in item.TextureGroups do
				if table.find(itemDef.TextureGroups, key) == nil then
					item.TextureGroups[key] = nil
				end
			end
		end
		local hiddenTags: { HiddenTag } = {}
		for _, tag in t.HiddenTags do
			if table.find(hiddenTags, tag) == nil then
				table.insert(hiddenTags, tag)
			end
		end
		t.HiddenTags = hiddenTags
		return t
	end)
end

Module.new = function(): Appearance
	local out: Appearance = {
		Items = {},
		SkinColor = DEFAULT_SKIN_COLOR,
		Transitions = {},
		HiddenTags = {},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
