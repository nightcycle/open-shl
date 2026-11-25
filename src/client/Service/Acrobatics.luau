--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AbilityService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Ability")
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local VFXService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Result<V, E> = TypeUnionLib.Result<V, E>
-- the move underway, the next one can't begin until it's over
type Tumble = {
	Avatar: Model,
	-- nil until the effect is on
	Handle: VFXType.Handle?,
	Connections: { RBXScriptConnection },
}
type AcrobaticsServiceImpl = {
	__index: AcrobaticsServiceImpl,
	-- if a move of the local player is underway
	GetIfTumbling: (self: AcrobaticsService) -> boolean,
	-- throws the avatar of the local player into a move. turned down with a word on why: while another is underway,
	-- while the avatar is down, seated or behind a menu, + while an ability has the hand
	Play: (self: AcrobaticsService, moveId: string) -> Result<true, string>,
	-- ends the move that's underway + has an avatar that was left lying get back up
	Fix: (self: AcrobaticsService) -> (),
}
export type AcrobaticsService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Tumble: Tumble?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AcrobaticsServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- whatever it's ended by, the body is let go of: nothing of a move outlasts it
local function stop(self: AcrobaticsService)
	local tumble = self._Tumble
	if not tumble then
		return
	end
	self._Tumble = nil
	for _, v in tumble.Connections do
		v:Disconnect()
	end
	if tumble.Handle then
		tumble.Handle.Stop()
	end
end
-- Class
local AcrobaticsService = {} :: AcrobaticsServiceImpl
AcrobaticsService.__index = AcrobaticsService

function AcrobaticsService:GetIfTumbling(): boolean
	assert(self.IsInitialized, `the acrobatics service isn't initialized`)
	return self._Tumble ~= nil
end

function AcrobaticsService:Play(moveId: string): Result<true, string>
	assert(self.IsInitialized, `the acrobatics service isn't initialized`)
	assert(AbilityService.IsInitialized, `the ability service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local moveRes = AcrobaticsDefinition.get(moveId)
	if moveRes.IsErr then
		return Result.err(moveRes.Value)
	end
	local move = moveRes.Value
	-- one at a time, as it always was
	if self._Tumble then
		return Result.err(`a move is underway`)
	end
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	if not avatar or not humanoid or not avatar.PrimaryPart then
		return Result.err(`there's no avatar to move`)
	end
	if humanoid.Health <= 0 or AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
		return Result.err(`the avatar is down`)
	end
	if humanoid.SeatPart then
		return Result.err(`the avatar is seated`)
	end
	if not ShellService:GetIsGameplayHudVisible() then
		return Result.err(`the avatar is behind a menu`)
	end
	-- what flies or swings a body has it to itself
	if AbilityService:GetIfEngaged() then
		return Result.err(`an ability has the avatar`)
	end

	local tumble: Tumble = {
		Avatar = avatar,
		Handle = nil,
		Connections = {},
	}
	self._Tumble = tumble
	-- a body that goes down in the air is let go of then + there
	table.insert(
		tumble.Connections,
		humanoid.Died:Connect(function()
			if self._Tumble == tumble then
				stop(self)
			end
		end)
	)
	-- nothing of it is anybody else's to be told: a body is its own client's to move, the others see it move
	local handle = VFXService:NewScope(avatar).start(
		ClientVFXDefinition.Tumble,
		table.freeze({
			Up = move.Up,
			Forward = move.Forward,
			Phases = move.Phases,
			IsTurned = move.IsTurned,
			OnEnded = function()
				if self._Tumble == tumble then
					stop(self)
				end
			end,
		})
	)
	-- an effect that couldn't hold the body is over before it's handed back
	if self._Tumble == tumble then
		tumble.Handle = handle
	else
		handle.Stop()
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function AcrobaticsService:Fix()
	assert(self.IsInitialized, `the acrobatics service isn't initialized`)
	assert(AbilityService.IsInitialized, `the ability service isn't initialized`)
	stop(self)
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	if not avatar or not humanoid then
		return
	end
	-- a body that's down stays down, one an ability holds is that ability's to put right
	if humanoid.Health <= 0 or AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
		return
	end
	if AbilityService:GetIfEngaged() then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

return ServiceLocker(function(): AcrobaticsService
	assert(AbilityService.IsInitialized, `the ability service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)

	local self = setmetatable({
		IsInitialized = true :: true,
		_Tumble = nil :: Tumble?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AcrobaticsService)

	-- an ability that takes the hand mid move wins, the way it does over anything else that's held
	local engagedConnection = AbilityService.EngagedChanged:Connect(function(isEngaged: boolean)
		if isEngaged then
			stop(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		engagedConnection:Disconnect()
	end)
	-- a menu that takes the screen takes the avatar out of play
	local hudConnection = ShellService.GameplayHudVisibleChanged:Connect(function(isVisible: boolean)
		if not isVisible then
			stop(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		hudConnection:Disconnect()
	end)
	-- an avatar that's replaced mid move takes the movers with it, the next one starts out clean
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterRemoving:Connect(function(avatar: Model)
			local tumble = self._Tumble
			if tumble and tumble.Avatar == avatar then
				stop(self)
			end
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		stop(self)
	end)

	return self
end, function(self: AcrobaticsService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
