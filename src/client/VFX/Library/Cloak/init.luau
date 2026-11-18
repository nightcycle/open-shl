--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Transparency = require("@self/Transparency")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Cloak
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Cloak, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local releases: { () -> () } = {}
	local function hide(inst: Instance)
		if inst:IsA("BasePart") or inst:IsA("Decal") then
			table.insert(releases, Transparency.hold(inst, props.Transparency))
		end
	end
	for _, v in character:GetDescendants() do
		hide(v)
	end
	-- whatever the avatar puts on or takes out while it's on goes the same way
	local connection = character.DescendantAdded:Connect(hide)
	return function()
		connection:Disconnect()
		for _, release in releases do
			release()
		end
	end
end)
