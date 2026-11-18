--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
local StyleTypes = require("@self/Types")
export type Style = StyleTypes.Style
-- Constants
-- the look the widgets were written in. it's what's read where nothing provides one, so whatever is mounted by itself
-- is drawn the way it always was. the app provides the look of the game it's built for
local DEFAULT: Style = require("@self/SHL2")
assert(StyleTypes.Style(DEFAULT))
TableUtil.deepFreeze(DEFAULT)
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(DEFAULT)
