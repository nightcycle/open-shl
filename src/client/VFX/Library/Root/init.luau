--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local WalkLock = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/WalkLock")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Root
-- Constants
-- Variables
-- how many of them hold each humanoid: two moves can hold an avatar at once, it only jumps again once the last of
-- them lets go
local HoldCounts: { [Humanoid]: number? } = {}
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Root, function(_: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return function() end
	end
	local walkLock = WalkLock.new(humanoid)
	HoldCounts[humanoid] = (HoldCounts[humanoid] or 0) + 1
	-- turned off rather than set to nothing: how high a jump goes stays whatever else made it
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	return function()
		if walkLock.IsAlive then
			walkLock:Destroy()
		end
		local count = (HoldCounts[humanoid] or 1) - 1
		HoldCounts[humanoid] = if count > 0 then count else nil
		if count <= 0 then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end
end)
