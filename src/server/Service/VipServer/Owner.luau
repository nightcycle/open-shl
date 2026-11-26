--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- who a server belongs to, by the two things the engine says of it. kept apart from the service so it's asked about
-- servers no test could ever be run on
local Util = {}

-- somebody bought this server off the engine. one the game reserved for itself has an id + nobody who owns it, a
-- public one + a session of studio have neither
function Util.getIfOwned(privateServerId: string, ownerId: number): boolean
	return privateServerId ~= "" and ownerId > 0
end

-- an owner without a server isn't one: the id of a player is never 0 or below, which is what the engine says for
-- nobody
function Util.getIfOwner(privateServerId: string, ownerId: number, userId: number): boolean
	return Util.getIfOwned(privateServerId, ownerId) and userId == ownerId
end

return Util
