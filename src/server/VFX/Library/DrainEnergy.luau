--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Amount: number, -- taken right away + again with every interval
	Interval: number,
	OnEmpty: () -> (), -- there wasn't enough left to take, nothing is taken from here on
}
-- Constants
local isProperties = Type.strictInterface({
	Amount = Type.numberMin(0),
	Interval = Type.numberPositive,
	OnEmpty = Type.callback,
})
-- Variables
-- References
-- Private Functions
-- Class
-- keeps taking energy off the character the effect belongs to for as long as it's on
return ServerVFX.newState("DrainEnergy", isProperties, function(props: Properties, scope: ServerScope)
	local thread = task.spawn(function()
		while scope.fire(SpendEnergy, { Amount = props.Amount }) do
			task.wait(props.Interval)
		end
		props.OnEmpty()
	end)
	return function()
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end)
