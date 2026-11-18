--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local Regenerate = require("@game/ServerScriptService/Server/VFX/Library/Regenerate")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- studs the bar is long while the user is whole
local BAR_LENGTH = 4
-- Variables
-- References
-- Private Functions
-- Class
-- the bar over the head of the user is their health, it starts out where the control puts it + grows with every lot
-- they have the energy for. nothing is taken for it in a build without energy
return VFXStory.newStateStory({
	Health = UILabs.Slider(10, 1, 100, 1),
	Amount = UILabs.Slider(15, 0, 100, 1),
	Cost = UILabs.Slider(30, 0, 200, 1),
	Interval = UILabs.Slider(2, 0.1, 5, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local user = stage.User
	local head = user:FindFirstChild("Head") :: BasePart
	AttributeDefinition.setDefaults(user, "Character")
	AttributeDefinition.set(user, AttributeDefinition.Health, controls.Health)
	local bar = Instance.new("BoxHandleAdornment")
	bar.Adornee = head
	bar.CFrame = CFrame.new(0, 2, 0)
	bar.Color3 = Color3.new(0, 1, 0)
	bar.AlwaysOnTop = true
	bar.Parent = head
	local function draw()
		local health = AttributeDefinition.get(user, AttributeDefinition.Health)
		bar.Size = Vector3.new(BAR_LENGTH * health / AttributeDefinition.MAX_HEALTH, 0.3, 0.3)
		print(`health: {health}, energy: {AttributeDefinition.get(user, AttributeDefinition.Energy)}`)
	end
	local connection = user:GetAttributeChangedSignal(AttributeDefinition.Health.Name):Connect(draw)
	print(`{controls.Amount} health every {controls.Interval} s, energy enabled: {ModeDefinition.getIfEnergyEnabled()}`)
	local handle = stage.ServerScope.start(Regenerate, {
		Amount = controls.Amount,
		Cost = controls.Cost,
		Interval = controls.Interval,
	})
	return function()
		handle.Stop()
		connection:Disconnect()
		bar:Destroy()
	end
end)
