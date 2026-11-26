--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local NpcDefinition = require("@game/ServerScriptService/Server/Definition/Npc")
local PreyUtil = require("@self/Prey")
local SteerUtil = require("@self/Steer")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
type Npc = NpcDefinition.Npc
type Tracks = {
	Idles: { AnimationTrack }, -- in the order the row lists them
	Walk: AnimationTrack,
	Jump: AnimationTrack,
	Fall: AnimationTrack,
	Climb: AnimationTrack,
}
-- a body of the map nobody plays, for as long as it's in the world
type Walker = {
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Npc: Npc,
	RaycastParams: RaycastParams,
	Memory: SteerUtil.Memory,
	-- on the clock of os.clock, all of them
	WakeAt: number,
	RemoveAt: number,
	DamageReadyAt: number,
	RegenerateAt: number?, -- nil while it has nothing to get back
	IsDown: boolean,
	Tracks: Tracks,
	Track: AnimationTrack?, -- the one that plays
	Connections: { RBXScriptConnection },
}
type NpcServiceImpl = {
	__index: NpcServiceImpl,
	-- puts one into the world for that many seconds, however it fares meanwhile. nil when the map is full of them
	Spawn: (self: NpcService, npcId: string, cframe: CFrame, lifetime: number) -> Model?,
	GetCount: (self: NpcService) -> number,
	List: (self: NpcService) -> { Model },
	-- takes all of them out of the world, answers how many went
	Clear: (self: NpcService) -> number,
}
export type NpcService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Walkers: { [Model]: Walker },
		_Count: number,
		_Folder: Folder,
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: NpcServiceImpl
))
-- Constants
local FOLDER_NAME = "Npcs"
-- its old place went by the name of the part, the engine climbs every one of the class
local TRUSS_NAME = "Truss"
-- seconds one animation takes to give way to the next
local FADE_DURATION = 0.1
-- studs a second under which it counts as standing, the engine reports a crawl for a body that's pushed
local WALK_THRESHOLD = 0.01
-- how far the health of the humanoid may be off what the body wears before it's written again
local HEALTH_TOLERANCE = 0.01
-- Variables
-- References
local Library = IndexUtil.waitForPath("game/ServerStorage/lib/npc") :: Folder
-- Private Functions
-- its humanoid goes by any name, so it's found by its class
local function getBody(model: Model): (Humanoid, BasePart)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart
	assert(humanoid and rootPart, `the model "{model.Name}" has no humanoid or no root`)
	return humanoid, rootPart
end

local function getTemplate(npc: Npc): Model
	local template = Library:FindFirstChild(npc.Id)
	assert(template and template:IsA("Model"), `the library has no model "{npc.Id}"`)
	getBody(template)
	return template
end

local function loadTrack(animator: Animator, animationId: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	return animator:LoadAnimation(animation)
end

local function play(walker: Walker, track: AnimationTrack, speed: number)
	if walker.Track ~= track then
		if walker.Track then
			walker.Track:Stop(FADE_DURATION)
		end
		track:Play(FADE_DURATION)
		walker.Track = track
	end
	track:AdjustSpeed(speed)
end

-- one of the ways it stands about, the heavier the likelier. one that stands about already carries on
local function idle(self: NpcService, walker: Walker)
	if walker.Track and table.find(walker.Tracks.Idles, walker.Track) then
		return
	end
	local idles = walker.Npc.Animations.Idles
	local totalWeight = 0
	for _, v in idles do
		totalWeight += v.Weight
	end
	local roll = self._Random:NextNumber(0, totalWeight)
	local index = #idles
	for i, v in idles do
		roll -= v.Weight
		if roll <= 0 then
			index = i
			break
		end
	end
	play(walker, walker.Tracks.Idles[index], 1)
end

-- the server plays what the rig's own script played in its old place: whoever has the model sees it, + no client
-- is handed anything to run
local function animate(self: NpcService, walker: Walker)
	local humanoid = walker.Humanoid
	local animations = walker.Npc.Animations
	local tracks = walker.Tracks
	table.insert(
		walker.Connections,
		humanoid.Running:Connect(function(speed: number)
			if speed > WALK_THRESHOLD then
				play(walker, tracks.Walk, speed / animations.WalkPace)
			else
				idle(self, walker)
			end
		end)
	)
	table.insert(
		walker.Connections,
		humanoid.Jumping:Connect(function(isActive: boolean)
			if isActive then
				play(walker, tracks.Jump, 1)
			end
		end)
	)
	table.insert(
		walker.Connections,
		humanoid.FreeFalling:Connect(function(isActive: boolean)
			if isActive then
				play(walker, tracks.Fall, 1)
			end
		end)
	)
	table.insert(
		walker.Connections,
		humanoid.Climbing:Connect(function(speed: number)
			play(walker, tracks.Climb, speed / animations.ClimbPace)
		end)
	)
	idle(self, walker)
end

local function remove(self: NpcService, walker: Walker)
	if self._Walkers[walker.Model] ~= walker then
		return
	end
	self._Walkers[walker.Model] = nil
	self._Count -= 1
	for _, v in walker.Connections do
		v:Disconnect()
	end
	table.clear(walker.Connections)
	walker.Model:Destroy()
end

-- who it goes after: nothing is kept from one wake to the next, so whoever went down, into a menu or out of sight
-- since is let go of there + then
local function getPreyRoot(walker: Walker, position: Vector3): BasePart?
	local npc = walker.Npc
	local candidates: { PreyUtil.Candidate } = {}
	local rootParts: { BasePart } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = if character then character.PrimaryPart else nil
		if character and rootPart then
			table.insert(candidates, {
				Position = rootPart.Position,
				TeamId = AttributeDefinition.get(character, AttributeDefinition.TeamId),
				IsAlive = TakeDownUtil.getIfAlive(character),
				IsSheltered = not CombatDefinition.getIfHostile(walker.Model, character),
			})
			table.insert(rootParts, rootPart)
		end
	end
	local index = PreyUtil.pick(position, candidates, npc.Sight, npc.PreyTeamId)
	return if index then rootParts[index] else nil
end

-- what a ray runs into first, the walker itself aside: whatever a ray finds counts, solid or not, as in its old place
local function cast(
	self: NpcService,
	walker: Walker,
	preyRoot: BasePart?,
	origin: Vector3,
	direction: Vector3
): SteerUtil.Sight?
	local result = Workspace:Raycast(origin, direction, walker.RaycastParams)
	if not result then
		return nil
	end
	local hit = result.Instance
	if hit:IsA("Terrain") then
		return "Terrain"
	end
	local prey = if preyRoot then preyRoot.Parent else nil
	if prey and hit:IsDescendantOf(prey) then
		return "Prey"
	end
	local model = hit:FindFirstAncestorOfClass("Model")
	if model and self._Walkers[model] then
		return "Kin"
	end
	if hit.Name == TRUSS_NAME or hit:IsA("TrussPart") then
		return "Truss"
	end
	return "Solid"
end

local function wake(self: NpcService, walker: Walker, now: number)
	local npc = walker.Npc
	local humanoid = walker.Humanoid
	local position = walker.RootPart.Position
	walker.WakeAt = now + npc.WakeDistance / npc.WalkSpeed
	-- an avatar that's frozen is held by its own client, this one has none
	if AttributeDefinition.get(walker.Model, AttributeDefinition.IsFrozen) then
		humanoid:MoveTo(position)
		return
	end
	local preyRoot = getPreyRoot(walker, position)
	local memory, order = SteerUtil.step(walker.Memory, {
		Position = position,
		Prey = if preyRoot then preyRoot.Position else nil,
		Cast = function(origin: Vector3, direction: Vector3): SteerUtil.Sight?
			return cast(self, walker, preyRoot, origin, direction)
		end,
	}, npc.Probe)
	walker.Memory = memory
	-- with a part the engine keeps after it, wherever it gets to before the next wake
	humanoid:MoveTo(order.Goal, if order.IsFollowing then preyRoot else nil)
	if order.IsJumping then
		humanoid.Jump = true
	end
end

-- what it gets back while it's hurt + up, + the engine's own bar over it: that reads the humanoid, a hit only ever
-- comes off the attribute
local function heal(walker: Walker, now: number)
	local npc = walker.Npc
	local regeneration = npc.Regeneration
	local health = AttributeDefinition.get(walker.Model, AttributeDefinition.Health)
	if health >= npc.MaxHealth then
		walker.RegenerateAt = nil
	elseif not walker.RegenerateAt then
		walker.RegenerateAt = now + regeneration.Interval
	elseif now >= walker.RegenerateAt then
		health = math.min(npc.MaxHealth, health + regeneration.Fraction * npc.MaxHealth)
		AttributeDefinition.set(walker.Model, AttributeDefinition.Health, health)
		walker.RegenerateAt = if health < npc.MaxHealth then now + regeneration.Interval else nil
	end
	-- the engine keeps it less finely than an attribute does, so the two are never quite the same number
	if math.abs(walker.Humanoid.Health - health) > HEALTH_TOLERANCE then
		walker.Humanoid.Health = health
	end
end

local function onHeartbeat(self: NpcService)
	local now = os.clock()
	for model, walker in self._Walkers do
		if now >= walker.RemoveAt or not walker.RootPart:IsDescendantOf(Workspace) then
			-- its time is up whatever it's doing, or the world let go of it: it fell out of the map
			remove(self, walker)
		elseif walker.IsDown then
			continue
		elseif walker.Humanoid.Health <= 0 or AttributeDefinition.get(model, AttributeDefinition.IsDead) then
			-- a hit took the last of it, or the engine did: a gate that's lit, a fall. either way it lies there for
			-- a moment + nothing more lands on it
			walker.IsDown = true
			walker.RemoveAt = math.min(walker.RemoveAt, now + walker.Npc.RemoveDelay)
			if not AttributeDefinition.get(model, AttributeDefinition.IsDead) then
				AttributeDefinition.set(model, AttributeDefinition.Health, 0)
				AttributeDefinition.set(model, AttributeDefinition.IsDead, true)
			end
		else
			heal(walker, now)
			if now >= walker.WakeAt then
				wake(self, walker, now)
			end
		end
	end
end

-- a touch is whatever the client of the avatar says it is: it only counts for somebody the server has at the arm, +
-- the rule of the game is asked there + then. one touch for the whole of the walker until its wait is over, whoever
-- it was that got it
local function onArmTouched(walker: Walker, arm: BasePart, hit: BasePart)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local now = os.clock()
	local model = walker.Model
	if walker.IsDown or now < walker.DamageReadyAt then
		return
	end
	if
		walker.Humanoid.Health <= 0
		or AttributeDefinition.get(model, AttributeDefinition.IsDead)
		or AttributeDefinition.get(model, AttributeDefinition.IsFrozen)
	then
		return
	end
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character then
		return
	end
	if
		not TakeDownUtil.getIfAlive(character)
		or not TouchUtil.getIfNear(character, arm, TouchUtil.REACH)
		or not CombatDefinition.getIfHostile(model, character)
	then
		return
	end
	walker.DamageReadyAt = now + walker.Npc.DamageCooldown
	-- what the row says to the point: nothing a game adds to a hit, + no shove. it's fired the way the effects of a
	-- character are, of one without a player
	VFXService:NewScope(nil, model).fire(Damage, {
		Target = character,
		Amount = walker.Npc.Damage,
	})
end
-- Class
local NpcService = {} :: NpcServiceImpl
NpcService.__index = NpcService

function NpcService:Spawn(npcId: string, cframe: CFrame, lifetime: number): Model?
	assert(self.IsInitialized, `the npc service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local npcRes = NpcDefinition.get(npcId)
	if npcRes.IsErr then
		error(npcRes.Value)
	end
	local npc = npcRes.Value
	if self._Count >= NpcDefinition.MAX_COUNT then
		warn(`{self._Count} bodies nobody plays walk the map already, no "{npcId}" was added`)
		return nil
	end

	local model = getTemplate(npc):Clone()
	local humanoid, rootPart = getBody(model)
	-- all of it or none of it: a client never holds half a body
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- what every power finds it by + takes its health off. it wears no side: anybody may hit it + it's on nobody's
	AttributeDefinition.set(model, AttributeDefinition.Health, npc.MaxHealth)
	AttributeDefinition.set(model, AttributeDefinition.IsDead, false)
	AttributeDefinition.set(model, AttributeDefinition.IsNonPlayer, true)
	humanoid.MaxHealth = npc.MaxHealth
	humanoid.Health = npc.MaxHealth
	humanoid.WalkSpeed = npc.WalkSpeed
	-- a humanoid sits down on any seat it brushes + this one has no way up again
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local face = npc.Face
	if face then
		local decal = model:FindFirstChild(face.Name, true)
		assert(decal and decal:IsA("Decal"), `the model "{npcId}" has no decal "{face.Name}"`)
		decal.Texture = face.Image
	end
	model:PivotTo(cframe)
	model.Parent = self._Folder
	-- the server walks it: left to the engine it'd go to the nearest client, who could then park it or carry it off
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(nil)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { model }
	local animations = npc.Animations
	local idles: { AnimationTrack } = {}
	for _, v in animations.Idles do
		table.insert(idles, loadTrack(animator, v.AnimationId))
	end
	local now = os.clock()
	local walker: Walker = {
		Model = model,
		Humanoid = humanoid,
		RootPart = rootPart,
		Npc = npc,
		RaycastParams = raycastParams,
		Memory = SteerUtil.new(rootPart.Position),
		-- they don't all look around on the same frame
		WakeAt = now + self._Random:NextNumber(npc.StartDelay.Min, npc.StartDelay.Max),
		RemoveAt = now + lifetime,
		DamageReadyAt = now,
		RegenerateAt = nil,
		IsDown = false,
		Tracks = {
			Idles = idles,
			Walk = loadTrack(animator, animations.Walk),
			Jump = loadTrack(animator, animations.Jump),
			Fall = loadTrack(animator, animations.Fall),
			Climb = loadTrack(animator, animations.Climb),
		},
		Track = nil,
		Connections = {},
	}
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and string.find(part.Name, npc.ArmPattern, 1, true) then
			table.insert(
				walker.Connections,
				part.Touched:Connect(function(hit: BasePart)
					onArmTouched(walker, part, hit)
				end)
			)
		end
	end
	animate(self, walker)
	self._Walkers[model] = walker
	self._Count += 1
	return model
end

function NpcService:GetCount(): number
	assert(self.IsInitialized, `the npc service isn't initialized`)
	return self._Count
end

function NpcService:List(): { Model }
	assert(self.IsInitialized, `the npc service isn't initialized`)
	local models: { Model } = {}
	for model in self._Walkers do
		table.insert(models, model)
	end
	return models
end

function NpcService:Clear(): number
	assert(self.IsInitialized, `the npc service isn't initialized`)
	local count = 0
	for _, walker in self._Walkers do
		remove(self, walker)
		count += 1
	end
	return count
end

-- the bodies of the map nobody plays. each is a clone of its library model that the server walks, animates, heals +
-- takes away again: it goes straight for the nearest it may hunt + hurts whoever its arms brush. a power finds it the
-- way it finds an avatar, by its humanoid + its attributes, + nobody is paid for one. it puts none into the world by
-- itself: whoever wants a wave asks for it. no remote, nothing saved, + nothing a client has to run
return ServiceLocker(function(): NpcService
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	-- a model that's missing or isn't a body says so as the server starts, not when the graves open
	for _, npc in NpcDefinition.list() do
		getTemplate(npc)
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace

	local self = setmetatable({
		IsInitialized = true :: true,
		_Walkers = {},
		_Count = 0,
		_Folder = folder,
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, NpcService)

	-- one beat for all of them: each wakes on its own time, so a wave is a few rays a frame
	table.insert(
		self._Connections,
		RunService.Heartbeat:Connect(function()
			onHeartbeat(self)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		folder:Destroy()
	end)

	return self
end, function(self: NpcService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	self:Clear()
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
