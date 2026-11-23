--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- deeper than anything a save or a session holds, a table that loops back into itself ends here
local MAX_DEPTH = 24
local CHANNEL_MAX = 255
-- Variables
-- References
-- Private Functions
local function getIfArray(t: { [any]: any }): boolean
	local count = 0
	for _ in t do
		count += 1
	end
	return count == #t
end

local function fromVector3(value: Vector3): { [string]: number }
	return {
		X = value.X,
		Y = value.Y,
		Z = value.Z,
	}
end

local function from(value: unknown, depth: number): any
	local kind = typeof(value)
	if kind == "nil" or kind == "boolean" or kind == "string" then
		return value
	elseif kind == "number" then
		-- neither has a spelling in json, which is what an answer is read as more often than not
		local number = value :: number
		return if number ~= number or math.abs(number) == math.huge then tostring(number) else number
	elseif kind == "table" then
		if depth >= MAX_DEPTH then
			return "..."
		end
		local t = value :: { [any]: any }
		local out: { [any]: any } = {}
		if getIfArray(t) then
			for index, item in t do
				out[index] = from(item, depth + 1)
			end
		else
			-- a table that's keyed by anything but strings doesn't cross a bindable
			for key, item in t do
				out[tostring(from(key, depth + 1))] = from(item, depth + 1)
			end
		end
		return out
	elseif kind == "Instance" then
		return (value :: Instance):GetFullName()
	elseif kind == "EnumItem" then
		return (value :: EnumItem).Name
	elseif kind == "Color3" then
		local color = value :: Color3
		return string.format(
			"#%02x%02x%02x",
			math.round(color.R * CHANNEL_MAX),
			math.round(color.G * CHANNEL_MAX),
			math.round(color.B * CHANNEL_MAX)
		)
	elseif kind == "Vector3" then
		return fromVector3(value :: Vector3)
	elseif kind == "CFrame" then
		local cframe = value :: CFrame
		return {
			Position = fromVector3(cframe.Position),
			LookVector = fromVector3(cframe.LookVector),
		}
	end
	return tostring(value)
end
-- Class
local Util = {}

-- whatever a service holds as something that crosses a bindable + can be written down: numbers, strings, booleans +
-- tables of them, either a list or keyed by strings. an instance is its path, a colour its hex, anything else its name
function Util.from(value: unknown): any
	return from(value, 0)
end

return Util
