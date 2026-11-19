--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local AppHasHudShownContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/HasHudShown")
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
type Character = ParentComponent.Character
-- Constants
-- as many rows as the old place had
local SLOT_COUNT = 5
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a slot as the game starts it out, under the name of a hero where one was saved to it
local function newCharacter(slot: number, name: string): Character
	return FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		t.Id = `slot-{slot}`
		t.Identities.Main.Profile.Name = name
		return t
	end)
end

local function newCharacters(savedCount: number): { Character }
	local out: { Character } = {}
	for slot = 1, SLOT_COUNT do
		table.insert(out, newCharacter(slot, if slot <= savedCount then `Super Hero {slot}` else ""))
	end
	table.freeze(out)
	return out
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		-- before the player was in the game it's the page of the creator, afterwards the panel over the game
		HasHudShown = UILabs.Boolean(false),
		-- how many of the rows hold a hero when the story starts, the others are empty. with all of them taken a new
		-- suit asks which one it replaces
		SavedCount = UILabs.Slider(2, 0, SLOT_COUNT, 1),
		IsSelectFailing = UILabs.Boolean(false),
	},
}, function(props)
	local savedCount: number = props.controls.SavedCount
	local characters: { Character }, setCharacters: ({ Character }) -> () = React.useState(function(): { Character }
		return newCharacters(savedCount)
	end)
	React.useEffect(function()
		setCharacters(newCharacters(savedCount))
		return function() end
	end, { savedCount })
	local activeCharacterId, setActiveCharacterId = React.useState("slot-1")
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)

	return StyleStory.provide(props.controls.Style, {
		HasHudShown = e(AppHasHudShownContext.Provider, {
			value = props.controls.HasHudShown,
		}, {
			Characters = e(SessionCharactersContext.Provider, {
				value = characters,
			}, {
				ActiveCharacterId = e(SessionActiveCharacterIdContext.Provider, {
					value = activeCharacterId,
				}, {
					SaveSlots = e(
						ParentComponent,
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(1, 1),
							ErrorMessage = errorMessage,
							OnAction = function(action: ParentComponent.ActionInfo)
								print(`action`, action)
								if action.Type == "Select" then
									if props.controls.IsSelectFailing then
										setErrorMessage(`the story was told to turn the load down`)
										return
									end
									setErrorMessage(nil)
									setActiveCharacterId(action.CharacterId)
								elseif action.Type == "Copy" then
									-- stands in for the server: the row takes the name of whoever is played
									local name = ""
									for _, character in characters do
										if character.Id == activeCharacterId then
											name = character.Identities.Main.Profile.Name
										end
									end
									local out: { Character } = {}
									for slot, character in characters do
										table.insert(
											out,
											if character.Id == action.CharacterId
												then newCharacter(slot, name)
												else character
										)
									end
									table.freeze(out)
									setErrorMessage(nil)
									setCharacters(out)
								end
							end,
							SizeConstraint = Enum.SizeConstraint.RelativeXY,
						} :: ParentComponent.Properties
					),
				}),
			}),
		}),
	})
end)
