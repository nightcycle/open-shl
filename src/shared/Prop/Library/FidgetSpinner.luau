--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
type Memory = AbilityType.Memory
-- Constants
local ID = "fidget-spinner"
-- degrees a second one flick adds, + the most it ever turns at
local FLICK_SPEED = 1500
local MAX_SPEED = 4000
-- degrees a second it loses every second: one flick turns for half a minute, a full one for 80 s
local DECAY = 50
-- it turns about the thin side of itself
local AXIS = Vector3.zAxis
-- the arm out in front, what a hand that holds anything used to do by itself
local HOLD_ANIMATION: AnimationKey = "GunHolding"
local LOOK: ClientVFXType.Prop = table.freeze({
	Limb = "RightHand",
	Size = Vector3.new(0.5, 0.5, 0.2),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-0.011, -0.169, -0.015, 1, 0, 0, 0, -1, 0, 0, 0, -1),
	-- the mesh is drawn by its texture, the part under it never shows
	Color = Color3.new(1, 1, 1),
	Mesh = "FidgetSpinner" :: "FidgetSpinner",
	MeshScale = Vector3.one * 0.15,
	MeshOffset = Vector3.new(-0.01, 0.14, 0),
})
-- Variables
-- References
-- Private Functions
-- how fast it turns right now, from what was written down at the last flick
local function getSpeed(memory: Memory, now: number): number
	local speed, at = memory.Speed, memory.At
	if type(speed) ~= "number" or type(at) ~= "number" then
		return 0
	end
	return math.max(0, speed - DECAY * math.max(0, now - at))
end
-- Class
local definitionRes = PropDefinition.get(ID)
assert(definitionRes.IsOk, `no prop is registered as "{ID}"`)

-- a spinner off the shelf downstairs in the apartments: a click flicks it, it turns on for a long while after + a
-- flick while it turns adds to it. what it turns at is kept as a speed + the time it had it, in what's emptied as
-- it's put away: put away, it's still. the old one had the server turn the grip every frame
return table.freeze({
	Prop = definitionRes.Value,
	HoldAnimation = HOLD_ANIMATION,
	-- one flick: what's left of the last ones + this one. now is on the clock of the server, every screen turns it
	-- from the same moment
	flick = function(memory: Memory, now: number)
		memory.Speed = math.min(MAX_SPEED, getSpeed(memory, now) + FLICK_SPEED)
		memory.At = now
	end,
	-- what's in the hand: still until it's flicked, turning from then on
	getLook = function(memory: Memory): ClientVFXType.Prop
		local speed, at = memory.Speed, memory.At
		if type(speed) ~= "number" or type(at) ~= "number" then
			return LOOK
		end
		local look = table.clone(LOOK)
		look.Spin = table.freeze({ Axis = AXIS, Speed = speed, Decay = DECAY, At = at })
		return table.freeze(look)
	end,
})
