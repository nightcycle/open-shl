--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type ColorizerServiceImpl = {
	__index: ColorizerServiceImpl,
}
export type ColorizerService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ColorizerServiceImpl
))
-- Constants
-- the model inside of a colorized one whose parts are the colors to pick from
local PALETTE_NAME = "ColorScale"
-- Variables
-- References
-- Private Functions
local function colorize(model: Model, rng: Random)
	local palette = model:FindFirstChild(PALETTE_NAME)
	local colors: { BrickColor } = {}
	if palette then
		for _, swatch in palette:GetChildren() do
			if swatch:IsA("BasePart") then
				table.insert(colors, swatch.BrickColor)
			end
		end
	end
	if #colors == 0 then
		warn(`{model:GetFullName()} has no colors to pick from`)
		return
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.BrickColor = colors[rng:NextInteger(1, #colors)]
		end
	end
end
-- Class
local ColorizerService = {} :: ColorizerServiceImpl
ColorizerService.__index = ColorizerService

return ServiceLocker(function(): ColorizerService
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ColorizerService)

	-- done once, a server keeps the colors it started with
	local rng = Random.new()
	for _, model in MapDefinition.list(MapDefinition.Colorizer) do
		colorize(model, rng)
	end

	return self
end, function(self: ColorizerService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
