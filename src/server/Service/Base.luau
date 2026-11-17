--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type BaseLayout = BaseType.BaseLayout
type PlacedFurniture = BaseType.PlacedFurniture
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
type BaseServiceImpl = {
	__index: BaseServiceImpl,
}
export type BaseService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Layout: BaseLayout, -- todo: one base for everybody until bases are kept per player
		_PlacedCount: number, -- the id of a new piece is made from it
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: BaseServiceImpl
))
-- Constants
local PLACEMENT = FurnitureDefinition.PLACEMENT
-- X + Z are in studs from the middle of the pad
local DEBUG_FURNITURE = table.freeze({
	{ FURNITURE_ID = "sports-car", ZONE_ID = 1, X = 0, Z = -1, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "workbench", ZONE_ID = 2, X = -4, Z = -6, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "gun-rack", ZONE_ID = 2, X = 5, Z = 4, ROTATION_DEG = 90 },
	{ FURNITURE_ID = "suit-display", ZONE_ID = 3, X = -5, Z = -5, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "micro-reactor", ZONE_ID = 3, X = 5, Z = 5, ROTATION_DEG = 45 },
	{ FURNITURE_ID = "round-meeting-table", ZONE_ID = 4, X = 0, Z = 0, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "punching-bag", ZONE_ID = 5, X = -6, Z = 0, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "punching-bag", ZONE_ID = 5, X = 6, Z = 0, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "round-artifact-pedestal", ZONE_ID = 6, X = -4, Z = -4, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "square-artifact-pedestal", ZONE_ID = 6, X = 4, Z = -4, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "rectangular-meeting-table", ZONE_ID = 7, X = 0, Z = 2, ROTATION_DEG = 0 },
	{ FURNITURE_ID = "holographic-projector", ZONE_ID = 7, X = 0, Z = -7, ROTATION_DEG = 0 },
})
-- Variables
-- References
-- Private Functions
local function newDebugLayout(): BaseLayout
	local furniture: { PlacedFurniture } = {}
	for index, CONFIG in DEBUG_FURNITURE do
		table.insert(furniture, {
			Id = `debug-{index}`,
			FurnitureId = CONFIG.FURNITURE_ID,
			ZoneId = CONFIG.ZONE_ID,
			CFrame = CFrame.new(CONFIG.X, PLACEMENT.PAD_HEIGHT_OFFSET, CONFIG.Z)
				* CFrame.Angles(0, math.rad(CONFIG.ROTATION_DEG), 0),
		})
	end
	local out: BaseLayout = {
		ThemeId = ThemeDefinition.DEFAULT_ID,
		Furniture = furniture,
	}
	TableUtil.deepFreeze(out)
	assert(BaseType.BaseLayout(out))
	return out
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

local function getIndex(layout: BaseLayout, placedId: string): number?
	for index, placed in layout.Furniture do
		if placed.Id == placedId then
			return index
		end
	end
	return nil
end

-- every client is told, whoever stands in a residence rebuilds what changed
local function setLayout(self: BaseService, layout: BaseLayout)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	self._Layout = layout
	NetworkService:FireAll(RemoteDefinition.BaseLayoutChanged, layout)
end

local function place(self: BaseService, player: Player, placement: FurniturePlacement): Result<PlacedFurniture, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local definitionRes = FurnitureDefinition.get(placement.FurnitureId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local definition = definitionRes.Value
	-- owning a piece of furniture allows any number of it to be placed
	if not table.find(sessionOpt.Value.Inventory.FurnitureIds, definition.Id) then
		return Result.err(`"{definition.Name}" isn't owned`)
	end
	if #self._Layout.Furniture >= PLACEMENT.MAX_PLACED then
		return Result.err(`a base holds up to {PLACEMENT.MAX_PLACED} pieces`)
	end
	local cframeRes = newCFrame(definition.Id, placement.X, placement.Z, placement.RotationDeg)
	if cframeRes.IsErr then
		return cframeRes
	end
	self._PlacedCount += 1
	local placed: PlacedFurniture = {
		Id = `placed-{self._PlacedCount}`,
		FurnitureId = definition.Id,
		ZoneId = placement.ZoneId,
		CFrame = cframeRes.Value,
	}
	table.freeze(placed)
	setLayout(
		self,
		FreezeUtil.delta(self._Layout, function(t: BaseLayout): BaseLayout
			table.insert(t.Furniture, placed)
			return t
		end)
	)
	return Result.ok(placed)
end

-- the base is shared for now, so a piece can be moved + removed by anybody whoever placed it
local function move(self: BaseService, player: Player, furnitureMove: FurnitureMove): Result<PlacedFurniture, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local index = getIndex(self._Layout, furnitureMove.Id)
	if not index then
		return Result.err(`no piece "{furnitureMove.Id}" is placed`)
	end
	local prior = self._Layout.Furniture[index]
	local cframeRes = newCFrame(prior.FurnitureId, furnitureMove.X, furnitureMove.Z, furnitureMove.RotationDeg)
	if cframeRes.IsErr then
		return cframeRes
	end
	local placed: PlacedFurniture = {
		Id = prior.Id,
		FurnitureId = prior.FurnitureId,
		ZoneId = furnitureMove.ZoneId,
		CFrame = cframeRes.Value,
	}
	table.freeze(placed)
	setLayout(
		self,
		FreezeUtil.delta(self._Layout, function(t: BaseLayout): BaseLayout
			t.Furniture[index] = placed
			return t
		end)
	)
	return Result.ok(placed)
end

local function remove(self: BaseService, player: Player, placedId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local index = getIndex(self._Layout, placedId)
	if not index then
		return Result.err(`no piece "{placedId}" is placed`)
	end
	setLayout(
		self,
		FreezeUtil.delta(self._Layout, function(t: BaseLayout): BaseLayout
			table.remove(t.Furniture, index)
			return t
		end)
	)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

local function setTheme(self: BaseService, player: Player, themeId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local definitionRes = ThemeDefinition.get(themeId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local definition = definitionRes.Value
	if not table.find(sessionOpt.Value.Inventory.ThemeIds, definition.Id) then
		return Result.err(`"{definition.Name}" isn't owned`)
	end
	if self._Layout.ThemeId ~= definition.Id then
		setLayout(
			self,
			FreezeUtil.delta(self._Layout, function(t: BaseLayout): BaseLayout
				t.ThemeId = definition.Id
				return t
			end)
		)
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
-- Class
local BaseService = {} :: BaseServiceImpl
BaseService.__index = BaseService

return ServiceLocker(function(): BaseService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Layout = newDebugLayout(),
		_PlacedCount = 0,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, BaseService)

	NetworkService:Handle(RemoteDefinition.GetBaseLayout, function(): Result<BaseLayout, string>
		return Result.ok(self._Layout)
	end)
	NetworkService:Handle(
		RemoteDefinition.PlaceFurniture,
		function(player: Player, placement: FurniturePlacement): Result<PlacedFurniture, string>
			return place(self, player, placement)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.MoveFurniture,
		function(player: Player, furnitureMove: FurnitureMove): Result<PlacedFurniture, string>
			return move(self, player, furnitureMove)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.RemoveFurniture,
		function(player: Player, placedId: string): Result<true, string>
			return remove(self, player, placedId)
		end
	)
	NetworkService:Handle(RemoteDefinition.SetBaseTheme, function(player: Player, themeId: string): Result<true, string>
		return setTheme(self, player, themeId)
	end)

	return self
end, function(self: BaseService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
