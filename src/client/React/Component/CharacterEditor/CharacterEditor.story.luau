--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
-- Constants
-- the word the filter of the story takes offense at
local CENSORED_PATTERN = "[Dd]arn"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		HasFifthPower = UILabs.Boolean(false),
		HasMultiHair = UILabs.Boolean(false),
		IsSaveFailing = UILabs.Boolean(false),
	},
}, function(props)
	local character: CharacterType.Character, setCharacter: (CharacterType.Character) -> () = React.useState(
		function(): CharacterType.Character
			return RandomCharacter.Character()
		end
	)
	-- how often the menu was left, every time it opens it starts over from what's stored
	local exitCount, setExitCount = React.useState(0)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)
	local filteredText: ParentComponent.FilteredText?, setFilteredText: (ParentComponent.FilteredText?) -> () =
		React.useState(nil :: ParentComponent.FilteredText?)
	local hasMultiHair: boolean = props.controls.HasMultiHair
	local entitlements = React.useMemo(function(): { EntitlementKey }
		local out: { EntitlementKey } = {}
		if hasMultiHair then
			table.insert(out, "MultiHair")
		end
		table.freeze(out)
		return out
	end, { hasMultiHair })

	local menus: { [string]: React.ReactNode } = {}
	menus[`Menu-{exitCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			FilteredText = filteredText,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "Save" then
					if props.controls.IsSaveFailing then
						setErrorMessage(`the story was told to turn the save down`)
						return
					end
					setErrorMessage(nil)
					setCharacter(action.Character)
					setExitCount(exitCount + 1)
				elseif action.Type == "FilterText" then
					setFilteredText({
						Filter = action.Filter,
						Text = (string.gsub(action.Filter.Text, CENSORED_PATTERN, "####")),
					})
				elseif action.Type == "Exit" then
					setErrorMessage(nil)
					setExitCount(exitCount + 1)
				end
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		PowerLimit = e(SessionPowerLimitContext.Provider, {
			value = if props.controls.HasFifthPower then PowerDefinition.PASS_LIMIT else PowerDefinition.DEFAULT_LIMIT,
		}, {
			Entitlements = e(SessionEntitlementsContext.Provider, {
				value = entitlements,
			}, {
				Menus = e(React.Fragment, {}, menus),
			}),
		}),
	})
end)
