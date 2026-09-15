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
return function(inst: Instance?, key: string): any?
	local value, setValue = React.useState(inst and inst:GetAttribute(key) or nil)
	React.useEffect(function()
		local function update()
			if inst then
				setValue(inst:GetAttribute(key))
			else
				setValue(nil)
			end
		end
		local connection: RBXScriptConnection?
		if inst then
			connection = inst:GetAttributeChangedSignal(key):Connect(function()
				update()
			end)
		end
		update()
		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, { inst :: any, key })
	if inst == nil then
		value = nil
	end
	return value
end
