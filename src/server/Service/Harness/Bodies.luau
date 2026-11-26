--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
local Watch = require("@game/ServerScriptService/Server/Service/Harness/Watch")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Log = Log.Log
-- somebody a command is about: the avatar of a player, or a puppet that stands in for the avatar of a second one
export type Body = {
	Name: string, -- of the player, or the one the puppet was given
	Character: Model,
	Player: Player?, -- nil for a puppet + for a body somebody lent
}
-- answers the body of the game's own that goes by a name, nil for a name that isn't one of its
export type Finder = (name: string) -> Model?
type Puppet = {
	Body: Body,
	Connections: { RBXScriptConnection },
}
type BodiesImpl = {
	__index: BodiesImpl,
	-- the player of that name. without one it's whoever is alone on the server
	GetPlayer: (self: Bodies, name: string?) -> Result<Player, string>,
	-- the avatar of a player, a puppet or a body somebody lent, by its name. without one it's the avatar of whoever is
	-- alone on the server
	Get: (self: Bodies, name: string?) -> Result<Body, string>,
	-- a body nobody plays is the game's own (a walker of the npc service): the area that knows them lends them by the
	-- names it lists them under, so a hit or a status can be asked for one. nothing of it is kept or watched here
	Lend: (self: Bodies, find: Finder) -> (),
	ListPuppets: (self: Bodies) -> { Body },
	-- takes a rig in as a puppet: it gets its name + the log hears of it the way it hears of an avatar
	Add: (self: Bodies, rig: Model) -> Body,
	-- takes one puppet out of the world, or all of them. answers how many went
	Remove: (self: Bodies, name: string?) -> number,
	Destroy: (self: Bodies) -> (),
}
export type Bodies = typeof(setmetatable(
	{} :: {
		_Log: Log,
		_Count: number, -- how many puppets were ever taken in, a name is never handed out twice
		_Puppets: { Puppet }, -- in the order they came in
		_Finders: { Finder },
	},
	{} :: BodiesImpl
))
-- Constants
-- no player is called that: a user name has no dash in it
local PUPPET_NAME = "puppet-%d"
-- Variables
-- References
-- Private Functions
local function listPlayerNames(): string
	local names: { string } = {}
	for _, player in Players:GetPlayers() do
		table.insert(names, player.Name)
	end
	table.sort(names)
	return if #names > 0 then table.concat(names, ", ") else "nobody"
end
-- Class
-- who the commands of the server are about, by the names an agent calls them: the players that are in + the puppets
-- the harness put into the world
local Bodies = {} :: BodiesImpl
Bodies.__index = Bodies

function Bodies:GetPlayer(name: string?): Result<Player, string>
	local players = Players:GetPlayers()
	if name == nil then
		if #players ~= 1 then
			return Result.err(`{#players} players are in, name one: {listPlayerNames()}`)
		end
		return Result.ok(players[1])
	end
	for _, player in players do
		if player.Name == name then
			return Result.ok(player)
		end
	end
	return Result.err(`no player "{name}", in are: {listPlayerNames()}`)
end

function Bodies:Get(name: string?): Result<Body, string>
	for _, puppet in self._Puppets do
		if puppet.Body.Name == name then
			if not puppet.Body.Character:IsDescendantOf(game) then
				return Result.err(`"{name}" is gone from the world`)
			end
			return Result.ok(puppet.Body)
		end
	end
	if name then
		for _, find in self._Finders do
			local character = find(name)
			if character then
				return Result.ok(table.freeze({
					Name = name,
					Character = character,
				}))
			end
		end
	end
	local playerRes = self:GetPlayer(name)
	if playerRes.IsErr then
		return Result.err(`{playerRes.Value}, + no puppet of that name`)
	end
	local player = playerRes.Value
	local character = player.Character
	if not character then
		return Result.err(`{player.Name} has no avatar right now`)
	end
	return Result.ok(table.freeze({
		Name = player.Name,
		Character = character,
		Player = player,
	}))
end

function Bodies:Lend(find: Finder)
	table.insert(self._Finders, find)
end

function Bodies:ListPuppets(): { Body }
	local out: { Body } = {}
	for _, puppet in self._Puppets do
		table.insert(out, puppet.Body)
	end
	return out
end

function Bodies:Add(rig: Model): Body
	self._Count += 1
	local name = string.format(PUPPET_NAME, self._Count)
	rig.Name = name
	local body: Body = table.freeze({
		Name = name,
		Character = rig,
	})
	table.insert(self._Puppets, {
		Body = body,
		Connections = Watch.character(self._Log, name, rig),
	})
	return body
end

function Bodies:Remove(name: string?): number
	local count = 0
	for index = #self._Puppets, 1, -1 do
		local puppet = self._Puppets[index]
		if name == nil or puppet.Body.Name == name then
			table.remove(self._Puppets, index)
			for _, v in puppet.Connections do
				v:Disconnect()
			end
			puppet.Body.Character:Destroy()
			count += 1
		end
	end
	return count
end

function Bodies:Destroy()
	self:Remove()
	table.clear(self :: any)
end

return {
	new = function(log: Log): Bodies
		return setmetatable({
			_Log = log,
			_Count = 0,
			_Puppets = {},
			_Finders = {},
		}, Bodies)
	end,
}
