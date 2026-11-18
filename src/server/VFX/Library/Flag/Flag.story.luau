--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local Flag = require("@game/ServerScriptService/Server/VFX/Library/Flag")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
type Attribute = AttributeDefinition.Attribute<boolean>
-- Constants
local ATTRIBUTES: { [string]: Attribute } = {
	IsInvulnerable = AttributeDefinition.IsInvulnerable,
	IsNameHidden = AttributeDefinition.IsNameHidden,
}
-- Variables
-- References
-- Private Functions
-- Class
-- the attribute is on the user for as long as the effect is. a hit is tried on them right away, which only an
-- invulnerable one shrugs off
return VFXStory.newStateStory({
	Attribute = UILabs.Choose({ "IsInvulnerable", "IsNameHidden" }),
	Damage = UILabs.Slider(14, 0, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local user = stage.User
	local attribute = ATTRIBUTES[controls.Attribute]
	AttributeDefinition.setDefaults(user, "Character")
	local handle = stage.ServerScope.start(Flag, { Attribute = attribute })
	local isHit = stage.ServerScope.fire(Damage, { Target = user, Amount = controls.Damage })
	print(`{attribute.Name}: {AttributeDefinition.get(user, attribute)}, hit: {isHit}`)
	return function()
		handle.Stop()
		print(`{attribute.Name}: {AttributeDefinition.get(user, attribute)}`)
	end
end)
