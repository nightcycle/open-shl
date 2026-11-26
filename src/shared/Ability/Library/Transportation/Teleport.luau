--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	Cast: EventBinding, -- the avatar is gone from where it stood + there where the click pointed
	Recover: EventBinding,
}
-- what both halves of the teleport have to agree on
export type Config = {
	Range: number, -- studs from the avatar a spot may be to be gone to
	Sound: VFXAssetDefinition.SoundKey, -- what the avatar is heard arriving with
	Cooldown: number, -- seconds from the click until the next one counts
	IsClamped: boolean?, -- a spot past the range is brought back to it, it's turned down without
	IsHeadingKept: boolean?, -- the avatar arrives turned the way it was, the way the world faces without
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
	getPosition: (origin: Vector3, aim: Vector3) -> Vector3,
}
-- Constants
local ID = "transportation_teleport"
local CONFIG: Config = table.freeze({
	Range = 250,
	Sound = "Transwarp" :: VFXAssetDefinition.SoundKey,
	Cooldown = 0.2,
})
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out puts the avatar where the player points. the avatar is its client's to move, so the
-- client has the say on the cast: the server hears of it + gets to turn it down
local bindings: Bindings = {
	Cast = VFXBinding.event(
		{ "Idle" },
		AbilityTrigger.during(
			AbilityTrigger.started(AbilityCondition.PRIMARY),
			AbilityTrigger.active(AbilityCondition.equipped(ID))
		),
		{ To = "Recovering", Authority = "Client" }
	),
	Recover = VFXBinding.event({ "Recovering" }, AbilityTrigger.after(CONFIG.Cooldown), { To = "Idle" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = CONFIG,
	-- where a jump from one spot at another is headed. both halves ask, each from where it has the avatar
	getPosition = function(origin: Vector3, aim: Vector3): Vector3
		local offset = aim - origin
		if CONFIG.IsClamped and offset.Magnitude > CONFIG.Range then
			return origin + offset.Unit * CONFIG.Range
		end
		return aim
	end,
})

return ability
