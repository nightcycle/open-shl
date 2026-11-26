--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local Orb = require("@game/ServerScriptService/Server/VFX/Library/Orb")
local Place = require("@game/ServerScriptService/Server/VFX/Library/Place")
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
-- the portals of the character that stand, by their slot
local PORTALS_KEY = "Portals"
-- the slot the next portal takes once both or neither of them are filled
local NEXT_SLOT_KEY = "NextSlot"
-- when the character last walked into one of its portals
local ENTER_TIME_KEY = "EnterTime"
-- when everybody else last did
local TRAVEL_TIMES_KEY = "TravelTimes"
-- whether the tool is out
local IS_HELD_KEY = "IsHeld"
-- what a shot is seen as on its way
local SHOT_SIZE = Vector3.one
-- studs short of where its shot ran into the world a portal opens, so nobody comes out of it inside a wall
local SHOT_INSET = 2
-- studs a click has to be off the avatar to point anywhere
local MIN_AIM_DISTANCE = 0.01
-- seconds a shot has to be in the air for to be worth showing on its way
local MIN_FLIGHT_DURATION = 0.05
-- Variables
-- References
-- Private Functions
local function getPortals(record: Memory): { [number]: Portal }
	local portals = (record[PORTALS_KEY] or {}) :: { [number]: Portal }
	record[PORTALS_KEY] = portals
	return portals
end

-- the bodies are only held for as long as they're around
local function getTravelTimes(record: Memory): { [Model]: number }
	local travelTimes = (record[TRAVEL_TIMES_KEY] or setmetatable({}, { __mode = "k" })) :: { [Model]: number }
	record[TRAVEL_TIMES_KEY] = travelTimes
	return travelTimes
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
assert(colorOpt.IsSome or config.Color, `"{layout.Id}" has no color to fall back on`)
local defaultColor = (if colorOpt.IsSome then colorOpt.Value else config.Color) :: Color3
local shot = config.Shot
-- a portal opens around a spot: the newest takes the slot that's its turn, whoever walks into it comes out of the
-- other one
local function open(context: ServerContext, spot: Vector3)
	local record = context.Record
	-- one that'd stand for as long as the tool is out doesn't open once it's away: nothing would ever close it
	if not config.Lifetime and not record[IS_HELD_KEY] then
		return
	end
	local slot = getSlot(record)
	close(record, slot)
	local position = spot + PORTAL_OFFSET
	local handle = context.VFX.start(Orb, {
		Position = position,
		Diameter = PORTAL_DIAMETER,
		CoreSize = PORTAL_CORE_SIZE,
		Color = context.Color or defaultColor,
		Mesh = config.Mesh,
		MeshScale = config.MeshScale,
		OnEntered = function(character: Model)
			local now = os.clock()
			if character == context.Character then
				-- the avatar is moved by the client of its player, which is told where it comes out
				local enterTime = record[ENTER_TIME_KEY] :: number?
				if enterTime and now - enterTime < config.TravelCooldown then
					return
				end
				record[ENTER_TIME_KEY] = now
				local other = getPortals(record)[3 - slot]
				if other then
					context.raise(bindings.Travel, { Position = other.Position })
				end
				return
			end
			-- anybody else is only taken where the game says so + by the server: their client didn't ask to go
			if not config.IsOpenToAll then
				return
			end
			local travelTimes = getTravelTimes(record)
			local travelTime = travelTimes[character]
			if travelTime and now - travelTime < config.TravelCooldown then
				return
			end
			local other = getPortals(record)[3 - slot]
			if other and context.VFX.fire(Place, { Target = character, Position = other.Position }) then
				travelTimes[character] = now
				context.VFX.fireClient(
					ClientVFXDefinition.Sound,
					{ Sound = config.TravelSound },
					{ Range = SOUND_RANGE }
				)
			end
		end,
	})
	local portal: Portal = {
		Position = position,
		Close = handle.Stop,
	}
	getPortals(record)[slot] = portal
	local lifetime = config.Lifetime
	if lifetime then
		task.delay(lifetime, function()
			if getPortals(record)[slot] == portal then
				close(record, slot)
			end
		end)
	end
end
-- the cast is heard as the portal opens, or as the shot that carries it leaves
local heardAt = if shot then bindings.Cast else bindings.Open
-- the server half of the portals: a cast costs energy, the portals are made here so they're there for everybody + it's
-- the server that sees who walks into one. the avatar of their maker is moved by the client of its player, which is
-- told where it comes out
local builder: AbilityBuilder.ServerBuilder = AbilityBuilder
	.newServer(layout)
	-- the portals go as the tool is put away
	:While(bindings.Hold, function(context: ServerContext)
		local record = context.Record
		record[IS_HELD_KEY] = true
		return function()
			record[IS_HELD_KEY] = nil
			close(record, 1)
			close(record, 2)
		end
	end)
	-- where the portal goes is the client's word: a spot that's out of range or off the map is turned down. a shot
	-- finds its own spot, the click it's let fly by may point anywhere
	:Guard(
		bindings.Cast,
		function(context: ServerContext): boolean
			local aim = context.Aim
			return aim ~= nil
				and (
					shot ~= nil
					or (
						PlayAreaDefinition.getIfInside(aim.Position)
						and context.VFX.fire(Reach, { Position = aim.Position, Range = MAX_RANGE })
					)
				)
		end
	)
	:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
if shot then
	-- the click only says which way. the shot is the server's from the avatar on: what it runs into is looked up in
	-- the world the server has, whoever is in its way is flown through + it's everybody's to see
	builder = builder:On(bindings.Cast, function(context: ServerContext)
		local aim = context.Aim
		if not aim then
			return
		end
		local origin = context.Character:GetPivot().Position
		local offset = aim.Position - origin
		if offset.Magnitude < MIN_AIM_DISTANCE then
			return
		end
		local direction = offset.Unit
		local scan = context.VFX.fire(Hitscan, {
			Origin = origin,
			Direction = direction,
			Range = shot.Start + shot.Range,
			IsPassingCharacters = true,
		})
		-- it's seen from a little ahead of the avatar, what's nearer than that is where it opens right away
		local duration = math.max(scan.Distance - shot.Start, 0) / shot.Speed
		if duration > MIN_FLIGHT_DURATION then
			local bolt: ClientVFXType.Bolt = {
				Origin = origin + direction * shot.Start,
				Direction = direction,
				Speed = shot.Speed,
				Lifetime = duration,
				Size = SHOT_SIZE,
				Color = context.Color or defaultColor,
				Mesh = shot.Mesh,
			}
			context.VFX.fireClient(ClientVFXDefinition.Bolt, bolt, { Range = shot.Start + shot.Range })
		end
		-- one that ran into nothing opens nothing, neither does one that left the map
		if not scan.Instance then
			return
		end
		local spot = scan.Position - direction * math.min(SHOT_INSET, scan.Distance)
		if not PlayAreaDefinition.getIfInside(spot) then
			return
		end
		if duration > 0 then
			task.delay(duration, open, context, spot)
		else
			open(context, spot)
		end
	end)
else
	builder = builder:On(bindings.Open, function(context: ServerContext)
		local aim = context.Aim
		if aim then
			open(context, aim.Position)
		end
	end)
end
return builder
	-- the player's own machine lets them hear both right away, this is for everybody else
	:FireClient(
		heardAt,
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
