--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Target: Model,
	Amount: number, -- what every tick takes off before the rule of the game
	Count: number,
	Interval: number, -- seconds between two ticks, the first is at once
	FlameDuration: number, -- seconds they're seen on fire
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Amount = Type.numberMin(0),
	Count = Type.intersection(Type.integer, Type.numberPositive),
	Interval = Type.numberPositive,
	FlameDuration = Type.numberMin(0),
})
local FLAME_NAME = "BurnFlame"
-- Variables
-- References
-- Private Functions
-- Class
-- a character setting another alight, as far as the mode + the rules of the game let them: it takes health off
-- them tick by tick + sends them nowhere. true if it caught. it's on them from then on: nothing that's raised
-- between the two after puts it out, it's over with the first tick that doesn't land
return ServerVFX.newEvent("Burn", isProperties, function(props: Properties, scope: ServerScope): boolean
	local target = props.Target
	if not CombatDefinition.getIfHostile(scope.Character, target) then
		return false
	end
	local function tick(): boolean
		return scope.fire(Attack, { Target = target, Amount = props.Amount, IsStill = true })
	end
	if not tick() then
		return false
	end
	-- the server's, so everybody sees it. it's on the middle of them: where they were hit isn't the server's to know
	local rootPart = target.PrimaryPart
	if rootPart and props.FlameDuration > 0 then
		local flame = Instance.new("Fire")
		flame.Name = FLAME_NAME
		flame.Parent = rootPart
		task.delay(props.FlameDuration, function()
			flame:Destroy()
		end)
	end
	task.spawn(function()
		for _ = 2, props.Count do
			task.wait(props.Interval)
			if not tick() then
				break
			end
		end
	end)
	return true
end)
