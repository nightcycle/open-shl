--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
-- Types
export type Action =
	{
		Type: "Remove",
	}
	| {
		Type: "Move",
		Direction: Vector3, -- along the piece's own axes
	}
	| {
		Type: "Turn",
	}
type PlacementGizmoImpl = {
	__index: PlacementGizmoImpl,
	SetTarget: (self: PlacementGizmo, target: Model?) -> (),
	GetAction: (self: PlacementGizmo, inst: Instance) -> Action?,
	Destroy: (self: PlacementGizmo) -> (),
}
export type PlacementGizmo = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		Instance: Model,
		_Parent: Instance, -- only parented while it floats over a piece
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PlacementGizmoImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local INSTANCE_NAME = "PlacementGizmo"
local REMOVE_NAME = "Delete"
local MOVE_NAME = "TranslateArrow"
local TURN_NAME = "RotateArrow"
local DIRECTION_NAME = "Value" -- the Vector3Value under an arrow
local HOVER_HEIGHT = 0.5
-- Variables
-- References
local Template = IndexUtil.waitForPath("game/ReplicatedStorage/lib/base/gizmo") :: Model
-- Private Functions
-- Class
local PlacementGizmo = {} :: PlacementGizmoImpl
PlacementGizmo.__index = PlacementGizmo

-- turned the way the piece is turned, so every arrow points where it pushes
function PlacementGizmo:SetTarget(target: Model?)
	if not self.IsAlive then
		return
	end
	if not target then
		self.Instance.Parent = nil
		return
	end
	self.Instance:PivotTo(target:GetPivot() + Vector3.new(0, target:GetExtentsSize().Y + HOVER_HEIGHT, 0))
	self.Instance.Parent = self._Parent
end

function PlacementGizmo:GetAction(inst: Instance): Action?
	if not self.IsAlive or inst.Parent ~= self.Instance then
		return nil
	end
	if inst.Name == REMOVE_NAME then
		return {
			Type = "Remove" :: "Remove",
		}
	elseif inst.Name == TURN_NAME then
		return {
			Type = "Turn" :: "Turn",
		}
	elseif inst.Name == MOVE_NAME then
		local direction = inst:FindFirstChild(DIRECTION_NAME)
		if not direction or not direction:IsA("Vector3Value") then
			warn(`an arrow of the gizmo has no direction`)
			return nil
		end
		return {
			Type = "Move" :: "Move",
			Direction = direction.Value,
		}
	end
	return nil
end

function PlacementGizmo:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	self.Instance:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(parent: Instance): PlacementGizmo
		local inst = Template:Clone()
		inst.Name = INSTANCE_NAME
		for _, desc in inst:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				desc.CanTouch = false
			end
		end
		local self = setmetatable({
			IsAlive = true :: true,
			Instance = inst,
			_Parent = parent,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, PlacementGizmo)
		return self
	end,
}
