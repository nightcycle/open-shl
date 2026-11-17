--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Components
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
local Scene = require("@self/Scene")
-- Hooks
local useCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterSelect/useCharacter")
-- Contexts
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
export type Character = SessionCharactersContext.Character
type PowerDefinition = PowerDefinition.PowerDefinition
export type ActionInfo =
	{
		Type: "Select",
		CharacterId: string,
	}
	| {
		Type: "Edit",
		CharacterId: string,
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local UNNAMED_TEXT = "Unnamed Character"
local BUTTON_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getOpenIndex(characters: { Character }, activeCharacterId: string): number?
	if #characters == 0 then
		return nil
	end
	for i, character in characters do
		if character.Id == activeCharacterId then
			return i
		end
	end
	return 1
end

local function turnButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.new(),
		BorderSizePixel = 5,
		FontFace = BUTTON_FONT,
		Modal = true,
		Size = UDim2.fromScale(0.143, 1),
		TextColor3 = Color3.new(),
		TextScaled = true,
		TextStrokeColor3 = Color3.new(1, 1, 1),
	}, props))
end

local function actionButton(props: RobloxComponents.FrameProperties & {
	Text: string,
	ButtonColor3: Color3,
	OnClick: (() -> ())?,
})
	local isEnabled = props.OnClick ~= nil
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Size = UDim2.fromScale(0.2, 0.07),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		},
		props,
		{
			Button = e(
				"TextButton",
				{
					Active = isEnabled,
					AutoButtonColor = isEnabled,
					BackgroundColor3 = props.ButtonColor3,
					BackgroundTransparency = isEnabled and 0.5 or 0.8,
					BorderSizePixel = 0,
					FontFace = BUTTON_FONT,
					Modal = true,
					Position = UDim2.fromOffset(5, 5),
					Selectable = isEnabled,
					Size = UDim2.new(1, -10, 1, -10),
					Text = props.Text,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeColor3 = Color3.new(1, 1, 1),
					TextTransparency = isEnabled and 0 or 0.7,
					[React.Event.Activated] = props.OnClick,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
-- Class
return function(props: Properties)
	local characters = React.useContext(SessionCharactersContext)
	local activeCharacterId = React.useContext(SessionActiveCharacterIdContext)

	-- read from who is worn once, when the menu opens: a select changes who that is a moment before the menu closes
	local index: number?, setIndex: (number?) -> () = React.useState(function(): number?
		return getOpenIndex(characters, activeCharacterId)
	end)
	React.useEffect(function()
		-- the slots can get here after the menu opened
		if not index then
			setIndex(getOpenIndex(characters, activeCharacterId))
		end
		return function() end
	end, { characters :: any, activeCharacterId })
	local character = useCharacter(index)

	local powerDefinitions = React.useMemo(function(): { PowerDefinition }
		local out: { PowerDefinition } = {}
		if character then
			for _, power in character.Powers do
				local powerDefRes = PowerDefinition.get(power.Id)
				if powerDefRes.IsErr then
					warn(`power-def err: {powerDefRes.Value}`)
					continue
				end
				table.insert(out, powerDefRes.Value)
			end
		end
		table.freeze(out)
		return out
	end, { character })

	local turnClockRef = React.useRef(0)
	local function turn(direction: number)
		-- a press is passed over until the row is done sliding
		if not index or os.clock() - turnClockRef.current < CONSTANTS.SLIDE_DURATION then
			return
		end
		turnClockRef.current = os.clock()
		setIndex(index + direction)
	end

	local powerIcons: { [string]: React.ReactNode } = {}
	for i, powerDef in powerDefinitions do
		local icon = powerDef.Icon
		powerIcons[`Power-{i}`] = e("ImageLabel", {
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Image = if icon.Type == "Sprite" then icon.SheetUrl else icon.Url,
			ImageRectOffset = if icon.Type == "Sprite" then icon.Position else nil,
			ImageRectSize = if icon.Type == "Sprite" then icon.Size else nil,
			LayoutOrder = i,
			Size = UDim2.fromScale(0.15, 0.15),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		})
	end

	local title = ""
	if character then
		local name = character.Identities.Main.Profile.Name
		title = if name == "" then UNNAMED_TEXT else name
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Scene = index and e(
				Scene,
				{
					Index = index,
				} :: Scene.Properties
			),
			TurnChar = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.125, 0.05),
				Size = UDim2.fromScale(0.75, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				Left = e(
					turnButton,
					{
						Text = "<",
						[React.Event.Activated] = function()
							turn(-1)
						end,
					} :: RobloxComponents.TextButtonProperties
				),
				Right = e(
					turnButton,
					{
						Position = UDim2.fromScale(0.857, 0),
						Text = ">",
						[React.Event.Activated] = function()
							turn(1)
						end,
					} :: RobloxComponents.TextButtonProperties
				),
			}),
			Title = e("Frame", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = UDim2.fromScale(0.25, 0.05),
				Size = UDim2.fromScale(0.5, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				TextLabel = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0, 0.125),
					Size = UDim2.fromScale(1, 0.75),
					Text = title,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
				Error = props.ErrorMessage and e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = BUTTON_FONT,
					Position = UDim2.fromScale(0, 1.1),
					Size = UDim2.fromScale(1, 0.4),
					Text = props.ErrorMessage,
					TextColor3 = Color3.fromRGB(255, 204, 0),
					TextScaled = true,
					TextStrokeColor3 = Color3.fromRGB(255, 0, 0),
					TextStrokeTransparency = 0.5,
				}),
			}),
			Select = e(actionButton, {
				Position = UDim2.fromScale(0.125, 0.75),
				Text = "Select",
				ButtonColor3 = Color3.fromRGB(0, 170, 0),
				OnClick = if character
					then function()
						props.OnAction({
							Type = "Select",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
			Weapons = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.325, 0.75),
				Size = UDim2.fromScale(0.35, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.02, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
				}),
				Icons = e(React.Fragment, {}, powerIcons),
			}),
			Edit = e(actionButton, {
				Position = UDim2.fromScale(0.675, 0.75),
				Text = "Edit",
				ButtonColor3 = Color3.fromRGB(0, 85, 255),
				OnClick = if character
					then function()
						props.OnAction({
							Type = "Edit",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.new(1, -28, 0, 28),
					ZIndex = 2,
					[React.Event.Activated] = function()
						props.OnAction({
							Type = "Exit",
						})
					end,
				} :: ExitButton.Properties
			),
		}
	))
end
