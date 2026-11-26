--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
-- what the server says to whoever asks for a place the build was never told of
local REFUSAL_TEXT = "roleplay isn't available yet"
-- seconds the stand-in for the server takes to turn a teleport down
local REFUSAL_DELAY = 1.5
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
		-- stands in for the server: on, a teleport is turned down a moment later + the card is back with why
		IsRefused = UILabs.Boolean(false),
		-- the roleplay place has no other place to offer: the old one opened an empty panel there
		IsEmpty = UILabs.Boolean(false),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local isLeaving, setIsLeaving = React.useState(false)
	local notice: string?, setNotice: (string?) -> () = React.useState(nil :: string?)
	local isRefused: boolean = props.controls.IsRefused
	local isEmpty: boolean = props.controls.IsEmpty

	local cards: { ParentComponent.CardInfo } = {}
	if not isEmpty then
		table.insert(cards, {
			Mode = "roleplay",
			Title = "Roleplay Mode",
			Description = "Tired of getting killed while roleplaying with friends? Roleplay mode is your answer!",
			IsLeaving = isLeaving,
			Notice = notice,
		})
	end

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
					Cards = cards,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Teleport" then
							setIsLeaving(true)
							setNotice(nil)
							if isRefused then
								task.delay(REFUSAL_DELAY, function()
									setIsLeaving(false)
									setNotice(REFUSAL_TEXT)
								end)
							end
						elseif action.Type == "Exit" then
							setIsOpen(false)
						end
					end,
				} :: ParentComponent.Properties
			),
			-- stands in for the hud button, which is where the panel is opened from
			Open = not isOpen and e("ImageButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(Image["shl-3"].ui["mode-changer"]["open.png"]),
				Position = UDim2.new(1, -10, 0.8, 0),
				Size = UDim2.fromScale(0.075, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				[React.Event.Activated] = function()
					setIsLeaving(false)
					setNotice(nil)
					setIsOpen(true)
				end,
			}),
		}),
	})
end)
