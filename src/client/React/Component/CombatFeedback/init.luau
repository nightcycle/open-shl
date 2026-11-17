--!strict
--!native
-- Services
local Lighting = game:GetService("Lighting")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
-- Components
-- Hooks
-- Contexts
local CharacterHealthContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Health")
-- Types
export type ActionInfo = {
	Type: "Hurt",
	Health: number,
}
export type Properties = {
	IsDead: boolean,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local PAIN_FX = {
	TINT_COLOR = Color3.fromRGB(255, 115, 115),
	DURATION = 0.15,
}
local KILL_FX = {
	BRIGHTNESS = 0.25,
	CONTRAST = 1,
	SATURATION = 0.25,
}
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local health = React.useContext(CharacterHealthContext)
	local healthRef = React.useRef(health)
	local onActionRef = React.useRef(props.OnAction)
	onActionRef.current = props.OnAction
	local hurtCount, setHurtCount = React.useState(0)
	local isPainVisible, setIsPainVisible = React.useState(false)
	React.useEffect(function()
		local previousHealth = healthRef.current
		healthRef.current = health
		if health < previousHealth then
			setHurtCount(hurtCount + 1)
			onActionRef.current({
				Type = "Hurt",
				Health = health,
			})
		end
		return function() end
	end, { health })
	-- a hit that lands while the screen is still red keeps it red for a full flash of its own
	React.useEffect(function()
		if hurtCount == 0 then
			return function() end
		end
		setIsPainVisible(true)
		local isDead = false
		task.delay(PAIN_FX.DURATION, function()
			if not isDead then
				setIsPainVisible(false)
			end
		end)
		return function()
			isDead = true
		end
	end, { hurtCount })

	-- nothing of it is interface, the effects live in the lighting of the world
	return ReactRoblox.createPortal(
		e(React.Fragment, {}, {
			PainFX = e("ColorCorrectionEffect", {
				Enabled = isPainVisible,
				TintColor = PAIN_FX.TINT_COLOR,
			}),

			KillFX = e("ColorCorrectionEffect", {
				Enabled = props.IsDead,
				Brightness = KILL_FX.BRIGHTNESS,
				Contrast = KILL_FX.CONTRAST,
				Saturation = KILL_FX.SATURATION,
			}),
		}),
		Lighting
	)
end
