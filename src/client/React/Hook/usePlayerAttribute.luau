--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
-- Types
type Attribute<V> = AttributeDefinition.Attribute<V>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function<V>(attribute: Attribute<V>): V
	return useAttributeValue(Players.LocalPlayer, attribute)
end
