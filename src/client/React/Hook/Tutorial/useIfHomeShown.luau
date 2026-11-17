--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Contexts
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local AppIsInResidenceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsInResidence")
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local TutorialContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial")
-- Types
export type Home = TutorialDefinition.Home
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): boolean
	local progress = React.useContext(TutorialContext)
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
	else
		return screen.Type == "ArtifactMenu"
	end
end
