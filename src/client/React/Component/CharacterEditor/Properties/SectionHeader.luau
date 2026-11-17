--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
local useFieldValue =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFieldValue")
-- Contexts
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
local CharacterEditorRefusalContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Refusal")
-- Types
local FieldTypes = require("./Types")
export type Properties = FieldTypes.FieldProperties
-- Constants
-- how often + how far apart the header changes color when a power went past the limit
local FLASH_COUNT = 15
local FLASH_INTERVAL = 0.1
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode?
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	local refusal = React.useContext(CharacterEditorRefusalContext)
	local value = useFieldValue()
	local isRed, setIsRed = React.useState(false)
	local isLimitHeader = fieldDefinition ~= nil
		and fieldDefinition.Type == "SectionHeader"
		and fieldDefinition.Binding ~= nil
	local isRefused = isLimitHeader and refusal ~= nil and refusal.Field.Type == "ChoiceList"
	React.useEffect(function()
		if not isRefused then
			return function() end
		end
		local isDead = false
		task.spawn(function()
			for i = 1, FLASH_COUNT do
				setIsRed(i % 2 == 1)
				task.wait(FLASH_INTERVAL)
				if isDead then
					return
				end
			end
			setIsRed(false)
		end)
		return function()
			isDead = true
		end
	end, { refusal :: any, isRefused })
	if not fieldDefinition or fieldDefinition.Type ~= "SectionHeader" then
		return
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.25),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		} :: RobloxComponents.FrameProperties,
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
				Text = if value and value.Type == "Text" then value.Text else fieldDefinition.Text,
				-- a flash that was cut short by the next edit leaves no red behind
				TextColor3 = (isRed and isRefused) and Color3.fromRGB(255, 0, 0) or Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 10,
			}),
		}
	))
end
