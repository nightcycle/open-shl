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
type Properties = ClientVFXType.Ragdoll
-- a joint of the body that's let go of
type Joint = {
	Name: string, -- of the motor that holds it + of the pair of attachments it turns at
	Limits: NumberRange?, -- degrees it bends between, the one way a hinge does. without, it swings any way
}
-- Constants
-- what the old place let go of: the shoulders, the elbows + the hips swing any way, a knee bends back + no further
-- than a knee does. it welded the wrists, the ankles, the waist + the neck: here they stay the motors they are
local KNEE_LIMITS = NumberRange.new(-75, 0)
local JOINTS: { Joint } = table.freeze({
	table.freeze({ Name = "LeftShoulder" }),
	table.freeze({ Name = "RightShoulder" }),
	table.freeze({ Name = "LeftElbow" }),
	table.freeze({ Name = "RightElbow" }),
	table.freeze({ Name = "LeftHip" }),
	table.freeze({ Name = "RightHip" }),
	table.freeze({ Name = "LeftKnee", Limits = KNEE_LIMITS }),
	table.freeze({ Name = "RightKnee", Limits = KNEE_LIMITS }),
})
-- what the two attachments of a joint are called after it, one in each of the parts it joins
local ATTACHMENT_SUFFIX = "RigAttachment"
local CONSTRAINT_PREFIX = "Ragdoll"
local NO_COLLISION_SUFFIX = "NoCollision"
-- Variables
-- References
-- Private Functions
local function getAttachment(part: BasePart, joint: Joint): Attachment?
	local inst = part:FindFirstChild(`{joint.Name}{ATTACHMENT_SUFFIX}`)
	return if inst and inst:IsA("Attachment") then inst else nil
end
-- Class
-- nothing of it is anybody's to be told: every client lets the body go on its own screen, where it lies is its
-- owner's to say the way it is of any body. a joint this body doesn't have, or has no attachments for, stays held
return ClientVFX.state(ClientVFXDefinition.Ragdoll, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local motors: { Motor6D } = {}
	local instances: { Instance } = {}
	for _, joint in JOINTS do
		local motor = character:FindFirstChild(joint.Name, true)
		if not motor or not motor:IsA("Motor6D") or not motor.Enabled then
			continue
		end
		local part0, part1 = motor.Part0, motor.Part1
		if not part0 or not part1 then
			continue
		end
		local attachment0, attachment1 = getAttachment(part0, joint), getAttachment(part1, joint)
		if not attachment0 or not attachment1 then
			continue
		end
		local constraint: Constraint
		local limits = joint.Limits
		if limits then
			local hinge = Instance.new("HingeConstraint")
			hinge.LimitsEnabled = true
			hinge.LowerAngle = limits.Min
			hinge.UpperAngle = limits.Max
			constraint = hinge
		else
			constraint = Instance.new("BallSocketConstraint")
		end
		constraint.Name = `{CONSTRAINT_PREFIX}{joint.Name}`
		constraint.Attachment0 = attachment0
		constraint.Attachment1 = attachment1
		constraint.Parent = part1
		-- two parts a motor holds never run into each other, hung from one another they would
		local noCollision = Instance.new("NoCollisionConstraint")
		noCollision.Name = `{CONSTRAINT_PREFIX}{joint.Name}{NO_COLLISION_SUFFIX}`
		noCollision.Part0 = part0
		noCollision.Part1 = part1
		noCollision.Parent = part1
		motor.Enabled = false
		table.insert(motors, motor)
		table.insert(instances, constraint)
		table.insert(instances, noCollision)
	end
	-- no two bodies come down the same way. it only moves the body on the screen of whoever it belongs to
	local rootPart = character.PrimaryPart
	if rootPart and props.Shove > 0 and #motors > 0 then
		local random = Random.new()
		local shove = props.Shove
		rootPart.AssemblyLinearVelocity = Vector3.new(
			random:NextNumber(-shove, shove),
			random:NextNumber(-shove, shove),
			random:NextNumber(-shove, shove)
		)
	end
	return function()
		for _, motor in motors do
			motor.Enabled = true
		end
		for _, inst in instances do
			inst:Destroy()
		end
	end
end)
