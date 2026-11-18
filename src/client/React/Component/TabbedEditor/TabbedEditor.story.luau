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
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
-- Constants
-- the word the filter of the story takes offense at
local CENSORED_PATTERN = "[Dd]arn"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the pages are bound to the editor of the game the place is built for: in a place of another game the shell, the art
-- + the picker show, the lists stay empty
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		HasPowerPass = UILabs.Boolean(false),
		IsRandomizable = UILabs.Boolean(true),
		IsSaveFailing = UILabs.Boolean(false),
	},
}, function(props)
	local character: CharacterType.Character, setCharacter: (CharacterType.Character) -> () = React.useState(
		function(): CharacterType.Character
			return RandomCharacter.Character()
		end
	)
	-- how often the draft was replaced, every time the editor starts over from what's stored
	local openCount, setOpenCount = React.useState(0)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)
	local filteredText: ParentComponent.FilteredText?, setFilteredText: (ParentComponent.FilteredText?) -> () =
		React.useState(nil :: ParentComponent.FilteredText?)

	local menus: { [string]: React.ReactNode } = {}
	menus[`Menu-{openCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			IsRandomizable = props.controls.IsRandomizable,
			FilteredText = filteredText,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "Save" then
					if props.controls.IsSaveFailing then
						setErrorMessage(`the story was told to turn the save down`)
						return
					end
					setErrorMessage(nil)
					setCharacter(action.Character)
					setOpenCount(openCount + 1)
				elseif action.Type == "FilterText" then
					setFilteredText({
						Filter = action.Filter,
						Text = (string.gsub(action.Filter.Text, CENSORED_PATTERN, "####")),
					})
				elseif action.Type == "Randomize" then
					-- stands in for the server, which is who rolls a character in the game
					setErrorMessage(nil)
					setCharacter(RandomCharacter.Character())
					setOpenCount(openCount + 1)
				end
			end,
		} :: ParentComponent.Properties
	)

	return StyleStory.provide(props.controls.Style, {
		Character = e(CharacterContext.Provider, {
			value = character,
		}, {
			PowerLimit = e(SessionPowerLimitContext.Provider, {
				value = if props.controls.HasPowerPass
					then PowerDefinition.PASS_LIMIT
					else PowerDefinition.DEFAULT_LIMIT,
			}, {
				Menus = e(React.Fragment, {}, menus),
			}),
		}),
	})
end)
