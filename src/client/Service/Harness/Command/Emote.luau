--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EmoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Emote")
local EmoteService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Emote")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
local EMOTE_IDS: { string } = {}
for _, definition in EmoteDefinition.list() do
	table.insert(EMOTE_IDS, definition.Id)
end
table.freeze(EMOTE_IDS)
local EMOTE_ID = Harness.newArgument(
	"EmoteId",
	"string",
	-- a game that holds its villains without anything to act out has the service + no row
	if #EMOTE_IDS > 0 then Type.literal(table.unpack(EMOTE_IDS)) else Type.string,
	`the id of an emote, one of {table.concat(EMOTE_IDS, ", ")}`
)
-- seconds an animation is given to load its clip before its track is read
local SETTLE_DURATION = 0.5
-- Variables
-- References
-- Private Functions
-- what plays on the avatar, as its animator has it: a track without a length is an animation that didn't come down
local function getState(): { [string]: any }
	assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local tracks: { any } = {}
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			local animation = track.Animation
			table.insert(tracks, {
				AnimationId = if animation then animation.AnimationId else nil,
				Length = track.Length,
				IsLooped = track.Looped,
				Priority = track.Priority.Name,
			})
		end
	end
	return {
		EmoteId = EmoteService:GetEmoteId(),
		Tracks = tracks,
		WalkSpeed = if humanoid then humanoid.WalkSpeed else nil,
		IsMasked = AttributeDefinition.get(avatar, AttributeDefinition.IsMasked),
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"emote.get",
			"the emote this client's avatar holds, every animation track that plays on it (a Length of 0 is a clip that didn't load), its walk speed (0 while a pose roots it) + whether its mask is on. EmoteIds are the emotes of the game in the order of their buttons",
			{},
			function(): Result<any, string>
				local state = getState()
				state.EmoteIds = EMOTE_IDS
				state.HasMaskPose = EmoteDefinition.MASK ~= nil
				return Result.ok(state)
			end
		),
		Harness.newCommand(
			"emote.play",
			"has this client's avatar act an emote out, the way its button does. answers half a second later with what plays",
			{ EMOTE_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
				local playRes = EmoteService:Play(args.EmoteId)
				if playRes.IsErr then
					return Result.err(playRes.Value)
				end
				task.wait(SETTLE_DURATION)
				return Result.ok(getState())
			end
		),
		Harness.newCommand("emote.stop", "lets go of the emote that's held", {}, function(): Result<any, string>
			assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
			EmoteService:Stop()
			return Result.ok(getState())
		end),
		Harness.newCommand(
			"emote.mask",
			"plays the gesture of a hand at the mask + nothing else: the mask itself is asked of the server by the button of the bar (or remote.fire SetMasked). answers half a second later with what plays",
			{},
			function(): Result<any, string>
				assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
				local maskRes = EmoteService:PlayMask()
				if maskRes.IsErr then
					return Result.err(maskRes.Value)
				end
				task.wait(SETTLE_DURATION)
				return Result.ok(getState())
			end
		),
	}
end

return Module
