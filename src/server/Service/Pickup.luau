--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local PropService = require("@game/ServerScriptService/Server/Service/Prop")
-- Types
-- a part of the map that hands out one prop
type Pad = {
	Part: BasePart,
	PropId: string,
	RestockDuration: number?,
	Transparency: number, -- what the map gave it, it's back at it once it's in stock again
	IsStocked: boolean,
	AttemptTime: number, -- when it last tried to hand its prop to somebody, on the clock of os.clock
	RestockThread: thread?,
	Connection: RBXScriptConnection,
}
type PickupServiceImpl = {
	__index: PickupServiceImpl,
}
export type PickupService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Pads: { [BasePart]: Pad },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PickupServiceImpl
))
-- Constants
-- seconds a pad takes between two tries to hand its prop out, whoever they're for
local ATTEMPT_INTERVAL = 1
-- studs past its own corners a pad still takes an avatar to be on it. a touch is whatever the client of an avatar
-- says it is, where the avatar stands is at least the server's own reading
local TOUCH_REACH = 10
-- Variables
-- References
-- Private Functions
-- whose avatar the part belongs to: a hat or something held touches for whoever wears it
local function getToucher(hit: BasePart): (Player?, Model?)
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player, model
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil, nil
end

-- back in stock: it shows again the way the map made it
local function restock(pad: Pad)
	pad.RestockThread = nil
	pad.IsStocked = true
	pad.Part.Transparency = pad.Transparency
end

local function onTouched(pad: Pad, hit: BasePart)
	assert(PropService.IsInitialized, `the prop service isn't initialized`)
	-- whatever else runs into it doesn't cost it its second
	local player, character = getToucher(hit)
	if not player or not character then
		return
	end
	if
		AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
	then
		return
	end
	local part = pad.Part
	local rootPart = character.PrimaryPart
	if not rootPart or (rootPart.Position - part.Position).Magnitude > part.Size.Magnitude / 2 + TOUCH_REACH then
		return
	end
	-- somebody who carries one already has nothing to take, so their touch doesn't cost the pad its second either: a
	-- touch is the client's to send, + whoever kept sending theirs would keep everybody else from the pad
	if PropService:GetIfCarried(player, pad.PropId) then
		return
	end
	local now = os.clock()
	if now - pad.AttemptTime < ATTEMPT_INTERVAL then
		return
	end
	pad.AttemptTime = now
	if not pad.IsStocked then
		return
	end
	-- only one that's really handed over empties it
	local restockDuration = pad.RestockDuration
	if PropService:Grant(player, pad.PropId) and restockDuration then
		pad.IsStocked = false
		-- it's gone to look at, it stays in the way
		part.Transparency = 1
		pad.RestockThread = task.delay(restockDuration, restock, pad)
	end
end
-- Class
local PickupService = {} :: PickupServiceImpl
PickupService.__index = PickupService

-- the pads of the map: whoever steps on one is handed the prop it's named after, one of each for as long as their
-- avatar lives. nothing tells them but the new slot of the hotbar
return ServiceLocker(function(): PickupService
	assert(PropService.IsInitialized, `the prop service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Pads = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, PickupService)

	for _, part in MapDefinition.list(MapDefinition.PropPad) do
		local nameRes = MapDefinition.get(part, MapDefinition.PropId)
		local restockRes = MapDefinition.get(part, MapDefinition.RestockDuration)
		-- a pad that's spelt wrong mustn't pass for one that was taken out on purpose
		if nameRes.IsErr then
			error(nameRes.Value)
		elseif restockRes.IsErr then
			error(restockRes.Value)
		end
		local name = nameRes.Value
		local definition = PropDefinition.find(name)
		if definition then
			local pad: Pad
			pad = {
				Part = part,
				PropId = definition.Id,
				RestockDuration = restockRes.Value,
				Transparency = part.Transparency,
				IsStocked = true,
				AttemptTime = -math.huge,
				RestockThread = nil,
				Connection = part.Touched:Connect(function(hit: BasePart)
					onTouched(pad, hit)
				end),
			}
			self._Pads[part] = pad
		elseif PropDefinition.getIfRetired(name) then
			-- what it handed out didn't come back, the map still has it lying there
			part:Destroy()
		elseif not PropDefinition.getIfUpcoming(name) then
			error(`{part:GetFullName()} hands out "{name}", which isn't a prop of the game`)
		end
		-- one whose prop isn't built yet lies where it is + hands out nothing
	end

	table.insert(self._CleanUpCallbacks, function()
		for _, pad in self._Pads do
			pad.Connection:Disconnect()
			if pad.RestockThread then
				task.cancel(pad.RestockThread)
				restock(pad)
			end
		end
	end)

	return self
end, function(self: PickupService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
