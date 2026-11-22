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
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
local NameTag = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/NameTag")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local usePlayerCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerCharacter")
local usePlayers = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayers")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
type IdentityKey = CharacterType.IdentityKey
type TeamId = CombatType.TeamId
type PublicProfile = ProfileType.PublicProfile
-- when the name over somebody gives way to what they tell about themselves
type BioTiming = {
	Range: number, -- how many studs off they have to come for it
	Delay: number, -- seconds from then until it's read
	Duration: number, -- seconds it's read for
	ResetRange: number, -- how far they have to go before coming close counts again
	Interval: number, -- seconds between two looks at how far they are
}
-- what's read with a name by whether its player sat fights out
type ModeTexts = {
	Peaceful: string,
	Fighting: string,
}
export type Properties = {}
-- Constants
local HEAD_NAME = "Head"
-- the identity that's known by the side it's on. the other one wearing its color would give away who it is
local SIDED_IDENTITY_KEY: IdentityKey = "Main"
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
-- what the name of a hero is written in, by the side they picked. a side without a row + a game without a table are
-- in the color of the look
local ALIGNMENT_COLORS: { [PseudoEnum.Alignment]: Color3 }? =
	GameDefinition.tune(nil :: { [PseudoEnum.Alignment]: Color3 }?, {
		-- it told the sides apart in a column of the player list + had no colors for them: these are the blue + the
		-- red at the top of the grid its costumes are colored from
		shl1 = {
			LawfulGood = Color3.fromRGB(13, 105, 172),
			NeutralGood = Color3.fromRGB(13, 105, 172),
			ChaoticGood = Color3.fromRGB(13, 105, 172),
			LawfulEvil = Color3.fromRGB(196, 40, 28),
			NeutralEvil = Color3.fromRGB(196, 40, 28),
			ChaoticEvil = Color3.fromRGB(196, 40, 28),
		},
	})
local NO_ALIGNMENTS: { [number]: PseudoEnum.Alignment } = table.freeze({})
-- what a name is written in by the side its avatar came in on, where the server puts everybody on one. an avatar
-- without a side + a game without a table are in the color of the look
local TEAM_COLORS: { [TeamId]: Color3 }? = GameDefinition.tune(nil :: { [TeamId]: Color3 }?, {
	-- the blue + the red its name label had for the two
	shl3 = {
		Heroes = Color3.fromRGB(0, 0, 255),
		Villains = Color3.fromRGB(255, 0, 0),
	},
})
-- only a game where who fights is each player's own pick says which they picked
local MODE_TEXTS: ModeTexts? = GameDefinition.tune(nil :: ModeTexts?, {
	-- the words its player list had for the two
	shl1 = {
		Peaceful = "RP",
		Fighting = "PVP",
	},
})
-- Variables
-- References
-- Private Functions
local e = React.createElement

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
	Alignment: PseudoEnum.Alignment?,
}): React.ReactNode
	local character = usePlayerCharacter(props.Player)
	local head = useHead(character)
	local isBioShown = useIsBioShown(character, props.Bio)
	local personaName = useAttributeValue(character, AttributeDefinition.PersonaName)
	local isInMenu = useAttributeValue(character, AttributeDefinition.IsInMenu)
	local isNameHidden = useAttributeValue(character, AttributeDefinition.IsNameHidden)
	local identityKey = useAttributeValue(character, AttributeDefinition.IdentityKey)
	local isPeaceful = useAttributeValue(character, AttributeDefinition.IsPeaceful)
	local teamId: TeamId? = useAttributeValue(character, AttributeDefinition.TeamId)
	-- a name over an avatar that's out of sight would say where it is
	if not head or isNameHidden then
		return nil
	end
	-- the side the server put the avatar on comes before the one its player says they're on: a game has the one or
	-- the other
	local sideColor3: Color3? = nil
	if identityKey == SIDED_IDENTITY_KEY then
		if TEAM_COLORS and teamId then
			sideColor3 = TEAM_COLORS[teamId]
		elseif ALIGNMENT_COLORS and props.Alignment then
			sideColor3 = ALIGNMENT_COLORS[props.Alignment]
		end
	end
	return e(
		NameTag,
		{
			Adornee = head,
			PersonaName = personaName,
			UserName = props.Player.Name,
			IsInMenu = isInMenu,
			Bio = if isBioShown then props.Bio else nil,
			TeamColor3 = sideColor3,
			Mode = if MODE_TEXTS then (if isPeaceful then MODE_TEXTS.Peaceful else MODE_TEXTS.Fighting) else nil,
		} :: NameTag.Properties
	)
end

local function tags(props: {
	Bios: { [number]: string },
	Alignments: { [number]: PseudoEnum.Alignment },
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
			Alignment = props.Alignments[player.UserId],
		})
	end
	-- a billboard doesn't show from inside of the app's ScreenGui, so the tags sit in the PlayerGui
	return ReactRoblox.createPortal(e(React.Fragment, {}, children), playerGui)
end

-- what everybody tells about themselves + the side they're on come with the profiles the session keeps
local function tagsWithProfiles(): React.ReactNode
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
	local alignments = React.useMemo(function(): { [number]: PseudoEnum.Alignment }
		local out: { [number]: PseudoEnum.Alignment } = {}
		for _, profile in profiles do
			out[profile.UserId] = profile.Alignment
		end
		table.freeze(out)
		return out
	end, { profiles })

	return e(tags, {
		Bios = bios,
		Alignments = alignments,
	})
end
-- Class
return function(): React.ReactNode
	-- a game that reads neither off the profiles doesn't wait on the session for its tags
	if not BIO_TIMING and not ALIGNMENT_COLORS then
		return e(tags, {
			Bios = NO_BIOS,
			Alignments = NO_ALIGNMENTS,
		})
	end
	return e(tagsWithProfiles, {})
end
