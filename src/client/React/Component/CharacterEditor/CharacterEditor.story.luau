--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Appearance")
local PreviewCharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/PreviewAppearance")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
-- Constants
local ITEM_DEFINITIONS = ItemAppearanceDefinition.list()
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {},
}, function(props)
	local baseAppearance = React.useMemo(function(): AppearanceType.Appearance
		return {
			Items = {},
			HiddenTags = {},
		}
	end, {})
	local appearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)

		return app
	end, { baseAppearance :: any })
	local previewAppearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)

		return app
	end, { baseAppearance :: any })
	local itemDefinitions = React.useMemo(function()
		local out = {}
		for i, v in ITEM_DEFINITIONS do
			local index = ItemAppearanceDefinition.getIndex(v.Id)
			if not index.IsOk then
				continue
			end
			if not v.Rarity or index.Value.Category ~= "artifacts" then
				continue
			end
			table.insert(out, v)
		end
		table.freeze(out)
		return out
	end, {})
	return e(CharacterAppearanceContext.Provider, {
		value = appearance,
	}, {
		PreviewAppearance = e(PreviewCharacterAppearanceContext.Provider, {
			value = previewAppearance,
		}, {
			Menu = e(ParentComponent, {
				ItemDefinitions = itemDefinitions,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				OnAction = function(action: ParentComponent.ActionInfo)
					print(`action`, action)
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			}),
		}),
	})
end)
