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
type Properties = ClientVFXType.Wake
-- Constants
local WAKE_NAME = "Wake"
local END_NAME = "WakeEnd"
-- how see-through a ribbon is where it's drawn out, in hundredths. each one is a little different from the next
local MIN_TRANSPARENCY = 85
local MAX_TRANSPARENCY = 95
-- Variables
local Rng = Random.new()
-- References
-- Private Functions
local function newEnd(position: Vector3, part: BasePart): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = END_NAME
	attachment.Position = position
	attachment.Parent = part
	return attachment
end

-- a ribbon between two spots of a part, both a way behind its middle
local function newRibbon(part: BasePart, from: Vector3, to: Vector3, color: Color3, lifetime: number): { Instance }
	local fromEnd = newEnd(from, part)
	local toEnd = newEnd(to, part)
	local trail = Instance.new("Trail")
	trail.Name = WAKE_NAME
	trail.Attachment0 = fromEnd
	trail.Attachment1 = toEnd
	trail.Lifetime = lifetime
	trail.Transparency = NumberSequence.new(Rng:NextInteger(MIN_TRANSPARENCY, MAX_TRANSPARENCY) / 100, 1)
	trail.Color = ColorSequence.new(color)
	-- it's seen at its full width from wherever it's looked at
	trail.FaceCamera = true
	trail.Parent = part
	return { trail, fromEnd, toEnd }
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Wake, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local insts: { Instance } = {}
	-- the body itself: what it wears + holds sits further in + leaves nothing behind
	for _, part in character:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		local size = part.Size
		local depth = props.Depth
		local tall = newRibbon(
			part,
			Vector3.new(0, size.Y / 2, depth),
			Vector3.new(0, -size.Y / 2, depth),
			props.Color or part.Color,
			props.Lifetime
		)
		local wide = newRibbon(
			part,
			Vector3.new(size.X / 2, 0, depth),
			Vector3.new(-size.X / 2, 0, depth),
			props.SecondaryColor or part.Color,
			props.Lifetime
		)
		table.move(tall, 1, #tall, #insts + 1, insts)
		table.move(wide, 1, #wide, #insts + 1, insts)
	end
	return function()
		for _, inst in insts do
			inst:Destroy()
		end
	end
end)
