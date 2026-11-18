--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
-- Components
local BarButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerBrowser/BarButton")
local Notice = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerBrowser/Notice")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
export type Settings = ServerType.Settings
export type Properties = RobloxComponents.FrameProperties & {
	Notice: string?,
	FilterText: (text: string) -> string, -- yields
	OnBack: () -> (),
	OnDone: (Settings) -> (),
}
-- Constants
local CHECKED_TEXT = "\u{2611}\u{FE0F}"
local LABEL_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local INPUT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json")
local TEXT_COLOR = Color3.fromRGB(152, 152, 152)
local INPUT_COLOR = Color3.fromRGB(33, 33, 33)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function readLimit(text: string): number
	local digits = string.gsub(text, "%D", "")
	return ServerDefinition.fixLimit(tonumber(digits))
end

local function row(props: {
	LayoutOrder: number,
	Text: string,
	LabelSize: UDim2,
	children: { [string]: React.ReactNode }?,
})
	return e("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(1, 0.15),
	}, {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 2),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 2),
			PaddingTop = UDim.new(0, 2),
		}),
		Label = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			FontFace = LABEL_FONT,
			LayoutOrder = 1,
			Size = props.LabelSize,
			Text = props.Text,
			TextColor3 = TEXT_COLOR,
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, {
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.1, 0),
				PaddingRight = UDim.new(0, 5),
				PaddingTop = UDim.new(0.1, 0),
			}),
		}),
		Input = e(React.Fragment, {}, props.children),
	})
end

local function box(props: RobloxComponents.TextBoxProperties)
	return e(RobloxComponents.TextBox(
		{
			BackgroundColor3 = INPUT_COLOR,
			BorderSizePixel = 0,
			FontFace = INPUT_FONT,
			LayoutOrder = 2,
			PlaceholderColor3 = Color3.fromRGB(97, 97, 97),
			Size = UDim2.new(0.65, -4, 1, 0),
			TextColor3 = TEXT_COLOR,
			TextScaled = true,
			TextWrapped = true,
		},
		props,
		{
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.08, 0),
				PaddingTop = UDim.new(0.08, 0),
			}),
		}
	))
end
-- Class
return function(props: Properties)
	local name: string, setName: (string) -> () = React.useState("")
	local limitText: string, setLimitText: (string) -> () = React.useState("")
	local code: string, setCode: (string) -> () = React.useState("")
	local isPVP, setIsPVP = React.useState(false)
	local isMountedRef = useIsMounted()
	local nameRef = React.useRef(name)
	nameRef.current = name

	local function filterName(text: string)
		if text == "" then
			return
		end
		task.spawn(function()
			local filteredText = props.FilterText(text)
			-- a name that was typed over in the meantime isn't the one that was asked about
			if isMountedRef.current and nameRef.current == text then
				setName(filteredText)
			end
		end)
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			BorderSizePixel = 0,
		},
		props,
		{
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0.02, 0),
				PaddingLeft = UDim.new(0.02, 0),
				PaddingRight = UDim.new(0.02, 0),
				PaddingTop = UDim.new(0.02, 0),
			}),
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.fromScale(1, 0.125),
				Text = "Configure Private Server",
				TextColor3 = Color3.fromRGB(162, 162, 162),
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.15, 0),
					PaddingRight = UDim.new(0, 5),
					PaddingTop = UDim.new(0.15, 0),
				}),
			}),
			Fields = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(42, 42, 42),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(1, 0.7),
			}, {
				UIListLayout = e("UIListLayout", {
					Padding = UDim.new(0.05, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0.01, 0),
					PaddingLeft = UDim.new(0.04, 0),
					PaddingRight = UDim.new(0.04, 0),
					PaddingTop = UDim.new(0.01, 0),
				}),
				Name = e(row, {
					LayoutOrder = 1,
					Text = "Name",
					LabelSize = UDim2.new(0.35, -4, 1, 0),
				}, {
					TextBox = e(
						box,
						{
							PlaceholderText = "How it appears on server list",
							Text = name,
							[React.Change.Text] = function(textBox: TextBox)
								setName(textBox.Text)
							end,
							[React.Event.FocusLost] = function(textBox: TextBox)
								filterName(textBox.Text)
							end,
						} :: RobloxComponents.TextBoxProperties
					),
				}),
				Limit = e(row, {
					LayoutOrder = 2,
					Text = "Max Fill",
					LabelSize = UDim2.new(0.35, -4, 1, 0),
				}, {
					TextBox = e(
						box,
						{
							PlaceholderText = "How many players allowed in game",
							Text = limitText,
							[React.Change.Text] = function(textBox: TextBox)
								setLimitText(textBox.Text)
							end,
							[React.Event.FocusLost] = function(textBox: TextBox)
								setLimitText(tostring(readLimit(textBox.Text)))
							end,
						} :: RobloxComponents.TextBoxProperties
					),
				}),
				Code = e(row, {
					LayoutOrder = 3,
					Text = "Entry Code",
					LabelSize = UDim2.new(0.35, -4, 1, 0),
				}, {
					TextBox = e(
						box,
						{
							PlaceholderText = "Empty = Public, don't reuse passwords",
							Text = code,
							[React.Change.Text] = function(textBox: TextBox)
								setCode(textBox.Text)
							end,
						} :: RobloxComponents.TextBoxProperties
					),
				}),
				PVP = e(row, {
					LayoutOrder = 4,
					Text = "PVP Enabled",
					LabelSize = UDim2.new(0.3, -4, 1, 0),
				}, {
					CheckBox = e(
						"TextButton",
						{
							BackgroundColor3 = INPUT_COLOR,
							BorderSizePixel = 0,
							FontFace = INPUT_FONT,
							LayoutOrder = 2,
							Size = UDim2.fromScale(1, 1),
							SizeConstraint = Enum.SizeConstraint.RelativeYY,
							Text = if isPVP then CHECKED_TEXT else "",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextWrapped = true,
							[React.Event.Activated] = function()
								setIsPVP(not isPVP)
							end,
						} :: RobloxComponents.TextButtonProperties,
						{
							UIPadding = e("UIPadding", {
								PaddingBottom = UDim.new(0.08, 0),
								PaddingTop = UDim.new(0.08, 0),
							}),
						}
					),
				}),
			}),
			-- the title takes up all of its row, so down here it's next to the button it's about
			Notice = props.Notice and e(Notice, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.925),
				Size = UDim2.new(0.35, 0, 0, 30),
				Text = props.Notice,
			}),
			Back = e(
				BarButton,
				{
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.925),
					Text = "Back",
					[React.Event.Activated] = props.OnBack,
				} :: BarButton.Properties
			),
			Done = e(
				"TextButton",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(56, 132, 84),
					BorderColor3 = Color3.fromRGB(109, 167, 117),
					BorderMode = Enum.BorderMode.Inset,
					BorderSizePixel = 2,
					FontFace = LABEL_FONT,
					Position = UDim2.fromScale(0.5, 0.925),
					Size = UDim2.fromScale(0.25, 0.125),
					Text = "Done",
					TextColor3 = Color3.fromRGB(177, 177, 177),
					TextScaled = true,
					TextWrapped = true,
					[React.Event.Activated] = function()
						props.OnDone(ServerDefinition.fixSettings({
							Name = name,
							Limit = readLimit(limitText),
							Code = code,
							IsPVP = isPVP,
						}))
					end,
				} :: RobloxComponents.TextButtonProperties,
				{
					UISizeConstraint = e("UISizeConstraint", {
						MaxSize = Vector2.new(150, 50),
					}),
				}
			),
		}
	))
end
