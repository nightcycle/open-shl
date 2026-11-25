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
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
local RollUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Roll")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
type Item = AppearanceType.Item
type ItemGroup = AppearanceType.ItemGroup
type Owned = SessionOwnedContext.Owned
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
-- the word the filter of the story takes offense at
local CENSORED_PATTERN = "[Dd]arn"
local SCALE = CharacterEditorDefinition.SCALE
-- a game without body sizes has the one
local DEFAULT_HEIGHT = if SCALE then SCALE.Default.Height else 1
local HEIGHTS: { number } = if SCALE then SCALE.Heights else table.freeze({ DEFAULT_HEIGHT })
local HAIR_GROUP: ItemGroup = "cosmetics"
local HAIR_CATEGORY = "hair"
local HAIR_TEXTURE_GROUP_KEY: TextureGroupKey = "Hair"
-- no head of hair is made in it, so another one that's picked shows whether it came in the color of the last
local HAIR_COLOR = Color3.fromRGB(190, 40, 160)
-- what the everyday identity is in while the story has the colors of the two apart
local APART_HAIR_COLOR = Color3.fromRGB(30, 120, 60)
local APART_SKIN_COLOR = Color3.fromRGB(90, 60, 40)
-- what the player of the story has to spend: whatever costs more is turned down the way the server would
local CREDITS = 10_000
local NOTHING_OWNED: Owned = table.freeze({ ItemIds = table.freeze({}), PowerIds = table.freeze({}) })
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getIfHair(item: Item): boolean
	local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	return indexRes.IsOk and indexRes.Value.Group == HAIR_GROUP and indexRes.Value.Category == HAIR_CATEGORY
end

-- a character the way the controls have it: a body of that height, one head of hair in that color on both identities
-- + the same skin under it, unless the everyday one is to have a skin + a hair color of its own
local function dress(character: Character, height: number, hairColor: Color3, isColorApart: boolean): Character
	return FreezeUtil.delta(character, function(t: Character): Character
		local main = t.Identities.Main
		-- the head of hair the hero was rolled, the first one of the game for one that was rolled bald
		local hairId: string? = nil
		for _, item in main.Appearance.Items do
			hairId = hairId or (if getIfHair(item) then item.DefinitionId else nil)
		end
		local hairDef = ItemAppearanceDefinition.list(HAIR_GROUP, HAIR_CATEGORY)[1]
		hairId = hairId or (if hairDef then hairDef.Id else nil)
		for identityKey, identity in t.Identities do
			if not identity then
				continue
			end
			local isOwn = isColorApart and identityKey ~= "Main"
			local appearance = identity.Appearance
			if SCALE then
				appearance.Scale = {
					Height = height,
					Width = height * SCALE.Default.Width / SCALE.Default.Height,
				}
			end
			appearance.SkinColor = if isOwn then APART_SKIN_COLOR else main.Appearance.SkinColor
			for index = #appearance.Items, 1, -1 do
				if getIfHair(appearance.Items[index]) then
					table.remove(appearance.Items, index)
				end
			end
			local defaultRes = if hairId
				then ItemAppearanceDefinition.getDefaultTextureGroup(hairId, HAIR_TEXTURE_GROUP_KEY)
				else nil
			if hairId and defaultRes and defaultRes.IsOk then
				table.insert(appearance.Items, {
					DefinitionId = hairId,
					TextureGroups = {
						[HAIR_TEXTURE_GROUP_KEY] = {
							Color = if isOwn then APART_HAIR_COLOR else hairColor,
							Material = defaultRes.Value.Material,
							Transparency = defaultRes.Value.Transparency,
						},
					},
				})
			end
		end
		return t
	end)
end

-- what's owned with everything a listing hands over on top
local function buy(owned: Owned, listing: AccessDefinition.Listing): Owned
	local out: Owned = { ItemIds = table.clone(owned.ItemIds), PowerIds = table.clone(owned.PowerIds) }
	local itemIds: { string } = listing.ItemIds or {}
	table.move(itemIds, 1, #itemIds, #out.ItemIds + 1, out.ItemIds)
	if listing.PowerId then
		table.insert(out.PowerIds, listing.PowerId)
	end
	return out
end

-- everything the game holds back, bought: no row has a price
local function newAllOwned(): Owned
	local out = NOTHING_OWNED
	for _, listing in AccessDefinition.list() do
		out = buy(out, listing)
	end
	return out
end
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
		-- what the game holds back is still to be bought: its rows are green + priced, a press tries one on + brings up
		-- the button that buys it. whatever costs more than 10,000 is turned down. off, everything is owned
		HasPrices = UILabs.Boolean(true),
		IsSaveFailing = UILabs.Boolean(false),
		-- how tall the body under the camera is, the smallest + the tallest are the ones to look at
		Height = UILabs.Choose(HEIGHTS, table.find(HEIGHTS, DEFAULT_HEIGHT)),
		-- what the head of hair of the character is colored, another one out of the list is to come in it
		HairColor = UILabs.Datatype.Color3(HAIR_COLOR),
		-- the everyday identity in a skin + a hair color of its own: the switch of the hair page is found apart
		IsColorApart = UILabs.Boolean(false),
	},
}, function(props)
	local height: number = props.controls.Height :: number
	local hairColor: Color3 = props.controls.HairColor
	local isColorApart: boolean = props.controls.IsColorApart
	local character: Character, setCharacter: (Character) -> () = React.useState(function(): Character
		return dress(RandomCharacter.Character(), height, hairColor, isColorApart)
	end)
	-- how often the draft was replaced, every time the editor starts over from what's stored
	local openCount, setOpenCount = React.useState(0)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)
	-- what the last press of randomize left of the draft
	local draft: Character?, setDraft: (Character?) -> () = React.useState(nil :: Character?)
	local owned: Owned, setOwned: (Owned) -> () = React.useState(NOTHING_OWNED)
	local allOwned = React.useMemo(newAllOwned, {})
	local filteredText: ParentComponent.FilteredText?, setFilteredText: (ParentComponent.FilteredText?) -> () =
		React.useState(nil :: ParentComponent.FilteredText?)

	-- a control that's moved is put on the character that's stored + the editor starts over from it, what's saved
	-- out of the editor after that stays the way it was saved. the first run is the mount: the roll came dressed
	local isMountedRef = React.useRef(false)
	React.useEffect(function()
		if not isMountedRef.current then
			isMountedRef.current = true
			return function() end
		end
		setCharacter(dress(character, height, hairColor, isColorApart))
		setOpenCount(openCount + 1)
		return function() end
	end, { height :: any, hairColor, isColorApart })

	local menus: { [string]: React.ReactNode } = {}
	menus[`Menu-{openCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			IsRandomizable = props.controls.IsRandomizable,
			Draft = draft,
			FilteredText = filteredText,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "Save" then
					if props.controls.IsSaveFailing then
						setErrorMessage(`the story was told to turn the save down`)
						return
					end
					setErrorMessage(nil)
					setDraft(nil)
					setCharacter(action.Character)
					setOpenCount(openCount + 1)
				elseif action.Type == "FilterText" then
					setFilteredText({
						Filter = action.Filter,
						Text = (string.gsub(action.Filter.Text, CENSORED_PATTERN, "####")),
					})
				elseif action.Type == "Randomize" then
					-- stands in for the server, which is who rolls a character in the game. the draft takes the roll
					-- the way the game's does: its size, its patterns + its accessories stay
					setErrorMessage(nil)
					setDraft(RollUtil.merge(action.Character, RandomCharacter.Character()))
				elseif action.Type == "Purchase" then
					local listing = AccessDefinition.getOf(action.Id)
					local access = AccessDefinition.getAccess(action.Id)
					if not listing or access.Type ~= "Price" then
						return
					end
					if access.Amount > CREDITS then
						setErrorMessage(`not enough Credits`)
						return
					end
					setErrorMessage(nil)
					setOwned(buy(owned, listing))
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
				Owned = e(SessionOwnedContext.Provider, {
					value = if props.controls.HasPrices then owned else allOwned,
				}, {
					Menus = e(React.Fragment, {}, menus),
				}),
			}),
		}),
	})
end)
