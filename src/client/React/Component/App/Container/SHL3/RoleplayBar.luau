--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EmoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Emote")
local EmoteService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Emote")
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local EnvironmentService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Environment")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local RoleplayBar = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/RoleplayBar")
-- Hooks
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Season = EnvironmentType.Season
type Weather = EnvironmentType.Weather
type TimeOfDay = EnvironmentType.TimeOfDay
type Grade = EnvironmentType.Grade
type Override = EnvironmentType.Override
type EmoteId = EmoteDefinition.EmoteId
type IdentityKey = SessionActiveIdentityKeyContext.IdentityKey
export type Properties = {}
-- Constants
-- the pass the upper row is sold as
local PRODUCT_ID = "gamepasses_advanced-roleplay"
-- the identity that has a mask to take off
local MASKED_IDENTITY_KEY: IdentityKey = "Main"
-- seconds from the hand at the mask until the server is asked for it. nothing of the strip hears a press meanwhile
local MASK_DELAY = 2
-- what each button of the upper row goes through, in the order the old place had them in
local SEASONS: { Season } = EnvironmentDefinition.CLIMATE.Seasons
local TIMES: { TimeOfDay } = table.freeze({ "day" :: TimeOfDay, "dusk", "night", "dawn" })
local WEATHERS: { Weather } = table.freeze({
	"sunny" :: Weather,
	"rain",
	"rainstorm",
	"snow",
	"blizzard",
	"thunder",
	"thunderstorm",
	"cloudy",
	"fog",
})
local GRADES: { Grade } = table.freeze({ "comic" :: Grade, "dark", "dreary", "greenlit", "noir", "normal" })
-- a product is free in studio, the server hands it over. anywhere else it's paid for through the prompt of the engine
local IS_STUDIO = RunService:IsStudio()
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- what a button moves on to: the one after what it shows. whoever holds the last of them is given the server's
-- back, the old place had no way back from a sky of one's own but to leave
local function getNext<V>(values: { V }, shown: V, isHeld: boolean): V?
	local index = table.find(values, shown) or 0
	if isHeld and index == #values then
		return nil
	end
	return values[index % #values + 1]
end

local function getOverride(): Override?
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentService:GetOverride()
end

local function getSeason(): Season
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentService:GetSeason()
end

local function getWeather(): Weather
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentService:GetWeather()
end

local function getIfNight(): boolean
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentService:GetIfNight()
end

local function getGrade(): Grade
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return EnvironmentService:GetGrade()
end

-- holds one thing of the sky at the next of its values, or lets go of all of them past the last
local function hold(override: Override?)
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	if override then
		EnvironmentService:SetOverride(override)
	else
		EnvironmentService:ClearOverride()
	end
end

-- the way the card of the shop asks for a product. what was paid for isn't the business of the client: the row
-- opens once the server wrote that the player has it
local function purchase()
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local definitionRes = ProductDefinition.get(PRODUCT_ID)
	if definitionRes.IsErr then
		warn(`purchase err: {definitionRes.Value}`)
		return
	end
	local definition = definitionRes.Value
	if IS_STUDIO then
		local purchaseRes = NetworkService:Invoke(RemoteDefinition.PurchaseProduct, definition.Id)
		if purchaseRes.IsErr then
			warn(`purchase err: {purchaseRes.Value}`)
		end
		return
	end
	local isPrompted, msg = pcall(function()
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, definition.LegacyId)
	end)
	if not isPrompted then
		warn(`purchase err: {msg}`)
	end
end
-- Class
-- the strip is on the hud of both places, as it was. the emotes are the avatar's own animator, the mask is asked of
-- the server + everything of the upper row is this screen's alone. the old place killed the emotes for as long as
-- the mask was off (the mask shared the latch of a held pose): here the mask is a state + the emotes stay live
return function(): React.ReactNode
	assert(EmoteService.IsInitialized, `the emote service isn't initialized`)
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	local identityKey: IdentityKey = React.useContext(SessionActiveIdentityKeyContext) :: IdentityKey
	local isOwned = usePlayerAttribute(AttributeDefinition.HasAdvancedRoleplay)
	local emoteId: EmoteId? = useSignalState(EmoteService.EmoteChanged, function(): EmoteId?
		return EmoteService:GetEmoteId()
	end) :: EmoteId?
	local isHudHidden = useSignalState(ShellService.HudHiddenChanged, function(): boolean
		return ShellService:GetIsHudHidden()
	end)
	local areNamesHidden = useSignalState(ShellService.NamesHiddenChanged, function(): boolean
		return ShellService:GetAreNamesHidden()
	end)
	local override: Override? = useSignalState(EnvironmentService.OverrideChanged, getOverride) :: Override?
	local season: Season = useSignalState(EnvironmentService.Changed, getSeason) :: Season
	local weather: Weather = useSignalState(EnvironmentService.Changed, getWeather) :: Weather
	local isNight = useSignalState(EnvironmentService.Changed, getIfNight)
	local grade: Grade = useSignalState(EnvironmentService.Changed, getGrade) :: Grade
	-- an hour that's held is the one that's shown, the clock of the server only ever reads as day or night
	local time: TimeOfDay = if override and override.Time then override.Time elseif isNight then "night" else "day"
	local isFolded: boolean, setIsFolded: (boolean) -> () = React.useState(false)
	-- a hand is at the mask
	local isMaskBusyRef = React.useRef(false)
	-- one ask for the pass at a time
	local isPurchasingRef = React.useRef(false)

	local emotes = React.useMemo(function(): { RoleplayBar.EmoteInfo }
		-- a pose that's held takes every other emote off the strip until it's let go of. one that's played once
		-- holds nothing
		local heldRes = if emoteId then EmoteDefinition.get(emoteId) else nil
		local heldId: EmoteId? = if heldRes and heldRes.IsOk and heldRes.Value.IsLooped then heldRes.Value.Id else nil
		local out: { RoleplayBar.EmoteInfo } = {}
		for _, definition in EmoteDefinition.list() do
			table.insert(
				out,
				table.freeze({
					Id = definition.Id,
					Name = definition.Name,
					IsDead = heldId ~= nil and heldId ~= definition.Id,
				})
			)
		end
		table.freeze(out)
		return out
	end, { emoteId })

	-- it's drawn with the hud. whoever put their hud away keeps the one button that brings it back
	if not isGameplayHudVisible and not isHudHidden then
		return nil
	end
	return e(
		RoleplayBar,
		{
			Size = UDim2.fromScale(1, 1),
			Emotes = emotes,
			IsFolded = isFolded,
			IsOwned = isOwned,
			Season = season,
			Time = time,
			Weather = weather,
			Grade = grade,
			AreNamesHidden = areNamesHidden,
			IsHudHidden = isHudHidden,
			OnAction = function(action: RoleplayBar.ActionInfo)
				if action.Type == "Emote" then
					if isMaskBusyRef.current then
						return
					end
					if emoteId == action.Id then
						EmoteService:Stop()
						return
					end
					local emoteRes = EmoteService:Play(action.Id)
					if emoteRes.IsErr then
						warn(`emote err: {emoteRes.Value}`)
					end
				elseif action.Type == "Mask" then
					-- only the hero has one, the server would do nothing for anybody else
					if isMaskBusyRef.current or identityKey ~= MASKED_IDENTITY_KEY then
						return
					end
					local maskRes = EmoteService:PlayMask()
					if maskRes.IsErr then
						warn(`mask err: {maskRes.Value}`)
						return
					end
					isMaskBusyRef.current = true
					local avatar = Players.LocalPlayer.Character
					task.delay(MASK_DELAY, function()
						isMaskBusyRef.current = false
						-- whoever became somebody else meanwhile has no mask to see to
						if not NetworkService.IsInitialized or Players.LocalPlayer.Character ~= avatar then
							return
						end
						-- the server wrote onto the avatar whether it's on: the other way is asked for
						local isMasked = AttributeDefinition.get(avatar, AttributeDefinition.IsMasked)
						NetworkService:Fire(RemoteDefinition.SetMasked, not isMasked)
					end)
				elseif action.Type == "Fold" then
					setIsFolded(not isFolded)
				elseif action.Type == "Buy" then
					if isPurchasingRef.current then
						return
					end
					isPurchasingRef.current = true
					task.spawn(function()
						purchase()
						isPurchasingRef.current = false
					end)
				elseif action.Type == "Season" then
					local isHeld = override ~= nil and override.Season ~= nil
					local nextSeason: Season? = getNext(SEASONS, season, isHeld) :: Season?
					hold(if nextSeason then { Season = nextSeason } :: Override else nil)
				elseif action.Type == "Time" then
					local isHeld = override ~= nil and override.Time ~= nil
					local nextTime: TimeOfDay? = getNext(TIMES, time, isHeld) :: TimeOfDay?
					hold(if nextTime then { Time = nextTime } :: Override else nil)
				elseif action.Type == "Weather" then
					local isHeld = override ~= nil and override.Weather ~= nil
					local nextWeather: Weather? = getNext(WEATHERS, weather, isHeld) :: Weather?
					hold(if nextWeather then { Weather = nextWeather } :: Override else nil)
				elseif action.Type == "Grade" then
					-- the colors go round + round, nothing of the day stands still for them
					local nextGrade: Grade? = getNext(GRADES, grade, false) :: Grade?
					if nextGrade then
						EnvironmentService:SetGrade(nextGrade)
					end
				elseif action.Type == "Names" then
					ShellService:SetNamesHidden(not areNamesHidden)
				elseif action.Type == "HideUi" then
					ShellService:SetHudHidden(true)
				elseif action.Type == "ShowUi" then
					ShellService:SetHudHidden(false)
				end
			end,
		} :: RoleplayBar.Properties
	)
end
