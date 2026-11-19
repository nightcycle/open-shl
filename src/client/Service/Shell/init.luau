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
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Flow = require("@self/Flow")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Types
local ShellType = require("@self/Types")
local TutorialType = require("@game/ReplicatedStorage/Shared/Type/Tutorial")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
type MenuRefusal = SessionService.MenuRefusal
export type BootPhase = ShellType.BootPhase
export type Screen = ShellType.Screen
export type ScreenType = ShellType.ScreenType
export type PanelId = ShellType.PanelId
type Stop = ShellType.Stop
type MenuAction = ShellType.MenuAction
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
local SCREEN_TRIGGERS: { [ScreenType]: Trigger } = table.freeze({
	CharacterSelect = "CharactersOpened",
	CharacterEditor = "EditorOpened",
	ArtifactMenu = "ArtifactMenuOpened",
})
-- the phases the game that's built goes through on the way in, in order
local STOPS: { Stop } = Flow.Stops
-- the screen the boot ends on. a game without one ends on its hud, as whoever the server picked
local FIRST_SCREEN: Screen? = Flow.FirstScreen
-- where a button of the hud leads, one the game has no use for leads nowhere
local MENU: { [PseudoEnum.MenuId]: MenuAction } = Flow.Menu
-- Variables
-- References
-- Private Functions
-- a player the game sent here picked their mode on the way
local function getIfModeSelectShown(): boolean
	return BUILD_CONFIG.MODE_SELECT_ENABLED
		and not AttributeDefinition.get(Players.LocalPlayer, AttributeDefinition.IsModeChosen)
end

-- the next phase of the game that has something to show, the game itself after the last
local function getNextBootPhase(bootPhase: BootPhase): BootPhase
	-- the browser is a side room of the mode screen, whoever leaves it goes on from there
	local from: BootPhase = bootPhase
	if bootPhase == "ServerBrowser" then
		from = "ModeSelect"
	end
	local index: number? = nil
	for i, stop in STOPS do
		if stop == from then
			index = i
			break
		end
	end
	if index then
		for i = index + 1, #STOPS do
			local stop: BootPhase = STOPS[i]
			-- a mode is only picked by whoever came without one, every other phase is everybody's
			local isShown = stop ~= "ModeSelect" or getIfModeSelectShown()
			if isShown then
				return stop
			end
		end
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
	local action: MenuAction? = MENU[menuId]
	if not action then
		return
	end
	if action.Type == "CameraMode" then
		self:SetCameraMode(not self._State.IsCameraMode)
	elseif self._State.IsCameraMode then
		return
	elseif action.Type == "Swap" then
		self.SwapRequested:Fire()
	elseif action.Type == "Screen" then
		-- the screen the avatar is swapped for another on
		if action.Screen.Type == "CharacterSelect" then
			local avatar = Players.LocalPlayer.Character
			-- a dead avatar has to get up before it can be swapped for another
			if AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
				return
			end
			-- one that's in a fight has to see it through first, the server wouldn't count it as in the menu anyway
			local fightingUntil = AttributeDefinition.get(avatar, AttributeDefinition.FightingUntil)
			if CombatDefinition.getIfFighting(fightingUntil, CombatDefinition.getTime()) then
				return
			end
		end
		self:OpenScreen(action.Screen)
	elseif action.Type == "Panel" then
		self:TogglePanel(action.PanelId)
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
		BootPhase = STOPS[1],
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
	-- the server didn't count the avatar as in a menu: it's in a fight this client hadn't heard of when it said so
	local refusedConnection = SessionService.MenuRefused:Connect(function(refusal: MenuRefusal)
		if self._State.IsGameplayHudVisible then
			return
		end
		-- whoever pressed their way in is back where they pressed, as if the button had been faded in time
		if self._HasHudShown then
			self:CloseScreen()
			return
		end
		-- nobody pressed their way into the menus of the boot, so they stay up + ask again once the fight is over
		task.delay(math.max(refusal.Until - CombatDefinition.getTime(), 0), function()
			if self.IsInitialized and SessionService.IsInitialized and not self._State.IsGameplayHudVisible then
				SessionService:SetInMenu(true)
			end
		end)
	end)
	table.insert(self._CleanUpCallbacks, function()
		refusedConnection:Disconnect()
	end)

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
