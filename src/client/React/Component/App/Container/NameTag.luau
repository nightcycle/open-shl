--!strict
--!native
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Components
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/NameTag")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local usePlayerCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerCharacter")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local HEAD_NAME = "Head"
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

-- the head isn't there yet when the avatar replicates + is swapped for another when the body is rebuilt
local function useHead(character: Model?): BasePart?
	local head: BasePart?, setHead: (BasePart?) -> () = React.useState(nil :: BasePart?)
	React.useEffect(function()
		if not character then
			setHead(nil)
			return function() end
		end
		local function update()
			local inst = character:FindFirstChild(HEAD_NAME)
			setHead(if inst and inst:IsA("BasePart") then inst else nil)
		end
		local addedConnection = character.ChildAdded:Connect(update)
		local removedConnection = character.ChildRemoved:Connect(update)
		update()
		return function()
			addedConnection:Disconnect()
			removedConnection:Disconnect()
		end
	end, { character })
	return head
end

local function playerTag(props: {
	Player: Player,
}): React.ReactNode
	local character = usePlayerCharacter(props.Player)
	local head = useHead(character)
	local personaName = useAttributeValue(character, AttributeDefinition.PersonaName)
	local isInMenu = useAttributeValue(character, AttributeDefinition.IsInMenu)
	local isNameHidden = useAttributeValue(character, AttributeDefinition.IsNameHidden)
	-- a name over an avatar that's out of sight would say where it is
	if not head or isNameHidden then
		return nil
	end
	return e(
		NameTag,
		{
			Adornee = head,
			PersonaName = personaName,
			UserName = props.Player.Name,
			IsInMenu = isInMenu,
		} :: NameTag.Properties
	)
end
-- Class
return function(): React.ReactNode
	local players = usePlayers()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end

	local tags: { [string]: React.ReactNode } = {}
	for _, player in players do
		if player == localPlayer then
			continue
		end
		tags[`NameTag-{player.UserId}`] = e(playerTag, {
			Player = player,
		})
	end
	-- a billboard doesn't show from inside of the app's ScreenGui, so the tags sit in the PlayerGui
	return ReactRoblox.createPortal(e(React.Fragment, {}, tags), playerGui)
end
