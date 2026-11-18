--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Components
-- Hooks
-- Contexts
-- Types
local AppTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Types")
type Registry = AppTypes.Registry
-- Constants
-- which container fills which slot is the game's own. what another game mounts is never required, so whatever its
-- containers wait on doesn't have to be in the place
local REGISTRY: Registry = GameDefinition.pick({
	shl1 = function(): Registry
		error(`shl1 has no registry yet`)
	end,
	shl2 = function(): Registry
		return require("@self/SHL2")
	end,
	shl3 = function(): Registry
		error(`shl3 has no registry yet`)
	end,
})
assert(AppTypes.Registry(REGISTRY))
TableUtil.deepFreeze(REGISTRY)
-- Variables
-- References
-- Private Functions
-- Class
return REGISTRY
