--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
-- Hooks
local useAppearance = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAppearance")
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
export type Properties = {
	Turn: number, -- how far the mannequin is turned away from the camera, in radians
}
-- Constants
local FIELD_OF_VIEW_ATTRIBUTE = "FieldOfView"
-- Variables
-- References
-- the booth is the same whoever stands in it, the scene of the hero is the one that's built
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/hero-character-editor") :: Folder
-- Private Functions
local e = React.createElement
-- Class
-- the booth with its one mannequin, seen from where the booth is looked into: it's dressed as whichever identity is
-- edited, the other one is never seen beside it
return function(props: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local character = React.useContext(CharacterContext)
	local previewCharacter = React.useContext(PreviewCharacterContext)
	local displayedCharacter = previewCharacter or character
	local secretIdentity = displayedCharacter.Identities.Secret
	local identity = if isHeroFocus or not secretIdentity then displayedCharacter.Identities.Main else secretIdentity

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local worldModelRef: { current: WorldModel? } = React.useRef(nil :: WorldModel?)
	local cameraRef: { current: Camera? } = React.useRef(nil :: Camera?)
	local scene = useScene(SceneTemplate)
	-- ahead of the appearance: the rig is in the world by the time it gets dressed
	React.useEffect(function()
		local worldModel = worldModelRef.current
		if scene and scene.IsAlive and worldModel then
			scene.Instance.Parent = worldModel
		end
		return function() end
	end, { scene })
	useAppearance(scene, identity.Appearance)

	local rig: Model? = if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil
	local rigAnchor = if scene and scene.IsAlive then scene.RigAnchor else nil
	local cameraMount = if scene and scene.IsAlive then scene.CameraMount else nil

	React.useEffect(function()
		local viewport, camera = viewportRef.current, cameraRef.current
		if viewport and camera then
			viewport.CurrentCamera = camera
		end
		return function() end
	end, {})

	-- the camera sits in the part the booth is looked into from + looks the way that does
	React.useEffect(function()
		local camera = cameraRef.current
		if camera and cameraMount then
			camera.CFrame = cameraMount.CFrame
			local fieldOfView = cameraMount:GetAttribute(FIELD_OF_VIEW_ATTRIBUTE)
			if type(fieldOfView) == "number" then
				camera.FieldOfView = fieldOfView
			end
		end
		return function() end
	end, { cameraMount })

	-- a rig that's dressed in another size is left standing where its old body stood, so it's put on its spot every
	-- frame rather than only when it's turned. a turn is a step, nothing eases it
	local turn = props.Turn
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			if rig and rigAnchor then
				RigUtil.moveTo(rig, rigAnchor.CFrame * CFrame.Angles(0, turn, 0))
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { rig :: any, rigAnchor, turn })

	return e(
		"ViewportFrame",
		{
			ZIndex = 0,
			Active = false,
			BackgroundTransparency = 1,
			ref = viewportRef,
			Position = UDim2.fromOffset(0, -topInset),
			Size = UDim2.new(1, 0, 1, topInset),
		} :: RobloxComponents.ViewportFrameProperties,
		{
			Camera = e("Camera", {
				ref = cameraRef,
			}),
			WorldModel = e("WorldModel", {
				ref = worldModelRef,
			}),
		}
	)
end
