--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
export type EmoteId = RoleplayType.EmoteId
export type EmoteDefinition = RoleplayType.EmoteDefinition
export type PoseDefinition = RoleplayType.PoseDefinition
-- Constants
-- animations are owned by the old place
local DEFINITIONS: { EmoteDefinition } = {
	{
		Id = "HandsBehindBack",
		Name = "Hands Behind Back",
		AnimationId = Animation.emote["hands-behind-back.rbxm"],
		IsLooped = true,
		IsRooting = true,
	},
	{
		Id = "HeroicPose",
		Name = "Heroic Pose",
		AnimationId = Animation.emote["heroic-pose.rbxm"],
		IsLooped = true,
		IsRooting = true,
	},
	{
		Id = "Kneel",
		Name = "Kneel",
		AnimationId = Animation.emote["kneel.rbxm"],
		IsLooped = true,
		IsRooting = true,
	},
	{
		Id = "Laugh",
		Name = "Laugh",
		AnimationId = Animation.emote["laugh.rbxm"],
		IsLooped = true,
		IsRooting = true,
	},
	{
		Id = "Point",
		Name = "Point",
		AnimationId = Animation.emote["point.rbxm"],
		IsLooped = true,
		IsRooting = true,
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- not an emote, a cuffed character can still walk around
local HANDCUFFS: PoseDefinition = table.freeze({
	Name = "Handcuffs",
	AnimationId = Animation.emote["handcuffs.rbxm"],
	IsLooped = true,
	IsRooting = false,
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

for _, DEFINITION in DEFINITIONS do
	assert(RoleplayType.EmoteDefinition(DEFINITION))
end
assert(RoleplayType.PoseDefinition(HANDCUFFS))

Module.HANDCUFFS = HANDCUFFS

Module.get = function(id: string): Result<EmoteDefinition, string>
	for _, definition in DEFINITIONS do
		if definition.Id == id then
			return Result.ok(definition)
		end
	end
	return Result.err(`no emote "{id}"`)
end

Module.list = function(): { EmoteDefinition }
	return DEFINITIONS
end

return Module
