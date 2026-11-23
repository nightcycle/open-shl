--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
-- Modules
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
type Log = Log.Log
-- Constants
-- the kinds of event a client adds, each off a signal that was there before the harness. what the server fires at
-- the client isn't one of them: a second listener on an event of the network takes what was queued for the first
local KINDS = table.freeze({
	"BootPhase", -- the shell is in another phase of the way in: Value
	"Screen", -- another screen is open, or none: Type
	"Panel", -- another panel is open, or none: Value
	"CameraMode", -- IsCameraMode
	"Residence", -- IsInResidence
	"HudVisible", -- the hud of the game came up or went: IsVisible
	"Tutorial", -- something the tutorial waits for happened: Trigger
	"SwapRequested", -- the swap button of the hud was pressed
	"SessionLoaded", -- the snapshot of the session arrived
	"ActiveCharacterChanged", -- another slot or another identity is played: CharacterId, IdentityKey
	"MenuRefused", -- the server didn't count the avatar as in a menu
	"Spawned", -- the avatar of this player came in
	"Attribute", -- an attribute of that avatar changed: Name, Value
	"PlayerAttribute", -- an attribute of this player changed: Name, Value
	"Died", -- the humanoid of that avatar died
})
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

Util.KINDS = KINDS

-- everything the client's log hears of without a command having asked. answers with what stops it
function Util.start(log: Log): () -> ()
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local player = Players.LocalPlayer
	local subject = player.Name
	-- the signals of the engine + the ones of the services, both are cut the same way
	local connections: { any } = {}
	-- the ones of the avatar that's out, they go with it
	local function watchAvatar(character: Model)
		log:Add("Spawned", subject)
		character.AttributeChanged:Connect(function(name: string)
			log:Add("Attribute", subject, {
				Name = name,
				Value = character:GetAttribute(name),
			})
		end)
		-- the humanoid of a new avatar may be a moment behind it
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					log:Add("Died", subject)
				end)
			end
		end)
	end

	table.insert(
		connections,
		ShellService.BootPhaseChanged:Connect(function(bootPhase: ShellService.BootPhase)
			log:Add("BootPhase", subject, {
				Value = bootPhase,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.ScreenChanged:Connect(function(screen: ShellService.Screen)
			log:Add("Screen", subject, screen)
		end)
	)
	table.insert(
		connections,
		ShellService.PanelChanged:Connect(function(panelId: ShellService.PanelId?)
			log:Add("Panel", subject, {
				Value = panelId,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.CameraModeChanged:Connect(function(isCameraMode: boolean)
			log:Add("CameraMode", subject, {
				IsCameraMode = isCameraMode,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.ResidenceChanged:Connect(function(isInResidence: boolean)
			log:Add("Residence", subject, {
				IsInResidence = isInResidence,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.GameplayHudVisibleChanged:Connect(function(isVisible: boolean)
			log:Add("HudVisible", subject, {
				IsVisible = isVisible,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.TutorialTriggered:Connect(function(trigger: ShellService.Trigger)
			log:Add("Tutorial", subject, {
				Trigger = trigger,
			})
		end)
	)
	table.insert(
		connections,
		ShellService.SwapRequested:Connect(function()
			log:Add("SwapRequested", subject)
		end)
	)
	table.insert(
		connections,
		SessionService.Loaded:Connect(function()
			log:Add("SessionLoaded", subject)
		end)
	)
	table.insert(
		connections,
		SessionService.ActiveCharacterChanged:Connect(function(characterId: string, identityKey: string)
			log:Add("ActiveCharacterChanged", subject, {
				CharacterId = characterId,
				IdentityKey = identityKey,
			})
		end)
	)
	table.insert(
		connections,
		SessionService.MenuRefused:Connect(function(refusal: SessionService.MenuRefusal)
			log:Add("MenuRefused", subject, refusal)
		end)
	)
	table.insert(
		connections,
		player.AttributeChanged:Connect(function(name: string)
			log:Add("PlayerAttribute", subject, {
				Name = name,
				Value = player:GetAttribute(name),
			})
		end)
	)
	table.insert(connections, player.CharacterAdded:Connect(watchAvatar))
	if player.Character then
		watchAvatar(player.Character)
	end

	return function()
		for _, v in connections do
			v:Disconnect()
		end
	end
end

return Util
