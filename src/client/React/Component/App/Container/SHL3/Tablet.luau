--!strict
--!native
-- Services
local ContentProvider = game:GetService("ContentProvider")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
local Tablet = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Tablet")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local PROP_ID = "tablet"
local TABLET = Image["shl-3"].prop.tablet
-- what its screen goes through, round + round. the old gear had four: its first was the picture of a form that asks
-- for a name + a password, its last promised whoever owned the gear a tablet in the mail. both files are landed,
-- putting one back is a line here
local SLIDE_IMAGES: { string } = table.freeze({
	TABLET["slide-2.png"],
	TABLET["slide-3.png"],
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the screen of the tablet, up for as long as the server counts it as in the hand of the local player + they aren't
-- sat in a menu. nobody else sees it + nothing of it is told to the server. it's mounted all along, so it comes
-- back up on the slide it was left on
return function(): React.ReactNode
	local isHeld = useCharacterAttribute(AttributeDefinition.HeldPropId) == PROP_ID
	local isInMenu = useCharacterAttribute(AttributeDefinition.IsInMenu)
	-- the slides are uploads of long ago that aren't the game's: one that doesn't load any more isn't shown, + with
	-- none of them the screen stays dark
	local slideImages: { string }, setSlideImages = React.useState({} :: { string })
	local index, setIndex = React.useState(1)
	local isAskedRef = React.useRef(false)
	local isMountedRef = useIsMounted()
	React.useEffect(function()
		-- asked for the first time it's got out, once
		if not isHeld or isAskedRef.current then
			return function() end
		end
		isAskedRef.current = true
		task.spawn(function()
			local loaded: { string } = {}
			for _, image in SLIDE_IMAGES do
				-- asked for by its id alone an upload of the old place answers as a failure: the id is a decal's,
				-- only something that draws it finds the picture behind it
				local probe = Instance.new("ImageLabel")
				probe.Image = image
				local isLoaded = false
				ContentProvider:PreloadAsync({ probe }, function(_: string, status: Enum.AssetFetchStatus)
					isLoaded = status == Enum.AssetFetchStatus.Success
				end)
				probe:Destroy()
				if isLoaded then
					table.insert(loaded, image)
				end
			end
			if isMountedRef.current then
				setSlideImages(loaded)
			end
		end)
		return function() end
	end, { isHeld })

	if not isHeld or isInMenu then
		return nil
	end
	return e(
		Tablet,
		{
			Size = UDim2.fromScale(1, 1),
			FrameImage = TABLET["frame.png"],
			SlideImage = if #slideImages > 0 then slideImages[(index - 1) % #slideImages + 1] else nil,
			OnAction = function(action: Tablet.ActionInfo)
				if action.Type == "NextSlide" then
					setIndex(index + 1)
				end
			end,
		} :: Tablet.Properties
	)
end
