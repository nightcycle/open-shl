--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local Placement = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Placement")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Residence = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Residence")
local ResidenceService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Signal<T...> = Signal.Signal<T...>
type Result<V, E> = TypeUnionLib.Result<V, E>
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
type Placement = Placement.Placement
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
export type PlacedFurniture = BaseType.PlacedFurniture
type BuildServiceImpl = {
	__index: BuildServiceImpl,
	GetFurnitureId: (self: BuildService) -> string?,
	SetFurnitureId: (self: BuildService, furnitureId: string?) -> Result<true, string>,
	GetSelection: (self: BuildService) -> PlacedFurniture?,
	ApplyTheme: (self: BuildService, themeId: string) -> Result<true, string>,
}
export type BuildService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		FurnitureIdChanged: Signal<string?>, -- the furniture the pointer places
		SelectionChanged: Signal<PlacedFurniture?>, -- the placed piece the gizmo floats over
		RequestFailed: Signal<string>, -- the line the server turned a request down with
		_Placement: Placement?, -- only while the base is built on
		_IsRequesting: boolean, -- the server hasn't answered the last request yet
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: BuildServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- one at a time: a step of the gizmo is measured from where the piece stands, which the server has to answer first
local function request<V, T>(self: BuildService, remote: ClientFunction<V, T>, value: T)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	if self._IsRequesting then
		return
	end
	self._IsRequesting = true
	task.spawn(function()
		local res = NetworkService:Invoke(remote, value)
		if not self.IsInitialized then
			return
		end
		self._IsRequesting = false
		if res.IsErr then
			warn(`base request failed: {res.Value}`)
			self.RequestFailed:Fire(res.Value)
		end
	end)
end

local function stopBuilding(self: BuildService)
	local placement = self._Placement
	if not placement then
		return
	end
	self._Placement = nil
	local hadFurnitureId = false
	local hadSelection = false
	if placement.IsAlive then
		hadFurnitureId = placement:GetFurnitureId() ~= nil
		hadSelection = placement:GetSelection() ~= nil
		placement:Destroy()
	end
	if hadFurnitureId then
		self.FurnitureIdChanged:Fire(nil)
	end
	if hadSelection then
		self.SelectionChanged:Fire(nil)
	end
end

local function startBuilding(self: BuildService): Result<true, string>
	assert(ResidenceService.IsInitialized, `the residence service isn't initialized`)
	if not self._Placement then
		-- the service only knows what's behind a door for an interior, build mode needs the residence it is
		local residence = Residence.from(ResidenceService:GetInterior())
		if not residence or not residence.IsAlive then
			return Result.err(`can't build outside of a residence`)
		end
		if residence.State.OwnerUserId ~= Players.LocalPlayer.UserId then
			return Result.err(`can't build in somebody else's residence`)
		end
		local placementRes = Placement.new(residence)
		if placementRes.IsErr then
			return placementRes
		end
		local placement = placementRes.Value
		if not placement.IsAlive then
			return Result.err(`can't build outside of a residence`)
		end
		self._Placement = placement
		-- the connections go with the placement, it takes its signals along as it's destroyed
		placement.PlaceRequested:Connect(function(furniturePlacement: FurniturePlacement)
			request(self, RemoteDefinition.PlaceFurniture, furniturePlacement)
		end)
		placement.MoveRequested:Connect(function(furnitureMove: FurnitureMove)
			request(self, RemoteDefinition.MoveFurniture, furnitureMove)
		end)
		placement.RemoveRequested:Connect(function(placedId: string)
			request(self, RemoteDefinition.RemoveFurniture, placedId)
		end)
		placement.SelectionChanged:Connect(function()
			self.SelectionChanged:Fire(self:GetSelection())
		end)
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
-- Class
local BuildService = {} :: BuildServiceImpl
BuildService.__index = BuildService

function BuildService:GetFurnitureId(): string?
	local placement = self._Placement
	if not placement or not placement.IsAlive then
		return nil
	end
	return placement:GetFurnitureId()
end

function BuildService:SetFurnitureId(furnitureId: string?): Result<true, string>
	local placement = self._Placement
	if not placement or not placement.IsAlive then
		if furnitureId == nil then
			return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
		end
		return Result.err(`the base isn't built on right now`)
	end
	local previousId = placement:GetFurnitureId()
	local res = placement:SetFurnitureId(furnitureId)
	local currentId = placement:GetFurnitureId()
	if previousId ~= currentId then
		self.FurnitureIdChanged:Fire(currentId)
	end
	return res
end

-- the same table until the piece changes
function BuildService:GetSelection(): PlacedFurniture?
	local placement = self._Placement
	if not placement or not placement.IsAlive then
		return nil
	end
	-- the residence that's built on is the one the avatar is inside of: build mode lets go of it before it's left
	local residence = placement.Residence
	if not residence.IsAlive then
		return nil
	end
	local placedId = placement:GetSelection()
	return if placedId then residence:GetPlaced(placedId) else nil
end

function BuildService:ApplyTheme(themeId: string): Result<true, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.SetBaseTheme, themeId)
end

return ServiceLocker(function(): BuildService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(ResidenceService.IsInitialized, `the residence service isn't initialized`)

	local self = setmetatable({
		IsInitialized = true :: true,
		FurnitureIdChanged = Signal.new(),
		SelectionChanged = Signal.new(),
		RequestFailed = Signal.new(),
		_Placement = nil :: Placement?,
		_IsRequesting = false,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, BuildService)

	local panelConnection = ShellService.PanelChanged:Connect(function(panelId: ShellService.PanelId?)
		if panelId ~= "Build" then
			stopBuilding(self)
			return
		end
		local buildingRes = startBuilding(self)
		if buildingRes.IsErr then
			warn(`build err: {buildingRes.Value}`)
		end
	end)
	-- the residence is taken down right after, what's built with holds on to its parts
	local leavingConnection = ResidenceService.Leaving:Connect(function()
		stopBuilding(self)
	end)
	-- a piece that's still picked may stand somewhere else by now
	local stateConnection = ResidenceService.StateChanged:Connect(function()
		local selection = self:GetSelection()
		if selection then
			self.SelectionChanged:Fire(selection)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		panelConnection:Disconnect()
		leavingConnection:Disconnect()
		stateConnection:Disconnect()
		stopBuilding(self)
	end)

	return self
end, function(self: BuildService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.FurnitureIdChanged:Destroy()
	self.SelectionChanged:Destroy()
	self.RequestFailed:Destroy()
	table.clear(self :: any)
end)
