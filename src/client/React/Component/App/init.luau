--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local Boundary = require("@self/Boundary")
local HUD = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD")
-- Hooks
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
-- Types
local AppTypes = require("@self/Types")
type BootPhase = AppBootPhaseContext.BootPhase
type PanelId = AppPanelContext.PanelId
export type Container = AppTypes.Container
export type Registry = AppTypes.Registry
export type Layer = AppTypes.Layer
export type ActionInfo =
	{
		Type: "MenuButtonPressed",
		MenuId: PseudoEnum.MenuId,
	}
	| {
		Type: "ContainerFailed",
		Layer: Layer,
		Id: string,
		Message: string,
	}
export type Properties = RobloxComponents.FrameProperties & {
	Registry: Registry,
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- each kind of container gets a frame of its own, so what covers what doesn't hang on the menus themselves
local function layer(props: {
	ZIndex: number,
	children: { [string]: React.ReactNode }?,
})
	return e("Frame", {
		Active = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = props.ZIndex,
	}, props.children)
end
-- Class
return function(props: Properties)
	local bootPhase: BootPhase = React.useContext(AppBootPhaseContext) :: BootPhase
	local screen = React.useContext(AppScreenContext)
	local panel: PanelId? = React.useContext(AppPanelContext) :: PanelId?
	local isCameraMode = React.useContext(AppIsCameraModeContext)
	local isCameraModeAvailable = React.useContext(AppIsCameraModeAvailableContext)
	local isInResidence = React.useContext(AppIsInResidenceContext)
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)

	local registry = props.Registry
	local function contain(layerId: Layer, id: string, container: Container, resetKey: any?): React.ReactNode
		-- keyed by its id, so that's what the instance of the menu is called
		local children: { [string]: React.ReactNode } = {}
		children[id] = e(container, {})
		return e(Boundary, {
			ResetKey = resetKey,
			OnError = function(message: string)
				props.OnAction({
					Type = "ContainerFailed",
					Layer = layerId,
					Id = id,
					Message = message,
				})
			end,
		}, children)
	end

	local bootPhases: { [string]: React.ReactNode } = {}
	local bootContainer: Container? = registry.BOOT_PHASES[bootPhase]
	if bootContainer then
		bootPhases[bootPhase] = contain("BootPhase", bootPhase, bootContainer)
	end
	local screens: { [string]: React.ReactNode } = {}
	local screenContainer: Container? = registry.SCREENS[screen.Type]
	if screenContainer then
		-- reset by the screen, so the next one of the same type doesn't inherit the empty place of one that broke
		screens[screen.Type] = contain("Screen", screen.Type, screenContainer, screen)
	end
	local panels: { [string]: React.ReactNode } = {}
	local panelContainer: Container? = if panel then registry.PANELS[panel] else nil
	if panel and panelContainer and isGameplayHudVisible and not isCameraMode then
		panels[panel] = contain("Panel", panel, panelContainer)
	end
	local overlays: { [string]: React.ReactNode } = {}
	for id, container in registry.OVERLAYS do
		overlays[id] = contain("Overlay", id, container)
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			HUD = isGameplayHudVisible and e(
				HUD,
				{
					Size = UDim2.fromScale(1, 1),
					ZIndex = 1,
					IsBuildVisible = isInResidence,
					IsCameraMode = isCameraMode,
					IsCameraHidden = not isCameraModeAvailable,
					IsHealthVisible = BUILD_CONFIG.PVP_ENABLED,
					IsEnergyVisible = BUILD_CONFIG.ENERGY_ENABLED,
					OnClick = function(menuId: PseudoEnum.MenuId)
						props.OnAction({
							Type = "MenuButtonPressed",
							MenuId = menuId,
						})
					end,
				} :: HUD.Properties
			),
			Panels = e(layer, {
				ZIndex = 2,
			}, panels),
			Screens = e(layer, {
				ZIndex = 3,
			}, screens),
			Overlays = e(layer, {
				ZIndex = 4,
			}, overlays),
			BootPhases = e(layer, {
				ZIndex = 5,
			}, bootPhases),
		}
	))
end
