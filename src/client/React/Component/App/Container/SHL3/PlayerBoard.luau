--!strict
--!native
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local PlayerBoard = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/PlayerBoard")
-- Hooks
-- Contexts
-- Types
type Row = PlayerBoard.Row
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- everybody in the game, in the order the engine lists them: what roblox knows them as + the name of whoever their
-- avatar is out as. the server says that on the player: an avatar is only here while it's in range, in the old place
-- every one of them was. whoever wasn't dressed yet has no name to go by, neither has one that wasn't given any.
-- nobody has a price on them: there are no sides to be on the wrong one of yet
local function getRows(): { Row }
	local out: { Row } = {}
	for _, player in Players:GetPlayers() do
		local personaName = AttributeDefinition.get(player, AttributeDefinition.ActivePersonaName)
		local row: Row = {
			UserId = player.UserId,
			UserName = player.Name,
			Name = if personaName ~= "" then personaName else nil,
		}
		table.freeze(row)
		table.insert(out, row)
	end
	table.freeze(out)
	return out
end
-- Class
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	-- the old place filled its list in as the panel came up + left it at that: whoever joins or changes after it's
	-- up is on it the next time
	local rows: { Row } = React.useMemo(getRows, {})

	return e(
		PlayerBoard,
		{
			Size = UDim2.fromScale(1, 1),
			Rows = rows,
			OnAction = function(action: PlayerBoard.ActionInfo)
				if action.Type == "Exit" then
					ShellService:ClosePanel("Database")
				end
			end,
		} :: PlayerBoard.Properties
	)
end
