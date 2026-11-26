--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
export type Properties = {
	CFrame: CFrame,
	Size: Vector3,
	Color: Color3,
	Lifetime: number, -- seconds it stands at full strength
	FadeDuration: number, -- seconds it takes to go after that
	Transparency: number?, -- how far it's seen through while it stands, a wall of light is all but solid without
	EndTransparency: number?, -- how far it's seen through as it goes, it has faded to nothing by then without
}
-- Constants
local isProperties = Type.strictInterface({
	CFrame = Type.CFrame,
	Size = Type.Vector3,
	Color = Type.Color3,
	Lifetime = Type.numberMin(0),
	FadeDuration = Type.numberMin(0),
	Transparency = Type.optional(Type.numberConstrained(0, 1)),
	EndTransparency = Type.optional(Type.numberConstrained(0, 1)),
})
local BARRIER_NAME = "Barrier"
local TRANSPARENCY = 0.2
local FADE_STEP_COUNT = 32
-- Variables
-- References
-- Private Functions
-- Class
-- a wall of light everybody runs into until it has faded. it's made by the server, so it's in the way of all of them
return ServerVFX.newEvent("Barrier", isProperties, function(props: Properties): nil
	local transparency = props.Transparency or TRANSPARENCY
	local endTransparency = props.EndTransparency or 1
	local part = Instance.new("Part")
	part.Name = BARRIER_NAME
	part.Anchored = true
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.Color = props.Color
	part.Size = props.Size
	part.CFrame = props.CFrame
	part.Parent = Workspace
	task.delay(props.Lifetime, function()
		for step = 1, FADE_STEP_COUNT do
			task.wait(props.FadeDuration / FADE_STEP_COUNT)
			part.Transparency = transparency + (endTransparency - transparency) * step / FADE_STEP_COUNT
		end
		part:Destroy()
	end)
	return nil
end)
