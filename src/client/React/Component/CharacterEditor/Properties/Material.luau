--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
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
type MaterialInfo = {
	MATERIAL: Enum.Material,
	ICON: string,
}
-- Constants
local GRID_COLUMNS = 5
local BUTTON_SIZE = 1 / GRID_COLUMNS
local MATERIALS: { MaterialInfo } = {
	{ MATERIAL = Enum.Material.Plastic, ICON = Image.material["plastic.png"] },
	{ MATERIAL = Enum.Material.Neon, ICON = Image.material["neon.png"] },
	{ MATERIAL = Enum.Material.WoodPlanks, ICON = Image.material["wood-planks.png"] },
	{ MATERIAL = Enum.Material.Slate, ICON = Image.material["slate.png"] },
	{ MATERIAL = Enum.Material.Granite, ICON = Image.material["granite.png"] },

	{ MATERIAL = Enum.Material.Pebble, ICON = Image.material["pebble.png"] },
	{ MATERIAL = Enum.Material.CorrodedMetal, ICON = Image.material["corroded-metal.png"] },
	{ MATERIAL = Enum.Material.Foil, ICON = Image.material["foil.png"] },
	{ MATERIAL = Enum.Material.Grass, ICON = Image.material["grass.png"] },
	{ MATERIAL = Enum.Material.Fabric, ICON = Image.material["fabric.png"] },

	{ MATERIAL = Enum.Material.SmoothPlastic, ICON = Image.material["smooth-plastic.png"] },
	{ MATERIAL = Enum.Material.Wood, ICON = Image.material["wood.png"] },
	{ MATERIAL = Enum.Material.Marble, ICON = Image.material["marble.png"] },
	{ MATERIAL = Enum.Material.Concrete, ICON = Image.material["concrete.png"] },

	{ MATERIAL = Enum.Material.Brick, ICON = Image.material["brick.png"] },
	{ MATERIAL = Enum.Material.Cobblestone, ICON = Image.material["cobblestone.png"] },
	{ MATERIAL = Enum.Material.DiamondPlate, ICON = Image.material["diamond-plate.png"] },
	{ MATERIAL = Enum.Material.Metal, ICON = Image.material["metal.png"] },
	{ MATERIAL = Enum.Material.Sand, ICON = Image.material["sand.png"] },

	{ MATERIAL = Enum.Material.Ice, ICON = Image.material["ice.png"] },
}
local GRID_ROWS = math.ceil(#MATERIALS / GRID_COLUMNS)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local fieldCallback = React.useContext(CharacterEditorFieldCallback)
	if not fieldDefinition or fieldDefinition.Type ~= "Material" then
		return
	end
	if not fieldCallback then
		return
	end

	local buttons: { [string]: React.ReactNode } = {}
	for index, CONFIG in MATERIALS do
		local column = (index - 1) % GRID_COLUMNS
		local row = math.floor((index - 1) / GRID_COLUMNS)
		buttons[`{CONFIG.MATERIAL.Name}-{index}`] = e("ImageButton", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			Image = CONFIG.ICON,
			Position = UDim2.fromScale(column * BUTTON_SIZE, row / GRID_ROWS),
			Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			[React.Event.Activated] = function()
				fieldCallback(fieldDefinition, CONFIG.MATERIAL)
			end,
		})
	end

	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, GRID_ROWS / GRID_COLUMNS),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			Buttons = e(React.Fragment, {}, buttons),
		}
	))
end
