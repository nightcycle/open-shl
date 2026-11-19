--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local Workspace = game:GetService("Workspace")
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
-- Constants
local HEAD_DISTANCE = 12
local HEAD_SIZE = Vector3.new(1.2, 1.2, 1.2)
-- the sides a name is colored for where there's a fight on
local TEAM_COLORS: { [string]: Color3 } = {
	Hero = Color3.fromRGB(0, 0, 255),
	Villain = Color3.fromRGB(255, 0, 0),
}
local TEAMS = { "None", "Hero", "Villain" }
-- what's read with the name where who fights is each player's own pick
local MODES = { "None", "RP", "PVP" }
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		PersonaName = UILabs.String("Captain Coolguy"),
		UserName = UILabs.String("Player1"),
		IsInMenu = UILabs.Boolean(false),
		-- only read in a look that has a place for it
		Bio = UILabs.String("Fell into a vat of something at the refinery. Sorts the mail of Valor City by day."),
		IsBioShown = UILabs.Boolean(false),
		Team = UILabs.Choose(TEAMS),
		-- only read in a look that has a place for it
		Mode = UILabs.Choose(MODES),
		Style = StyleStory.newControl(),
	},
}, function(props)
	-- billboards only render in the world, so it needs a part to sit on
	local head: Part?, setHead: (Part?) -> () = React.useState(nil :: Part?)
	React.useEffect(function()
		local camera = Workspace.CurrentCamera
		local part = Instance.new("Part")
		part.Name = "NameTagStoryHead"
		part.Anchored = true
		part.CanCollide = false
		part.Size = HEAD_SIZE
		part.CFrame = if camera then camera.CFrame * CFrame.new(0, 0, -HEAD_DISTANCE) else CFrame.new(0, 10, 0)
		part.Parent = Workspace
		setHead(part)
		return function()
			part:Destroy()
		end
	end, {})

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Hint = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.fromScale(0.5, 0.05),
			Text = "the tag floats over the part in front of the camera of the place",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}),
		Tag = head and ReactRoblox.createPortal(
			StyleStory.provide(props.controls.Style, {
				NameTag = e(
					ParentComponent,
					{
						PersonaName = props.controls.PersonaName,
						UserName = props.controls.UserName,
						IsInMenu = props.controls.IsInMenu,
						Bio = if props.controls.IsBioShown then props.controls.Bio else nil,
						TeamColor3 = TEAM_COLORS[props.controls.Team],
						Mode = if props.controls.Mode ~= "None" then props.controls.Mode else nil,
					} :: ParentComponent.Properties
				),
			}),
			head
		),
	})
end)
