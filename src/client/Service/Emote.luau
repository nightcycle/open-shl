--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EmoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Emote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local WalkLock = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/WalkLock")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
type PoseDefinition = EmoteDefinition.PoseDefinition
type WalkLock = WalkLock.WalkLock
export type EmoteId = EmoteDefinition.EmoteId
type EmoteServiceImpl = {
	__index: EmoteServiceImpl,
	GetEmoteId: (self: EmoteService) -> EmoteId?,
	Play: (self: EmoteService, emoteId: EmoteId) -> Result<true, string>,
	Stop: (self: EmoteService) -> (),
}
export type EmoteService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		EmoteChanged: Signal<EmoteId?>, -- nil once the emote was let go of
		_Character: Model?,
		_EmoteId: EmoteId?,
		_EmoteTrack: AnimationTrack?,
		_EmoteConnection: RBXScriptConnection?,
		_PoseTrack: AnimationTrack?, -- the cuffed arms, held while handcuffed + not in an emote
		_PoseConnection: RBXScriptConnection?,
		_Tracks: { [string]: AnimationTrack }, -- loaded once per avatar, an animator only holds so many
		_WalkLock: WalkLock?, -- only while an emote roots the avatar
		_CharacterConnections: { RBXScriptConnection },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: EmoteServiceImpl
))
-- Constants
local AVATAR_TIMEOUT = 10
local CLIP_TIMEOUT = 10
local CLIP_POLL_DELAY = 0.25
-- Variables
-- References
-- Private Functions
local function getHumanoid(self: EmoteService): Humanoid?
	local character = self._Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

-- the animator the server gave the avatar, what plays on it is what the other players see
local function getAnimator(self: EmoteService): Animator?
	local humanoid = getHumanoid(self)
	return if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
end

-- an animation that can't be loaded is an error, one that loads without its clip plays as nothing
local function play(self: EmoteService, pose: PoseDefinition): Result<AnimationTrack, string>
	local animator = getAnimator(self)
	if not animator then
		return Result.err(`there's no avatar to animate`)
	end
	local track = self._Tracks[pose.AnimationId]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = pose.AnimationId
		local isLoaded, newTrack = pcall(function(): AnimationTrack
			return animator:LoadAnimation(animation)
		end)
		if not isLoaded then
			return Result.err(`can't load "{pose.Name}": {newTrack}`)
		end
		track = newTrack
		self._Tracks[pose.AnimationId] = newTrack
		-- a clip that loads late overwrites Looped, so it's set again
		task.spawn(function()
			local deadline = os.clock() + CLIP_TIMEOUT
			while newTrack.Length == 0 and os.clock() < deadline do
				task.wait(CLIP_POLL_DELAY)
				-- the avatar the track was loaded for is gone
				if not self.IsInitialized or self._Tracks[pose.AnimationId] ~= newTrack then
					return
				end
			end
			-- the track stays, so the emote is still held + let go of like any other
			if newTrack.Length == 0 then
				warn(`"{pose.Name}" has no clip to play`)
				return
			end
			newTrack.Priority = Enum.AnimationPriority.Action
			newTrack.Looped = pose.IsLooped
			-- played before its clip was there it was over at once: whoever is still cuffed is posed now that it is
			if self._PoseTrack == newTrack and not newTrack.IsPlaying then
				newTrack:Play()
			end
		end)
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = pose.IsLooped
	track:Play()
	return Result.ok(track)
end

local function unroot(self: EmoteService)
	local walkLock = self._WalkLock
	self._WalkLock = nil
	if walkLock and walkLock.IsAlive then
		walkLock:Destroy()
	end
end

local function root(self: EmoteService, humanoid: Humanoid)
	local walkLock = self._WalkLock
	-- an emote that takes over from another one keeps the speed the first one found
	if walkLock and walkLock.IsAlive and walkLock.Humanoid == humanoid then
		return
	end
	unroot(self)
	self._WalkLock = WalkLock.new(humanoid)
end

local function endPose(self: EmoteService)
	if self._PoseConnection then
		self._PoseConnection:Disconnect()
		self._PoseConnection = nil
	end
	if self._PoseTrack then
		self._PoseTrack:Stop()
		self._PoseTrack = nil
	end
end

-- the cuffed arms follow the attribute the server writes, an emote takes their place while it's held
local function updatePose(self: EmoteService)
	local isPosed = self._EmoteId == nil and AttributeDefinition.get(self._Character, AttributeDefinition.IsHandcuffed)
	if not isPosed then
		endPose(self)
		return
	end
	if (self._PoseTrack and self._PoseTrack.IsPlaying) or not getAnimator(self) then
		return
	end
	local trackRes = play(self, EmoteDefinition.HANDCUFFS)
	if trackRes.IsErr then
		warn(`handcuffs err: {trackRes.Value}`)
		return
	end
	local track = trackRes.Value
	if self._PoseConnection then
		self._PoseConnection:Disconnect()
	end
	self._PoseTrack = track
	-- the cuffs stay on through whatever ends the track early. a track without a clip has nothing to hold
	self._PoseConnection = track.Stopped:Connect(function()
		if self._PoseTrack ~= track or track.IsPlaying or track.Length == 0 then
			return
		end
		task.defer(function()
			local character = self._Character
			if
				not self.IsInitialized
				or self._PoseTrack ~= track
				or not character
				or not character:IsDescendantOf(game)
			then
				return
			end
			updatePose(self)
		end)
	end)
end

-- doesn't fire EmoteChanged, answers if there was one
local function endEmote(self: EmoteService): boolean
	if self._EmoteId == nil then
		return false
	end
	if self._EmoteConnection then
		self._EmoteConnection:Disconnect()
		self._EmoteConnection = nil
	end
	if self._EmoteTrack then
		self._EmoteTrack:Stop()
		self._EmoteTrack = nil
	end
	self._EmoteId = nil
	return true
end

local function setCharacter(self: EmoteService, character: Model?)
	for _, v in self._CharacterConnections do
		v:Disconnect()
	end
	table.clear(self._CharacterConnections)
	local hadEmote = endEmote(self)
	unroot(self)
	endPose(self)
	table.clear(self._Tracks)
	self._Character = character
	if hadEmote then
		self.EmoteChanged:Fire(nil)
	end
	if not character then
		return
	end

	table.insert(
		self._CharacterConnections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsHandcuffed.Name):Connect(function()
			-- the cuffs + an emote don't go together, the one that came last stays
			if AttributeDefinition.get(character, AttributeDefinition.IsHandcuffed) then
				self:Stop()
			end
			updatePose(self)
		end)
	)
	table.insert(
		self._CharacterConnections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
			if AttributeDefinition.get(character, AttributeDefinition.IsDead) then
				self:Stop()
			end
		end)
	)
	-- the humanoid + the animator of a new avatar may still be on their way
	task.spawn(function()
		local humanoid = IndexUtil.waitForLocalPath(character, "Humanoid", AVATAR_TIMEOUT)
		if not self.IsInitialized or self._Character ~= character then
			return
		end
		if not humanoid or not humanoid:IsA("Humanoid") then
			return
		end
		table.insert(
			self._CharacterConnections,
			humanoid.Died:Connect(function()
				self:Stop()
			end)
		)
		IndexUtil.waitForLocalPath(humanoid, "Animator", AVATAR_TIMEOUT)
		if self.IsInitialized and self._Character == character then
			updatePose(self)
		end
	end)
end
-- Class
local EmoteService = {} :: EmoteServiceImpl
EmoteService.__index = EmoteService

function EmoteService:GetEmoteId(): EmoteId?
	return self._EmoteId
end

function EmoteService:Play(emoteId: EmoteId): Result<true, string>
	if self._EmoteId == emoteId then
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	local definitionRes = EmoteDefinition.get(emoteId)
	if definitionRes.IsErr then
		return Result.err(definitionRes.Value)
	end
	local definition = definitionRes.Value
	-- the avatar is frozen + out of sight of its player while a screen is up
	if ShellService.IsInitialized and not ShellService:GetIsGameplayHudVisible() then
		return Result.err(`can't emote without the hud`)
	end
	local humanoid = getHumanoid(self)
	if not humanoid or humanoid.Health <= 0 or AttributeDefinition.get(self._Character, AttributeDefinition.IsDead) then
		return Result.err(`there's no avatar to emote with`)
	end
	local trackRes = play(self, definition)
	if trackRes.IsErr then
		return Result.err(trackRes.Value)
	end
	local track = trackRes.Value

	endEmote(self)
	self._EmoteId = emoteId
	self._EmoteTrack = track
	self._EmoteConnection = track.Stopped:Connect(function()
		-- a track that was played again while it faded out is still going
		if self._EmoteTrack == track and not track.IsPlaying then
			self:Stop()
		end
	end)
	if definition.IsRooting then
		root(self, humanoid)
	else
		unroot(self)
	end
	updatePose(self)
	self.EmoteChanged:Fire(emoteId)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function EmoteService:Stop()
	if not endEmote(self) then
		return
	end
	unroot(self)
	updatePose(self)
	self.EmoteChanged:Fire(nil)
end

return ServiceLocker(function(): EmoteService
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local player = Players.LocalPlayer

	local self = setmetatable({
		IsInitialized = true :: true,
		EmoteChanged = Signal.new(),
		_Character = nil :: Model?,
		_EmoteId = nil :: EmoteId?,
		_EmoteTrack = nil :: AnimationTrack?,
		_EmoteConnection = nil :: RBXScriptConnection?,
		_PoseTrack = nil :: AnimationTrack?,
		_PoseConnection = nil :: RBXScriptConnection?,
		_Tracks = {} :: { [string]: AnimationTrack },
		_WalkLock = nil :: WalkLock?,
		_CharacterConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, EmoteService)

	table.insert(
		self._Connections,
		player.CharacterAdded:Connect(function(character: Model)
			setCharacter(self, character)
		end)
	)
	table.insert(
		self._Connections,
		player.CharacterRemoving:Connect(function(character: Model)
			if self._Character == character then
				setCharacter(self, nil)
			end
		end)
	)
	setCharacter(self, player.Character)

	local hudConnection = ShellService.GameplayHudVisibleChanged:Connect(function(isGameplayHudVisible: boolean)
		if not isGameplayHudVisible then
			self:Stop()
		end
	end)
	local swapConnection = ShellService.SwapRequested:Connect(function()
		self:Stop()
	end)
	table.insert(self._CleanUpCallbacks, function()
		hudConnection:Disconnect()
		swapConnection:Disconnect()
	end)
	table.insert(self._CleanUpCallbacks, function()
		setCharacter(self, nil)
	end)

	return self
end, function(self: EmoteService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.EmoteChanged:Destroy()
	table.clear(self :: any)
end)
