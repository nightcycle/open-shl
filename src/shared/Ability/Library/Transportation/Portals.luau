--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
type SoundKey = VFXAssetDefinition.SoundKey
type MeshKey = VFXAssetDefinition.MeshKey
-- where a portal lets out whoever walked into the other one
export type Travel = {
	Position: Vector3,
}
export type Bindings = {
	Hold: StateBinding, -- the tool is out, the portals only stand for as long as it is
	Cast: EventBinding,
	Open: EventBinding, -- the cast is done, a portal stands where the click pointed: in a game without a shot
	Travel: ServerSignal<Travel>, -- the avatar walked into one of its portals, which only the server sees
	Recover: EventBinding,
}
-- what carries a portal to where it opens
export type Shot = {
	Start: number, -- studs off the middle of the avatar it's seen from
	Speed: number, -- studs a second it flies at
	Range: number, -- studs it flies at most, one that ran into nothing by then opens nothing
	Mesh: MeshKey?, -- what it's drawn as, a ball of light without
}
-- what both halves of the portals have to agree on
export type Config = {
	OpenSound: SoundKey,
	TravelSound: SoundKey,
	Cooldown: number, -- seconds from a click until the next one counts
	Lifetime: number?, -- seconds a portal stands for at most, for as long as the tool is out without
	TravelCooldown: number, -- seconds whoever walked into a portal isn't taken by one again
	IsOpenToAll: boolean?, -- whoever walks into one comes out of the other, only their maker without
	-- a shot the server lets fly the way the click pointed, the portal opens where that runs into the world. it opens
	-- where the click pointed without
	Shot: Shot?,
	Color: Color3?, -- what a portal is drawn in where neither the character nor the power has a color for it
	Mesh: MeshKey?, -- what a portal is drawn as, a ball of light without
	MeshScale: Vector3?,
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_portals"
-- seconds from the click until the portal stands
local OPEN_DELAY = 0.6
local DEFAULT_CONFIG: Config = {
	OpenSound = "PortalShot",
	TravelSound = "Transwarp",
	Cooldown = 2,
	Lifetime = 60,
	-- they come out inside of the other one
	TravelCooldown = 0.75,
}
-- the portals work the same way in every game, how one gets to where it opens, who it takes + what it looks like
-- doesn't
local CONFIG: Config = GameDefinition.tune(table.freeze(DEFAULT_CONFIG), {
	shl1 = FreezeUtil.delta(DEFAULT_CONFIG, function(config: Config): Config
		-- they stand until their tool is put away + take whoever walks into one
		config.Lifetime = nil
		config.TravelCooldown = 1
		config.IsOpenToAll = true
		-- three seconds of flight
		config.Shot = { Start = 8, Speed = 80, Range = 240, Mesh = "Icicle" }
		-- the bright blue of the shot, nobody has a color for this
		config.Color = Color3.fromRGB(13, 105, 172)
		config.Mesh = "Portal"
		config.MeshScale = Vector3.one * 10
		return config
	end),
})
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
-- point is only the client's to tell, so it has the say on the cast: the server hears of it + gets to turn it down.
-- in a game with a shot the click only says which way: the server lets the shot fly + opens the portal where it lands
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
	Config = CONFIG,
})

return ability
