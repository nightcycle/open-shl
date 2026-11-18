--!strict
--!native
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
-- Types
local CurrencyPopupTypes = require("@self/Types")
type BootPhase = AppBootPhaseContext.BootPhase
type Balances = { [PseudoEnum.Currency]: number }
type Gain = {
	Id: number,
	Currency: PseudoEnum.Currency,
	Amount: number,
}
export type Properties = CurrencyPopupTypes.Properties
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local REST_POSITION = UDim2.fromScale(-0.5, 0.2)
local SHOWN_POSITION = UDim2.fromScale(0.3, 0.2)
local GONE_POSITION = UDim2.fromScale(1.1, 0.2)
local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EXIT_DELAY = 2.5
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local credits = React.useContext(SessionCreditsContext)
	local gems = React.useContext(SessionGemsContext)
	local bootPhase: BootPhase = React.useContext(AppBootPhaseContext) :: BootPhase

	local queue, setQueue = React.useState(table.freeze({}) :: { Gain })
	local nextIdRef = React.useRef(1)
	local shownIdRef = React.useRef(0)
	-- nil until the session loaded
	local baselineRef: { current: Balances? } = React.useRef(nil :: Balances?)
	React.useEffect(function()
		local baseline = baselineRef.current
		if not props.IsLoaded then
			baselineRef.current = nil
			return function() end
		end
		local balances: Balances = {
			Credits = credits,
			Gems = gems,
		}
		baselineRef.current = balances
		if not baseline then
			return function() end
		end

		local gains: { Gain } = {}
		for _, currency: PseudoEnum.Currency in PseudoEnum.getEnumItems("Currency") do
			local amount = balances[currency] - baseline[currency]
			if amount > 0 then
				table.insert(
					gains,
					table.freeze({
						Id = nextIdRef.current,
						Currency = currency,
						Amount = amount,
					})
				)
				nextIdRef.current += 1
			end
		end
		if #gains > 0 then
			setQueue(function(prior: { Gain }): { Gain }
				local out = table.clone(prior)
				for _, gain in gains do
					local last: Gain? = out[#out]
					-- fold into the one still waiting so a run of gains is one popup
					if last and last.Currency == gain.Currency and last.Id ~= shownIdRef.current then
						out[#out] = table.freeze({
							Id = last.Id,
							Currency = last.Currency,
							Amount = last.Amount + gain.Amount,
						})
					else
						table.insert(out, gain)
					end
				end
				table.freeze(out)
				return out
			end)
		end
		return function() end
	end, { credits :: any, gems, props.IsLoaded })

	-- wait for the loading screen to be gone
	local current: Gain? = if bootPhase == "Playing" then queue[1] else nil
	local currentId = current and current.Id or 0
	local popupRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local soundRef: { current: Sound? } = React.useRef(nil :: Sound?)
	React.useEffect(function()
		local inst = popupRef.current
		if not current or not inst then
			return function() end
		end
		local isDead = false
		shownIdRef.current = current.Id
		inst.Position = REST_POSITION
		local enterTween = TweenService:Create(inst, TWEEN_INFO, {
			Position = SHOWN_POSITION,
		})
		local exitTween = TweenService:Create(inst, TWEEN_INFO, {
			Position = GONE_POSITION,
		})
		enterTween:Play()
		local sound = soundRef.current
		if sound then
			sound.Volume = CONSTANTS.CURRENCIES[current.Currency].Volume
			sound:Play()
		end
		task.spawn(function()
			task.wait(EXIT_DELAY)
			if isDead then
				return
			end
			exitTween:Play()
			task.wait(TWEEN_INFO.Time)
			if isDead then
				return
			end
			setQueue(function(prior: { Gain }): { Gain }
				local out = table.clone(prior)
				if out[1] and out[1].Id == current.Id then
					table.remove(out, 1)
				end
				table.freeze(out)
				return out
			end)
		end)
		return function()
			isDead = true
			enterTween:Cancel()
			enterTween:Destroy()
			exitTween:Cancel()
			exitTween:Destroy()
		end
	end, { currentId })

	local currencyInfo = current and CONSTANTS.CURRENCIES[current.Currency]
	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Popup = e(
				"Frame",
				{
					ref = popupRef,
					BackgroundTransparency = 1,
					Position = REST_POSITION,
					Size = UDim2.fromScale(0.4, 0.05),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				} :: RobloxComponents.FrameProperties,
				{
					TextLabel = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
						Size = UDim2.fromScale(1, 1),
						Text = if current and currencyInfo then `+{current.Amount} {currencyInfo.Text}` else "",
						TextColor3 = currencyInfo and currencyInfo.TextColor3 or Color3.new(1, 1, 1),
						TextScaled = true,
						TextStrokeColor3 = currencyInfo and currencyInfo.TextStrokeColor3 or Color3.new(),
						TextStrokeTransparency = 0,
					}),
					Sound = e("Sound", {
						ref = soundRef,
						SoundId = CONSTANTS.SOUND_ID,
					}),
				}
			),
		}
	))
end
