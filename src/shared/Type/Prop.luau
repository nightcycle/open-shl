--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Aim = AbilityType.Aim
type Memory = AbilityType.Memory
type IconDefinition = MiscType.IconDefinition
type Cleanup = VFXType.Cleanup
type ClientScope = VFXType.ClientScope
type ServerScope = VFXType.ServerScope

local Types = {}

-- what a click with the prop out comes to
export type UseRule = {
	Duration: number, -- seconds a use lasts: what it shows is on for this long + what it gives comes at the end of it
	Lockout: number?, -- seconds from the start of a use until the next may start, as long as the use itself without
}
Types.UseRule = Type.intersection(
	Type.strictInterface({
		Duration = Type.numberPositive,
		Lockout = Type.optional(Type.numberPositive),
	}),
	-- a second use would start in the middle of the first
	function(value: UseRule): (boolean, string?)
		if value.Lockout ~= nil and value.Lockout < value.Duration then
			return false, `a use that may start again before it's over`
		end
		return true
	end
)

-- something a character holds that isn't a power
export type PropDefinition = {
	Id: string,
	Name: string, -- what the hotbar calls it. a map that was exported before the props had ids names its pad by it
	Icon: IconDefinition?, -- the hotbar spells the name out without
	Use: UseRule?, -- a click does nothing without
}
Types.PropDefinition = Type.strictInterface({
	Id = Type.string,
	Name = Type.string,
	Icon = Type.optional(MiscType.IconDefinition),
	Use = Type.optional(Types.UseRule),
})

-- what a game has of them. a game with none lists none
export type PropCatalogue = {
	Definitions: { PropDefinition },
	-- the ones whose halves aren't built yet: nobody is handed one + a pad that names one is left alone
	Upcoming: { PropDefinition }?,
	-- what the pads of the ones that never come back are named, each is taken off the map
	Retired: { string }?,
}
Types.PropCatalogue = Type.strictInterface({
	Definitions = Type.array(Types.PropDefinition),
	Upcoming = Type.optional(Type.array(Types.PropDefinition)),
	Retired = Type.optional(Type.array(Type.string)),
})

-- what a prop hangs its effects on. every prop has the same six, there's nothing to lay out
export type StateMomentName = "Hold" | "Rest" | "Using"
export type EventMomentName = "Draw" | "Use" | "Finish"
export type StateMoment = {
	Kind: "State",
	Name: StateMomentName,
}
export type EventMoment = {
	Kind: "Event",
	Name: EventMomentName,
}

-- what a half hooks onto an event moment. a guard that turns a use down stops it as a whole
export type EventHook<C> = {
	Guard: ((context: C) -> boolean)?,
	Run: ((context: C) -> ())?,
}
export type StateHook<C> = (context: C) -> Cleanup

-- one half of a prop: what it does at every moment
export type Definition<C> = {
	Prop: PropDefinition,
	EventHooks: { [string]: { EventHook<C> } },
	StateHooks: { [string]: { StateHook<C> } },
}

-- what a hook of the client half is run with
export type ClientContext = {
	PropId: string,
	Character: Model,
	Player: Player?,
	Aim: Aim?, -- what came with the click, nil for whatever no click set off
	Memory: Memory, -- emptied whenever it's put away
	Record: Memory, -- kept for as long as the character carries it
	VFX: ClientScope,
	getAim: () -> Aim, -- where the player points right now
}
export type ServerContext = {
	PropId: string,
	Character: Model,
	Player: Player?,
	Aim: Aim?,
	Memory: Memory,
	Record: Memory,
	VFX: ServerScope,
}
export type ClientDefinition = Definition<ClientContext>
export type ServerDefinition = Definition<ServerContext>

-- what a client tells the server about the prop in the hand of its own character: it was clicked with
export type Report = {
	Id: string,
	Aim: Aim?,
}
Types.Report = Type.strictInterface({
	Id = Type.string,
	Aim = Type.optional(AbilityType.Aim),
})

return Types
