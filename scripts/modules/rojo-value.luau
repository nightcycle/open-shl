--!strict
local serde = require("@lune/serde")

local rojo = require("./rojo")

type Vector2Value = { X: number, Y: number }
type Vector3Value = { X: number, Y: number, Z: number }
type ColorValue = { R: number, G: number, B: number }
type UDimValue = { Scale: number, Offset: number }
type CFrameValue = {
	GetComponents: (
		self: CFrameValue
	) -> (number, number, number, number, number, number, number, number, number, number, number, number),
}
type EnumValue = { Name: string, Value: number, EnumType: unknown }

local function base64(value: string): string
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result: { string } = {}
	for index = 1, #value, 3 do
		local a, b, c = string.byte(value, index, index + 2)
		local bits = a * 65536 + (b or 0) * 256 + (c or 0)
		for shift = 18, 0, -6 do
			local digit = bit32.band(bit32.rshift(bits, shift), 63) + 1
			table.insert(result, alphabet:sub(digit, digit))
		end
		if not c then
			result[#result] = "="
		end
		if not b then
			result[#result - 1] = "="
		end
	end
	return table.concat(result)
end

local function vector2(value: Vector2Value): { number }
	return { value.X, value.Y }
end

local function vector3(value: Vector3Value): { number }
	return { value.X, value.Y, value.Z }
end

local function color(value: ColorValue): { number }
	return { value.R, value.G, value.B }
end

local function udim(value: UDimValue): { number }
	return { value.Scale, value.Offset }
end

local function cframe(value: CFrameValue): rojo.StrictPropertyValue
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
	return {
		position = { x, y, z },
		orientation = { { r00, r01, r02 }, { r10, r11, r12 }, { r20, r21, r22 } },
	}
end

local function toValue(value: unknown, datatype: string?): rojo.StrictPropertyValue
	local kind = typeof(value)
	if kind == "boolean" then
		return { Bool = value :: boolean }
	elseif kind == "number" then
		local numberValue = value :: number
		assert(
			numberValue == numberValue and math.abs(numberValue) < math.huge,
			"JSON cannot represent NaN or infinity"
		)
		return { [datatype or "Float64"] = numberValue }
	elseif kind == "string" then
		local stringValue = value :: string
		if datatype == "BinaryString" or datatype == "SharedString" then
			return { [datatype] = base64(stringValue) }
		end
		return { [datatype or "String"] = stringValue }
	elseif kind == "Vector2" or kind == "Vector2int16" then
		return { [kind] = vector2(value :: Vector2Value) }
	elseif kind == "Vector3" or kind == "Vector3int16" then
		return { [kind] = vector3(value :: Vector3Value) }
	elseif kind == "Color3" then
		local components = color(value :: ColorValue)
		if datatype == "Color3uint8" then
			for index, component in components do
				components[index] = math.round(component * 255)
			end
		end
		return { [datatype or "Color3"] = components }
	elseif kind == "BrickColor" then
		return { BrickColor = (value :: { Number: number }).Number }
	elseif kind == "CFrame" then
		return { [datatype or "CFrame"] = cframe(value :: CFrameValue) }
	elseif kind == "UDim" then
		return { UDim = udim(value :: UDimValue) }
	elseif kind == "UDim2" then
		local dimensions = value :: { X: UDimValue, Y: UDimValue }
		return { UDim2 = { udim(dimensions.X), udim(dimensions.Y) } }
	elseif kind == "NumberRange" then
		local range = value :: { Min: number, Max: number }
		return { NumberRange = { range.Min, range.Max } }
	elseif kind == "Rect" then
		local rect = value :: { Min: Vector2Value, Max: Vector2Value }
		return { Rect = { vector2(rect.Min), vector2(rect.Max) } }
	elseif kind == "Region3int16" then
		local region = value :: { Min: Vector3Value, Max: Vector3Value }
		return { Region3int16 = { vector3(region.Min), vector3(region.Max) } }
	elseif kind == "Region3" then
		local region = value :: { CFrame: { Position: Vector3Value }, Size: Vector3Value }
		local center = region.CFrame.Position
		local size = region.Size
		return {
			Region3 = {
				{ center.X - size.X / 2, center.Y - size.Y / 2, center.Z - size.Z / 2 },
				{ center.X + size.X / 2, center.Y + size.Y / 2, center.Z + size.Z / 2 },
			},
		}
	elseif kind == "Ray" then
		local ray = value :: { Origin: Vector3Value, Direction: Vector3Value }
		return { Ray = { origin = vector3(ray.Origin), direction = vector3(ray.Direction) } }
	elseif kind == "NumberSequence" then
		local sequence = value :: { Keypoints: { { Time: number, Value: number, Envelope: number } } }
		local keypoints: { rojo.JSONValue } = {}
		for _, keypoint in sequence.Keypoints do
			table.insert(keypoints, { time = keypoint.Time, value = keypoint.Value, envelope = keypoint.Envelope })
		end
		return { NumberSequence = { keypoints = keypoints } }
	elseif kind == "ColorSequence" then
		local sequence = value :: { Keypoints: { { Time: number, Value: ColorValue } } }
		local keypoints: { rojo.JSONValue } = {}
		for _, keypoint in sequence.Keypoints do
			table.insert(keypoints, { time = keypoint.Time, color = color(keypoint.Value) })
		end
		return { ColorSequence = { keypoints = keypoints } }
	elseif kind == "Font" then
		local font = value :: { Family: string, Weight: EnumValue, Style: EnumValue }
		return { Font = { family = font.Family, weight = font.Weight.Name, style = font.Style.Name } }
	elseif kind == "EnumItem" then
		local item = value :: EnumValue
		if datatype then
			return { Enum = item.Value }
		end
		return { EnumItem = { type = tostring(item.EnumType):gsub("^Enum%.", ""), value = item.Value } }
	elseif kind == "PhysicalProperties" then
		local physics = value :: {
			Density: number,
			Friction: number,
			Elasticity: number,
			FrictionWeight: number,
			ElasticityWeight: number,
			AcousticAbsorption: number,
		}
		return {
			PhysicalProperties = {
				density = physics.Density,
				friction = physics.Friction,
				elasticity = physics.Elasticity,
				frictionWeight = physics.FrictionWeight,
				elasticityWeight = physics.ElasticityWeight,
				acousticAbsorption = physics.AcousticAbsorption,
			},
		}
	elseif kind == "Axes" or kind == "Faces" then
		local flags = value :: { [string]: boolean }
		local names: { string } = if kind == "Axes"
			then { "X", "Y", "Z" }
			else { "Right", "Top", "Back", "Left", "Bottom", "Front" }
		local enabled: { string } = {}
		for _, name in names do
			if flags[name] then
				table.insert(enabled, name)
			end
		end
		return { [kind] = enabled }
	elseif kind == "Content" then
		local content = value :: { SourceType: EnumValue, Uri: string? }
		if content.SourceType.Name == "None" then
			return { Content = "None" }
		end
		assert(content.SourceType.Name == "Uri", "Object-backed Content cannot be represented as a JSON asset URI")
		return { Content = { Uri = assert(content.Uri) } }
	elseif kind == "UniqueId" then
		return { UniqueId = tostring(value) }
	end
	error(`Unsupported Roblox value type {kind} ({datatype or "attribute"})`)
end

local function validateNumbers(value: rojo.JSONValue)
	if type(value) == "number" then
		assert(value == value and math.abs(value) < math.huge, "JSON cannot represent NaN or infinity")
	elseif type(value) == "table" then
		for _, child in value :: { [string | number]: rojo.JSONValue } do
			validateNumbers(child)
		end
	end
end

return {
	encode = function(value: rojo.JSONValue): string
		validateNumbers(value)
		-- Lune encodes empty tables as objects. These two value types require arrays.
		local json = serde.encode("json", value, true)
		json = json:gsub('("Axes"%s*:%s*){}', "%1[]")
		json = json:gsub('("Faces"%s*:%s*){}', "%1[]")
		-- These tagged integers may have come directly from serialized XML.
		-- Passing them through a Luau number would lose bits above 2^53.
		json = json:gsub('("Int64"%s*:%s*)"(%-?%d+)"', "%1%2")
		json = json:gsub('("SecurityCapabilities"%s*:%s*)"(%d+)"', "%1%2")
		return json
	end,
	toValue = toValue,
}
