--!strict
-- Services
-- Packages
-- Modules
-- Types
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
export type ChoiceDefinition = MiscType.ChoiceDefinition
type IconDefinition = MiscType.IconDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

function Module.text(value: any, text: string): ChoiceDefinition
	local out: ChoiceDefinition = {
		Type = "Text",
		Text = text,
		Value = value,
	}
	table.freeze(out)
	return out
end
function Module.icon(value: any, icon: IconDefinition): ChoiceDefinition
	local out: ChoiceDefinition = {
		Type = "Icon",
		Icon = icon,
		Value = value,
	}
	table.freeze(out)
	return out
end
function Module.textIcon(value: any, text: string, icon: IconDefinition): ChoiceDefinition
	local out: ChoiceDefinition = {
		Type = "TextIcon",
		Text = text,
		Icon = icon,
		Value = value,
	}
	table.freeze(out)
	return out
end

return Module
