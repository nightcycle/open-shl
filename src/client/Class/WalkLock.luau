--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Types
type WalkLockImpl = {
	__index: WalkLockImpl,
	Destroy: (self: WalkLock) -> (),
}
export type WalkLock = typeof(setmetatable(
	{} :: {
		IsAlive: true,
		Humanoid: Humanoid,
		_WalkSpeed: number, -- what the humanoid goes back to
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: WalkLockImpl
)) | {
	IsAlive: false | nil,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local WalkLock = {} :: WalkLockImpl
WalkLock.__index = WalkLock

function WalkLock:Destroy()
	if not self.IsAlive then
		return
	end
	self.IsAlive = false :: any
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	local humanoid = self.Humanoid
	-- a speed something else just wrote stands, an avatar that went down meanwhile stays put
	if humanoid.WalkSpeed == 0 and not AttributeDefinition.get(humanoid.Parent, AttributeDefinition.IsDead) then
		humanoid.WalkSpeed = self._WalkSpeed
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end

return {
	new = function(humanoid: Humanoid): WalkLock
		local self = setmetatable({
			IsAlive = true :: true,
			Humanoid = humanoid,
			_WalkSpeed = humanoid.WalkSpeed,
			_CleanUpCallbacks = {},
			_Connections = {},
		}, WalkLock)
		humanoid.WalkSpeed = 0
		-- whatever else writes the speed meanwhile gets its way once the lock is off
		table.insert(
			self._Connections,
			humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if humanoid.WalkSpeed ~= 0 then
					self._WalkSpeed = humanoid.WalkSpeed
					humanoid.WalkSpeed = 0
				end
			end)
		)
		return self
	end,
}
