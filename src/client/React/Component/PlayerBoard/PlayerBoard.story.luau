--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type Row = ParentComponent.Row
-- Constants
-- how many the servers of the game the layout was made for hold
local MAX_PLAYERS = 30
local NAMES = { "Captain Coolguy", "Sam Carter", "Night Owl", "Maya Lopez", "The Crimson Bolt" }
-- what the old place paid for somebody who hadn't taken anybody down yet
local BOUNTY = 50
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newRow(index: number, hasBounties: boolean): Row
	local out: Row = {
		UserId = index,
		UserName = `Player{index}`,
		-- every fourth one has no avatar to go by
		Name = if index % 4 == 0 then nil else NAMES[(index - 1) % #NAMES + 1],
		-- only somebody on the wrong side of the law has a price on them
		Bounty = if hasBounties and index % 2 == 0 then BOUNTY * (index // 2) else nil,
	}
	table.freeze(out)
	return out
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		PlayerCount = UILabs.Slider(6, 0, MAX_PLAYERS, 1),
		-- off, it's the list of a place where nobody fights: nobody is on a side there, the cells under the head
		-- stay empty
		HasBounties = UILabs.Boolean(true),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local playerCount: number = props.controls.PlayerCount
	local hasBounties: boolean = props.controls.HasBounties
	local rows = React.useMemo(function(): { Row }
		local out: { Row } = {}
		for i = 1, playerCount do
			table.insert(out, newRow(i, hasBounties))
		end
		table.freeze(out)
		return out
	end, { playerCount :: any, hasBounties })

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Menu = isOpen and e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Rows = rows,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Exit" then
							setIsOpen(false)
						end
					end,
				} :: ParentComponent.Properties
			),
			-- stands in for the hud button, which is where the panel is opened from
			Open = not isOpen and e("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 166, 230),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromScale(0.075, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = "Info",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					setIsOpen(true)
				end,
			}),
		}),
	})
end)
