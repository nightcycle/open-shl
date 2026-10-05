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
-- Types
export type Properties = Frame.Properties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: Frame.Properties,
		props,
		{
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 0.1),
				Text = "Properties",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			ScrollingFrame = e("ScrollingFrame", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				CanvasSize = UDim2.fromScale(0, 1.5),
				Position = UDim2.new(0, 8, 0.1, 8),
				ScrollBarThickness = 15,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Size = UDim2.new(1, -16, 0.9, -16),
			}, {
				Selection = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0, 0.65),
					Size = UDim2.new(1, -17, 0.5, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Edit = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(107, 107, 107),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Modal = true,
						Position = UDim2.fromScale(0.125, 0.4),
						Size = UDim2.fromScale(0.75, 0.25),
						Text = "Edit Lenses",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextStrokeColor3 = Color3.new(1, 1, 1),
						Visible = false,
					}),

					AddRemove = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 0),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Modal = true,
						Position = UDim2.fromScale(0.125, 0.05),
						Size = UDim2.fromScale(0.75, 0.25),
						Text = "Add Lenses",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextStrokeColor3 = Color3.new(1, 1, 1),
					}),
				}),

				Materials = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.05, 0.4),
					Size = UDim2.new(0.9, -17, 0.72, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
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
				}),

				AddRemove = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 0.25, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Button = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 0),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Modal = true,
						Position = UDim2.fromScale(0.125, 0.25),
						Size = UDim2.fromScale(0.75, 0.5),
						Text = "Add Item",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextStrokeColor3 = Color3.new(1, 1, 1),
					}),
				}),

				NameEntry = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 0.25, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					TextBox = e("TextBox", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.3,
						BorderColor3 = Color3.new(1, 1, 1),
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
						Position = UDim2.fromScale(0.0625, 0.25),
						Size = UDim2.fromScale(0.875, 0.5),
						Text = "Insert Name Here",
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 14,
					}),

					Test = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 255),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.25, 1),
						Size = UDim2.fromScale(0.5, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Test for Censorship",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),
				}),

				BackstoryEntry = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 0.5, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					TextBox = e("TextBox", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.3,
						BorderColor3 = Color3.new(1, 1, 1),
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						MultiLine = true,
						PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
						Position = UDim2.fromScale(0.062, 0.125),
						Size = UDim2.fromScale(0.875, 1.5),
						Text = "Insert Story Here",
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
					}),

					Test = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 255),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.25, 1.75),
						Size = UDim2.fromScale(0.5, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Test for Censorship",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),
				}),

				Alignment = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 1, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Quality = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0, 0.1525),
						Size = UDim2.fromScale(1, 0.35),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
					}, {
						Evil = e("TextButton", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.02, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Evil",
							TextSize = 14,
						}),

						Neutral = e("TextButton", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.345, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Neutral",
							TextSize = 14,
						}),

						Good = e("TextButton", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.67, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Good",
							TextSize = 14,
						}),
					}),

					Temperament = e("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0, 0.65),
						Size = UDim2.fromScale(1, 0.35),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
					}, {
						Lawful = e("TextButton", {
							BackgroundColor3 = Color3.fromRGB(171, 171, 171),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.67, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Lawful",
							TextSize = 14,
						}),

						Neutral = e("TextButton", {
							BackgroundColor3 = Color3.fromRGB(171, 171, 171),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.345, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Neutral",
							TextSize = 14,
						}),

						Chaotic = e("TextButton", {
							BackgroundColor3 = Color3.fromRGB(171, 171, 171),
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.02, 0),
							Size = UDim2.fromScale(0.3, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Chaotic",
							TextSize = 14,
						}),
					}),

					TextLabel = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Size = UDim2.fromScale(1, 0.15),
						Text = "Choose One:",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					TextLabel2 = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(1, 0.15),
						Text = "Choose One:",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),
				}),

				Powers = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 2, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
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
						Visible = false,
					}),

					PowerTemplate = e("Folder", nil, {
						TextButton = e("TextButton", {
							BackgroundColor3 = Color3.new(),
							BackgroundTransparency = 0.5,
							BorderColor3 = Color3.new(1, 1, 1),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.19, 0.15),
							Size = UDim2.fromScale(0.8, 0.15),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							Visible = false,
						}, {
							ColorPicker = e("Frame", {
								BackgroundColor3 = Color3.new(),
								BorderColor3 = Color3.fromRGB(255, 170, 0),
								BorderSizePixel = 0,
								Selectable = true,
								Size = UDim2.fromScale(1, 1),
								Visible = false,
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
							Visible = false,
						}),
					}),
				}),

				DeathStyle = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 2, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					BasicLabel = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/SourceSansPro.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.fromScale(0, 0.025),
						Size = UDim2.fromScale(1, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Choose a Death Style",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					FallForward = e("TextButton", {
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

					FallBackward = e("TextButton", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.025, 0.1),
						Size = UDim2.fromScale(0.95, 0.08),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Fall Backwards",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Test = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 255),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.35, 0.25),
						Size = UDim2.fromScale(0.3, 0.3),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Test",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Visible = false,
					}),
				}),

				TransformationStyle = e("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -17, 2, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					BasicLabel = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/SourceSansPro.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.fromScale(0, 0.025),
						Size = UDim2.fromScale(1, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Choose a Transformation Style",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Ascension = e("TextButton", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.025, 0.1),
						Size = UDim2.fromScale(0.95, 0.08),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Ascension",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Fire = e("TextButton", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.025, 0.2),
						Size = UDim2.fromScale(0.95, 0.08),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Fire",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Smoke = e("TextButton", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.025, 0.25),
						Size = UDim2.fromScale(0.95, 0.08),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Smoke",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Spin = e("TextButton", {
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.025, 0.15),
						Size = UDim2.fromScale(0.95, 0.08),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Spin",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Test = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 255),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.35, 0.4),
						Size = UDim2.fromScale(0.3, 0.3),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Test",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Visible = false,
					}),
				}),

				GenerateName = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0, 0.15),
					Size = UDim2.new(1, -17, 0.25, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Generate = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 170, 0),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 2,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.05, 0.2),
						Size = UDim2.fromScale(0.35, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "Generate Alias",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),

					Title = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/SourceSansPro.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.fromScale(0.45, 0.2),
						Size = UDim2.fromScale(0.5, 0.1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = "",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						ZIndex = 10,
					}),
				}),

				SkinColors = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.05, 0.075),
					Size = UDim2.new(0.9, -17, 0.9, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Jango = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(180, 128, 255),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.5, 0.75),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
						Visible = false,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new("Alder"),
						}),
					}),

					LimeGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 255, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511429, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new("Lime green"),
						}),
					}),

					LightOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(234, 184, 146),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.894999, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Light orange),
						}),
					}),

					Lapis = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(16, 42, 220),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lapis),
						}),
					}),

					HotPink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 0, 191),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767141, 1.95094e-06),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Hot pink),
						}),
					}),

					LightReddishViolet = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(232, 186, 200),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767144, 0.255717),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Light reddish violet),
						}),
					}),

					Mint = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(177, 229, 166),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511429, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Mint),
						}),
					}),

					PastelBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(128, 187, 219),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel Blue),
						}),
					}),

					Rust = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(143, 76, 42),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Rust),
						}),
					}),

					BrightYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(245, 205, 48),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383571, 0.511427),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Yellow(),
						}),
					}),

					NewYeller = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(New Yeller),
						}),
					}),

					Tawny = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(150, 85, 85),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.12786, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Tawny),
						}),
					}),

					SmokyGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(91, 93, 105),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Smoky grey),
						}),
					}),

					NeonOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(213, 115, 61),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Neon orange),
						}),
					}),

					ReallyRed = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Really red),
						}),
					}),

					Nougat = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(204, 142, 105),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Nougat),
						}),
					}),

					PastelGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(204, 255, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel green),
						}),
					}),

					Seashell = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(233, 218, 218),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767142, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Seashell),
						}),
					}),

					Cashmere = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(211, 190, 150),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0.639287),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cashmere),
						}),
					}),

					LilyWhite = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(237, 234, 234),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lily white),
						}),
					}),

					Cork = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(188, 155, 93),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383574, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cork),
						}),
					}),

					BrightRed = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(196, 40, 28),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Red(),
						}),
					}),

					Fog = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(199, 212, 228),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.127857),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Fog),
						}),
					}),

					Cyan = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(4, 175, 236),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639287, 0.383573),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cyan),
						}),
					}),

					CarnationPink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 152, 220),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767142, 0.383571),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Carnation pink),
						}),
					}),

					Moss = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(124, 156, 107),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.51143, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Moss),
						}),
					}),

					DaisyOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(248, 217, 109),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383571, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Daisy orange),
						}),
					}),

					Maroon = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(117, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Maroon),
						}),
					}),

					BurntSienna = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(106, 57, 9),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.767141),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Burnt Sienna),
						}),
					}),

					CGABrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(170, 85, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.511427),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(CGA brown),
						}),
					}),

					DustyRose = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(163, 75, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.511429),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Dusty Rose),
						}),
					}),

					FawnBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(160, 132, 79),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383573, 0.894998),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Fawn brown),
						}),
					}),

					Black = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(27, 42, 53),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(7.31603e-07, 0.767141),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Black(),
						}),
					}),

					Plum = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(123, 47, 123),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767141, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Plum),
						}),
					}),

					ParsleyGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(44, 101, 29),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Parsley green),
						}),
					}),

					Cocoa = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 36, 36),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127858, 0.76714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cocoa),
						}),
					}),

					StormBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(51, 88, 130),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.767145),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Storm blue),
						}),
					}),

					DirtBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 66, 54),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Medium brown),
						}),
					}),

					InstitutionalWhite = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(248, 248, 248),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 1.95094e-06),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Institutional white),
						}),
					}),

					DeepOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 175, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Deep orange),
						}),
					}),

					PastelYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383574, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel yellow),
						}),
					}),

					Crimson = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(151, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Crimson),
						}),
					}),

					Lilac = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(167, 94, 155),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767143, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lilac),
						}),
					}),

					DarkStoneGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(99, 95, 98),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(9.75471e-07, 0.639285),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.DarkGray(),
						}),
					}),

					DirtBrown2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 66, 54),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Medium brown),
						}),
					}),

					Wheat = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(241, 231, 199),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.894999, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel yellow),
						}),
					}),

					ElectricBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(9, 137, 207),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639288, 0.51143),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Electric blue),
						}),
					}),

					CoolYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(253, 234, 141),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cool yellow),
						}),
					}),

					MediumStoneGrey = e("TextButton", {
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(4.87736e-07, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue"),
					}),

					DarkGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(40, 127, 71),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Green(),
						}),
					}),

					BrightBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(13, 105, 172),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.639285),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Blue(),
						}),
					}),

					BrightGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(75, 151, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.511429),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Bright green),
						}),
					}),

					PineCone = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(108, 88, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 0.767143),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pine Cone),
						}),
					}),

					Pink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 102, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.76714, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pink),
						}),
					}),

					DustyRose2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(163, 75, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Dusty Rose),
						}),
					}),

					ReddishBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(105, 64, 40),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255716, 0.639288),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Reddish brown),
						}),
					}),

					BurntSienna2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(106, 57, 9),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127857, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Burnt Sienna),
						}),
					}),

					NavyBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 32, 96),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Navy blue),
						}),
					}),

					ReallyBlack = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(17, 17, 17),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.894999),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Really black),
						}),
					}),

					BrightOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(218, 133, 65),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Bright orange),
						}),
					}),

					BrYellowishOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(226, 155, 64),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Br. yellowish orange),
						}),
					}),

					EarthGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(39, 70, 45),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Earth green),
						}),
					}),

					PastelBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 204, 153),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel brown),
						}),
					}),

					Mulberry = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(89, 34, 89),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.76714, 0.894998),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Mulberry),
						}),
					}),

					GhostGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(202, 203, 209),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Ghost grey),
						}),
					}),
				}),

				Colors = e("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.05, 0.075),
					Size = UDim2.new(0.9, -17, 0.9, -15),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = false,
				}, {
					Jango = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(180, 128, 255),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.5, 0.75),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
						Visible = false,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Alder),
						}),
					}),

					LimeGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 255, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511429, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lime green),
						}),
					}),

					LightOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(234, 184, 146),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.894999, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Light orange),
						}),
					}),

					Lapis = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(16, 42, 220),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lapis),
						}),
					}),

					HotPink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 0, 191),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767141, 1.95094e-06),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Hot pink),
						}),
					}),

					LightReddishViolet = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(232, 186, 200),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767144, 0.255717),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Light reddish violet),
						}),
					}),

					Mint = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(177, 229, 166),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511429, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Mint),
						}),
					}),

					PastelBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(128, 187, 219),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel Blue),
						}),
					}),

					Rust = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(143, 76, 42),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Rust),
						}),
					}),

					BrightYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(245, 205, 48),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383571, 0.511427),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Yellow(),
						}),
					}),

					NewYeller = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(New Yeller),
						}),
					}),

					Tawny = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(150, 85, 85),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.12786, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Tawny),
						}),
					}),

					SmokyGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(91, 93, 105),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Smoky grey),
						}),
					}),

					NeonOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(213, 115, 61),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Neon orange),
						}),
					}),

					ReallyRed = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Really red),
						}),
					}),

					Nougat = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(204, 142, 105),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Nougat),
						}),
					}),

					PastelGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(204, 255, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel green),
						}),
					}),

					Seashell = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(233, 218, 218),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767142, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Seashell),
						}),
					}),

					Cashmere = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(211, 190, 150),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0.639287),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cashmere),
						}),
					}),

					LilyWhite = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(237, 234, 234),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lily white),
						}),
					}),

					Cork = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(188, 155, 93),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383574, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cork),
						}),
					}),

					BrightRed = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(196, 40, 28),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.127859),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Red(),
						}),
					}),

					Fog = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(199, 212, 228),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.127857),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Fog),
						}),
					}),

					Cyan = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(4, 175, 236),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639287, 0.383573),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cyan),
						}),
					}),

					CarnationPink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 152, 220),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767142, 0.383571),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Carnation pink),
						}),
					}),

					Moss = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(124, 156, 107),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.51143, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Moss),
						}),
					}),

					DaisyOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(248, 217, 109),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383571, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Daisy orange),
						}),
					}),

					Maroon = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(117, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Maroon),
						}),
					}),

					BurntSienna = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(106, 57, 9),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.767141),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Burnt Sienna),
						}),
					}),

					CGABrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(170, 85, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.511427),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(CGA brown),
						}),
					}),

					DustyRose = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(163, 75, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.511429),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Dusty Rose),
						}),
					}),

					FawnBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(160, 132, 79),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383573, 0.894998),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Fawn brown),
						}),
					}),

					Black = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(27, 42, 53),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(7.31603e-07, 0.767141),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Black(),
						}),
					}),

					Plum = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(123, 47, 123),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767141, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Plum),
						}),
					}),

					ParsleyGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(44, 101, 29),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.767142),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Parsley green),
						}),
					}),

					Cocoa = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 36, 36),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127858, 0.76714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cocoa),
						}),
					}),

					StormBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(51, 88, 130),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.767145),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Storm blue),
						}),
					}),

					DirtBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 66, 54),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Medium brown),
						}),
					}),

					InstitutionalWhite = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(248, 248, 248),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 1.95094e-06),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Institutional white),
						}),
					}),

					DeepOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 175, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Deep orange),
						}),
					}),

					PastelYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383574, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel yellow),
						}),
					}),

					Crimson = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(151, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Crimson),
						}),
					}),

					Lilac = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(167, 94, 155),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.767143, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Lilac),
						}),
					}),

					DarkStoneGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(99, 95, 98),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(9.75471e-07, 0.639285),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.DarkGray(),
						}),
					}),

					DirtBrown2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(86, 66, 54),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Medium brown),
						}),
					}),

					Wheat = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(241, 231, 199),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.894999, 9.7547e-07),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel yellow),
						}),
					}),

					ElectricBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(9, 137, 207),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639288, 0.51143),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Electric blue),
						}),
					}),

					CoolYellow = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(253, 234, 141),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.383572, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Cool yellow),
						}),
					}),

					MediumStoneGrey = e("TextButton", {
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(4.87736e-07, 0.383572),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue"),
					}),

					DarkGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(40, 127, 71),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.639286),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Green(),
						}),
					}),

					BrightBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(13, 105, 172),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639285, 0.639285),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							Value = BrickColor.Blue(),
						}),
					}),

					BrightGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(75, 151, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.511429),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Bright green),
						}),
					}),

					PineCone = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(108, 88, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 0.767143),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pine Cone),
						}),
					}),

					Pink = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 102, 204),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.76714, 0.511428),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pink),
						}),
					}),

					DustyRose2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(163, 75, 75),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127859, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Dusty Rose),
						}),
					}),

					ReddishBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(105, 64, 40),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255716, 0.639288),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Reddish brown),
						}),
					}),

					BurntSienna2 = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(106, 57, 9),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.127857, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Burnt Sienna),
						}),
					}),

					NavyBlue = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(0, 32, 96),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.639286, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Navy blue),
						}),
					}),

					ReallyBlack = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(17, 17, 17),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.894999),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Really black),
						}),
					}),

					BrightOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(218, 133, 65),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255714, 0.255715),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Bright orange),
						}),
					}),

					BrYellowishOrange = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(226, 155, 64),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.255715, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Br. yellowish orange),
						}),
					}),

					EarthGreen = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(39, 70, 45),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.511427, 0.895),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Earth green),
						}),
					}),

					PastelBrown = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(255, 204, 153),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.895, 0.127858),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Pastel brown),
						}),
					}),

					Mulberry = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(89, 34, 89),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.76714, 0.894998),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Mulberry),
						}),
					}),

					GhostGrey = e("TextButton", {
						BackgroundColor3 = Color3.fromRGB(202, 203, 209),
						BorderColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(1.46321e-06, 0.255714),
						Size = UDim2.fromScale(0.125, 0.125),
						Text = "",
						TextSize = 14,
					}, {
						Value = e("BrickColorValue", {
							-- Value = BrickColor.new(Ghost grey),
						}),
					}),
				}),
			}),
		}
	))
end
