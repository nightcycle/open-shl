--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
-- Components
-- Hooks
-- Contexts
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
export type Listing = ServerType.Listing
export type Properties = RobloxComponents.FrameProperties & {
	Listing: Listing,
	OnJoin: (Listing) -> (),
}
-- Constants
local LOCKED_TEXT = "\u{1F511}"
local PVP_TEXT = "\u{1F3F9}"
local PEACE_TEXT = "\u{262E}"
local LABEL_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json")
local LABEL_COLOR = Color3.fromRGB(209, 209, 209)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function glyph(props: RobloxComponents.TextLabelProperties)
	return e(RobloxComponents.TextLabel({
		BackgroundTransparency = 1,
		FontFace = LABEL_FONT,
		Size = UDim2.fromScale(0.04, 1),
		TextColor3 = LABEL_COLOR,
		TextScaled = true,
		TextWrapped = true,
	}, props))
end

local function field(props: RobloxComponents.TextLabelProperties)
	return e(RobloxComponents.TextLabel(
		{
			BackgroundColor3 = Color3.fromRGB(42, 42, 42),
			BorderSizePixel = 0,
			FontFace = LABEL_FONT,
			TextColor3 = LABEL_COLOR,
			TextSize = 15,
			TextWrapped = true,
		},
		props,
		{
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0, 1),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				PaddingTop = UDim.new(0, 1),
			}),
		}
	))
end
-- Class
return function(props: Properties)
	local listing = props.Listing
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.fromRGB(49, 49, 49),
			BorderColor3 = Color3.fromRGB(62, 62, 62),
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = 2,
		},
		props,
		{
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 4),
			}),
			Region = e(glyph, {
				LayoutOrder = 1,
				Text = ServerDefinition.getFlag(listing.Region),
			}),
			Access = e(glyph, {
				LayoutOrder = 2,
				Text = if listing.IsLocked then LOCKED_TEXT else "",
			}),
			Mode = e(glyph, {
				LayoutOrder = 3,
				Text = if listing.IsPVP then PVP_TEXT else PEACE_TEXT,
			}),
			Title = e(field, {
				LayoutOrder = 4,
				Size = UDim2.new(0.5, -50, 1, 0),
				Text = listing.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Username = e(field, {
				LayoutOrder = 5,
				Size = UDim2.fromScale(0.15, 1),
				Text = listing.OwnerName,
			}),
			Fill = e(field, {
				LayoutOrder = 6,
				Size = UDim2.fromScale(0.1, 1),
				Text = `[{listing.Fill}/{listing.Limit}]`,
				TextScaled = true,
			}),
			Join = e(
				"TextButton",
				{
					BackgroundColor3 = Color3.fromRGB(46, 105, 132),
					BorderColor3 = Color3.fromRGB(109, 145, 167),
					BorderMode = Enum.BorderMode.Inset,
					BorderSizePixel = 2,
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Medium,
						Enum.FontStyle.Normal
					),
					LayoutOrder = 7,
					Size = UDim2.fromScale(0.15, 1),
					Text = "Join",
					TextColor3 = Color3.fromRGB(177, 177, 177),
					TextSize = 14,
					TextWrapped = true,
					[React.Event.Activated] = function()
						props.OnJoin(listing)
					end,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
