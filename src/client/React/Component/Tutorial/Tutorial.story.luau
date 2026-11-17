--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local AppIsInResidenceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsInResidence")
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local TutorialContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial")
local TutorialIsEnabledContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial/IsEnabled")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
type Screen = AppScreenContext.Screen
type SectionId = TutorialDefinition.SectionId
type Home = TutorialDefinition.Home
type Progress = TutorialContext.Progress
-- Constants
local BOOT_PHASES: { BootPhase } = { "Playing", "Loading", "Intro" }
local NO_SCREEN: Screen = table.freeze({
	Type = "None" :: "None",
})
local OTHER_SCREEN: Screen = table.freeze({
	Type = "CharacterSelect" :: "CharacterSelect",
})
local HOME_SCREENS: { [Home]: Screen } = table.freeze({
	Hud = NO_SCREEN,
	Residence = NO_SCREEN,
	CharacterEditor = table.freeze({
		Type = "CharacterEditor" :: "CharacterEditor",
		CharacterId = "",
	}),
	ArtifactMenu = table.freeze({
		Type = "ArtifactMenu" :: "ArtifactMenu",
	}),
})
local SECTION_IDS: { SectionId } = {}
local MAX_STEP_COUNT = 1
for _, SECTION in TutorialDefinition.list() do
	table.insert(SECTION_IDS, SECTION.Id)
	MAX_STEP_COUNT = math.max(MAX_STEP_COUNT, #SECTION.Steps)
end
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newProgress(sectionId: SectionId, stepIndex: number): Progress?
	if stepIndex < 1 or stepIndex > #TutorialDefinition.get(sectionId).Steps then
		return nil
	end
	return table.freeze({
		SectionId = sectionId,
		StepIndex = stepIndex,
	})
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		BootPhase = UILabs.Choose(BOOT_PHASES),
		IsCameraMode = UILabs.Boolean(false),
		IsHomeShown = UILabs.Boolean(true),
		Section = UILabs.Choose(SECTION_IDS),
		Step = UILabs.Slider(1, 0, MAX_STEP_COUNT, 1),
	},
}, function(props)
	local sectionId: SectionId = props.controls.Section :: SectionId
	local stepIndex: number = props.controls.Step
	local isEnabled, setIsEnabled = React.useState(true)
	local progress: Progress?, setProgress: (Progress?) -> () = React.useState(nil :: Progress?)
	React.useEffect(function()
		setProgress(newProgress(sectionId, stepIndex))
		return function() end
	end, { sectionId :: any, stepIndex })

	local bootPhase: BootPhase = props.controls.BootPhase :: BootPhase
	local home: Home = TutorialDefinition.getHome(sectionId, if progress then progress.StepIndex else stepIndex)
	local screen: Screen = if props.controls.IsHomeShown then HOME_SCREENS[home] else OTHER_SCREEN

	return e(AppBootPhaseContext.Provider, {
		value = bootPhase,
	}, {
		Screen = e(AppScreenContext.Provider, {
			value = screen,
		}, {
			IsCameraMode = e(AppIsCameraModeContext.Provider, {
				value = props.controls.IsCameraMode,
			}, {
				IsInResidence = e(AppIsInResidenceContext.Provider, {
					value = home == "Residence",
				}, {
					IsGameplayHudVisible = e(AppIsGameplayHudVisibleContext.Provider, {
						value = bootPhase == "Playing" and screen.Type == "None",
					}, {
						Progress = e(TutorialContext.Provider, {
							value = if isEnabled then progress else nil,
						}, {
							IsEnabled = e(TutorialIsEnabledContext.Provider, {
								value = isEnabled,
							}, {
								Tutorial = e(
									ParentComponent,
									{
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.5, 0.5),
										Size = UDim2.fromScale(1, 1),
										OnAction = function(action: ParentComponent.ActionInfo)
											if action.Type == "Next" then
												if progress then
													setProgress(newProgress(progress.SectionId, progress.StepIndex + 1))
												end
											elseif action.Type == "SetEnabled" then
												setIsEnabled(action.IsEnabled)
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
		}),
	})
end)
