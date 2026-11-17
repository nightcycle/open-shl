--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type HazardServiceImpl = {
	__index: HazardServiceImpl,
	SetLethal: (self: HazardService, part: BasePart, isLethal: boolean) -> (),
}
export type HazardService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_PartConnections: { [BasePart]: RBXScriptConnection },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: HazardServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- the avatar dies the way the engine has anything die, whatever follows a death + the respawn come with it
local function onTouched(hit: BasePart)
	local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end
-- Class
local HazardService = {} :: HazardServiceImpl
HazardService.__index = HazardService

-- for a part that only kills some of the time, what the map tags is lethal from the start
function HazardService:SetLethal(part: BasePart, isLethal: boolean)
	local connection = self._PartConnections[part]
	if isLethal and not connection then
		self._PartConnections[part] = part.Touched:Connect(onTouched)
	elseif not isLethal and connection then
		connection:Disconnect()
		self._PartConnections[part] = nil
	end
end

return ServiceLocker(function(): HazardService
	local self = setmetatable({
		IsInitialized = true :: true,
		_PartConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, HazardService)

	for _, part in MapDefinition.list(MapDefinition.Hazard) do
		self:SetLethal(part, true)
	end

	table.insert(self._CleanUpCallbacks, function()
		for _, connection in self._PartConnections do
			connection:Disconnect()
		end
	end)

	return self
end, function(self: HazardService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
