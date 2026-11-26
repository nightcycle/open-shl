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
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ChatLog/CONSTANTS")
-- what a log reads like: a name that needs its escapes, a line that's muted + one that's longer than the box
local SAMPLE_LINES: { string } = table.freeze({
	"Night Falcon: anybody at the bank?",
	"Dr. Malice: come + find out",
	"[MUTED]",
	"Tom &amp; Jerry: we sit this one out",
	"Night Falcon: a line that goes on for as long as nobody stops it, well past what the box was made to hold of one,"
		.. " so where it ends up can be looked at",
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the button is pressed for real: it reads "MUTED" until it's pressed again. more lines than the log holds are asked
-- for to see the oldest go
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		LineCount = UILabs.Slider(5, 0, CONSTANTS.LINE_COUNT + 3, 1),
		IsPeaceful = UILabs.Boolean(false),
	},
}, function(props)
	local isMuting: boolean, setIsMuting: (boolean) -> () = React.useState(false)
	local lineCount: number = props.controls.LineCount
	local lines = React.useMemo(function(): { string }
		local out: { string } = {}
		for index = 1, lineCount do
			out[index] = `{index}. {SAMPLE_LINES[(index - 1) % #SAMPLE_LINES + 1]}`
		end
		return out
	end, { lineCount })

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Log = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Lines = lines,
					IsPeaceful = props.controls.IsPeaceful,
					IsMuting = isMuting,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "ToggleMute" then
							setIsMuting(not isMuting)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
