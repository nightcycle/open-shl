--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Hooks
-- Contexts
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
-- Types
local FieldTypes = require("./Types")
export type Properties = FieldTypes.FieldProperties
-- Constants
local GRID_COLUMNS = 8
local BUTTON_SIZE = 1 / GRID_COLUMNS
local GRID_STEP = 0.895 / (GRID_COLUMNS - 1)
local COLORS: { BrickColor } = table.freeze({
	BrickColor.new("Institutional white"),
	BrickColor.new("Really red"),
	BrickColor.new(1017), -- Deep orange
	BrickColor.new("New Yeller"),
	BrickColor.new("Lime green"),
	BrickColor.new("Lapis"),
	BrickColor.new("Hot pink"),
	BrickColor.new("Wheat"),

	BrickColor.new("Lily white"),
	BrickColor.new("Bright red"),
	BrickColor.new("Br. yellowish orange"),
	BrickColor.new("Pastel yellow"),
	BrickColor.new("Pastel green"),
	BrickColor.new("Fog"),
	BrickColor.new("Seashell"),
	BrickColor.new("Pastel brown"),

	BrickColor.new("Ghost grey"),
	BrickColor.new("Dusty Rose"),
	BrickColor.new("Bright orange"),
	BrickColor.new("Cool yellow"),
	BrickColor.new("Mint"),
	BrickColor.new("Pastel Blue"),
	BrickColor.new("Light reddish violet"),
	BrickColor.new("Light orange"),

	BrickColor.new("Medium stone grey"),
	BrickColor.new("Tawny"),
	BrickColor.new("Neon orange"),
	BrickColor.new("Daisy orange"),
	BrickColor.new("Moss"),
	BrickColor.new("Cyan"),
	BrickColor.new("Carnation pink"),
	BrickColor.new("Nougat"),

	BrickColor.new("Smoky grey"),
	BrickColor.new("Crimson"),
	BrickColor.new("CGA brown"),
	BrickColor.new("Bright yellow"),
	BrickColor.new("Bright green"),
	BrickColor.new("Electric blue"),
	BrickColor.new("Pink"),
	BrickColor.new("Dusty Rose"),

	BrickColor.new("Dark stone grey"),
	BrickColor.new("Maroon"),
	BrickColor.new("Reddish brown"),
	BrickColor.new("Cashmere"),
	BrickColor.new("Dark green"),
	BrickColor.new("Bright blue"),
	BrickColor.new(321), -- Lilac
	BrickColor.new(345), -- Rust

	BrickColor.new("Black"),
	BrickColor.new("Cocoa"),
	BrickColor.new("Pine Cone"),
	BrickColor.new("Cork"),
	BrickColor.new("Parsley green"),
	BrickColor.new("Storm blue"),
	BrickColor.new("Plum"),
	BrickColor.new("Burnt Sienna"),

	BrickColor.new("Really black"),
	BrickColor.new("Burnt Sienna"),
	BrickColor.new("Dirt brown"),
	BrickColor.new("Fawn brown"),
	BrickColor.new("Earth green"),
	BrickColor.new("Navy blue"),
	BrickColor.new("Mulberry"),
	BrickColor.new("Dirt brown"),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	if not fieldDefinition or fieldDefinition.Type ~= "Color" then
		return
	end
	if not fieldCallback then
		return
	end

	local buttons: { [string]: React.ReactNode } = {}
	for index, color in COLORS do
		local column = (index - 1) % GRID_COLUMNS
		local row = math.floor((index - 1) / GRID_COLUMNS)
		buttons[tostring(index)] = e("TextButton", {
			BackgroundColor3 = color.Color,
			BorderColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.fromScale(column * GRID_STEP, row * GRID_STEP),
			Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
			Text = "",
			TextSize = 14,
			[React.Event.Activated] = function()
				fieldCallback(fieldDefinition, color.Color)
			end,
		})
	end

	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{

			Buttons = e(React.Fragment, {}, buttons),
		}
	))
end
