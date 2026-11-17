--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Hooks
local useAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttribute")
-- Types
type Attribute<V> = AttributeDefinition.Attribute<V>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function<V>(inst: Instance?, attribute: Attribute<V>): V
	return AttributeDefinition.fix(attribute, useAttribute(inst, attribute.Name))
end
