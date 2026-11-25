--!strict
-- Services
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
-- the windows of one building, they switch together
type Building = {
	Model: Model,
	-- nil until it was switched for the first time, it's the way the map has it until then
	IsLit: boolean?,
}
export type Drawer = {
	-- lights the windows of the city or puts them out, one building after another. rushed, all of them at once
	Set: (isLit: boolean, isRushed: boolean) -> (),
	Destroy: () -> (),
}
-- Constants
local WINDOWS = EnvironmentDefinition.CLIMATE.Windows
-- a pane that's out isn't dark, it's gone: the wall behind it is what's seen
local UNLIT_TRANSPARENCY = 1
-- how much a lit pane lets through is picked in hundredths
local TRANSPARENCY_STEPS = 100
-- Variables
-- References
-- Private Functions
-- Class
return {
	new = function(): Drawer
		local isLit: boolean? = nil
		local rng = Random.new()
		local buildings: { [Model]: Building } = {}
		local switchThread: thread? = nil

		-- the more of the room a pane lets through, the less its light reaches
		local function drawLight(light: SurfaceLight, isOn: boolean)
			local pane = light.Parent
			if not isOn or not pane or not pane:IsA("BasePart") then
				light.Enabled = false
				return
			end
			light.Enabled = true
			light.Range = WINDOWS.Range * (1 - pane.Transparency)
		end

		-- every pane picks for itself how bright its room is, on every client for itself
		local function drawPane(pane: BasePart, isOn: boolean)
			pane.Transparency = if isOn
				then rng:NextInteger(
					math.round(WINDOWS.Transparency.Min * TRANSPARENCY_STEPS),
					math.round(WINDOWS.Transparency.Max * TRANSPARENCY_STEPS)
				) / TRANSPARENCY_STEPS
				else UNLIT_TRANSPARENCY
			for _, child in pane:GetChildren() do
				if child:IsA("SurfaceLight") then
					drawLight(child, isOn)
				end
			end
		end

		local function switch(building: Building, isOn: boolean)
			building.IsLit = isOn
			for _, desc in building.Model:GetDescendants() do
				if desc:IsA("BasePart") then
					drawPane(desc, isOn)
				end
			end
		end

		local function stopSwitch()
			if switchThread and coroutine.status(switchThread) == "suspended" then
				task.cancel(switchThread)
			end
			switchThread = nil
		end

		-- a building that comes into the world is switched to what the hour has right then. its panes + their lights
		-- may get here after it did
		local stopWindows = MapDefinition.observe(MapDefinition.NightWindows, function(model: Model): (() -> ())?
			local building: Building = {
				Model = model,
				IsLit = nil,
			}
			buildings[model] = building
			local connection = model.DescendantAdded:Connect(function(desc: Instance)
				local isOn = building.IsLit
				if isOn == nil then
					return
				end
				if desc:IsA("BasePart") then
					drawPane(desc, isOn)
				elseif desc:IsA("SurfaceLight") then
					drawLight(desc, isOn)
				end
			end)
			if isLit ~= nil then
				switch(building, isLit)
			end
			return function()
				connection:Disconnect()
				buildings[model] = nil
			end
		end)

		return table.freeze({
			Set = function(newIsLit: boolean, isRushed: boolean)
				-- a switch that's still going would undo this one building by building
				stopSwitch()
				isLit = newIsLit
				if isRushed then
					for _, building in buildings do
						switch(building, newIsLit)
					end
					return
				end
				local queue: { Building } = {}
				for _, building in buildings do
					table.insert(queue, building)
				end
				local delay = if newIsLit then WINDOWS.OnDelay else WINDOWS.OffDelay
				switchThread = task.spawn(function()
					for _, building in queue do
						-- one that left the world while it waited for its turn has nothing to switch
						if buildings[building.Model] == building then
							switch(building, newIsLit)
							task.wait(delay)
						end
					end
				end)
			end,
			Destroy = function()
				stopSwitch()
				stopWindows()
			end,
		})
	end,
}
