--!strict
-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
local SweepUtil = require("@game/ReplicatedStorage/Shared/Util/Sweep")
-- Types
export type Drawer = {
	Destroy: () -> (),
}
-- a beam this client has, + what the server said of its sweep. nil for one it said nothing of yet
type Beam = {
	Part: BasePart?,
	Sweep: {
		From: CFrame,
		To: CFrame,
		Duration: number,
	}?,
}
-- a half of a vault door this client has
type Half = {
	-- nil for one the server said nothing of yet
	Slide: {
		ClosedPivot: CFrame,
		-- studs over where it's shut that it's at while open, + where it set out from on the slide it's on
		OpenOffset: number,
		StartOffset: number,
		IsOpen: boolean,
		ChangedAt: number,
		Duration: number,
	}?,
	-- studs over where it's shut it was last put at, nil for one that was never put anywhere
	Offset: number?,
	IsAtRest: boolean,
}
-- Constants
-- the part of a marked model that's the beam itself
local BEAM_NAME = "Beam"
-- how a half of a vault door gets going + comes to rest, as its old place had it
local SLIDE_STYLE = Enum.EasingStyle.Quad
local SLIDE_DIRECTION = Enum.EasingDirection.Out
-- Variables
-- References
-- Private Functions
-- nil while the server didn't say all of it
local function readSweep(model: Model): { From: CFrame, To: CFrame, Duration: number }?
	local fromRes = MapDefinition.get(model, MapDefinition.SweepFrom)
	local toRes = MapDefinition.get(model, MapDefinition.SweepTo)
	local paceRes = MapDefinition.get(model, MapDefinition.SweepPace)
	local durationRes = MapDefinition.get(model, MapDefinition.SweepDuration)
	if fromRes.IsErr or toRes.IsErr or paceRes.IsErr or durationRes.IsErr then
		return nil
	end
	return {
		From = fromRes.Value,
		To = toRes.Value,
		Duration = durationRes.Value * paceRes.Value,
	}
end

-- what the server says of the half now. it sets out from where this client last had it: a slide that's turned
-- around on its way goes back from there. one that's seen for the first time is taken to come from the other end
local function readSlide(model: Model, half: Half)
	local closedRes = MapDefinition.get(model, MapDefinition.ClosedPivot)
	local slideRes = MapDefinition.get(model, MapDefinition.Slide)
	local isOpenRes = MapDefinition.get(model, MapDefinition.IsOpen)
	local changedRes = MapDefinition.get(model, MapDefinition.ChangedAt)
	local durationRes = MapDefinition.get(model, MapDefinition.SlideDuration)
	if closedRes.IsErr or slideRes.IsErr or isOpenRes.IsErr or changedRes.IsErr or durationRes.IsErr then
		half.Slide = nil
		return
	end
	local isOpen, openOffset = isOpenRes.Value, slideRes.Value
	half.Slide = {
		ClosedPivot = closedRes.Value,
		OpenOffset = openOffset,
		StartOffset = half.Offset or if isOpen then 0 else openOffset,
		IsOpen = isOpen,
		ChangedAt = changedRes.Value,
		Duration = durationRes.Value,
	}
	half.IsAtRest = false
end
-- Class
-- what a client draws of a bank: the beams that sweep its hall + the halves of its vault doors as they slide, on
-- the map's own parts. the server moves neither. where a beam is follows from the clock both sides read, so every
-- client has it where the server looks for whoever it went through; a door is said to be open or shut + since
-- when, so a client that comes by in the middle of a slide has it where everybody else does
return {
	new = function(): Drawer
		local beams: { [Model]: Beam } = {}
		local halves: { [Model]: Half } = {}

		-- under streaming a model is here before what's in it, + its parts come + go by themselves
		local stopBeams = MapDefinition.observe(MapDefinition.LaserBeam, function(model: Model): (() -> ())?
			local beam: Beam = {
				Sweep = readSweep(model),
			}
			local function find()
				local part = model:FindFirstChild(BEAM_NAME)
				beam.Part = if part and part:IsA("BasePart") then part else nil
			end
			find()
			beams[model] = beam
			local connections = {
				model.ChildAdded:Connect(find),
				model.ChildRemoved:Connect(find),
				model.AttributeChanged:Connect(function()
					beam.Sweep = readSweep(model)
				end),
			}
			return function()
				for _, connection in connections do
					connection:Disconnect()
				end
				beams[model] = nil
			end
		end)

		local stopHalves = MapDefinition.observe(MapDefinition.VaultDoor, function(model: Model): (() -> ())?
			local half: Half = {
				IsAtRest = false,
			}
			readSlide(model, half)
			halves[model] = half
			local connection = model.AttributeChanged:Connect(function()
				readSlide(model, half)
			end)
			return function()
				connection:Disconnect()
				halves[model] = nil
			end
		end)

		local stepConnection = RunService.RenderStepped:Connect(function()
			local now = Workspace:GetServerTimeNow()
			for _, beam in beams do
				local part, sweep = beam.Part, beam.Sweep
				if part and sweep then
					part.CFrame = SweepUtil.getCFrame(sweep.From, sweep.To, now, sweep.Duration)
				end
			end
			for model, half in halves do
				local slide = half.Slide
				if not slide or half.IsAtRest then
					continue
				end
				local alpha = math.clamp((now - slide.ChangedAt) / slide.Duration, 0, 1)
				local eased = TweenService:GetValue(alpha, SLIDE_STYLE, SLIDE_DIRECTION)
				local goal = if slide.IsOpen then slide.OpenOffset else 0
				local offset = slide.StartOffset + (goal - slide.StartOffset) * eased
				half.Offset = offset
				half.IsAtRest = alpha >= 1
				model:PivotTo(slide.ClosedPivot + Vector3.new(0, offset, 0))
			end
		end)

		return table.freeze({
			Destroy = function()
				stepConnection:Disconnect()
				stopBeams()
				stopHalves()
			end,
		})
	end,
}
