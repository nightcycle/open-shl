--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
local Utils = script.Parent
-- Private Functions
-- Class
return {
	name = "Util (Shared)",
	-- a util keeps its story in its own folder, rooting at each of those leaves one flat list
	storyRoots = Utils:GetChildren(),
}
