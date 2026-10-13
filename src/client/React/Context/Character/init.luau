--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type Character = CharacterType.Character
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(CharacterConstructor.new())
