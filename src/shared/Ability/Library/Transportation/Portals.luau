--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
type SoundKey = VFXAssetDefinition.SoundKey
-- where a portal lets out whoever walked into the other one
export type Travel = {
	Position: Vector3,
}
export type Bindings = {
	Hold: StateBinding, -- the tool is out, the portals only stand for as long as it is
	Cast: EventBinding,
	Open: EventBinding, -- the cast is done, a portal stands where the click pointed
	Travel: ServerSignal<Travel>, -- the avatar walked into one of its portals, which only the server sees
	Recover: EventBinding,
}
-- what both halves of the portals have to agree on
export type Config = {
	OpenSound: SoundKey,
	TravelSound: SoundKey,
	Cooldown: number, -- seconds from a click until the next one counts
	Lifetime: number?, -- seconds a portal stands for at most, for as long as the tool is out without
	TravelCooldown: number, -- seconds whoever walked into a portal isn't taken by one again
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_portals"
-- seconds from the click until the portal stands
local OPEN_DELAY = 0.6
local CONFIG: Config = {
	OpenSound = "PortalShot",
	TravelSound = "Transwarp",
	Cooldown = 2,
	Lifetime = 60,
	-- they come out inside of the other one
	TravelCooldown = 0.75,
}
-- a portal is walked into whatever the machine is up to
local STATE_IDS = table.freeze({ "Idle", "Casting" })
local isTravel = Type.strictInterface({
	Position = AbilityType.FiniteVector3,
})
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out opens a portal where the player points, up to two at a time. walking into one of them
-- lets its maker out of the other. the tool can be put away mid-cast: the portal still opens. where the click may
-- point is only the client's to tell, so it has the say on the cast: the server hears of it + gets to turn it down
local bindings: Bindings = {
	Hold = VFXBinding.state(STATE_IDS, AbilityTrigger.active(AbilityCondition.equipped(ID))),
	Cast = VFXBinding.event(
		{ "Idle" },
		AbilityTrigger.during(
			AbilityTrigger.started(AbilityCondition.PRIMARY),
			AbilityTrigger.active(AbilityCondition.equipped(ID))
		),
		{ To = "Casting", Authority = "Client" }
	),
	Open = VFXBinding.event({ "Casting" }, AbilityTrigger.after(OPEN_DELAY)),
	Travel = VFXBinding.signal(STATE_IDS, "Server", isTravel) :: ServerSignal<Travel>,
	Recover = VFXBinding.event({ "Casting" }, AbilityTrigger.after(CONFIG.Cooldown), { To = "Idle" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = table.freeze(CONFIG),
})

return ability
