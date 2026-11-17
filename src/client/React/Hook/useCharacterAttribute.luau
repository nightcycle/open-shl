--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
-- Types
type Attribute<V> = AttributeDefinition.Attribute<V>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function<V>(attribute: Attribute<V>): V
	return useAttributeValue(useLocalCharacter(), attribute)
end
