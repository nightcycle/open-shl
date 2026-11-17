--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local HazardService = require("@game/ServerScriptService/Server/Service/Hazard")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Reactor = {
	Trigger: BasePart,
	Alarm: Sound?,
	-- the sheet of lightning that fills the room during a meltdown
	MeltBeam: BasePart,
	MeltLightning: ParticleEmitter?,
	-- what spins in the middle: the rods + the arcs between them, around a core that flickers
	Rotary: Model,
	Glow: ParticleEmitter?,
	Rods: { BasePart },
	Arcs: { ParticleEmitter },
	IsMeltingDown: boolean,
	IsBusy: boolean, -- the trigger was just used
}
type ReactorServiceImpl = {
	__index: ReactorServiceImpl,
}
export type ReactorService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ReactorServiceImpl
))
-- Constants
local TRIGGER_NAME = "Trigger"
local MELT_BEAM_NAME = "MeltBeam"
local ROTARY_NAME = "Rotary"
local ROD_NAME = "Rod"
local LIGHTNING_NAME = "Lightning"
local GLOW_NAME = "Glow"
local TRIGGER_COOLDOWN = 1
local SPIN_INTERVAL = 0.05
local SPIN_STEP = math.rad(2)
local MELTDOWN_COLOR = BrickColor.new("Really red")
local STABLE_COLOR = BrickColor.new("Lime green")
-- Variables
-- References
-- Private Functions
local function newReactor(model: Model): Result<Reactor, string>
	local trigger = model:FindFirstChild(TRIGGER_NAME)
	local meltBeam = model:FindFirstChild(MELT_BEAM_NAME)
	local rotary = model:FindFirstChild(ROTARY_NAME)
	if not trigger or not trigger:IsA("BasePart") then
		return Result.err(`{model:GetFullName()} has no trigger`)
	end
	if not meltBeam or not meltBeam:IsA("BasePart") then
		return Result.err(`{model:GetFullName()} has no melt beam`)
	end
	if not rotary or not rotary:IsA("Model") then
		return Result.err(`{model:GetFullName()} has no rotary`)
	end
	local reactor: Reactor = {
		Trigger = trigger,
		Alarm = trigger:FindFirstChildOfClass("Sound"),
		MeltBeam = meltBeam,
		MeltLightning = meltBeam:FindFirstChildOfClass("ParticleEmitter"),
		Rotary = rotary,
		Rods = {},
		Arcs = {},
		IsMeltingDown = false,
		IsBusy = false,
	}
	for _, v in rotary:GetDescendants() do
		if v:IsA("BasePart") and v.Name == ROD_NAME then
			table.insert(reactor.Rods, v)
		elseif v:IsA("ParticleEmitter") and v.Name == LIGHTNING_NAME then
			table.insert(reactor.Arcs, v)
		elseif v:IsA("ParticleEmitter") and v.Name == GLOW_NAME then
			reactor.Glow = v
		end
	end
	return Result.ok(reactor)
end

-- a meltdown takes the rods + their arcs out of sight, the lightning fills the room in their place
local function setMeltingDown(reactor: Reactor, isMeltingDown: boolean)
	assert(HazardService.IsInitialized, `the hazard service isn't initialized`)
	reactor.IsMeltingDown = isMeltingDown
	reactor.Trigger.BrickColor = if isMeltingDown then MELTDOWN_COLOR else STABLE_COLOR
	if reactor.Alarm then
		if isMeltingDown then
			reactor.Alarm:Play()
		else
			reactor.Alarm:Stop()
		end
	end
	if reactor.MeltLightning then
		reactor.MeltLightning.Enabled = isMeltingDown
	end
	for _, arc in reactor.Arcs do
		arc.Enabled = not isMeltingDown
	end
	for _, rod in reactor.Rods do
		rod.Transparency = if isMeltingDown then 1 else 0
	end
	-- the lightning only hurts where players can be hurt at all
	HazardService:SetLethal(reactor.MeltBeam, isMeltingDown and BUILD_CONFIG.PVP_ENABLED)
end

-- yields for as long as the service lives
local function spin(reactor: Reactor)
	local pivot = reactor.Rotary:GetPivot()
	local step = 0
	while true do
		task.wait(SPIN_INTERVAL)
		step += 1
		if reactor.Glow then
			reactor.Glow.Enabled = not reactor.Glow.Enabled
		end
		-- turned from where it started, so the turns don't add up to a drift
		reactor.Rotary:PivotTo(pivot * CFrame.Angles(0, step * SPIN_STEP, 0))
	end
end
-- Class
local ReactorService = {} :: ReactorServiceImpl
ReactorService.__index = ReactorService

return ServiceLocker(function(): ReactorService
	assert(HazardService.IsInitialized, `the hazard service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ReactorService)

	for _, model in MapDefinition.list(MapDefinition.Reactor) do
		local reactorRes = newReactor(model)
		if reactorRes.IsErr then
			warn(`reactor err: {reactorRes.Value}`)
			continue
		end
		local reactor = reactorRes.Value
		table.insert(
			self._Connections,
			reactor.Trigger.Touched:Connect(function()
				if reactor.IsBusy then
					return
				end
				reactor.IsBusy = true
				setMeltingDown(reactor, not reactor.IsMeltingDown)
				task.wait(TRIGGER_COOLDOWN)
				reactor.IsBusy = false
			end)
		)
		local spinThread = task.spawn(spin, reactor)
		table.insert(self._CleanUpCallbacks, function()
			task.cancel(spinThread)
		end)
	end

	return self
end, function(self: ReactorService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
