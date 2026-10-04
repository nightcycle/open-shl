--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ArtifactScene = require(".")
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
-- Components
-- Hooks
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
	local controller: ArtifactScene.ArtifactScene?, setController = React.useState(nil :: ArtifactScene.ArtifactScene?)
	local appearance = React.useMemo(function()
		return {
			Items = {
				{
					DefinitionId = "costume/hoods/hood",
				},
				{
					DefinitionId = "costume/artifacts/bluesteel-fedora",
				},
			},
			HiddenTags = {},
		}
	end, {})

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return function() end
		end

		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")

		local cleanUp: () -> () = function() end
		task.spawn(function()
			if ArtifactScene.IsInitialized == false then
				cleanUp = ArtifactScene.init()
				setController(controller)
			end
			assert(ArtifactScene.IsInitialized, `bad scene`)
			ArtifactScene._Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = ArtifactScene._CameraMount.CFrame
		end)
		return function()
			setController(nil)
			cleanUp()
			worldModel:Destroy()
			camera:Destroy()
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
