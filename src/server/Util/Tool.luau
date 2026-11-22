--!strict
-- Services
-- Packages
-- Modules
-- Types
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type IconDefinition = MiscType.IconDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what the hotbar holds is made here: a power + a prop are the same thing to it
local Util = {}

-- a tool with nothing in it: no handle to weld + nothing to drop. what's seen in the hand is an effect's to show,
-- the attribute says what it stands for. one without an icon is spelt out by the hotbar
function Util.new(name: string, icon: IconDefinition?, attribute: string, id: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.ToolTip = name
	if icon then
		tool.TextureId = if icon.Type == "Decal" then icon.Url else icon.SheetUrl
	end
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute(attribute, id)
	return tool
end

return Util
