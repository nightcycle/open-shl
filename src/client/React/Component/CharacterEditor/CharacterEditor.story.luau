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
local ItemDefSelection =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Selection/AppearanceItemDefinition")
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
	local appliedArtifact: Item?, setAppliedArtifact: (Item?) -> () = React.useState(nil :: Item?)
	local selectedItemDef: ItemDefinition?, setSelectedItemDef: (ItemDefinition?) -> () =
		React.useState(nil :: ItemDefinition?)
	local baseAppearance = React.useMemo(function(): AppearanceType.Appearance
		return {
			Items = {},
			HiddenTags = {},
		}
	end, {})
	local appearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)
		if appliedArtifact then
			table.insert(app.Items, appliedArtifact)
		end
		return app
	end, { baseAppearance :: any, appliedArtifact })
	local previewAppearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)
		if selectedItemDef then
			table.insert(app.Items, {
				DefinitionId = selectedItemDef.Id,
			})
		end
		return app
	end, { baseAppearance :: any, selectedItemDef })
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
			ItemDefSelection = e(ItemDefSelection.Provider, {
				value = selectedItemDef,
			}, {
				Menu = e(ParentComponent, {
					ItemDefinitions = itemDefinitions,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "AddItem" then
							setAppliedArtifact({
								DefinitionId = action.ItemDefinition.Id,
							})
						elseif action.Type == "RemoveItem" then
							setAppliedArtifact(nil)
						elseif action.Type == "SelectItem" then
							setSelectedItemDef(action.ItemDefinition)
						elseif action.Type == "Exit" then
							setSelectedItemDef(nil)
						end
					end,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
				}),
			}),
		}),
	})
end)
