--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
local Library = script.Parent
-- Private Functions
-- Class
return {
	name = "VFX (Server)",
	-- an effect keeps its story in its own folder, rooting at each of those leaves one flat list
	storyRoots = Library:GetChildren(),
}
