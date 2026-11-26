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
local JobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type JobShift = JobType.JobShift
type Stat = JobType.Stat
export type ActionInfo =
	{
		Type: "Answer", -- a yes or a no to the card that's up
		IsYes: boolean,
	}
	| {
		Type: "Retire", -- the shift is left
	}
export type Properties = RobloxComponents.FrameProperties & {
	Shift: JobShift,
	-- the card only just came up: the two answers are faded + a press on either is one too early
	IsReading: boolean,
	-- a screen that's touched is a small one, the card is set smaller on it
	IsTouch: boolean?,
	OnAction: (ActionInfo) -> (),
}
-- one of the four plates along the top
type MeterInfo = {
	Stat: Stat,
	Image: string,
	-- how far down its plate the window for the bar is, of the height of the meter
	TrackHeight: number,
}
-- Constants
local IMAGES = Image["shl-3"].ui.job
-- the list of the old place went by name, which is this order
local METERS: { MeterInfo } = table.freeze({
	table.freeze({ Stat = "Accomplishments" :: Stat, Image = IMAGES["stat-accomplishments.png"], TrackHeight = 0.52 }),
	table.freeze({ Stat = "Colleagues" :: Stat, Image = IMAGES["stat-colleagues.png"], TrackHeight = 0.5 }),
	table.freeze({ Stat = "Happiness" :: Stat, Image = IMAGES["stat-happiness.png"], TrackHeight = 0.52 }),
	table.freeze({ Stat = "Morality" :: Stat, Image = IMAGES["stat-morality.png"], TrackHeight = 0.5 }),
})
-- a bar is full where a shift is over
local STAT_MAX = 16
local FILL_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
-- everything below is of the screen: a box that's as wide as it's tall on one is a size of the width or of the height
-- alone. the row of meters is 1536 by 115 on a screen that's 1920 wide
local STATS_POSITION = UDim2.fromScale(0.5, 0.03)
local STATS_SIZE = UDim2.fromScale(0.8, 0.06)
local STATS_PADDING = UDim.new(0.025, 0)
-- three times as wide as the row is tall
local METER_SIZE = UDim2.fromScale(3, 0.9)
local NAME_POSITION = UDim2.fromScale(0.05, 0.5)
local NAME_SIZE = UDim2.fromScale(0.6, 0.09)
local NAME_COLOR3 = Color3.fromRGB(131, 131, 131)
local TRACK_SIZE = UDim2.fromScale(0.25, 0.175)
local TRACK_COLOR3 = Color3.fromRGB(14, 113, 156)
-- 756 by 216 on a screen that's 1080 tall
local SCENARIO_POSITION = UDim2.fromScale(0.4996, 0.7688)
local SCENARIO_SIZE = UDim2.fromScale(0.7, 0.2)
local SCENARIO_ART_SIZE = UDim2.fromScale(1.1, 1.1)
local SCENARIO_COLOR3 = Color3.fromRGB(81, 81, 81)
local SCENARIO_TEXT_SIZE = 22
local SCENARIO_TOUCH_TEXT_SIZE = 18
local NO_POSITION = UDim2.fromScale(0.26, 0.769)
local YES_POSITION = UDim2.fromScale(0.74, 0.769)
local ANSWER_SIZE = UDim2.fromScale(0.1, 0.07)
local ANSWER_TAG_SIZE = UDim2.fromScale(0.5491, 0.5555)
-- how see-through the two are while the card is read
local READING_TRANSPARENCY = 0.5
local PAYCHECK_POSITION = UDim2.fromScale(0.499, 0.575)
local PAYCHECK_SIZE = UDim2.fromScale(0.15, 0.05)
local PAYCHECK_ART_SIZE = UDim2.fromScale(1.2, 1.2)
local RETIRE_POSITION = UDim2.fromScale(0.4988, 0.9469)
local RETIRE_SIZE = UDim2.fromScale(0.2, 0.066)
local RETIRE_TAG_SIZE = UDim2.fromScale(0.8, 0.1)
local RETIRE_COLOR3 = Color3.fromRGB(62, 190, 235)
local CENTER = Vector2.new(0.5, 0.5)
local CENTER_POSITION = UDim2.fromScale(0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a picture of the look: a square of the width of its box, about its middle
local function art(props: {
	Image: string,
	Size: UDim2?,
	ImageTransparency: number?,
	children: { [string]: React.ReactNode }?,
}): React.ReactNode
	return e("ImageLabel", {
		AnchorPoint = CENTER,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = props.Image,
		ImageTransparency = props.ImageTransparency,
		Position = CENTER_POSITION,
		Size = props.Size or UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		ZIndex = 1,
	}, props.children)
end

local function meter(props: {
	Info: MeterInfo,
	Value: number,
	FontFace: Font,
}): React.ReactNode
	local info = props.Info
	local size = UDim2.fromScale(1, math.clamp(props.Value / STAT_MAX, 0, 1))
	local barRef: { current: Frame? } = React.useRef(nil :: Frame?)
	-- the bar is only told where it starts out, from there on it grows + shrinks to where it belongs
	local initialSizeRef = React.useRef(size)
	useTween(barRef, FILL_TWEEN_INFO, {
		Size = size,
	}, { props.Value })

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = METER_SIZE,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	}, {
		-- the plate has a window the bar is seen through, so the bar is under it
		Track = e("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = TRACK_COLOR3,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.99, info.TrackHeight),
			Size = TRACK_SIZE,
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 1,
		}, {
			-- every bar is white: the old place meant to light the ones a card moves + painted all of them instead
			Bar = e("Frame", {
				ref = barRef,
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 1),
				Size = initialSizeRef.current,
			}),
		}),
		Plate = e("ImageLabel", {
			AnchorPoint = CENTER,
			BackgroundTransparency = 1,
			Image = info.Image,
			Position = CENTER_POSITION,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 2,
		}),
		Name = e("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			FontFace = props.FontFace,
			Position = NAME_POSITION,
			Size = NAME_SIZE,
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Text = info.Stat,
			TextColor3 = NAME_COLOR3,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = 3,
		}),
	})
end

-- a yes or a no: a picture with a tag on it. the box that's pressed is wider than the tag + lower than the picture
local function answerButton(props: {
	Position: UDim2,
	Image: string,
	Text: string,
	Color: Color3,
	FontFace: Font,
	IsReading: boolean,
	OnPress: () -> (),
}): React.ReactNode
	return e("ImageButton", {
		AnchorPoint = CENTER,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ImageTransparency = 1,
		Position = props.Position,
		Size = ANSWER_SIZE,
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		[React.Event.Activated] = function()
			if not props.IsReading then
				props.OnPress()
			end
		end,
	}, {
		Art = e(art, {
			Image = props.Image,
			ImageTransparency = if props.IsReading then READING_TRANSPARENCY else 0,
		}),
		Tag = e("TextLabel", {
			AnchorPoint = CENTER,
			BackgroundColor3 = props.Color,
			BorderSizePixel = 0,
			FontFace = props.FontFace,
			Position = CENTER_POSITION,
			Size = ANSWER_TAG_SIZE,
			Text = props.Text,
			TextColor3 = WHITE,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = 2,
		}),
	})
end
-- Class
-- the screen of a job of the legacy place: a card with a yes + a no beside it, the four a shift is judged by along
-- the top, what was earned so far + the way out. all of it is there at once, nothing slides or fades in. it shows
-- what it's handed + reports what's pressed: what an answer does is whoever mounts it to say
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local shift = props.Shift
	local values: { [Stat]: number } = {
		Morality = shift.Morality,
		Colleagues = shift.Colleagues,
		Accomplishments = shift.Accomplishments,
		Happiness = shift.Happiness,
	}
	local function answer(isYes: boolean)
		props.OnAction({
			Type = "Answer",
			IsYes = isYes,
		})
	end

	local meters: { [string]: React.ReactNode } = {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = STATS_PADDING,
			SortOrder = Enum.SortOrder.Name,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}
	for _, info in METERS do
		meters[info.Stat] = e(meter, {
			Info = info,
			Value = values[info.Stat],
			FontFace = style.Fonts.Body,
		})
	end

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Stats = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = STATS_POSITION,
				Size = STATS_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, meters),
			Scenario = e("Frame", {
				AnchorPoint = CENTER,
				BackgroundTransparency = 1,
				Position = SCENARIO_POSITION,
				Size = SCENARIO_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}, {
				Art = e(art, {
					Image = IMAGES["scenario-label.png"],
					Size = SCENARIO_ART_SIZE,
				}),
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Body,
					Size = UDim2.fromScale(1, 1),
					Text = shift.Text,
					TextColor3 = SCENARIO_COLOR3,
					TextSize = if props.IsTouch then SCENARIO_TOUCH_TEXT_SIZE else SCENARIO_TEXT_SIZE,
					TextWrapped = true,
					ZIndex = 2,
				}),
			}),
			-- a job that's over has nothing left to answer
			No = not shift.IsOver and e(answerButton, {
				Position = NO_POSITION,
				Image = IMAGES["no.png"],
				Text = "NO",
				Color = style.Palette.Negative,
				FontFace = style.Fonts.Heading,
				IsReading = props.IsReading,
				OnPress = function()
					answer(false)
				end,
			}),
			Yes = not shift.IsOver and e(answerButton, {
				Position = YES_POSITION,
				Image = IMAGES["yes.png"],
				Text = "YES",
				Color = style.Palette.Positive,
				FontFace = style.Fonts.Heading,
				IsReading = props.IsReading,
				OnPress = function()
					answer(true)
				end,
			}),
			Paycheck = e("Frame", {
				AnchorPoint = CENTER,
				BackgroundTransparency = 1,
				Position = PAYCHECK_POSITION,
				Size = PAYCHECK_SIZE,
			}, {
				Art = e(art, {
					Image = IMAGES["paycheck-amount.png"],
					Size = PAYCHECK_ART_SIZE,
				}),
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Body,
					Size = UDim2.fromScale(1, 1),
					Text = `Paycheck: ${shift.Paycheck}`,
					TextColor3 = WHITE,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
				}),
			}),
			-- pressed whenever, a card that's still read doesn't keep anybody
			Retire = e("ImageButton", {
				AnchorPoint = CENTER,
				AutoButtonColor = false,
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				ImageTransparency = 1,
				Position = RETIRE_POSITION,
				Size = RETIRE_SIZE,
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Retire",
					})
				end,
			}, {
				Art = e(art, {
					Image = IMAGES["retire.png"],
				}, {
					Tag = e("TextLabel", {
						AnchorPoint = CENTER,
						BackgroundColor3 = WHITE,
						BorderSizePixel = 0,
						FontFace = style.Fonts.Heading,
						Position = CENTER_POSITION,
						Size = RETIRE_TAG_SIZE,
						Text = "RETIRE",
						TextColor3 = RETIRE_COLOR3,
						TextScaled = true,
						TextWrapped = true,
					}),
				}),
			}),
		}
	))
end
