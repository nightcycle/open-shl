--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
export type Drawer = {
	-- when the clock of the server started, which the spouts keep their time by. without it they're left as they are
	Set: (startedAt: number?) -> (),
	Destroy: () -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {
	new = function(): Drawer
		-- nil until the clock is known
		local isSpouting: boolean? = nil
		local jets: { [ParticleEmitter]: true } = {}
		local spoutThread: thread? = nil

		local function stop()
			if spoutThread and coroutine.status(spoutThread) == "suspended" then
				task.cancel(spoutThread)
			end
			spoutThread = nil
		end

		-- one that comes into the world runs or doesn't the way the others do right then, so the lot stays in step
		local stopSpouts = MapDefinition.observe(MapDefinition.Spout, function(spout: BasePart): (() -> ())?
			local own: { ParticleEmitter } = {}
			local function add(child: Instance)
				if not child:IsA("ParticleEmitter") or jets[child] then
					return
				end
				table.insert(own, child)
				jets[child] = true
				if isSpouting ~= nil then
					child.Enabled = isSpouting
				end
			end
			local connection = spout.ChildAdded:Connect(add)
			for _, child in spout:GetChildren() do
				add(child)
			end
			return function()
				connection:Disconnect()
				for _, jet in own do
					jets[jet] = nil
				end
			end
		end)

		return table.freeze({
			Set = function(startedAt: number?)
				stop()
				if not startedAt then
					return
				end
				-- it sleeps from one turn to the next, no frame is asked anything in between. the winter doesn't
				-- stop them: they run over the ice, as they did
				spoutThread = task.spawn(function()
					while true do
						local isOn, remaining =
							EnvironmentDefinition.getIfSpouting(startedAt, Workspace:GetServerTimeNow())
						isSpouting = isOn
						for jet in jets do
							jet.Enabled = isOn
						end
						task.wait(remaining)
					end
				end)
			end,
			Destroy = function()
				stop()
				stopSpouts()
			end,
		})
	end,
}
