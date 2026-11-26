--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local SpawnDefinition = require("@game/ServerScriptService/Server/Definition/Spawn")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
-- Types
-- Constants
-- nil in a game that draws the health of an avatar itself
local HEALTH_DISPLAY_DISTANCE: number? = SpawnDefinition.HEALTH_DISPLAY_DISTANCE
-- Variables
-- References
-- Private Functions
-- Class
-- the server's side of who fights where that's each player's own pick: whether an avatar sat fights out is the
-- server's to write, a client only reads it + asks for the other
local Util = {}

-- an avatar comes in by what its player picked + stays that for as long as it's in the world. whoever sits fights
-- out has no health to lose, so the bar the engine draws over a hurt avatar is off over theirs: the old game had the
-- client of each say so for itself
function Util.apply(character: Model, isPeaceful: boolean)
	AttributeDefinition.set(character, AttributeDefinition.IsPeaceful, isPeaceful)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.HealthDisplayDistance = if isPeaceful then 0 else HEALTH_DISPLAY_DISTANCE or 0
	end
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
