--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local CharacterEnergyContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Energy")
local CharacterHealthContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Health")
local CharacterIsEnergyInsufficientContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/IsEnergyInsufficient")
-- Types
export type Properties = {
	IsHealthVisible: boolean?,
	IsEnergyVisible: boolean?,
}
-- Constants
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
local MAX_ENERGY = AttributeDefinition.MAX_ENERGY
local FILL_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getFillPosition(fill: number): UDim2
	return UDim2.fromScale((1 - 0.98 * fill) / 2, 0.06)
end

local function getFillSize(fill: number): UDim2
	return UDim2.fromScale(0.98 * fill, 0.88)
end

local function getHealthColor(health: number): Color3
	if health < MAX_HEALTH * 0.33 then
		return Color3.fromRGB(255, 0, 0)
	elseif health < MAX_HEALTH * 0.66 then
		return Color3.fromRGB(253, 198, 0)
	end
	return Color3.fromRGB(0, 170, 0)
end

local function statBar(props: {
	Text: string,
	Fill: number,
	FillColor3: Color3,
	Position: UDim2,
}): React.ReactNode
	local fill = math.clamp(props.Fill, 0, 1)
	local fillRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local initialFillRef = React.useRef(fill)
	useTween(fillRef, FILL_TWEEN_INFO, {
		Position = getFillPosition(fill),
		Size = getFillSize(fill),
	}, { fill })

	return e("Frame", {
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		Position = props.Position,
		Size = UDim2.new(0.3, 0, 0, 20),
	}, {
		Bar = e(
			"Frame",
			{
				ref = fillRef,
				BackgroundColor3 = props.FillColor3,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				Position = getFillPosition(initialFillRef.current),
				Size = getFillSize(initialFillRef.current),
			} :: RobloxComponents.FrameProperties
		),

		TextLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
			Position = UDim2.fromScale(0, 0.06),
			Size = UDim2.fromScale(1, 0.88),
			Text = props.Text,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextStrokeTransparency = 0.5,
			ZIndex = 2,
		}),
	})
end
-- Class
return function(props: Properties): React.ReactNode
	local health = React.useContext(CharacterHealthContext)
	local energy = React.useContext(CharacterEnergyContext)
	local isEnergyInsufficient = React.useContext(CharacterIsEnergyInsufficientContext)

	return e(React.Fragment, {}, {
		Energy = props.IsEnergyVisible ~= false and e(statBar, {
			Text = "ENERGY",
			Fill = energy / MAX_ENERGY,
			FillColor3 = Color3.fromRGB(26, 167, 255),
			Position = UDim2.new(0.35, 0, 0.01, 25),
		}),

		Health = props.IsHealthVisible ~= false and e(statBar, {
			Text = "HEALTH",
			Fill = health / MAX_HEALTH,
			FillColor3 = getHealthColor(health),
			Position = UDim2.fromScale(0.35, 0.01),
		}),

		EnergyWarning = props.IsEnergyVisible ~= false and isEnergyInsufficient and e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
			Position = UDim2.new(0.35, 0, 0.01, 50),
			Size = UDim2.new(0.3, 0, 0, 20),
			Text = "Not Enough Energy",
			TextColor3 = Color3.fromRGB(255, 204, 0),
			TextScaled = true,
			TextStrokeColor3 = Color3.fromRGB(255, 0, 0),
			TextStrokeTransparency = 0.5,
		}),
	})
end
