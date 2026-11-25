--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local FaceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Face")
local FadeUtil = require("@self/Fade")
local Image = require("@game/ReplicatedStorage/Generated/Image")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type FaceSlot = FaceUtil.FaceSlot
-- a door that fades out of the way for whoever clicks one of its buttons
type Door = {
	Part: BasePart,
	Steps: { FadeUtil.Step },
	Transparency: number, -- what the map gave it, it's back at it once it's shut again
	Thread: thread?, -- it's on its way open or shut: whoever clicks meanwhile changes nothing
}
-- a screen that flickers through its pictures at a click
type Screen = {
	Part: BasePart,
	Images: { string },
	Face: Enum.NormalId,
	Interval: number,
	Duration: number,
	Decal: Decal?,
	Thread: thread?, -- it's at it: a click meanwhile changes nothing
}
-- a seat that puts one of its pictures on the face of whoever sits on it
type Gag = {
	Seat: Seat,
	Images: { string },
	Sitter: Model?,
	Image: string?, -- what the sitter wears, a dress they get meanwhile is drawn over with it again
}
type SceneryServiceImpl = {
	__index: SceneryServiceImpl,
}
export type SceneryService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Doors: { Door },
		_Screens: { Screen },
		_Gags: { Gag },
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SceneryServiceImpl
))
-- Constants
local DOOR_NAME = "Door"
local DECAL_NAME = "Static"
-- studs past what its detector takes a click from that the server still takes one from: a click is the client's to
-- send, where the avatar stands is the server's own reading + a step behind
local CLICK_SLACK = 5
-- the slot a gag face goes over: the whole face in one picture, which only a game that draws its faces that way has
local FACE_SLOT: FaceSlot = "Face"
-- Variables
-- References
-- Private Functions
-- what a mark says about itself. nil + a word about it where that's said wrong
local function read<V>(inst: Instance, attribute: MapDefinition.Attribute<V>): V?
	local valueRes = MapDefinition.get(inst, attribute)
	if valueRes.IsErr then
		warn(valueRes.Value)
		return nil
	end
	return valueRes.Value
end

-- the pictures a mark names: files under asset/image with commas between them. nil if one of them isn't there
local function getImages(inst: Instance): { string }?
	local keys = read(inst, MapDefinition.ImageKeys)
	if keys == nil then
		return nil
	end
	local images: { string } = {}
	for _, key in string.split(keys, ",") do
		local node: any = Image
		for _, name in string.split(key, "/") do
			node = if type(node) == "table" then node[name] else nil
		end
		if type(node) ~= "string" then
			warn(`{inst:GetFullName()} shows "{key}", which is no picture of the game`)
			return nil
		end
		table.insert(images, node)
	end
	if #images == 0 then
		warn(`{inst:GetFullName()} has no picture to show`)
		return nil
	end
	return images
end

-- whether the server has the avatar of whoever clicked where a click can come from
local function getIfInReach(player: Player, detector: ClickDetector): boolean
	local character = player.Character
	local rootPart = if character then character.PrimaryPart else nil
	local button = detector.Parent
	if not rootPart or not button or not button:IsA("BasePart") then
		return false
	end
	return (rootPart.Position - button.Position).Magnitude <= detector.MaxActivationDistance + CLICK_SLACK
end

local function shut(door: Door)
	door.Thread = nil
	door.Part.Transparency = door.Transparency
	door.Part.CanCollide = true
end

-- yields. it's walked through from the first step on, while it still looks all there
local function cycle(door: Door)
	local part = door.Part
	part.CanCollide = false
	for _, step in door.Steps do
		if step.Delay > 0 then
			task.wait(step.Delay)
		end
		part.Transparency = step.Transparency
	end
	part.CanCollide = true
	door.Thread = nil
end

-- the door has one state, whichever button is clicked: each of its old buttons kept its own + faded over the other
local function onDoorClicked(door: Door, detector: ClickDetector, player: Player)
	if door.Thread or not getIfInReach(player, detector) then
		return
	end
	door.Thread = task.spawn(cycle, door)
end

local function clear(screen: Screen)
	screen.Thread = nil
	if screen.Decal then
		screen.Decal:Destroy()
		screen.Decal = nil
	end
end

-- yields. the pictures take turns for as long as the run lasts, then the screen is what it was
local function flicker(screen: Screen)
	local decal = Instance.new("Decal")
	decal.Name = DECAL_NAME
	decal.Face = screen.Face
	screen.Decal = decal
	for index = 1, math.round(screen.Duration / screen.Interval) do
		decal.Texture = screen.Images[(index - 1) % #screen.Images + 1]
		if index == 1 then
			decal.Parent = screen.Part
		end
		task.wait(screen.Interval)
	end
	clear(screen)
end

local function onScreenClicked(screen: Screen, detector: ClickDetector, player: Player)
	if screen.Thread or not getIfInReach(player, detector) then
		return
	end
	screen.Thread = task.spawn(flicker, screen)
end

local function draw(gag: Gag)
	local sitter, image = gag.Sitter, gag.Image
	if not sitter or not image then
		return
	end
	local faceRes = FaceUtil.override(sitter, FACE_SLOT, image)
	if faceRes.IsErr then
		warn(`gag face err: {faceRes.Value}`)
	end
end

-- the face they're dressed in is drawn back. a body its player left behind keeps what it has
local function restore(character: Model)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local player = Players:GetPlayerFromCharacter(character)
	local appearanceOpt = if player then AvatarService:GetAppearance(player) else nil
	if not appearanceOpt or appearanceOpt.IsNone then
		return
	end
	local faceRes = FaceUtil.apply(character, appearanceOpt.Value)
	if faceRes.IsErr then
		warn(`gag face err: {faceRes.Value}`)
	end
end

-- only the avatar of a player gets a face, whatever else is put on the seat doesn't
local function onOccupantChanged(self: SceneryService, gag: Gag)
	local humanoid = gag.Seat.Occupant
	local character = if humanoid then humanoid.Parent else nil
	local sitter: Model? = nil
	if character and character:IsA("Model") and Players:GetPlayerFromCharacter(character) then
		sitter = character
	end
	local priorSitter = gag.Sitter
	if sitter == priorSitter then
		return
	end
	gag.Sitter = sitter
	gag.Image = if sitter then gag.Images[self._Random:NextInteger(1, #gag.Images)] else nil
	if priorSitter then
		restore(priorSitter)
	end
	draw(gag)
end

local function addDoor(self: SceneryService, model: Model)
	local part = model:FindFirstChild(DOOR_NAME)
	local fadeDuration = read(model, MapDefinition.FadeDuration)
	local openDuration = read(model, MapDefinition.OpenDuration)
	local openTransparency = read(model, MapDefinition.OpenTransparency)
	if not part or not part:IsA("BasePart") then
		warn(`{model:GetFullName()} has no {DOOR_NAME} to open`)
		return
	end
	if fadeDuration == nil or openDuration == nil or openTransparency == nil then
		return
	end
	local door: Door = {
		Part = part,
		Steps = FadeUtil.getSteps(part.Transparency, openTransparency, fadeDuration, openDuration),
		Transparency = part.Transparency,
		Thread = nil,
	}
	table.insert(self._Doors, door)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ClickDetector") then
			table.insert(
				self._Connections,
				descendant.MouseClick:Connect(function(player: Player)
					onDoorClicked(door, descendant, player)
				end)
			)
		end
	end
end

local function addScreen(self: SceneryService, part: BasePart)
	local detector = part:FindFirstChildOfClass("ClickDetector")
	local face = read(part, MapDefinition.ImageFace)
	local interval = read(part, MapDefinition.ImageInterval)
	local duration = read(part, MapDefinition.ImageDuration)
	local images = getImages(part)
	if not detector then
		warn(`{part:GetFullName()} has nothing to click`)
		return
	end
	if face == nil or interval == nil or duration == nil or images == nil then
		return
	end
	local screen: Screen = {
		Part = part,
		Images = images,
		Face = (Enum.NormalId :: any)[face] :: Enum.NormalId,
		Interval = interval,
		Duration = duration,
		Decal = nil,
		Thread = nil,
	}
	table.insert(self._Screens, screen)
	table.insert(
		self._Connections,
		detector.MouseClick:Connect(function(player: Player)
			onScreenClicked(screen, detector, player)
		end)
	)
end

local function addGag(self: SceneryService, seat: Seat)
	local images = getImages(seat)
	if images == nil then
		return
	end
	local gag: Gag = {
		Seat = seat,
		Images = images,
		Sitter = nil,
		Image = nil,
	}
	table.insert(self._Gags, gag)
	table.insert(
		self._Connections,
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			onOccupantChanged(self, gag)
		end)
	)
end
-- Class
local SceneryService = {} :: SceneryServiceImpl
SceneryService.__index = SceneryService

-- the things of a map that are only there to be played with, where what they do is everybody's to see: a door that
-- fades out of the way at a click, a screen that flickers, a seat that pulls a face. the parts that only turn are
-- each client's own
return ServiceLocker(function(): SceneryService
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Doors = {} :: { Door },
		_Screens = {} :: { Screen },
		_Gags = {} :: { Gag },
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SceneryService)

	-- a map is found by its marks alone: one that's marked wrong says so + stays as it is
	for _, model in MapDefinition.list(MapDefinition.ClickDoor) do
		addDoor(self, model)
	end
	for _, part in MapDefinition.list(MapDefinition.ImageCycle) do
		addScreen(self, part)
	end
	local seats = MapDefinition.list(MapDefinition.FaceSwap)
	if #seats > 0 and not table.find(ItemAppearanceDefinition.listFaceSlots(), FACE_SLOT) then
		warn(`the faces of this game aren't one picture, the {#seats} seats that pull one are only sat on`)
		table.clear(seats)
	end
	for _, seat in seats do
		addGag(self, seat)
	end
	-- a dress draws the face that's worn, whoever sits through one has the gag back over it
	local dressedConnection = AvatarService.Dressed:Connect(function(_player: Player, character: Model)
		for _, gag in self._Gags do
			if gag.Sitter == character then
				draw(gag)
			end
		end
	end)

	table.insert(self._CleanUpCallbacks, function()
		dressedConnection:Disconnect()
		for _, door in self._Doors do
			if door.Thread then
				task.cancel(door.Thread)
				shut(door)
			end
		end
		for _, screen in self._Screens do
			if screen.Thread then
				task.cancel(screen.Thread)
				clear(screen)
			end
		end
		for _, gag in self._Gags do
			local sitter = gag.Sitter
			gag.Sitter = nil
			gag.Image = nil
			if sitter and AvatarService.IsInitialized then
				restore(sitter)
			end
		end
	end)

	return self
end, function(self: SceneryService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
