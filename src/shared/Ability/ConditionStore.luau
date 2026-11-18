--!strict
-- Services
-- Packages
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type Signal<T...> = Signal.Signal<T...>
type Aim = AbilityType.Aim
type Stimulus = AbilityType.Stimulus
type ConditionStoreImpl = {
	__index: ConditionStoreImpl,
	Get: (self: ConditionStore, key: string) -> boolean,
	Set: (self: ConditionStore, key: string, isActive: boolean, aim: Aim?, payload: unknown) -> (),
	Pulse: (self: ConditionStore, key: string, aim: Aim?, payload: unknown) -> (),
	Destroy: (self: ConditionStore) -> (),
}
-- every boolean the abilities of one player hang on, on one side of the network
export type ConditionStore = typeof(setmetatable(
	{} :: {
		IsAlive: boolean,
		Changed: Signal<Stimulus>,
		_Values: { [string]: boolean? },
	},
	{} :: ConditionStoreImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local ConditionStore = {} :: ConditionStoreImpl
ConditionStore.__index = ConditionStore

function ConditionStore:Get(key: string): boolean
	return self.IsAlive and self._Values[key] == true
end

function ConditionStore:Set(key: string, isActive: boolean, aim: Aim?, payload: unknown)
	if not self.IsAlive or self:Get(key) == isActive then
		return
	end
	self._Values[key] = isActive or nil
	self.Changed:Fire(table.freeze({
		Key = key,
		IsActive = isActive,
		Aim = aim,
		Payload = payload,
	}))
end

-- true for an instant: how something that happens rather than lasts is told
function ConditionStore:Pulse(key: string, aim: Aim?, payload: unknown)
	self:Set(key, true, aim, payload)
	self:Set(key, false, aim, payload)
end

function ConditionStore:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false
	self.Changed:Destroy()
	table.clear(self._Values)
end

return {
	new = function(): ConditionStore
		return setmetatable({
			IsAlive = true,
			Changed = Signal.new(),
			_Values = {},
		}, ConditionStore)
	end,
}
