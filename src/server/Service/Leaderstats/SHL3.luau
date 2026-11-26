--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
type Session = SessionService.Session
-- Constants
local CREDITS_CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
-- Variables
-- References
-- Private Functions
-- Class
-- the one column of the old place: what a player has to spend
return table.freeze({
	table.freeze({
		Name = "Credits",
		ClassName = "IntValue" :: "IntValue",
		Get = function(session: Session): number
			return session.Save.Balances[CREDITS_CURRENCY]
		end,
	}),
})
