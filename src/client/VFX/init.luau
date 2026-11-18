--!strict
-- Services
-- Packages
-- Modules
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type ClientEvent<P> = VFXType.ClientEvent<P>
type ClientState<P> = VFXType.ClientState<P>
type ClientScope = VFXType.ClientScope
type Cleanup = VFXType.Cleanup
type Swap = VFXType.Swap
-- what a client effect does, filed under the handle the server + the clients know it by
export type Implementation = {
	VFX: VFX,
	Run: ((props: any, scope: ClientScope) -> ())?,
	Start: ((props: any, scope: ClientScope, swap: Swap?) -> Cleanup)?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.event = function<P>(vfx: ClientEvent<P>, run: (props: P, scope: ClientScope) -> ()): Implementation
	return table.freeze({
		VFX = vfx :: any,
		Run = run,
	})
end

Module.state = function<P>(
	vfx: ClientState<P>,
	start: (props: P, scope: ClientScope, swap: Swap?) -> Cleanup
): Implementation
	return table.freeze({
		VFX = vfx :: any,
		Start = start,
	})
end

return Module
