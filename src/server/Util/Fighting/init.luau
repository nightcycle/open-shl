--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
export type MenuRefusal = CombatType.MenuRefusal
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the server's side of a fight: the time an avatar is in one until is the server's to write, a client only reads it
local Util = {}

-- whoever lost health is in a fight from here on, whatever took it off them. nothing is written in a game that
-- keeps no such time
function Util.hit(character: Model, now: number)
	local fightingUntil =
		CombatDefinition.getFightingUntil(AttributeDefinition.get(character, AttributeDefinition.FightingUntil), now)
	if fightingUntil then
		AttributeDefinition.set(character, AttributeDefinition.FightingUntil, fightingUntil)
	end
end

-- whoever took it off them is in that fight too, for as long: they'd step into a menu between two hits otherwise +
-- hit from where nothing hits back. nobody did where no character is behind the loss or one did it to themselves, +
-- one who went down while their hit was on its way has no fight left to be in
function Util.land(attacker: Model?, victim: Model, now: number)
	if not attacker or attacker == victim or AttributeDefinition.get(attacker, AttributeDefinition.IsDead) then
		return
	end
	Util.hit(attacker, now)
end

-- a fight is over for whoever went down in it, the avatar they come back as was never in one
function Util.clear(character: Model)
	if AttributeDefinition.get(character, AttributeDefinition.FightingUntil) ~= nil then
		AttributeDefinition.set(character, AttributeDefinition.FightingUntil, nil)
	end
end

-- why an avatar isn't counted as in a menu (or out of one) when its player says so, nil if it is. only the way in is
-- ever shut + only to whoever is in a fight: a menu would be where they walk out of it. nobody who sits in one is
-- thrown out by a hit, a game that keeps a fight out of its menus has no hit land on them
function Util.getMenuRefusal(character: Model?, isInMenu: boolean, now: number): MenuRefusal?
	if not isInMenu then
		return nil
	end
	local fightingUntil = AttributeDefinition.get(character, AttributeDefinition.FightingUntil)
	if not fightingUntil or not CombatDefinition.getIfFighting(fightingUntil, now) then
		return nil
	end
	return table.freeze({
		Type = "Fighting" :: "Fighting",
		Until = fightingUntil,
	})
end

return Util
