--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type Character = CharacterType.Character
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: Character?)
