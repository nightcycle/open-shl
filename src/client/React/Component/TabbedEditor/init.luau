--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
-- Components
local EditableCharacterProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/EditableCharacterProvider")
local Page = require("@self/Page")
local Picker = require("@self/Picker")
local Stage = require("@self/Stage")
local Tabs = require("@self/Tabs")
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
local SetIsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetIsHeroFocus")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
local Types = require("@self/Types")
type Character = CharacterType.Character
type Focus = Types.Focus
type Preview = Types.Preview
type TabInfo = Types.TabInfo
type TextFilter = EditorTypes.TextFilter
export type FilteredText = EditorTypes.FilteredText
export type ActionInfo = EditorTypes.ActionInfo
export type Properties = EditorTypes.Properties
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local TABS: { TabInfo } = CONSTANTS.TABS
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- whatever takes the place of the page grows out of the middle of the canvas
local function opening(props: {
	children: { [string]: React.ReactNode }?,
})
	local style = React.useContext(StyleContext)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	useTween(frameRef, style.Motion.Open, {
		Size = UDim2.fromScale(1, 1),
	}, {})
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		ref = frameRef,
		Size = UDim2.new(),
	}, props.children)
end

local function editor(props: {
	ErrorMessage: string?,
	IsSaving: boolean?,
	IsRandomizable: boolean?,
	OnSave: (character: Character) -> (),
	OnRandomize: (character: Character) -> (),
	OnPurchase: (id: string) -> (),
})
	local style = React.useContext(StyleContext)
	local character = React.useContext(CharacterContext)
	local state = React.useContext(CharacterEditorStateContext)
	local owned = React.useContext(SessionOwnedContext)
	local setIsHeroFocus = React.useContext(SetIsHeroFocusContext)
	local setPath = React.useContext(SetPathContext)
	local tabKey, setTabKey = React.useState(TABS[1].Key)
	-- the color the picker is open for, it covers the page while it is
	local focus: Focus?, setFocus: (Focus?) -> () = React.useState(nil :: Focus?)
	local limbIndex, setLimbIndex = React.useState(1)
	local lockedUntilRef = React.useRef(0)
	-- what has to be bought + is looked at. an item is only looked at for as long as it's tried on: whatever takes
	-- it off the mannequin ends that
	local preview: Preview?, setPreview: (Preview?) -> () = React.useState(nil :: Preview?)
	local pendingItem = if state then state.PendingItem else nil
	local previewId: string? = if preview
			and (not preview.IsTriedOn or (pendingItem ~= nil and pendingItem.DefinitionId == preview.Id))
		then preview.Id
		else nil
	-- once it's theirs there's nothing left to buy: the button goes, + what was tried on comes off, it isn't worn
	-- for having been paid for
	local isBought = preview ~= nil and AccessDefinition.getIfOwned(owned, preview.Id)
	React.useEffect(function()
		if isBought then
			setPreview(nil)
			if setPath then
				setPath("")
			end
		end
		return function() end
	end, { isBought })

	-- the editor opens on the everyday identity
	React.useEffect(function()
		if setIsHeroFocus and character.Identities.Secret then
			setIsHeroFocus(false)
		end
		return function() end
	end, {})

	local tab: TabInfo = TABS[1]
	for _, tabInfo in TABS do
		if tabInfo.Key == tabKey then
			tab = tabInfo
		end
	end

	local screens: { [string]: React.ReactNode } = {}
	if focus then
		screens[`Picker-{focus.Path}-{focus.Group or ""}`] = e(opening, {}, {
			Picker = e(
				Picker,
				{
					Size = UDim2.fromScale(1, 1),
					Focus = focus,
					OnDone = function()
						setFocus(nil)
					end,
				} :: Picker.Properties
			),
		})
	else
		screens[`Page-{tab.Key}`] = e(opening, {}, {
			Page = e(
				Page,
				{
					Size = UDim2.fromScale(1, 1),
					Tab = tab,
					LimbIndex = limbIndex,
					OnFocus = function(pickedFocus: Focus)
						if setPath then
							setPath(pickedFocus.Path)
							setFocus(pickedFocus)
						end
					end,
					OnLimbStep = function()
						setLimbIndex(limbIndex + 1)
					end,
					OnPreview = setPreview,
				} :: Page.Properties
			),
		})
	end

	return e(React.Fragment, {}, {
		Tabs = e(
			Tabs,
			{
				AnchorPoint = CONSTANTS.TAB_PANEL_ANCHOR_POINT,
				Position = CONSTANTS.TAB_PANEL_POSITION,
				Size = CONSTANTS.TAB_PANEL_SIZE,
				Tabs = TABS,
				SelectedKey = tab.Key,
				OnSelect = function(pickedTab: TabInfo)
					if pickedTab.Key == tab.Key or os.clock() < lockedUntilRef.current then
						return
					end
					lockedUntilRef.current = os.clock() + CONSTANTS.TAB_LOCK_DURATION
					-- the identity a page is about steps forward for it, a page of another identity is closed to a path
					if pickedTab.IdentityKey and setIsHeroFocus then
						setIsHeroFocus(pickedTab.IdentityKey == "Main")
					end
					if setPath then
						setPath(pickedTab.Path or "")
					end
					setFocus(nil)
					setPreview(nil)
					setTabKey(pickedTab.Key)
				end,
				OnDone = function()
					if not props.IsSaving then
						props.OnSave(character)
					end
				end,
			} :: Tabs.Properties
		),
		Panel = e("Frame", {
			AnchorPoint = CONSTANTS.PANEL_ANCHOR_POINT,
			BackgroundTransparency = 1,
			Position = CONSTANTS.PANEL_POSITION,
			Size = CONSTANTS.PANEL_SIZE,
		}, {
			Canvas = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}, screens),
		}),
		Randomize = props.IsRandomizable and e("ImageButton", {
			AnchorPoint = CONSTANTS.RANDOMIZE_ANCHOR_POINT,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Position = CONSTANTS.RANDOMIZE_POSITION,
			Size = CONSTANTS.RANDOMIZE_SIZE,
			[React.Event.Activated] = function()
				-- what's being colored or looked at is somebody else's once the roll is in
				setFocus(nil)
				setPreview(nil)
				props.OnRandomize(character)
			end,
		}, {
			-- the pill is the middle band of a square as wide as the button
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = CONSTANTS.BUTTON_ART,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
			TextLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Size = UDim2.fromScale(1, 1),
				Text = "Randomize",
				TextColor3 = CONSTANTS.RANDOMIZE_TEXT_COLOR,
				TextSize = style.TextSizes.Button,
				TextWrapped = true,
				ZIndex = 2,
			}),
		}),
		Purchase = previewId and e("ImageButton", {
			AnchorPoint = CONSTANTS.PURCHASE_ANCHOR_POINT,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Position = CONSTANTS.PURCHASE_POSITION,
			Size = CONSTANTS.PURCHASE_SIZE,
			[React.Event.Activated] = function()
				props.OnPurchase(previewId)
			end,
		}, {
			-- the pill is the middle band of a square as wide as the button
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = CONSTANTS.BUTTON_ART,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
			TextLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Size = UDim2.fromScale(1, 1),
				Text = "Purchase",
				TextColor3 = CONSTANTS.PURCHASE_TEXT_COLOR,
				TextSize = CONSTANTS.PURCHASE_TEXT_SIZE,
				ZIndex = 2,
			}),
		}),
		-- the old editor had nowhere to say that a save was turned down
		Error = props.ErrorMessage and e("TextLabel", {
			AnchorPoint = CONSTANTS.ERROR_ANCHOR_POINT,
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = CONSTANTS.ERROR_POSITION,
			Size = CONSTANTS.ERROR_SIZE,
			Text = props.ErrorMessage,
			TextColor3 = style.Palette.Negative,
			TextSize = style.TextSizes.Button,
			TextWrapped = true,
		}),
	})
end
-- Class
-- the editor as a column of tabs: one page at a time at the left, both identities of the character in the middle.
-- there's no way out of it but its last tab, which saves
return function(props: Properties): React.ReactNode
	local character = React.useContext(CharacterContext)
	local editors: { [string]: React.ReactNode } = {}
	-- keyed by the character, so another one starts over with a draft of its own
	editors[`Editor-{character.Id}`] = e(EditableCharacterProvider, {
		Draft = props.Draft,
		FilteredText = props.FilteredText,
		OnFilterText = function(filter: TextFilter)
			props.OnAction({
				Type = "FilterText",
				Filter = filter,
			})
		end,
	}, {
		Stage = e(Stage, {}),
		Editor = e(editor, {
			ErrorMessage = props.ErrorMessage,
			IsSaving = props.IsSaving,
			IsRandomizable = props.IsRandomizable,
			OnSave = function(draft: Character)
				props.OnAction({
					Type = "Save",
					Character = draft,
				})
			end,
			OnRandomize = function(draft: Character)
				props.OnAction({
					Type = "Randomize",
					Character = draft,
				})
			end,
			OnPurchase = function(id: string)
				props.OnAction({
					Type = "Purchase",
					Id = id,
				})
			end,
		}),
	})
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Editors = e(React.Fragment, {}, editors),
			-- nothing is pressed while the draft is on its way, what changed in the meantime wouldn't be stored
			Blocker = props.IsSaving and e("Frame", {
				Active = true,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10,
			}),
		}
	))
end
