--!strict
--!native
-- Services
local Players = game:GetService("Players")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/NameTag")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local usePlayerCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerCharacter")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
type PublicProfile = ProfileType.PublicProfile
-- when the name over somebody gives way to what they tell about themselves
type BioTiming = {
	Range: number, -- how many studs off they have to come for it
	Delay: number, -- seconds from then until it's read
	Duration: number, -- seconds it's read for
	ResetRange: number, -- how far they have to go before coming close counts again
	Interval: number, -- seconds between two looks at how far they are
}
export type Properties = {}
-- Constants
local HEAD_NAME = "Head"
-- a game whose tags only ever name has no row
local BIO_TIMING: BioTiming? = GameDefinition.tune(nil :: BioTiming?, {
	shl3 = {
		Range = 28,
		Delay = 5,
		Duration = 12,
		ResetRange = 100,
		Interval = 1,
	},
})
local NO_BIOS: { [number]: string } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- everybody in the game, a player that is on their way out is already left out
local function usePlayers(): { Player }
	local players: { Player }, setPlayers: ({ Player }) -> () = React.useState(Players:GetPlayers())
	React.useEffect(function()
		local function update(leavingPlayer: Player?)
			local out: { Player } = {}
			for _, player in Players:GetPlayers() do
				if player ~= leavingPlayer then
					table.insert(out, player)
				end
			end
			table.freeze(out)
			setPlayers(out)
		end
		local addedConnection = Players.PlayerAdded:Connect(function()
			update(nil)
		end)
		local removingConnection = Players.PlayerRemoving:Connect(function(player: Player)
			update(player)
		end)
		update(nil)
		return function()
			addedConnection:Disconnect()
			removingConnection:Disconnect()
		end
	end, {})
	return players
end

-- the head isn't there yet when the avatar replicates + is swapped for another when the body is rebuilt
local function useHead(character: Model?): BasePart?
	local head: BasePart?, setHead: (BasePart?) -> () = React.useState(nil :: BasePart?)
	React.useEffect(function()
		if not character then
			setHead(nil)
			return function() end
		end
		local function update()
			local inst = character:FindFirstChild(HEAD_NAME)
			setHead(if inst and inst:IsA("BasePart") then inst else nil)
		end
		local addedConnection = character.ChildAdded:Connect(update)
		local removedConnection = character.ChildRemoved:Connect(update)
		update()
		return function()
			addedConnection:Disconnect()
			removedConnection:Disconnect()
		end
	end, { character })
	return head
end

-- how far somebody is from the avatar of the player, as long as both are there
local function getDistance(character: Model): number?
	local localCharacter = Players.LocalPlayer.Character
	if not localCharacter or not character.Parent or not localCharacter.Parent then
		return nil
	end
	return (character:GetPivot().Position - localCharacter:GetPivot().Position).Magnitude
end

-- somebody who comes close is read up on once, they have to go a good way off before they are again
local function useIsBioShown(character: Model?, bio: string): boolean
	local isShown: boolean, setIsShown: (boolean) -> () = React.useState(false)
	-- kept over the avatars they go through, it's them that was read up on
	local isSeenRef = React.useRef(false)
	React.useEffect(function()
		local timing = BIO_TIMING
		-- whatever was being read was on the avatar before this one
		setIsShown(false)
		if not timing or not character or bio == "" then
			return function() end
		end
		local swapThread: thread? = nil
		local pollThread = task.spawn(function()
			while true do
				task.wait(timing.Interval)
				local distance = getDistance(character)
				if not distance then
					continue
				end
				if distance < timing.Range then
					if not isSeenRef.current then
						isSeenRef.current = true
						swapThread = task.delay(timing.Delay, function()
							setIsShown(true)
							task.wait(timing.Duration)
							swapThread = nil
							setIsShown(false)
						end)
					end
				elseif distance > timing.ResetRange then
					isSeenRef.current = false
				end
			end
		end)
		return function()
			task.cancel(pollThread)
			if swapThread then
				task.cancel(swapThread)
			end
		end
	end, { character :: any, bio })
	return isShown
end

local function playerTag(props: {
	Player: Player,
	Bio: string,
}): React.ReactNode
	local character = usePlayerCharacter(props.Player)
	local head = useHead(character)
	local isBioShown = useIsBioShown(character, props.Bio)
	local personaName = useAttributeValue(character, AttributeDefinition.PersonaName)
	local isInMenu = useAttributeValue(character, AttributeDefinition.IsInMenu)
	local isNameHidden = useAttributeValue(character, AttributeDefinition.IsNameHidden)
	-- a name over an avatar that's out of sight would say where it is
	if not head or isNameHidden then
		return nil
	end
	return e(
		NameTag,
		{
			Adornee = head,
			PersonaName = personaName,
			UserName = props.Player.Name,
			IsInMenu = isInMenu,
			Bio = if isBioShown then props.Bio else nil,
		} :: NameTag.Properties
	)
end

local function tags(props: {
	Bios: { [number]: string },
}): React.ReactNode
	local players = usePlayers()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end

	local children: { [string]: React.ReactNode } = {}
	for _, player in players do
		if player == localPlayer then
			continue
		end
		children[`NameTag-{player.UserId}`] = e(playerTag, {
			Player = player,
			Bio = props.Bios[player.UserId] or "",
		})
	end
	-- a billboard doesn't show from inside of the app's ScreenGui, so the tags sit in the PlayerGui
	return ReactRoblox.createPortal(e(React.Fragment, {}, children), playerGui)
end

-- what everybody tells about themselves comes with the profiles the session keeps
local function tagsWithBios(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local profiles = useSignalState(SessionService.ProfilesChanged, function(): { PublicProfile }
		return SessionService:GetProfiles()
	end)
	local bios = React.useMemo(function(): { [number]: string }
		local out: { [number]: string } = {}
		for _, profile in profiles do
			out[profile.UserId] = profile.Backstory
		end
		table.freeze(out)
		return out
	end, { profiles })

	return e(tags, {
		Bios = bios,
	})
end
-- Class
return function(): React.ReactNode
	if not BIO_TIMING then
		return e(tags, {
			Bios = NO_BIOS,
		})
	end
	return e(tagsWithBios, {})
end
