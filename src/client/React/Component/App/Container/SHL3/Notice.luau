--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local Noticed = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/Notice/Noticed")
-- Components
local Notice = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Notice")
-- Hooks
-- Contexts
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a line the server has for this player alone, up for as long as it says: what a prop does to whoever holds it. the
-- old gear put a gui of its own on the screen of its holder + decided there what it said. a line that comes in while
-- one is up takes its place
return function(): React.ReactNode
	local notice: ClientVFXType.Notice?, setNotice: (ClientVFXType.Notice?) -> () =
		React.useState(nil :: ClientVFXType.Notice?)
	React.useEffect(function()
		local thread: thread? = nil
		local connection = Noticed:Connect(function(value: ClientVFXType.Notice)
			if thread then
				task.cancel(thread)
			end
			setNotice(value)
			thread = task.delay(value.Duration, function()
				thread = nil
				setNotice(nil)
			end)
		end)
		return function()
			connection:Disconnect()
			if thread then
				task.cancel(thread)
			end
		end
	end, {})

	return e(
		Notice,
		{
			Size = UDim2.fromScale(1, 1),
			Text = if notice then notice.Text else nil,
			TextColor3 = if notice then notice.Color else nil,
		} :: Notice.Properties
	)
end
