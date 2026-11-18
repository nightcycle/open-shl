--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local AppIsInResidenceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsInResidence")
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local TutorialContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
export type Home = TutorialDefinition.Home
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): boolean
	local progress = React.useContext(TutorialContext)
	local bootPhase: BootPhase = React.useContext(AppBootPhaseContext) :: BootPhase
	local screen = React.useContext(AppScreenContext)
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	local isCameraMode = React.useContext(AppIsCameraModeContext)
	local isInResidence = React.useContext(AppIsInResidenceContext)
	if not progress then
		return false
	end
	local home: Home = TutorialDefinition.getHome(progress.SectionId, progress.StepIndex)
	-- camera mode leaves nothing of the hud but its camera button
	if home == "Hud" then
		return isGameplayHudVisible and not isCameraMode
	elseif home == "Residence" then
		return isGameplayHudVisible and not isCameraMode and isInResidence
	elseif home == "CharacterEditor" then
		return screen.Type == "CharacterEditor"
	elseif home == "ArtifactMenu" then
		return screen.Type == "ArtifactMenu"
	else
		return bootPhase == "ModeSelect"
	end
end
