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
type Properties = ClientVFXType.Streak
-- Constants
local STREAK_NAME = "Streak"
local FROM_NAME = "StreakFrom"
local TO_NAME = "StreakTo"
-- Variables
-- References
-- Private Functions
local function newEnd(name: string, cframe: CFrame, limb: BasePart): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = cframe
	attachment.Parent = limb
	return attachment
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Streak, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limb = character and character:FindFirstChild(props.Limb)
	if not limb or not limb:IsA("BasePart") then
		return function() end
	end
	-- a prop sits off its limb by the inverse of its offset, so do the ends of what it leaves behind
	local space = if props.Offset then props.Offset:Inverse() else CFrame.identity
	local from = newEnd(FROM_NAME, space * CFrame.new(props.From), limb)
	local to = newEnd(TO_NAME, space * CFrame.new(props.To), limb)
	local trail = Instance.new("Trail")
	trail.Name = STREAK_NAME
	trail.Attachment0 = from
	trail.Attachment1 = to
	trail.Lifetime = props.Lifetime
	trail.Transparency = NumberSequence.new(props.Transparency, 1)
	trail.Color = ColorSequence.new(props.Color)
	-- it lies the way the limb sweeps, not the way it's looked at
	trail.FaceCamera = false
	local delay = props.Delay or 0
	trail.Enabled = delay <= 0
	trail.Parent = limb
	local showThread: thread? = nil
	if delay > 0 then
		showThread = task.delay(delay, function()
			showThread = nil
			trail.Enabled = true
		end)
	end
	local function remove()
		trail:Destroy()
		from:Destroy()
		to:Destroy()
	end
	return function()
		-- one that's stopped before it was there never shows
		if showThread then
			task.cancel(showThread)
			remove()
			return
		end
		local linger = props.Linger or 0
		if linger > 0 then
			task.delay(linger, remove)
		else
			remove()
		end
	end
end)
