--!strict
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Item")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local ResidenceType = require("@game/ServerScriptService/Server/Type/Residence")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Appearance = AppearanceType.Appearance
type BaseLayout = BaseType.BaseLayout
type PlacedFurniture = BaseType.PlacedFurniture
type ResidenceId = BaseType.ResidenceId
type Character = CharacterType.Character
type PlayerSave = SaveType.PlayerSave
type Session = SessionService.Session
type ResidenceState = SessionType.ResidenceState
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
type Slot = ResidenceType.Slot
type Rooms = ResidenceType.Rooms
type Rule = ResidenceType.Rule
type ResidenceServiceImpl = {
	__index: ResidenceServiceImpl,
}
export type ResidenceService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Slots: { Slot }, -- in the order they're handed out
		_Owners: { [ResidenceId]: Player },
		_Hosts: { [Player]: Player }, -- whose residence a player is inside of, their own included
		_States: { [Player]: ResidenceState }, -- by owner: what the players inside were told last
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ResidenceServiceImpl
))
-- Constants
local DOORS_PATH = "game/Workspace/Map/buildings/Apartments/Lobby/Doors"
local PLATE_PATH = "Address/SurfaceGui/Frame/TextLabel"
local VACANT_TEXT = "Vacant"
local PLACEMENT = FurnitureDefinition.PLACEMENT
local SUIT_DISPLAY_ID = "suit-display"
local PEDESTAL_IDS = table.freeze({ "round-artifact-pedestal", "square-artifact-pedestal" })
-- a pedestal is a head on a stand, it has nothing else to hang an artifact on
local PEDESTAL_ANCHOR_NAME = "Head"
local ARTIFACT_CATEGORY = "artifacts"
local COSMETICS_GROUP = "cosmetics"
-- Variables
-- References
-- Private Functions
local function getSlots(): { Slot }
	local out: { Slot } = {}
	local doors = IndexUtil.findFirstPath(DOORS_PATH)
	if not doors then
		warn(`the map has no apartments, nobody gets a residence`)
		return out
	end
	for _, door in doors:GetChildren() do
		local plate = IndexUtil.findFirstLocalPath(door, PLATE_PATH)
		if not BaseType.ResidenceId(door.Name) or not plate or not plate:IsA("TextLabel") then
			warn(`"{door.Name}" isn't the door of a residence`)
			continue
		end
		local label: TextLabel = plate
		table.insert(out, {
			Id = door.Name :: ResidenceId,
			-- the plate next to the door in the lobby reads who lives behind it
			SetOwner = function(player: Player?)
				label.Text = if player then player.Name else VACANT_TEXT
			end,
		})
	end
	-- the same order on every server: one column of the tower from the ground up, then the other
	table.sort(out, function(a: Slot, b: Slot): boolean
		local column, otherColumn = string.sub(a.Id, 1, 1), string.sub(b.Id, 1, 1)
		if column ~= otherColumn then
			return column < otherColumn
		end
		return (tonumber(string.sub(a.Id, 2)) or 0) < (tonumber(string.sub(b.Id, 2)) or 0)
	end)
	return out
end

local function getCharacter(save: PlayerSave, characterId: string): Character?
	for _, character in save.Characters do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

local function getIndex(layout: BaseLayout, placedId: string): number?
	for index, placed in layout.Furniture do
		if placed.Id == placedId then
			return index
		end
	end
	return nil
end

-- a suit display wears the costume alone: no hair, no face + no artifact, so nothing the artifact hid stays hidden
local function newCostume(appearance: Appearance): Appearance
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		for i = #t.Items, 1, -1 do
			local indexRes = ItemAppearanceDefinition.getIndex(t.Items[i].DefinitionId)
			if
				indexRes.IsErr
				or indexRes.Value.Group == COSMETICS_GROUP
				or indexRes.Value.Category == ARTIFACT_CATEGORY
			then
				table.remove(t.Items, i)
			end
		end
		table.clear(t.HiddenTags)
		return t
	end)
end

local function newState(residenceId: ResidenceId, owner: Player, save: PlayerSave): ResidenceState
	local costumes: { [string]: Appearance } = {}
	for _, placed in save.BaseLayout.Furniture do
		local characterId = placed.CharacterId
		if not characterId or costumes[characterId] then
			continue
		end
		-- a display that outlived its character shows the first one instead
		local character = getCharacter(save, characterId) or save.Characters[1]
		if character then
			costumes[characterId] = newCostume(character.Identities.Main.Appearance)
		end
	end
	table.freeze(costumes)
	local out: ResidenceState = {
		ResidenceId = residenceId,
		OwnerUserId = owner.UserId,
		Layout = save.BaseLayout,
		Costumes = costumes,
	}
	table.freeze(out)
	return out
end

-- only what the avatar wears on its head right now, with the mask off or as a civilian that's nothing
local function getArtifactId(player: Player): string?
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local appearanceOpt = AvatarService:GetAppearance(player)
	if appearanceOpt.IsNone then
		return nil
	end
	for _, item in appearanceOpt.Value.Items do
		local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if indexRes.IsErr or indexRes.Value.Category ~= ARTIFACT_CATEGORY then
			continue
		end
		local anchorNameRes = ItemUtil.getAnchorName(item.DefinitionId)
		if anchorNameRes.IsOk and anchorNameRes.Value == PEDESTAL_ANCHOR_NAME then
			return item.DefinitionId
		end
	end
	return nil
end

-- nothing is taken from a client as it came: the spot is put on the grid + the footprint has to stay on the pad
local function newCFrame(furnitureId: string, x: number, z: number, rotationDeg: number): Result<CFrame, string>
	local cframe = BaseUtil.newCFrame(x, z, rotationDeg)
	local inBoundsRes = FurnitureDefinition.getIfInBounds(furnitureId, cframe)
	if inBoundsRes.IsErr then
		return inBoundsRes
	end
	if not inBoundsRes.Value then
		return Result.err(`the piece doesn't fit on the pad there`)
	end
	return Result.ok(cframe)
end

-- a base is only built on by its owner + from the inside
local function getSave(rooms: Rooms, player: Player): Result<PlayerSave, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if rooms.GetHost(player) ~= player then
		return Result.err(`{player.Name} isn't in their base`)
	end
	return Result.ok(sessionOpt.Value.Save)
end

local function place(rooms: Rooms, player: Player, placement: FurniturePlacement): Result<PlacedFurniture, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = getSave(rooms, player)
	if saveRes.IsErr then
		return saveRes
	end
	local save = saveRes.Value
	local definitionRes = FurnitureDefinition.get(placement.FurnitureId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local definition = definitionRes.Value
	-- owning a piece of furniture allows any number of it to be placed
	if not table.find(save.Inventory.FurnitureIds, definition.Id) then
		return Result.err(`"{definition.Name}" isn't owned`)
	end
	if #save.BaseLayout.Furniture >= PLACEMENT.MAX_PLACED then
		return Result.err(`a base holds up to {PLACEMENT.MAX_PLACED} pieces`)
	end
	local cframeRes = newCFrame(definition.Id, placement.X, placement.Z, placement.RotationDeg)
	if cframeRes.IsErr then
		return cframeRes
	end
	-- a display keeps showing what its owner was + wore as it was placed
	local placed: PlacedFurniture = {
		Id = HttpService:GenerateGUID(false),
		FurnitureId = definition.Id,
		ZoneId = placement.ZoneId,
		CFrame = cframeRes.Value,
		CharacterId = if definition.Id == SUIT_DISPLAY_ID then save.ActiveCharacterId else nil,
		ArtifactId = if table.find(PEDESTAL_IDS, definition.Id) then getArtifactId(player) else nil,
	}
	local updateRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		table.insert(t.BaseLayout.Furniture, placed)
		return t
	end)
	if updateRes.IsErr then
		return updateRes
	end
	return Result.ok(placed)
end

local function move(rooms: Rooms, player: Player, furnitureMove: FurnitureMove): Result<PlacedFurniture, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = getSave(rooms, player)
	if saveRes.IsErr then
		return saveRes
	end
	local layout = saveRes.Value.BaseLayout
	local index = getIndex(layout, furnitureMove.Id)
	if not index then
		return Result.err(`no piece "{furnitureMove.Id}" is placed`)
	end
	local prior = layout.Furniture[index]
	local cframeRes = newCFrame(prior.FurnitureId, furnitureMove.X, furnitureMove.Z, furnitureMove.RotationDeg)
	if cframeRes.IsErr then
		return cframeRes
	end
	local placed = table.clone(prior)
	placed.ZoneId = furnitureMove.ZoneId
	placed.CFrame = cframeRes.Value
	local updateRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		t.BaseLayout.Furniture[index] = placed
		return t
	end)
	if updateRes.IsErr then
		return updateRes
	end
	return Result.ok(placed)
end

local function remove(rooms: Rooms, player: Player, placedId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = getSave(rooms, player)
	if saveRes.IsErr then
		return saveRes
	end
	local index = getIndex(saveRes.Value.BaseLayout, placedId)
	if not index then
		return Result.err(`no piece "{placedId}" is placed`)
	end
	local updateRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		table.remove(t.BaseLayout.Furniture, index)
		return t
	end)
	if updateRes.IsErr then
		return updateRes
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

local function setTheme(rooms: Rooms, player: Player, themeId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = getSave(rooms, player)
	if saveRes.IsErr then
		return saveRes
	end
	local definitionRes = ThemeDefinition.get(themeId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local definition = definitionRes.Value
	if not table.find(saveRes.Value.Inventory.ThemeIds, definition.Id) then
		return Result.err(`"{definition.Name}" isn't owned`)
	end
	local updateRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		if t.BaseLayout.ThemeId == definition.Id then
			return nil
		end
		t.BaseLayout.ThemeId = definition.Id
		return t
	end)
	if updateRes.IsErr then
		return updateRes
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

local function purchaseFurniture(player: Player, furnitureId: string): Result<true, string>
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local definitionRes = FurnitureDefinition.get(furnitureId)
	if definitionRes.IsErr then
		return definitionRes
	end
	return EconomyService:Purchase(player, definitionRes.Value, function(save: PlayerSave): { string }
		return save.Inventory.FurnitureIds
	end)
end

local function purchaseTheme(player: Player, themeId: string): Result<true, string>
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local definitionRes = ThemeDefinition.get(themeId)
	if definitionRes.IsErr then
		return definitionRes
	end
	return EconomyService:Purchase(player, definitionRes.Value, function(save: PlayerSave): { string }
		return save.Inventory.ThemeIds
	end)
end

-- the requests only this game takes: a base is furnished, + what it's furnished with is sold where it's put
local function start(rooms: Rooms): (() -> ())?
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	NetworkService:Handle(
		RemoteDefinition.PlaceFurniture,
		function(player: Player, placement: FurniturePlacement): Result<PlacedFurniture, string>
			return place(rooms, player, placement)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.MoveFurniture,
		function(player: Player, furnitureMove: FurnitureMove): Result<PlacedFurniture, string>
			return move(rooms, player, furnitureMove)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.RemoveFurniture,
		function(player: Player, placedId: string): Result<true, string>
			return remove(rooms, player, placedId)
		end
	)
	NetworkService:Handle(RemoteDefinition.SetBaseTheme, function(player: Player, themeId: string): Result<true, string>
		return setTheme(rooms, player, themeId)
	end)
	NetworkService:Handle(
		RemoteDefinition.PurchaseFurniture,
		function(player: Player, furnitureId: string): Result<true, string>
			return purchaseFurniture(player, furnitureId)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.PurchaseTheme,
		function(player: Player, themeId: string): Result<true, string>
			return purchaseTheme(player, themeId)
		end
	)
	return nil
end

-- what's one game's own of a residence
local RULE: Rule = table.freeze({
	GetSlots = getSlots,
	-- everybody is given one
	GetIfHoused = function(_save: PlayerSave): boolean
		return true
	end,
	GetIfLocked = function(save: PlayerSave): boolean
		return save.IsApartmentLocked
	end,
	NewState = newState,
	Start = start,
})
assert(ResidenceType.Rule(RULE))

local function assign(self: ResidenceService, player: Player)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	for _, owner in self._Owners do
		if owner == player then
			return
		end
	end
	-- who gets a residence is the game's to say
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone or not RULE.GetIfHoused(sessionOpt.Value.Save) then
		return
	end
	for _, slot in self._Slots do
		if self._Owners[slot.Id] then
			continue
		end
		self._Owners[slot.Id] = player
		slot.SetOwner(player)
		AttributeDefinition.set(player, AttributeDefinition.ResidenceId, slot.Id)
		return
	end
	warn(`every residence is taken, {player.Name} goes without one`)
end

local function leave(self: ResidenceService, player: Player)
	local host = self._Hosts[player]
	if not host then
		return
	end
	self._Hosts[player] = nil
	for _, other in self._Hosts do
		if other == host then
			return
		end
	end
	-- nobody is left to tell of a change
	self._States[host] = nil
end

-- whoever is still inside is walked out by their own client as the owner goes
local function free(self: ResidenceService, player: Player)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	leave(self, player)
	for visitor, host in self._Hosts do
		if host == player then
			self._Hosts[visitor] = nil
		end
	end
	self._States[player] = nil
	for _, slot in self._Slots do
		if self._Owners[slot.Id] == player then
			self._Owners[slot.Id] = nil
			slot.SetOwner(nil)
		end
	end
	-- a client finds the owner of a door by it, the player is still around for a moment as the next one moves in
	AttributeDefinition.set(player, AttributeDefinition.ResidenceId, nil)
	-- somebody who came in while every residence was taken moves in now
	for _, other in Players:GetPlayers() do
		if other ~= player and SessionService:Get(other).IsSome then
			assign(self, other)
		end
	end
end

-- the lock only keeps the door shut, a visitor who's already inside stays
local function enter(self: ResidenceService, player: Player, residenceId: ResidenceId): Result<ResidenceState, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local owner = self._Owners[residenceId]
	local sessionOpt = if owner then SessionService:Get(owner) else nil
	if not owner or not sessionOpt or sessionOpt.IsNone then
		return Result.err(`nobody lives in "{residenceId}"`)
	end
	local save = sessionOpt.Value.Save
	if owner ~= player and RULE.GetIfLocked(save) then
		return Result.err(`the door is locked`)
	end
	leave(self, player)
	local state = RULE.NewState(residenceId, owner, save)
	self._Hosts[player] = owner
	self._States[owner] = state
	return Result.ok(state)
end
-- Class
local ResidenceService = {} :: ResidenceServiceImpl
ResidenceService.__index = ResidenceService

return ServiceLocker(function(): ResidenceService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local slots = RULE.GetSlots()
	for _, slot in slots do
		assert(ResidenceType.Slot(slot))
	end
	local self = setmetatable({
		IsInitialized = true :: true,
		_Slots = slots,
		_Owners = {},
		_Hosts = {},
		_States = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ResidenceService)

	NetworkService:Handle(
		RemoteDefinition.EnterResidence,
		function(player: Player, residenceId: ResidenceId): Result<ResidenceState, string>
			return enter(self, player, residenceId)
		end
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.LeaveResidence, function(player: Player)
			leave(self, player)
		end)
	)
	-- the game's own part asks about who's inside through this, it's never handed the service
	local rooms: Rooms = table.freeze({
		GetHost = function(player: Player): Player?
			return self._Hosts[player]
		end,
	})
	local stop = RULE.Start(rooms)
	if stop then
		table.insert(self._CleanUpCallbacks, stop)
	end

	-- whatever wrote to the save of an owner, the players inside only hear of it when what they see changed
	local changedConnection = SessionService.Changed:Connect(
		function(player: Player, session: Session, priorSession: Session)
			local priorState = self._States[player]
			if not priorState or session.Save == priorSession.Save then
				return
			end
			local state = RULE.NewState(priorState.ResidenceId, player, session.Save)
			if StateUtil.getIfEqual(state, priorState) then
				return
			end
			self._States[player] = state
			for visitor, host in self._Hosts do
				if host == player then
					NetworkService:Fire(RemoteDefinition.ResidenceChanged, visitor, state)
				end
			end
		end
	)
	local addedConnection = SessionService.Added:Connect(function(player: Player)
		assign(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		free(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		changedConnection:Disconnect()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			assign(self, player)
		end
	end

	table.insert(self._CleanUpCallbacks, function()
		for _, slot in self._Slots do
			local owner = self._Owners[slot.Id]
			if owner then
				AttributeDefinition.set(owner, AttributeDefinition.ResidenceId, nil)
			end
			slot.SetOwner(nil)
		end
	end)

	return self
end, function(self: ResidenceService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
