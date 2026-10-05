--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
local Future = TypeUnionLib.Future
-- Components
-- Hooks
local useArtifactScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useArtifactScene")
-- Contexts
local CharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Appearance")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
type Item = AppearanceType.Item
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {},
}, function(props)
	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local artifactScene, refreshScene = useArtifactScene()
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport or not artifactScene then
			return function() end
		end
		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")
		local cleanUp: () -> () = function() end
		task.spawn(function()
			assert(artifactScene.IsAlive, `bad scene`)
			artifactScene.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = artifactScene.CameraMount.CFrame
			camera.Parent = viewport
		end)
		return function()
			cleanUp()
			worldModel:Destroy()
			camera:Destroy()
			refreshScene()
		end
	end, { viewportRef.current :: any })

	return e(CharacterAppearanceContext.Provider, {
		value = appearance,
	}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				BackgroundTransparency = 1,
				ref = viewportRef,
				Size = UDim2.fromScale(1, 1),
			} :: ViewportFrame.Properties
		),
	})
end)
