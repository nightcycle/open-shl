--!strict
--!native
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Components
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local usePlayerCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerCharacter")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- everybody in the game, a player that is on their way out is already left out
local function usePlayers(): { Player }
	local players: { Player }, setPlayers: ({ Player }) -> () = React.useState(Players:GetPlayers())
	React.useEffect(function()
		local function update(leavingPlayer: Player?)
			local out: { Player } = {}
			for _, player in Players:GetPlayers() do
				if player ~= leavingPlayer then
					table.insert(out, player)
				end
			end
			table.freeze(out)
			setPlayers(out)
		end
		local addedConnection = Players.PlayerAdded:Connect(function()
			update(nil)
		end)
		local removingConnection = Players.PlayerRemoving:Connect(function(player: Player)
			update(player)
		end)
		update(nil)
		return function()
			addedConnection:Disconnect()
			removingConnection:Disconnect()
		end
	end, {})
	return players
end

-- the humanoid isn't there yet when the avatar replicates
local function useHumanoid(character: Model?): Humanoid?
	local humanoid: Humanoid?, setHumanoid: (Humanoid?) -> () = React.useState(nil :: Humanoid?)
	React.useEffect(function()
		if not character then
			setHumanoid(nil)
			return function() end
		end
		local function update()
			setHumanoid(character:FindFirstChildOfClass("Humanoid"))
		end
		local addedConnection = character.ChildAdded:Connect(update)
		local removedConnection = character.ChildRemoved:Connect(update)
		update()
		return function()
			addedConnection:Disconnect()
			removedConnection:Disconnect()
		end
	end, { character })
	return humanoid
end

local function playerHealth(props: {
	Player: Player,
}): React.ReactNode
	local character = usePlayerCharacter(props.Player)
	local humanoid = useHumanoid(character)
	local health = useAttributeValue(character, AttributeDefinition.Health)

	React.useEffect(function()
		-- that it's dead is the server's to say, which it does on the humanoid itself
		if humanoid and humanoid.Health > 0 and health > 0 then
			humanoid.Health = humanoid.MaxHealth * health / MAX_HEALTH
		end
		return function() end
	end, { humanoid :: any, health })

	return nil
end
-- Class
-- the health bars the game leaves to the engine, the one of the player + the one over whoever is hurt nearby, are
-- drawn from humanoids, which the game leaves full until an avatar is dead: what's left of its health is an attribute.
-- so every humanoid is told what its avatar's attribute says, on this client alone. it draws nothing itself
return function(): React.ReactNode
	local players = usePlayers()

	local children: { [string]: React.ReactNode } = {}
	for _, player in players do
		children[`Health-{player.UserId}`] = e(playerHealth, {
			Player = player,
		})
	end
	return e(React.Fragment, {}, children)
end
