--!strict
-- Services
-- Packages
-- Modules
local Cheeseburger = require("@game/ReplicatedStorage/Shared/Prop/Library/Cheeseburger")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Heal = require("@game/ServerScriptService/Server/VFX/Library/Heal")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- studs everybody else hears the wrapper + the bites from
local SOUND_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
-- the player's own half shows + plays it to them right away, this is for everybody else. the health is nobody's to
-- claim: it comes at the end of a bite the server timed, a bite that's cut short never gets there
return PropBuilder.newServer(Cheeseburger.Prop)
	:RunClient(PropMoment.Rest, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Cheeseburger.Rest
	end, { Audience = "Others" })
	:RunClient(PropMoment.Using, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Cheeseburger.Bite
	end, { Audience = "Others" })
	:FireClient(PropMoment.Draw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Cheeseburger.DrawSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:FireClient(PropMoment.Use, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Cheeseburger.BiteSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:Fire(PropMoment.Finish, Heal, function(): Heal.Properties
		return { Amount = Cheeseburger.BiteHealth }
	end)
	:Build()
