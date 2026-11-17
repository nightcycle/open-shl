--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
-- Types
type Signal<T...> = Signal.Signal<T...>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- get must return the same value until the signal fires
return function<V>(signal: Signal<...any>, get: () -> V): V
	local value, setValue = React.useState(get)
	local getRef = React.useRef(get)
	getRef.current = get
	React.useEffect(function()
		local function update()
			setValue(getRef.current())
		end
		local connection = signal:Connect(update)
		-- the signal may have fired between the render + the effect
		update()
		return function()
			connection:Disconnect()
		end
	end, { signal })
	return value
end
