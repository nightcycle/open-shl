--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
export type Properties = {
	Position: Vector3,
	Diameter: number, -- studs across, as it's seen
	CoreSize: number, -- studs across the box at the heart of it a character has to get into
	Color: Color3,
	OnEntered: (character: Model) -> (), -- every time one of them gets in from outside
}
-- Constants
local isProperties = Type.strictInterface({
	Position = AbilityType.FiniteVector3,
	Diameter = Type.numberPositive,
	CoreSize = Type.numberPositive,
	Color = Type.Color3,
	OnEntered = Type.callback,
})
local ORB_NAME = "Orb"
-- Variables
-- References
-- Private Functions
local function getCharacter(part: BasePart): Model?
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end
-- Class
-- a ball of light that hangs in the world for as long as it's on + tells of every character that walks into the
-- heart of it. it's made by the server, so it's there for everybody
return ServerVFX.newState("Orb", isProperties, function(props: Properties)
	local part = Instance.new("Part")
	part.Name = ORB_NAME
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = props.Color
	part.Size = Vector3.one * props.Diameter
	part.Anchored = true
	-- it's walked into rather than run into: it can't push, be stood on or get in the way of a ray
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Position = props.Position
	part.Parent = Workspace

	local core = CFrame.new(props.Position)
	local coreSize = Vector3.one * props.CoreSize
	-- who was in it as of the last look, only somebody new is told of
	local inside: { [Model]: true } = {}
	local connection = RunService.Heartbeat:Connect(function()
		local found: { [Model]: true } = {}
		for _, other in Workspace:GetPartBoundsInBox(core, coreSize) do
			local character = getCharacter(other)
			if character and not found[character] then
				found[character] = true
				if not inside[character] then
					task.spawn(props.OnEntered, character)
				end
			end
		end
		inside = found
	end)
	return function()
		connection:Disconnect()
		part:Destroy()
	end
end)
