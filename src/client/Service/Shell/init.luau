--!strict
-- Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Types
local ShellType = require("@self/Types")
local TutorialType = require("@game/ReplicatedStorage/Shared/Type/Tutorial")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
export type BootPhase = ShellType.BootPhase
export type Screen = ShellType.Screen
export type ScreenType = ShellType.ScreenType
export type PanelId = ShellType.PanelId
export type Trigger = TutorialType.Trigger
-- swapped for a new frozen table on every change
type State = {
	BootPhase: BootPhase,
	Screen: Screen,
	Panel: PanelId?,
	IsCameraMode: boolean,
	IsInResidence: boolean,
	IsBackpackLocked: boolean,
	IsGameplayHudVisible: boolean,
}
type ShellServiceImpl = {
	__index: ShellServiceImpl,
	GetBootPhase: (self: ShellService) -> BootPhase,
	GetScreen: (self: ShellService) -> Screen,
	GetPanel: (self: ShellService) -> PanelId?,
	GetIsCameraMode: (self: ShellService) -> boolean,
	GetIsCameraModeAvailable: (self: ShellService) -> boolean,
	GetIsInResidence: (self: ShellService) -> boolean,
	GetIsGameplayHudVisible: (self: ShellService) -> boolean,
	FinishBootPhase: (self: ShellService, bootPhase: BootPhase) -> (),
	SetServerBrowserOpen: (self: ShellService, isOpen: boolean) -> (),
	OpenScreen: (self: ShellService, screen: Screen) -> Result<true, string>,
	CloseScreen: (self: ShellService) -> (),
	OpenPanel: (self: ShellService, panelId: PanelId) -> Result<true, string>,
	ClosePanel: (self: ShellService, panelId: PanelId?) -> (),
	TogglePanel: (self: ShellService, panelId: PanelId) -> Result<true, string>,
	SetCameraMode: (self: ShellService, isCameraMode: boolean) -> Result<true, string>,
	SetIsInResidence: (self: ShellService, isInResidence: boolean) -> (),
	SetBackpackLocked: (self: ShellService, isLocked: boolean) -> (),
	PressMenuButton: (self: ShellService, menuId: PseudoEnum.MenuId) -> (),
	FireTutorialTrigger: (self: ShellService, trigger: Trigger) -> (),
}
export type ShellService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		BootPhaseChanged: Signal<BootPhase>,
		ScreenChanged: Signal<Screen>,
		PanelChanged: Signal<PanelId?>,
		CameraModeChanged: Signal<boolean>,
		ResidenceChanged: Signal<boolean>,
		GameplayHudVisibleChanged: Signal<boolean>,
		SwapRequested: Signal<>, -- the hud's swap button was pressed, the swap is up to whoever listens
		TutorialTriggered: Signal<Trigger>,
		_State: State,
		_IsCameraModeAvailable: boolean, -- the free camera is flown with a keyboard
		_IsBackpackEnabled: boolean,
		_HasHudShown: boolean,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ShellServiceImpl
))
-- Constants
local PANEL_IDS: { [PseudoEnum.MenuId]: PanelId } = table.freeze({
	Music = "Music",
	Actions = "Actions",
	Database = "Database",
	Shop = "Shop",
	Build = "Build",
})
local SCREEN_TRIGGERS: { [ScreenType]: Trigger } = table.freeze({
	CharacterSelect = "CharactersOpened",
	CharacterEditor = "EditorOpened",
	ArtifactMenu = "ArtifactMenuOpened",
})
-- the screen the boot ends on. a game without one ends on its hud, as whoever the server picked
local FIRST_SCREEN: Screen? = GameDefinition.tune(nil :: Screen?, {
	-- who to play as is picked on every join, its legacy place opened the character manager the same way
	shl3 = {
		Type = "CharacterSelect",
	} :: Screen,
})
-- Variables
-- References
-- Private Functions
-- a player the game sent here picked their mode on the way
local function getIfModeSelectShown(): boolean
	return BUILD_CONFIG.MODE_SELECT_ENABLED
		and not AttributeDefinition.get(Players.LocalPlayer, AttributeDefinition.IsModeChosen)
end

local function getNextBootPhase(bootPhase: BootPhase): BootPhase
	if bootPhase == "Loading" then
		return if getIfModeSelectShown() then "ModeSelect" else "Intro"
	elseif bootPhase == "ModeSelect" or bootPhase == "ServerBrowser" then
		return "Intro"
	end
	return "Playing"
end

-- the only place the state changes. a signal hands out what's current by the time it fires
local function setState(self: ShellService, state: State)
	local previous = self._State
	state.IsGameplayHudVisible = state.BootPhase == "Playing" and state.Screen.Type == "None"
	if not state.IsGameplayHudVisible then
		state.IsCameraMode = false
	end
	if not state.IsGameplayHudVisible or state.IsCameraMode then
		state.Panel = nil
	end
	if state.Panel == "Build" and not state.IsInResidence then
		state.Panel = nil
	end
	TableUtil.deepFreeze(state)
	self._State = state

	local isBackpackEnabled = state.IsGameplayHudVisible and not state.IsCameraMode and not state.IsBackpackLocked
	if self._IsBackpackEnabled ~= isBackpackEnabled then
		self._IsBackpackEnabled = isBackpackEnabled
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, isBackpackEnabled)
	end
	if previous.IsGameplayHudVisible ~= state.IsGameplayHudVisible then
		assert(SessionService.IsInitialized, `the session service isn't initialized`)
		-- the avatar is nobody's target while the player can't see it
		SessionService:SetInMenu(not state.IsGameplayHudVisible)
	end

	if previous.BootPhase ~= state.BootPhase then
		self.BootPhaseChanged:Fire(self._State.BootPhase)
	end
	if previous.IsCameraMode ~= state.IsCameraMode then
		self.CameraModeChanged:Fire(self._State.IsCameraMode)
	end
	if previous.Panel ~= state.Panel then
		self.PanelChanged:Fire(self._State.Panel)
	end
	if previous.Screen ~= state.Screen then
		self.ScreenChanged:Fire(self._State.Screen)
	end
	if previous.IsInResidence ~= state.IsInResidence then
		self.ResidenceChanged:Fire(self._State.IsInResidence)
	end
	if previous.IsGameplayHudVisible ~= state.IsGameplayHudVisible then
		self.GameplayHudVisibleChanged:Fire(self._State.IsGameplayHudVisible)
	end

	if previous.BootPhase ~= state.BootPhase and state.BootPhase == "ModeSelect" then
		self:FireTutorialTrigger("ModeSelectShown")
	end
	if state.IsGameplayHudVisible and not self._HasHudShown then
		self._HasHudShown = true
		self:FireTutorialTrigger("HudShown")
	end
	local screenTrigger: Trigger? = SCREEN_TRIGGERS[state.Screen.Type]
	if previous.Screen.Type ~= state.Screen.Type and screenTrigger then
		self:FireTutorialTrigger(screenTrigger)
	end
	if previous.Panel ~= state.Panel and state.Panel == "Build" then
		self:FireTutorialTrigger("BuildPressed")
	end
end
-- Class
local ShellService = {} :: ShellServiceImpl
ShellService.__index = ShellService

function ShellService:GetBootPhase(): BootPhase
	return self._State.BootPhase
end

function ShellService:GetScreen(): Screen
	return self._State.Screen
end

function ShellService:GetPanel(): PanelId?
	return self._State.Panel
end

function ShellService:GetIsCameraMode(): boolean
	return self._State.IsCameraMode
end

function ShellService:GetIsCameraModeAvailable(): boolean
	return self._IsCameraModeAvailable
end

function ShellService:GetIsInResidence(): boolean
	return self._State.IsInResidence
end

function ShellService:GetIsGameplayHudVisible(): boolean
	return self._State.IsGameplayHudVisible
end

function ShellService:FinishBootPhase(bootPhase: BootPhase)
	if self._State.BootPhase ~= bootPhase then
		return
	end
	local state = table.clone(self._State)
	state.BootPhase = getNextBootPhase(bootPhase)
	-- the boot is only left once. nothing could be opened during it, so there's no screen this takes the place of
	if FIRST_SCREEN and bootPhase ~= "Playing" and state.BootPhase == "Playing" then
		state.Screen = TableUtil.deepCopy(FIRST_SCREEN)
	end
	setState(self, state)
end

function ShellService:SetServerBrowserOpen(isOpen: boolean)
	local from: BootPhase = if isOpen then "ModeSelect" else "ServerBrowser"
	if self._State.BootPhase ~= from then
		return
	end
	local state = table.clone(self._State)
	state.BootPhase = if isOpen then "ServerBrowser" else "ModeSelect"
	setState(self, state)
end

function ShellService:OpenScreen(screen: Screen): Result<true, string>
	if screen.Type == "None" then
		self:CloseScreen()
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	if self._State.BootPhase ~= "Playing" then
		return Result.err(`can't open "{screen.Type}" while {self._State.BootPhase}`)
	end
	local state = table.clone(self._State)
	state.Screen = TableUtil.deepCopy(screen)
	setState(self, state)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function ShellService:CloseScreen()
	if self._State.Screen.Type == "None" then
		return
	end
	local state = table.clone(self._State)
	state.Screen = {
		Type = "None",
	}
	setState(self, state)
end

function ShellService:OpenPanel(panelId: PanelId): Result<true, string>
	if not self._State.IsGameplayHudVisible or self._State.IsCameraMode then
		return Result.err(`can't open "{panelId}" without the hud`)
	end
	if panelId == "Build" and not self._State.IsInResidence then
		return Result.err(`can't build outside of a residence`)
	end
	local state = table.clone(self._State)
	state.Panel = panelId
	setState(self, state)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- a panel that's named is only closed while it's the one that's up
function ShellService:ClosePanel(panelId: PanelId?)
	if self._State.Panel == nil or (panelId ~= nil and self._State.Panel ~= panelId) then
		return
	end
	local state = table.clone(self._State)
	state.Panel = nil
	setState(self, state)
end

function ShellService:TogglePanel(panelId: PanelId): Result<true, string>
	if self._State.Panel == panelId then
		self:ClosePanel()
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	end
	return self:OpenPanel(panelId)
end

function ShellService:SetCameraMode(isCameraMode: boolean): Result<true, string>
	if isCameraMode then
		if not self._IsCameraModeAvailable then
			return Result.err(`camera mode needs a keyboard`)
		elseif not self._State.IsGameplayHudVisible then
			return Result.err(`can't enter camera mode without the hud`)
		end
	end
	if self._State.IsCameraMode ~= isCameraMode then
		local state = table.clone(self._State)
		state.IsCameraMode = isCameraMode
		setState(self, state)
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function ShellService:SetIsInResidence(isInResidence: boolean)
	if self._State.IsInResidence == isInResidence then
		return
	end
	local state = table.clone(self._State)
	state.IsInResidence = isInResidence
	setState(self, state)
end

function ShellService:SetBackpackLocked(isLocked: boolean)
	if self._State.IsBackpackLocked == isLocked then
		return
	end
	local state = table.clone(self._State)
	state.IsBackpackLocked = isLocked
	setState(self, state)
end

function ShellService:PressMenuButton(menuId: PseudoEnum.MenuId)
	if not self._State.IsGameplayHudVisible then
		return
	end
	if menuId == PseudoEnum.MenuId.Camera then
		self:SetCameraMode(not self._State.IsCameraMode)
	elseif self._State.IsCameraMode then
		return
	elseif menuId == PseudoEnum.MenuId.Swap then
		self.SwapRequested:Fire()
	elseif menuId == PseudoEnum.MenuId.Characters then
		-- a dead avatar has to get up before it can be swapped for another
		if AttributeDefinition.get(Players.LocalPlayer.Character, AttributeDefinition.IsDead) then
			return
		end
		self:OpenScreen({
			Type = "CharacterSelect",
		})
	elseif menuId == PseudoEnum.MenuId.Artifact then
		self:OpenScreen({
			Type = "ArtifactMenu",
		})
	else
		local panelId: PanelId? = PANEL_IDS[menuId]
		if panelId then
			self:TogglePanel(panelId)
		end
	end
end

function ShellService:FireTutorialTrigger(trigger: Trigger)
	self.TutorialTriggered:Fire(trigger)
end

return ServiceLocker(function(): ShellService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)

	-- the game draws its own player list, health bar + emotes, the hotbar comes back with the gameplay hud
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	local state: State = {
		BootPhase = "Loading",
		Screen = {
			Type = "None",
		},
		Panel = nil,
		IsCameraMode = false,
		IsInResidence = false,
		IsBackpackLocked = false,
		IsGameplayHudVisible = false,
	}
	TableUtil.deepFreeze(state)

	local self = setmetatable({
		IsInitialized = true :: true,
		BootPhaseChanged = Signal.new(),
		ScreenChanged = Signal.new(),
		PanelChanged = Signal.new(),
		CameraModeChanged = Signal.new(),
		ResidenceChanged = Signal.new(),
		GameplayHudVisibleChanged = Signal.new(),
		SwapRequested = Signal.new(),
		TutorialTriggered = Signal.new(),
		_State = state,
		_IsCameraModeAvailable = UserInputService.KeyboardEnabled,
		_IsBackpackEnabled = false,
		_HasHudShown = false,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ShellService)

	SessionService:SetInMenu(not state.IsGameplayHudVisible)
	-- a new avatar starts out unfrozen, so the server hears it again
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterAdded:Connect(function()
			if not self._State.IsGameplayHudVisible and SessionService.IsInitialized then
				SessionService:SetInMenu(true)
			end
		end)
	)

	table.insert(self._CleanUpCallbacks, function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)

	return self
end, function(self: ShellService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.BootPhaseChanged:Destroy()
	self.ScreenChanged:Destroy()
	self.PanelChanged:Destroy()
	self.CameraModeChanged:Destroy()
	self.ResidenceChanged:Destroy()
	self.GameplayHudVisibleChanged:Destroy()
	self.SwapRequested:Destroy()
	self.TutorialTriggered:Destroy()
	table.clear(self :: any)
end)
