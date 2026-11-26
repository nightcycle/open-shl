--!strict
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local BankDefinition = require("@game/ServerScriptService/Server/Definition/Bank")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local SweepUtil = require("@game/ReplicatedStorage/Shared/Util/Sweep")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
export type Sweeper = {
	Destroy: () -> (),
}
-- a beam of the map as the server has it: it's never moved here
-- the box the middles of all of them stay in, + how far from it an avatar can be + still be in one
type Bounds = {
	Low: Vector3,
	High: Vector3,
	Reach: number,
}
type Beam = {
	From: CFrame,
	To: CFrame,
	Size: Vector3,
	-- seconds from one end to the other at the pace it rolled
	Duration: number,
	-- on the clock of the server, when it next takes anything off somebody it went through
	SparedUntil: { [Player]: number },
}
-- Constants
local BEAM = BankDefinition.BEAM
-- the parts of a marked model: the beam itself + the two ends of its way
local BEAM_NAME = "Beam"
local FROM_NAME = "Start"
local TO_NAME = "Finish"
-- Variables
-- References
-- Private Functions
-- the box grown to hold the spot as well
local function widen(low: Vector3?, high: Vector3?, position: Vector3): (Vector3, Vector3)
	if not low or not high then
		return position, position
	end
	return Vector3.new(math.min(low.X, position.X), math.min(low.Y, position.Y), math.min(low.Z, position.Z)),
		Vector3.new(math.max(high.X, position.X), math.max(high.Y, position.Y), math.max(high.Z, position.Z))
end

-- studs from the spot to the box, none for a spot inside of it
local function getDistance(low: Vector3, high: Vector3, position: Vector3): number
	local closest = Vector3.new(
		math.clamp(position.X, low.X, high.X),
		math.clamp(position.Y, low.Y, high.Y),
		math.clamp(position.Z, low.Z, high.Z)
	)
	return (position - closest).Magnitude
end
-- Class
-- the beams that sweep the hall of a bank. where one is follows from the clock of the server alone, so the server
-- knows it without moving anything + every client draws it in the same place. the pace of each is rolled once as
-- the server starts: the old place had every client roll its own, so no two players saw a beam in the same spot +
-- each client took the health off its own avatar. here the server looks at what a beam went through since the step
-- before + the loss is the game's own: whoever its rules shelter is spared, in a menu or where nobody fights
return {
	new = function(): Sweeper
		assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
		local random = Random.new()
		-- the hits are the world's own, nobody is counted for them
		local scope = VFXService:NewScope(nil, nil)
		local beams: { [Model]: Beam } = {}
		-- nil until it's asked for after a beam came or went
		local bounds: Bounds? = nil

		local stopBeams = MapDefinition.observe(MapDefinition.LaserBeam, function(model: Model): (() -> ())?
			local durationRes = MapDefinition.get(model, MapDefinition.SweepDuration)
			if durationRes.IsErr then
				warn(durationRes.Value)
				return nil
			end
			local part = model:FindFirstChild(BEAM_NAME)
			local from, to = model:FindFirstChild(FROM_NAME), model:FindFirstChild(TO_NAME)
			if
				not part
				or not part:IsA("BasePart")
				or not from
				or not from:IsA("BasePart")
				or not to
				or not to:IsA("BasePart")
			then
				warn(`{model:GetFullName()} has no beam with both ends of its way`)
				return nil
			end
			local pace = BankDefinition.rollPace(random)
			MapDefinition.set(model, MapDefinition.SweepFrom, from.CFrame)
			MapDefinition.set(model, MapDefinition.SweepTo, to.CFrame)
			MapDefinition.set(model, MapDefinition.SweepPace, pace)
			beams[model] = {
				From = from.CFrame,
				To = to.CFrame,
				Size = part.Size,
				Duration = durationRes.Value * pace,
				SparedUntil = {},
			}
			bounds = nil
			return function()
				beams[model] = nil
				bounds = nil
			end
		end)

		local function getBounds(): Bounds?
			if bounds then
				return bounds
			end
			local low: Vector3?, high: Vector3? = nil, nil
			local reach = 0
			for _, beam in beams do
				low, high = widen(low, high, beam.From.Position)
				low, high = widen(low, high, beam.To.Position)
				reach = math.max(reach, beam.Size.Magnitude / 2)
			end
			if low and high then
				bounds = { Low = low, High = high, Reach = reach + TouchUtil.REACH }
			end
			return bounds
		end

		-- every avatar that's up + near enough to where a beam ever is. none: nothing is looked for
		local function getNear(): { Instance }
			local near: { Instance } = {}
			local box = getBounds()
			if not box then
				return near
			end
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local rootPart = character and character.PrimaryPart
				if
					character
					and rootPart
					and TakeDownUtil.getIfAlive(character)
					and getDistance(box.Low, box.High, rootPart.Position) <= box.Reach
				then
					table.insert(near, character)
				end
			end
			return near
		end

		local function step(before: number, now: number)
			local near = getNear()
			if #near == 0 then
				return
			end
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			overlapParams.FilterDescendantsInstances = near
			for _, beam in beams do
				for player, sparedUntil in beam.SparedUntil do
					if sparedUntil <= now then
						beam.SparedUntil[player] = nil
					end
				end
				local cframe, size = SweepUtil.getSwept(beam.From, beam.To, beam.Size, before, now, beam.Duration)
				for _, part in Workspace:GetPartBoundsInBox(cframe, size, overlapParams) do
					local player, character = TouchUtil.getToucher(part)
					if
						not player
						or not character
						or beam.SparedUntil[player]
						or not TakeDownUtil.getIfAlive(character)
						or not CombatDefinition.getIfHostile(nil, character)
					then
						continue
					end
					-- spared from here on, also where nothing came off: one who can't be hurt isn't asked again at once
					beam.SparedUntil[player] = now + BEAM.Cooldown
					scope.fire(Damage, { Target = character, Amount = BEAM.Damage })
				end
			end
		end

		local steppedAt = Workspace:GetServerTimeNow()
		local stepConnection = RunService.Heartbeat:Connect(function()
			local before = steppedAt
			steppedAt = Workspace:GetServerTimeNow()
			step(before, steppedAt)
		end)

		return table.freeze({
			Destroy = function()
				stepConnection:Disconnect()
				stopBeams()
			end,
		})
	end,
}
