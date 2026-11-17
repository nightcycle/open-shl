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
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local ItemDefSelection =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Selection/AppearanceItemDefinition")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
local SessionArtifactIdsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ArtifactIds")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type ItemGroup = AppearanceType.ItemGroup
type HiddenTag = AppearanceType.HiddenTag
-- Constants
-- the hero wears one item out of each, so every toggle has something to hide + a back artifact has a cape to cover
local WORN_CATEGORIES: { { GROUP: ItemGroup, CATEGORY: string } } = table.freeze({
	{ GROUP = "costume" :: ItemGroup, CATEGORY = "suit" },
	{ GROUP = "costume" :: ItemGroup, CATEGORY = "masks" },
	{ GROUP = "costume" :: ItemGroup, CATEGORY = "hoods" },
	{ GROUP = "costume" :: ItemGroup, CATEGORY = "mouth-covers" },
	{ GROUP = "costume" :: ItemGroup, CATEGORY = "capes" },
	{ GROUP = "cosmetics" :: ItemGroup, CATEGORY = "hair" },
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		OwnsEverything = UILabs.Boolean(false),
	},
}, function(props)
	local appliedArtifact: Item?, setAppliedArtifact: (Item?) -> () = React.useState(nil :: Item?)
	local hiddenTags: { HiddenTag }, setHiddenTags: ({ HiddenTag }) -> () = React.useState({} :: { HiddenTag })
	local selectedItemDef: ItemDefinition?, setSelectedItemDef: (ItemDefinition?) -> () =
		React.useState(nil :: ItemDefinition?)
	local baseCharacter = React.useMemo(function(): CharacterType.Character
		local out = TableUtil.deepCopy(CharacterConstructor.new())
		for i, CONFIG in WORN_CATEGORIES do
			local itemDef = ItemAppearanceDefinition.list(CONFIG.GROUP, CONFIG.CATEGORY)[1]
			if itemDef then
				table.insert(out.Identities.Main.Appearance.Items, ItemConstructor.new(itemDef.Id))
			end
		end
		return out
	end, {})
	local character = React.useMemo(function(): CharacterType.Character
		local out = TableUtil.deepCopy(baseCharacter)
		if appliedArtifact then
			table.insert(out.Identities.Main.Appearance.Items, appliedArtifact)
		end
		out.Identities.Main.Appearance.HiddenTags = table.clone(hiddenTags)
		return out
	end, { baseCharacter :: any, appliedArtifact, hiddenTags })
	local previewCharacter = React.useMemo(function(): CharacterType.Character?
		if not selectedItemDef then
			return nil
		end
		local out = TableUtil.deepCopy(baseCharacter)
		table.insert(out.Identities.Main.Appearance.Items, ItemConstructor.new(selectedItemDef.Id))
		out.Identities.Main.Appearance.HiddenTags = table.clone(hiddenTags)
		return out
	end, { baseCharacter :: any, selectedItemDef, hiddenTags })
	-- every other artifact stays locked, unless the control hands them all out
	local artifactIds = React.useMemo(function(): { string }
		local out: { string } = {}
		for i, itemDef in ItemAppearanceDefinition.list("costume", "artifacts") do
			if props.controls.OwnsEverything or i % 2 == 1 then
				table.insert(out, itemDef.Id)
			end
		end
		table.freeze(out)
		return out
	end, { props.controls.OwnsEverything })

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		PreviewCharacter = e(PreviewCharacterContext.Provider, {
			value = previewCharacter,
		}, {
			ItemDefSelection = e(ItemDefSelection.Provider, {
				value = selectedItemDef,
			}, {
				ArtifactIds = e(SessionArtifactIdsContext.Provider, {
					value = artifactIds,
				}, {
					Menu = e(ParentComponent, {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						OnAction = function(action: ParentComponent.ActionInfo)
							if action.Type == "AddItem" then
								setAppliedArtifact(ItemConstructor.new(action.ItemDefinition.Id))
							elseif action.Type == "RemoveItem" then
								setAppliedArtifact(nil)
								setHiddenTags({})
							elseif action.Type == "SetTagVisibility" then
								local newHiddenTags = table.clone(hiddenTags)
								local index = table.find(newHiddenTags, action.Tag)
								if action.IsVisible and index then
									table.remove(newHiddenTags, index)
								elseif not action.IsVisible and not index then
									table.insert(newHiddenTags, action.Tag)
								end
								setHiddenTags(newHiddenTags)
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
		}),
	})
end)
