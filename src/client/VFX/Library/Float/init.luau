--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Float
-- Constants
local FORCE_NAME = "FloatForce"
local ATTACHMENT_NAME = "FloatAttachment"
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Float, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local rootPart = character and character.PrimaryPart
	if not rootPart then
		return function() end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = ATTACHMENT_NAME
	attachment.Parent = rootPart
	-- straight up whichever way the avatar is turned, through the middle of its weight so it isn't tipped over
	local vectorForce = Instance.new("VectorForce")
	vectorForce.Name = FORCE_NAME
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.ApplyAtCenterOfMass = true
	-- what an avatar weighs changes with what it wears + holds, the push is made to fit anew every frame
	local function update()
		vectorForce.Force = Vector3.new(0, props.Share * rootPart.AssemblyMass * Workspace.Gravity, 0)
	end
	update()
	vectorForce.Parent = rootPart
	local connection = RunService.Heartbeat:Connect(update)
	return function()
		connection:Disconnect()
		vectorForce:Destroy()
		attachment:Destroy()
	end
end)
