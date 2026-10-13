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
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local ItemDefSelection =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Selection/AppearanceItemDefinition")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
-- Constants
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
	local baseCharacter = React.useMemo(function(): CharacterType.Character
		return CharacterConstructor.new()
	end, {})
	local character = React.useMemo(function(): CharacterType.Character
		local out = TableUtil.deepCopy(baseCharacter)
		if appliedArtifact then
			table.insert(out.Identities.Main.Appearance.Items, appliedArtifact)
		end
		return out
	end, { baseCharacter :: any, appliedArtifact })
	local previewCharacter = React.useMemo(function(): CharacterType.Character?
		if not selectedItemDef then
			return nil
		end
		local out = TableUtil.deepCopy(baseCharacter)
		table.insert(out.Identities.Main.Appearance.Items, {
			DefinitionId = selectedItemDef.Id,
		})
		return out
	end, { baseCharacter :: any, selectedItemDef })

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		PreviewCharacter = e(PreviewCharacterContext.Provider, {
			value = previewCharacter,
		}, {
			ItemDefSelection = e(ItemDefSelection.Provider, {
				value = selectedItemDef,
			}, {
				Menu = e(ParentComponent, {
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
