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
	if not fieldDefinition or fieldDefinition.Type ~= "ChoiceList" then
		return
	end
	if not fieldCallback then
		return
	end
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 2),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.fromScale(1, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "Choose Four Powers",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 10,
			}),

			BasicLabel = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.1),
				Size = UDim2.fromScale(1, 0.1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "-Melee-",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			PowerTemplate = e("Folder", nil, {
				TextButton = e("TextButton", {
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0.025, 0.15),
					Size = UDim2.fromScale(0.95, 0.08),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = "Fall Forwards",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),

				TextIconButton = e("TextButton", {
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0.19, 0.15),
					Size = UDim2.fromScale(0.8, 0.15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}, {
					ColorPicker = e("Frame", {
						BackgroundColor3 = Color3.new(),
						BorderColor3 = Color3.fromRGB(255, 170, 0),
						BorderSizePixel = 0,
						Selectable = true,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 3,
					}, {
						Left = e("TextButton", {
							BackgroundColor3 = Color3.new(),
							BackgroundTransparency = 0.1,
							BorderColor3 = Color3.new(1, 1, 1),
							BorderSizePixel = 3,
							FontFace = Font.new(
								"rbxasset://fonts/families/SourceSansPro.json",
								Enum.FontWeight.Bold,
								Enum.FontStyle.Normal
							),
							Position = UDim2.fromScale(0.025, 0.1),
							Size = UDim2.fromScale(0.15, 0.8),
							Text = "<",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							ZIndex = 4,
						}),

						Right = e("TextButton", {
							BackgroundColor3 = Color3.new(),
							BackgroundTransparency = 0.1,
							BorderColor3 = Color3.new(1, 1, 1),
							BorderSizePixel = 3,
							FontFace = Font.new(
								"rbxasset://fonts/families/SourceSansPro.json",
								Enum.FontWeight.Bold,
								Enum.FontStyle.Normal
							),
							Position = UDim2.fromScale(0.45, 0.1),
							Size = UDim2.fromScale(0.15, 0.8),
							Text = ">",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							ZIndex = 4,
						}),

						ImageLabel = e("ImageLabel", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							BorderColor3 = Color3.new(1, 1, 1),
							Position = UDim2.fromScale(0.225, 0.2),
							Selectable = true,
							Size = UDim2.fromScale(0.175, 0.6),
							ZIndex = 4,
						}),

						Done = e("TextButton", {
							BackgroundColor3 = Color3.fromRGB(0, 170, 0),
							BackgroundTransparency = 0.1,
							BorderColor3 = Color3.new(1, 1, 1),
							BorderSizePixel = 3,
							FontFace = Font.new(
								"rbxasset://fonts/families/SourceSansPro.json",
								Enum.FontWeight.Bold,
								Enum.FontStyle.Normal
							),
							Position = UDim2.fromScale(0.65, 0.15),
							Size = UDim2.fromScale(0.3, 0.7),
							Text = "Done",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							ZIndex = 4,
						}),
					}),
				}),

				ImageLabel = e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://133293265",
					Position = UDim2.fromScale(0.0125, 0.15),
					Selectable = true,
					Size = UDim2.fromScale(0.15, 0.15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				}),
			}),
		}
	))
end
