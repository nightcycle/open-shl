--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local EmoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Emote")
local ExpressionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Expression")
-- Components
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
local RowList = require("@self/RowList")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
-- Types
type IdentityKey = SessionActiveIdentityKeyContext.IdentityKey
export type ExpressionId = ExpressionDefinition.ExpressionId
export type EmoteId = EmoteDefinition.EmoteId
export type ActionInfo =
	{
		Type: "SetExpression",
		ExpressionId: ExpressionId?,
	}
	| {
		Type: "SetEmote",
		EmoteId: EmoteId?,
	}
	| {
		Type: "SetMasked",
		IsMasked: boolean,
	}
	| {
		Type: "SetHandcuffed",
		IsHandcuffed: boolean,
	}
	| {
		Type: "SetApartmentLocked",
		IsApartmentLocked: boolean,
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	ExpressionId: ExpressionId?,
	EmoteId: EmoteId?,
	IsMasked: boolean,
	IsHandcuffed: boolean,
	IsApartmentLocked: boolean,
	OnAction: (ActionInfo) -> (),
}
type TabId = "Expressions" | "Emotes" | "Misc"
type TabInfo = {
	Id: TabId,
	Text: string,
	Position: UDim2,
	Size: UDim2,
}
-- Constants
local TAB_HEIGHT = 0.15
local TAB_TEXT_SIZE = 14
local TABS: { TabInfo } = {
	{
		Id = "Expressions",
		Text = "Facial Expressions",
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.33, TAB_HEIGHT),
	},
	{
		Id = "Emotes",
		Text = "Actions",
		Position = UDim2.fromScale(0.33, 0),
		Size = UDim2.fromScale(0.34, TAB_HEIGHT),
	},
	{
		Id = "Misc",
		Text = "Miscellaneous",
		Position = UDim2.fromScale(0.67, 0),
		Size = UDim2.fromScale(0.33, TAB_HEIGHT),
	},
}
-- the panel waits just past the left edge of the screen
local SLIDE_OFFSET = UDim2.fromScale(0.7, 0)
local SLIDE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local identityKey: IdentityKey = React.useContext(SessionActiveIdentityKeyContext) :: IdentityKey
	local tabId: TabId, setTabId: (TabId) -> () = React.useState("Expressions" :: TabId)
	local openPosition = props.Position or UDim2.new()
	local frameRef, initialPosition, close = useSlide(
		openPosition,
		openPosition - SLIDE_OFFSET,
		SLIDE_TWEEN_INFO,
		function()
			props.OnAction({
				Type = "Exit",
			})
		end
	)

	local expressionRows: { RowList.RowInfo } = {}
	for _, definition in ExpressionDefinition.list() do
		local isActive = props.ExpressionId == definition.Id
		local rowInfo: RowList.RowInfo = {
			Id = definition.Id,
			Text = definition.Name,
			ButtonText = isActive and "Using" or "Use",
			IsActive = isActive,
			OnClick = function()
				props.OnAction({
					Type = "SetExpression",
					ExpressionId = if isActive then nil else definition.Id,
				})
			end,
		}
		table.insert(expressionRows, rowInfo)
	end
	local emoteRows: { RowList.RowInfo } = {}
	for _, definition in EmoteDefinition.list() do
		local isActive = props.EmoteId == definition.Id
		local rowInfo: RowList.RowInfo = {
			Id = definition.Id,
			Text = definition.Name,
			ButtonText = isActive and "Activated" or "Activate",
			IsActive = isActive,
			OnClick = function()
				props.OnAction({
					Type = "SetEmote",
					EmoteId = if isActive then nil else definition.Id,
				})
			end,
		}
		table.insert(emoteRows, rowInfo)
	end
	-- the first two are captioned with what the next press does, the lock with what it is
	local miscRows: { RowList.RowInfo } = {
		{
			Id = "Mask",
			Text = "Mask",
			ButtonText = props.IsMasked and "Remove" or "Apply",
			IsActive = not props.IsMasked,
			-- only the super identity has a mask to take off
			IsDisabled = identityKey ~= "Main",
			OnClick = function()
				props.OnAction({
					Type = "SetMasked",
					IsMasked = not props.IsMasked,
				})
			end,
		},
		{
			Id = "Handcuffs",
			Text = "Handcuffs",
			ButtonText = props.IsHandcuffed and "Remove" or "Apply",
			IsActive = props.IsHandcuffed,
			OnClick = function()
				props.OnAction({
					Type = "SetHandcuffed",
					IsHandcuffed = not props.IsHandcuffed,
				})
			end,
		},
		{
			Id = "Apartment",
			Text = "Apartment",
			ButtonText = props.IsApartmentLocked and "Locked" or "Unlocked",
			IsActive = false,
			OnClick = function()
				props.OnAction({
					Type = "SetApartmentLocked",
					IsApartmentLocked = not props.IsApartmentLocked,
				})
			end,
		},
	}

	local tabs: { [string]: React.ReactNode } = {}
	for _, TAB in TABS do
		tabs[`{TAB.Id}Tab`] = e(
			"TextButton",
			{
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = tabId == TAB.Id and 0 or 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = TAB.Position,
				Size = TAB.Size,
				Text = TAB.Text,
				TextColor3 = Color3.fromRGB(27, 42, 53),
				TextScaled = true,
				[React.Event.Activated] = function()
					setTabId(TAB.Id)
				end,
			} :: RobloxComponents.TextButtonProperties,
			{
				UITextSizeConstraint = e("UITextSizeConstraint", {
					MaxTextSize = TAB_TEXT_SIZE,
				}),
			}
		)
	end

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.7,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = initialPosition,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Tabs = e(React.Fragment, {}, tabs),
			Expressions = e(
				RowList,
				{
					Position = UDim2.fromScale(0, TAB_HEIGHT),
					Size = UDim2.fromScale(1, 1 - TAB_HEIGHT),
					Visible = tabId == "Expressions",
					Rows = expressionRows,
				} :: RowList.Properties
			),
			Emotes = e(
				RowList,
				{
					Position = UDim2.fromScale(0, TAB_HEIGHT),
					Size = UDim2.fromScale(1, 1 - TAB_HEIGHT),
					Visible = tabId == "Emotes",
					Rows = emoteRows,
				} :: RowList.Properties
			),
			Misc = e(
				RowList,
				{
					Position = UDim2.fromScale(0, TAB_HEIGHT),
					Size = UDim2.fromScale(1, 1 - TAB_HEIGHT),
					Visible = tabId == "Misc",
					Rows = miscRows,
				} :: RowList.Properties
			),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.fromScale(0, 0),
					ZIndex = 2,
					[React.Event.Activated] = close,
				} :: ExitButton.Properties
			),
		}
	))
end
