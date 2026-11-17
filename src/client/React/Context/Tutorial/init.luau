--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local TutorialType = require("@game/ReplicatedStorage/Shared/Type/Tutorial")
export type SectionId = TutorialType.SectionId
export type Progress = {
	SectionId: SectionId,
	StepIndex: number,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- nil while no section plays
return React.createContext(nil :: Progress?)
