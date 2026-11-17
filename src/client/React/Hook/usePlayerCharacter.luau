--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(player: Player): Model?
	local character: Model?, setCharacter: (Model?) -> () = React.useState(player.Character)
	React.useEffect(function()
		local addedConnection = player.CharacterAdded:Connect(function(newCharacter: Model)
			setCharacter(newCharacter)
		end)
		local removingConnection = player.CharacterRemoving:Connect(function(oldCharacter: Model)
			-- the player may have let go of the avatar already by the time this is heard, or hold the next one
			local newCharacter = player.Character
			setCharacter(if newCharacter ~= oldCharacter then newCharacter else nil)
		end)
		setCharacter(player.Character)
		return function()
			addedConnection:Disconnect()
			removingConnection:Disconnect()
		end
	end, { player })
	return character
end
