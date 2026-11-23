--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
local DEFAULT_TIMEOUT = 30
local MAX_TIMEOUT = 120
-- the loading screen lets go by itself once the session + what it preloads are in. it's given this long before the
-- phase is finished for it, which is what the app does for a container that broke
local LOADING_GRACE = 6
local CHARACTER_ID = Harness.newArgument(
	"CharacterId",
	"string",
	Type.string,
	"the slot to come in as where the boot ends on the character select. left out: the one the server picked"
)
local TIMEOUT = Harness.newArgument(
	"Timeout",
	"number",
	Type.numberConstrained(1, MAX_TIMEOUT),
	`seconds the whole way in may take, {DEFAULT_TIMEOUT} when left out`
)
-- Variables
-- References
-- Private Functions
local function getIfInMenu(): boolean?
	local avatar = Players.LocalPlayer.Character
	return if avatar then AttributeDefinition.get(avatar, AttributeDefinition.IsInMenu) else nil
end

local function describe(steps: { string }): { [string]: any }
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	return {
		BootPhase = ShellService:GetBootPhase(),
		Screen = ShellService:GetScreen(),
		IsGameplayHudVisible = ShellService:GetIsGameplayHudVisible(),
		ActiveCharacterId = SessionService:GetActiveCharacterId(),
		-- what the server made of it: false once it counts the avatar as out of its menus
		IsInMenu = getIfInMenu(),
		Steps = steps,
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"boot.play",
			"walks the way into the game without a click: every boot phase of this game, then its character select through the real request. answers where it ended",
			{ Harness.optional(CHARACTER_ID), Harness.optional(TIMEOUT) },
			function(args: { [string]: any }): Result<any, string>
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				assert(ShellService.IsInitialized, `the shell service isn't initialized`)
				local timeout: number = args.Timeout or DEFAULT_TIMEOUT
				local deadline = os.clock() + timeout
				local steps: { string } = {}
				local function fail(message: string): Result<any, string>
					return Result.err(`{message} after {timeout} seconds. done so far: {table.concat(steps, "; ")}`)
				end

				while not SessionService:GetIsLoaded() do
					if os.clock() >= deadline then
						return fail(`the session hasn't arrived`)
					end
					task.wait()
				end
				table.insert(steps, "the session is in")

				-- every stop of the game is left the way its own screen leaves it: by telling the shell it's done.
				-- the mode screen is left for the mode of this place, which is a pick that goes to no server
				local loadingDeadline = os.clock() + LOADING_GRACE
				while ShellService:GetBootPhase() ~= "Playing" do
					if os.clock() >= deadline then
						return fail(`still in {ShellService:GetBootPhase()}`)
					end
					local bootPhase: ShellService.BootPhase = ShellService:GetBootPhase()
					if bootPhase == "Loading" and os.clock() < loadingDeadline then
						task.wait()
					elseif bootPhase == "ServerBrowser" then
						ShellService:SetServerBrowserOpen(false)
						table.insert(steps, "closed the server browser")
					else
						ShellService:FinishBootPhase(bootPhase)
						table.insert(steps, `finished {bootPhase}`)
					end
				end

				-- the screen a game ends its boot on. the select is left the way its own button leaves it: the server
				-- is asked for the slot, then the screen closes
				local screen = ShellService:GetScreen()
				if screen.Type == "CharacterEditor" then
					ShellService:CloseScreen()
					table.insert(steps, "closed the character editor")
					screen = ShellService:GetScreen()
				end
				if screen.Type == "CharacterSelect" then
					local characterId: string = args.CharacterId or SessionService:GetActiveCharacterId()
					local selectRes = SessionService:SelectCharacter(characterId)
					if selectRes.IsErr then
						return Result.err(
							`the server turned "{characterId}" down: {selectRes.Value}. done so far: {table.concat(
								steps,
								"; "
							)}`
						)
					end
					ShellService:FireTutorialTrigger("CharacterSelected")
					ShellService:CloseScreen()
					table.insert(steps, `selected {characterId}`)
				elseif screen.Type ~= "None" then
					ShellService:CloseScreen()
					table.insert(steps, `closed {screen.Type}`)
				end

				-- the shell told the server the avatar is out of its menus as the hud came up, the avatar says once
				-- the server agreed. one that's refused (a fight) stays in: that's an answer, not a failure
				while getIfInMenu() ~= false and os.clock() < deadline do
					task.wait()
				end
				return Result.ok(describe(steps))
			end
		),
	}
end

return Module
