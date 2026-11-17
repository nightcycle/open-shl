--!strict
--!native
-- Services
local GuiService = game:GetService("GuiService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local AppIsCameraModeAvailableContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraModeAvailable")
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local AppIsInResidenceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsInResidence")
local AppPanelContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Panel")
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
-- Types
type BootPhase = ShellService.BootPhase
type Screen = ShellService.Screen
type PanelId = ShellService.PanelId
export type Properties = {
	children: { [string]: React.ReactNode }?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the inset has no signal of its own, the top bar says when it's laid out again
local function useTopInset(): number
	local topInset, setTopInset = React.useState(function(): number
		return GuiService:GetGuiInset().Y
	end)
	React.useEffect(function()
		local function update()
			setTopInset(GuiService:GetGuiInset().Y)
		end
		local connection = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(update)
		-- the top bar may have been laid out between the render + the effect
		update()
		return function()
			connection:Disconnect()
		end
	end, {})
	return topInset
end
-- Class
return function(props: Properties): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local bootPhase = useSignalState(ShellService.BootPhaseChanged, function(): BootPhase
		return ShellService:GetBootPhase()
	end)
	local screen = useSignalState(ShellService.ScreenChanged, function(): Screen
		return ShellService:GetScreen()
	end)
	local panel = useSignalState(ShellService.PanelChanged, function(): PanelId?
		return ShellService:GetPanel()
	end)
	local isCameraMode = useSignalState(ShellService.CameraModeChanged, function(): boolean
		return ShellService:GetIsCameraMode()
	end)
	local isInResidence = useSignalState(ShellService.ResidenceChanged, function(): boolean
		return ShellService:GetIsInResidence()
	end)
	local isGameplayHudVisible = useSignalState(ShellService.GameplayHudVisibleChanged, function(): boolean
		return ShellService:GetIsGameplayHudVisible()
	end)
	local topInset = useTopInset()

	return e(AppBootPhaseContext.Provider, {
		value = bootPhase,
	}, {
		Screen = e(AppScreenContext.Provider, {
			value = screen,
		}, {
			Panel = e(AppPanelContext.Provider, {
				value = panel,
			}, {
				IsCameraMode = e(AppIsCameraModeContext.Provider, {
					value = isCameraMode,
				}, {
					IsCameraModeAvailable = e(AppIsCameraModeAvailableContext.Provider, {
						value = ShellService:GetIsCameraModeAvailable(),
					}, {
						IsInResidence = e(AppIsInResidenceContext.Provider, {
							value = isInResidence,
						}, {
							IsGameplayHudVisible = e(AppIsGameplayHudVisibleContext.Provider, {
								value = isGameplayHudVisible,
							}, {
								TopInset = e(AppTopInsetContext.Provider, {
									value = topInset,
								}, props.children),
							}),
						}),
					}),
				}),
			}),
		}),
	})
end
