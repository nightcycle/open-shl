--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local EditableCharacterProvider = require("@self/EditableCharacterProvider")
local Explorer = require("@self/Explorer")
local Properties = require("@self/Properties")
local Scene = require("@self/Scene")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local SetIsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetIsHeroFocus")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EditorTypes = require("@self/Types")
export type Character = CharacterType.Character
type TextFilter = EditorTypes.TextFilter
export type FilteredText = EditorTypes.FilteredText
export type ActionInfo =
	{
		Type: "Save",
		Character: Character,
	}
	| {
		Type: "FilterText",
		Filter: TextFilter,
	}
	| {
		Type: "Back",
	}
	| {
		Type: "Exit",
	}
export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	IsSaving: boolean?,
	FilteredText: FilteredText?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local BUTTON_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function frameButton(props: RobloxComponents.FrameProperties & {
	Text: string,
	ButtonColor3: Color3,
	OnClick: (() -> ())?,
	children: { [string]: React.ReactNode }?,
})
	local isEnabled = props.OnClick ~= nil
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(0.25, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		},
		props,
		{
			Button = e(
				"TextButton",
				{
					Active = isEnabled,
					AutoButtonColor = isEnabled,
					BackgroundColor3 = props.ButtonColor3,
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Modal = true,
					Position = UDim2.fromOffset(5, 5),
					Selectable = isEnabled,
					Size = UDim2.new(1, -10, 1, -10),
					Text = props.Text,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeColor3 = Color3.new(1, 1, 1),
					[React.Event.Activated] = props.OnClick,
				} :: RobloxComponents.TextButtonProperties
			),
			Children = e(React.Fragment, {}, props.children),
		}
	))
end

local function swapButton(props: RobloxComponents.FrameProperties)
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local setIsHeroFocus = React.useContext(SetIsHeroFocusContext)
	return e(frameButton, {
		Position = props.Position,
		Text = "Swap Identities",
		ButtonColor3 = Color3.fromRGB(255, 201, 37),
		OnClick = if setIsHeroFocus
			then function()
				setIsHeroFocus(not isHeroFocus)
			end
			else nil,
	})
end

local function saveButton(props: RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	IsSaving: boolean?,
	OnSave: (character: Character) -> (),
})
	local character = React.useContext(CharacterContext)
	return e(frameButton, {
		Position = props.Position,
		Text = props.IsSaving and "Saving..." or "Save and Exit",
		ButtonColor3 = Color3.fromRGB(75, 115, 245),
		OnClick = if props.IsSaving
			then nil
			else function()
				props.OnSave(character)
			end,
	}, {
		Error = props.ErrorMessage and e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = BUTTON_FONT,
			Position = UDim2.fromScale(0, 1.1),
			Size = UDim2.fromScale(1, 0.6),
			Text = props.ErrorMessage,
			TextColor3 = Color3.fromRGB(255, 204, 0),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(255, 0, 0),
			TextStrokeTransparency = 0,
		}),
	})
end
-- Class
return function(props: Properties)
	local character = React.useContext(CharacterContext)
	local editors: { [string]: React.ReactNode } = {}
	-- keyed by the character, so another one starts over with a draft of its own
	editors[`Editor-{character.Id}`] = e(EditableCharacterProvider, {
		FilteredText = props.FilteredText,
		OnFilterText = function(filter: TextFilter)
			props.OnAction({
				Type = "FilterText",
				Filter = filter,
			})
		end,
	}, {
		Scene = e(Scene, {}),
		Explorer = e(Explorer, {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0, 0.025),
			Size = UDim2.fromScale(0.3, 0.54),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			OnBack = function()
				props.OnAction({
					Type = "Back",
				})
			end,
			OnExit = function()
				props.OnAction({
					Type = "Exit",
				})
			end,
		}),
		Properties = e(Properties, {
			Position = UDim2.fromScale(0.7, 0.025),
			Size = UDim2.fromScale(0.3, 0.54),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),
		SwitchIdentity = e(swapButton, {
			Position = UDim2.fromScale(0.375, 0.8),
		}),
		Exit = e(saveButton, {
			Position = UDim2.fromScale(0.375, 0.025),
			ErrorMessage = props.ErrorMessage,
			IsSaving = props.IsSaving,
			OnSave = function(draft: Character)
				props.OnAction({
					Type = "Save",
					Character = draft,
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
