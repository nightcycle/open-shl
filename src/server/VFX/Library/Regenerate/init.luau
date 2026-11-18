--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Amount: number, -- health given right away + again with every interval that's paid for
	Cost: number, -- energy every one after the first takes
	Interval: number,
}
-- Constants
local isProperties = Type.strictInterface({
	Amount = Type.numberMin(0),
	Cost = Type.numberMin(0),
	Interval = Type.numberPositive,
})
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
-- Class
-- gives the character the effect belongs to health back for as long as it's on. the first of it comes right away +
-- is on whoever started the effect, every one after that is paid for with the energy of the character. it's over
-- once they're whole or can't pay
return ServerVFX.newState("Regenerate", isProperties, function(props: Properties, scope: ServerScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local thread = task.spawn(function()
		while true do
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			-- nothing brings back who's already down
			if
				not humanoid
				or humanoid.Health <= 0
				or AttributeDefinition.get(character, AttributeDefinition.IsDead)
			then
				break
			end
			local health =
				math.min(MAX_HEALTH, AttributeDefinition.get(character, AttributeDefinition.Health) + props.Amount)
			AttributeDefinition.set(character, AttributeDefinition.Health, health)
			if health >= MAX_HEALTH then
				break
			end
			task.wait(props.Interval)
			if not scope.fire(SpendEnergy, { Amount = props.Cost, IsQuiet = true }) then
				break
			end
		end
	end)
	return function()
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end)
