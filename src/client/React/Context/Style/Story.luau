--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Style = StyleTypes.Style
-- "none" is the story as it mounts with nothing around it
export type StyleName = "none" | "shl2" | "shl3"
-- Constants
local NAMES: { StyleName } = table.freeze({ "none" :: StyleName, "shl2", "shl3" })
-- a style is nothing but values, so a story can be looked at in the look of a game the place isn't built for
local LOADERS: { [StyleName]: () -> Style } = table.freeze({
	shl2 = function(): Style
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/SHL2")
	end,
	shl3 = function(): Style
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/SHL3")
	end,
})
-- Variables
local Styles: { [StyleName]: Style } = {}
-- References
-- Private Functions
local e = React.createElement

local function getStyle(name: StyleName): Style?
	local load = LOADERS[name]
	if not load then
		return nil
	end
	local style: Style? = Styles[name]
	if not style then
		local loaded = load()
		assert(StyleTypes.Style(loaded))
		TableUtil.deepFreeze(loaded)
		Styles[name] = loaded
		style = loaded
	end
	return style
end
-- Class
-- what a story needs to be seen in the look of every game that has one
local Module = {}

-- the control a story picks its look with, starting at the one it's told to
Module.newControl = function(default: StyleName?)
	return UILabs.Choose(NAMES, table.find(NAMES, default or "none" :: StyleName))
end

Module.provide = function(name: StyleName, children: { [string]: React.ReactNode }): React.ReactNode
	local style = getStyle(name)
	if not style then
		return e(React.Fragment, {}, children)
	end
	return e(StyleContext.Provider, {
		value = style,
	}, children)
end

return Module
