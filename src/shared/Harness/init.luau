--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Plain = require("@self/Plain")
-- Types
local HarnessTypes = require("@self/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Validator = HarnessTypes.Validator
export type Argument = HarnessTypes.Argument
export type Command = HarnessTypes.Command
export type Answer = HarnessTypes.Answer
export type Bridge = HarnessTypes.Bridge
-- Constants
local LIST_NAME = "list"
-- what the bindable of either side is called. the server's is in ServerStorage, a client's in its own PlayerScripts
local BINDABLE_NAME = "Harness"
local OPTIONAL_SUFFIX = "?"
-- Variables
-- References
-- Private Functions
local function fail(message: string): Answer
	return {
		IsOk = false,
		Error = message,
	}
end

-- every field a command takes by its name, + none it doesn't
local function newValidator(arguments: { Argument }): Validator
	local fields: { [string]: Validator } = {}
	for _, argument in arguments do
		assert(not fields[argument.Name], `the argument "{argument.Name}" is listed twice`)
		fields[argument.Name] = argument.Validator
	end
	return Type.strictInterface(fields)
end

-- what the list says of a command: enough to call it without having read it
local function describe(command: Command): { [string]: any }
	local arguments: { { [string]: string } } = {}
	for _, argument in command.Arguments do
		table.insert(arguments, {
			Name = argument.Name,
			Kind = argument.Kind,
			Doc = argument.Doc,
		})
	end
	return {
		Name = command.Name,
		Doc = command.Doc,
		Arguments = arguments,
	}
end
-- Class
-- what an agent drives a running game through. it only exists in a place that was built for it (HARNESS_ENABLED): each
-- side has one service that puts one BindableFunction where only that side reaches, + answers it with a bridge over
-- the commands of that side. the game never requires any of it, the commands require the game
local Module = {}

Module.LIST_NAME = LIST_NAME
Module.BINDABLE_NAME = BINDABLE_NAME

Module.newArgument = function(name: string, kind: string, validator: Validator, doc: string): Argument
	local argument: Argument = table.freeze({
		Name = name,
		Kind = kind,
		Doc = doc,
		Validator = validator,
	})
	assert(HarnessTypes.Argument(argument))
	return argument
end

-- the same argument as one that may be left out
Module.optional = function(argument: Argument): Argument
	return Module.newArgument(
		argument.Name,
		argument.Kind .. OPTIONAL_SUFFIX,
		Type.optional(argument.Validator),
		argument.Doc
	)
end

Module.newCommand = function(
	name: string,
	doc: string,
	arguments: { Argument },
	run: (args: { [string]: any }) -> Result<any, string>
): Command
	local command: Command = table.freeze({
		Name = name,
		Doc = doc,
		Arguments = table.freeze(table.clone(arguments)),
		Run = run,
	})
	assert(HarnessTypes.Command(command))
	return command
end

-- answers a bindable with the commands of a side. whatever it's handed + whatever a command does, what comes back is
-- an answer: nothing is thrown at whoever invoked it
Module.newBridge = function(commands: { Command }): Bridge
	local byName: { [string]: Command } = {}
	local validators: { [string]: Validator } = {}
	local descriptions: { { [string]: any } } = {}
	local function add(command: Command)
		assert(not byName[command.Name], `the command "{command.Name}" is listed twice`)
		byName[command.Name] = command
		validators[command.Name] = newValidator(command.Arguments)
		table.insert(descriptions, describe(command))
	end
	add(
		Module.newCommand(
			LIST_NAME,
			"every command of this side: its name, what it does + what it takes",
			{},
			function(): Result<any, string>
				return Result.ok(descriptions)
			end
		)
	)
	for _, command in commands do
		add(command)
	end
	table.sort(descriptions, function(a: { [string]: any }, b: { [string]: any }): boolean
		return a.Name < b.Name
	end)

	return function(name: unknown, args: unknown): Answer
		if type(name) ~= "string" then
			return fail(`a command is named by a string, received a {typeof(name)}. "{LIST_NAME}" names them all`)
		end
		local command = byName[name]
		if not command then
			return fail(`no command "{name}" on this side in this game. "{LIST_NAME}" names them all`)
		end
		local values: unknown = if args == nil then {} else args
		local isValid, problem = validators[name](values)
		if not isValid then
			return fail(`bad arguments for "{name}": {problem}`)
		end
		local isDone, res = xpcall(command.Run :: any, debug.traceback, values)
		if not isDone then
			return fail(`"{name}" threw: {res}`)
		end
		if type(res) ~= "table" or (res.IsOk ~= true and res.IsErr ~= true) then
			return fail(`"{name}" answered with no result`)
		end
		if res.IsErr then
			return fail(tostring(res.Value))
		end
		return {
			IsOk = true,
			Value = Plain.from(res.Value),
		}
	end
end

return Module
