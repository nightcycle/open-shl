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
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
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
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionRentedIdsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/RentedIds")
-- Types
type Character = ParentComponent.Character
-- Constants
-- as many rows as the old place had
local SLOT_COUNT = 5
-- something the game holds back behind a lock, for whoever is played to have rented. none in a place whose lists
-- have no lock: there the line under the rows never has a fee to say
local LOCKED_ITEM = ItemAppearanceDefinition.listLocked()[1]
local RENTED_IDS: { string } = table.freeze(if LOCKED_ITEM then { LOCKED_ITEM.Id } else {})
local NO_IDS: { string } = table.freeze({})
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
		-- whoever is played has something on that was rented for them: keeping them costs + their own row takes them
		IsRenting = UILabs.Boolean(false),
		Credits = UILabs.Slider(100, 0, 300, 50),
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
	local isRenting: boolean = props.controls.IsRenting
	local shown = React.useMemo(function(): { Character }
		if not isRenting or not LOCKED_ITEM then
			return characters
		end
		local out: { Character } = {}
		for _, character in characters do
			table.insert(
				out,
				if character.Id == activeCharacterId
					then FreezeUtil.delta(character, function(t: Character): Character
						table.insert(t.Identities.Main.Appearance.Items, ItemConstructor.new(LOCKED_ITEM.Id))
						return t
					end)
					else character
			)
		end
		table.freeze(out)
		return out
	end, { characters :: any, activeCharacterId, isRenting })

	return StyleStory.provide(props.controls.Style, {
		Credits = e(SessionCreditsContext.Provider, {
			value = props.controls.Credits,
		}, {
			RentedIds = e(SessionRentedIdsContext.Provider, {
				value = if isRenting then RENTED_IDS else NO_IDS,
			}, {
				HasHudShown = e(AppHasHudShownContext.Provider, {
					value = props.controls.HasHudShown,
				}, {
					Characters = e(SessionCharactersContext.Provider, {
						value = shown,
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
			}),
		}),
	})
end)
