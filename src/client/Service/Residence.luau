--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local Placement = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Placement")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Residence = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Residence")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Signal<T...> = Signal.Signal<T...>
type Result<V, E> = TypeUnionLib.Result<V, E>
type ClientFunction<V, T> = RemoteDefinition.ClientFunction<V, T>
type Placement = Placement.Placement
type Residence = Residence.Residence
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
type BaseLayout = BaseType.BaseLayout
export type PlacedFurniture = BaseType.PlacedFurniture
type Door = {
	Trigger: BasePart,
	Doorstep: CFrame, -- where the avatar is put as it leaves, its back to the door
	Anchor: CFrame, -- where the residence is built
	Parent: Instance, -- what the residence is put under
}
type ResidenceServiceImpl = {
	__index: ResidenceServiceImpl,
	GetFurnitureId: (self: ResidenceService) -> string?,
	SetFurnitureId: (self: ResidenceService, furnitureId: string?) -> Result<true, string>,
	GetSelection: (self: ResidenceService) -> PlacedFurniture?,
	ApplyTheme: (self: ResidenceService, themeId: string) -> Result<true, string>,
}
export type ResidenceService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		FurnitureIdChanged: Signal<string?>, -- the furniture the pointer places
		SelectionChanged: Signal<PlacedFurniture?>, -- the placed piece the gizmo floats over
		RequestFailed: Signal<string>, -- the line the server turned a request down with
		_Door: Door?,
		_Residence: Residence?, -- only while the avatar is inside
		_Placement: Placement?, -- only while the base is built on
		_IsRequesting: boolean, -- the server hasn't answered the last request yet
		_TeleportTime: number,
		_ResidenceConnections: { RBXScriptConnection }, -- the triggers of the residence
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ResidenceServiceImpl
))
-- Constants
local MAP_PATH = "game/Workspace/Map"
local APARTMENTS_PATH = "buildings/Apartments"
-- todo: one shared residence until the server hands them out per player
local RESIDENCE_NAME = "N3"
local DOOR_TRIGGER_PATH = `{APARTMENTS_PATH}/Lobby/Doors/{RESIDENCE_NAME}/Part`
local DOOR_PLATE_PATH = `{APARTMENTS_PATH}/Lobby/Doors/{RESIDENCE_NAME}/Address`
local DOOR_LABEL_PATH = "SurfaceGui/Frame/TextLabel"
local ANCHOR_PATH = `{APARTMENTS_PATH}/Residences/{RESIDENCE_NAME}/Anchor`
local LOBBY_TRIGGER_PATH = `{APARTMENTS_PATH}/Trigz`
-- the value under a trigger that holds the part it leads to
local EXIT_NAME = "Exit"
-- without it a trigger would send the avatar right back to where it just came from
local TELEPORT_COOLDOWN = 3
local DOORSTEP_DISTANCE = 4
local PRESENCE_INTERVAL = 0.5
local PRESENCE_MARGIN = 8
-- further than the avatar walks between two looks, or it'd be pulled back to the doorstep
local DOORSTEP_RADIUS = 12
-- Variables
-- References
-- Private Functions
local function tryPart(root: Instance, path: string): Result<BasePart, string>
	local instRes = IndexUtil.tryFirstLocalPath(root, path)
	if instRes.IsErr then
		return instRes
	end
	local inst = instRes.Value
	if not inst:IsA("BasePart") then
		return Result.err(`expected a BasePart at "{path}", received a {inst.ClassName}`)
	end
	return Result.ok(inst)
end

local function getIfAvatar(hit: BasePart): boolean
	local avatar = Players.LocalPlayer.Character
	if not avatar or not hit:IsDescendantOf(avatar) then
		return false
	end
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- the avatar lands with its back to the trigger that leads back, kept upright
local function getLanding(exit: BasePart, behind: BasePart): CFrame
	local position = exit.Position
	local offset = (position - behind.Position) * Vector3.new(1, 0, 1)
	if offset.Magnitude < 1e-3 then
		return CFrame.new(position)
	end
	return CFrame.lookAt(position, position + offset)
end

-- the plate with the name of the owner hangs on the side of the door the lobby is on
local function getDoorstep(door: BasePart, plate: BasePart): CFrame
	local out = door.CFrame.LookVector
	if (plate.Position - door.Position):Dot(out) < 0 then
		out = -out
	end
	local position = door.Position + out * DOORSTEP_DISTANCE
	return CFrame.lookAt(position, position + out)
end

local function getIfReady(self: ResidenceService): boolean
	return os.clock() - self._TeleportTime >= TELEPORT_COOLDOWN
end

local function teleport(self: ResidenceService, cframe: CFrame): boolean
	local avatar = Players.LocalPlayer.Character
	if not avatar or not avatar.PrimaryPart then
		return false
	end
	self._TeleportTime = os.clock()
	avatar:PivotTo(cframe)
	return true
end

local function bind(connections: { RBXScriptConnection }, trigger: BasePart, onTouched: () -> ())
	table.insert(
		connections,
		trigger.Touched:Connect(function(hit: BasePart)
			if getIfAvatar(hit) then
				onTouched()
			end
		end)
	)
end

-- one at a time: a step of the gizmo is measured from where the piece stands, which the server has to answer first
local function request<V, T>(self: ResidenceService, remote: ClientFunction<V, T>, value: T)
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

local function stopBuilding(self: ResidenceService)
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

local function startBuilding(self: ResidenceService): Result<true, string>
	if not self._Placement then
		local residence = self._Residence
		if not residence or not residence.IsAlive then
			return Result.err(`can't build outside of a residence`)
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

local function leave(self: ResidenceService)
	stopBuilding(self)
	for _, v in self._ResidenceConnections do
		v:Disconnect()
	end
	table.clear(self._ResidenceConnections)
	local residence = self._Residence
	self._Residence = nil
	if residence and residence.IsAlive then
		residence:Destroy()
	end
	if ShellService.IsInitialized then
		ShellService:SetIsInResidence(false)
	end
end

local function walkOut(self: ResidenceService)
	local door = self._Door
	if not door or not getIfReady(self) then
		return
	end
	if teleport(self, door.Doorstep) then
		leave(self)
	end
end

-- the floors only exist on this client, an avatar the server moves drops through them + is put on the doorstep
local function watch(self: ResidenceService, bounds: CFrame, limit: Vector3)
	local door = self._Door
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	-- a dead avatar lies where it fell, the residence goes once it's removed
	if not door or not avatar or not humanoid or humanoid.Health <= 0 then
		return
	end
	local position = avatar:GetPivot().Position
	local offset = bounds:PointToObjectSpace(position)
	if math.abs(offset.X) <= limit.X and math.abs(offset.Y) <= limit.Y and math.abs(offset.Z) <= limit.Z then
		return
	end
	if (position - door.Doorstep.Position).Magnitude <= DOORSTEP_RADIUS then
		leave(self)
		return
	end
	teleport(self, door.Doorstep)
end

local function bindResidence(self: ResidenceService, residence: Residence)
	if not residence.IsAlive then
		return
	end
	local connections = self._ResidenceConnections
	local bounds, size = residence.Frame:GetBoundingBox()
	local limit = size / 2 + Vector3.one * PRESENCE_MARGIN
	local elapsed = 0
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed < PRESENCE_INTERVAL then
				return
			end
			elapsed = 0
			watch(self, bounds, limit)
		end)
	)
	bind(connections, residence.Exit, function()
		walkOut(self)
	end)
	for _, passage in residence.Passages do
		bind(connections, passage.Trigger, function()
			if not getIfReady(self) or not teleport(self, getLanding(passage.Exit, passage.Return)) then
				return
			end
			if passage.IsToBase and ShellService.IsInitialized then
				ShellService:FireTutorialTrigger("BaseEntered")
			end
		end)
	end
	bind(connections, residence.ShelfTrigger, function()
		if residence.IsAlive then
			residence:OpenShelf()
		end
	end)
end

local function walkIn(self: ResidenceService)
	local door = self._Door
	if not door or self._Residence or not SessionService.IsInitialized or not ShellService.IsInitialized then
		return
	end
	local residenceRes = Residence.new(door.Anchor, SessionService:GetBaseLayout(), door.Parent)
	if residenceRes.IsErr then
		warn(`residence err: {residenceRes.Value}`)
		return
	end
	local residence = residenceRes.Value
	self._Residence = residence
	bindResidence(self, residence)
	if not residence.IsAlive or not teleport(self, getLanding(residence.Entrance, residence.Exit)) then
		leave(self)
		return
	end
	ShellService:SetIsInResidence(true)
	ShellService:FireTutorialTrigger("ApartmentEntered")
end

local function bindTeleports(self: ResidenceService, map: Instance)
	local apartments = IndexUtil.findFirstLocalPath(map, APARTMENTS_PATH)
	local lobbyTrigger = IndexUtil.findFirstLocalPath(map, LOBBY_TRIGGER_PATH)
	for _, desc in map:GetDescendants() do
		if desc.Name ~= EXIT_NAME or not desc:IsA("ObjectValue") then
			continue
		end
		local trigger = desc.Parent
		local exit = desc.Value
		if not trigger or not trigger:IsA("BasePart") or not exit or not exit:IsA("BasePart") then
			continue
		end
		-- the way back sits next to the exit under the same name
		local behind = exit.Parent and exit.Parent:FindFirstChild(trigger.Name)
		if not behind or not behind:IsA("BasePart") then
			warn(`the exit of {trigger:GetFullName()} has no trigger next to it`)
			continue
		end
		local isCooledDown = apartments ~= nil and trigger:IsDescendantOf(apartments)
		bind(self._Connections, trigger, function()
			if isCooledDown and not getIfReady(self) then
				return
			end
			if not teleport(self, getLanding(exit, behind)) then
				return
			end
			if trigger == lobbyTrigger and ShellService.IsInitialized then
				ShellService:FireTutorialTrigger("LobbyEntered")
			end
		end)
	end
end

local function bindDoor(self: ResidenceService, map: Instance)
	local triggerRes = tryPart(map, DOOR_TRIGGER_PATH)
	local plateRes = tryPart(map, DOOR_PLATE_PATH)
	local anchorRes = tryPart(map, ANCHOR_PATH)
	if triggerRes.IsErr or plateRes.IsErr or anchorRes.IsErr then
		warn(`the map has no door to a residence`)
		return
	end
	local door: Door = {
		Trigger = triggerRes.Value,
		Doorstep = getDoorstep(triggerRes.Value, plateRes.Value),
		Anchor = anchorRes.Value.CFrame,
		Parent = anchorRes.Value.Parent or map,
	}
	table.freeze(door)
	self._Door = door
	bind(self._Connections, door.Trigger, function()
		walkIn(self)
	end)
	-- the tutorial sends the player looking for their name next to the door
	local label = IndexUtil.findFirstLocalPath(plateRes.Value, DOOR_LABEL_PATH)
	if label and label:IsA("TextLabel") then
		local text = label.Text
		label.Text = Players.LocalPlayer.Name
		table.insert(self._CleanUpCallbacks, function()
			label.Text = text
		end)
	end
end
-- Class
local ResidenceService = {} :: ResidenceServiceImpl
ResidenceService.__index = ResidenceService

function ResidenceService:GetFurnitureId(): string?
	local placement = self._Placement
	if not placement or not placement.IsAlive then
		return nil
	end
	return placement:GetFurnitureId()
end

function ResidenceService:SetFurnitureId(furnitureId: string?): Result<true, string>
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
function ResidenceService:GetSelection(): PlacedFurniture?
	local placement = self._Placement
	local residence = self._Residence
	if not placement or not placement.IsAlive or not residence or not residence.IsAlive then
		return nil
	end
	local placedId = placement:GetSelection()
	return if placedId then residence:GetPlaced(placedId) else nil
end

function ResidenceService:ApplyTheme(themeId: string): Result<true, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.SetBaseTheme, themeId)
end

return ServiceLocker(function(): ResidenceService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)

	local self = setmetatable({
		IsInitialized = true :: true,
		FurnitureIdChanged = Signal.new(),
		SelectionChanged = Signal.new(),
		RequestFailed = Signal.new(),
		_Door = nil :: Door?,
		_Residence = nil :: Residence?,
		_Placement = nil :: Placement?,
		_IsRequesting = false,
		_TeleportTime = -TELEPORT_COOLDOWN,
		_ResidenceConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ResidenceService)

	local layoutConnection = SessionService.BaseLayoutChanged:Connect(function(layout: BaseLayout)
		local residence = self._Residence
		if not residence or not residence.IsAlive then
			return
		end
		residence:SetLayout(layout)
		-- a piece that's still picked may stand somewhere else by now
		local selection = self:GetSelection()
		if selection then
			self.SelectionChanged:Fire(selection)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		layoutConnection:Disconnect()
	end)
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
	table.insert(self._CleanUpCallbacks, function()
		panelConnection:Disconnect()
	end)
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterRemoving:Connect(function()
			leave(self)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		leave(self)
	end)

	-- the map is still on its way in when the client starts, its triggers are looked for once all of it is there
	task.spawn(function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		local mapF = Future.awaitUntil(IndexUtil.getFuturePath(MAP_PATH), function(): boolean
			return not self.IsInitialized
		end)
		if not mapF.IsDone or not self.IsInitialized then
			return
		end
		bindTeleports(self, mapF.Value)
		bindDoor(self, mapF.Value)
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
	self.FurnitureIdChanged:Destroy()
	self.SelectionChanged:Destroy()
	self.RequestFailed:Destroy()
	table.clear(self :: any)
end)
