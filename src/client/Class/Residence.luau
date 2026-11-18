--!strict
-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local ItemUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Item")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Signal<T...> = Signal.Signal<T...>
type Appearance = AppearanceType.Appearance
type ResidenceState = SessionType.ResidenceState
export type PlacedFurniture = BaseType.PlacedFurniture
export type ZoneId = BaseType.ZoneId
-- a way from one floor of the residence to the other
export type Passage = {
	Trigger: BasePart,
	Exit: BasePart,
	Return: BasePart, -- the trigger next to the exit that leads back
	IsToBase: boolean,
}
type Piece = {
	Placed: PlacedFurniture,
	Model: Model,
	Costume: Appearance?, -- what a suit display wears right now
}
-- one half of the bookshelf the base hides behind
type ShelfDoor = {
	Model: Model,
	Closed: CFrame,
	Direction: Vector3, -- the way it slides open
}
type ResidenceImpl = {
	__index: ResidenceImpl,
	SetState: (self: Residence, state: ResidenceState) -> (),
	GetZoneId: (self: Residence, pad: Instance) -> ZoneId?,
	GetPlaced: (self: Residence, placedId: string) -> PlacedFurniture?,
	GetModel: (self: Residence, placedId: string) -> Model?,
	GetPlacedId: (self: Residence, inst: Instance) -> string?,
	SetPadsShown: (self: Residence, isShown: boolean) -> (),
	OpenShelf: (self: Residence) -> (),
	Destroy: (self: Residence) -> (),
}
export type Residence = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		Instance: Model,
		Frame: Model, -- the shell: the apartment + the walls around the base below it
		Interior: Model, -- the base: what the themes recolor + the pads
		Furniture: Folder, -- parent of every placed piece
		Entrance: BasePart, -- where the avatar lands as it comes in
		Exit: BasePart, -- the door of the apartment
		Passages: { Passage },
		ShelfTrigger: BasePart, -- stepped on it opens the bookshelf
		Pads: { [ZoneId]: BasePart },
		State: ResidenceState,
		StateChanged: Signal<ResidenceState>, -- fires once the furniture + the theme match the new state
		_Pieces: { [string]: Piece },
		_ShelfDoors: { ShelfDoor },
		_IsShelfOpen: boolean,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ResidenceImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
local INSTANCE_NAME = "Residence"
local FURNITURE_NAME = "Furniture"
local ENTRANCE_PATH = "Apartment/ApartPort"
local EXIT_PATH = "Apartment/ApartTrigger"
local APARTMENT_TRIGGER_PATH = "Apar2BaseTrig"
local BASE_TRIGGER_PATH = "Base2AparTrig"
local SHELF_TRIGGER_PATH = "Apartment/SecretShelf/Trigger"
-- SIGN is the way a half slides along its own depth
local SHELF_DOORS = table.freeze({
	{ PATH = "Apartment/SecretShelf/Door1", SIGN = 1 },
	{ PATH = "Apartment/SecretShelf/Door2", SIGN = -1 },
})
local EXIT_NAME = "Exit"
local PAD_NAME = "SelectionZone"
local PAD_ID_NAME = "ID"
local PAD_COLOR = Color3.fromRGB(255, 255, 0)
local PAD_SHOWN_TRANSPARENCY = 0.7
local PAD_HIDDEN_TRANSPARENCY = 1
local SHELF_SLIDE_DISTANCE = 3.8
local SHELF_SLIDE_DURATION = 0.76
local SHELF_OPEN_DURATION = 10
-- what the rooms are lit by on top of their own fittings
local INDOOR_AMBIENT = Color3.fromRGB(140, 140, 140)
-- Variables
-- References
local FrameTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/base/frame") :: Model
local InteriorTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/base/interiors/facility") :: Model
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

local function tryPassage(
	frame: Model,
	triggerPath: string,
	returnPath: string,
	isToBase: boolean
): Result<Passage, string>
	local triggerRes = tryPart(frame, triggerPath)
	if triggerRes.IsErr then
		return triggerRes
	end
	local returnRes = tryPart(frame, returnPath)
	if returnRes.IsErr then
		return returnRes
	end
	local trigger = triggerRes.Value
	-- the copy of a model has its values point at its own parts
	local value = trigger:FindFirstChild(EXIT_NAME)
	local exit = if value and value:IsA("ObjectValue") then value.Value else nil
	if not exit or not exit:IsA("BasePart") then
		return Result.err(`"{triggerPath}" has no exit`)
	end
	local out: Passage = {
		Trigger = trigger,
		Exit = exit,
		Return = returnRes.Value,
		IsToBase = isToBase,
	}
	table.freeze(out)
	return Result.ok(out)
end

local function tryShelfDoor(frame: Model, path: string, sign: number): Result<ShelfDoor, string>
	local instRes = IndexUtil.tryFirstLocalPath(frame, path)
	if instRes.IsErr then
		return instRes
	end
	local model = instRes.Value
	if not model:IsA("Model") then
		return Result.err(`expected a Model at "{path}", received a {model.ClassName}`)
	end
	local primaryPart = model.PrimaryPart
	if not primaryPart then
		return Result.err(`"{path}" has no primary part`)
	end
	local out: ShelfDoor = {
		Model = model,
		Closed = model:GetPivot(),
		Direction = primaryPart.CFrame.ZVector * sign,
	}
	table.freeze(out)
	return Result.ok(out)
end

-- the pads are numbered by a value of their own, the layout tells them apart by it
local function getPads(interior: Model): { [ZoneId]: BasePart }
	local out: { [ZoneId]: BasePart } = {}
	for _, child in interior:GetChildren() do
		if child.Name ~= PAD_NAME or not child:IsA("BasePart") then
			continue
		end
		local id = child:FindFirstChild(PAD_ID_NAME)
		if not id or not id:IsA("IntValue") or not BaseType.ZoneId(id.Value) then
			warn(`a pad of the base has no zone id`)
			continue
		end
		out[id.Value] = child
	end
	table.freeze(out)
	return out
end

-- every part right under the interior takes the surface the palette holds for its name
local function applyTheme(interior: Model, themeId: string)
	local definitionRes = ThemeDefinition.get(themeId)
	if definitionRes.IsErr then
		warn(`theme err: {definitionRes.Value}`)
		return
	end
	local palette = definitionRes.Value.Palette
	for _, child in interior:GetChildren() do
		local surface = palette[child.Name]
		if not surface or not child:IsA("BasePart") then
			continue
		end
		child.Color = surface.Color
		child.Material = surface.Material
		for _, light in child:GetChildren() do
			if light:IsA("SurfaceLight") then
				light.Color = surface.Color
			end
		end
	end
end

-- a suit display is a mannequin + a pedestal a head on a stand, so they're dressed the way an avatar is
local function wear(model: Model, appearance: Appearance)
	for _, item in appearance.Items do
		-- one broken item shouldn't cost the residence the rest of its furniture
		local success, res = pcall(ItemUtil.apply, model, appearance, item)
		if not success then
			warn(`display err: item "{item.DefinitionId}" threw: {res}`)
		elseif res.IsErr then
			warn(`display err: item "{item.DefinitionId}" failed to apply: {res.Value}`)
		end
	end
end

local function setCostume(piece: Piece, costume: Appearance?)
	for _, v in piece.Model:QueryDescendants(`.{ItemUtil.ITEM_TAG}`) do
		v:Destroy()
	end
	piece.Costume = costume
	if costume then
		wear(piece.Model, costume)
	end
end

local function newPiece(self: Residence, placed: PlacedFurniture, costume: Appearance?): Result<Piece, string>
	if not self.IsAlive then
		return Result.err(`the residence is gone`)
	end
	local pad = self.Pads[placed.ZoneId]
	if not pad then
		return Result.err(`piece "{placed.Id}" stands on pad {placed.ZoneId}, the base has none`)
	end
	local modelRes = BaseUtil.newModel(placed.FurnitureId)
	if modelRes.IsErr then
		return modelRes
	end
	local model = modelRes.Value
	-- a piece is kept relative to its pad, the pads don't all lie the same way around
	model:PivotTo(pad.CFrame * placed.CFrame)
	model.Parent = self.Furniture
	local out: Piece = {
		Placed = placed,
		Model = model,
	}
	if costume then
		setCostume(out, costume)
	end
	local artifactId = placed.ArtifactId
	if artifactId then
		wear(
			model,
			FreezeUtil.delta(AppearanceConstructor.new(), function(t: Appearance): Appearance
				table.insert(t.Items, ItemConstructor.new(artifactId))
				return t
			end)
		)
	end
	return Result.ok(out)
end

-- only what differs from the state is touched, a piece that's picked in build mode keeps its model as it moves
local function furnish(self: Residence, state: ResidenceState)
	if not self.IsAlive then
		return
	end
	local layout = state.Layout
	local placedById: { [string]: PlacedFurniture } = {}
	for _, placed in layout.Furniture do
		placedById[placed.Id] = placed
	end
	for id, piece in self._Pieces do
		local placed = placedById[id]
		if not placed or placed.FurnitureId ~= piece.Placed.FurnitureId then
			piece.Model:Destroy()
			self._Pieces[id] = nil
		end
	end
	for _, placed in layout.Furniture do
		local costume = if placed.CharacterId then state.Costumes[placed.CharacterId] else nil
		local piece = self._Pieces[placed.Id]
		if not piece then
			local pieceRes = newPiece(self, placed, costume)
			if pieceRes.IsErr then
				warn(`furniture err: {pieceRes.Value}`)
				continue
			end
			self._Pieces[placed.Id] = pieceRes.Value
			continue
		end
		if piece.Placed.ZoneId ~= placed.ZoneId or piece.Placed.CFrame ~= placed.CFrame then
			local pad = self.Pads[placed.ZoneId]
			if pad then
				piece.Model:PivotTo(pad.CFrame * placed.CFrame)
			else
				warn(`furniture err: piece "{placed.Id}" stands on pad {placed.ZoneId}, the base has none`)
			end
		end
		piece.Placed = placed
		-- a costume that came through a remote is a new table every time, whatever is in it
		if not StateUtil.getIfEqual(piece.Costume, costume) then
			setCostume(piece, costume)
		end
	end
end

local function setShelf(self: Residence, alpha: number)
	if not self.IsAlive then
		return
	end
	for _, door in self._ShelfDoors do
		door.Model:PivotTo(door.Closed + door.Direction * (SHELF_SLIDE_DISTANCE * alpha))
	end
end

-- yields, false when the residence went away meanwhile
local function slideShelf(self: Residence, from: number, to: number): boolean
	local elapsed = 0
	while elapsed < SHELF_SLIDE_DURATION do
		elapsed += RunService.Heartbeat:Wait()
		if not self.IsAlive then
			return false
		end
		setShelf(self, from + (to - from) * math.min(elapsed / SHELF_SLIDE_DURATION, 1))
	end
	return true
end
-- Class
local Residence = {} :: ResidenceImpl
Residence.__index = Residence

function Residence:SetState(state: ResidenceState)
	if not self.IsAlive then
		return
	end
	if self.State.Layout.ThemeId ~= state.Layout.ThemeId then
		applyTheme(self.Interior, state.Layout.ThemeId)
	end
	furnish(self, state)
	self.State = state
	self.StateChanged:Fire(state)
end

function Residence:GetZoneId(pad: Instance): ZoneId?
	if not self.IsAlive then
		return nil
	end
	for zoneId, other in self.Pads do
		if other == pad then
			return zoneId
		end
	end
	return nil
end

function Residence:GetPlaced(placedId: string): PlacedFurniture?
	if not self.IsAlive then
		return nil
	end
	local piece = self._Pieces[placedId]
	return piece and piece.Placed
end

function Residence:GetModel(placedId: string): Model?
	if not self.IsAlive then
		return nil
	end
	local piece = self._Pieces[placedId]
	return piece and piece.Model
end

function Residence:GetPlacedId(inst: Instance): string?
	if not self.IsAlive then
		return nil
	end
	for id, piece in self._Pieces do
		if inst == piece.Model or inst:IsDescendantOf(piece.Model) then
			return id
		end
	end
	return nil
end

function Residence:SetPadsShown(isShown: boolean)
	if not self.IsAlive then
		return
	end
	for _, pad in self.Pads do
		if isShown then
			pad.Color = PAD_COLOR
			pad.Transparency = PAD_SHOWN_TRANSPARENCY
		else
			pad.Transparency = PAD_HIDDEN_TRANSPARENCY
		end
	end
end

function Residence:OpenShelf()
	if not self.IsAlive or self._IsShelfOpen then
		return
	end
	self._IsShelfOpen = true
	task.spawn(function()
		if not slideShelf(self, 0, 1) then
			return
		end
		task.wait(SHELF_OPEN_DURATION)
		if not self.IsAlive or not slideShelf(self, 1, 0) then
			return
		end
		if self.IsAlive then
			self._IsShelfOpen = false
		end
	end)
end

function Residence:Destroy()
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
	self.StateChanged:Destroy()
	self.Instance:Destroy()
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(anchor: CFrame, state: ResidenceState, parent: Instance): Result<Residence, string>
		local inst = Instance.new("Model")
		inst.Name = INSTANCE_NAME
		local frame = FrameTemplate:Clone()
		frame:PivotTo(anchor)
		frame.Parent = inst
		local interior = InteriorTemplate:Clone()
		interior:PivotTo(anchor)
		interior.Parent = inst
		local furniture = Instance.new("Folder")
		furniture.Name = FURNITURE_NAME
		furniture.Parent = inst

		-- a shell that misses one of the parts the avatar gets around by can't be lived in
		local function fail(msg: string): Result<Residence, string>
			inst:Destroy()
			return Result.err(`residence failed: {msg}`)
		end
		local entranceRes = tryPart(frame, ENTRANCE_PATH)
		if entranceRes.IsErr then
			return fail(entranceRes.Value)
		end
		local exitRes = tryPart(frame, EXIT_PATH)
		if exitRes.IsErr then
			return fail(exitRes.Value)
		end
		local shelfTriggerRes = tryPart(frame, SHELF_TRIGGER_PATH)
		if shelfTriggerRes.IsErr then
			return fail(shelfTriggerRes.Value)
		end
		local toBaseRes = tryPassage(frame, APARTMENT_TRIGGER_PATH, BASE_TRIGGER_PATH, true)
		if toBaseRes.IsErr then
			return fail(toBaseRes.Value)
		end
		local toApartmentRes = tryPassage(frame, BASE_TRIGGER_PATH, APARTMENT_TRIGGER_PATH, false)
		if toApartmentRes.IsErr then
			return fail(toApartmentRes.Value)
		end
		local shelfDoors: { ShelfDoor } = {}
		for _, CONFIG in SHELF_DOORS do
			local doorRes = tryShelfDoor(frame, CONFIG.PATH, CONFIG.SIGN)
			if doorRes.IsErr then
				return fail(doorRes.Value)
			end
			table.insert(shelfDoors, doorRes.Value)
		end

		-- the template is stored looking like one of the themes, the one of the layout always goes over it
		applyTheme(interior, state.Layout.ThemeId)
		local self = setmetatable({
			IsAlive = true :: true,
			Instance = inst,
			Frame = frame,
			Interior = interior,
			Furniture = furniture,
			Entrance = entranceRes.Value,
			Exit = exitRes.Value,
			Passages = table.freeze({ toBaseRes.Value, toApartmentRes.Value }),
			ShelfTrigger = shelfTriggerRes.Value,
			Pads = getPads(interior),
			State = state,
			StateChanged = Signal.new(),
			_Pieces = {},
			_ShelfDoors = shelfDoors,
			_IsShelfOpen = false,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, Residence)
		furnish(self, state)
		-- everything is in place by the time the world sees any of it
		inst.Parent = parent
		-- no daylight gets in + the fittings of an interior only reach the spot under them, which leaves the rest of
		-- it black. whoever is inside sees by a light of their own for as long as they are
		if RunService:IsRunning() then
			local ambient = Lighting.Ambient
			Lighting.Ambient = INDOOR_AMBIENT
			table.insert(self._CleanUpCallbacks, function()
				Lighting.Ambient = ambient
			end)
		end
		return Result.ok(self)
	end,
}
