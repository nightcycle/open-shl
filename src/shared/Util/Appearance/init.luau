--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Future = TypeUnionLib.Future
-- Modules
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemUtil = require("@self/Item")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type ItemDefinitionIndex = ItemAppearanceDefinition.ItemDefinitionIndex
-- Constants
local ITEM_TAG = "AppearanceItem"
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.clear(rig: Model): TypeUnionLib.ToDo<true>
	return Future.toDo(function(getIfCanceled): true?
		local desc = HumanoidDescriptionBuilder.new():build()
		local f = Future.awaitUntil(RigUtil.applyDescription(rig, desc), getIfCanceled)
		desc:Destroy()
		for i, v in rig:QueryDescendants(`.{ITEM_TAG}`) do
			v:Destroy()
		end
		if f.IsDone then
			return true
		end
		return
	end)
end

function Util.apply(rig: Model, appearance: Appearance): TypeUnionLib.ToDo<Result<true, { string }>>
	return Future.toDo(function(getIfCanceled): Result<true, { string }>?
		do
			local f = Future.awaitUntil(Util.clear(rig), getIfCanceled)
			if f.IsCanceled then
				return
			end
		end
		local errs = {}
		for i, item in appearance.Items do
			if getIfCanceled() then
				return
			end
			local res = ItemUtil.apply(rig, appearance, item)
			if res.IsErr then
				table.insert(errs, `item "{item.DefinitionId}" failed to apply: {res.Value}`)
			end
		end
		if #errs > 0 then
			return Result.err(errs)
		end
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end)
end

return Util
