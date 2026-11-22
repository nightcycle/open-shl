--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
-- Hooks
local useAppearance = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAppearance")
local useCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterSelect/useCharacter")
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
-- Types
export type Properties = {
	Index: number,
	WorldModel: WorldModel,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/CONSTANTS")
-- the stock R15 idle
local IDLE_ANIMATION_ID = "rbxassetid://507766388"
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/character-select") :: Folder
-- Private Functions
-- the idle is only there for show, a rig that can't play it stands still
local function playIdle(rig: Model)
	local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = IDLE_ANIMATION_ID
	local success, msg = pcall(function()
		local animator: Animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end)
	animation:Destroy()
	if not success then
		warn(`idle err: {msg}`)
	end
end
-- Class
return function(props: Properties): React.ReactNode?
	local character = useCharacter(props.Index)
	local appearance = if character then character.Identities.Main.Appearance else nil

	-- the scene is built wherever its template stands, so each booth gets a template that was moved to its place
	local template = React.useState(function(): Folder
		local out = SceneTemplate:Clone()
		local offset = Vector3.new(CONSTANTS.BOOTH_WIDTH * props.Index, 0, 0)
		for _, desc in out:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CFrame += offset
			end
		end
		return out
	end)
	React.useEffect(function()
		return function()
			template:Destroy()
		end
	end, {})

	local scene = useScene(template)
	local rig = if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil

	-- the bare booth stands in until the rig of its scene was made, so the row has no hole in it
	React.useEffect(function()
		if scene and scene.IsAlive then
			scene.Instance.Parent = props.WorldModel
			template.Parent = nil
		else
			template.Parent = props.WorldModel
		end
		return function() end
	end, { scene :: any, props.WorldModel, template })

	useAppearance(scene, appearance)

	-- an animation only loads on a rig that's part of the game, by now the scene is under the world model
	React.useEffect(function()
		if rig then
			playIdle(rig)
		end
		-- the track goes when the rig does
		return function() end
	end, { rig })

	return nil
end
