--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- if the avatar of the player is in a fight, by the time the server wrote onto it. it's over by itself once that
-- time has passed: the server isn't asked, + never in a game that keeps no fight out of its menus
return function(): boolean
	local fightingUntil = useCharacterAttribute(AttributeDefinition.FightingUntil)
	-- the fight that was waited out. the clock may still be a moment short of it when the wait is over, so it's what
	-- ends the fight here
	local pastUntil: number?, setPastUntil: (number?) -> () = React.useState(nil :: number?)
	React.useEffect(function()
		if not fightingUntil or not CombatDefinition.FIGHTING then
			return function() end
		end
		local isDead = false
		task.delay(math.max(fightingUntil - CombatDefinition.getTime(), 0), function()
			if not isDead then
				setPastUntil(fightingUntil)
			end
		end)
		return function()
			isDead = true
		end
	end, { fightingUntil })

	return fightingUntil ~= pastUntil and CombatDefinition.getIfFighting(fightingUntil, CombatDefinition.getTime())
end
