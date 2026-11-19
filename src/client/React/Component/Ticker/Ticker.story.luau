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
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Ticker/CONSTANTS")
-- a line that doesn't fit the bar at the size the rest are read at, to see what the bar does with it
local LONG_MESSAGES: { string } = table.freeze({
	"A line of news that goes on for as long as nobody stops it, well past what the bar was made to hold of one, so"
		.. " what's left of its size by the end can be looked at",
	"Short",
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a message stays for seven seconds, the bar is empty for one before each
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		IsLong = UILabs.Boolean(false),
	},
}, function(props)
	local isLong: boolean = props.controls.IsLong
	local tickers: { [string]: React.ReactNode } = {}
	-- another list is another ticker, it starts over from its first line
	tickers[if isLong then "Long" else "News"] = e(
		ParentComponent,
		{
			Size = UDim2.fromScale(1, 1),
			Messages = if isLong then LONG_MESSAGES else CONSTANTS.MESSAGES,
		} :: ParentComponent.Properties
	)

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.9),
		}, tickers),
	})
end)
