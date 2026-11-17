--!strict
-- Services
-- Packages
-- Modules
-- Types
local Types = require("./Types")
type Tab = Types.Tab
export type TabInfo = {
	Tab: Tab, -- also the text of its button
	Position: UDim2,
	Size: UDim2,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {
	TABS = {
		{
			Tab = "Users",
			Position = UDim2.fromScale(0.3, 0.025),
			Size = UDim2.fromScale(0.15, 0.1),
		} :: TabInfo,
		{
			Tab = "Aliases",
			Position = UDim2.fromScale(0.5, 0.025),
			Size = UDim2.fromScale(0.15, 0.1),
		},
		{
			Tab = "Identities",
			Position = UDim2.fromScale(0.7, 0.025),
			Size = UDim2.fromScale(0.175, 0.1),
		},
	},
}
