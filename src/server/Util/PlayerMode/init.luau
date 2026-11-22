--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the server's side of who fights where that's each player's own pick: whether an avatar sat fights out is the
-- server's to write, a client only reads it + asks for the other
local Util = {}

-- an avatar comes in by what its player picked + stays that for as long as it's in the world
function Util.apply(character: Model, isPeaceful: boolean)
	AttributeDefinition.set(character, AttributeDefinition.IsPeaceful, isPeaceful)
end

-- what a new pick comes to for the avatar that's out. nobody changes sides on a body that's been in the world: it's
-- taken down as it is + the one that comes back is the first to play by the pick, or picking would be the way out
-- of a fight + the way to hit from where nothing hits back. the body the old game took down for it was one its
-- player had long left, so nobody ever went down there. an avatar that's held (it came in behind a menu + wasn't
-- let out of it since) was met by nobody, it takes the pick as it stands
function Util.change(character: Model?, isHeld: boolean, isPeaceful: boolean)
	if not character then
		return
	end
	if isHeld then
		Util.apply(character, isPeaceful)
	elseif TakeDownUtil.getIfAlive(character) then
		TakeDownUtil.takeDown(character)
	end
end

return Util
