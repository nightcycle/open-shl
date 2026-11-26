--!strict
-- Services
-- Packages
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local NpcDefinition = require("@game/ServerScriptService/Server/Definition/Npc")
local NpcService = require("@game/ServerScriptService/Server/Service/Npc")
-- Types
local DisasterType = require("@game/ReplicatedStorage/Shared/Type/Disaster")
type Rise = DisasterType.Rise
-- the ground of a map that bodies nobody plays come out of as a target falls
export type Ground = {
	-- it smokes, they're out + walk for as long as they do. onStood is called once the target is to stand again
	Raise: (onStood: () -> ()) -> (),
	Destroy: () -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
-- what the map has every one of its spots smoke with, off as it comes
local function setSmoke(spot: BasePart, isEnabled: boolean)
	local smoke = spot:FindFirstChildOfClass("Smoke")
	if smoke then
		smoke.Enabled = isEnabled
	end
end
-- Class
-- what follows the fall of a target that bodies rise at: every spot the map marks for one smokes for a while, then
-- one comes out of each + the smoke stops. they walk for as long as the row says + the target stands again a
-- good while after they're gone, so no two waves are ever out at once
return {
	new = function(rise: Rise): Ground
		-- a body the game doesn't list would only show as the first target falls
		local npcRes = NpcDefinition.get(rise.NpcId)
		assert(npcRes.IsOk, `a disaster: {npcRes.Value}`)
		-- yields from the fall until the target stands again
		local thread: thread? = nil

		local function stop()
			local running = thread
			thread = nil
			if running and coroutine.status(running) == "suspended" then
				task.cancel(running)
			end
		end

		return table.freeze({
			Raise = function(onStood: () -> ())
				stop()
				thread = task.spawn(function()
					assert(NpcService.IsInitialized, `the npc service isn't initialized`)
					for _, spot in MapDefinition.list(MapDefinition.ZombieSpawn) do
						setSmoke(spot, true)
					end
					task.wait(rise.SmokeDuration)
					-- one a spot, all over the map: a server that walks as many as it may already has the rest
					-- refused with a word of the service's own
					for _, spot in MapDefinition.list(MapDefinition.ZombieSpawn) do
						NpcService:Spawn(rise.NpcId, spot.CFrame + rise.Offset, rise.Lifetime)
						setSmoke(spot, false)
					end
					task.wait(rise.ResetDelay)
					thread = nil
					onStood()
				end)
			end,
			Destroy = function()
				stop()
				for _, spot in MapDefinition.list(MapDefinition.ZombieSpawn) do
					setSmoke(spot, false)
				end
			end,
		})
	end,
}
