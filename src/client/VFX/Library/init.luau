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
	require("@self/Beam"),
	require("@self/Bolt"),
	require("@self/Cloak"),
	require("@self/Coat"),
	require("@self/Cursor"),
	require("@self/EnergyWarning"),
	require("@self/FieldOfView"),
	require("@self/Flame"),
	require("@self/Flare"),
	require("@self/Frost"),
	require("@self/Gauge"),
	require("@self/Hover"),
	require("@self/Lift"),
	require("@self/Notice"),
	require("@self/Plume"),
	require("@self/Prop"),
	require("@self/Reel"),
	require("@self/Ripple"),
	require("@self/Root"),
	require("@self/Rope"),
	require("@self/Scatter"),
	require("@self/ScreenFilter"),
	require("@self/SeeThrough"),
	require("@self/Shaft"),
	require("@self/Skim"),
	require("@self/Smoke"),
	require("@self/Sound"),
	require("@self/SoundLoop"),
	require("@self/Spectate"),
	require("@self/Spray"),
	require("@self/Streak"),
	require("@self/Thrust"),
	require("@self/Tumble"),
	require("@self/Wake"),
	require("@self/WalkSpeed"),
	require("@self/Warp"),
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
