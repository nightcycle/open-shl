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
local usePlayers = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayers")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
local e = React.createElement

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
	local isNameHidden = useAttributeValue(character, AttributeDefinition.IsNameHidden)
	-- a bar over an avatar that's out of sight would say where it is, as its name would: somebody else's is full for
	-- as long as nobody is shown who they are
	local shownHealth = if isNameHidden and props.Player ~= Players.LocalPlayer then MAX_HEALTH else health

	React.useEffect(function()
		-- that it's dead is the server's to say, which it does on the humanoid itself
		if humanoid and humanoid.Health > 0 and shownHealth > 0 then
			humanoid.Health = humanoid.MaxHealth * shownHealth / MAX_HEALTH
		end
		return function() end
	end, { humanoid :: any, shownHealth })

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
