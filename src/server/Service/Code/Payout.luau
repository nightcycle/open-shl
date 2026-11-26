--!strict
-- Services
-- Packages
-- Modules
local CodeDefinition = require("@game/ServerScriptService/Server/Definition/Code")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type CodeDefinition = CodeDefinition.CodeDefinition
type PlayerSave = SaveType.PlayerSave
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what a code does to a save, apart from the service so it's held to it without a session
local Util = {}

-- nil for a save that keeps no codes: nothing can be said of it
function Util.getIfPaid(save: PlayerSave, definition: CodeDefinition): boolean?
	local redeemedIds = CodeDefinition.getRedeemedIds(save)
	if not redeemedIds then
		return nil
	end
	return table.find(redeemedIds, definition.Id) ~= nil
end

-- writes into the save it's handed: the money + the mark that it was paid, both or neither, so no save ever holds
-- one without the other. false leaves it untouched: it was paid before, or the save keeps no codes
function Util.pay(save: PlayerSave, definition: CodeDefinition): boolean
	local redeemedIds = CodeDefinition.getRedeemedIds(save)
	if not redeemedIds or table.find(redeemedIds, definition.Id) then
		return false
	end
	save.Balances[definition.Currency] += definition.Amount
	table.insert(redeemedIds, definition.Id)
	return true
end

return Util
