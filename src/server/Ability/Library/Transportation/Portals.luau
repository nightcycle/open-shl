--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Orb = require("@game/ServerScriptService/Server/VFX/Library/Orb")
local PlayAreaDefinition = require("@game/ReplicatedStorage/Shared/Definition/PlayArea")
local Portals = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Portals")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Memory = AbilityType.Memory
type ServerContext = AbilityType.ServerContext
-- one of the two portals a character has standing
type Portal = {
	Position: Vector3,
	Close: () -> (),
}
-- Constants
-- studs everybody else hears a portal open + its maker come out of one from
local SOUND_RANGE = 150
-- studs from the avatar a portal is opened at most. a pointer gets 1000 from the camera, which stands back from the
-- avatar: nothing a player can really point at is turned down, a spot made up across the map is
local MAX_RANGE = 1200
-- the middle of a portal is this far off the spot, so whoever comes out of it stands on the spot rather than in it
local PORTAL_OFFSET = Vector3.new(0, 3, 0)
local PORTAL_DIAMETER = 6
local PORTAL_CORE_SIZE = 2
-- seconds a portal stands for at most
local PORTAL_LIFETIME = 60
-- seconds a character that walked into a portal isn't taken by one again: they come out inside of the other
local TRAVEL_COOLDOWN = 0.75
-- the portals of the character that stand, by their slot
local PORTALS_KEY = "Portals"
-- the slot the next portal takes once both or neither of them are filled
local NEXT_SLOT_KEY = "NextSlot"
-- when the character last walked into one of its portals
local ENTER_TIME_KEY = "EnterTime"
-- Variables
-- References
-- Private Functions
local function getPortals(record: Memory): { [number]: Portal }
	local portals = (record[PORTALS_KEY] or {}) :: { [number]: Portal }
	record[PORTALS_KEY] = portals
	return portals
end

local function close(record: Memory, slot: number)
	local portals = getPortals(record)
	local portal = portals[slot]
	if portal then
		portals[slot] = nil
		portal.Close()
	end
end

-- with one portal standing the next one is its other end. with both or neither it's the slots' turns, the second
-- one first: which means that the portal after a pair is made takes the place of the newer one of the two
local function getSlot(record: Memory): number
	local portals = getPortals(record)
	if portals[1] and not portals[2] then
		record[NEXT_SLOT_KEY] = 2
		return 2
	elseif portals[2] and not portals[1] then
		record[NEXT_SLOT_KEY] = 1
		return 1
	end
	local slot = (record[NEXT_SLOT_KEY] or 2) :: number
	record[NEXT_SLOT_KEY] = 3 - slot
	return slot
end
-- Class
local layout = Portals.Layout
local bindings = layout.Bindings
local config = Portals.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local power = powerRes.Value
local colorOpt = PowerDefinition.getColor(power, nil)
assert(colorOpt.IsSome, `"{layout.Id}" has no color to fall back on`)
local defaultColor = colorOpt.Value
-- the server half of the portals: a cast costs energy, the portals are made here so they're there for everybody + it's
-- the server that sees their maker walk into one. the avatar is moved by the client of its player, which is told
-- where it comes out
return AbilityBuilder
	.newServer(layout)
	-- the portals go as the tool is put away
	:While(bindings.Hold, function(context: ServerContext)
		return function()
			close(context.Record, 1)
			close(context.Record, 2)
		end
	end)
	-- where the portal goes is the client's word: a spot that's out of range or off the map is turned down
	:Guard(
		bindings.Cast,
		function(context: ServerContext): boolean
			local aim = context.Aim
			return aim ~= nil
				and PlayAreaDefinition.getIfInside(aim.Position)
				and context.VFX.fire(Reach, { Position = aim.Position, Range = MAX_RANGE })
		end
	)
	:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
	:On(bindings.Open, function(context: ServerContext)
		local aim = context.Aim
		if not aim then
			return
		end
		local record = context.Record
		local slot = getSlot(record)
		close(record, slot)
		local position = aim.Position + PORTAL_OFFSET
		local handle = context.VFX.start(Orb, {
			Position = position,
			Diameter = PORTAL_DIAMETER,
			CoreSize = PORTAL_CORE_SIZE,
			Color = context.Color or defaultColor,
			-- a portal only takes whoever made it
			OnEntered = function(character: Model)
				local now = os.clock()
				local enterTime = record[ENTER_TIME_KEY] :: number?
				if character ~= context.Character or (enterTime and now - enterTime < TRAVEL_COOLDOWN) then
					return
				end
				record[ENTER_TIME_KEY] = now
				local other = getPortals(record)[3 - slot]
				if other then
					context.raise(bindings.Travel, { Position = other.Position })
				end
			end,
		})
		local portal: Portal = {
			Position = position,
			Close = handle.Stop,
		}
		getPortals(record)[slot] = portal
		task.delay(PORTAL_LIFETIME, function()
			if getPortals(record)[slot] == portal then
				close(record, slot)
			end
		end)
	end)
	-- the player's own machine lets them hear both right away, this is for everybody else
	:FireClient(
		bindings.Open,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = config.OpenSound }
		end,
		{ Audience = "Others", Range = SOUND_RANGE }
	)
	:FireClient(bindings.Travel, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.TravelSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:Build()
