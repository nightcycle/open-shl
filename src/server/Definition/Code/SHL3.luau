--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local CodeType = require("@game/ServerScriptService/Server/Type/Code")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type CodeCatalogue = CodeType.CodeCatalogue
type PlayerSave = SaveType.PlayerSave
-- Constants
-- the one code its old place ever had, + what it paid: 14 allowances for six characters. a new one is a row here +
-- a publish
local CATALOGUE: CodeCatalogue = {
	Definitions = {
		{
			Id = "map-2-0",
			Text = "MAP2.0",
			Currency = PseudoEnum.Currency.Credits,
			Amount = 700,
		},
	},
	getRedeemedIds = function(save: PlayerSave): { string }?
		local section = save.SHL3
		return if section then section.RedeemedCodeIds else nil
	end,
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
