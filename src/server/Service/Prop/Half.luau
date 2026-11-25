--!strict
-- Services
-- Packages
-- Modules
local PropLibrary = require("@game/ServerScriptService/Server/Prop/Library")
local Runner = require("@game/ReplicatedStorage/Shared/Prop/Runner")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Runner = Runner.Runner
type Aim = AbilityType.Aim
type Memory = AbilityType.Memory
type ServerContext = PropType.ServerContext
type ServerScope = VFXType.ServerScope
-- Constants
-- seconds the server is ahead of what a use waits for, the same a machine is given
local LENIENCY = 0.15
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

-- the half the server runs of one prop, for the one avatar that carries it: every effect of it is asked of the scope
-- it's handed. it says nothing of the hand, whoever made it draws + stows it. an error for a prop the game doesn't
-- list as built
function Util.new(id: string, character: Model, player: Player?, scope: ServerScope): Runner
	return Runner.new(PropLibrary.get(id), {
		Leniency = LENIENCY,
		NewContext = function(aim: Aim?, memory: Memory, record: Memory): ServerContext
			return table.freeze({
				PropId = id,
				Character = character,
				Player = player,
				Aim = aim,
				Memory = memory,
				Record = record,
				VFX = scope,
			})
		end,
	})
end

return Util
