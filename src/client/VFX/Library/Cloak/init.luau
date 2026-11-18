--!strict
-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Transparency = require("@self/Transparency")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Cloak
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Cloak, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local fadeDuration = props.FadeDuration or 0
	-- how far in it is, from not at all to all the way. one that doesn't fade is in from the start
	local alpha = if fadeDuration > 0 then 0 else 1
	local function getAmount(): number
		return props.Transparency * TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	end
	local releases: { () -> () } = {}
	local setters: { (amount: number) -> () } = {}
	local function hide(inst: Instance)
		if inst:IsA("BasePart") or inst:IsA("Decal") then
			if fadeDuration > 0 then
				local release, set = Transparency.holdEased(inst, getAmount())
				table.insert(releases, release)
				table.insert(setters, set)
			else
				table.insert(releases, Transparency.hold(inst, props.Transparency))
			end
		elseif props.IsUnlit and inst:IsA("Light") and inst.Enabled then
			-- what can't be seen would still give itself away by what it lights
			inst.Enabled = false
			table.insert(releases, function()
				inst.Enabled = true
			end)
		end
	end
	for _, v in character:GetDescendants() do
		hide(v)
	end
	-- whatever the avatar puts on or takes out while it's on goes the same way
	local connection = character.DescendantAdded:Connect(hide)
	local function release()
		connection:Disconnect()
		for _, v in releases do
			v()
		end
	end
	if fadeDuration <= 0 then
		return release
	end
	-- eased a step a frame: all the way in as it starts, back out once it's stopped. one that's stopped on its way in
	-- turns around where it is
	local fade: RBXScriptConnection? = nil
	local function ease(direction: number)
		if fade then
			fade:Disconnect()
		end
		local step: RBXScriptConnection
		step = RunService.Heartbeat:Connect(function(deltaTime: number)
			alpha = math.clamp(alpha + direction * deltaTime / fadeDuration, 0, 1)
			local amount = getAmount()
			for _, set in setters do
				set(amount)
			end
			if direction > 0 and alpha >= 1 then
				step:Disconnect()
			elseif direction < 0 and alpha <= 0 then
				step:Disconnect()
				release()
			end
		end)
		fade = step
	end
	ease(1)
	return function()
		ease(-1)
	end
end)
