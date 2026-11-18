--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Validator = VFXType.Validator
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Reach = VFXType.Reach
type ClientScope = VFXType.ClientScope
type ServerScope = VFXType.ServerScope

local Types = {}

local isFinite = function(value: unknown): (boolean, string?)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return false, `finite number expected, got {value}`
	end
	return true
end
local isFiniteVector3 = function(value: unknown): (boolean, string?)
	if typeof(value) ~= "Vector3" then
		return false, `Vector3 expected, got {typeof(value)}`
	end
	local vector = value :: Vector3
	return isFinite(vector.X + vector.Y + vector.Z)
end
Types.FiniteVector3 = isFiniteVector3

-- where a player looks from + what they point at
export type Aim = {
	Origin: Vector3,
	Position: Vector3,
}
Types.Aim = Type.strictInterface({
	Origin = isFiniteVector3,
	Position = isFiniteVector3,
})

-- a boolean of a player a binding can hang on. the Key is what it's stored + sent under
export type Condition =
	{
		-- held down, any one of them is enough
		Type: "Input",
		Key: string,
		UserInputTypes: { Enum.UserInputType },
		KeyCodes: { Enum.KeyCode },
	}
	| {
		-- the tool of an ability is in the hand
		Type: "Equipped",
		Key: string,
		AbilityId: string,
	}
	| {
		-- the machine of an ability is in a state: how one ability takes what another is up to into account
		Type: "AbilityState",
		Key: string,
		AbilityId: string,
		StateId: string,
	}
	| {
		Type: "HumanoidState",
		Key: string,
		HumanoidStateType: Enum.HumanoidStateType,
	}
	| {
		-- set per player by whatever game system owns the name
		Type: "Custom",
		Key: string,
		Name: string,
	}
	| {
		-- the machine is in a state the binding belongs to
		Type: "Current",
		Key: string,
	}
	| {
		-- the machine has been in the state it's in for this long
		Type: "Elapsed",
		Key: string,
		Duration: number,
	}

export type Requirement = {
	Condition: Condition,
	IsActive: boolean,
}
-- fires once as its condition starts or stops, as long as everything it requires holds
export type EventTrigger = {
	Kind: "Event",
	Condition: Condition,
	IsStarted: boolean,
	Requirements: { Requirement },
}
-- on for as long as everything it requires holds
export type StateTrigger = {
	Kind: "State",
	Requirements: { Requirement },
}

-- who works out that an event binding fires. either side on its own for what both can see (an input, time, a tool),
-- one of them for what only it can know: that side tells the other
export type Authority = "Both" | "Client" | "Server"

-- a binding is what an ability hangs its effects on: a name, when it's set off + where it leaves the machine. it's
-- unique to its ability + shared by the two halves, each of which hooks its own effects onto it
export type EventBinding = {
	Kind: "Event",
	Name: string,
	StateIds: { string }, -- the states of the machine it's live in
	Trigger: EventTrigger?,
	Authority: Authority,
	Payload: Validator,
	To: string?, -- the state the machine is in afterwards
	Duration: number?, -- seconds the effects of the two states get to ease into each other
}
-- an event with no trigger: it fires when the half named by its authority raises it, carrying what that half knows.
-- _Signature is never set, it only carries the type of the payload
export type ClientSignal<T> = {
	Kind: "Event",
	Name: string,
	StateIds: { string },
	Authority: "Client",
	Payload: Validator,
	To: string?,
	Duration: number?,
	_Signature: (T) -> (),
}
export type ServerSignal<T> = {
	Kind: "Event",
	Name: string,
	StateIds: { string },
	Authority: "Server",
	Payload: Validator,
	To: string?,
	Duration: number?,
	_Signature: (T) -> (),
}
export type StateBinding = {
	Kind: "State",
	Name: string,
	StateIds: { string },
	Trigger: StateTrigger,
}
export type Binding = EventBinding | StateBinding

-- every binding of one ability + the machine they make up. B is the table of them, so each is reached by its name
export type Layout<B> = {
	Id: string,
	InitialStateId: string,
	-- false: it's not held, its machine runs from the moment the character has it
	HasTool: boolean,
	Bindings: B,
}

-- what the hooks of a half keep between each other
export type Memory = { [string]: unknown }

-- what sets a binding off, on its way to the machine
export type Stimulus = {
	Key: string,
	IsActive: boolean,
	Aim: Aim?,
	Payload: unknown,
	BindingName: string?, -- the one binding it's meant for, whatever its trigger
	IsRemote: boolean?, -- it's the other side's word
}

-- what a half hooks onto an event binding. a guard that turns it down stops the binding as a whole: nothing of
-- this half runs + the machine stays where it is
export type EventHook<C> = {
	Guard: ((context: C) -> boolean)?,
	Run: ((context: C) -> ())?,
}
export type StateHook<C> = (context: C, swap: Swap?) -> Cleanup

-- one half of an ability: what it does at every binding of the layout
export type Definition<C> = {
	Layout: Layout<any>,
	EventHooks: { [string]: { EventHook<C> } },
	StateHooks: { [string]: { StateHook<C> } },
	-- the client effects the machine of the player may pass on to everybody else as it uses them on their own
	-- avatar, by name, + how far they go. only the server half has a say in it
	Relays: { [string]: Reach },
}

-- what a hook of the client half is run with
export type ClientContext = {
	AbilityId: string,
	Character: Model,
	Player: Player?,
	Color: Color3?, -- the one the character wears the ability in
	-- what came with whatever set the binding off. for one that's set off by time or by the state itself: with
	-- whatever brought the machine into the state
	Aim: Aim?,
	Memory: Memory, -- emptied whenever the machine changes state
	Record: Memory, -- kept for as long as the character has the ability
	VFX: ClientScope,
	getAim: () -> Aim, -- where the player points right now
	-- fires a binding that waits for the word of this half, the server half is told + gets to check it
	raise: <T>(signal: { Kind: "Event", Name: string, Authority: "Client", _Signature: (T) -> () }, payload: T) -> (),
	-- what the binding that's running was raised with, nil if it's another one
	read: <T>(signal: { Kind: "Event", Name: string, _Signature: (T) -> () }) -> T?,
}
export type ServerContext = {
	AbilityId: string,
	Character: Model,
	Player: Player?,
	Color: Color3?,
	Aim: Aim?,
	Memory: Memory,
	Record: Memory,
	VFX: ServerScope,
	raise: <T>(signal: { Kind: "Event", Name: string, Authority: "Server", _Signature: (T) -> () }, payload: T) -> (),
	read: <T>(signal: { Kind: "Event", Name: string, _Signature: (T) -> () }) -> T?,
}
export type ClientDefinition = Definition<ClientContext>
export type ServerDefinition = Definition<ServerContext>

-- an ability a character was given, as its owner's client is told
export type Grant = {
	Id: string,
	Color: Color3?,
}
Types.Grant = Type.strictInterface({
	Id = Type.string,
	Color = Type.optional(Type.Color3),
})

-- what a client tells the server about the abilities of its own character
export type Report =
	{
		Type: "Condition",
		Key: string,
		IsActive: boolean,
		Aim: Aim?,
	}
	| {
		-- a binding the client has the say on fired
		Type: "Binding",
		AbilityId: string,
		Name: string,
		Payload: unknown,
		Aim: Aim?,
	}
Types.Report = Type.union(
	Type.strictInterface({
		Type = Type.literal("Condition"),
		Key = Type.string,
		IsActive = Type.boolean,
		Aim = Type.optional(Types.Aim),
	}),
	Type.strictInterface({
		Type = Type.literal("Binding"),
		AbilityId = Type.string,
		Name = Type.string,
		Payload = Type.optional(Type.any),
		Aim = Type.optional(Types.Aim),
	})
)

-- what the server tells a client about the abilities of its character
export type Update =
	{
		Type: "Granted",
		Grants: { Grant },
	}
	| {
		-- a binding the server has the say on fired
		Type: "Binding",
		AbilityId: string,
		Name: string,
		Payload: unknown,
	}
	| {
		Type: "Custom",
		Name: string,
		IsActive: boolean,
	}
Types.Update = Type.union(
	Type.strictInterface({
		Type = Type.literal("Granted"),
		Grants = Type.array(Types.Grant),
	}),
	Type.strictInterface({
		Type = Type.literal("Binding"),
		AbilityId = Type.string,
		Name = Type.string,
		Payload = Type.optional(Type.any),
	}),
	Type.strictInterface({
		Type = Type.literal("Custom"),
		Name = Type.string,
		IsActive = Type.boolean,
	})
)

return Types
