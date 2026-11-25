--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
-- Types
type SeasonLook = EnvironmentDefinition.SeasonLook
-- a part the way the map has it, which is what it goes back to when no season is drawn
type Authored = {
	Color: Color3,
	Material: Enum.Material,
	Transparency: number,
	CanCollide: boolean,
}
-- a part on its way to a look
type Fade = {
	StartAt: number,
	Duration: number,
	-- the last jump of its color that was made
	Step: number,
	FromColor: Color3,
	ToColor: Color3,
	FromTransparency: number,
	ToTransparency: number,
}
export type Drawer = {
	-- turns the ground, the water, the trees + the fountains of the map to a season, + whatever of them comes into
	-- the world later as it does. without a look they're put back the way the map has them. rushed, nothing fades
	Set: (look: SeasonLook?, isRushed: boolean) -> (),
	Destroy: () -> (),
}
-- Constants
local CLIMATE = EnvironmentDefinition.CLIMATE
-- Variables
-- References
-- Private Functions
-- Class
return {
	new = function(): Drawer
		local look: SeasonLook? = nil
		local rng = Random.new()
		local authored: { [BasePart]: Authored } = {}
		local grounds: { [BasePart]: true } = {}
		local waters: { [BasePart]: true } = {}
		local leaves: { [BasePart]: true } = {}
		-- what a fountain runs with, + if the map has it running
		local jets: { [ParticleEmitter]: boolean } = {}
		local fades: { [BasePart]: Fade } = {}
		local fadeConnection: RBXScriptConnection? = nil

		-- the color of a part doesn't glide, it gets there in a few jumps the way it did in the old place. what it
		-- lets through does glide. one loop for all of them: a tree alone is 8 leaves, the map has some 700
		local function stepFades()
			local now = os.clock()
			for part, fade in fades do
				-- it hasn't set out yet
				if now < fade.StartAt then
					continue
				end
				local alpha = if fade.Duration > 0 then math.min((now - fade.StartAt) / fade.Duration, 1) else 1
				local step = math.floor(alpha * CLIMATE.ColorSteps)
				if step ~= fade.Step then
					fade.Step = step
					part.Color = fade.FromColor:Lerp(fade.ToColor, step / CLIMATE.ColorSteps)
				end
				if fade.FromTransparency ~= fade.ToTransparency then
					part.Transparency = fade.FromTransparency + (fade.ToTransparency - fade.FromTransparency) * alpha
				end
				if alpha >= 1 then
					fades[part] = nil
				end
			end
			if next(fades) == nil and fadeConnection then
				fadeConnection:Disconnect()
				fadeConnection = nil
			end
		end

		-- at once when it's rushed. a part that's on its way somewhere else sets out again from where it got to, +
		-- only a leaf is ever seen through more or less: without a word on it that's left alone
		local function turn(
			part: BasePart,
			color: Color3,
			transparency: number?,
			isRushed: boolean,
			delay: number,
			duration: number
		)
			if isRushed then
				fades[part] = nil
				part.Color = color
				if transparency then
					part.Transparency = transparency
				end
				return
			end
			fades[part] = {
				StartAt = os.clock() + delay,
				Duration = duration,
				Step = 0,
				FromColor = part.Color,
				ToColor = color,
				FromTransparency = part.Transparency,
				ToTransparency = transparency or part.Transparency,
			}
			if not fadeConnection then
				fadeConnection = RunService.Heartbeat:Connect(stepFades)
			end
		end

		-- what it's made of switches at once while its color is still on the way, as it did
		local function drawGround(part: BasePart, isRushed: boolean)
			local was = authored[part]
			if not look then
				turn(part, was.Color, nil, true, 0, 0)
				part.Material = was.Material
				return
			end
			turn(part, look.GroundColor, nil, isRushed, 0, CLIMATE.ChangeDuration)
			part.Material = look.GroundMaterial
		end

		-- only the water that's marked for it freezes over, the sea never does. ice can be stood on
		local function drawWater(part: BasePart, isRushed: boolean)
			local was = authored[part]
			if not look then
				turn(part, was.Color, nil, true, 0, 0)
			else
				turn(part, look.WaterColor, nil, isRushed, 0, CLIMATE.ChangeDuration)
			end
			local freezesRes = MapDefinition.get(part, MapDefinition.Freezes)
			if freezesRes.IsErr then
				warn(freezesRes.Value)
				return
			end
			if freezesRes.Value then
				local isFrozen = look ~= nil and look.IsFrozen
				part.Material = if isFrozen then CLIMATE.IceMaterial else was.Material
				part.CanCollide = if isFrozen then true else was.CanCollide
			end
		end

		-- every leaf picks its own color + sets out in its own time, so no two trees turn alike. a bare tree keeps
		-- its leaves, they only can't be seen
		local function drawLeaf(part: BasePart, isRushed: boolean)
			local was = authored[part]
			if not look then
				turn(part, was.Color, was.Transparency, true, 0, 0)
				return
			end
			local color = look.LeafColors[rng:NextInteger(1, #look.LeafColors)]
			local delay = rng:NextNumber(CLIMATE.LeafDelay.Min, CLIMATE.LeafDelay.Max)
			turn(part, color, look.LeafTransparency, isRushed, delay, CLIMATE.LeafDuration)
		end

		local function drawJet(jet: ParticleEmitter)
			jet.Enabled = if look then not look.IsFrozen else jets[jet]
		end

		local function note(part: BasePart)
			authored[part] = {
				Color = part.Color,
				Material = part.Material,
				Transparency = part.Transparency,
				CanCollide = part.CanCollide,
			}
		end

		local function forget(part: BasePart)
			authored[part] = nil
			fades[part] = nil
		end

		-- whatever comes into the world is drawn as the season has it right then, with nothing to watch fade: it
		-- wasn't there to be seen any other way
		local stopGround = MapDefinition.observe(MapDefinition.SeasonGround, function(part: BasePart): (() -> ())?
			note(part)
			grounds[part] = true
			if look then
				drawGround(part, true)
			end
			return function()
				grounds[part] = nil
				forget(part)
			end
		end)
		local stopWater = MapDefinition.observe(MapDefinition.SeasonWater, function(part: BasePart): (() -> ())?
			note(part)
			waters[part] = true
			if look then
				drawWater(part, true)
			end
			return function()
				waters[part] = nil
				forget(part)
			end
		end)
		-- the parts of a tree may get here after the tree did, so its leaves are whatever it holds + comes to hold
		local stopFoliage = MapDefinition.observe(MapDefinition.Foliage, function(tree: Model): (() -> ())?
			local own: { [BasePart]: true } = {}
			local function add(child: Instance)
				if not child:IsA("BasePart") or child.Material ~= CLIMATE.LeafMaterial or own[child] then
					return
				end
				own[child] = true
				note(child)
				leaves[child] = true
				if look then
					drawLeaf(child, true)
				end
			end
			local function remove(child: Instance)
				if child:IsA("BasePart") and own[child] then
					own[child] = nil
					leaves[child] = nil
					forget(child)
				end
			end
			local addedConnection = tree.ChildAdded:Connect(add)
			local removedConnection = tree.ChildRemoved:Connect(remove)
			for _, child in tree:GetChildren() do
				add(child)
			end
			return function()
				addedConnection:Disconnect()
				removedConnection:Disconnect()
				for child in table.clone(own) do
					remove(child)
				end
			end
		end)
		local stopFountains = MapDefinition.observe(MapDefinition.Fountain, function(fountain: BasePart): (() -> ())?
			local own: { ParticleEmitter } = {}
			local function add(child: Instance)
				if not child:IsA("ParticleEmitter") or jets[child] ~= nil then
					return
				end
				table.insert(own, child)
				jets[child] = child.Enabled
				if look then
					drawJet(child)
				end
			end
			local addedConnection = fountain.ChildAdded:Connect(add)
			for _, child in fountain:GetChildren() do
				add(child)
			end
			return function()
				addedConnection:Disconnect()
				for _, jet in own do
					jets[jet] = nil
				end
			end
		end)

		return table.freeze({
			Set = function(newLook: SeasonLook?, isRushed: boolean)
				look = newLook
				for part in grounds do
					drawGround(part, isRushed)
				end
				for part in waters do
					drawWater(part, isRushed)
				end
				for part in leaves do
					drawLeaf(part, isRushed)
				end
				for jet in jets do
					drawJet(jet)
				end
			end,
			Destroy = function()
				stopGround()
				stopWater()
				stopFoliage()
				stopFountains()
				if fadeConnection then
					fadeConnection:Disconnect()
					fadeConnection = nil
				end
				table.clear(fades)
			end,
		})
	end,
}
