--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local IceStorm = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/IceStorm")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
local function getCharacter(inst: Instance): Model?
	local model = inst:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end
-- Class
local bindings = IceStorm.Layout.Bindings
local claim = BurstFactory.claim(IceStorm)
local builder = BurstFactory.new(IceStorm, {
	CastAnimation = "IceSpin",
}):Run(bindings.Surge, ClientVFXDefinition.Spray, function(context: ClientContext): ClientVFXType.Spray
	local spray = table.clone(IceStorm.Spray)
	-- an icicle is still on its way long after the hands stopped letting them go
	spray.OnHit = function(result: RaycastResult)
		local target = getCharacter(result.Instance)
		if target then
			claim(context, target)
		end
	end
	return spray
end)
for _, smoke in IceStorm.Smokes do
	builder = builder:Run(bindings.Surge, ClientVFXDefinition.Smoke, function(): ClientVFXType.Smoke
		return smoke
	end)
end

return builder:Build()
