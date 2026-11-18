--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local HUD = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD")
local ParentComponent = require(".")
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local AppIsInResidenceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsInResidence")
local AppPanelContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Panel")
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
type Screen = AppScreenContext.Screen
type PanelId = AppPanelContext.PanelId
-- Constants
local BOOT_PHASES: { BootPhase } = { "Playing", "Loading", "ModeSelect", "ServerBrowser", "Intro" }
local NO_SCREEN: Screen = table.freeze({
	Type = "None" :: "None",
})
local PANEL_IDS: { [PseudoEnum.MenuId]: PanelId } = {
	Music = "Music",
	Actions = "Actions",
	Database = "Database",
	Shop = "Shop",
	Build = "Build",
}
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function placeholder(props: RobloxComponents.FrameProperties & {
	Text: string,
	OnExit: (() -> ())?,
})
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		},
		props,
		{
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 0.2),
				Text = props.Text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			Exit = props.OnExit and e(
				"TextButton",
				{
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.fromRGB(151, 75, 75),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.new(0.5, 0, 1, -8),
					Size = UDim2.fromScale(0.5, 0.2),
					Text = "Exit",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					[React.Event.Activated] = props.OnExit,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		BootPhase = UILabs.Choose(BOOT_PHASES),
		IsInResidence = UILabs.Boolean(false),
	},
}, function(props)
	local screen: Screen, setScreen: (Screen) -> () = React.useState(NO_SCREEN)
	local panel: PanelId?, setPanel: (PanelId?) -> () = React.useState(nil :: PanelId?)
	local isCameraMode, setIsCameraMode = React.useState(false)
	local bootPhase: BootPhase = props.controls.BootPhase :: BootPhase
	local isGameplayHudVisible = bootPhase == "Playing" and screen.Type == "None"

	local registry = React.useMemo(function(): ParentComponent.Registry
		local function newScreen(text: string): ParentComponent.Container
			return function(): React.ReactNode
				return e(placeholder, {
					Size = UDim2.fromScale(1, 1),
					Text = text,
					OnExit = function()
						setScreen(NO_SCREEN)
					end,
				})
			end
		end
		local function newPanel(text: string): ParentComponent.Container
			return function(): React.ReactNode
				return e(placeholder, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.3, 0.3),
					Text = text,
					OnExit = function()
						setPanel(nil)
					end,
				})
			end
		end
		local function newCover(text: string): ParentComponent.Container
			return function(): React.ReactNode
				return e(placeholder, {
					BackgroundTransparency = 0,
					Size = UDim2.fromScale(1, 1),
					Text = text,
				})
			end
		end
		return {
			HUD = HUD,
			BOOT_PHASES = {
				Loading = newCover("Loading"),
				ModeSelect = newCover("ModeSelect"),
				ServerBrowser = newCover("ServerBrowser"),
				Intro = newCover("Intro"),
			},
			SCREENS = {
				CharacterSelect = newScreen("CharacterSelect"),
				ArtifactMenu = newScreen("ArtifactMenu"),
			},
			PANELS = {
				Music = newPanel("Music"),
				Actions = newPanel("Actions"),
				Shop = newPanel("Shop"),
				Build = newPanel("Build"),
				-- throws on purpose: the app reports it + the rest of the interface stays up
				Database = function(): React.ReactNode
					error(`the database panel is broken on purpose`)
				end,
			},
			OVERLAYS = {
				ServerId = function(): React.ReactNode
					return e(placeholder, {
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.fromScale(0.15, 0.1),
						Text = "Overlay",
					})
				end,
			},
			TOP_OVERLAYS = {
				Tutorial = function(): React.ReactNode
					return e(placeholder, {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.fromScale(0.15, 0.1),
						Text = "Top overlay",
					})
				end,
			},
		}
	end, {})

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
					IsInResidence = e(AppIsInResidenceContext.Provider, {
						value = props.controls.IsInResidence,
					}, {
						IsGameplayHudVisible = e(AppIsGameplayHudVisibleContext.Provider, {
							value = isGameplayHudVisible,
						}, {
							App = e(
								ParentComponent,
								{
									AnchorPoint = Vector2.new(0.5, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									Size = UDim2.fromScale(1, 1),
									Registry = registry,
									OnAction = function(action: ParentComponent.ActionInfo)
										if action.Type == "ContainerFailed" then
											warn(`{action.Layer} "{action.Id}" failed: {action.Message}`)
											setScreen(NO_SCREEN)
											setPanel(nil)
										elseif action.MenuId == PseudoEnum.MenuId.Camera then
											setPanel(nil)
											setIsCameraMode(not isCameraMode)
										elseif action.MenuId == PseudoEnum.MenuId.Characters then
											setPanel(nil)
											setScreen({
												Type = "CharacterSelect",
											})
										elseif action.MenuId == PseudoEnum.MenuId.Artifact then
											setPanel(nil)
											setScreen({
												Type = "ArtifactMenu",
											})
										else
											local panelId: PanelId? = PANEL_IDS[action.MenuId]
											if panelId == panel then
												setPanel(nil)
											else
												setPanel(panelId)
											end
										end
									end,
									SizeConstraint = Enum.SizeConstraint.RelativeXY,
								} :: ParentComponent.Properties
							),
						}),
					}),
				}),
			}),
		}),
	})
end)
