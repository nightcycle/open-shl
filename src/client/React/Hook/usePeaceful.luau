--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- stub: the remote the server takes the pick by isn't there yet, so it's told nothing + the avatar stays what it was
local function setPeaceful(isPeaceful: boolean)
	warn(`the server can't be told to {if isPeaceful then "sit fights out" else "fight"} yet, it has no remote for it`)
end
-- Class
-- if the player sits fights out, by what the server wrote onto their avatar, + the way to ask for the other. what's
-- asked for is never shown before the server made it so: it comes back on the avatar
return function(): (boolean, (isPeaceful: boolean) -> ())
	return useCharacterAttribute(AttributeDefinition.IsPeaceful) == true, setPeaceful
end
