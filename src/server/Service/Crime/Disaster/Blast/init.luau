--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local RebuildUtil = require("@self/Rebuild")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
local DisasterType = require("@game/ReplicatedStorage/Shared/Type/Disaster")
type Blast = DisasterType.Blast
-- a building that goes up with its target, + stands again later
export type Site = {
	-- the building a target of it came into the world with, + that one leaving it again
	Add: (building: Model) -> (),
	Remove: (building: Model) -> (),
	-- what stands of it is thrown about, whoever is near goes down + the wreck is gone a while later
	Blow: (target: Model) -> (),
	Destroy: () -> (),
}
-- Constants
-- the part of a target its bar + the sound of its fall sit on: it marks the middle of the blast
local VISUAL_NAME = "Visual"
-- seconds between two moves of a building on its way up
local RISE_STEP = 0.05
-- Variables
-- References
-- Private Functions
-- a part of the wreck is deadly to the side the building stood for, for as long as it lies about. whoever the rules
-- shelter is spared: nobody is taken down in a menu
local function onDebrisTouched(part: BasePart, hit: BasePart, blast: Blast)
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character or not TakeDownUtil.getIfAlive(character) then
		return
	end
	if
		AttributeDefinition.get(character, AttributeDefinition.TeamId) ~= blast.DebrisTeamId
		or not TouchUtil.getIfNear(character, part, TouchUtil.REACH)
		or not CombatDefinition.getIfHostile(nil, character)
	then
		return
	end
	TakeDownUtil.takeDown(character)
end

-- the engine of the old place broke the joints of everybody its blast reached, whoever's side they were on. here
-- the blast breaks nothing + the server takes them down itself, which whoever the rules shelter is spared
local function takeDownNear(position: Vector3, radius: number)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if
			character
			and TakeDownUtil.getIfAlive(character)
			and (character:GetPivot().Position - position).Magnitude <= radius
			and CombatDefinition.getIfHostile(nil, character)
		then
			TakeDownUtil.takeDown(character)
		end
	end
end
-- Class
return {
	-- building is how it stands as the server starts, which is how it comes back every time. the wreck is put in the
	-- folder, startedAt is when the beat it's looked at on began, on the clock of os.clock
	new = function(building: Model, blast: Blast, folder: Folder, startedAt: number): Site
		local rebuild = blast.Rebuild
		local template = building:Clone()
		local home = building:GetPivot()
		local parent: Instance? = building.Parent
		-- the one that's in the world, nil from when the wreck of one is gone until the next is put in
		local live: Model? = nil
		local riseThread: thread? = nil
		local wreckThreads: { [thread]: true } = {}

		local function stopRise()
			if riseThread and coroutine.status(riseThread) == "suspended" then
				task.cancel(riseThread)
			end
			riseThread = nil
		end

		-- it comes in under its place + is moved up to it in steps. a target of it is found as it's put in the world,
		-- so it can be worn down on its way up, as in the old place
		local function rise()
			-- a map whose folder of them is gone has nowhere to put one
			if not parent or not parent:IsDescendantOf(Workspace) then
				return
			end
			stopRise()
			local clone = template:Clone()
			clone:PivotTo(home - Vector3.new(0, rebuild.Depth, 0))
			clone.Parent = parent
			live = clone
			riseThread = task.spawn(function()
				local riseStartedAt = os.clock()
				while true do
					task.wait(RISE_STEP)
					local elapsed = os.clock() - riseStartedAt
					if clone.Parent == nil then
						break
					end
					clone:PivotTo(home - Vector3.new(0, RebuildUtil.getDrop(elapsed, rebuild), 0))
					if elapsed >= rebuild.RiseDuration then
						break
					end
				end
				riseThread = nil
			end)
		end

		-- yields for as long as the site is kept
		local rebuildThread = task.spawn(function()
			while true do
				task.wait(RebuildUtil.getDelay(os.clock() - startedAt, rebuild))
				-- a wreck that still lies about counts as the building: it's looked at again an interval later
				if not live then
					rise()
				end
			end
		end)

		return table.freeze({
			Add = function(added: Model)
				live = added
			end,
			Remove = function(removed: Model)
				if live == removed then
					live = nil
				end
			end,
			Blow = function(target: Model)
				local wrecked = target.Parent
				stopRise()
				local visual = target:FindFirstChild(VISUAL_NAME)
				local position = if visual and visual:IsA("BasePart")
					then visual.Position
					else target:GetPivot().Position
				-- the mark itself stays where it is: every client reads the middle of the blast off it
				local debris: { BasePart } = {}
				local function collect(holder: Instance)
					for _, child in holder:GetChildren() do
						if child:IsA("BasePart") and child ~= visual then
							table.insert(debris, child)
						end
					end
				end
				if wrecked then
					collect(wrecked)
				end
				collect(target)
				for _, part in debris do
					part.Anchored = false
					part.Material = Enum.Material.CorrodedMetal
					part.Parent = folder
					-- gone with the part
					part.Touched:Connect(function(hit: BasePart)
						onDebrisTouched(part, hit, blast)
					end)
				end
				if visual then
					local bar = visual:FindFirstChildOfClass("BillboardGui")
					if bar then
						bar.Enabled = false
					end
					-- the map has it play as it's removed, which is how the blast is heard
					local sound = visual:FindFirstChildOfClass("Sound")
					if sound then
						sound:Destroy()
					end
				end
				-- everything is said of it before it's in the world, it goes off as it's put in
				local explosion = Instance.new("Explosion")
				explosion.Position = position
				explosion.BlastRadius = blast.Radius
				explosion.BlastPressure = blast.Pressure
				explosion.DestroyJointRadiusPercent = 0
				explosion.Parent = folder
				takeDownNear(position, blast.Radius)

				local wreckThread: thread
				wreckThread = task.delay(blast.DebrisLifetime, function()
					wreckThreads[wreckThread] = nil
					for _, part in debris do
						part:Destroy()
					end
					explosion:Destroy()
					if wrecked then
						wrecked:Destroy()
					end
				end)
				wreckThreads[wreckThread] = true
			end,
			Destroy = function()
				stopRise()
				task.cancel(rebuildThread)
				for thread in wreckThreads do
					task.cancel(thread)
				end
				table.clear(wreckThreads)
				template:Destroy()
			end,
		})
	end,
}
