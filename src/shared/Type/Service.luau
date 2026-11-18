--!strict
--!native
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

-- one of the services a side starts. only the ones of the game that's built are ever loaded, so what another game's
-- waits on doesn't have to be in the place
export type Entry = {
	Name: string, -- of its module
	IsFeatured: boolean?, -- nil when every game runs it
	Load: () -> ServiceLocker.InitializationInterface, -- yields
}
Types.Entry = Type.strictInterface({
	Name = Type.string,
	IsFeatured = Type.optional(Type.boolean),
	Load = Type.callback,
})

return Types
