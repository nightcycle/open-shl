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
	if not fieldDefinition or fieldDefinition.Type ~= "Choose" then
		return
	end
	if not fieldCallback then
		return
	end
	return e(Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.5),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: Frame.Properties,
		props,
		{
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
		}
	))
end
