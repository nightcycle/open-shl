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
type Properties = ClientVFXType.Warp
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.Warp, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if character then
		character:PivotTo(
			if props.IsHeadingKept then character:GetPivot().Rotation + props.Position else CFrame.new(props.Position)
		)
	end
end)
