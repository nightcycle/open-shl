--!strict
-- Services
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Implementation = ClientVFX.Implementation
-- Constants
local IMPLEMENTATIONS: { Implementation } = {
	require("@self/Animation"),
	require("@self/AnimationOnce"),
	require("@self/Bolt"),
	require("@self/EnergyWarning"),
	require("@self/Hover"),
	require("@self/Prop"),
	require("@self/Sound"),
	require("@self/SoundLoop"),
	require("@self/Thrust"),
}
-- Variables
local ImplementationsByName: { [string]: Implementation } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, implementation in IMPLEMENTATIONS do
	local name = implementation.VFX.Name
	assert(ImplementationsByName[name] == nil, `the "{name}" effect is implemented twice`)
	ImplementationsByName[name] = implementation
end
-- an effect the server can ask for + no client can show would only be found out in the middle of a fight
for _, vfx in ClientVFXDefinition.list() do
	assert(ImplementationsByName[vfx.Name], `the "{vfx.Name}" effect isn't implemented`)
end

Module.get = function(vfx: VFXType.VFX): Implementation?
	return ImplementationsByName[vfx.Name]
end

return Module
