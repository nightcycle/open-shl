--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Target: Model,
	Amount: number,
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Amount = Type.numberMin(0),
})
-- Variables
-- References
-- Private Functions
-- Class
-- a character hurting another one, as far as the mode lets them. true if it landed
return ServerVFX.newEvent("Attack", isProperties, function(props: Properties, scope: ServerScope): boolean
	if not ModeDefinition.getIfPVPEnabled() or props.Target == scope.Character then
		return false
	end
	return scope.fire(Damage, {
		Target = props.Target,
		Amount = props.Amount,
	})
end)
