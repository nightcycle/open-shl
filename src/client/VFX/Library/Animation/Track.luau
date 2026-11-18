--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local DEFAULT_FADE_TIME = 0.1
-- Variables
local Animations: { [string]: Animation } = {}
-- outside of a running game nothing moves an animator along, a story has to do it by hand
local SteppedAnimators: { [Animator]: number? } = {}
local StepConnection: RBXScriptConnection? = nil
-- References
-- Private Functions
local function getAnimation(url: string): Animation
	local animation = Animations[url]
	if animation then
		return animation
	end
	local newAnimation = Instance.new("Animation")
	newAnimation.AnimationId = url
	Animations[url] = newAnimation
	return newAnimation
end

local function setStepped(animator: Animator, isStepped: boolean)
	if RunService:IsRunning() then
		return
	end
	local count = (SteppedAnimators[animator] or 0) + (if isStepped then 1 else -1)
	SteppedAnimators[animator] = if count > 0 then count else nil
	if count <= 0 then
		-- left mid-pose it would stay bent out of shape
		pcall(function()
			(animator :: any):StepAnimations(0)
		end)
	end
	if next(SteppedAnimators) == nil then
		if StepConnection then
			StepConnection:Disconnect()
			StepConnection = nil
		end
	elseif not StepConnection then
		StepConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
			for other in SteppedAnimators do
				pcall(function()
					(other :: any):StepAnimations(deltaTime)
				end)
			end
		end)
	end
end
-- Class
local Module = {}

-- a playing track on the avatar + what stops it. no track for an avatar that can't be animated
Module.play = function(
	character: Model?,
	props: ClientVFXType.Animation,
	isLooped: boolean
): (AnimationTrack?, (fadeTime: number?) -> ())
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildWhichIsA("Animator")
	if not humanoid or not animator then
		return nil, function() end
	end
	local definition = VFXAssetDefinition.getAnimation(props.Animation)
	local track = animator:LoadAnimation(getAnimation(definition.Url))
	track.Looped = isLooped
	track.Priority = Enum.AnimationPriority.Action
	track:Play(props.FadeTime or DEFAULT_FADE_TIME, 1, props.Speed or 1)
	setStepped(animator, true)
	local isStopped = false
	return track,
		function(fadeTime: number?)
			if isStopped then
				return
			end
			isStopped = true
			local fadeDuration = fadeTime or props.FadeTime or DEFAULT_FADE_TIME
			track:Stop(fadeDuration)
			-- it's still on its way out for as long as it fades
			task.delay(fadeDuration, setStepped, animator, false)
		end
end

return Module
