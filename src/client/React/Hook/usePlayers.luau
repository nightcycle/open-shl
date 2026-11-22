--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- everybody in the game, a player that is on their way out is already left out
return function(): { Player }
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
