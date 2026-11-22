--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the server's way of having an avatar go down that no hit took down: a pick of its player that only the next avatar
-- plays by
local Util = {}

function Util.getIfAlive(character: Model): boolean
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	return humanoid ~= nil
		and humanoid.Health > 0
		and not AttributeDefinition.get(character, AttributeDefinition.IsDead)
end

-- the avatar goes down the way one does whose last health a hit took, whatever it had left + whatever kept it from
-- harm: this is no hit, nothing stands in its way
function Util.takeDown(character: Model)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	AttributeDefinition.set(character, AttributeDefinition.Health, 0)
	AttributeDefinition.set(character, AttributeDefinition.IsDead, true)
	FightingUtil.clear(character)
	humanoid.Health = 0
end

return Util
