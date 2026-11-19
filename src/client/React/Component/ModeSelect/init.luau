--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
-- Types
local ModeSelectTypes = require("@self/Types")
export type Mode = ModeSelectTypes.Mode
export type ActionInfo = ModeSelectTypes.ActionInfo
export type Properties = ModeSelectTypes.Properties
-- Constants
local EMPTY_ID_TEXT = "You need to insert an ID first, otherwise click a mode!"
local LEAVE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COMBAT_POSITION = UDim2.fromScale(0.3, 0.35)
local COMBAT_AWAY_POSITION = UDim2.fromScale(-0.4, 0.1)
local ROLEPLAY_POSITION = UDim2.fromScale(0.7, 0.35)
local ROLEPLAY_AWAY_POSITION = UDim2.fromScale(1.1, 0.1)
local ID_POSITION = UDim2.new(1, -20, 1, -20)
local ID_AWAY_POSITION = UDim2.new(1, -20, 1.1, 0)
local ID_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local SERVERS_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the frame is only told where it starts out, from there on it slides to where it belongs
local function useLeave(isLeaving: boolean, position: UDim2, awayPosition: UDim2): ({ current: Frame? }, UDim2)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local initialPositionRef = React.useRef(if isLeaving then awayPosition else position)
	useTween(frameRef, LEAVE_TWEEN_INFO, {
		Position = if isLeaving then awayPosition else position,
	}, { isLeaving })
	return frameRef, initialPositionRef.current
end

local function modeButton(props: {
	Image: string,
	Position: UDim2,
	AwayPosition: UDim2,
	IsLeaving: boolean,
	OnClick: () -> (),
})
	local frameRef, initialPosition = useLeave(props.IsLeaving, props.Position, props.AwayPosition)
	local isClickable = not props.IsLeaving
	return e(
		"Frame",
		{
			ref = frameRef,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = initialPosition,
			Size = UDim2.fromScale(0.3, 0.3),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 2,
		} :: RobloxComponents.FrameProperties,
		{
			Button = e(
				"ImageButton",
				{
					Active = isClickable,
					AutoButtonColor = isClickable,
					BackgroundTransparency = 1,
					ImageContent = Content.fromUri(props.Image),
					Selectable = isClickable,
					Size = UDim2.fromScale(1, 1),
					[React.Event.Activated] = isClickable and function()
						props.OnClick()
					end or nil,
				} :: RobloxComponents.ImageButtonProperties
			),
		}
	)
end
-- Class
return function(props: Properties): React.ReactNode
	local idText: string, setIdText: (string) -> () = React.useState("")
	-- the line the box was last made to say, a box that still says it holds no id
	local idMessageRef: { current: string? } = React.useRef(nil :: string?)
	local idRef, initialIdPosition = useLeave(props.IsLeaving, ID_POSITION, ID_AWAY_POSITION)
	React.useEffect(function()
		if props.IdNotice then
			idMessageRef.current = props.IdNotice
			setIdText(props.IdNotice)
		end
		return function() end
	end, { props.IdNotice })

	local isClickable = not props.IsLeaving
	local function enter()
		local id = string.match(idText, "^%s*(.-)%s*$") or ""
		if id == "" or idText == idMessageRef.current then
			idMessageRef.current = EMPTY_ID_TEXT
			setIdText(EMPTY_ID_TEXT)
			return
		end
		props.OnAction({
			Type = "IdEntered",
			Id = id,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
			}),

			Combat = e(modeButton, {
				Image = Image["shl-2"].ui["combat-mode.png"],
				Position = COMBAT_POSITION,
				AwayPosition = COMBAT_AWAY_POSITION,
				IsLeaving = props.IsLeaving,
				OnClick = function()
					props.OnAction({
						Type = "ModePressed",
						Mode = "combat",
					})
				end,
			}),

			Roleplay = e(modeButton, {
				Image = Image["shl-2"].ui["roleplay-mode.png"],
				Position = ROLEPLAY_POSITION,
				AwayPosition = ROLEPLAY_AWAY_POSITION,
				IsLeaving = props.IsLeaving,
				OnClick = function()
					props.OnAction({
						Type = "ModePressed",
						Mode = "roleplay",
					})
				end,
			}),

			Servers = e(
				"TextButton",
				{
					Active = isClickable,
					AnchorPoint = Vector2.new(0.5, 0.5),
					AutoButtonColor = isClickable,
					BackgroundColor3 = Color3.fromRGB(168, 168, 168),
					FontFace = SERVERS_FONT,
					Position = UDim2.fromScale(0.5, 0.75),
					Selectable = isClickable,
					Size = UDim2.fromScale(0.3, 0.1),
					Text = "Private Servers",
					TextColor3 = Color3.fromRGB(27, 27, 27),
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
					[React.Event.Activated] = isClickable and function()
						props.OnAction({
							Type = "ServersPressed",
						})
					end or nil,
				} :: RobloxComponents.TextButtonProperties,
				{
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0.2, 0),
					}),
					UIPadding = e("UIPadding", {
						PaddingBottom = UDim.new(0.1, 0),
						PaddingLeft = UDim.new(0.1, 0),
						PaddingRight = UDim.new(0.1, 0),
						PaddingTop = UDim.new(0.1, 0),
					}),
				}
			),

			Notice = props.Notice and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				FontFace = SERVERS_FONT,
				Position = UDim2.fromScale(0.5, 0.82),
				Size = UDim2.fromScale(0.6, 0.035),
				Text = props.Notice,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 2,
			}),

			Id = e(
				"Frame",
				{
					ref = idRef,
					AnchorPoint = Vector2.new(1, 1),
					BackgroundColor3 = Color3.fromRGB(99, 99, 99),
					BackgroundTransparency = 0.65,
					BorderSizePixel = 0,
					Position = initialIdPosition,
					Size = UDim2.fromScale(0.3, 0.065),
					ZIndex = 2,
				} :: RobloxComponents.FrameProperties,
				{
					UIPadding = e("UIPadding", {
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
						PaddingTop = UDim.new(0, 5),
					}),
					TextBox = e(
						"TextBox",
						{
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundColor3 = Color3.fromRGB(68, 68, 68),
							BorderSizePixel = 0,
							FontFace = ID_FONT,
							PlaceholderColor3 = Color3.fromRGB(132, 132, 132),
							PlaceholderText = "[OPTIONAL] Insert Server ID",
							Position = UDim2.fromScale(0.01, 0.5),
							Size = UDim2.fromScale(0.7, 0.9),
							Text = idText,
							TextColor3 = Color3.fromRGB(132, 132, 132),
							TextEditable = isClickable,
							TextScaled = true,
							TextWrapped = true,
							[React.Change.Text] = function(textBox: TextBox)
								setIdText(textBox.Text)
							end,
						} :: RobloxComponents.TextBoxProperties
					),
					Enter = e(
						"TextButton",
						{
							Active = isClickable,
							AnchorPoint = Vector2.new(1, 0.5),
							AutoButtonColor = isClickable,
							BackgroundColor3 = Color3.fromRGB(29, 161, 0),
							BorderSizePixel = 0,
							FontFace = ID_FONT,
							Position = UDim2.fromScale(0.99, 0.5),
							Selectable = isClickable,
							Size = UDim2.fromScale(0.25, 0.8),
							Text = "ENTER",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextWrapped = true,
							[React.Event.Activated] = isClickable and enter or nil,
						} :: RobloxComponents.TextButtonProperties
					),
				}
			),
		}
	))
end
