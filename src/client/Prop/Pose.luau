--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
type ClientContext = PropType.ClientContext
type Cleanup = VFXType.Cleanup
type Handle = VFXType.Handle
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the arm a prop is held out by, for as long as the arm is the prop's to pose: whoever is cuffed keeps the prop in
-- their hand + their arms where the cuffs have them
Module.hold = function(context: ClientContext, animation: AnimationKey): Cleanup
	local character = context.Character
	local handle: Handle? = nil
	local function update()
		local isFree = not AttributeDefinition.get(character, AttributeDefinition.IsHandcuffed)
		if isFree and not handle then
			handle = context.VFX.start(ClientVFXDefinition.Animation, { Animation = animation })
		elseif not isFree and handle then
			handle.Stop(nil)
			handle = nil
		end
	end
	local connection = character:GetAttributeChangedSignal(AttributeDefinition.IsHandcuffed.Name):Connect(update)
	update()
	return function()
		connection:Disconnect()
		if handle then
			handle.Stop(nil)
		end
	end
end

return Module
