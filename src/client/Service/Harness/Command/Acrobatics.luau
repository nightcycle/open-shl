--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
local AcrobaticsService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Acrobatics")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
local MOVE_IDS: { string } = {}
for _, move in AcrobaticsDefinition.MOVES do
	table.insert(MOVE_IDS, move.Id)
end
table.freeze(MOVE_IDS)
local MOVE_ID = Harness.newArgument(
	"MoveId",
	"string",
	Type.literal(table.unpack(MOVE_IDS)),
	`the id of a move, one of {table.concat(MOVE_IDS, ", ")}`
)
-- Variables
-- References
-- Private Functions
local function getState(): { [string]: any }
	assert(AcrobaticsService.IsInitialized, `the acrobatics service isn't initialized`)
	return {
		IsTumbling = AcrobaticsService:GetIfTumbling(),
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"acrobatics.get",
			"whether a move of this client's avatar is underway, + the moves there are in the order of their buttons",
			{},
			function(): Result<any, string>
				local state = getState()
				state.MoveIds = MOVE_IDS
				return Result.ok(state)
			end
		),
		Harness.newCommand(
			"acrobatics.play",
			"throws this client's avatar into a move, the way the button of the panel does. an error says why it was turned down: another move is underway, the avatar is down, seated or behind a menu, or an ability has it",
			{ MOVE_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(AcrobaticsService.IsInitialized, `the acrobatics service isn't initialized`)
				local playRes = AcrobaticsService:Play(args.MoveId)
				if playRes.IsErr then
					return Result.err(playRes.Value)
				end
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"acrobatics.fix",
			"what the Fix Character button does: ends the move that's underway + has the avatar get back up",
			{},
			function(): Result<any, string>
				assert(AcrobaticsService.IsInitialized, `the acrobatics service isn't initialized`)
				AcrobaticsService:Fix()
				return Result.ok(getState())
			end
		),
	}
end

return Module
