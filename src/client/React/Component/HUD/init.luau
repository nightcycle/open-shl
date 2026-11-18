--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local StatBars = require("@self/StatBars")
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Types
local HUDTypes = require("@self/Types")
export type Properties = HUDTypes.Properties
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local BUTTON_SIZE = 0.08
local BUTTON_PADDING = 0.02
local COLUMN_SIZE = 0.75 + BUTTON_SIZE - 0.45
local CAMERA_MODE_TRANSPARENCY = 0.8
local BUILD_POSITION = UDim2.fromScale(0.1, 0.75)
local BUILD_HIDDEN_POSITION = UDim2.fromScale(-0.1, 0.75)
local BUILD_TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local isCameraMode = props.IsCameraMode == true
	local buildInfo = CONSTANTS.BUTTONS.BUILD
	local isBuildVisible = props.IsBuildVisible == true and not isCameraMode

	local buildRef: { current: ImageButton? } = React.useRef(nil :: ImageButton?)
	local initialBuildPositionRef = React.useRef(isBuildVisible and BUILD_POSITION or BUILD_HIDDEN_POSITION)
	useTween(buildRef, BUILD_TWEEN_INFO, {
		Position = isBuildVisible and BUILD_POSITION or BUILD_HIDDEN_POSITION,
	}, { isBuildVisible })

	local leftButtons: { [string]: React.ReactNode } = {}
	for i, buttonInfo in CONSTANTS.BUTTONS.LEFT do
		local isCamera = buttonInfo.MenuId == PseudoEnum.MenuId.Camera
		local isUsable = not isCameraMode or isCamera -- an unusable button still holds its place in the column
		local transparency = if not isUsable then 1 elseif isCameraMode then CAMERA_MODE_TRANSPARENCY else 0
		leftButtons[`{buttonInfo.MenuId}`] = e(
			"ImageButton",
			{
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = i,
				BorderSizePixel = isUsable and 1 or 0,
				BackgroundColor3 = buttonInfo.BackgroundColor3,
				BackgroundTransparency = transparency,
				ImageContent = Content.fromUri(buttonInfo.Image),
				ImageTransparency = transparency,
				Active = isUsable,
				Interactable = isUsable,
				Visible = not (isCamera and props.IsCameraHidden == true),
				[React.Event.Activated] = function()
					props.OnClick(buttonInfo.MenuId)
				end,
			} :: RobloxComponents.ImageButtonProperties
		)
	end
	local rightButtons: { [string]: React.ReactNode } = {}
	for i, buttonInfo in CONSTANTS.BUTTONS.RIGHT do
		rightButtons[`{buttonInfo.MenuId}`] = e(
			"ImageButton",
			{
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				LayoutOrder = i,
				BorderSizePixel = 1,
				BackgroundColor3 = buttonInfo.BackgroundColor3,
				ImageContent = Content.fromUri(buttonInfo.Image),
				[React.Event.Activated] = function()
					props.OnClick(buttonInfo.MenuId)
				end,
			} :: RobloxComponents.ImageButtonProperties
		)
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Bars = not isCameraMode and e(StatBars, {
				IsHealthVisible = props.IsHealthVisible,
				IsEnergyVisible = props.IsEnergyVisible,
			}),
			Left = e(
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.fromScale(BUTTON_SIZE, COLUMN_SIZE),
					Position = UDim2.fromScale(0.04, 0.45 - BUTTON_SIZE / 2),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Active = false,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(BUTTON_PADDING / COLUMN_SIZE, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: RobloxComponents.UIListLayoutProperties
					),
					Buttons = e(React.Fragment, {}, leftButtons),
				}
			),
			Right = not isCameraMode and e(
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.fromScale(BUTTON_SIZE, COLUMN_SIZE),
					Position = UDim2.fromScale(1 - 0.04, 0.45 - BUTTON_SIZE / 2),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Active = false,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e(
						"UIListLayout",
						{
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(BUTTON_PADDING / COLUMN_SIZE, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
						} :: RobloxComponents.UIListLayoutProperties
					),
					Buttons = e(React.Fragment, {}, rightButtons),
				}
			),
			Build = buildInfo and e(
				"ImageButton",
				{
					ref = buildRef,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
					Position = initialBuildPositionRef.current,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BorderSizePixel = 1,
					BackgroundColor3 = buildInfo.BackgroundColor3,
					ImageContent = Content.fromUri(buildInfo.Image),
					Active = isBuildVisible,
					Interactable = isBuildVisible,
					Visible = not isCameraMode,
					[React.Event.Activated] = function()
						props.OnClick(buildInfo.MenuId)
					end,
				} :: RobloxComponents.ImageButtonProperties
			),
		}
	))
end
