--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactErrorBoundary = require("@game/ReplicatedStorage/Packages/ReactErrorBoundary")
-- Modules
-- Components
-- Hooks
-- Contexts
-- Types
export type Properties = {
	OnError: (message: string) -> (),
	-- what's inside gets another go once this changes
	ResetKey: any?,
	children: { [string]: React.ReactNode }?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	return e(ReactErrorBoundary.ErrorBoundary, {
		fallbackRender = function(): React.ReactNode
			return nil
		end,
		onError = function(err: unknown)
			props.OnError(tostring(err))
		end,
		resetKeys = { props.ResetKey },
	}, props.children)
end
