--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local StyleTypes = require("@self/Types")
export type Style = StyleTypes.Style
-- Constants
-- the look of the game that's built. it's what's read where nothing provides one, so whatever is mounted by itself is
-- drawn the way the app draws it. the look of another game is never required
local DEFAULT: Style = GameDefinition.pick({
	shl1 = function(): Style
		return require("@self/SHL1")
	end,
	shl2 = function(): Style
		return require("@self/SHL2")
	end,
	shl3 = function(): Style
		return require("@self/SHL3")
	end,
})
assert(StyleTypes.Style(DEFAULT))
TableUtil.deepFreeze(DEFAULT)
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(DEFAULT)
