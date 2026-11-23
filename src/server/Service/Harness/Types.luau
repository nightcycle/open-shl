--!strict
-- Services
-- Packages
-- Modules
local Bodies = require("@game/ServerScriptService/Server/Service/Harness/Bodies")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
-- Types
local Types = {}

export type Body = Bodies.Body
-- what every command of the server is made with
export type Context = {
	Log: Log.Log,
	Bodies: Bodies.Bodies,
}
-- the commands of one area, beside the service they drive. an area whose service the game doesn't start is never loaded
export type Area = {
	Name: string,
	IsFeatured: boolean?, -- nil when every game has it
	Load: () -> { list: (context: Context) -> { Harness.Command } },
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
