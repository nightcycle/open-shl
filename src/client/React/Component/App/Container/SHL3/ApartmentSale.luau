--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ApartmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Apartment")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ApartmentSale = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ApartmentSale")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local ROWS: { ApartmentSale.RowInfo } = {}
for _, row in ApartmentDefinition.list() do
	table.insert(ROWS, table.freeze({ Tier = row.Tier, Text = ApartmentDefinition.getRowText(row) }))
end
table.freeze(ROWS)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the old place had the client look the price up + tell the server what to take. here it only says which flat: the
-- server knows the price, whether it's paid + whether the avatar stands by the salesman, + answers with a yes or with
-- the line that's read in place of his
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	-- the panel is mounted as it opens, so he starts over every time
	local message: string?, setMessage: (string?) -> () = React.useState(nil :: string?)
	local isBusy, setIsBusy = React.useState(false)
	local isBusyRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local function ask(tier: number)
		-- the server answers one ask at a time, a second one would only be turned down
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		setIsBusy(true)
		task.spawn(function()
			local purchaseRes = NetworkService:Invoke(RemoteDefinition.PurchaseApartment, tier)
			if not isMountedRef.current then
				return
			end
			isBusyRef.current = false
			setIsBusy(false)
			-- another flat can be had right after: a dearer one, or a cheaper one after all
			setMessage(if purchaseRes.IsErr then purchaseRes.Value else ApartmentDefinition.RESPONSE)
		end)
	end

	return e(
		ApartmentSale,
		{
			Size = UDim2.fromScale(1, 1),
			Title = ApartmentDefinition.TITLE,
			Text = ApartmentDefinition.PROMPT,
			Rows = ROWS,
			Message = message,
			IsBusy = isBusy,
			OnAction = function(action: ApartmentSale.ActionInfo)
				if action.Type == "Purchase" then
					ask(action.Tier)
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("ApartmentSale")
				end
			end,
		} :: ApartmentSale.Properties
	)
end
