--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type Listing = ParentComponent.Listing
-- Constants
local MAX_LISTINGS = 40
local FILTER_DURATION = 0.5
local NAMES = {
	"Cool People Hangout Server",
	"RP",
	"The city that never sleeps: serious roleplay only, no powers in the lobby, read the rules before you join",
	"Villains Only",
	"Unnamed Server",
}
local REGIONS = { "us", "gb", "", "br", "de", "jp" }
local LIMITS = { 12, 50, 6 }
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newListing(index: number): Listing
	local limit = LIMITS[(index - 1) % #LIMITS + 1]
	local out: Listing = {
		Id = `server-{index}`,
		Name = NAMES[(index - 1) % #NAMES + 1],
		OwnerName = `Player{index}`,
		Region = REGIONS[(index - 1) % #REGIONS + 1],
		IsLocked = index % 3 == 0,
		IsPVP = index % 2 == 0,
		Fill = if index % 4 == 0 then limit else (index * 5) % limit,
		Limit = limit,
	}
	table.freeze(out)
	return out
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		ListingCount = UILabs.Slider(8, 0, MAX_LISTINGS, 1),
		IsBusy = UILabs.Boolean(false),
		Notice = UILabs.String(""),
	},
}, function(props)
	local listingCount: number = props.controls.ListingCount
	local notice: string = props.controls.Notice
	local listings = React.useMemo(function(): { Listing }
		local out: { Listing } = {}
		for i = 1, listingCount do
			table.insert(out, newListing(i))
		end
		table.freeze(out)
		return out
	end, { listingCount })

	return e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Listings = listings,
			IsBusy = props.controls.IsBusy,
			Notice = if notice ~= "" then notice else nil,
			FilterText = function(text: string): string
				task.wait(FILTER_DURATION)
				return text
			end,
			OnAction = function(action: ParentComponent.ActionInfo)
				print(`action`, action)
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)
end)
