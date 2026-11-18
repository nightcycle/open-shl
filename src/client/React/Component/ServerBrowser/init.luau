--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local Form = require("@self/Form")
local List = require("@self/List")
local Passcode = require("@self/Passcode")
-- Hooks
-- Contexts
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
export type Listing = ServerType.Listing
export type Settings = ServerType.Settings
export type Entry = ServerType.Entry
export type ActionInfo =
	{
		Type: "Back",
	}
	| {
		Type: "Refresh",
	}
	| {
		Type: "Create",
		Settings: Settings,
	}
	| {
		Type: "Join",
		Entry: Entry,
	}
export type Properties = RobloxComponents.FrameProperties & {
	Listings: { Listing }, -- already in the order they are shown in
	IsBusy: boolean, -- a join or a create is on its way: nothing but the background shows
	Notice: string?, -- why the last try fell through
	FilterText: (text: string) -> string, -- yields
	OnAction: (ActionInfo) -> (),
}
type View = "List" | "Form"
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local view: View, setView: (View) -> () = React.useState("List" :: View)
	-- the server an entry code is being asked for
	local lockedId: string?, setLockedId: (string?) -> () = React.useState(nil :: string?)
	local code: string, setCode: (string) -> () = React.useState("")
	-- an answer that comes in while a code is being asked for is given where the code was typed
	React.useEffect(function()
		if lockedId and props.Notice and not props.IsBusy then
			setCode(props.Notice)
		end
		return function() end
	end, { props.Notice :: any, props.IsBusy })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
			}),

			Background = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(31, 31, 31),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 2,
			}, {
				UIPadding = e("UIPadding", {
					PaddingBottom = UDim.new(0, 20),
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
					PaddingTop = UDim.new(0, 20),
				}),
				-- the list is kept around under the form, so it's still scrolled to where it was left
				List = e(
					List,
					{
						Size = UDim2.fromScale(1, 1),
						Visible = view == "List" and not props.IsBusy,
						Listings = props.Listings,
						Notice = if lockedId then nil else props.Notice,
						OnBack = function()
							props.OnAction({
								Type = "Back",
							})
						end,
						OnRefresh = function()
							props.OnAction({
								Type = "Refresh",
							})
						end,
						OnCreate = function()
							setView("Form")
						end,
						OnJoin = function(listing: Listing)
							if listing.Fill >= listing.Limit then
								return
							end
							if listing.IsLocked then
								setCode("")
								setLockedId(listing.Id)
							else
								props.OnAction({
									Type = "Join",
									Entry = {
										Id = listing.Id,
										Code = "",
									},
								})
							end
						end,
					} :: List.Properties
				),
				-- a form that's opened anew starts out blank
				Form = view == "Form" and e(
					Form,
					{
						Size = UDim2.fromScale(1, 1),
						Visible = not props.IsBusy,
						Notice = props.Notice,
						FilterText = props.FilterText,
						OnBack = function()
							setView("List")
						end,
						OnDone = function(settings: Settings)
							props.OnAction({
								Type = "Create",
								Settings = settings,
							})
						end,
					} :: Form.Properties
				),
				Passcode = lockedId and e(
					Passcode,
					{
						Size = UDim2.fromScale(1, 1),
						Visible = not props.IsBusy,
						ZIndex = 2,
						Code = code,
						OnChange = setCode,
						OnSubmit = function(text: string)
							props.OnAction({
								Type = "Join",
								Entry = {
									Id = lockedId,
									Code = text,
								},
							})
						end,
						OnBack = function()
							setLockedId(nil)
							setCode("")
						end,
					} :: Passcode.Properties
				),
			}),
		}
	))
end
