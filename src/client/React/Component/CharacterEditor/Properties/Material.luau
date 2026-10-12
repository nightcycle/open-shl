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
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.9, 0.72),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			Plastic = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606124009",
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Neon = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606120991",
				Position = UDim2.fromScale(0.2, 0),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			WoodPlanks = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606130167",
				Position = UDim2.fromScale(0.4, 0),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Granite = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606113723",
				Position = UDim2.fromScale(0.8, 0),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Slate = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606126284",
				Position = UDim2.fromScale(0.6, 0),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Pebble = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606122309",
				Position = UDim2.fromScale(0, 0.25),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			CorrodedMetal = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606107154",
				Position = UDim2.fromScale(0.2, 0.25),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Foil = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606112190",
				Position = UDim2.fromScale(0.4, 0.25),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Grass = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606115488",
				Position = UDim2.fromScale(0.6, 0.25),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Fabric = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606110569",
				Position = UDim2.fromScale(0.8, 0.25),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			SmoothPlastic = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606127869",
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Wood = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606129056",
				Position = UDim2.fromScale(0.2, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Marble = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "rbxassetid://133293265",
				Position = UDim2.fromScale(0.4, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Marble2 = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606118512",
				Position = UDim2.fromScale(0.4, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Concrete = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606105689",
				Position = UDim2.fromScale(0.6, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Brick = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606096509",
				Position = UDim2.fromScale(0.8, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Cobblestone = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606103198",
				Position = UDim2.fromScale(0, 0.75),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			DiamondPlate = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606109257",
				Position = UDim2.fromScale(0.2, 0.75),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Metal = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606119709",
				Position = UDim2.fromScale(0.4, 0.75),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Sand = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606125442",
				Position = UDim2.fromScale(0.6, 0.75),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Ice = e("ImageButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=606117135",
				Position = UDim2.fromScale(0.8, 0.75),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
		}
	))
end
