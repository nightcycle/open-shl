--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local MindReading = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/MindReading")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Handle = VFXType.Handle
-- Constants
-- the world loses its color + its edges for whoever looks in on somebody
local FILTER: ClientVFXType.ScreenFilter = table.freeze({
	Brightness = 0.3,
	Contrast = 0.1,
	Saturation = -1,
	Blur = 7,
})
-- how many clicks there were since the tool came out
local INDEX_KEY = "Index"
-- what holds the camera on whoever the last click got to
local HANDLE_KEY = "Spectate"
-- Variables
-- References
-- Private Functions
-- Class
local layout = MindReading.Layout
local bindings = layout.Bindings
-- all of it happens on the screen of the player: nobody else sees or hears a thing, whoever is looked in on included
local builder = AbilityBuilder.newClient(layout)
	:Run(bindings.Read, ClientVFXDefinition.ScreenFilter, function(): ClientVFXType.ScreenFilter
		return FILTER
	end)
local nextBinding = bindings.Next
if nextBinding then
	-- nobody is watched until the first click, every one after it moves on by one. the camera is held by hand: what
	-- holds it changes with each click while the tool stays out
	builder = builder
		:While(bindings.Read, function(context: ClientContext)
			context.Record[INDEX_KEY] = 0
			return function()
				local handle = context.Record[HANDLE_KEY] :: Handle?
				context.Record[HANDLE_KEY] = nil
				if handle then
					handle.Stop()
				end
			end
		end)
		:On(nextBinding, function(context: ClientContext)
			local index = (context.Record[INDEX_KEY] :: number? or 0) + 1
			context.Record[INDEX_KEY] = index
			local handle = context.Record[HANDLE_KEY] :: Handle?
			if handle then
				handle.Stop()
			end
			context.Record[HANDLE_KEY] =
				context.VFX.start(ClientVFXDefinition.Spectate, { Index = index, IsBare = true })
		end)
else
	-- who is watched is picked with the buttons the effect comes with
	builder = builder:Run(bindings.Read, ClientVFXDefinition.Spectate, function(): ClientVFXType.Spectate
		return {}
	end)
end

return builder:Build()
