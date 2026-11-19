--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
local WalkLock = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/WalkLock")
-- Types
type WalkLock = WalkLock.WalkLock
-- the swap underway, the next one can't begin until it's over
type Swap = {
	Avatar: Model,
	Track: AnimationTrack?,
}
type SwapServiceImpl = {
	__index: SwapServiceImpl,
}
export type SwapService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Swap: Swap?,
		_WalkLock: WalkLock?, -- only while the swap keeps the avatar from walking
		_Animator: Animator?,
		_Tracks: { [string]: AnimationTrack }, -- loaded once per avatar, an animator only holds so many
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SwapServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- an animation that can't be loaded is skipped, the swap goes on without it
local function getTrack(self: SwapService, humanoid: Humanoid, animationId: string): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	if self._Animator ~= animator then
		self._Animator = animator
		table.clear(self._Tracks)
	end
	if self._Tracks[animationId] then
		return self._Tracks[animationId]
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local success, track = pcall(function(): AnimationTrack
		return animator:LoadAnimation(animation)
	end)
	if not success then
		warn(`animation err: {track}`)
		return nil
	end
	self._Tracks[animationId] = track
	return track
end

local function unfreeze(self: SwapService)
	local walkLock = self._WalkLock
	self._WalkLock = nil
	if walkLock and walkLock.IsAlive then
		walkLock:Destroy()
	end
end

local function freeze(self: SwapService, humanoid: Humanoid, duration: number)
	-- the lock of the swap before hands the speed back first, so this one reads what the avatar really walks at
	unfreeze(self)
	local walkLock = WalkLock.new(humanoid)
	self._WalkLock = walkLock
	task.delay(duration, function()
		if self._WalkLock == walkLock then
			unfreeze(self)
		end
	end)
end

local function finish(self: SwapService)
	self._Swap = nil
	if ShellService.IsInitialized then
		ShellService:SetBackpackLocked(false)
	end
end

local function cancel(self: SwapService)
	local swap = self._Swap
	unfreeze(self)
	if not swap then
		return
	end
	finish(self)
	local track = swap.Track
	if track then
		track:Stop()
	end
end

local function start(self: SwapService)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	if self._Swap then
		return
	end
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	local characterOpt = SessionService:GetActiveCharacter()
	if not avatar or not humanoid or characterOpt.IsNone then
		return
	end
	-- a dead avatar has to get up before it can become somebody else
	if humanoid.Health <= 0 or AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
		return
	end
	local identity = characterOpt.Value.Identities[SessionService:GetActiveIdentityKey()]
	if not identity then
		return
	end
	local transformation = identity.Appearance.Transitions.Transformation
	local definition = TransitionDefinition.getTransformation(transformation and transformation.Style)

	local swap: Swap = {
		Avatar = avatar,
		-- a game that swaps without a move has nothing to load
		Track = if definition.AnimationId then getTrack(self, humanoid, definition.AnimationId) else nil,
	}
	self._Swap = swap
	-- the way out is set before anything is taken, the hotbar + the button come back whatever happens below
	task.delay(definition.LockDuration, function()
		if self._Swap == swap then
			finish(self)
		end
	end)
	-- the server takes the tools + hands out new ones as it dresses the avatar, the hotbar stays away meanwhile
	ShellService:SetBackpackLocked(true)
	ShellService:FireTutorialTrigger("SwapPressed")
	local track = swap.Track
	if track then
		track:Play()
		-- one that's still going from the swap before starts over
		track.TimePosition = 0
	end
	if definition.FreezeDuration then
		freeze(self, humanoid, definition.FreezeDuration)
	end
	task.spawn(function()
		local identityRes = SessionService:SwapIdentity()
		if identityRes.IsOk then
			return
		end
		warn(`swap err: {identityRes.Value}`)
		-- an answer that's late finds the swap over or the next one underway, there's nothing left to hand back
		if self._Swap == swap then
			cancel(self)
		end
	end)
end
-- Class
local SwapService = {} :: SwapServiceImpl
SwapService.__index = SwapService

return ServiceLocker(function(): SwapService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)

	local self = setmetatable({
		IsInitialized = true :: true,
		_Swap = nil :: Swap?,
		_WalkLock = nil :: WalkLock?,
		_Animator = nil :: Animator?,
		_Tracks = {} :: { [string]: AnimationTrack },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SwapService)

	local swapConnection = ShellService.SwapRequested:Connect(function()
		start(self)
	end)
	table.insert(self._CleanUpCallbacks, function()
		swapConnection:Disconnect()
	end)
	-- an avatar that's replaced mid swap takes the animation + the freeze with it, the next one starts out clean
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterRemoving:Connect(function(avatar: Model)
			local swap = self._Swap
			local walkLock = self._WalkLock
			if
				(swap and swap.Avatar == avatar)
				or (walkLock and walkLock.IsAlive and walkLock.Humanoid.Parent == avatar)
			then
				cancel(self)
			end
			self._Animator = nil
			table.clear(self._Tracks)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		cancel(self)
	end)

	return self
end, function(self: SwapService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
