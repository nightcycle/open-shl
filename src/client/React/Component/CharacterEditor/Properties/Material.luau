--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
local useFieldValue =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFieldValue")
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
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/CONSTANTS")
local GRID_COLUMNS = 5
local BUTTON_SIZE = 1 / GRID_COLUMNS
local MATERIALS: { MaterialInfo } = {
	{ MATERIAL = Enum.Material.Plastic, ICON = Image["shl-2"].material["plastic.png"] },
	{ MATERIAL = Enum.Material.Neon, ICON = Image["shl-2"].material["neon.png"] },
	{ MATERIAL = Enum.Material.WoodPlanks, ICON = Image["shl-2"].material["wood-planks.png"] },
	{ MATERIAL = Enum.Material.Slate, ICON = Image["shl-2"].material["slate.png"] },
	{ MATERIAL = Enum.Material.Granite, ICON = Image["shl-2"].material["granite.png"] },

	{ MATERIAL = Enum.Material.Pebble, ICON = Image["shl-2"].material["pebble.png"] },
	{ MATERIAL = Enum.Material.CorrodedMetal, ICON = Image["shl-2"].material["corroded-metal.png"] },
	{ MATERIAL = Enum.Material.Foil, ICON = Image["shl-2"].material["foil.png"] },
	{ MATERIAL = Enum.Material.Grass, ICON = Image["shl-2"].material["grass.png"] },
	{ MATERIAL = Enum.Material.Fabric, ICON = Image["shl-2"].material["fabric.png"] },

	{ MATERIAL = Enum.Material.SmoothPlastic, ICON = Image["shl-2"].material["smooth-plastic.png"] },
	{ MATERIAL = Enum.Material.Wood, ICON = Image["shl-2"].material["wood.png"] },
	{ MATERIAL = Enum.Material.Marble, ICON = Image["shl-2"].material["marble.png"] },
	{ MATERIAL = Enum.Material.Concrete, ICON = Image["shl-2"].material["concrete.png"] },

	{ MATERIAL = Enum.Material.Brick, ICON = Image["shl-2"].material["brick.png"] },
	{ MATERIAL = Enum.Material.Cobblestone, ICON = Image["shl-2"].material["cobblestone.png"] },
	{ MATERIAL = Enum.Material.DiamondPlate, ICON = Image["shl-2"].material["diamond-plate.png"] },
	{ MATERIAL = Enum.Material.Metal, ICON = Image["shl-2"].material["metal.png"] },
	{ MATERIAL = Enum.Material.Sand, ICON = Image["shl-2"].material["sand.png"] },

	{ MATERIAL = Enum.Material.Ice, ICON = Image["shl-2"].material["ice.png"] },
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
	local value = useFieldValue()
	if not fieldDefinition or fieldDefinition.Type ~= "Material" then
		return
	end
	if not fieldCallback or not value or value.Type ~= "Material" then
		return
	end

	local buttons: { [string]: React.ReactNode } = {}
	for index, CONFIG in MATERIALS do
		if fieldDefinition.Filtered and table.find(fieldDefinition.Filtered, CONFIG.MATERIAL) then
			continue
		end
		local column = (index - 1) % GRID_COLUMNS
		local row = math.floor((index - 1) / GRID_COLUMNS)
		local isSelected = CONFIG.MATERIAL == value.Material
		buttons[`{CONFIG.MATERIAL.Name}-{index}`] = e("ImageButton", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.5,
			BorderColor3 = isSelected and CONSTANTS.SELECTION_COLOR or Color3.fromRGB(27, 42, 53),
			BorderSizePixel = isSelected and 3 or 0,
			Image = CONFIG.ICON,
			Position = UDim2.fromScale(column * BUTTON_SIZE, row / GRID_ROWS),
			Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = isSelected and 2 or 1,
			[React.Event.Activated] = function()
				fieldCallback(fieldDefinition, {
					Type = "Material",
					Material = CONFIG.MATERIAL,
				})
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, GRID_ROWS / GRID_COLUMNS),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Buttons = e(React.Fragment, {}, buttons),
		}
	))
end
