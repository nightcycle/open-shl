--!strict
-- Services
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local CoverUtil = require("@game/ServerScriptService/Server/Util/Cover")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Target: Model?, -- whose root carries it, the character the effect belongs to without
	Size: Vector3,
	Offset: CFrame, -- of the cover from the root
	Color: Color3,
	Material: Enum.Material,
	Transparency: number, -- once it's up
	FadeDuration: number?, -- seconds it takes to show + to go, there + gone at once without
	GrowDuration: number?, -- seconds it takes to grow to its size + to shrink away, its size at once without
	Delay: number?, -- seconds until it's there
	Linger: number?, -- seconds it stays once it's stopped, before it goes
	GoneDuration: number?, -- seconds it's still in the way once it's gone from sight
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.optional(Type.instanceIsA("Model")),
	Size = Type.Vector3,
	Offset = Type.CFrame,
	Color = Type.Color3,
	Material = Type.enum(Enum.Material),
	Transparency = Type.numberConstrained(0, 1),
	FadeDuration = Type.optional(Type.numberMin(0)),
	GrowDuration = Type.optional(Type.numberMin(0)),
	Delay = Type.optional(Type.numberMin(0)),
	Linger = Type.optional(Type.numberMin(0)),
	GoneDuration = Type.optional(Type.numberMin(0)),
})
local COVER_NAME = "Cover"
-- Variables
-- References
-- Private Functions
local function tween(inst: Instance, duration: number, goal: { [string]: any })
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	TweenService:Create(inst, tweenInfo, goal):Play()
end

-- right away if there's nothing to wait for, so what follows a cover with no delay finds it up
local function after(duration: number, fn: () -> ())
	if duration > 0 then
		task.delay(duration, fn)
	else
		fn()
	end
end
-- Class
-- something a character carries between themselves + whoever is after them: a shield ahead of them, the ice they're
-- shut in. it's a part of the server's outside of every character, so a ray anybody lets go ends at it by itself +
-- the server takes no hit that would have had to go into it. nobody runs into it
return ServerVFX.newState("Cover", isProperties, function(props: Properties, scope: ServerScope)
	local owner = props.Target or scope.Character
	local rootPart = if owner then owner.PrimaryPart else nil
	if not owner or not rootPart then
		return function() end
	end
	local fadeDuration = props.FadeDuration or 0
	local growDuration = props.GrowDuration or 0
	local isStopped = false
	local part: Part? = nil
	local mesh: BlockMesh? = nil
	local connection: RBXScriptConnection? = nil
	local function destroy()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if part then
			CoverUtil.remove(part)
			part:Destroy()
			part = nil
		end
	end
	after(props.Delay or 0, function()
		-- it was put away before it was ever there
		if isStopped or not rootPart:IsDescendantOf(Workspace) then
			return
		end
		local cover = Instance.new("Part")
		cover.Name = COVER_NAME
		cover.Size = props.Size
		cover.Color = props.Color
		cover.Material = props.Material
		cover.Transparency = if fadeDuration > 0 then 1 else props.Transparency
		-- it weighs on nobody + nobody runs into it, it's only ever found by what looks for something in the way
		cover.Massless = true
		cover.CanCollide = false
		cover.CanTouch = false
		cover.CastShadow = false
		cover.CFrame = rootPart.CFrame * props.Offset
		local weld = Instance.new("Weld")
		weld.Part0 = rootPart
		weld.Part1 = cover
		weld.C0 = props.Offset
		weld.Parent = cover
		if growDuration > 0 then
			local blockMesh = Instance.new("BlockMesh")
			blockMesh.Scale = Vector3.zero
			blockMesh.Parent = cover
			mesh = blockMesh
			tween(blockMesh, growDuration, { Scale = Vector3.one })
		end
		-- beside the character rather than in it: a part of a character is that character to whatever finds it
		cover.Parent = Workspace
		part = cover
		CoverUtil.add(cover, owner)
		if fadeDuration > 0 then
			tween(cover, fadeDuration, { Transparency = props.Transparency })
		end
		-- nothing holds up a part whose root is gone, it goes with whoever carried it
		connection = rootPart.AncestryChanged:Connect(function()
			if not rootPart:IsDescendantOf(Workspace) then
				destroy()
			end
		end)
	end)
	return function()
		isStopped = true
		after(props.Linger or 0, function()
			local cover = part
			if not cover then
				return
			end
			if fadeDuration > 0 then
				tween(cover, fadeDuration, { Transparency = 1 })
			end
			if mesh and growDuration > 0 then
				tween(mesh, growDuration, { Scale = Vector3.zero })
			end
			after(math.max(fadeDuration, growDuration) + (props.GoneDuration or 0), destroy)
		end)
	end
end)
