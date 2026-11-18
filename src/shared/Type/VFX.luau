--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types

local Types = {}

export type Validator = (value: unknown) -> (boolean, string?)
-- an event is fired + forgotten, a state is started + has to be stopped
export type Kind = "Event" | "State"
export type Realm = "Client" | "Shared" | "Server"

-- what a state effect is handed as it ends right where another begins, so the two can ease into each other
export type Swap = {
	From: string,
	To: string,
	Duration: number,
}
Types.Swap = Type.strictInterface({
	From = Type.string,
	To = Type.string,
	Duration = Type.numberMin(0),
})

export type Cleanup = (swap: Swap?) -> ()
export type Handle = {
	Stop: (swap: Swap?) -> (),
}

-- who the server shows a client effect to, counted from the player the effect belongs to
export type Audience = "All" | "Owner" | "Others"
Types.Audience = Type.literal("All", "Owner", "Others")

-- how far one use of a client effect goes. it's said where the effect is used rather than by the effect, so the
-- same one can carry across a street for one ability + only be seen up close for another
export type Reach = {
	Range: number?, -- studs from the avatar an event is still worth showing at
	MinQualityLevel: number?, -- the graphics level it's skipped below
}
-- for a use on the client of the player it belongs to
export type ClientOptions = {
	Range: number?,
	MinQualityLevel: number?,
	-- the player's own machine passes it on to everybody else. only ever what it does to their own avatar, + only
	-- if the server half of one of their abilities lets that effect through
	IsReplicated: boolean?,
}
-- for a use the server has clients show
export type Replication = {
	Range: number?,
	MinQualityLevel: number?,
	Audience: Audience?, -- everybody without one
}

-- whose effect it is, an effect of the world has neither
export type Subject = {
	Character: Model?,
	Player: Player?,
	IsOwner: boolean, -- on a client: whether it's the local player's own doing, not something they were told of
}

-- _Signature is never set, it only carries the types. an effect is only its name + what it takes: where, how far +
-- to whom it's shown is up to every use of it
export type VFX = {
	Name: string,
	Realm: Realm,
	Kind: Kind,
	Props: Validator,
}
export type ClientEvent<P> = {
	Name: string,
	Realm: "Client",
	Kind: "Event",
	IsClientSide: true,
	Props: Validator,
	_Signature: (P) -> nil,
}
export type ClientState<P> = {
	Name: string,
	Realm: "Client",
	Kind: "State",
	IsClientSide: true,
	Props: Validator,
	_Signature: (P) -> (),
}
export type SharedEvent<P, R> = {
	Name: string,
	Realm: "Shared",
	Kind: "Event",
	IsClientSide: true,
	IsServerSide: true,
	Props: Validator,
	Run: (props: P, scope: SharedScope) -> R,
	_Signature: (P) -> R,
}
export type SharedState<P> = {
	Name: string,
	Realm: "Shared",
	Kind: "State",
	IsClientSide: true,
	IsServerSide: true,
	Props: Validator,
	Start: (props: P, scope: SharedScope, swap: Swap?) -> Cleanup,
	_Signature: (P) -> (),
}
export type ServerEvent<P, R> = {
	Name: string,
	Realm: "Server",
	Kind: "Event",
	IsServerSide: true,
	Props: Validator,
	Run: (props: P, scope: ServerScope) -> R,
	_Signature: (P) -> R,
}
export type ServerState<P> = {
	Name: string,
	Realm: "Server",
	Kind: "State",
	IsServerSide: true,
	Props: Validator,
	Start: (props: P, scope: ServerScope, swap: Swap?) -> Cleanup,
	_Signature: (P) -> (),
}

-- what an effect is run with: whose it is + the only way to run more effects from inside of it. the functions take
-- what's compatible with where they are, anything else is a type error
export type SharedScope = {
	Character: Model?,
	Player: Player?,
	IsOwner: boolean,
	fire: <P, R>(
		vfx: { Kind: "Event", IsClientSide: true, IsServerSide: true, _Signature: (P) -> R },
		props: P
	) -> R,
	start: <P>(
		vfx: { Kind: "State", IsClientSide: true, IsServerSide: true, _Signature: (P) -> () },
		props: P,
		swap: Swap?
	) -> Handle,
}
export type ClientScope = {
	Character: Model?,
	Player: Player?,
	IsOwner: boolean,
	fire: <P, R>(
		vfx: { Kind: "Event", IsClientSide: true, _Signature: (P) -> R },
		props: P,
		options: ClientOptions?
	) -> R,
	start: <P>(
		vfx: { Kind: "State", IsClientSide: true, _Signature: (P) -> () },
		props: P,
		swap: Swap?,
		options: ClientOptions?
	) -> Handle,
}
export type ServerScope = {
	Character: Model?,
	Player: Player?,
	IsOwner: boolean,
	fire: <P, R>(vfx: { Kind: "Event", IsServerSide: true, _Signature: (P) -> R }, props: P) -> R,
	start: <P>(vfx: { Kind: "State", IsServerSide: true, _Signature: (P) -> () }, props: P, swap: Swap?) -> Handle,
	-- shown by the clients the replication picks
	fireClient: <P>(
		vfx: { Kind: "Event", Realm: "Client", _Signature: (P) -> nil },
		props: P,
		replication: Replication?
	) -> (),
	startClient: <P>(
		vfx: { Kind: "State", Realm: "Client", _Signature: (P) -> () },
		props: P,
		swap: Swap?,
		replication: Replication?
	) -> Handle,
}

-- how a realm runs the effects a scope is asked for. nil from Fire or Start: it wasn't run (culled, unknown)
export type Driver = {
	Fire: (vfx: VFX, props: unknown, subject: Subject, options: ClientOptions?) -> unknown,
	Start: (vfx: VFX, props: unknown, subject: Subject, swap: Swap?, options: ClientOptions?) -> Cleanup?,
	FireClient: ((vfx: VFX, props: unknown, subject: Subject, replication: Replication) -> ())?,
	StartClient: ((vfx: VFX, props: unknown, subject: Subject, swap: Swap?, replication: Replication) -> Cleanup?)?,
}

-- an effect crossing the network: told to clients by the server + to the server by the client it belongs to. how
-- far it reaches is only ever the server's to say
export type Message =
	{
		Type: "Fire",
		Name: string,
		Props: unknown,
		Character: Model?,
		Range: number?,
		MinQualityLevel: number?,
	}
	| {
		Type: "Start",
		Name: string,
		Props: unknown,
		Character: Model?,
		Id: string,
		Swap: Swap?,
		MinQualityLevel: number?,
	}
	| {
		Type: "Stop",
		Id: string,
		Swap: Swap?,
	}
Types.Message = Type.union(
	Type.strictInterface({
		Type = Type.literal("Fire"),
		Name = Type.string,
		Props = Type.any,
		Character = Type.optional(Type.instanceIsA("Model")),
		Range = Type.optional(Type.numberMin(0)),
		MinQualityLevel = Type.optional(Type.number),
	}),
	Type.strictInterface({
		Type = Type.literal("Start"),
		Name = Type.string,
		Props = Type.any,
		Character = Type.optional(Type.instanceIsA("Model")),
		Id = Type.string,
		Swap = Type.optional(Types.Swap),
		MinQualityLevel = Type.optional(Type.number),
	}),
	Type.strictInterface({
		Type = Type.literal("Stop"),
		Id = Type.string,
		Swap = Type.optional(Types.Swap),
	})
)

return Types
