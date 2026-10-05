--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

Util.createFromDescription = function(description: HumanoidDescription): TypeUnionLib.ToDo<Model>
	return Future.toDo(function(getIfCanceled)
		local avatar = Players:CreateHumanoidModelFromDescriptionAsync(
			description,
			Enum.HumanoidRigType.R15,
			Enum.AssetTypeVerification.ClientOnly
		)
		if getIfCanceled() then
			avatar:Destroy()
		end
		return avatar
	end)
end

return Util
