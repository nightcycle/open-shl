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
-- References
-- Private Functions
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
	local part = Instance.new("Part")
	part.Name = BEAM_NAME
	part.Material = props.Material or Enum.Material.Neon
	part.Color = props.Color
	part.Transparency = transparency
	part.Size = Vector3.new(props.Thickness, props.Thickness, length)
	part.CFrame = CFrame.lookAt(props.Origin, props.Position) * CFrame.new(0, 0, -length / 2)
	part.Anchored = true
	part.CastShadow = false
	-- it's only there to be looked at: it can't push, be stood on or get in the way of a ray
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = Workspace

	local entry: Entry
	local connection: RBXScriptConnection
	local function remove()
		connection:Disconnect()
		part:Destroy()
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
			part.Transparency = transparency + (1 - transparency) * faded
		end
	end)
	if key then
		local entries = EntriesByOwner[owner] or {}
		EntriesByOwner[owner] = entries
		entries[key] = entry
	end
end)
