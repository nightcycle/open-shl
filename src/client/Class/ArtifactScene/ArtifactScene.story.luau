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
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
local Future = TypeUnionLib.Future
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
		local newController: ArtifactScene.ArtifactScene
		local cleanUp: () -> () = function() end
		task.spawn(function()
			newController = ArtifactScene.new()
			assert(newController.IsAlive, `bad scene`)
			newController.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = newController.CameraMount.CFrame
			camera.Parent = viewport
			if newController.Rig.IsToDo then
				newController.Rig = Future.poll(newController.Rig)
			end
		end)
		return function()
			cleanUp()
			if newController.IsAlive then
				newController:Destroy()
			end
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
