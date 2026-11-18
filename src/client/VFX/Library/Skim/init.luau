--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Skim
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the part only turns solid on the machine the effect runs on, which is the one that moves the avatar: nobody else
-- gets to stand on it
return ClientVFX.state(ClientVFXDefinition.Skim, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return function() end
	end
	local part = props.Part
	local canCollide = part.CanCollide
	local function update()
		part.CanCollide = humanoid.MoveDirection.Magnitude > 0
	end
	update()
	local connection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(update)
	return function()
		connection:Disconnect()
		part.CanCollide = canCollide
	end
end)
