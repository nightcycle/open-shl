--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
type MaskServiceImpl = {
	__index: MaskServiceImpl,
}
export type MaskService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: MaskServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local MaskService = {} :: MaskServiceImpl
MaskService.__index = MaskService

-- a hero takes their mask off + puts it back on. it's a service of its own because a game may have that without the
-- rest of what a player does to their avatar: nothing is kept here, who's unmasked is the avatar service's to know
return ServiceLocker(function(): MaskService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, MaskService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetMasked, function(player: Player, isMasked: boolean)
			-- the avatar service renders the look without the mask, a dress is the only thing that changes items
			AvatarService:SetMasked(player, isMasked)
		end)
	)

	return self
end, function(self: MaskService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
