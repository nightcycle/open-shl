--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
local WalkLock = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/WalkLock")
-- Components
local CombatFeedback = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CombatFeedback")
-- Hooks
local useAttributeValue = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAttributeValue")
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
-- Types
type IdentityKey = SessionActiveIdentityKeyContext.IdentityKey
type WalkLock = WalkLock.WalkLock
type Flinch = {
	WalkLock: WalkLock,
	Track: AnimationTrack?,
	Thread: thread?,
}
export type Properties = {}
-- Constants
local FLINCH = TransitionDefinition.FLINCH
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- an animation that doesn't load here plays nothing
local function playAnimation(humanoid: Humanoid, animationId: string): AnimationTrack?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local success, result = pcall(function(): AnimationTrack
		return animator:LoadAnimation(animation)
	end)
	if not success then
		warn(`animation err: {result}`)
		return nil
	end
	result:Play()
	return result
end

local function stopAnimation(track: AnimationTrack?)
	if track then
		track:Stop()
		track:Destroy()
	end
end

local function endFlinch(flinch: Flinch)
	if flinch.Thread then
		task.cancel(flinch.Thread)
		flinch.Thread = nil
	end
	stopAnimation(flinch.Track)
	local walkLock = flinch.WalkLock
	if walkLock.IsAlive then
		walkLock:Destroy()
	end
end

local function feedback(): React.ReactNode
	local avatar = useLocalCharacter()
	local isDead = useAttributeValue(avatar, AttributeDefinition.IsDead)
	local character = React.useContext(CharacterContext)
	local identityKey: IdentityKey = React.useContext(SessionActiveIdentityKeyContext) :: IdentityKey
	local identity = character.Identities[identityKey]
	local death = identity and identity.Appearance.Transitions.Death
	local deathAnimationId = TransitionDefinition.getDeath(death and death.Style).AnimationId

	React.useEffect(function()
		local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
		if not isDead or not humanoid then
			return function() end
		end
		local track = playAnimation(humanoid, deathAnimationId)
		return function()
			stopAnimation(track)
		end
	end, { isDead :: any, avatar, deathAnimationId })

	local flinchRef: { current: Flinch? } = React.useRef(nil :: Flinch?)
	-- a wince doesn't outlive the avatar it's on
	React.useEffect(function()
		return function()
			local flinch = flinchRef.current
			flinchRef.current = nil
			if flinch then
				endFlinch(flinch)
			end
		end
	end, { avatar })

	return e(
		CombatFeedback,
		{
			IsDead = isDead,
			OnAction = function(action: CombatFeedback.ActionInfo)
				if action.Type == "Hurt" then
					local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
					-- the hit that puts the avatar down is answered by the death instead
					if action.Health <= 0 or not humanoid then
						return
					end
					local previous = flinchRef.current
					if previous then
						endFlinch(previous)
					end
					local animationId = FLINCH.ANIMATION_IDS[Random.new():NextInteger(1, #FLINCH.ANIMATION_IDS)]
					local flinch: Flinch = {
						WalkLock = WalkLock.new(humanoid),
						Track = playAnimation(humanoid, animationId),
						Thread = nil,
					}
					flinch.Thread = task.delay(FLINCH.DURATION, function()
						flinch.Thread = nil
						if flinchRef.current == flinch then
							flinchRef.current = nil
						end
						endFlinch(flinch)
					end)
					flinchRef.current = flinch
				end
			end,
		} :: CombatFeedback.Properties
	)
end
-- Class
return function(): React.ReactNode
	if not ModeDefinition.getIfPVPEnabled() then
		return nil
	end
	return e(feedback, {})
end
