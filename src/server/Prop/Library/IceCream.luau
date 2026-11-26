--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ConsumableFactory = require("@game/ServerScriptService/Server/Prop/Factory/Consumable")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local IceCream = require("@game/ReplicatedStorage/Shared/Prop/Library/IceCream")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerContext = PropType.ServerContext
type Replication = VFXType.Replication
-- Constants
-- studs everybody else hears a lick from: as far as an ability is heard
local HEARD: Replication = table.freeze({ Audience = "Others" :: "Others", Range = 150 })
-- the line is for whoever licked + nobody else
local OWNER: Replication = table.freeze({ Audience = "Owner" :: "Owner" })
-- what the avatar keeps for as long as it carries the cone: when its last lick was over, on the clock of os.clock
local LICKED_AT = "LickedAt"
-- Variables
-- References
-- Private Functions
local function getSound(): ClientVFXType.Sound
	return IceCream.Consumable.UseSound
end

-- a lick is over. the one before it is the server's to remember: putting the cone away between two licks doesn't
-- make the second one any later. the old gear had the client of the holder take the health off itself
local function onLicked(context: ServerContext)
	local now = os.clock()
	local lickedAt = context.Record[LICKED_AT]
	context.Record[LICKED_AT] = now
	if type(lickedAt) ~= "number" or now - lickedAt >= IceCream.LickGap then
		return
	end
	-- taken as it is, whatever the mode: it's the holder's own doing
	if context.VFX.fire(Damage, { Target = context.Character, Amount = IceCream.LickCost }) then
		context.VFX.fireClient(ClientVFXDefinition.Notice, IceCream.Notice, OWNER)
	end
end
-- Class
-- the lick is heard as it's over, not as it starts: one that's cut short is never heard + never counted
return ConsumableFactory.new(IceCream.Consumable)
	:Clear(PropMoment.Use)
	:FireClient(PropMoment.Finish, ClientVFXDefinition.Sound, getSound, HEARD)
	:On(PropMoment.Finish, onLicked)
	:Build()
