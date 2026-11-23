--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Log = Log.Log
-- Constants
local DEFAULT_TIMEOUT = 10
-- an invoke that never comes back takes the call of the agent with it
local MAX_TIMEOUT = 120
local SINCE = Harness.newArgument(
	"Since",
	"number",
	Type.intersection(Type.integer, Type.numberMin(0)),
	"the number of an event: only what came after it counts"
)
local KIND = Harness.newArgument("Kind", "string", Type.string, "the kind of event, the list of kinds is in the answer")
local SUBJECT =
	Harness.newArgument("Subject", "string", Type.string, "whose event: the name of a player or of a puppet")
local WHERE = Harness.newArgument(
	"Where",
	"table",
	Type.map(Type.string, Type.any),
	'what the data of the event has to hold, field by field: { Name = "Health" }'
)
local TIMEOUT = Harness.newArgument(
	"Timeout",
	"number",
	Type.numberConstrained(0, MAX_TIMEOUT),
	`seconds to wait, {DEFAULT_TIMEOUT} when left out`
)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the two commands every side reads what it saw with. the kinds are the ones that side adds, they're only named here
Module.list = function(log: Log, kinds: { string }): { Command }
	return {
		Harness.newCommand(
			"event.read",
			"the events the harness saw, oldest first: everything it still keeps, or what came after a number",
			{
				Harness.optional(SINCE),
				Harness.optional(KIND),
				Harness.optional(SUBJECT),
				Harness.optional(WHERE),
			},
			function(args: { [string]: any }): Result<any, string>
				return Result.ok({
					Events = log:Read(args.Since or 0, {
						Kind = args.Kind,
						Subject = args.Subject,
						Where = args.Where,
					}),
					-- an event before First fell out of the log, Last is what to ask from next
					First = log:GetFirst(),
					Last = log:GetLast(),
					Kinds = kinds,
				})
			end
		),
		Harness.newCommand(
			"event.wait",
			"yields until an event of a kind is seen: one after Since, or the next one from now when that's left out",
			{
				KIND,
				Harness.optional(SINCE),
				Harness.optional(SUBJECT),
				Harness.optional(WHERE),
				Harness.optional(TIMEOUT),
			},
			function(args: { [string]: any }): Result<any, string>
				local timeout: number = args.Timeout or DEFAULT_TIMEOUT
				local event = log:Wait(args.Since or log:GetLast(), {
					Kind = args.Kind,
					Subject = args.Subject,
					Where = args.Where,
				}, timeout)
				if not event then
					return Result.err(
						`no "{args.Kind}" event like that in {timeout} seconds, the last one is {log:GetLast()}`
					)
				end
				return Result.ok(event)
			end
		),
	}
end

return Module
