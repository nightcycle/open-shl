--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
local Components = script.Parent
-- Private Functions
-- Class
return {
	name = "Interface",
	-- a component keeps its story in its own folder, rooting at each of those leaves one flat list
	storyRoots = Components:GetChildren(),
}
