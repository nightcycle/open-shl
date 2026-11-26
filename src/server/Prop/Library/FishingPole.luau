--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FishingPole = require("@game/ReplicatedStorage/Shared/Prop/Library/FishingPole")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type MeshKey = VFXAssetDefinition.MeshKey
type ServerContext = PropType.ServerContext
type Cleanup = VFXType.Cleanup
type Handle = VFXType.Handle
type Replication = VFXType.Replication
-- where the line is for as long as the pole is out. it's emptied with everything else as the pole is put away
type State = {
	Position: Vector3?, -- where its far end lies while it's cast, nil while it hangs off the pole
	Length: number, -- studs of it that are out
	Fish: MeshKey?, -- what's on the hook in place of the sinker
	Line: Handle?, -- what everybody is shown of it right now
	FishThread: thread?, -- waits to take a fish that was reeled in off the hook
}
-- Constants
-- the player's own half shows them the pole right away, the server tells everybody else
local SEEN: Replication = table.freeze({ Audience = "Others" :: "Others" })
-- the line is the server's to say for everybody, whoever holds the pole included: only a cast it let through is
-- ever seen, where its ray ended
local EVERYBODY: Replication = table.freeze({ Audience = "All" :: "All" })
local STATE = "Line"
-- studs the ray goes past what was pointed at: that spot lies on the face of something, which is hit rather than
-- just missed
local OVERSHOOT = 1
-- Variables
local random = Random.new()
-- References
-- Private Functions
local function getState(context: ServerContext): State
	local memory = context.Memory
	local state = memory[STATE] :: State?
	if not state then
		local newState: State = { Length = FishingPole.RestLength }
		memory[STATE] = newState
		return newState
	end
	return state
end

-- where the line is tied as the server has the avatar: about the far end of the pole
local function getTip(character: Model): Vector3
	local limb = character:FindFirstChild(FishingPole.Pole.Limb)
	if limb and limb:IsA("BasePart") then
		return limb.CFrame * FishingPole.Tip
	end
	return character:GetPivot().Position
end

-- the line as it is now, in place of however everybody was shown it
local function show(context: ServerContext)
	local state = getState(context)
	if state.Line then
		state.Line.Stop(nil)
	end
	state.Line = context.VFX.startClient(
		ClientVFXDefinition.Line,
		FishingPole.getLine(state.Position, state.Length, state.Fish),
		nil,
		EVERYBODY
	)
end

local function getPole(): ClientVFXType.Prop
	return FishingPole.Pole
end

-- it hangs off the pole from the moment that's out
local function hold(context: ServerContext): Cleanup
	show(context)
	return function()
		local state = getState(context)
		if state.FishThread then
			task.cancel(state.FishThread)
		end
		if state.Line then
			state.Line.Stop(nil)
		end
	end
end

-- reeling in asks nothing of where the click pointed. a cast has to point somewhere the avatar can reach: that the
-- spot is a spot at all is the remote's to check, the old pole put its sinker wherever the client said
local function getIfAllowed(context: ServerContext): boolean
	if getState(context).Position then
		return true
	end
	local aim = context.Aim
	return aim ~= nil and (aim.Position - context.Character:GetPivot().Position).Magnitude <= FishingPole.Reach
end

local function cast(context: ServerContext, state: State, target: Vector3)
	local origin = getTip(context.Character)
	local span = target - origin
	local position = target
	-- a cast right after a catch starts over with the sinker
	state.Fish = nil
	if span.Magnitude > 0 then
		-- one ray from the pole to the spot, through the world as the server has it: the line ends at the first
		-- thing in its way, + if that's water something bites
		local sight = context.VFX.fire(Hitscan, {
			Origin = origin,
			Direction = span,
			Range = span.Magnitude + OVERSHOOT,
		})
		if sight and sight.Instance then
			position = sight.Position
			if sight.Instance:HasTag(MapDefinition.Water.Name) then
				state.Fish = FishingPole.Fish[random:NextInteger(1, #FishingPole.Fish)]
			end
		end
	end
	state.Position = position
	state.Length = math.max(FishingPole.RestLength, (position - origin).Magnitude * FishingPole.Slack)
end

-- what bit comes in on the hook + is the sinker again a moment later
local function reel(context: ServerContext, state: State)
	state.Position = nil
	state.Length = FishingPole.RestLength
	if not state.Fish then
		return
	end
	state.FishThread = task.delay(FishingPole.FishDuration, function()
		state.FishThread = nil
		state.Fish = nil
		show(context)
	end)
end

-- a click casts, the next reels in: which it is depends on where the line is, not on the click
local function onUsed(context: ServerContext)
	local state = getState(context)
	if state.FishThread then
		task.cancel(state.FishThread)
		state.FishThread = nil
	end
	local aim = context.Aim
	if state.Position then
		reel(context, state)
	elseif aim then
		cast(context, state, aim.Position)
	end
	show(context)
end
-- Class
return PropBuilder.newServer(FishingPole.Prop)
	:RunClient(PropMoment.Hold, ClientVFXDefinition.Prop, getPole, SEEN)
	:While(PropMoment.Hold, hold)
	:Guard(getIfAllowed)
	:On(PropMoment.Use, onUsed)
	:Build()
