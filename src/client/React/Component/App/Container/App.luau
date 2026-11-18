--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local App = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App")
local CharacterProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/CharacterProvider")
local Registry = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container")
local SessionProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/SessionProvider")
local ShellProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/ShellProvider")
local StyleProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/StyleProvider")
-- Hooks
-- Contexts
-- Types
type BootPhase = ShellService.BootPhase
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	return e(StyleProvider, {}, {
		SessionProvider = e(SessionProvider, {}, {
			CharacterProvider = e(CharacterProvider, {}, {
				ShellProvider = e(ShellProvider, {}, {
					App = e(
						App,
						{
							Size = UDim2.fromScale(1, 1),
							Registry = Registry,
							OnAction = function(action: App.ActionInfo)
								if action.Type == "MenuButtonPressed" then
									ShellService:PressMenuButton(action.MenuId)
								elseif action.Type == "ContainerFailed" then
									warn(`{action.Layer} "{action.Id}" failed: {action.Message}`)
									-- whatever broke lets go of the screen, so the player isn't left without a hud
									local bootPhase: BootPhase = ShellService:GetBootPhase()
									if action.Layer == "BootPhase" and bootPhase == action.Id then
										ShellService:FinishBootPhase(bootPhase)
									elseif action.Layer == "Screen" and ShellService:GetScreen().Type == action.Id then
										ShellService:CloseScreen()
									elseif action.Layer == "Panel" and ShellService:GetPanel() == action.Id then
										ShellService:ClosePanel()
									end
								end
							end,
						} :: App.Properties
					),
				}),
			}),
		}),
	})
end
