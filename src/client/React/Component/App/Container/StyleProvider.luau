--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Style = StyleTypes.Style
export type Properties = {
	children: { [string]: React.ReactNode }?,
}
-- Constants
-- how the game that's built looks. what the context holds by itself is only read by what's mounted without the app
local STYLE: Style = GameDefinition.pick({
	shl1 = function(): Style
		error(`shl1 has no style yet`)
	end,
	shl2 = function(): Style
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/SHL2")
	end,
	shl3 = function(): Style
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/SHL3")
	end,
})
assert(StyleTypes.Style(STYLE))
TableUtil.deepFreeze(STYLE)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	return e(StyleContext.Provider, {
		value = STYLE,
	}, props.children)
end
