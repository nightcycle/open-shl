--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local ResidenceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Residence")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
-- what every game's residence says of itself, what it's built from on top of that is the game's own
export type State = ResidenceDefinition.State
type ResidenceState = State

local Types = {}

-- a way into one residence, whoever lives there
export type Door = {
	ResidenceId: string, -- what names a residence is the game's to say
	Doorstep: CFrame, -- where the avatar is put as it leaves, its back to the door
	Anchor: CFrame, -- where the residence is built
	Parent: Instance, -- what the residence is put under
}
Types.Door = Type.strictInterface({
	ResidenceId = ResidenceDefinition.ResidenceId,
	Doorstep = Type.CFrame,
	Anchor = Type.CFrame,
	Parent = Type.instanceIsA("Instance"),
})

-- what's built behind a door, as far as the residence service has to know it. whatever else there is to one is the
-- game's own
export type Interior =
	{
		IsAlive: true,
		State: ResidenceState,
		Entrance: BasePart, -- where the avatar lands as it comes in
		Exit: BasePart, -- stepped on it leads back out
		SetState: (self: any, state: ResidenceState) -> (),
		Destroy: (self: any) -> (),
	}
	| {
		IsAlive: false | nil,
	}
-- of one that's alive
Types.Interior = Type.interface({
	IsAlive = Type.literal(true),
	State = ResidenceDefinition.State,
	Entrance = Type.instanceIsA("BasePart"),
	Exit = Type.instanceIsA("BasePart"),
	SetState = Type.callback,
	Destroy = Type.callback,
})

-- what the residence service lets the part of it that's one game's own ask of it
export type Walk = {
	-- a trigger only runs for the living avatar of this client
	Bind: (trigger: BasePart, onTouched: () -> ()) -> RBXScriptConnection,
	-- without it a trigger would send the avatar right back to where it just came from
	GetIfReady: () -> boolean,
	-- puts the avatar on an exit, its back to the trigger next to it that leads back. false if there's none to put
	Land: (exit: BasePart, behind: BasePart) -> boolean,
}
Types.Walk = Type.strictInterface({
	Bind = Type.callback,
	GetIfReady = Type.callback,
	Land = Type.callback,
})

-- the part of the residences that's one game's own: where the ways into them are in its map, what's behind a door +
-- what the avatar gets around by in there. the residence service does what every game with residences shares: the
-- door the server opens or keeps shut, the way back out + the changes it's told of
export type Rule = {
	-- binds every way into a residence, `enter` takes the door the avatar stands at. what it hands back unbinds them
	Bind: (walk: Walk, enter: (door: Door) -> ()) -> () -> (),
	-- if the door of somebody else is known to stay shut before the server is asked. it's never about the player's own
	GetIfShut: (owner: Player) -> boolean,
	-- what's built at the anchor of a door the server opened
	NewInterior: (anchor: CFrame, state: ResidenceState, parent: Instance) -> Result<Interior, string>,
	-- the box an avatar that's inside stays in
	GetBounds: (interior: Interior) -> (CFrame, Vector3),
	-- where the avatar stands as it comes in. a game that leaves it out has it on the entrance, its back to the exit
	GetLanding: ((interior: Interior) -> CFrame)?,
	-- runs once the avatar is inside. what it hands back runs as the avatar is out again
	Entered: (interior: Interior, isOwn: boolean, walk: Walk) -> (() -> ())?,
}
Types.Rule = Type.strictInterface({
	Bind = Type.callback,
	GetIfShut = Type.callback,
	NewInterior = Type.callback,
	GetBounds = Type.callback,
	GetLanding = Type.optional(Type.callback),
	Entered = Type.callback,
})

return Types
