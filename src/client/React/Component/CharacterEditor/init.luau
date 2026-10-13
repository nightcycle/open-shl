--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
-- Components
local EditableCharacterProvider = require("@self/EditableCharacterProvider")
local Explorer = require("@self/Explorer")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local Properties = require("@self/Properties")
local Scene = require("@self/Scene")
-- Contexts
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type ItemDefinition = AppearanceType.ItemDefinition
export type HiddenTag = AppearanceType.HiddenTag
export type FieldDefinition = CharacterEditorType.FieldDefinition
export type PageDefinition = CharacterEditorType.PageDefinition
export type ActionInfo =
	{
		Type: "FieldUpdated",
		Path: string,
		Page: PageDefinition,
		Field: FieldDefinition,
		Value: any,
	}
	| {
		Type: "Exit",
		IsSaving: boolean,
	}
export type Properties = Frame.Properties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local isHeroFocus, setIsHeroFocus = React.useState(true)
	local path, setPath = React.useState("")
	local setPathCallback = React.useCallback(function(...)
		print(`path:`, ...)
		setPath(...)
	end, {})
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		Path = e(PathContext.Provider, {
			value = path,
		}, {
			EditableCharacterProvider = e(EditableCharacterProvider, {}, {
				HeroFocusProvider = e(IsHeroFocusContext.Provider, {
					value = isHeroFocus,
				}, {
					Scene = e(Scene, {
						IsHeroFocus = isHeroFocus,
					}),
					SetPath = e(SetPathContext.Provider, {
						value = setPathCallback,
					}, {
						Explorer = e(Explorer, {
							BackgroundColor3 = Color3.new(),
							BackgroundTransparency = 0.5,
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							Position = UDim2.fromScale(0, 0.025),
							Size = UDim2.fromScale(0.3, 0.54),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							OnExit = function()
								props.OnAction({
									Type = "Exit",
									IsSaving = false,
								})
							end,
						}),
					}),
				}),

				Properties = e(Properties, {
					Position = UDim2.fromScale(0.7, 0.025),
					Size = UDim2.fromScale(0.3, 0.54),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				}),
			}),
		}),

		SwitchIdentity = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.375, 0.7),
			Size = UDim2.fromScale(0.25, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Button = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(255, 201, 37),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 1, -10),
				Text = "Swap Identities",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					local page = CharacterEditorDefinition.getPage(path)
					if page.IsSome and page.Value.ExclusionTags then
						if not isHeroFocus then
							if table.find(page.Value.ExclusionTags, "IsSuper") then
								setPath("")
							end
						else
							if table.find(page.Value.ExclusionTags, "IsSecret") then
								setPath("")
							end
						end
					end
					setIsHeroFocus(not isHeroFocus)
				end,
			}),
		}),

		Exit = e("Frame", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = UDim2.fromScale(0.375, 0.025),
			Size = UDim2.fromScale(0.25, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Button = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(75, 115, 245),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.new(1, -10, 1, -10),
				Text = "Save and Exit",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Exit",
						IsSaving = true,
					})
				end,
			}),
		}),
	})
end
