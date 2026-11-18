--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
-- Components
local ServerId = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerId")
-- Hooks
-- Contexts
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
-- Types
export type Properties = {}
-- Constants
local SIZE = UDim2.fromOffset(150, 30)
-- a test session isn't a job anybody could join, so it has no id worth reading out
local STUDIO_ID = "STUDIO"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	local isCameraMode = React.useContext(AppIsCameraModeContext)
	local id = ServerDefinition.getId(game.JobId)

	return e(
		ServerId,
		{
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = SIZE,
			-- a photo is taken without the hud
			Visible = not isCameraMode,
			Id = if RunService:IsStudio() or id == "" then STUDIO_ID else id,
		} :: ServerId.Properties
	)
end
