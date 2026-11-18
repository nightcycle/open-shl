--!strict
--!native
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CurrencyPopupTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CurrencyPopup/Types")
export type Properties = CurrencyPopupTypes.Properties
-- one gain on its way across the screen
type Gain = {
	Id: number,
	Amount: number,
	Position: UDim2, -- where it comes up: off the middle of the screen by a little
	Rotation: number, -- the tilt it comes up at, in degrees
	Spin: number, -- how much further it turns on its way out
}
-- Constants
local TEXT_COLOR3 = Color3.fromRGB(0, 255, 0)
local TEXT_SIZE = 75
-- the most a gain is thrown off the middle by, in hundredths of the screen
local MAX_OFFSET = 10
local MAX_ROTATION = 20
local MAX_SPIN = 80
-- it pops up where it lands, then makes off for the corner its balance was read in
local POP_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut)
local EXIT_TWEEN_INFO = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local EXIT_POSITION = UDim2.fromScale(1, 0)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- never nothing: a whole number up to the range, to either side about as often
local function getRandom(random: Random, range: number): number
	local value = random:NextInteger(1, range)
	return if random:NextInteger(1, 100) < 50 then -value else value
end

local function gainLabel(props: {
	Gain: Gain,
	FontFace: Font,
	OnDone: (id: number) -> (),
}): React.ReactNode
	local gain = props.Gain
	local labelRef: { current: TextLabel? } = React.useRef(nil :: TextLabel?)
	local onDoneRef = React.useRef(props.OnDone)
	onDoneRef.current = props.OnDone
	React.useEffect(function()
		local inst = labelRef.current
		if not inst then
			return function() end
		end
		local isDead = false
		local popTween = TweenService:Create(inst, POP_TWEEN_INFO, {
			TextSize = TEXT_SIZE,
		})
		local exitTween = TweenService:Create(inst, EXIT_TWEEN_INFO, {
			Position = EXIT_POSITION,
			Rotation = gain.Rotation + gain.Spin,
			TextSize = 0,
			TextTransparency = 1,
		})
		popTween:Play()
		task.spawn(function()
			task.wait(POP_TWEEN_INFO.Time)
			if isDead then
				return
			end
			exitTween:Play()
			task.wait(EXIT_TWEEN_INFO.Time)
			if isDead then
				return
			end
			onDoneRef.current(gain.Id)
		end)
		return function()
			isDead = true
			popTween:Cancel()
			popTween:Destroy()
			exitTween:Cancel()
			exitTween:Destroy()
		end
	end, { gain.Id })

	return e("TextLabel", {
		ref = labelRef,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		FontFace = props.FontFace,
		-- the same value on every render, one that's made anew could put it back where it started
		Position = gain.Position,
		Rotation = gain.Rotation,
		Size = UDim2.fromOffset(10, 10),
		Text = `${gain.Amount}`,
		TextColor3 = TEXT_COLOR3,
		-- it grows out of nothing
		TextSize = 0,
	})
end
-- Class
-- a gain isn't queued or told in a sentence: every one is a number that's thrown at the middle of the screen
return function(props: Properties): React.ReactNode
	local credits = React.useContext(SessionCreditsContext)
	local style = React.useContext(StyleContext)

	local gains, setGains = React.useState(table.freeze({}) :: { Gain })
	local nextIdRef = React.useRef(1)
	-- nil until the session loaded
	local baselineRef: { current: number? } = React.useRef(nil :: number?)
	React.useEffect(function()
		local baseline = baselineRef.current
		if not props.IsLoaded then
			baselineRef.current = nil
			return function() end
		end
		baselineRef.current = credits
		-- what's spent goes without a word
		if not baseline or credits <= baseline then
			return function() end
		end
		local random = Random.new()
		local gain: Gain = table.freeze({
			Id = nextIdRef.current,
			Amount = credits - baseline,
			Position = UDim2.fromScale(
				0.5 + getRandom(random, MAX_OFFSET) / 100,
				0.5 + getRandom(random, MAX_OFFSET) / 100
			),
			Rotation = getRandom(random, MAX_ROTATION),
			Spin = getRandom(random, MAX_SPIN),
		})
		nextIdRef.current += 1
		setGains(function(prior: { Gain }): { Gain }
			local out = table.clone(prior)
			table.insert(out, gain)
			table.freeze(out)
			return out
		end)
		return function() end
	end, { credits :: any, props.IsLoaded })

	local onDone = React.useCallback(function(id: number)
		setGains(function(prior: { Gain }): { Gain }
			local out: { Gain } = {}
			for _, gain in prior do
				if gain.Id ~= id then
					table.insert(out, gain)
				end
			end
			table.freeze(out)
			return out
		end)
	end, {})

	local labels: { [string]: React.ReactNode } = {}
	for _, gain in gains do
		labels[`Gain-{gain.Id}`] = e(gainLabel, {
			Gain = gain,
			FontFace = style.Fonts.Body,
			OnDone = onDone,
		})
	end

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Gains = e(React.Fragment, {}, labels),
		}
	))
end
