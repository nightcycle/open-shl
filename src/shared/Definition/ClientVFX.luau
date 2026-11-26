--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Validator = VFXType.Validator
type VFX = VFXType.VFX
type ClientEvent<P> = VFXType.ClientEvent<P>
type ClientState<P> = VFXType.ClientState<P>
-- Constants
-- Variables
local VFXs: { VFX } = {}
local VFXsByName: { [string]: VFX } = {}
-- References
-- Private Functions
local function register(vfx: VFX): any
	assert(VFXsByName[vfx.Name] == nil, `duplicate client effect "{vfx.Name}"`)
	table.freeze(vfx)
	table.insert(VFXs, vfx)
	VFXsByName[vfx.Name] = vfx
	return vfx
end

local function newEvent(name: string, props: Validator): any
	return register({
		Name = name,
		Realm = "Client",
		Kind = "Event",
		IsClientSide = true,
		Props = props,
	} :: any)
end

local function newState(name: string, props: Validator): any
	return register({
		Name = name,
		Realm = "Client",
		Kind = "State",
		IsClientSide = true,
		Props = props,
	} :: any)
end
-- Class
-- what the server + the clients agree a client effect is called + takes. what it does is client code that's
-- registered under the same handle, a client that's missing one of them doesn't start. an effect may be made for one
-- ability, it's still filed here like any other: nothing about it says who uses it, how far it's shown or to whom
local Module = {}

Module.Animation = newState("Animation", ClientVFXType.Animation) :: ClientState<ClientVFXType.Animation>
Module.AnimationOnce =
	newEvent("AnimationOnce", ClientVFXType.AnimationOnce) :: ClientEvent<ClientVFXType.AnimationOnce>
Module.Sound = newEvent("Sound", ClientVFXType.Sound) :: ClientEvent<ClientVFXType.Sound>
Module.SoundLoop = newState("SoundLoop", ClientVFXType.SoundLoop) :: ClientState<ClientVFXType.SoundLoop>
Module.Prop = newState("Prop", ClientVFXType.Prop) :: ClientState<ClientVFXType.Prop>
Module.Bolt = newEvent("Bolt", ClientVFXType.Bolt) :: ClientEvent<ClientVFXType.Bolt>
Module.Hover = newState("Hover", ClientVFXType.Hover) :: ClientState<ClientVFXType.Hover>
Module.Thrust = newState("Thrust", ClientVFXType.Thrust) :: ClientState<ClientVFXType.Thrust>
Module.Warp = newEvent("Warp", ClientVFXType.Warp) :: ClientEvent<ClientVFXType.Warp>
Module.WalkSpeed = newState("WalkSpeed", ClientVFXType.WalkSpeed) :: ClientState<ClientVFXType.WalkSpeed>
Module.JumpPower = newState("JumpPower", ClientVFXType.JumpPower) :: ClientState<ClientVFXType.JumpPower>
Module.Float = newState("Float", ClientVFXType.Float) :: ClientState<ClientVFXType.Float>
Module.Ragdoll = newState("Ragdoll", ClientVFXType.Ragdoll) :: ClientState<ClientVFXType.Ragdoll>
Module.Skim = newState("Skim", ClientVFXType.Skim) :: ClientState<ClientVFXType.Skim>
Module.Lift = newState("Lift", ClientVFXType.Lift) :: ClientState<ClientVFXType.Lift>
Module.Reel = newState("Reel", ClientVFXType.Reel) :: ClientState<ClientVFXType.Reel>
Module.Rope = newState("Rope", ClientVFXType.Rope) :: ClientState<ClientVFXType.Rope>
Module.Cloak = newState("Cloak", ClientVFXType.Cloak) :: ClientState<ClientVFXType.Cloak>
Module.Coat = newState("Coat", ClientVFXType.Coat) :: ClientState<ClientVFXType.Coat>
Module.ScreenFilter = newState("ScreenFilter", ClientVFXType.ScreenFilter) :: ClientState<ClientVFXType.ScreenFilter>
Module.Spectate = newState("Spectate", ClientVFXType.Spectate) :: ClientState<ClientVFXType.Spectate>
Module.Root = newState("Root", ClientVFXType.Root) :: ClientState<ClientVFXType.Root>
Module.EnergyWarning =
	newEvent("EnergyWarning", ClientVFXType.EnergyWarning) :: ClientEvent<ClientVFXType.EnergyWarning>
Module.Plume = newState("Plume", ClientVFXType.Plume) :: ClientState<ClientVFXType.Plume>
Module.Smoke = newState("Smoke", ClientVFXType.Smoke) :: ClientState<ClientVFXType.Smoke>
Module.Flame = newState("Flame", ClientVFXType.Flame) :: ClientState<ClientVFXType.Flame>
Module.Ripple = newEvent("Ripple", ClientVFXType.Ripple) :: ClientEvent<ClientVFXType.Ripple>
Module.Spray = newState("Spray", ClientVFXType.Spray) :: ClientState<ClientVFXType.Spray>
Module.Beam = newEvent("Beam", ClientVFXType.Beam) :: ClientEvent<ClientVFXType.Beam>
Module.Streak = newState("Streak", ClientVFXType.Streak) :: ClientState<ClientVFXType.Streak>
Module.Wake = newState("Wake", ClientVFXType.Wake) :: ClientState<ClientVFXType.Wake>
Module.FieldOfView = newState("FieldOfView", ClientVFXType.FieldOfView) :: ClientState<ClientVFXType.FieldOfView>
Module.Tumble = newState("Tumble", ClientVFXType.Tumble) :: ClientState<ClientVFXType.Tumble>
Module.SeeThrough = newState("SeeThrough", ClientVFXType.SeeThrough) :: ClientState<ClientVFXType.SeeThrough>
Module.Frost = newEvent("Frost", ClientVFXType.Frost) :: ClientEvent<ClientVFXType.Frost>
Module.Flare = newEvent("Flare", ClientVFXType.Flare) :: ClientEvent<ClientVFXType.Flare>
Module.Shaft = newEvent("Shaft", ClientVFXType.Shaft) :: ClientEvent<ClientVFXType.Shaft>
Module.Scatter = newEvent("Scatter", ClientVFXType.Scatter) :: ClientEvent<ClientVFXType.Scatter>
Module.Notice = newEvent("Notice", ClientVFXType.Notice) :: ClientEvent<ClientVFXType.Notice>
Module.Line = newState("Line", ClientVFXType.Line) :: ClientState<ClientVFXType.Line>
Module.Cursor = newState("Cursor", ClientVFXType.Cursor) :: ClientState<ClientVFXType.Cursor>
Module.Gauge = newState("Gauge", ClientVFXType.Gauge) :: ClientState<ClientVFXType.Gauge>

Module.get = function(name: string): Result<VFX, string>
	local vfx = VFXsByName[name]
	if vfx then
		return Result.ok(vfx)
	end
	return Result.err(`no client effect "{name}"`)
end

Module.list = function(): { VFX }
	return table.freeze(table.clone(VFXs))
end

return Module
