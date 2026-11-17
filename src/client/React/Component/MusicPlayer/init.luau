--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
-- Types
local SongType = require("@game/ReplicatedStorage/Shared/Type/Song")
export type SongDefinition = SongType.SongDefinition
export type ActionInfo =
	{
		Type: "SetPower",
		IsOn: boolean,
	}
	| {
		Type: "Next",
	}
	| {
		Type: "Previous",
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	Song: SongDefinition,
	IsOn: boolean,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local LABEL_FONT = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local BUTTON_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local ON_COLOR = Color3.fromRGB(75, 151, 75)
local OFF_COLOR = Color3.fromRGB(196, 40, 28)
local SLIDE_OFFSET = UDim2.fromScale(1, 0)
local SLIDE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function skipButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = BUTTON_FONT,
		Size = UDim2.fromScale(0.2, 1),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, props))
end
-- Class
return function(props: Properties)
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

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			-- a click that lands on the panel isn't one on the world behind it
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.7,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = initialPosition,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Header = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = LABEL_FONT,
				Position = UDim2.fromScale(0, 0.025),
				Size = UDim2.fromScale(0.5, 0.2),
				Text = "Music Player",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Power = e(
				"TextButton",
				{
					BackgroundColor3 = props.IsOn and ON_COLOR or OFF_COLOR,
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0.05, 0.3),
					Size = UDim2.fromScale(0.2, 0.5),
					Text = props.IsOn and "ON" or "OFF",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					[React.Event.Activated] = function()
						props.OnAction({
							Type = "SetPower",
							IsOn = not props.IsOn,
						})
					end,
				} :: RobloxComponents.TextButtonProperties
			),
			MusicDisplay = e("Frame", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.4,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.3, 0.25),
				Size = UDim2.fromScale(0.675, 0.65),
			}, {
				Left = e(
					skipButton,
					{
						Text = "<",
						[React.Event.Activated] = function()
							props.OnAction({
								Type = "Previous",
							})
						end,
					} :: RobloxComponents.TextButtonProperties
				),
				Right = e(
					skipButton,
					{
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Text = ">",
						[React.Event.Activated] = function()
							props.OnAction({
								Type = "Next",
							})
						end,
					} :: RobloxComponents.TextButtonProperties
				),
				Title = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0.25, 0.15),
					Size = UDim2.fromScale(0.5, 0.3),
					Text = props.Song.Title,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
				Artist = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0.25, 0.6),
					Size = UDim2.fromScale(0.5, 0.25),
					Text = props.Song.Artist,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextTransparency = 0.2,
					TextYAlignment = Enum.TextYAlignment.Top,
				}),
			}),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.fromScale(0, 0),
					ZIndex = 30,
					[React.Event.Activated] = close,
				} :: ExitButton.Properties
			),
		}
	))
end
