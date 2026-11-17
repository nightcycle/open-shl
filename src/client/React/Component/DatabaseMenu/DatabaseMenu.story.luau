--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type PublicProfile = ParentComponent.PublicProfile
-- Constants
local MAX_PLAYERS = 12
local ALIAS_NAMES = { "Captain Coolguy", "Night Owl", "The Crimson Bolt", "Doctor Frost" }
local IDENTITY_NAMES = { "Sam Carter", "Maya Lopez", "Jon Reyes" }
local BACKSTORY = "Raised on a farm, struck by lightning + bitten by a spider on the very same day."
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newProfile(index: number): PublicProfile
	local alignments = PseudoEnum.getEnumItems("Alignment")
	local out: PublicProfile = {
		UserId = index,
		UserName = `Player{index}`,
		AliasName = if index % 3 == 0 then "" else ALIAS_NAMES[(index - 1) % #ALIAS_NAMES + 1],
		IdentityName = if index % 4 == 0 then "" else IDENTITY_NAMES[(index - 1) % #IDENTITY_NAMES + 1],
		Alignment = alignments[(index - 1) % #alignments + 1],
		Backstory = if index % 2 == 0 then "" else BACKSTORY,
	}
	table.freeze(out)
	return out
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PlayerCount = UILabs.Slider(6, 0, MAX_PLAYERS, 1),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local playerCount: number = props.controls.PlayerCount
	local profiles = React.useMemo(function(): { PublicProfile }
		local out: { PublicProfile } = {}
		for i = 1, playerCount do
			table.insert(out, newProfile(i))
		end
		table.freeze(out)
		return out
	end, { playerCount })

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Open = e(
			"TextButton",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 213, 255),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.04, 0.55),
				Size = UDim2.fromScale(0.08, 0.08),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = isOpen and "Close" or "Open",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					setIsOpen(not isOpen)
				end,
			} :: RobloxComponents.TextButtonProperties
		),
		Menu = isOpen and e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0.25, 0.5),
				Size = UDim2.fromScale(0.5, 0.6),
				Profiles = profiles,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "Exit" then
						setIsOpen(false)
					end
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			} :: ParentComponent.Properties
		),
	})
end)
