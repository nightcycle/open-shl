--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Types
export type Properties = Frame.Properties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	return e(
		Frame({
			BackgroundTransparency = 1,
			Active = false,
		} :: Frame.Properties),
		props,
		{}
	)
end
