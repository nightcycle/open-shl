--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type EntitlementKey = EconomyType.EntitlementKey
type Owned = SessionOwnedContext.Owned
-- Constants
-- the word the filter of the story takes offense at
local CENSORED_PATTERN = "[Dd]arn"
-- what every pass the game holds something back behind hands out. none in a place whose lists have no lock: there
-- no row is ever held, whatever the story is told the player has
local PASS_KEYS: { EntitlementKey } = {}
for _, listing in AccessDefinition.list() do
	local lock = listing.Lock
	if lock and lock.Type == "Entitlement" and not table.find(PASS_KEYS, lock.Key) then
		table.insert(PASS_KEYS, lock.Key)
	end
end
table.freeze(PASS_KEYS)
local NO_KEYS: { EntitlementKey } = table.freeze({})
local NO_IDS: { string } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the pages are bound to the editor of the game the place is built for: in a place of another game the walk, the
-- panels, the grid + the bar show, the rows have nothing to step through + a color paints nothing
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		IsSaving = UILabs.Boolean(false),
		IsSaveFailing = UILabs.Boolean(false),
		-- what opens the locks of the game: with neither, a row that steps onto something held back says so + the
		-- page isn't left ahead
		HasPasses = UILabs.Boolean(false),
		HasGroupPerk = UILabs.Boolean(false),
		-- what there is to rent with, in a place that rents: a page that's held is left for a fee while this covers it
		Credits = UILabs.Slider(50, 0, 200, 5),
	},
}, function(props)
	local character: CharacterType.Character, setCharacter: (CharacterType.Character) -> () = React.useState(
		function(): CharacterType.Character
			return RandomCharacter.Character()
		end
	)
	-- how often the walk was left, every time it starts over from what's stored
	local openCount, setOpenCount = React.useState(0)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)
	local filteredText: ParentComponent.FilteredText?, setFilteredText: (ParentComponent.FilteredText?) -> () =
		React.useState(nil :: ParentComponent.FilteredText?)
	-- a press on a row that's behind a pass stands in for the pass being bought: every one of them at once
	local isPassBought, setIsPassBought = React.useState(false)
	-- stands in for the shop over the walk: the button only says whether it's up
	local isShopOpen, setIsShopOpen = React.useState(false)
	local hasPasses: boolean = props.controls.HasPasses or isPassBought
	local hasGroupPerk: boolean = props.controls.HasGroupPerk
	local owned = React.useMemo(function(): Owned
		return table.freeze({
			ItemIds = NO_IDS,
			PowerIds = NO_IDS,
			Entitlements = if hasPasses then PASS_KEYS else NO_KEYS,
			HasGroupPerk = hasGroupPerk,
		})
	end, { hasPasses, hasGroupPerk })

	local menus: { [string]: React.ReactNode } = {}
	menus[`Menu-{openCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			IsSaving = props.controls.IsSaving,
			IsShopOpen = isShopOpen,
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
				elseif action.Type == "Purchase" then
					setIsPassBought(true)
				elseif action.Type == "ToggleShop" then
					setIsShopOpen(not isShopOpen)
				elseif action.Type == "Exit" then
					-- stands in for the screen the walk is given up to, the same character is walked again
					setErrorMessage(nil)
					setIsPassBought(false)
					setOpenCount(openCount + 1)
				end
			end,
		} :: ParentComponent.Properties
	)

	return StyleStory.provide(props.controls.Style, {
		Credits = e(SessionCreditsContext.Provider, {
			value = props.controls.Credits,
		}, {
			Character = e(CharacterContext.Provider, {
				value = character,
			}, {
				PowerLimit = e(SessionPowerLimitContext.Provider, {
					value = PowerDefinition.DEFAULT_LIMIT,
				}, {
					Owned = e(SessionOwnedContext.Provider, {
						value = owned,
					}, {
						Menus = e(React.Fragment, {}, menus),
					}),
				}),
			}),
		}),
	})
end)
