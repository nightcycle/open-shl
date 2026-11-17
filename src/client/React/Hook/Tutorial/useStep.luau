--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Contexts
local TutorialContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial")
-- Types
export type StepDefinition = TutorialDefinition.StepDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): StepDefinition?
	local progress = React.useContext(TutorialContext)
	return React.useMemo(function(): StepDefinition?
		if not progress then
			return nil
		end
		return TutorialDefinition.get(progress.SectionId).Steps[progress.StepIndex]
	end, { progress })
end
