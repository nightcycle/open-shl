--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local ArtifactScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/ArtifactScene")
-- Components
-- Hooks
-- Contexts
-- Types
export type ArtifactScene = ArtifactScene.ArtifactScene
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): (ArtifactScene?, () -> ())
	local scene: ArtifactScene?, setArtifactScene: (ArtifactScene?) -> () = React.useState(nil :: ArtifactScene?)
	local index, setIndex = React.useState(0)
	local indexRef = React.useRef(index)
	indexRef.current = index

	React.useEffect(function()
		local newController: ArtifactScene
		local isDead = false
		task.spawn(function()
			newController = ArtifactScene.new()
			assert(newController.IsAlive, `bad scene`)
			if newController.Rig.IsToDo then
				newController.Rig = Future.awaitUntil(newController.Rig, function()
					return isDead
				end)
			end
			if not isDead then
				setArtifactScene(newController)
			end
		end)
		return function()
			isDead = true
			setArtifactScene(nil)
			if newController.IsAlive then
				newController:Destroy()
			end
		end
	end, { index })

	return scene, function()
		setIndex(indexRef.current + 1)
	end
end
