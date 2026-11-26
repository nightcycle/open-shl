--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local CustodyUtil = require("@self/Custody")
local JailDefinition = require("@game/ServerScriptService/Server/Definition/Jail")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PropService = require("@game/ServerScriptService/Server/Service/Prop")
local RoleplayService = require("@game/ServerScriptService/Server/Service/Roleplay")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TeamService = require("@game/ServerScriptService/Server/Service/Team")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- somebody who's held, for as long as the avatar they came in as is
type Prisoner = {
	Avatar: Model,
	CellIndex: number,
	-- it's been put into its cell. until then where it is says nothing about having got away: every spot of the map
	-- an avatar comes in at is far enough from the jail to be let go on
	IsPlaced: boolean,
}
-- a pane of the map that keeps the held in
type Gate = {
	Part: BasePart,
	Transparency: number, -- what the map gave it, it's back at it once it's shut again
	CanCollide: boolean, -- what the map gave it, it's back at it once somebody may be held again
	Thread: thread?, -- it's on its way open or shut: whoever walks up meanwhile changes nothing
	Connection: RBXScriptConnection?, -- none while nobody is held: it's no wall then
}
type JailServiceImpl = {
	__index: JailServiceImpl,
	GetIfJailed: (self: JailService, player: Player) -> boolean,
}
export type JailService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- none of it is saved: whoever comes back as the side that's held comes back held
		_Prisoners: { [Player]: Prisoner },
		-- where the held are put, in an order that's the same every time
		_Spots: { BasePart },
		-- in the order the map lists them
		_Gates: { Gate },
		_CenterPosition: Vector3?,
		_Radius: number,
		_RoadParams: RaycastParams?,
		-- what takes down the part of it that's only up for as long as somebody may be held
		_StopCallbacks: { () -> () },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: JailServiceImpl
))
-- Constants
local SPOT_NAME = "SpawnPoint"
local GATE = JailDefinition.GATE
-- what the held are put in, the same for every one of them
local COSTUME = CustodyUtil.newCostume(JailDefinition.IDENTITY_KEY, JailDefinition.ITEM_IDS, JailDefinition.COLOR)
-- Variables
-- References
-- Private Functions
-- how many each cell holds
local function getOccupancy(self: JailService): { number }
	local occupancy = table.create(#self._Spots, 0)
	for _, prisoner in self._Prisoners do
		occupancy[prisoner.CellIndex] += 1
	end
	return occupancy
end

-- nobody is held any more: not by the look, not by the cuffs. the avatar that's out keeps on what it has until its
-- next dress
local function free(self: JailService, player: Player)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	self._Prisoners[player] = nil
	AvatarService:SetCostume(player, nil)
	if RoleplayService.IsInitialized then
		RoleplayService:SetRestrained(player, false)
	end
end

-- yields. the engine puts an avatar that comes in onto one of the spots of the map, which may be after the server
-- hears of it: it's moved once it's in the world + a step went by
local function place(self: JailService, player: Player, prisoner: Prisoner)
	local character = prisoner.Avatar
	while not character:IsDescendantOf(Workspace) do
		task.wait()
		if not self.IsInitialized or self._Prisoners[player] ~= prisoner or player.Character ~= character then
			return
		end
	end
	RunService.Heartbeat:Wait()
	if not self.IsInitialized or self._Prisoners[player] ~= prisoner or player.Character ~= character then
		return
	end
	character:PivotTo(self._Spots[prisoner.CellIndex].CFrame)
	prisoner.IsPlaced = true
end

-- an avatar of the side that's held comes in held: in a cell, as who the rule says, in what the held wear, cuffed +
-- with no powers. the costume is on its player before the dress every avatar gets as it comes in
local function jail(self: JailService, player: Player, character: Model)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	AttributeDefinition.set(character, AttributeDefinition.IsJailed, true)
	AttributeDefinition.set(character, AttributeDefinition.IsTroublesome, false)
	AvatarService:SetCostume(player, COSTUME)
	if RoleplayService.IsInitialized then
		RoleplayService:SetRestrained(player, true)
	end
	-- the body they were held as before isn't counted any more
	self._Prisoners[player] = nil
	local prisoner: Prisoner = {
		Avatar = character,
		CellIndex = CustodyUtil.getCellIndex(getOccupancy(self)),
		IsPlaced = false,
	}
	self._Prisoners[player] = prisoner
	task.spawn(place, self, player, prisoner)
end

-- somebody got away. they keep what they have on + stay who they were held as until their next dress, the way the
-- old place had it: the cuffs come off at once, the powers a moment later
local function release(self: JailService, player: Player, prisoner: Prisoner)
	local character = prisoner.Avatar
	free(self, player)
	AttributeDefinition.set(character, AttributeDefinition.IsJailed, false)
	task.delay(JailDefinition.RELEASE_DELAY, function()
		if
			self.IsInitialized
			and AvatarService.IsInitialized
			and player.Character == character
			and TakeDownUtil.getIfAlive(character)
			and not self._Prisoners[player]
		then
			AvatarService:Arm(player)
		end
	end)
end

-- if it stands on a road: a part filed under one, right under its root
local function getIfOnRoad(self: JailService, character: Model): boolean
	local rootPart = character.PrimaryPart
	local roadParams = self._RoadParams
	if not rootPart or not roadParams then
		return false
	end
	return Workspace:Raycast(rootPart.Position, Vector3.new(0, -JailDefinition.ROAD_REACH, 0), roadParams) ~= nil
end

-- the server alone says who got away: whoever is up + far enough from the middle of the jail, or on a road
local function check(self: JailService)
	for player, prisoner in self._Prisoners do
		local character = prisoner.Avatar
		if not prisoner.IsPlaced or player.Character ~= character or not TakeDownUtil.getIfAlive(character) then
			continue
		end
		local centerPosition = self._CenterPosition
		local isOut = centerPosition ~= nil
			and CustodyUtil.getIfOut(character:GetPivot().Position, centerPosition, self._Radius)
		if isOut or getIfOnRoad(self, character) then
			release(self, player, prisoner)
		end
	end
end

local function shut(gate: Gate)
	gate.Thread = nil
	gate.Part.Transparency = gate.Transparency
	gate.Part.CanCollide = true
end

-- yields. it's out of the way for everybody while it is, whoever it opened for
local function cycle(gate: Gate)
	local part = gate.Part
	part.Transparency = GATE.FadeTransparency
	task.wait(GATE.FadeDuration)
	part.Transparency = GATE.OpenTransparency
	part.CanCollide = false
	task.wait(GATE.OpenDuration)
	part.Transparency = GATE.FadeTransparency
	task.wait(GATE.FadeDuration)
	shut(gate)
end

-- a gate opens for whoever isn't of the side that's held, + for whoever has the key in their hand
local function onGateTouched(gate: Gate, hit: BasePart)
	if gate.Thread then
		return
	end
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character then
		return
	end
	if
		AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
		or not TouchUtil.getIfNear(character, gate.Part, TouchUtil.REACH)
	then
		return
	end
	local teamId = AttributeDefinition.get(character, AttributeDefinition.TeamId)
	local isKeyHeld = false
	if PropService.IsInitialized then
		isKeyHeld = PropService:GetHeldId(player) == JailDefinition.KEY_PROP_ID
	end
	if isKeyHeld or (teamId ~= nil and teamId ~= JailDefinition.TEAM_ID) then
		gate.Thread = task.spawn(cycle, gate)
	end
end

-- whoever is held + touches one of these made trouble: they're fair game for as long as that avatar lives
local function onTroubleTouched(self: JailService, part: BasePart, hit: BasePart)
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character then
		return
	end
	local prisoner = self._Prisoners[player]
	if not prisoner or prisoner.Avatar ~= character or not TouchUtil.getIfNear(character, part, TouchUtil.REACH) then
		return
	end
	if not AttributeDefinition.get(character, AttributeDefinition.IsTroublesome) then
		AttributeDefinition.set(character, AttributeDefinition.IsTroublesome, true)
	end
end

local function onDeployed(self: JailService, player: Player, character: Model, teamId: TeamId)
	if teamId == JailDefinition.TEAM_ID and #self._Spots > 0 then
		jail(self, player, character)
	else
		free(self, player)
	end
end

-- players fight from here on: the gates are the walls the map made them + whoever is held is watched. nobody who
-- stands in the world is put in a cell for it, the next avatar of the side that's held comes in held
local function start(self: JailService)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(TeamService.IsInitialized, `the team service isn't initialized`)
	for _, gate in self._Gates do
		local part = gate.Part
		part.Transparency = gate.Transparency
		part.CanCollide = gate.CanCollide
		gate.Connection = part.Touched:Connect(function(hit: BasePart)
			onGateTouched(gate, hit)
		end)
	end
	local troubleConnections: { RBXScriptConnection } = {}
	for _, part in MapDefinition.list(MapDefinition.Troublesome) do
		table.insert(
			troubleConnections,
			part.Touched:Connect(function(hit: BasePart)
				onTroubleTouched(self, part, hit)
			end)
		)
	end
	local deployedConnection = TeamService.Deployed:Connect(function(player: Player, character: Model, teamId: TeamId)
		onDeployed(self, player, character, teamId)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		self._Prisoners[player] = nil
	end)
	local checkThread = task.spawn(function()
		while true do
			task.wait(JailDefinition.CHECK_INTERVAL)
			check(self)
		end
	end)
	table.insert(self._StopCallbacks, function()
		for _, connection in troubleConnections do
			connection:Disconnect()
		end
		deployedConnection:Disconnect()
		removingConnection:Disconnect()
		task.cancel(checkThread)
	end)
end

-- nothing is watched any more + no gate is on its way anywhere. whoever is held stays held
local function halt(self: JailService)
	for _, callback in self._StopCallbacks do
		callback()
	end
	table.clear(self._StopCallbacks)
	for _, gate in self._Gates do
		local connection = gate.Connection
		if connection then
			connection:Disconnect()
		end
		gate.Connection = nil
		if gate.Thread then
			task.cancel(gate.Thread)
			shut(gate)
		end
	end
end

-- nobody fights from here on, so nobody is held: whoever was is let go the way somebody who got away is, + the
-- gates are no wall to anybody. the old place left them cuffed + without powers behind gates that opened for them
local function stop(self: JailService)
	halt(self)
	for player, prisoner in self._Prisoners do
		local character = prisoner.Avatar
		release(self, player, prisoner)
		AttributeDefinition.set(character, AttributeDefinition.IsTroublesome, nil)
	end
	for _, gate in self._Gates do
		gate.Part.CanCollide = false
	end
end
-- Class
local JailService = {} :: JailServiceImpl
JailService.__index = JailService

function JailService:GetIfJailed(player: Player): boolean
	local prisoner = self._Prisoners[player]
	return prisoner ~= nil and prisoner.Avatar == player.Character
end

-- the jail of a place where players fight. nobody puts anybody in it: it's where every avatar of one side comes in,
-- + getting away from it is what lets them out. the server alone says who did, a client is told by the avatar. it
-- holds for as long as players fight: a server that changes its mind about that has it let everybody go + take the
-- next ones in as it does
return ServiceLocker(function(): JailService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	assert(TeamService.IsInitialized, `the team service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Prisoners = {} :: { [Player]: Prisoner },
		_Spots = {} :: { BasePart },
		_Gates = {} :: { Gate },
		_CenterPosition = nil :: Vector3?,
		_Radius = 0,
		_RoadParams = nil :: RaycastParams?,
		_StopCallbacks = {} :: { () -> () },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, JailService)

	-- a map is found by its marks alone: one that lacks some has that much less of a jail, + says so
	for _, cell in MapDefinition.list(MapDefinition.JailCell) do
		local spot = cell:FindFirstChild(SPOT_NAME)
		if spot and spot:IsA("BasePart") then
			table.insert(self._Spots, spot)
		else
			warn(`{cell:GetFullName()} has no {SPOT_NAME} to put anybody on`)
		end
	end
	CustodyUtil.sort(self._Spots)
	if #self._Spots == 0 then
		warn(`the map marks no cell, nobody is held`)
	end
	local center = MapDefinition.list(MapDefinition.JailCenter)[1]
	local radiusRes = if center then MapDefinition.get(center, MapDefinition.Radius) else nil
	if center and radiusRes and radiusRes.IsOk then
		self._CenterPosition = center.Position
		self._Radius = radiusRes.Value
	else
		warn(`the map marks no middle of the jail, nobody gets away by distance`)
	end
	local roads: { Instance } = {}
	for _, road in MapDefinition.list(MapDefinition.Road) do
		table.insert(roads, road)
	end
	if #roads > 0 then
		local roadParams = RaycastParams.new()
		roadParams.FilterType = Enum.RaycastFilterType.Include
		roadParams.FilterDescendantsInstances = roads
		self._RoadParams = roadParams
	else
		warn(`the map marks no road, nobody gets away by reaching one`)
	end

	-- what the map gave a gate is read before anything is done to it: a place that starts out with nobody fighting
	-- has them out of the way from the first moment
	for _, part in MapDefinition.list(MapDefinition.HeroGate) do
		local gate: Gate = {
			Part = part,
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			Thread = nil,
			Connection = nil,
		}
		table.insert(self._Gates, gate)
	end

	local isStarted: boolean? = nil
	local unobserve = ModeDefinition.observe(function(isPVP: boolean)
		if isPVP == isStarted or not self.IsInitialized then
			return
		end
		isStarted = isPVP
		if isPVP then
			start(self)
		else
			stop(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		unobserve()
		halt(self)
	end)
	-- the avatars that came in before this was up were dressed without it. it's only ever asked as the service
	-- starts: whoever stands in the world as a server takes up fighting stays at large
	if isStarted then
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local teamId = if character then AttributeDefinition.get(character, AttributeDefinition.TeamId) else nil
			if character and teamId == JailDefinition.TEAM_ID and #self._Spots > 0 then
				jail(self, player, character)
				AvatarService:Dress(player)
			end
		end
	end

	return self
end, function(self: JailService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
