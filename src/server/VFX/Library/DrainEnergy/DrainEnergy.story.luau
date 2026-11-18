--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local DrainEnergy = require("@game/ServerScriptService/Server/VFX/Library/DrainEnergy")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- studs the bar is long while the user has all of their energy
local BAR_LENGTH = 4
-- Variables
-- References
-- Private Functions
-- Class
-- the bar over the head of the user is what they have left, it starts out full + turns red once there isn't enough
-- of it to go on. nothing is taken in a build without energy
return VFXStory.newStateStory({
	Amount = UILabs.Slider(6, 0, 100, 1),
	Interval = UILabs.Slider(0.9, 0.1, 5, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local user = stage.User
	local head = user:FindFirstChild("Head") :: BasePart
	AttributeDefinition.setDefaults(user, "Character")
	local bar = Instance.new("BoxHandleAdornment")
	bar.Adornee = head
	bar.CFrame = CFrame.new(0, 2, 0)
	bar.Color3 = Color3.new(0, 1, 0)
	bar.AlwaysOnTop = true
	bar.Parent = head
	local function draw()
		local energy = AttributeDefinition.get(user, AttributeDefinition.Energy)
		bar.Size = Vector3.new(BAR_LENGTH * energy / AttributeDefinition.MAX_ENERGY, 0.3, 0.3)
	end
	draw()
	local connection = user:GetAttributeChangedSignal(AttributeDefinition.Energy.Name):Connect(draw)
	print(
		`draining {controls.Amount} every {controls.Interval} s, energy enabled: {ModeDefinition.getIfEnergyEnabled()}`
	)
	local handle = stage.ServerScope.start(DrainEnergy, {
		Amount = controls.Amount,
		Interval = controls.Interval,
		OnEmpty = function()
			bar.Color3 = Color3.new(1, 0, 0)
			print(`empty, energy: {AttributeDefinition.get(user, AttributeDefinition.Energy)}`)
		end,
	})
	return function()
		handle.Stop()
		connection:Disconnect()
		bar:Destroy()
	end
end)
