--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- a new one for every set, so the same value set twice still starts the clock over
type Entry<V> = {
	Value: V,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the value is nil again once the duration has passed since it was last set
return function<V>(duration: number): (V?, (V?) -> ())
	local entry: Entry<V>?, setEntry: (Entry<V>?) -> () = React.useState(nil :: Entry<V>?)
	React.useEffect(function()
		if not entry then
			return function() end
		end
		local isDead = false
		task.delay(duration, function()
			if not isDead then
				setEntry(nil)
			end
		end)
		return function()
			isDead = true
		end
	end, { entry })

	return if entry then entry.Value else nil,
		function(value: V?)
			setEntry(if value ~= nil then { Value = value } else nil)
		end
end
