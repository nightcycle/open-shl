--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
local ServiceType = require("@game/ReplicatedStorage/Shared/Type/Service")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
-- Variables
-- References
-- the list of services is what requires the harness, which requires this: a loop to the checker, so it isn't shown
-- the require. by the time anything here runs the list is long read
local ServiceDefinition: { list: () -> { ServiceType.Entry } } = (require :: any)(
	"@game/ServerScriptService/Server/Definition/Service"
)
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"game.get",
			"which game + mode the place is built for, its switches, the services it started, who's in",
			{},
			function(): Result<any, string>
				local services: { string } = {}
				for _, entry in ServiceDefinition.list() do
					table.insert(services, entry.Name)
				end
				local players: { string } = {}
				for _, player in Players:GetPlayers() do
					table.insert(players, player.Name)
				end
				local puppets: { string } = {}
				for _, body in context.Bodies:ListPuppets() do
					table.insert(puppets, body.Name)
				end
				return Result.ok({
					Game = GameDefinition.ID,
					BuildConfig = BUILD_CONFIG,
					Features = GameDefinition.FEATURES,
					Services = services, -- in the order they started
					IsPVPEnabled = ModeDefinition.getIfPVPEnabled(),
					IsEnergyEnabled = ModeDefinition.getIfEnergyEnabled(),
					IsPVP = AttributeDefinition.get(Workspace, AttributeDefinition.IsPVP),
					Players = players,
					Puppets = puppets,
					Time = Workspace:GetServerTimeNow(),
				})
			end
		),
	}
end

return Module
