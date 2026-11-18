--!strict
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ClientVFXLibrary = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library")
local Driver = require("@game/ReplicatedStorage/Shared/VFX/Driver")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Scope = require("@game/ReplicatedStorage/Shared/VFX/Scope")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type ClientOptions = VFXType.ClientOptions
type Subject = VFXType.Subject
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
type Message = VFXType.Message
type ClientScope = VFXType.ClientScope
type VFXServiceImpl = {
	__index: VFXServiceImpl,
	NewScope: (self: VFXService, character: Model?) -> ClientScope,
}
export type VFXService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Driver: VFXType.Driver,
		-- what stops the states the server has this client hold, by the id it gave them
		_Cleanups: { [string]: Cleanup },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: VFXServiceImpl
))
-- Constants
-- what the level reads as while the player leaves it to the engine
local AUTOMATIC_QUALITY_LEVEL = 10
-- Variables
-- References
-- Private Functions
-- the culling: an effect that wouldn't be made out or that the machine is too slow for isn't shown at all
local function getIfShown(vfx: VFX, subject: Subject, options: ClientOptions?): boolean
	if not options then
		return true
	end
	if options.MinQualityLevel then
		local level = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
		if (if level == 0 then AUTOMATIC_QUALITY_LEVEL else level) < options.MinQualityLevel then
			return false
		end
	end
	local camera = Workspace.CurrentCamera
	-- a state may still be on once the camera gets there, only something that's over in a moment is skipped
	if vfx.Kind == "Event" and options.Range and camera and subject.Character and not subject.IsOwner then
		if (subject.Character:GetPivot().Position - camera.CFrame.Position).Magnitude > options.Range then
			return false
		end
	end
	return true
end

-- what the player's own machine does to their own avatar is theirs to pass on, where the use of it asks for that
local function getIfPassedOn(subject: Subject, options: ClientOptions?): boolean
	return options ~= nil
		and options.IsReplicated == true
		and subject.IsOwner
		and subject.Character == Players.LocalPlayer.Character
end

local function onFire(vfx: VFX, props: unknown, subject: Subject, options: ClientOptions?)
	if not getIfPassedOn(subject, options) or not NetworkService.IsInitialized then
		return
	end
	NetworkService:Fire(
		RemoteDefinition.VFXReported,
		table.freeze({
			Type = "Fire" :: "Fire",
			Name = vfx.Name,
			Props = props,
		})
	)
end

local function onStart(vfx: VFX, props: unknown, subject: Subject, swap: Swap?, options: ClientOptions?): Cleanup?
	if not getIfPassedOn(subject, options) or not NetworkService.IsInitialized then
		return nil
	end
	local id = HttpService:GenerateGUID(false)
	NetworkService:Fire(
		RemoteDefinition.VFXReported,
		table.freeze({
			Type = "Start" :: "Start",
			Name = vfx.Name,
			Props = props,
			Id = id,
			Swap = swap,
		})
	)
	return function(stopSwap: Swap?)
		if NetworkService.IsInitialized then
			NetworkService:Fire(
				RemoteDefinition.VFXReported,
				table.freeze({
					Type = "Stop" :: "Stop",
					Id = id,
					Swap = stopSwap,
				})
			)
		end
	end
end

-- an effect the server tells of: its own or one another player's machine passed on
local function onReplicated(self: VFXService, message: Message)
	if message.Type == "Stop" then
		local cleanup = self._Cleanups[message.Id]
		self._Cleanups[message.Id] = nil
		if cleanup then
			cleanup(message.Swap)
		end
		return
	end
	local vfxRes = ClientVFXDefinition.get(message.Name)
	if vfxRes.IsErr then
		warn(`vfx err: {vfxRes.Value}`)
		return
	end
	local vfx = vfxRes.Value
	local success, msg = vfx.Props(message.Props)
	if not success then
		warn(`dropped the "{message.Name}" effect: {msg}`)
		return
	end
	local character = message.Character
	local subject: Subject = table.freeze({
		Character = character,
		Player = if character then Players:GetPlayerFromCharacter(character) else nil,
		IsOwner = false,
	})
	if message.Type == "Fire" then
		self._Driver.Fire(
			vfx,
			message.Props,
			subject,
			table.freeze({ Range = message.Range, MinQualityLevel = message.MinQualityLevel })
		)
	elseif not self._Cleanups[message.Id] then
		local cleanup = self._Driver.Start(
			vfx,
			message.Props,
			subject,
			message.Swap,
			table.freeze({ MinQualityLevel = message.MinQualityLevel })
		)
		if cleanup then
			self._Cleanups[message.Id] = cleanup
		end
	end
end
-- Class
local VFXService = {} :: VFXServiceImpl
VFXService.__index = VFXService

-- what the effects the local player sets off themselves are run with
function VFXService:NewScope(character: Model?): ClientScope
	assert(self.IsInitialized, `the vfx service isn't initialized`)
	local scope = Scope.new(
		table.freeze({
			Character = character,
			Player = Players.LocalPlayer,
			IsOwner = true,
		}),
		self._Driver
	)
	return scope
end

return ServiceLocker(function(): VFXService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Driver = Driver.new({
			GetImplementation = ClientVFXLibrary.get,
			RunsServer = false,
			GetIfShown = getIfShown,
			OnFire = onFire,
			OnStart = onStart,
		}),
		_Cleanups = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, VFXService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.VFXReplicated, function(message: Message)
			onReplicated(self, message)
		end)
	)

	return self
end, function(self: VFXService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, cleanup in self._Cleanups do
		task.spawn(cleanup, nil)
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
