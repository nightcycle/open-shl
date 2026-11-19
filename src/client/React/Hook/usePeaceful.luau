--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- the server is only told what was picked: what it made of it is on the avatar. a pick that changes sides takes down
-- an avatar that's been in the world, the one that comes back is the first to wear it
local function setPeaceful(isPeaceful: boolean)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	NetworkService:Fire(RemoteDefinition.SetPeaceful, isPeaceful)
end
-- Class
-- if the player sits fights out, by what the server wrote onto their avatar, + the way to ask for the other. what's
-- asked for is never shown before the server made it so: it comes back on the avatar
return function(): (boolean, (isPeaceful: boolean) -> ())
	return useCharacterAttribute(AttributeDefinition.IsPeaceful) == true, setPeaceful
end
