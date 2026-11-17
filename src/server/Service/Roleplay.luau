--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local ExpressionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Expression")
local FaceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Face")
local ItemUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Item")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type ExpressionId = ExpressionDefinition.ExpressionId
type PlayerSave = SaveType.PlayerSave
type Session = SessionService.Session
-- none of it is saved. it belongs to the player rather than to the avatar, so it's still there after a respawn
type Roleplay = {
	ExpressionId: ExpressionId?,
	IsHandcuffed: boolean,
	Handcuffs: Instance?, -- the pair the avatar wears right now
}
type RoleplayServiceImpl = {
	__index: RoleplayServiceImpl,
}
export type RoleplayService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Roleplays: { [Player]: Roleplay },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: RoleplayServiceImpl
))
-- Constants
-- Variables
-- References
local HandcuffsTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/prop/handcuffs") :: Model
-- Private Functions
-- an expression only overrides the face the avatar is dressed in, without one that face is drawn again
local function applyExpression(player: Player, character: Model, roleplay: Roleplay)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	AttributeDefinition.set(character, AttributeDefinition.ExpressionId, roleplay.ExpressionId)
	local faceRes: Result<true, string> = Result.err(`{player.Name} has no face to draw`)
	if roleplay.ExpressionId then
		local definitionRes = ExpressionDefinition.get(roleplay.ExpressionId)
		if definitionRes.IsOk then
			faceRes = FaceUtil.set(character, definitionRes.Value.DefinitionIds)
		else
			faceRes = Result.err(definitionRes.Value)
		end
	else
		local appearanceOpt = AvatarService:GetAppearance(player)
		if appearanceOpt.IsSome then
			faceRes = AppearanceUtil.applyFace(character, appearanceOpt.Value)
		end
	end
	if faceRes.IsErr then
		warn(`expression err: {faceRes.Value}`)
	end
end

-- the handcuffs are worn like an item, so a dress takes them off along with everything else
local function applyHandcuffs(character: Model, roleplay: Roleplay)
	AttributeDefinition.set(character, AttributeDefinition.IsHandcuffed, roleplay.IsHandcuffed)
	if roleplay.Handcuffs then
		roleplay.Handcuffs:Destroy()
		roleplay.Handcuffs = nil
	end
	if not roleplay.IsHandcuffed then
		return
	end
	local handcuffsRes = ItemUtil.applyTemplate(character, HandcuffsTemplate)
	if handcuffsRes.IsErr then
		warn(`handcuffs err: {handcuffsRes.Value}`)
		return
	end
	roleplay.Handcuffs = handcuffsRes.Value
end

local function add(self: RoleplayService, player: Player)
	if self._Roleplays[player] then
		return
	end
	self._Roleplays[player] = {
		IsHandcuffed = false,
	}
end
-- Class
local RoleplayService = {} :: RoleplayServiceImpl
RoleplayService.__index = RoleplayService

return ServiceLocker(function(): RoleplayService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Roleplays = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, RoleplayService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetExpression, function(player: Player, expressionId: ExpressionId?)
			local roleplay = self._Roleplays[player]
			if not roleplay then
				return
			end
			roleplay.ExpressionId = expressionId
			if player.Character then
				applyExpression(player, player.Character, roleplay)
			end
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetMasked, function(player: Player, isMasked: boolean)
			-- the avatar service renders the look without the mask, a dress is the only thing that changes items
			AvatarService:SetMasked(player, isMasked)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetHandcuffed, function(player: Player, isHandcuffed: boolean)
			local roleplay = self._Roleplays[player]
			if not roleplay or roleplay.IsHandcuffed == isHandcuffed then
				return
			end
			roleplay.IsHandcuffed = isHandcuffed
			if player.Character then
				applyHandcuffs(player.Character, roleplay)
			end
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetApartmentLocked, function(player: Player, isLocked: boolean)
			local saveRes = SessionService:Update(player, function(save: PlayerSave): PlayerSave?
				if save.IsApartmentLocked == isLocked then
					return nil
				end
				save.IsApartmentLocked = isLocked
				return save
			end)
			if saveRes.IsErr then
				warn(`apartment lock err: {saveRes.Value}`)
			end
		end)
	)

	-- a dress draws the saved face + takes every item off, whatever the player has going is put back on top
	local dressedConnection = AvatarService.Dressed:Connect(function(player: Player, character: Model)
		local roleplay = self._Roleplays[player]
		if not roleplay then
			return
		end
		applyExpression(player, character, roleplay)
		applyHandcuffs(character, roleplay)
	end)
	-- an expression is the mood of one character, another one starts out with the face it was saved with
	local changedConnection = SessionService.Changed:Connect(
		function(player: Player, session: Session, priorSession: Session)
			local roleplay = self._Roleplays[player]
			if not roleplay or session.Save.ActiveCharacterId == priorSession.Save.ActiveCharacterId then
				return
			end
			roleplay.ExpressionId = nil
			if player.Character then
				AttributeDefinition.set(player.Character, AttributeDefinition.ExpressionId, nil)
			end
		end
	)
	local addedConnection = SessionService.Added:Connect(function(player: Player)
		add(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		self._Roleplays[player] = nil
	end)
	table.insert(self._CleanUpCallbacks, function()
		dressedConnection:Disconnect()
		changedConnection:Disconnect()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			add(self, player)
		end
	end

	return self
end, function(self: RoleplayService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
