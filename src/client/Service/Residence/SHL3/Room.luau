--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ApartmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Apartment")
-- Types
local ResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
type ResidenceState = ResidenceType.SHL3State
type Bounds = {
	Center: Vector3,
	Size: Vector3,
}
type RoomImpl = {
	__index: RoomImpl,
	new: (anchor: CFrame, state: ResidenceState, parent: Instance) -> Result<Room, string>,
	from: (interior: unknown) -> Room?,
	GetBounds: (self: Room) -> (CFrame, Vector3),
	SetState: (self: Room, state: ResidenceState) -> (),
	Destroy: (self: Room) -> (),
}
export type Room = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		Instance: Model, -- holds the room of the tier that's owned + the two spots below
		-- where the avatar lands + the pad that leads back out. they're the room's own: a room of another tier has
		-- them elsewhere, whoever listens to them goes on listening as they're moved
		Entrance: BasePart,
		Exit: BasePart,
		State: ResidenceState,
		Rebuilt: Signal<>, -- the owner bought another tier while the avatar was inside, the room is another one
		_Anchor: CFrame,
		_Model: Model?,
	},
	{} :: RoomImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local INSTANCE_NAME = "Apartment"
local ENTRANCE_PATH = "Gate/Teleport"
local EXIT_PATH = "Gate/Telepad"
-- Variables
-- in the space of the anchor a room is built at. it's read off the rooms of the library once
local BoundsCache: Bounds? = nil
-- References
local Library = IndexUtil.waitForPath("game/ReplicatedStorage/lib/apartment") :: Folder
-- Private Functions
local function tryPart(root: Instance, path: string): Result<BasePart, string>
	local instRes = IndexUtil.tryFirstLocalPath(root, path)
	if instRes.IsErr then
		return instRes
	end
	local inst = instRes.Value
	if not inst:IsA("BasePart") then
		return Result.err(`expected a BasePart at "{path}", received a {inst.ClassName}`)
	end
	return Result.ok(inst)
end

local function tryTemplate(tier: number): Result<Model, string>
	local rowRes = ApartmentDefinition.get(tier)
	if rowRes.IsErr then
		return rowRes
	end
	local template = Library:FindFirstChild(rowRes.Value.ModelName)
	if not template or not template:IsA("Model") or not template.PrimaryPart then
		return Result.err(`the library has no room "{rowRes.Value.ModelName}"`)
	end
	return Result.ok(template)
end

-- the box every tier fits in
local function getLibraryBounds(): Bounds
	local bounds = BoundsCache
	if bounds then
		return bounds
	end
	local min, max = Vector3.one * math.huge, Vector3.one * -math.huge
	for _, row in ApartmentDefinition.list() do
		local templateRes = tryTemplate(row.Tier)
		if templateRes.IsErr then
			continue
		end
		local template = templateRes.Value
		-- the box of a model lies along its primary part, which is the anchor of the room
		local box, size = template:GetBoundingBox()
		local center = template:GetPivot():PointToObjectSpace(box.Position)
		min = min:Min(center - size / 2)
		max = max:Max(center + size / 2)
	end
	local newBounds: Bounds = table.freeze({ Center = (min + max) / 2, Size = max - min })
	BoundsCache = newBounds
	return newBounds
end

-- a spot of the room that's listened to: it's as its part of the room is, without being one of them
local function newSpot(name: string, parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	part.Parent = parent
	return part
end

-- the room of a tier stands where the anchor of the flat is: the pane of the tower its own anchor part lies on
local function build(self: Room, tier: number): Result<true, string>
	if not self.IsAlive then
		return Result.err(`the room is gone`)
	end
	local templateRes = tryTemplate(tier)
	if templateRes.IsErr then
		return templateRes
	end
	local model = templateRes.Value:Clone()
	local entranceRes = tryPart(model, ENTRANCE_PATH)
	local exitRes = tryPart(model, EXIT_PATH)
	if entranceRes.IsErr or exitRes.IsErr then
		model:Destroy()
		return Result.err(`room "{model.Name}" has no gate`)
	end
	model:PivotTo(self._Anchor)
	self.Entrance.Size = entranceRes.Value.Size
	self.Entrance.CFrame = entranceRes.Value.CFrame
	self.Exit.Size = exitRes.Value.Size
	self.Exit.CFrame = exitRes.Value.CFrame
	-- a pad that's stepped on twice would lead out twice
	entranceRes.Value:Destroy()
	exitRes.Value:Destroy()
	local priorModel = self._Model
	if priorModel then
		priorModel:Destroy()
	end
	self._Model = model
	model.Parent = self.Instance
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
-- Class
-- the flat of superhero life 3 as its owner's client has it: the room of the tier they bought, built at the anchor
-- the server handed them for the visit. nobody else has it, the tower is as empty behind its panes as it is to them
local Room = {} :: RoomImpl
Room.__index = Room

function Room.new(anchor: CFrame, state: ResidenceState, parent: Instance): Result<Room, string>
	local instance = Instance.new("Model")
	instance.Name = INSTANCE_NAME
	local self = setmetatable({
		IsAlive = true :: true,
		Instance = instance,
		Entrance = newSpot("Entrance", instance),
		Exit = newSpot("Exit", instance),
		State = state,
		Rebuilt = Signal.new() :: Signal<>,
		_Anchor = anchor,
		_Model = nil :: Model?,
	}, Room)
	local buildRes = build(self, state.Tier)
	if buildRes.IsErr then
		self:Destroy()
		return buildRes
	end
	instance.Parent = parent
	return Result.ok(self)
end

-- the room behind what the residence service holds, nil for anything that isn't one
function Room.from(interior: unknown): Room?
	if type(interior) == "table" and getmetatable(interior :: any) == Room then
		return interior :: any
	end
	return nil
end

-- whatever tier it's of: the box the service keeps the avatar in is asked for once, the room may change after
function Room:GetBounds(): (CFrame, Vector3)
	local anchor = if self.IsAlive then self._Anchor else CFrame.identity
	local bounds = getLibraryBounds()
	return anchor * CFrame.new(bounds.Center), bounds.Size
end

function Room:SetState(state: ResidenceState)
	if not self.IsAlive then
		return
	end
	local priorState = self.State
	self.State = state
	if priorState.Tier == state.Tier then
		return
	end
	local buildRes = build(self, state.Tier)
	if buildRes.IsErr then
		-- the room of before stays up, it's left by its own pad
		warn(`room err: {buildRes.Value}`)
		return
	end
	self.Rebuilt:Fire()
end

function Room:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	self.Rebuilt:Destroy()
	self.Instance:Destroy()
	table.clear(self :: any)
end

return Room
