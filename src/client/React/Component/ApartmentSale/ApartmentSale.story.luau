--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
-- the four lines + two of the sentences of the salesman of the old place
local TITLE_TEXT = "BELMONT SQUARE"
local PROMPT_TEXT = "Welcome to Belmont Square, would you like to buy a new condo?"
local RESPONSE_TEXT = "Excellent choice! Enter the elevator to your left to find your apartment!"
local ROWS: { ParentComponent.RowInfo } = table.freeze({
	table.freeze({ Tier = 1, Text = "Lower Class - $250" }),
	table.freeze({ Tier = 2, Text = "Middle Class - $1250" }),
	table.freeze({ Tier = 3, Text = "Upper Class - $4250" }),
	table.freeze({ Tier = 4, Text = "Luxury Class - $10000" }),
})
-- what the server says to whoever can't pay
local REFUSAL_TEXT = "not enough Credits"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		-- stands in for the server: on, a flat that's asked for is turned down
		IsRefused = UILabs.Boolean(false),
		-- an ask that's never answered: the rows take no press
		IsBusy = UILabs.Boolean(false),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local message: string?, setMessage: (string?) -> () = React.useState(nil :: string?)
	local isRefused: boolean = props.controls.IsRefused

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Menu = isOpen and e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Title = TITLE_TEXT,
					Text = PROMPT_TEXT,
					Rows = ROWS,
					Message = message,
					IsBusy = props.controls.IsBusy,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Purchase" then
							setMessage(if isRefused then REFUSAL_TEXT else RESPONSE_TEXT)
						elseif action.Type == "Exit" then
							setIsOpen(false)
						end
					end,
				} :: ParentComponent.Properties
			),
			-- stands in for the prompt of the salesman, which is where the panel is opened from. he starts over
			Open = not isOpen and e("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 166, 230),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.new(1, -10, 0.6, 0),
				Size = UDim2.fromScale(0.075, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = "Talk",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					setMessage(nil)
					setIsOpen(true)
				end,
			}),
		}),
	})
end)
