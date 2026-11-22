--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local BarButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerBrowser/BarButton")
local Card = require("@self/Card")
local Notice = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerBrowser/Notice")
-- Hooks
-- Contexts
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
export type Listing = ServerType.Listing
export type Properties = RobloxComponents.FrameProperties & {
	Listings: { Listing },
	Notice: string?,
	OnBack: () -> (),
	OnRefresh: () -> (),
	OnCreate: () -> (),
	OnJoin: (Listing) -> (),
}
-- Constants
local ROW_SIZE = UDim2.new(1, 0, 0, 44)
-- what a row is counted as when the canvas is measured out, a little more than it + the gap under it take up
local CELL_HEIGHT = 49
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local windowHeight: number, setWindowHeight: (number) -> () = React.useState(0)
	local function measure(scrollingFrame: ScrollingFrame)
		setWindowHeight(scrollingFrame.AbsoluteWindowSize.Y)
	end
	local fillHeight = #props.Listings * CELL_HEIGHT
	-- rows with nothing in them take up what the cards leave of the window
	local emptyCount = if fillHeight < windowHeight then 1 + math.ceil((windowHeight - fillHeight) / CELL_HEIGHT) else 0

	local rows: { [string]: React.ReactNode } = {}
	for i, listing in props.Listings do
		rows[`Listing-{listing.Id}`] = e(
			Card,
			{
				LayoutOrder = i,
				Size = ROW_SIZE,
				Listing = listing,
				OnJoin = props.OnJoin,
			} :: Card.Properties
		)
	end
	for i = 1, emptyCount do
		rows[`Empty-{i}`] = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(31, 31, 31),
			BorderColor3 = Color3.fromRGB(83, 83, 83),
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = 2,
			LayoutOrder = #props.Listings + i,
			Size = ROW_SIZE,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			BorderSizePixel = 0,
		},
		props,
		{
			UIListLayout = e("UIListLayout", {
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			UIPadding = e("UIPadding", {
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 10),
			}),
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 30),
				Text = "List",
				TextColor3 = Color3.fromRGB(162, 162, 162),
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				Notice = props.Notice and e(Notice, {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(0.7, 1),
					Text = props.Notice,
				}),
			}),
			Bar = e("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 40),
			}, {
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 3),
					PaddingRight = UDim.new(0, 3),
					PaddingTop = UDim.new(0, 5),
				}),
				Back = e(
					BarButton,
					{
						Text = "Back",
						[React.Event.Activated] = props.OnBack,
					} :: BarButton.Properties
				),
				Refresh = e(
					BarButton,
					{
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						Text = "Refresh",
						[React.Event.Activated] = props.OnRefresh,
					} :: BarButton.Properties
				),
				Create = e(
					BarButton,
					{
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Text = "Create",
						IsConfirm = true,
						[React.Event.Activated] = props.OnCreate,
					} :: BarButton.Properties
				),
			}),
			ScrollingFrame = e(
				"ScrollingFrame",
				{
					Active = true,
					BackgroundColor3 = Color3.fromRGB(31, 31, 31),
					BorderColor3 = Color3.fromRGB(35, 35, 35),
					BorderSizePixel = 10,
					CanvasSize = UDim2.fromOffset(0, fillHeight),
					HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					LayoutOrder = 3,
					ScrollBarImageColor3 = Color3.fromRGB(89, 89, 89),
					ScrollBarThickness = 30,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					Size = UDim2.new(1, 0, 1, -80),
					VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
					[React.Change.AbsoluteSize] = measure,
					[React.Change.AbsoluteWindowSize] = measure,
				} :: RobloxComponents.ScrollingFrameProperties,
				{
					UIListLayout = e("UIListLayout", {
						Padding = UDim.new(0, 3),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Rows = e(React.Fragment, {}, rows),
				}
			),
		}
	))
end
