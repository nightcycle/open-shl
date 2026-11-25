--!strict
-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Beam
-- a beam with a key that's still there
type Entry = {
	StartTime: number,
	Remove: () -> (),
}
-- Constants
local BEAM_NAME = "Beam"
-- studs a beam has to be long to be shown at all, there's no pointing it at what's right where it starts
local MIN_LENGTH = 0.05
-- what the keyed beams of the world itself are filed under, it has no character to file them by
local WORLD = table.freeze({})
-- Variables
-- the beams with a key that are still there, by whose they are
local EntriesByOwner: { [any]: { [string]: Entry } } = {}
-- every viewer rolls the turns of a jagged line for themselves
local Rng = Random.new()
-- References
-- Private Functions
-- the spots a line runs through on its way: its two ends, with a turn every so often in between for one that's jagged.
-- a turn is off the straight line by a whole number of studs on every axis, never by none
local function getJoints(props: Properties, length: number): { Vector3 }
	local joints = { props.Origin }
	local jitter = props.Jitter
	if jitter then
		local spread = math.floor(jitter.Spread)
		local count = math.ceil(length / jitter.Step)
		for index = 1, count - 1 do
			local turn = Vector3.new(
				Rng:NextInteger(1, spread) * (if Rng:NextNumber() < 0.5 then -1 else 1),
				Rng:NextInteger(1, spread) * (if Rng:NextNumber() < 0.5 then -1 else 1),
				Rng:NextInteger(1, spread) * (if Rng:NextNumber() < 0.5 then -1 else 1)
			)
			table.insert(joints, props.Origin:Lerp(props.Position, index / count) + turn)
		end
	end
	table.insert(joints, props.Position)
	return joints
end
-- Class
return ClientVFX.event(ClientVFXDefinition.Beam, function(props: Properties, scope: ClientScope)
	local owner: any = scope.Character or WORLD
	local key = props.Key
	local startTime = os.clock()
	local previous = if key and EntriesByOwner[owner] then EntriesByOwner[owner][key] else nil
	if previous then
		-- it's the same beam put right: it's gone when the one it takes the place of would have been
		startTime = previous.StartTime
		previous.Remove()
	end
	local length = (props.Position - props.Origin).Magnitude
	if length < MIN_LENGTH or os.clock() - startTime >= props.Lifetime then
		return
	end
	local transparency = props.Transparency or 0
	-- a straight one is a single stretch from end to end
	local parts: { Part } = {}
	local joints = getJoints(props, length)
	for index = 1, #joints - 1 do
		local from = joints[index]
		local to = joints[index + 1]
		local stretch = (to - from).Magnitude
		local part = Instance.new("Part")
		part.Name = BEAM_NAME
		part.Material = props.Material or Enum.Material.Neon
		part.Color = props.Color
		part.Transparency = transparency
		part.Size = Vector3.new(props.Thickness, props.Thickness, stretch)
		part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -stretch / 2)
		part.Anchored = true
		part.CastShadow = false
		-- it's only there to be looked at: it can't push, be stood on or get in the way of a ray
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Parent = Workspace
		table.insert(parts, part)
	end

	local entry: Entry
	local connection: RBXScriptConnection
	local function remove()
		connection:Disconnect()
		for _, part in parts do
			part:Destroy()
		end
		local entries = EntriesByOwner[owner]
		if key and entries and entries[key] == entry then
			entries[key] = nil
			if next(entries) == nil then
				EntriesByOwner[owner] = nil
			end
		end
	end
	entry = table.freeze({
		StartTime = startTime,
		Remove = remove,
	})
	connection = RunService.Heartbeat:Connect(function()
		local alpha = (os.clock() - startTime) / props.Lifetime
		if alpha >= 1 then
			remove()
			return
		end
		if props.IsFading then
			local faded = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			for _, part in parts do
				part.Transparency = transparency + (1 - transparency) * faded
			end
		end
	end)
	if key then
		local entries = EntriesByOwner[owner] or {}
		EntriesByOwner[owner] = entries
		entries[key] = entry
	end
end)
