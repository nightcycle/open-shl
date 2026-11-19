--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Hooks
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Scene = useScene.Scene
export type Appearance = AppearanceType.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(scene: Scene?, appearance: Appearance?)
	local rig = if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil
	-- a rig in a scene stands for a character of the player's own, so in a game whose bodies wear the shirt + the
	-- pants of the account it wears theirs. the server asks for those once a session, a moment after the join
	local shirtAssetId = usePlayerAttribute(AttributeDefinition.ShirtAssetId)
	local pantsAssetId = usePlayerAttribute(AttributeDefinition.PantsAssetId)
	-- a rig is only dressed again for what shows on it, a new death or transformation style keeps the very same items
	React.useEffect(function()
		if not rig or not appearance then
			return function() end
		end
		local isDead = false
		task.spawn(function()
			local resF: TypeUnionLib.Future<TypeUnionLib.Result<true, { string }>> = TypeUnionLib.Future.awaitUntil(
				AppearanceUtil.apply(rig, appearance, AppearanceUtil.getClothes(Players.LocalPlayer)),
				function()
					return isDead
				end
			)
			if resF.IsDone and resF.Value.IsErr then
				for _, message in resF.Value.Value do
					warn(`appearance err: {message}`)
				end
			end
		end)
		return function()
			isDead = true
		end
	end, {
		appearance and appearance.Items :: any,
		appearance and appearance.HiddenTags,
		appearance and appearance.SkinColor,
		-- never nil, a hole would cut the list short of the rig
		appearance and appearance.Scale or false,
		shirtAssetId or false,
		pantsAssetId or false,
		rig,
	})
end
