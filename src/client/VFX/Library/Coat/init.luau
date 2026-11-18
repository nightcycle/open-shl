--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Transparency = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/Cloak/Transparency")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Coat
-- what a part looked like before it was coated + how many coats it has on
type Look = {
	Material: Enum.Material,
	Color: Color3,
	Count: number,
}
-- Constants
-- Variables
local Looks: { [BasePart]: Look } = {}
-- References
-- Private Functions
-- a part that's coated twice over only gets its own look back once both are off
local function coat(part: BasePart, props: Properties): () -> ()
	local look: Look = Looks[part] or { Material = part.Material, Color = part.Color, Count = 0 }
	Looks[part] = look
	look.Count += 1
	part.Color = props.Color
	-- a few materials are the ground's alone, a part that's handed one keeps its own
	pcall(function()
		part.Material = props.Material
	end)
	return function()
		look.Count -= 1
		if look.Count > 0 then
			return
		end
		Looks[part] = nil
		part.Material = look.Material
		part.Color = look.Color
	end
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Coat, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local releases: { () -> () } = {}
	local function cover(inst: Instance)
		if inst:IsA("BasePart") then
			table.insert(releases, coat(inst, props))
		elseif inst:IsA("Decal") then
			-- a face or a print would give away what's underneath
			table.insert(releases, Transparency.hold(inst, 1))
		end
	end
	for _, v in character:GetDescendants() do
		cover(v)
	end
	-- whatever the avatar puts on or takes out while it's on is covered as well
	local connection = character.DescendantAdded:Connect(cover)
	return function()
		connection:Disconnect()
		for _, release in releases do
			release()
		end
	end
end)
