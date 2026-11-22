--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Components
-- Hooks
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
-- Contexts
local CharacterHealthContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Health")
-- Types
export type Properties = {}
-- Constants
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
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
-- Class
-- the health bar the flow asks the engine for is drawn from the humanoid, which the game leaves full until the avatar
-- is dead: what's left of its health is an attribute. so the humanoid is told what the attribute says, on this client
-- alone. it draws nothing itself
return function(): React.ReactNode
	local health = React.useContext(CharacterHealthContext)
	local humanoid = useHumanoid(useLocalCharacter())

	React.useEffect(function()
		-- that it's dead is the server's to say, which it does on the humanoid itself
		if humanoid and humanoid.Health > 0 and health > 0 then
			humanoid.Health = humanoid.MaxHealth * health / MAX_HEALTH
		end
		return function() end
	end, { humanoid :: any, health })

	return nil
end
