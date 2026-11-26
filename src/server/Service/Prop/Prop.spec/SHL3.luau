--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local HalfUtil = require("@game/ServerScriptService/Server/Service/Prop/Half")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type TestMap = SimpleTest.TestMap
type Handle = VFXType.Handle
type Replication = VFXType.Replication
type ServerScope = VFXType.ServerScope
-- one thing a half asked of the effects
type Ask = {
	Verb: "fire" | "start" | "fireClient" | "startClient" | "stop",
	Name: string,
	Props: any,
	Replication: Replication?,
}
-- Constants
local HEALTH = AttributeDefinition.Health
-- what a walk starts its avatar out with: hurt enough for anything a prop gives to show
local START_HEALTH = 50
-- what a bite of the burger that ran its length gives back
local BITE_HEALTH = 1.6
-- seconds a wait is given on top of what it waits for
local MARGIN = 0.1
-- where the clicks of a walk point: a spot a few studs off an avatar that stands where the world starts
local AIM = table.freeze({ Origin = Vector3.new(0, 5, 10), Position = Vector3.new(0, 0, -10) })
-- Variables
-- References
-- Private Functions
-- an avatar nobody plays: a body with the attributes every avatar comes in with
local function newAvatar(): Model
	local avatar = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = avatar
	AttributeDefinition.setDefaults(avatar, "Character")
	AttributeDefinition.set(avatar, HEALTH, START_HEALTH)
	return avatar
end

-- stands in for the scope the service hands a half. whatever is asked of it is held to what the effect takes +
-- written down, what the server makes true by itself is run for real on the avatar. nothing is told to a client
local function newScope(avatar: Model, asks: { Ask }): ServerScope
	local scope: any
	local function ask(verb: "fire" | "start" | "fireClient" | "startClient", vfx: any, props: any, to: Replication?)
		local isTaken, problem = vfx.Props(props)
		assert(isTaken, `"{vfx.Name}" is asked for with what it doesn't take: {problem}`)
		table.insert(asks, { Verb = verb, Name = vfx.Name, Props = props, Replication = to })
	end
	local function newHandle(name: string, cleanup: (() -> ())?): Handle
		return {
			Stop = function()
				table.insert(asks, { Verb = "stop" :: "stop", Name = name })
				if cleanup then
					cleanup()
				end
			end,
		}
	end
	scope = {
		Character = avatar,
		IsOwner = false,
		fire = function(vfx: any, props: any): any
			ask("fire", vfx, props)
			return vfx.Run(props, scope)
		end,
		start = function(vfx: any, props: any): Handle
			ask("start", vfx, props)
			return newHandle(vfx.Name, vfx.Start(props, scope, nil))
		end,
		fireClient = function(vfx: any, props: any, replication: Replication?)
			ask("fireClient", vfx, props, replication)
		end,
		startClient = function(vfx: any, props: any, _: unknown, replication: Replication?): Handle
			ask("startClient", vfx, props, replication)
			return newHandle(vfx.Name)
		end,
	}
	return scope :: ServerScope
end

local function count(asks: { Ask }, verb: string, name: string?): number
	local total = 0
	for _, ask in asks do
		if ask.Verb == verb and (name == nil or ask.Name == name) then
			total += 1
		end
	end
	return total
end

local function getHealth(avatar: Model): number
	return AttributeDefinition.get(avatar, HEALTH)
end

local function getIfNear(value: number, target: number): boolean
	return math.abs(value - target) < 0.001
end
-- Class
local Tests: TestMap = {
	-- every prop the game hands out, through the hand once: it's shown to everybody else while it's out, a click is a
	-- use only where the row has one, + put away nothing of it is left
	Every = SpecUtil.newScenario(function()
		assert(#PropDefinition.list() > 0, `the game hands out no prop`)
		for _, prop in PropDefinition.list() do
			local id = prop.Id
			local avatar = newAvatar()
			local asks: { Ask } = {}
			local half = HalfUtil.new(id, avatar, nil, newScope(avatar, asks))
			assert(not half:Use(nil) and #asks == 0, `"{id}" does something before it's in a hand`)
			half:Draw()
			assert(half.IsHeld, `"{id}" isn't held once it's got out`)
			assert(count(asks, "startClient", "Prop") >= 1, `"{id}" is out + nobody is shown it`)
			-- the client of whoever holds it shows them their own, the moment they get it out. what only the
			-- server can say of it (where a line lies) is everybody's to be told
			for _, ask in asks do
				local to = ask.Replication
				assert(
					ask.Name ~= "Prop" or (to ~= nil and to.Audience == "Others"),
					`"{id}" has its own holder shown it by the server`
				)
			end
			-- a click that points somewhere: one prop asks where
			local isUsed = half:Use(AIM)
			assert(isUsed == (prop.Use ~= nil), `a click with "{id}": a use started is {isUsed}`)
			assert(half.IsUsing == isUsed, `"{id}" doesn't say if it's being used`)
			assert(not half:Use(AIM), `a second use of "{id}" starts in the middle of the first`)
			half:Stow()
			assert(not half.IsHeld and not half.IsUsing, `"{id}" is still out once it's put away`)
			assert(
				count(asks, "stop") == count(asks, "startClient") + count(asks, "start"),
				`something of "{id}" is still on once it's put away`
			)
			-- what's cut short gives nothing: all a use makes true comes at its end
			-- a look along a ray makes nothing true
			assert(
				count(asks, "fire") == count(asks, "fire", "Hitscan"),
				`"{id}" made something true without a use that ran its length`
			)
			assert(getHealth(avatar) == START_HEALTH, `"{id}" gave health for a use that was cut short`)
			half:Destroy()
			half:Draw()
			assert(not half.IsHeld, `"{id}" comes out once it's gone`)
		end
		local avatar = newAvatar()
		local isMade = pcall(HalfUtil.new, "no-such-prop", avatar, nil, newScope(avatar, {}))
		assert(not isMade, `a prop the game doesn't have has a half`)
	end),

	-- the card: a bare part in the hand + nothing else. the gates ask the service who holds one
	Card = SpecUtil.newScenario(function()
		local definitionRes = PropDefinition.get("keycard")
		assert(definitionRes.IsOk, definitionRes.Value)
		assert(definitionRes.Value.Use == nil and definitionRes.Value.Icon ~= nil, `the card has a use or no picture`)
		local avatar = newAvatar()
		local asks: { Ask } = {}
		local half = HalfUtil.new("keycard", avatar, nil, newScope(avatar, asks))
		half:Draw()
		assert(#asks == 1 and asks[1].Verb == "startClient" and asks[1].Name == "Prop", `more than the card is shown`)
		assert(asks[1].Props.Mesh == nil and asks[1].Props.Limb == "RightHand", `it isn't a bare part in the hand`)
		assert(not half:Use(nil) and #asks == 1, `a click with the card does something`)
		half:Stow()
		assert(#asks == 2 and asks[2].Verb == "stop", `the card is still shown once it's put away`)
		half:Destroy()
	end),

	-- the burger: a bite that ran its length gives a little health, never past what an avatar has at most. the next
	-- may start as it's over, + the wait isn't the hand's: putting it away + getting it back out brings none closer
	Bite = SpecUtil.newScenario(function()
		local definitionRes = PropDefinition.get("cheeseburger")
		assert(definitionRes.IsOk, definitionRes.Value)
		local rule = definitionRes.Value.Use
		assert(rule and rule.Lockout == nil, `a bite of the burger keeps the next off for longer than it takes`)
		local duration = rule.Duration
		local avatar = newAvatar()
		local asks: { Ask } = {}
		local half = HalfUtil.new("cheeseburger", avatar, nil, newScope(avatar, asks))
		half:Draw()
		assert(count(asks, "fireClient", "Sound") == 1, `nobody hears the wrapper come off`)
		assert(half:Use(nil), `a bite doesn't start`)
		assert(count(asks, "fireClient", "Sound") == 2, `nobody hears the bite`)
		assert(count(asks, "startClient", "Prop") == 2, `nobody is shown the burger go up to the mouth`)
		task.wait(duration / 2)
		assert(getHealth(avatar) == START_HEALTH, `a bite gives before it's over`)
		task.wait(duration / 2 + MARGIN)
		assert(not half.IsUsing, `a bite is still on after {duration} s`)
		assert(
			getIfNear(getHealth(avatar), START_HEALTH + BITE_HEALTH),
			`a bite gave {getHealth(avatar) - START_HEALTH}`
		)
		assert(count(asks, "startClient", "Prop") == 3, `nobody is shown the burger come back down`)
		assert(half:Use(nil), `the next bite is kept off once the first is over`)
		half:Stow()
		half:Draw()
		assert(not half:Use(nil), `getting it back out brought the next bite closer`)
		task.wait(duration + MARGIN)
		assert(getIfNear(getHealth(avatar), START_HEALTH + BITE_HEALTH), `a bite that was cut short gave health`)
		AttributeDefinition.set(avatar, HEALTH, AttributeDefinition.MAX_HEALTH - BITE_HEALTH / 2)
		assert(half:Use(nil), `no bite starts {duration} s after the last one did`)
		task.wait(duration + MARGIN)
		assert(getHealth(avatar) == AttributeDefinition.MAX_HEALTH, `a bite went past what an avatar has at most`)
		half:Destroy()
	end),

	-- the latte: a sip is over in three seconds + keeps the next one off for a minute more. it gives nothing, + the
	-- minute isn't the hand's either
	Minute = SpecUtil.newScenario(function()
		local definitionRes = PropDefinition.get("latte")
		assert(definitionRes.IsOk, definitionRes.Value)
		local rule = definitionRes.Value.Use
		assert(rule and rule.Duration == 3 and rule.Lockout == 63, `a sip of the latte isn't 3 s + a minute more`)
		local avatar = newAvatar()
		local asks: { Ask } = {}
		local half = HalfUtil.new("latte", avatar, nil, newScope(avatar, asks))
		half:Draw()
		assert(count(asks, "fireClient", "Sound") == 0, `the latte is heard as it's got out`)
		assert(half:Use(nil), `a sip doesn't start`)
		assert(count(asks, "fireClient", "Sound") == 1, `nobody hears the sip`)
		task.wait(rule.Duration + MARGIN)
		assert(not half.IsUsing, `a sip is still on after {rule.Duration} s`)
		assert(count(asks, "fire") == 0 and getHealth(avatar) == START_HEALTH, `a sip gave something`)
		assert(not half:Use(nil), `the next sip starts as the first is over`)
		half:Stow()
		half:Draw()
		assert(not half:Use(nil), `getting it back out brought the next sip closer`)
		half:Destroy()
	end),
}

return Tests
