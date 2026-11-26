--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type TestMap = SimpleTest.TestMap
type PlayerSave = SaveType.PlayerSave
-- Constants
local CREDITS = 1000
-- Variables
-- References
-- Private Functions
-- as much of a save as a code reads + writes
local function newSave(redeemedIds: { string }): PlayerSave
	local save: any = {
		Balances = { Credits = CREDITS, Gems = 0 },
		SHL3 = { RedeemedCodeIds = redeemedIds },
	}
	return save
end

-- the catalogue raises in a game without codes, so it's only asked for by one that has them
local function newTests(): TestMap
	local CodeDefinition = require("@game/ServerScriptService/Server/Definition/Code")
	local PayoutUtil = require("@game/ServerScriptService/Server/Service/Code/Payout")
	local first = CodeDefinition.list()[1]
	assert(first, `the game is listed for codes it has none of`)

	return {
		-- a word is found however a keyboard left it, + nothing else is
		Match = SpecUtil.newScenario(function()
			local text = first.Text
			assert(CodeDefinition.find(text) == first, `"{text}" isn't found as it's written`)
			assert(CodeDefinition.find(` {text} `) == first, `"{text}" isn't found with spaces around it`)
			assert(CodeDefinition.find(string.lower(text)) == first, `"{text}" isn't found in lower case`)
			assert(CodeDefinition.find(string.upper(text)) == first, `"{text}" isn't found in upper case`)
			assert(CodeDefinition.find(string.sub(text, 1, -2)) == nil, `a part of "{text}" is found`)
			assert(CodeDefinition.find(`{text}{text}`) == nil, `"{text}" twice over is found`)
			assert(CodeDefinition.find("") == nil, `nothing at all is a code`)
			assert(CodeDefinition.find("   ") == nil, `a few spaces are a code`)
			assert(CodeDefinition.find(string.rep("a", 10000)) == nil, `a text of 10,000 characters is a code`)
		end),

		-- the money + the mark land in the one save, the id is what's kept
		Paid = SpecUtil.newScenario(function()
			local save = newSave({})
			assert(PayoutUtil.getIfPaid(save, first) == false, `a new save was paid for "{first.Id}"`)
			assert(PayoutUtil.pay(save, first), `"{first.Id}" wasn't paid`)
			local balance = save.Balances[first.Currency]
			assert(balance == CREDITS + first.Amount, `{CREDITS} + {first.Amount} came to {balance}`)
			local redeemedIds = CodeDefinition.getRedeemedIds(save)
			assert(
				redeemedIds and #redeemedIds == 1 and redeemedIds[1] == first.Id,
				`the save doesn't keep "{first.Id}" as paid`
			)
			assert(PayoutUtil.getIfPaid(save, first) == true, `the save doesn't say "{first.Id}" was paid`)
		end),

		-- a code is good once: for a save that says it was paid nothing is written
		Once = SpecUtil.newScenario(function()
			local save = newSave({ first.Id })
			assert(not PayoutUtil.pay(save, first), `"{first.Id}" was paid twice`)
			assert(save.Balances[first.Currency] == CREDITS, `a code that was used changed the balance`)
			local redeemedIds = CodeDefinition.getRedeemedIds(save)
			assert(redeemedIds and #redeemedIds == 1, `a code that was used is kept twice`)
		end),

		-- a save that has nowhere to keep the mark isn't paid either
		NoSection = SpecUtil.newScenario(function()
			local save: any = newSave({})
			save.SHL3 = nil
			assert(PayoutUtil.getIfPaid(save, first) == nil, `a save that keeps no codes says something of one`)
			assert(not PayoutUtil.pay(save, first), `a save that keeps no codes was paid`)
			assert(save.Balances[first.Currency] == CREDITS, `a save that keeps no codes has more for it`)
		end),
	}
end
-- Class
-- only a game with codes has anything to hold this to
return if GameDefinition.FEATURES.Codes then newTests() else {} :: TestMap
