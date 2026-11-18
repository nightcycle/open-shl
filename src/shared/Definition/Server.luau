--!strict
-- Services
-- Packages
-- Modules
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
export type Mode = ServerType.Mode
export type Listing = ServerType.Listing
export type Settings = ServerType.Settings
export type Entry = ServerType.Entry
-- Constants
local DEFAULT_LIMIT = 12
local MAX_LIMIT = 50
local DEFAULT_NAME = "Unnamed Server"
-- a name ends up in the list of every player, a code is typed in by hand
local MAX_TEXT_LENGTH = 150
-- how much of the id of a server players read out to each other
local ID_LENGTH = 6
local REGIONAL_INDICATOR_A = 0x1F1E6
-- Variables
-- References
-- Private Functions
local function cut(text: string): string
	local length = utf8.len(text)
	if length == nil or length <= MAX_TEXT_LENGTH then
		return text
	end
	return string.sub(text, 1, (utf8.offset(text, MAX_TEXT_LENGTH + 1) :: number) - 1)
end
-- Class
local Module = {}

Module.DEFAULT_LIMIT = DEFAULT_LIMIT
Module.MAX_LIMIT = MAX_LIMIT
Module.DEFAULT_NAME = DEFAULT_NAME
Module.MAX_TEXT_LENGTH = MAX_TEXT_LENGTH
Module.ID_LENGTH = ID_LENGTH

-- anything that isn't a head count a server can hold falls back to the default
Module.fixLimit = function(limit: number?): number
	if limit == nil or limit ~= limit then
		return DEFAULT_LIMIT
	end
	local count = math.round(limit)
	if count > MAX_LIMIT then
		return DEFAULT_LIMIT
	end
	return math.max(count, 1)
end

Module.fixSettings = function(settings: Settings): Settings
	local name = cut(settings.Name)
	return table.freeze({
		Name = if string.match(name, "%S") then name else DEFAULT_NAME,
		Limit = Module.fixLimit(settings.Limit),
		Code = cut(settings.Code),
		IsPVP = settings.IsPVP,
	})
end

-- "" outside of a live server, there's no job to name
Module.getId = function(jobId: string): string
	return string.lower(string.sub(jobId, 1, ID_LENGTH))
end

-- "en-us" is spoken in "us", a locale without a country has no region
Module.getRegion = function(localeId: string): string
	local region = string.match(string.lower(localeId), "^%a+%-(%a%a)$")
	return region or ""
end

-- the flag of a region, written as its two letters in regional indicators
Module.getFlag = function(region: string): string
	if not string.match(region, "^%l%l$") then
		return ""
	end
	local first, second = string.byte(region, 1, 2)
	local a = string.byte("a")
	return utf8.char(REGIONAL_INDICATOR_A + first - a, REGIONAL_INDICATOR_A + second - a)
end

return Module
