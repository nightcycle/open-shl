--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Flow = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Flow")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local Registry = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
-- the gui the client's start script mounts the app into, + the frames the app keeps each kind of container in
local APP_NAME = "App"
local LAYER_NAMES = table.freeze({ "Panels", "Screens", "Overlays", "BootPhases", "TopOverlays" })
local HUD_NAME = "HUD"
-- what the app is given to draw what the shell was just told, before it's read off its instances
local SETTLE_DURATION = 0.1
-- the checker has the list for one of its own literals, which is no list of strings to it
local MENU_IDS: { string } = PseudoEnum.getEnumItems("MenuId") :: { any }
local MENU_ID = Harness.newArgument(
	"MenuId",
	"string",
	Type.literal(table.unpack(MENU_IDS)),
	`the id of a button of the hud, one of {table.concat(MENU_IDS, ", ")}`
)
local WHAT = Harness.newArgument(
	"What",
	"string",
	Type.literal("Panel", "Screen"),
	"Panel or Screen. left out: the panel if one is open, the screen otherwise"
)
-- Variables
-- References
-- Private Functions
-- why a button of that id can't be pressed in this game, nil for one that can: the flow of a game may hold the row
-- of a button its hud doesn't have, which the shell would follow into a menu nothing draws
local function getRefusal(menuId: PseudoEnum.MenuId): string?
	local action = Flow.Menu[menuId]
	if not action then
		return `the "{menuId}" button leads nowhere in this game`
	end
	if action.Type == "Panel" and not Registry.PANELS[action.PanelId] then
		return `this game has no "{action.PanelId}" panel for the "{menuId}" button to open`
	end
	if action.Type == "Screen" and not Registry.SCREENS[action.Screen.Type] then
		return `this game has no "{action.Screen.Type}" screen for the "{menuId}" button to open`
	end
	return nil
end

local function listKeys(dict: { [any]: any }): { string }
	local keys: { string } = {}
	for key in dict do
		table.insert(keys, tostring(key))
	end
	table.sort(keys)
	return keys
end

local function listChildren(parent: Instance?): { string }
	local names: { string } = {}
	if parent then
		for _, child in parent:GetChildren() do
			table.insert(names, child.Name)
		end
	end
	table.sort(names)
	return names
end

-- what the app has on the screen right now, read off its instances: a container is named by the id it's mounted under
local function getMounted(): { [string]: any }?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local gui = if playerGui then playerGui:FindFirstChild(APP_NAME) else nil
	local firstLayer = if gui then gui:FindFirstChild(LAYER_NAMES[1], true) else nil
	local root = if firstLayer then firstLayer.Parent else nil
	if not root then
		return nil
	end
	local mounted: { [string]: any } = {
		HUD = root:FindFirstChild(HUD_NAME) ~= nil,
	}
	for _, layerName in LAYER_NAMES do
		mounted[layerName] = listChildren(root:FindFirstChild(layerName))
	end
	return mounted
end

local function getState(): { [string]: any }
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	return {
		BootPhase = ShellService:GetBootPhase(),
		Screen = ShellService:GetScreen(),
		Panel = ShellService:GetPanel(),
		IsCameraMode = ShellService:GetIsCameraMode(),
		IsCameraModeAvailable = ShellService:GetIsCameraModeAvailable(),
		IsInResidence = ShellService:GetIsInResidence(),
		IsGameplayHudVisible = ShellService:GetIsGameplayHudVisible(),
		-- what the player took off their own screen
		IsHudHidden = ShellService:GetIsHudHidden(),
		AreNamesHidden = ShellService:GetAreNamesHidden(),
		-- the hud was up at least once since the client started
		HasHudShown = ShellService._HasHudShown,
		-- nil until the app drew for the first time
		Mounted = getMounted(),
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"shell.get",
			"where the client is: its boot phase, the open screen + panel, whether the hud is up, what the app has mounted",
			{},
			function(): Result<any, string>
				local state = getState()
				-- what this game could mount at all, + the buttons of its hud that lead somewhere
				state.Registry = {
					BootPhases = listKeys(Registry.BOOT_PHASES),
					Screens = listKeys(Registry.SCREENS),
					Panels = listKeys(Registry.PANELS),
					Overlays = listKeys(Registry.OVERLAYS),
					TopOverlays = listKeys(Registry.TOP_OVERLAYS),
				}
				state.Stops = Flow.Stops
				state.FirstScreen = Flow.FirstScreen
				local menu: { [string]: any } = {}
				for menuId, action in Flow.Menu do
					-- the checker widens a key it walks to a string
					if not getRefusal(menuId :: any) then
						menu[menuId] = action
					end
				end
				state.Menu = menu
				return Result.ok(state)
			end
		),
		Harness.newCommand(
			"shell.press",
			"presses a button of the hud by its id, through the shell the way the hud's own click does. answers with where that left the client: a press the shell turns down (the select of an avatar that's in a fight or down) leaves it where it was",
			{ MENU_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(ShellService.IsInitialized, `the shell service isn't initialized`)
				-- the two presses the shell drops without a word
				if not ShellService:GetIsGameplayHudVisible() then
					return Result.err(
						`the hud isn't up ({ShellService:GetBootPhase()}, {ShellService:GetScreen().Type}): no button to press`
					)
				end
				local refusal = getRefusal(args.MenuId)
				if refusal then
					return Result.err(`{refusal}, shell.get has the Menu of it`)
				end
				ShellService:PressMenuButton(args.MenuId)
				task.wait(SETTLE_DURATION)
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"shell.close",
			"closes the open panel or the open screen, the way its own close button does. answers with where that left the client",
			{ Harness.optional(WHAT) },
			function(args: { [string]: any }): Result<any, string>
				assert(ShellService.IsInitialized, `the shell service isn't initialized`)
				if args.What == nil and ShellService:GetPanel() == nil and ShellService:GetScreen().Type == "None" then
					return Result.err(`neither a panel nor a screen is open`)
				end
				local what: string = args.What or if ShellService:GetPanel() ~= nil then "Panel" else "Screen"
				if what == "Panel" then
					if ShellService:GetPanel() == nil then
						return Result.err(`no panel is open`)
					end
					ShellService:ClosePanel()
				else
					if ShellService:GetScreen().Type == "None" then
						return Result.err(`no screen is open`)
					end
					ShellService:CloseScreen()
				end
				task.wait(SETTLE_DURATION)
				return Result.ok(getState())
			end
		),
	}
end

return Module
