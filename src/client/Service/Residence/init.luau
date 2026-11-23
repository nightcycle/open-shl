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
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Residence = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Residence")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local ResidenceType = require("@self/Types")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Signal<T...> = Signal.Signal<T...>
type Result<V, E> = TypeUnionLib.Result<V, E>
type ResidenceId = BaseType.ResidenceId
export type ResidenceState = SessionType.ResidenceState
export type Interior = ResidenceType.Interior
type Door = ResidenceType.Door
type Walk = ResidenceType.Walk
type Rule = ResidenceType.Rule
type ResidenceServiceImpl = {
	__index: ResidenceServiceImpl,
	GetState: (self: ResidenceService) -> ResidenceState?,
	GetInterior: (self: ResidenceService) -> Interior?,
}
export type ResidenceService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		StateChanged: Signal<ResidenceState?>, -- of the residence the avatar is inside of
		Leaving: Signal<>, -- the residence the avatar is inside of is about to be taken down
		_Door: Door?, -- the one the avatar came in through
		_Residence: Interior?, -- only while the avatar is inside
		_Walk: Walk, -- what the game's part of the residences gets around by
		_IsEntering: boolean, -- the server hasn't said yet if the door opens
		_PendingState: ResidenceState?, -- a change that got here ahead of the answer it follows
		_TeleportTime: number,
		_ResidenceConnections: { RBXScriptConnection }, -- the way out of the residence + the look at where the avatar is
		_OnLeft: (() -> ())?, -- takes back what the game put into the residence for whoever is inside
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ResidenceServiceImpl
))
-- Constants
local MAP_PATH = "game/Workspace/Map"
local APARTMENTS_PATH = "buildings/Apartments"
local DOORS_PATH = `{APARTMENTS_PATH}/Lobby/Doors`
local DOOR_TRIGGER_NAME = "Part"
local DOOR_PLATE_NAME = "Address"
local ANCHORS_PATH = `{APARTMENTS_PATH}/Residences`
local ANCHOR_NAME = "Anchor"
local LOBBY_TRIGGER_PATH = `{APARTMENTS_PATH}/Trigz`
-- the value under a trigger that holds the part it leads to
local EXIT_NAME = "Exit"
local DOORSTEP_DISTANCE = 4
-- without it a trigger would send the avatar right back to where it just came from
local TELEPORT_COOLDOWN = 3
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

-- the plate with the name of the owner hangs on the side of the door the lobby is on
local function getDoorstep(door: BasePart, plate: BasePart): CFrame
	local out = door.CFrame.LookVector
	if (plate.Position - door.Position):Dot(out) < 0 then
		out = -out
	end
	local position = door.Position + out * DOORSTEP_DISTANCE
	return CFrame.lookAt(position, position + out)
end

-- a client only has the parts of the map around its avatar, so a teleport is bound as its trigger gets here + where it
-- leads is looked at once it's stepped on: the other side may show up later than the trigger did
local function bindTeleport(
	walk: Walk,
	connections: { RBXScriptConnection },
	triggers: { [BasePart]: true },
	map: Instance,
	desc: Instance
)
	if desc.Name ~= EXIT_NAME or not desc:IsA("ObjectValue") then
		return
	end
	local trigger = desc.Parent
	-- a trigger that left + came back is still bound from the first time
	if not trigger or not trigger:IsA("BasePart") or triggers[trigger] then
		return
	end
	triggers[trigger] = true
	table.insert(
		connections,
		walk.Bind(trigger, function()
			local exit = desc.Value
			-- the way back sits next to the exit under the same name
			local behind = exit and exit.Parent and exit.Parent:FindFirstChild(trigger.Name)
			if not exit or not exit:IsA("BasePart") or not behind or not behind:IsA("BasePart") then
				return
			end
			local apartments = IndexUtil.findFirstLocalPath(map, APARTMENTS_PATH)
			if apartments and trigger:IsDescendantOf(apartments) and not walk.GetIfReady() then
				return
			end
			if not walk.Land(exit, behind) then
				return
			end
			if trigger == IndexUtil.findFirstLocalPath(map, LOBBY_TRIGGER_PATH) and ShellService.IsInitialized then
				ShellService:FireTutorialTrigger("LobbyEntered")
			end
		end)
	)
end

-- every door of the lobby leads to the residence of the same name, whoever lives there
local function bindDoors(
	walk: Walk,
	connections: { RBXScriptConnection },
	enter: (door: Door) -> (),
	doors: Instance,
	anchors: Instance
)
	for _, inst in doors:GetChildren() do
		local triggerRes = tryPart(inst, DOOR_TRIGGER_NAME)
		local plateRes = tryPart(inst, DOOR_PLATE_NAME)
		local anchorRes = tryPart(anchors, `{inst.Name}/{ANCHOR_NAME}`)
		if not BaseType.ResidenceId(inst.Name) or triggerRes.IsErr or plateRes.IsErr or anchorRes.IsErr then
			warn(`"{inst.Name}" isn't the door of a residence`)
			continue
		end
		local door: Door = {
			ResidenceId = inst.Name :: ResidenceId,
			Doorstep = getDoorstep(triggerRes.Value, plateRes.Value),
			Anchor = anchorRes.Value.CFrame,
			Parent = anchorRes.Value.Parent or anchors,
		}
		table.freeze(door)
		table.insert(
			connections,
			walk.Bind(triggerRes.Value, function()
				enter(door)
			end)
		)
	end
end
local RULE: Rule = table.freeze({
	Bind = function(walk: Walk, enter: (door: Door) -> ()): () -> ()
		assert(ShellService.IsInitialized, `the shell service isn't initialized`)
		local connections: { RBXScriptConnection } = {}
		-- the teleports of the map that are bound
		local triggers: { [BasePart]: true } = {}
		local isBound = true
		local function getIfUnbound(): boolean
			return not isBound
		end
		-- the map is still on its way in when the client starts + what's far from the avatar may never get here
		task.spawn(function()
			local mapF = Future.awaitUntil(IndexUtil.getFuturePath(MAP_PATH), getIfUnbound)
			if not mapF.IsDone or not isBound then
				return
			end
			local map = mapF.Value
			table.insert(
				connections,
				map.DescendantAdded:Connect(function(desc: Instance)
					bindTeleport(walk, connections, triggers, map, desc)
				end)
			)
			for _, desc in map:GetDescendants() do
				bindTeleport(walk, connections, triggers, map, desc)
			end
		end)
		-- the doors + what they lead to are persistent in the map: every client has all of them, wherever its avatar is.
		-- not every map has residences, so nothing waits on them
		task.spawn(function()
			-- a map that isn't streamed comes in piece by piece, its doors are only all there once the game is
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			local doorsF = Future.awaitUntil(IndexUtil.getFuturePath(`{MAP_PATH}/{DOORS_PATH}`), getIfUnbound)
			local anchorsF = Future.awaitUntil(IndexUtil.getFuturePath(`{MAP_PATH}/{ANCHORS_PATH}`), getIfUnbound)
			if not doorsF.IsDone or not anchorsF.IsDone or not isBound then
				return
			end
			bindDoors(walk, connections, enter, doorsF.Value, anchorsF.Value)
		end)
		return function()
			isBound = false
			for _, v in connections do
				v:Disconnect()
			end
			table.clear(connections)
		end
	end,
	NewInterior = function(anchor: CFrame, state: ResidenceState, parent: Instance): Result<Interior, string>
		return Residence.new(anchor, state, parent) :: any
	end,
	GetBounds = function(interior: Interior): (CFrame, Vector3)
		local residence = Residence.from(interior)
		assert(residence and residence.IsAlive, `there's no residence to stay in`)
		return residence.Frame:GetBoundingBox()
	end,
	Entered = function(interior: Interior, isOwn: boolean, walk: Walk): (() -> ())?
		local residence = Residence.from(interior)
		local connections: { RBXScriptConnection } = {}
		if residence and residence.IsAlive then
			for _, passage in residence.Passages do
				table.insert(
					connections,
					walk.Bind(passage.Trigger, function()
						if not walk.GetIfReady() or not walk.Land(passage.Exit, passage.Return) then
							return
						end
						if passage.IsToBase and isOwn and ShellService.IsInitialized then
							ShellService:FireTutorialTrigger("BaseEntered")
						end
					end)
				)
			end
			table.insert(
				connections,
				walk.Bind(residence.ShelfTrigger, function()
					if residence.IsAlive then
						residence:OpenShelf()
					end
				end)
			)
		end
		-- a visitor looks around, the base is only built on by whoever it belongs to
		if isOwn and ShellService.IsInitialized then
			ShellService:SetIsInResidence(true)
			ShellService:FireTutorialTrigger("ApartmentEntered")
		end
		return function()
			for _, v in connections do
				v:Disconnect()
			end
			table.clear(connections)
			if ShellService.IsInitialized then
				ShellService:SetIsInResidence(false)
			end
		end
	end,
})
assert(ResidenceType.Rule(RULE))

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

-- the server says who lives where through an attribute on every player
local function getOwner(residenceId: ResidenceId): Player?
	for _, player in Players:GetPlayers() do
		if AttributeDefinition.get(player, AttributeDefinition.ResidenceId) == residenceId then
			return player
		end
	end
	return nil
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

local function bind(trigger: BasePart, onTouched: () -> ()): RBXScriptConnection
	return trigger.Touched:Connect(function(hit: BasePart)
		if getIfAvatar(hit) then
			onTouched()
		end
	end)
end

local function leave(self: ResidenceService)
	-- whatever holds on to the parts of the residence lets go of them before it's taken down
	if self._Residence then
		self.Leaving:Fire()
	end
	for _, v in self._ResidenceConnections do
		v:Disconnect()
	end
	table.clear(self._ResidenceConnections)
	local residence = self._Residence
	self._Residence = nil
	self._Door = nil
	if residence then
		if residence.IsAlive then
			residence:Destroy()
		end
		-- the server stops telling of changes to a residence nobody looks at
		if NetworkService.IsInitialized then
			NetworkService:Fire(RemoteDefinition.LeaveResidence, nil)
		end
		self.StateChanged:Fire(nil)
	end
	local onLeft = self._OnLeft
	self._OnLeft = nil
	if onLeft then
		onLeft()
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

local function bindResidence(self: ResidenceService, residence: Interior)
	if not residence.IsAlive then
		return
	end
	local connections = self._ResidenceConnections
	local bounds, size = RULE.GetBounds(residence)
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
	table.insert(
		connections,
		bind(residence.Exit, function()
			walkOut(self)
		end)
	)
end

local function moveIn(self: ResidenceService, door: Door, state: ResidenceState)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local residenceRes = RULE.NewInterior(door.Anchor, state, door.Parent)
	if residenceRes.IsErr then
		warn(`residence err: {residenceRes.Value}`)
		NetworkService:Fire(RemoteDefinition.LeaveResidence, nil)
		return
	end
	local residence = residenceRes.Value
	if residence.IsAlive then
		assert(ResidenceType.Interior(residence))
	end
	local isOwn = state.OwnerUserId == Players.LocalPlayer.UserId
	self._Door = door
	self._Residence = residence
	bindResidence(self, residence)
	if not residence.IsAlive or not teleport(self, getLanding(residence.Entrance, residence.Exit)) then
		leave(self)
		return
	end
	self.StateChanged:Fire(state)
	self._OnLeft = RULE.Entered(residence, isOwn, self._Walk)
end

-- a door nobody lives behind stays shut, so does a locked one for anybody but its owner
local function walkIn(self: ResidenceService, door: Door)
	assert(ResidenceType.Door(door))
	if self._IsEntering or self._Residence or not getIfReady(self) or not NetworkService.IsInitialized then
		return
	end
	local owner = getOwner(door.ResidenceId)
	if not owner then
		return
	end
	if owner ~= Players.LocalPlayer and AttributeDefinition.get(owner, AttributeDefinition.IsApartmentLocked) then
		return
	end
	local avatar = Players.LocalPlayer.Character
	self._IsEntering = true
	-- a door the server keeps shut after all isn't asked for again with every step the avatar takes on it
	self._TeleportTime = os.clock()
	task.spawn(function()
		local stateRes = NetworkService:Invoke(RemoteDefinition.EnterResidence, door.ResidenceId)
		if not self.IsInitialized then
			return
		end
		self._IsEntering = false
		local pendingState = self._PendingState
		self._PendingState = nil
		if stateRes.IsErr then
			warn(`residence err: {stateRes.Value}`)
			return
		end
		-- the server only tells of a change behind a door it opened, so one that's here already is the newer of the two
		local state = if pendingState and pendingState.ResidenceId == door.ResidenceId
			then pendingState
			else stateRes.Value
		-- the avatar that stood at the door may have died since, the one after it spawned far from here. the owner may
		-- have left since as well, a residence built now would stand for good as nobody says they're gone a second time
		if Players.LocalPlayer.Character ~= avatar or not Players:GetPlayerByUserId(state.OwnerUserId) then
			NetworkService:Fire(RemoteDefinition.LeaveResidence, nil)
			return
		end
		moveIn(self, door, state)
	end)
end

-- Class
local ResidenceService = {} :: ResidenceServiceImpl
ResidenceService.__index = ResidenceService

-- the same table until the server tells of a change
function ResidenceService:GetState(): ResidenceState?
	local residence = self._Residence
	if not residence or not residence.IsAlive then
		return nil
	end
	return residence.State
end

-- what the avatar is inside of
function ResidenceService:GetInterior(): Interior?
	local residence = self._Residence
	if not residence or not residence.IsAlive then
		return nil
	end
	return residence
end

return ServiceLocker(function(): ResidenceService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)

	local self = setmetatable({
		IsInitialized = true :: true,
		StateChanged = Signal.new() :: Signal<ResidenceState?>,
		Leaving = Signal.new() :: Signal<>,
		_Door = nil :: Door?,
		_Residence = nil :: Interior?,
		_Walk = nil :: any,
		_IsEntering = false,
		_PendingState = nil :: ResidenceState?,
		_TeleportTime = -TELEPORT_COOLDOWN,
		_ResidenceConnections = {},
		_OnLeft = nil :: (() -> ())?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ResidenceService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.ResidenceChanged, function(state: ResidenceState)
			local residence = self._Residence
			if not residence or not residence.IsAlive then
				-- nothing says the answer of a door gets here before the first change behind it does
				if self._IsEntering then
					self._PendingState = state
				end
				return
			end
			if residence.State.ResidenceId ~= state.ResidenceId then
				return
			end
			residence:SetState(state)
			self.StateChanged:Fire(state)
		end)
	)
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterRemoving:Connect(function()
			leave(self)
		end)
	)
	-- a residence goes with its owner, whoever is visiting is put back in front of the door
	table.insert(
		self._Connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			local residence = self._Residence
			local door = self._Door
			if not residence or not residence.IsAlive or residence.State.OwnerUserId ~= player.UserId then
				return
			end
			if door then
				teleport(self, door.Doorstep)
			end
			leave(self)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		leave(self)
	end)

	local walk: Walk = {
		Bind = bind,
		GetIfReady = function(): boolean
			return getIfReady(self)
		end,
		Land = function(exit: BasePart, behind: BasePart): boolean
			return teleport(self, getLanding(exit, behind))
		end,
	}
	table.freeze(walk)
	self._Walk = walk
	-- the ways in are unbound as the service goes
	table.insert(
		self._CleanUpCallbacks,
		RULE.Bind(walk, function(door: Door)
			walkIn(self, door)
		end)
	)

	return self
end, function(self: ResidenceService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.StateChanged:Destroy()
	self.Leaving:Destroy()
	table.clear(self :: any)
end)
