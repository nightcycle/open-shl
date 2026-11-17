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
local SongDefinition = require("@game/ReplicatedStorage/Shared/Definition/Song")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type SongId = SongDefinition.SongId
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {},
}, function(props)
	local songId: SongId, setSongId: (SongId) -> () = React.useState(SongDefinition.DEFAULT_ID)
	local isOn, setIsOn = React.useState(false)
	local isOpen, setIsOpen = React.useState(true)
	local song = React.useMemo(function(): ParentComponent.SongDefinition?
		local songRes = SongDefinition.get(songId)
		if songRes.IsErr then
			warn(`song err: {songRes.Value}`)
			return nil
		end
		return songRes.Value
	end, { songId })

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
				BackgroundColor3 = Color3.fromRGB(0, 198, 92),
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.04, 0.45),
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
		Menu = isOpen and song and e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.3, 0.08),
				Song = song,
				IsOn = isOn,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "SetPower" then
						setIsOn(action.IsOn)
					elseif action.Type == "Next" then
						local songRes = SongDefinition.getNext(songId)
						if songRes.IsOk then
							setSongId(songRes.Value.Id)
						end
					elseif action.Type == "Previous" then
						local songRes = SongDefinition.getPrevious(songId)
						if songRes.IsOk then
							setSongId(songRes.Value.Id)
						end
					elseif action.Type == "Exit" then
						setIsOpen(false)
					end
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			} :: ParentComponent.Properties
		),
	})
end)
