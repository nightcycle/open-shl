--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a request can outlive the component that sent it
return function(): { current: boolean }
	local isMountedRef = React.useRef(true)
	React.useEffect(function()
		isMountedRef.current = true
		return function()
			isMountedRef.current = false
		end
	end, {})
	return isMountedRef
end
