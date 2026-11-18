--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type Condition = AbilityType.Condition
-- Constants
local KEY_DELIMITER = "/"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- held down, any one of them is enough: a button of the mouse or a touch as well as a key or a button of a gamepad
Module.input = function(...: Enum.UserInputType | Enum.KeyCode): Condition
	local userInputTypes: { Enum.UserInputType } = {}
	local keyCodes: { Enum.KeyCode } = {}
	local names: { string } = {}
	for _, input in { ... } do
		if input.EnumType == Enum.UserInputType then
			table.insert(userInputTypes, input :: Enum.UserInputType)
		else
			table.insert(keyCodes, input :: Enum.KeyCode)
		end
		table.insert(names, input.Name)
	end
	assert(#names > 0, `an input condition needs something to be held`)
	-- sorted so the same inputs are one condition whatever order they're listed in
	table.sort(names)
	return table.freeze({
		Type = "Input" :: "Input",
		Key = `Input{KEY_DELIMITER}{table.concat(names, "+")}`,
		UserInputTypes = table.freeze(userInputTypes),
		KeyCodes = table.freeze(keyCodes),
	})
end

Module.equipped = function(abilityId: string): Condition
	return table.freeze({
		Type = "Equipped" :: "Equipped",
		Key = `Equipped{KEY_DELIMITER}{abilityId}`,
		AbilityId = abilityId,
	})
end

-- how an ability takes what another one is up to into account
Module.abilityState = function(abilityId: string, stateId: string): Condition
	return table.freeze({
		Type = "AbilityState" :: "AbilityState",
		Key = `AbilityState{KEY_DELIMITER}{abilityId}{KEY_DELIMITER}{stateId}`,
		AbilityId = abilityId,
		StateId = stateId,
	})
end

Module.humanoidState = function(humanoidStateType: Enum.HumanoidStateType): Condition
	return table.freeze({
		Type = "HumanoidState" :: "HumanoidState",
		Key = `HumanoidState{KEY_DELIMITER}{humanoidStateType.Name}`,
		HumanoidStateType = humanoidStateType,
	})
end

Module.custom = function(name: string): Condition
	return table.freeze({
		Type = "Custom" :: "Custom",
		Key = `Custom{KEY_DELIMITER}{name}`,
		Name = name,
	})
end

Module.current = function(): Condition
	return table.freeze({
		Type = "Current" :: "Current",
		Key = "Current",
	})
end

Module.elapsed = function(duration: number): Condition
	return table.freeze({
		Type = "Elapsed" :: "Elapsed",
		Key = `Elapsed{KEY_DELIMITER}{duration}`,
		Duration = duration,
	})
end

-- what a tool is used with on every device
Module.PRIMARY = Module.input(Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonR2)

return Module
