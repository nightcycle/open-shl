--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
-- Types
local Types = {}

export type Validator = (value: unknown) -> (boolean, string?)
-- one field of what a command is called with
export type Argument = {
	Name: string,
	-- what it takes the way the list tells it, a "?" at its end for one that may be left out
	Kind: string,
	Doc: string,
	Validator: Validator,
}
Types.Argument = Type.strictInterface({
	Name = Type.string,
	Kind = Type.string,
	Doc = Type.string,
	Validator = Type.callback,
})
-- something an agent has the running game do or tell. it's data next to the service it drives: the bridge only ever
-- runs one with a table that passed the validators of its arguments, + a field none of them names is turned down
export type Command = {
	Name: string, -- "<area>.<verb>", lower-case
	Doc: string, -- one line
	Arguments: { Argument },
	-- may yield. what it answers with crosses the bridge as plain data, a throw crosses it as an error
	Run: (args: { [string]: any }) -> TypeUnionLib.Result<any, string>,
}
Types.Command = Type.strictInterface({
	Name = Type.union(Type.literal("list"), Type.match("^%l+%.%l+$")),
	Doc = Type.string,
	Arguments = Type.array(Types.Argument),
	Run = Type.callback,
})
-- what comes back over the bindable, whatever went in
export type Answer = {
	IsOk: boolean,
	Value: any?,
	Error: string?,
}
Types.Answer = Type.strictInterface({
	IsOk = Type.boolean,
	Value = Type.optional(Type.any),
	Error = Type.optional(Type.string),
})
-- what the bindable of a side is answered by. neither argument is trusted to be what it should
export type Bridge = (name: unknown, args: unknown) -> Answer
-- something the harness saw happen, off a signal that was there to be listened to
export type Event = {
	Sequence: number, -- counts up from 1 for as long as the side runs, none is handed out twice
	Time: number, -- on the clock of the server, the one a fight is timed by
	Kind: string,
	Subject: string?, -- whose it is: the name of a player or of a puppet
	Data: { [string]: any }, -- plain
}
Types.Event = Type.strictInterface({
	Sequence = Type.intersection(Type.integer, Type.numberPositive),
	Time = Type.number,
	Kind = Type.string,
	Subject = Type.optional(Type.string),
	Data = Type.map(Type.string, Type.any),
})
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
