--!strict
-- Services
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
-- Packages
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local PlacementGizmo = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/PlacementGizmo")
local Residence = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/Residence")
-- Types
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
type PlacementGizmo = PlacementGizmo.PlacementGizmo
type Residence = Residence.Residence
export type FurniturePlacement = SessionType.FurniturePlacement
export type FurnitureMove = SessionType.FurnitureMove
-- the copy of a piece of furniture that follows the pointer over the pads
type Ghost = {
	FurnitureId: string,
	Model: Model,
	Transparencies: { [BasePart]: number }, -- what each part goes back to on a spot it can stand on
	Placement: FurniturePlacement?, -- nil while the pointer is off the pads
	IsValid: boolean,
}
type PlacementImpl = {
	__index: PlacementImpl,
	GetFurnitureId: (self: Placement) -> string?,
	SetFurnitureId: (self: Placement, furnitureId: string?) -> Result<true, string>,
	GetSelection: (self: Placement) -> string?,
	SetSelection: (self: Placement, placedId: string?) -> (),
	Destroy: (self: Placement) -> (),
}
export type Placement = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		Residence: Residence,
		-- requests only, nothing in the base changes until the layout came back
		PlaceRequested: Signal<FurniturePlacement>,
		MoveRequested: Signal<FurnitureMove>,
		RemoveRequested: Signal<string>, -- the id of the placed piece
		SelectionChanged: Signal<string?>, -- the id of the placed piece
		_Ghost: Ghost?,
		_SelectedId: string?,
		_SelectionBox: SelectionBox,
		_Gizmo: PlacementGizmo,
		_Pointer: Vector2?, -- screen position of the mouse or the last touch, top bar included
		_PadParams: RaycastParams, -- what the ghost is aimed at
		_PieceParams: RaycastParams, -- what a click is aimed at: furniture + the gizmo
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PlacementImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local RAY_LENGTH = 1_000
local INVALID_TRANSPARENCY = 0.7
local SELECTION_COLOR = Color3.new(1, 1, 1)
-- Variables
-- References
-- Private Functions
local function getRay(pointer: Vector2): Ray?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	return camera:ViewportPointToRay(pointer.X, pointer.Y)
end

local function newGhost(furnitureId: string): Result<Ghost, string>
	local modelRes = BaseUtil.newModel(furnitureId)
	if modelRes.IsErr then
		return modelRes
	end
	local model = modelRes.Value
	local transparencies: { [BasePart]: number } = {}
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			-- the anchor of the model is never seen
			if desc ~= model.PrimaryPart then
				transparencies[desc] = desc.Transparency
			end
		elseif desc:IsA("Sound") or desc:IsA("Humanoid") then
			-- a hum would follow the pointer around + a humanoid keeps its body solid whatever its parts are told
			desc:Destroy()
		end
	end
	local out: Ghost = {
		FurnitureId = furnitureId,
		Model = model,
		Transparencies = transparencies,
		Placement = nil,
		IsValid = false,
	}
	return Result.ok(out)
end

local function setIsValid(ghost: Ghost, isValid: boolean)
	ghost.IsValid = isValid
	for part, transparency in ghost.Transparencies do
		part.Transparency = if isValid then transparency else INVALID_TRANSPARENCY
	end
end

local function getPlacement(self: Placement, furnitureId: string): FurniturePlacement?
	if not self.IsAlive then
		return nil
	end
	local residence = self.Residence
	local pointer = self._Pointer
	if not residence.IsAlive or not pointer then
		return nil
	end
	local ray = getRay(pointer)
	if not ray then
		return nil
	end
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, self._PadParams)
	if not hit then
		return nil
	end
	local zoneId = residence:GetZoneId(hit.Instance)
	local pad = zoneId and residence.Pads[zoneId]
	if not zoneId or not pad then
		return nil
	end
	local point = pad.CFrame:PointToObjectSpace(hit.Position)
	-- the pads are rotated in the world, the ghost follows the base
	local rotationDeg = BaseUtil.getRotationDeg(pad.CFrame:ToObjectSpace(residence.Interior:GetPivot()))
	local cframe = BaseUtil.newCFrame(point.X, point.Z, rotationDeg)
	local out: FurniturePlacement = {
		FurnitureId = furnitureId,
		ZoneId = zoneId,
		X = cframe.X,
		Z = cframe.Z,
		RotationDeg = rotationDeg,
	}
	return out
end

-- runs every frame, the camera moves under a pointer that stays where it is
local function stepGhost(self: Placement)
	if not self.IsAlive then
		return
	end
	local ghost = self._Ghost
	local residence = self.Residence
	if not ghost or not residence.IsAlive then
		return
	end
	local placement = getPlacement(self, ghost.FurnitureId)
	local pad = placement and residence.Pads[placement.ZoneId]
	if not placement or not pad then
		ghost.Placement = nil
		ghost.Model.Parent = nil
		return
	end
	local previous = ghost.Placement
	if
		previous
		and previous.ZoneId == placement.ZoneId
		and previous.X == placement.X
		and previous.Z == placement.Z
		and previous.RotationDeg == placement.RotationDeg
	then
		return
	end
	ghost.Placement = placement
	local cframe = BaseUtil.newCFrame(placement.X, placement.Z, placement.RotationDeg)
	-- the rule of the server: the footprint has to stay on the one pad
	local inBoundsRes = FurnitureDefinition.getIfInBounds(ghost.FurnitureId, cframe)
	setIsValid(ghost, inBoundsRes.IsOk and inBoundsRes.Value)
	ghost.Model:PivotTo(pad.CFrame * cframe)
	ghost.Model.Parent = residence.Instance
end

local function removeGhost(self: Placement)
	if not self.IsAlive then
		return
	end
	local ghost = self._Ghost
	if not ghost then
		return
	end
	self._Ghost = nil
	ghost.Model:Destroy()
end

local function act(self: Placement, action: PlacementGizmo.Action)
	if not self.IsAlive then
		return
	end
	local residence = self.Residence
	local selectedId = self._SelectedId
	local placed = if selectedId and residence.IsAlive then residence:GetPlaced(selectedId) else nil
	if not placed then
		return
	end
	if action.Type == "Remove" then
		self.RemoveRequested:Fire(placed.Id)
		return
	end
	local cframe = if action.Type == "Move"
		then BaseUtil.nudge(placed.CFrame, action.Direction)
		else BaseUtil.turn(placed.CFrame)
	local furnitureMove: FurnitureMove = {
		Id = placed.Id,
		ZoneId = placed.ZoneId,
		X = cframe.X,
		Z = cframe.Z,
		RotationDeg = BaseUtil.getRotationDeg(cframe),
	}
	self.MoveRequested:Fire(furnitureMove)
end

local function click(self: Placement, pointer: Vector2)
	if not self.IsAlive then
		return
	end
	self._Pointer = pointer
	local ghost = self._Ghost
	if ghost then
		-- a touch has nothing to hover with, the ghost goes where the tap is before it's stamped
		stepGhost(self)
		local placement = ghost.Placement
		if placement and ghost.IsValid then
			self.PlaceRequested:Fire(placement)
		end
		return
	end
	local ray = getRay(pointer)
	local hit = ray and Workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, self._PieceParams)
	if not hit then
		self:SetSelection(nil)
		return
	end
	local gizmo = self._Gizmo
	local action = if gizmo.IsAlive then gizmo:GetAction(hit.Instance) else nil
	if action then
		act(self, action)
		return
	end
	local residence = self.Residence
	self:SetSelection(if residence.IsAlive then residence:GetPlacedId(hit.Instance) else nil)
end
-- Class
local Placement = {} :: PlacementImpl
Placement.__index = Placement

function Placement:GetFurnitureId(): string?
	if not self.IsAlive then
		return nil
	end
	local ghost = self._Ghost
	return ghost and ghost.FurnitureId
end

function Placement:SetFurnitureId(furnitureId: string?): Result<true, string>
	if not self.IsAlive then
		return Result.err(`the base isn't built on anymore`)
	end
	if self:GetFurnitureId() ~= furnitureId then
		removeGhost(self)
		if furnitureId then
			local ghostRes = newGhost(furnitureId)
			if ghostRes.IsErr then
				return ghostRes
			end
			self._Ghost = ghostRes.Value
			self:SetSelection(nil)
			stepGhost(self)
		end
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function Placement:GetSelection(): string?
	if not self.IsAlive then
		return nil
	end
	return self._SelectedId
end

function Placement:SetSelection(placedId: string?)
	if not self.IsAlive then
		return
	end
	local residence = self.Residence
	local model = if placedId and residence.IsAlive then residence:GetModel(placedId) else nil
	local selectedId = if model then placedId else nil
	self._SelectionBox.Adornee = model
	local gizmo = self._Gizmo
	if gizmo.IsAlive then
		gizmo:SetTarget(model)
	end
	if self._SelectedId ~= selectedId then
		self._SelectedId = selectedId
		self.SelectionChanged:Fire(selectedId)
	end
end

function Placement:Destroy()
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
	local ghost = self._Ghost
	if ghost then
		ghost.Model:Destroy()
	end
	self._SelectionBox:Destroy()
	local gizmo = self._Gizmo
	if gizmo.IsAlive then
		gizmo:Destroy()
	end
	local residence = self.Residence
	if residence.IsAlive then
		residence:SetPadsShown(false)
	end
	self.PlaceRequested:Destroy()
	self.MoveRequested:Destroy()
	self.RemoveRequested:Destroy()
	self.SelectionChanged:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(residence: Residence): Result<Placement, string>
		if not residence.IsAlive then
			return Result.err(`there's no residence to build on`)
		end
		local pads: { Instance } = {}
		for _, pad in residence.Pads do
			table.insert(pads, pad)
		end
		local padParams = RaycastParams.new()
		padParams.FilterType = Enum.RaycastFilterType.Include
		padParams.FilterDescendantsInstances = pads

		local gizmo = PlacementGizmo.new(residence.Instance)
		if not gizmo.IsAlive then
			return Result.err(`there's no gizmo to build with`)
		end
		local pieceParams = RaycastParams.new()
		pieceParams.FilterType = Enum.RaycastFilterType.Include
		pieceParams.FilterDescendantsInstances = { residence.Furniture, gizmo.Instance }

		local selectionBox = Instance.new("SelectionBox")
		selectionBox.Color3 = SELECTION_COLOR
		selectionBox.Parent = residence.Instance

		local self = setmetatable({
			IsAlive = true :: true,
			Residence = residence,
			PlaceRequested = Signal.new(),
			MoveRequested = Signal.new(),
			RemoveRequested = Signal.new(),
			SelectionChanged = Signal.new(),
			_Ghost = nil :: Ghost?,
			_SelectedId = nil :: string?,
			_SelectionBox = selectionBox,
			_Gizmo = gizmo,
			_Pointer = if UserInputService.MouseEnabled then UserInputService:GetMouseLocation() else nil,
			_PadParams = padParams,
			_PieceParams = pieceParams,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, Placement)

		residence:SetPadsShown(true)
		-- somebody else may have moved or removed the piece that's picked
		local layoutConnection = residence.LayoutChanged:Connect(function()
			if self.IsAlive then
				self:SetSelection(self._SelectedId)
			end
		end)
		table.insert(self._CleanUpCallbacks, function()
			layoutConnection:Disconnect()
		end)
		table.insert(
			self._Connections,
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if self.IsAlive and input.UserInputType == Enum.UserInputType.MouseMovement then
					self._Pointer = UserInputService:GetMouseLocation()
				end
			end)
		)
		-- a click the interface took for itself isn't one on the base
		table.insert(
			self._Connections,
			UserInputService.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
				if isProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				click(self, UserInputService:GetMouseLocation())
			end)
		)
		table.insert(
			self._Connections,
			UserInputService.TouchTapInWorld:Connect(function(position: Vector2, isProcessed: boolean)
				if isProcessed then
					return
				end
				-- a touch is measured from under the top bar, the camera wants it from the corner of the screen
				local inset = GuiService:GetGuiInset()
				click(self, position + inset)
			end)
		)
		table.insert(
			self._Connections,
			RunService.RenderStepped:Connect(function()
				stepGhost(self)
			end)
		)

		return Result.ok(self)
	end,
}
