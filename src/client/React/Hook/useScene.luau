--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local Scene = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Scene")
-- Components
-- Hooks
-- Contexts
-- Types
export type Scene = Scene.Scene
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(template: Folder): (Scene?, () -> ())
	local scene: Scene?, setScene: (Scene?) -> () = React.useState(nil :: Scene?)
	local index, setIndex = React.useState(0)
	local indexRef = React.useRef(index)
	indexRef.current = index

	React.useEffect(function()
		local newController: Scene
		local isDead = false
		task.spawn(function()
			newController = Scene.new(template)
			assert(newController.IsAlive, `bad scene`)
			if newController.Rig.IsToDo then
				newController.Rig = Future.awaitUntil(newController.Rig, function()
					return isDead
				end)
			end
			if not isDead then
				setScene(newController)
			end
		end)
		return function()
			isDead = true
			setScene(nil)
			if newController.IsAlive then
				newController:Destroy()
			end
		end
	end, { template :: any, index })

	return scene, function()
		setIndex(indexRef.current + 1)
	end
end
