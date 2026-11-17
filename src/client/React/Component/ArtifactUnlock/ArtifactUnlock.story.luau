--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type ItemDefinition = ParentComponent.ItemDefinition
-- Constants
local RARITIES: { PseudoEnum.Rarity } = table.clone(PseudoEnum.getEnumItems("Rarity"))
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Rarity = UILabs.Choose(RARITIES),
	},
}, function(props)
	local rarity = props.controls.Rarity :: PseudoEnum.Rarity
	local itemDefinitions = React.useMemo(function(): { ItemDefinition }
		local out: { ItemDefinition } = {}
		for i, itemDef in ItemAppearanceDefinition.list("costume", "artifacts") do
			if itemDef.Rarity == rarity then
				table.insert(out, itemDef)
			end
		end
		table.freeze(out)
		return out
	end, { rarity })
	-- the story plays the shell: a cut-scene that is over makes way for the one of the next artifact
	local playCount, setPlayCount = React.useState(1)
	local itemDefinition: ItemDefinition? = itemDefinitions[(playCount - 1) % math.max(#itemDefinitions, 1) + 1]

	local cutScenes: { [string]: React.ReactNode } = {}
	if itemDefinition then
		cutScenes[`ArtifactUnlock-{itemDefinition.Id}-{playCount}`] = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				ItemDefinition = itemDefinition,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "Exit" then
						setPlayCount(playCount + 1)
					end
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			} :: ParentComponent.Properties
		)
	end
	return e(React.Fragment, {}, cutScenes)
end)
