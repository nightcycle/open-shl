--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BlastSite = require("@self/Blast")
local DisasterDefinition = require("@game/ReplicatedStorage/Shared/Definition/Disaster")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PayoutUtil = require("@self/Payout")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TallyUtil = require("@game/ServerScriptService/Server/Util/Tally")
-- Types
type Disaster = DisasterDefinition.Disaster
export type Runner = {
	Destroy: () -> (),
}
-- a target that's in the world + worn down
type Target = {
	Model: Model,
	Disaster: Disaster,
	IsAlerted: boolean, -- the town was told of this round
	IsFallen: boolean,
}
-- Constants
local WRECK_FOLDER_NAME = "DisasterWreck"
-- Variables
-- References
-- Private Functions
-- the pool goes to whoever took the health off it, each for what they took: whatever side they're on by now.
-- somebody who left since is paid nothing + their share is nobody's
local function pay(target: Target)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local shares = PayoutUtil.getShares(TallyUtil.take(target.Model), target.Disaster.PoolScale)
	for player, amount in shares do
		if amount <= 0 or SessionService:Get(player).IsNone then
			continue
		end
		local grantRes = EconomyService:Grant(player, PseudoEnum.Currency.Credits, amount)
		if grantRes.IsErr then
			warn(`disaster err: {player.Name} isn't paid {amount}: {grantRes.Value}`)
		end
	end
end

-- a round that's under way is void: the health is back + what was taken off it counts for nothing
local function refill(target: Target)
	if target.IsFallen then
		return
	end
	target.IsAlerted = false
	AttributeDefinition.set(target.Model, AttributeDefinition.Health, target.Disaster.MaxHealth)
	TallyUtil.take(target.Model)
end
-- Class
-- the targets of the map: something that stands for one side + is worn down by the other. a target is a body nobody
-- plays, so every power hits it the way it hits an avatar + the rules of a hit are the game's own: its side leaves
-- it alone, nobody hurts it from a menu or where nobody fights. the health that comes off it is counted where it
-- comes off, the pool is shared out by that count as it falls + what follows the fall is the row's to say
return {
	new = function(): Runner
		assert(AlertService.IsInitialized, `the alert service isn't initialized`)
		local startedAt = os.clock()
		local targets: { [Model]: Target } = {}
		-- what goes up with its target, by the id of the disaster: kept from the first of them on, the building comes
		-- back as another instance every time
		local sites: { [string]: BlastSite.Site } = {}
		local wreckFolder = Instance.new("Folder")
		wreckFolder.Name = WRECK_FOLDER_NAME
		wreckFolder.Parent = Workspace

		local function fall(target: Target, id: string)
			target.IsFallen = true
			pay(target)
			local consequence = target.Disaster.Consequence
			if consequence.Type == "Blast" then
				local site = sites[id]
				if site then
					site.Blow(target.Model)
				end
			else
				-- no target with another end is armed, so none of them falls
				warn(`disaster err: nothing follows the fall of "{id}" yet`)
			end
		end

		-- the server holds the whole map, but what was blown up comes back as a new instance
		local stopTargets = MapDefinition.observe(MapDefinition.DisasterTarget, function(model: Model): (() -> ())?
			local idRes = MapDefinition.get(model, MapDefinition.DisasterId)
			if idRes.IsErr then
				warn(idRes.Value)
				return nil
			end
			local id = idRes.Value
			local disasterRes = DisasterDefinition.get(id)
			if disasterRes.IsErr then
				warn(`{model:GetFullName()}: {disasterRes.Value}`)
				return nil
			end
			local disaster = disasterRes.Value
			local consequence = disaster.Consequence
			-- a shove moves a body by its primary part: a target with one would be pushed out of the map
			if model.PrimaryPart then
				warn(`{model:GetFullName()} has a primary part, a hit could move it`)
			end

			local building: Model? = nil
			if disaster.IsArmed and consequence.Type == "Blast" then
				local parent = model.Parent
				if not parent or not parent:IsA("Model") then
					warn(`{model:GetFullName()} has no building around it to blow up`)
					return nil
				end
				building = parent
			end

			-- it stands for a side, so the rule that has a side leave its own alone keeps that side off it
			AttributeDefinition.set(model, AttributeDefinition.IsNonPlayer, true)
			AttributeDefinition.set(model, AttributeDefinition.TeamId, disaster.GuardTeamId)
			AttributeDefinition.set(model, AttributeDefinition.Health, disaster.MaxHealth)
			AttributeDefinition.set(model, AttributeDefinition.IsDead, false)
			if not disaster.IsArmed then
				-- the bar over it stays full + nothing comes off
				AttributeDefinition.set(model, AttributeDefinition.IsInvulnerable, true)
				return nil
			end
			-- kept as the first of them stands whole, with what a target wears on it: the one that comes back is
			-- told apart from an avatar + has its health from the moment a client has it
			if building and consequence.Type == "Blast" and not sites[id] then
				sites[id] = BlastSite.new(building, consequence, wreckFolder, startedAt)
			end

			local target: Target = {
				Model = model,
				Disaster = disaster,
				IsAlerted = false,
				IsFallen = false,
			}
			targets[model] = target
			TallyUtil.open(model)
			if building then
				sites[id].Add(building)
			end
			-- the town hears of a round once, as the first health comes off
			local healthConnection = model:GetAttributeChangedSignal(AttributeDefinition.Health.Name):Connect(function()
				local health = AttributeDefinition.get(model, AttributeDefinition.Health)
				if health < disaster.MaxHealth and not target.IsAlerted and not target.IsFallen then
					target.IsAlerted = true
					AlertService:Announce(disaster.Alert)
				end
			end)
			-- it only ever goes down once: what falls is replaced, not stood up again
			local deadConnection = model:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
				if AttributeDefinition.get(model, AttributeDefinition.IsDead) and not target.IsFallen then
					fall(target, id)
				end
			end)

			return function()
				healthConnection:Disconnect()
				deadConnection:Disconnect()
				TallyUtil.close(model)
				targets[model] = nil
				if building then
					sites[id].Remove(building)
				end
			end
		end)

		-- nothing lands where nobody fights, every hit asks the rules as it comes in. a server that stops its fights
		-- while a target is half down has it stand whole again
		local stopMode = ModeDefinition.observe(function(isPVP: boolean)
			if isPVP then
				return
			end
			for _, target in targets do
				refill(target)
			end
		end)

		return table.freeze({
			Destroy = function()
				stopMode()
				stopTargets()
				for _, site in sites do
					site.Destroy()
				end
				table.clear(sites)
				wreckFolder:Destroy()
			end,
		})
	end,
}
