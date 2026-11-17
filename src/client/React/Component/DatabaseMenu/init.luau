--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
-- Components
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
local PlayerList = require("@self/PlayerList")
local ProfilePanel = require("@self/ProfilePanel")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
-- Types
local Types = require("@self/Types")
export type PublicProfile = Types.PublicProfile
export type Tab = Types.Tab
export type ActionInfo = {
	Type: "Exit",
}

export type Properties = RobloxComponents.FrameProperties & {
	Profiles: { PublicProfile },
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local NO_BACKSTORY_TEXT = "Their life was changed when they forgot to write a backstory"
local SLIDE_OFFSET = UDim2.fromScale(0.75, 0)
local SLIDE_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- placeholder text for whatever the player left blank
local function fill(profile: PublicProfile): PublicProfile
	return FreezeUtil.delta(profile, function(t: PublicProfile): PublicProfile
		if t.AliasName == "" then
			t.AliasName = `Super {t.UserName}`
		end
		if t.IdentityName == "" then
			t.IdentityName = t.UserName
		end
		if t.Backstory == "" then
			t.Backstory = NO_BACKSTORY_TEXT
		end
		return t
	end)
end
-- Class
return function(props: Properties)
	local tab: Tab, setTab: (Tab) -> () = React.useState("Users" :: Tab)
	local selectedUserId: number?, setSelectedUserId: (number?) -> () = React.useState(nil :: number?)
	local profiles = React.useMemo(function(): { PublicProfile }
		local out: { PublicProfile } = {}
		for _, profile in props.Profiles do
			table.insert(out, fill(profile))
		end
		table.freeze(out)
		return out
	end, { props.Profiles })
	local selectedProfile = React.useMemo(function(): PublicProfile?
		for _, profile in profiles do
			if profile.UserId == selectedUserId then
				return profile
			end
		end
		return nil
	end, { profiles :: any, selectedUserId })

	local openPosition = props.Position or UDim2.new()
	local frameRef, initialPosition, close = useSlide(
		openPosition,
		openPosition - SLIDE_OFFSET,
		SLIDE_TWEEN_INFO,
		function()
			props.OnAction({
				Type = "Exit",
			})
		end
	)

	local tabs: { [string]: React.ReactNode } = {}
	for _, tabInfo in CONSTANTS.TABS do
		tabs[tabInfo.Tab] = e(
			"TextButton",
			{
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.3,
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = tabInfo.Tab == tab and 4 or 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = tabInfo.Position,
				Size = tabInfo.Size,
				Text = tabInfo.Tab,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 2,
				[React.Event.Activated] = function()
					setTab(tabInfo.Tab)
				end,
			} :: RobloxComponents.TextButtonProperties
		)
	end

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			-- a click that lands on the panel isn't one on the world behind it
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.7,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = initialPosition,
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
				Position = UDim2.fromScale(0.05, 0.025),
				Size = UDim2.fromScale(0.9, 0.1),
				Text = "Database",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Tabs = e(React.Fragment, {}, tabs),
			PlayerList = e(
				PlayerList,
				{
					Position = UDim2.fromScale(0.025, 0.15),
					Size = UDim2.fromScale(0.4, 0.8),
					Profiles = profiles,
					Tab = tab,
					SelectedUserId = selectedUserId,
					OnClick = function(profile: PublicProfile)
						setSelectedUserId(profile.UserId)
					end,
				} :: PlayerList.Properties
			),
			ProfilePanel = e(
				ProfilePanel,
				{
					Position = UDim2.fromScale(0.45, 0.15),
					Size = UDim2.fromScale(0.525, 0.8),
					Profile = selectedProfile,
				} :: ProfilePanel.Properties
			),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.fromScale(0, 0),
					ZIndex = 3,
					[React.Event.Activated] = close,
				} :: ExitButton.Properties
			),
		}
	))
end
