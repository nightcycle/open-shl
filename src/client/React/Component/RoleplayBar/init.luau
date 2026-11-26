--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type Season = EnvironmentType.Season
type Weather = EnvironmentType.Weather
type TimeOfDay = EnvironmentType.TimeOfDay
type Grade = EnvironmentType.Grade
type EmoteId = RoleplayType.EmoteId
-- a button of the lower row
export type EmoteInfo = {
	Id: EmoteId,
	Name: string,
	-- its words are gone + a press of it does nothing, the way every other one is while a pose is held
	IsDead: boolean?,
}
export type ActionInfo =
	{
		Type: "Emote",
		Id: EmoteId,
	}
	| {
		Type: "Mask",
	}
	| {
		Type: "Fold", -- the tab under the strip
	}
	| {
		Type: "Buy", -- a press anywhere on the upper row of somebody who doesn't own it
	}
	| {
		Type: "Season",
	}
	| {
		Type: "Time",
	}
	| {
		Type: "Weather",
	}
	| {
		Type: "Grade",
	}
	| {
		Type: "Names",
	}
	| {
		Type: "HideUi",
	}
	| {
		Type: "ShowUi",
	}
export type Properties = RobloxComponents.FrameProperties & {
	Emotes: { EmoteInfo },
	-- the strip is up out of sight, all but its tab
	IsFolded: boolean,
	-- the upper row is this player's to use, without it all of it is one button that sells it
	IsOwned: boolean,
	-- what the screen of the player shows, each button of the upper row moves on from it
	Season: Season,
	Time: TimeOfDay,
	Weather: Weather,
	Grade: Grade,
	AreNamesHidden: boolean,
	-- nothing of the strip is drawn but the button that brings everything back
	IsHudHidden: boolean,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local ART = Image["shl-3"].ui["rp-top-bar"]
local SEASON_ICONS: { [Season]: string } = table.freeze({
	summer = ART["season-summer.png"],
	autumn = ART["season-autumn.png"],
	winter = ART["season-winter.png"],
	spring = ART["season-spring.png"],
})
local TIME_ICONS: { [TimeOfDay]: string } = table.freeze({
	day = ART["time-day.png"],
	dusk = ART["time-dusk.png"],
	night = ART["time-night.png"],
	dawn = ART["time-dawn.png"],
})
local WEATHER_ICONS: { [Weather]: string } = table.freeze({
	sunny = ART["weather-sunny.png"],
	rain = ART["weather-rain.png"],
	rainstorm = ART["weather-rainstorm.png"],
	snow = ART["weather-snow.png"],
	blizzard = ART["weather-blizzard.png"],
	thunder = ART["weather-thunder.png"],
	thunderstorm = ART["weather-thunderstorm.png"],
	cloudy = ART["weather-cloudy.png"],
	fog = ART["weather-fog.png"],
})
local MASK_TEXT = "Mask"
local HIDE_UI_TEXT = "Hide UI"
local SHOW_UI_TEXT = "Show UI"
local HIDE_NAMES_TEXT = "Hide Names"
local SHOW_NAMES_TEXT = "Show Names"
-- the grey of everything that's pressed on the strip, a shade off the one the rest of the look is read in
local BUTTON_TEXT_COLOR3 = Color3.fromRGB(115, 115, 115)
-- every position below is where a thing is while the strip is down, + where it goes as the strip is folded up
-- the art is a square a good deal taller than the strip drawn in it, hung so that the strip lies along the top edge
local BACKGROUND_SIZE = UDim2.fromScale(1.12, 1.12)
local BACKGROUND_ANCHOR_POINT = Vector2.new(0.5, 0.425)
local BACKGROUND_POSITION = UDim2.fromScale(0.5, 0)
local BACKGROUND_FOLDED_POSITION = UDim2.fromScale(0.5, -0.14)
-- the upper row, the one that's sold
local ADVANCED_SIZE = UDim2.fromScale(0.515, 0.033)
local ADVANCED_POSITION = UDim2.fromScale(0.5, 0.017)
local ADVANCED_FOLDED_POSITION = UDim2.fromScale(0.5, -0.12)
-- what's in it is laid out on a box 32 times as wide as the row is high, whatever the shape of the screen
local ADVANCED_BOX_SIZE = UDim2.fromScale(32, 1)
-- the lower row: the mask + the emotes, six to a row
local BAR_SIZE = UDim2.fromScale(0.75, 0.032)
local BAR_POSITION = UDim2.fromScale(0.5, 0.09)
local BAR_FOLDED_POSITION = UDim2.fromScale(0.5, -0.05)
local BAR_PADDING = UDim.new(0, 2)
local EMOTE_SIZE = UDim2.new(0.167, -2, 0.95, 0)
local EMOTE_LABEL_SIZE = UDim2.fromScale(1, 0.75)
local EMOTE_LABEL_POSITION = UDim2.fromScale(0.5, 0.55)
-- nothing of the tab is drawn here, it's part of the art: this is the press over it
local TAB_SIZE = UDim2.fromOffset(180, 16)
local TAB_POSITION = UDim2.fromScale(0.499, 0.14)
local TAB_FOLDED_POSITION = UDim2.fromScale(0.499, 0)
local FOLD_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TAB_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local SHOW_UI_SIZE = UDim2.new(0.059, 0, 0, 20)
local SHOW_UI_COLOR3 = Color3.new(0, 0, 0)
-- the text buttons of the upper row hang from a twentieth down it
local TEXT_BUTTON_Y = 0.05
local TEXT_BUTTON_HEIGHT = 0.9
-- the blue tags + the square a picture button is pressed on sit a little under + on the middle of it
local TAG_Y = 0.535
local TAG_HEIGHT = 0.8
local ICON_BUTTON_SIZE = UDim2.fromScale(2, 2)
local ICON_SIZE = UDim2.fromScale(0.7, 0.7)
-- a blank piece of the blue behind the picture of the time
local COVER_POSITION = UDim2.fromScale(0.4248, 0.5)
local COVER_SIZE = UDim2.fromScale(0.0534, 1.4)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a tag of the upper row: what the button to its right changes
local function tag(props: {
	Text: string,
	X: number,
	Width: number,
}): React.ReactNode
	local style = React.useContext(StyleContext)
	return e("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = style.Palette.Accent,
		BorderSizePixel = 0,
		FontFace = style.Fonts.Heading,
		Position = UDim2.fromScale(props.X, TAG_Y),
		Size = UDim2.fromScale(props.Width, TAG_HEIGHT),
		-- the space keeps the word off the picture it's the tag of
		Text = `{props.Text} `,
		TextColor3 = style.Palette.TextOnAccent,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
end

-- a button of the upper row that shows what it's at as a picture
local function iconButton(props: {
	Image: string,
	X: number,
	OnClick: () -> (),
}): React.ReactNode
	return e("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(props.X, 0.5),
		Size = ICON_BUTTON_SIZE,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 2,
		[React.Event.Activated] = props.OnClick,
	}, {
		Icon = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Image,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = ICON_SIZE,
		}),
	})
end

-- + one that says it
local function textButton(props: {
	Text: string,
	X: number,
	Width: number,
	OnClick: () -> (),
}): React.ReactNode
	local style = React.useContext(StyleContext)
	return e("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = style.Fonts.Body,
		Position = UDim2.fromScale(props.X, TEXT_BUTTON_Y),
		Size = UDim2.fromScale(props.Width, TEXT_BUTTON_HEIGHT),
		Text = props.Text,
		TextColor3 = BUTTON_TEXT_COLOR3,
		TextScaled = true,
		TextWrapped = true,
		ZIndex = 2,
		[React.Event.Activated] = props.OnClick,
	})
end

local function emoteButton(props: {
	LayoutOrder: number,
	Text: string,
	IsDead: boolean?,
	OnClick: () -> (),
}): React.ReactNode
	local style = React.useContext(StyleContext)
	return e("TextButton", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Size = EMOTE_SIZE,
		Text = "",
		[React.Event.Activated] = function()
			if not props.IsDead then
				props.OnClick()
			end
		end,
	}, {
		Label = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = EMOTE_LABEL_POSITION,
			Size = EMOTE_LABEL_SIZE,
			Text = props.Text,
			TextColor3 = BUTTON_TEXT_COLOR3,
			-- the old place took the words off a button it wouldn't hear, that's all there ever was to see of it
			TextTransparency = if props.IsDead then 1 else 0,
			TextScaled = true,
			TextWrapped = true,
		}),
	})
end

-- the first letter of what a button is at is written large
local function capitalize(text: string): string
	return `{string.upper(string.sub(text, 1, 1))}{string.sub(text, 2)}`
end
-- Class
-- the strip of the third game along the top of the screen: an upper row that's sold, with what a player has their own
-- screen show of the season, the hour, the weather + the colors, + a lower row with the mask + the emotes. the tab
-- under it folds all of it up out of sight. it opens nothing + knows of nothing: every press is an action
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local isFolded = props.IsFolded
	local onAction = props.OnAction

	local backgroundRef: { current: ImageLabel? } = React.useRef(nil :: ImageLabel?)
	local advancedRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local barRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local tabRef: { current: TextButton? } = React.useRef(nil :: TextButton?)
	-- each piece is only told where it starts out, from there on it slides to where it belongs
	local isFoldedAtFirstRef = React.useRef(isFolded)
	-- while nothing of the strip is drawn there's nothing to slide: it comes back the way it was left
	if props.IsHudHidden then
		isFoldedAtFirstRef.current = isFolded
	end
	local isFoldedAtFirst = isFoldedAtFirstRef.current
	local deps = { isFolded, props.IsHudHidden }
	useTween(backgroundRef, FOLD_TWEEN_INFO, {
		Position = if isFolded then BACKGROUND_FOLDED_POSITION else BACKGROUND_POSITION,
	}, deps)
	useTween(advancedRef, FOLD_TWEEN_INFO, {
		Position = if isFolded then ADVANCED_FOLDED_POSITION else ADVANCED_POSITION,
	}, deps)
	useTween(barRef, FOLD_TWEEN_INFO, {
		Position = if isFolded then BAR_FOLDED_POSITION else BAR_POSITION,
	}, deps)
	useTween(tabRef, TAB_TWEEN_INFO, {
		Position = if isFolded then TAB_FOLDED_POSITION else TAB_POSITION,
	}, deps)

	if props.IsHudHidden then
		return e(RobloxComponents.Frame(
			{
				Active = false,
				BackgroundTransparency = 1,
			},
			props,
			{
				ShowUI = e("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = SHOW_UI_COLOR3,
					BorderSizePixel = 0,
					FontFace = style.Fonts.Note,
					Position = UDim2.fromScale(0.5, 0),
					Size = SHOW_UI_SIZE,
					Text = SHOW_UI_TEXT,
					TextColor3 = style.Palette.TextOnAccent,
					TextScaled = true,
					TextWrapped = true,
					[React.Event.Activated] = function()
						onAction({
							Type = "ShowUi",
						})
					end,
				}),
			}
		))
	end

	local emoteButtons: { [string]: React.ReactNode } = {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = BAR_PADDING,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		UIPadding = e("UIPadding", {
			PaddingLeft = BAR_PADDING,
			PaddingRight = BAR_PADDING,
		}),
		-- the mask isn't an emote, it stays live through every one of them
		Mask = e(emoteButton, {
			LayoutOrder = 0,
			Text = MASK_TEXT,
			OnClick = function()
				onAction({
					Type = "Mask",
				})
			end,
		}),
	}
	for i, emote in props.Emotes do
		emoteButtons[emote.Id] = e(emoteButton, {
			LayoutOrder = i,
			Text = emote.Name,
			IsDead = emote.IsDead,
			OnClick = function()
				onAction({
					Type = "Emote",
					Id = emote.Id,
				})
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Background = e("ImageLabel", {
				ref = backgroundRef,
				AnchorPoint = BACKGROUND_ANCHOR_POINT,
				BackgroundTransparency = 1,
				Image = ART["background.png"],
				Position = if isFoldedAtFirst then BACKGROUND_FOLDED_POSITION else BACKGROUND_POSITION,
				Size = BACKGROUND_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 1,
			}),
			Advanced = e("Frame", {
				ref = advancedRef,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = if isFoldedAtFirst then ADVANCED_FOLDED_POSITION else ADVANCED_POSITION,
				Size = ADVANCED_SIZE,
				ZIndex = 2,
			}, {
				Box = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = ADVANCED_BOX_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
				}, {
					HideUI = e(textButton, {
						Text = HIDE_UI_TEXT,
						X = 0.063,
						Width = 0.09,
						OnClick = function()
							onAction({
								Type = "HideUi",
							})
						end,
					}),
					SeasonTag = e(tag, {
						Text = "SEASON",
						X = 0.2041,
						Width = 0.1341,
					}),
					Season = e(iconButton, {
						Image = SEASON_ICONS[props.Season],
						X = 0.293,
						OnClick = function()
							onAction({
								Type = "Season",
							})
						end,
					}),
					TimeTag = e(tag, {
						Text = "TIME",
						X = 0.36,
						Width = 0.0714,
					}),
					TimeCover = e("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = style.Palette.Accent,
						BorderSizePixel = 0,
						Position = COVER_POSITION,
						Size = COVER_SIZE,
					}),
					Time = e(iconButton, {
						Image = TIME_ICONS[props.Time],
						X = 0.42,
						OnClick = function()
							onAction({
								Type = "Time",
							})
						end,
					}),
					WeatherTag = e(tag, {
						Text = "WEATHER",
						X = 0.4945,
						Width = 0.1052,
					}),
					Weather = e(iconButton, {
						Image = WEATHER_ICONS[props.Weather],
						X = 0.572,
						OnClick = function()
							onAction({
								Type = "Weather",
							})
						end,
					}),
					GradeTag = e(tag, {
						Text = "THEME",
						X = 0.6546,
						Width = 0.0989,
					}),
					Grade = e(textButton, {
						Text = capitalize(props.Grade),
						X = 0.769,
						Width = 0.096,
						OnClick = function()
							onAction({
								Type = "Grade",
							})
						end,
					}),
					Names = e(textButton, {
						Text = if props.AreNamesHidden then SHOW_NAMES_TEXT else HIDE_NAMES_TEXT,
						X = 0.932,
						Width = 0.118,
						OnClick = function()
							onAction({
								Type = "Names",
							})
						end,
					}),
				}),
				-- nothing says the row is for sale: it lies over all of it + takes every press, as it always did
				Buy = not props.IsOwned and e("TextButton", {
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.fromScale(1, 1),
					Text = "",
					ZIndex = 3,
					[React.Event.Activated] = function()
						onAction({
							Type = "Buy",
						})
					end,
				}),
			}),
			Bar = e("Frame", {
				ref = barRef,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = if isFoldedAtFirst then BAR_FOLDED_POSITION else BAR_POSITION,
				Size = BAR_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 2,
			}, emoteButtons),
			Tab = e("TextButton", {
				ref = tabRef,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = if isFoldedAtFirst then TAB_FOLDED_POSITION else TAB_POSITION,
				Size = TAB_SIZE,
				Text = "",
				ZIndex = 3,
				[React.Event.Activated] = function()
					onAction({
						Type = "Fold",
					})
				end,
			}),
		}
	))
end
