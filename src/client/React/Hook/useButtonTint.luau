--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type ButtonTint = StyleTypes.ButtonTint
-- what a button listens to, keyed the way the events of an instance are
export type Listeners = { [any]: () -> () }
-- Constants
local NO_LISTENERS: Listeners = table.freeze({})
-- Variables
-- References
-- Private Functions
-- Class
-- the tint of whatever the pointer is doing to a button + what the button has to listen to for it. a look with neither
-- tint listens to nothing, so a button of that look is the same instance it was before looks had any
return function(hover: ButtonTint?, press: ButtonTint?): (ButtonTint?, Listeners)
	local isHovered, setIsHovered = React.useState(false)
	local isPressed, setIsPressed = React.useState(false)
	local isListening = hover ~= nil or press ~= nil
	local listeners = React.useMemo(function(): Listeners
		if not isListening then
			return NO_LISTENERS
		end
		local out: Listeners = {}
		out[React.Event.MouseEnter] = function()
			setIsHovered(true)
		end
		-- a button that's left while it's held never hears of the release
		out[React.Event.MouseLeave] = function()
			setIsHovered(false)
			setIsPressed(false)
		end
		out[React.Event.MouseButton1Down] = function()
			setIsPressed(true)
		end
		out[React.Event.MouseButton1Up] = function()
			setIsPressed(false)
		end
		table.freeze(out)
		return out
	end, { isListening })

	if isPressed and press then
		return press, listeners
	elseif isHovered or isPressed then
		return hover, listeners
	end
	return nil, listeners
end
