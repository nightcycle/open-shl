--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
-- Components
local ServerId = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerId")
-- Hooks
-- Contexts
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
-- Types
export type Properties = {}
type Placement = {
	AnchorPoint: Vector2,
	Position: UDim2,
	Size: UDim2,
}
-- Constants
local PLACEMENT: Placement = {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(150, 30),
}
-- which corner the label has is the game's own
local GAME_PLACEMENT: Placement = GameDefinition.tune(PLACEMENT, {
	-- where its version label was: the bottom right, 5 px off both edges
	shl3 = {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -5, 1, -5),
		Size = UDim2.fromOffset(200, 25),
	},
})
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
			AnchorPoint = GAME_PLACEMENT.AnchorPoint,
			Position = GAME_PLACEMENT.Position,
			Size = GAME_PLACEMENT.Size,
			-- a photo is taken without the hud
			Visible = not isCameraMode,
			Id = if RunService:IsStudio() or id == "" then STUDIO_ID else id,
		} :: ServerId.Properties
	)
end
