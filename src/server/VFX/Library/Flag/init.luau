--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Attribute: AttributeDefinition.Attribute<boolean>,
}
-- Constants
local isFlag = function(value: unknown): (boolean, string?)
	for _, attribute in AttributeDefinition.list("Character") do
		if attribute == value and attribute.Default == false then
			return true
		end
	end
	return false, `an attribute of a character that's off by itself expected`
end
local isProperties = Type.strictInterface({
	Attribute = isFlag,
})
-- Variables
-- how many of the effect hold each attribute of a character up right now
local Counts: { [Model]: { [string]: number } } = {}
-- References
-- Private Functions
-- Class
-- keeps an attribute of the character the effect belongs to on for as long as it's on itself: how the rest of the
-- game gets to know what an ability made of them. two that keep the same one on don't let go of it until both are off
return ServerVFX.newState("Flag", isProperties, function(props: Properties, scope: ServerScope)
	local character = scope.Character
	if not character then
		return function() end
	end
	local attribute = props.Attribute
	local counts: { [string]: number } = Counts[character] or {}
	Counts[character] = counts
	counts[attribute.Name] = (counts[attribute.Name] or 0) + 1
	AttributeDefinition.set(character, attribute, true)
	return function()
		local count = counts[attribute.Name] - 1
		if count > 0 then
			counts[attribute.Name] = count
			return
		end
		counts[attribute.Name] = nil
		if next(counts) == nil and Counts[character] == counts then
			Counts[character] = nil
		end
		AttributeDefinition.set(character, attribute, false)
	end
end)
