--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Packages
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
type Log = Log.Log
-- Constants
-- the kinds of event the server adds, each off a signal that was there before the harness
local KINDS = table.freeze({
	"Spawned", -- an avatar came in
	"Dressed", -- the look of an avatar is on it
	"Attribute", -- an attribute of an avatar or a puppet changed: Name, Value
	"PlayerAttribute", -- an attribute of a player changed: Name, Value
	"Died", -- the humanoid of an avatar or a puppet died
	"ActiveCharacterChanged", -- a player plays another slot or another identity
	"InMenuChanged", -- the server counts a player as in a menu, or as out of it: IsInMenu
	"Remote", -- a client fired an event at the server: Name, Value
})
-- Variables
-- References
-- Private Functions
local function watchPlayer(log: Log, player: Player): RBXScriptConnection
	return player.AttributeChanged:Connect(function(name: string)
		log:Add("PlayerAttribute", player.Name, {
			Name = name,
			Value = player:GetAttribute(name),
		})
	end)
end
-- Class
local Util = {}

Util.KINDS = KINDS

-- the log hears of every attribute the body changes + of its death, until the connections are cut or it's gone
function Util.character(log: Log, subject: string, character: Model): { RBXScriptConnection }
	local connections: { RBXScriptConnection } = {
		character.AttributeChanged:Connect(function(name: string)
			log:Add("Attribute", subject, {
				Name = name,
				Value = character:GetAttribute(name),
			})
		end),
	}
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		table.insert(
			connections,
			humanoid.Died:Connect(function()
				log:Add("Died", subject)
			end)
		)
	end
	return connections
end

-- everything the server's log hears of without a command having asked. answers with what stops it
function Util.start(log: Log): () -> ()
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local connections: { RBXScriptConnection } = {}
	local playerConnections: { [Player]: RBXScriptConnection } = {}

	local function add(player: Player)
		if not playerConnections[player] then
			playerConnections[player] = watchPlayer(log, player)
		end
	end
	for _, player in Players:GetPlayers() do
		add(player)
		-- an avatar that's dead goes with its connections, none of them is kept
		if player.Character then
			Util.character(log, player.Name, player.Character)
		end
	end
	table.insert(connections, Players.PlayerAdded:Connect(add))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			local connection = playerConnections[player]
			if connection then
				connection:Disconnect()
			end
			playerConnections[player] = nil
		end)
	)

	local spawnedConnection = AvatarService.Spawned:Connect(function(player: Player, character: Model)
		log:Add("Spawned", player.Name)
		Util.character(log, player.Name, character)
	end)
	local dressedConnection = AvatarService.Dressed:Connect(function(player: Player)
		log:Add("Dressed", player.Name)
	end)
	local activeCharacterConnection = SessionService.ActiveCharacterChanged:Connect(function(player: Player)
		local sessionOpt = SessionService:Get(player)
		log:Add("ActiveCharacterChanged", player.Name, {
			CharacterId = if sessionOpt.IsSome then sessionOpt.Value.Save.ActiveCharacterId else nil,
			IdentityKey = if sessionOpt.IsSome then sessionOpt.Value.ActiveIdentityKey else nil,
		})
	end)
	local inMenuConnection = SessionService.InMenuChanged:Connect(function(player: Player, isInMenu: boolean)
		log:Add("InMenuChanged", player.Name, {
			IsInMenu = isInMenu,
		})
	end)

	-- what clients fire. the network service has no one place a call goes through, but the events themselves are
	-- there to be listened to a second time: every one a service takes has its listener by now, so nothing that was
	-- queued for it lands here instead. what a function is asked + what the server fires back isn't heard this way
	local folder = ReplicatedStorage:FindFirstChild(RemoteDefinition.FOLDER_NAME)
	for _, remote in RemoteDefinition.list() do
		local inst = if folder then folder:FindFirstChild(remote.Name) else nil
		if remote.Kind == "Event" and remote.Direction == "ClientToServer" and inst and inst:IsA("RemoteEvent") then
			table.insert(
				connections,
				inst.OnServerEvent:Connect(function(player: Player, value: unknown)
					log:Add("Remote", player.Name, {
						Name = remote.Name,
						Value = value,
					})
				end)
			)
		end
	end

	return function()
		for _, v in connections do
			v:Disconnect()
		end
		for _, v in playerConnections do
			v:Disconnect()
		end
		table.clear(playerConnections)
		spawnedConnection:Disconnect()
		dressedConnection:Disconnect()
		activeCharacterConnection:Disconnect()
		inMenuConnection:Disconnect()
	end
end

return Util
