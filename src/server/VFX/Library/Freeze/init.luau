--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Cover = require("@game/ServerScriptService/Server/VFX/Library/Cover")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Target: Model,
	Duration: number, -- seconds they neither walk nor jump
	Block: Cover.Properties?, -- what they're shut in for the while, nothing without
	-- seconds the block is in the way, from when they're held. as long as it takes to go once they're let go without
	BlockDuration: number?,
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Duration = Type.numberPositive,
	Block = Type.optional(Cover.Props),
	BlockDuration = Type.optional(Type.numberPositive),
})
-- Variables
-- how many of them hold each character right now
local Counts: { [Model]: number? } = {}
-- References
-- Private Functions
-- Class
-- a character holding another where it stands, as far as the mode + the rules of the game let them. true if it
-- held. the server only says so: the client that walks the avatar is what keeps it still, the way it's kept in
-- every other place. two that hold the same one don't let go of it until the later is over
return ServerVFX.newEvent("Freeze", isProperties, function(props: Properties, scope: ServerScope): boolean
	local target = props.Target
	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 or AttributeDefinition.get(target, AttributeDefinition.IsDead) then
		return false
	end
	if not CombatDefinition.getIfHostile(scope.Character, target) then
		return false
	end
	Counts[target] = (Counts[target] or 0) + 1
	AttributeDefinition.set(target, AttributeDefinition.IsFrozen, true)
	task.delay(props.Duration, function()
		local count = (Counts[target] or 1) - 1
		Counts[target] = if count > 0 then count else nil
		if count <= 0 then
			AttributeDefinition.set(target, AttributeDefinition.IsFrozen, false)
		end
	end)
	local block = props.Block
	if block then
		-- it starts to go as they're let go of. what's left of its time once nobody sees it, it's still in the way
		local stopDelay = math.min(props.Duration, props.BlockDuration or props.Duration)
		local goDuration = (block.Linger or 0) + math.max(block.FadeDuration or 0, block.GrowDuration or 0)
		local cover = table.clone(block)
		cover.Target = target
		cover.GoneDuration = math.max((props.BlockDuration or 0) - stopDelay - goDuration, 0)
		local handle = scope.start(Cover, cover)
		task.delay(stopDelay, handle.Stop)
	end
	return true
end)
