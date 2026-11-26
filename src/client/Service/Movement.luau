--!strict
-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
local VFXService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Handle = VFXType.Handle
-- the avatar of somebody in the game, + what lets it hang loose while it's down
type Body = {
	Character: Model?,
	Handle: Handle?,
	Connections: { RBXScriptConnection },
	CharacterConnections: { RBXScriptConnection },
}
type MovementServiceImpl = {
	__index: MovementServiceImpl,
	GetIfSprinting: (self: MovementService) -> boolean,
	-- goes from the walk to the run or back, the way a press of shift does
	ToggleSprint: (self: MovementService) -> Result<true, string>,
	-- pushes the avatar up from where it is in the air, the way a second jump does
	Lift: (self: MovementService) -> Result<true, string>,
}
export type MovementService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_SprintedAt: number,
		_LiftedAt: number,
		_Bodies: { [Player]: Body },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: MovementServiceImpl
))
-- Constants
-- the numbers of the third game, the only one whose bodies move by more than the engine gives them
-- studs a second of a run. the walk it goes back to is the pace every avatar of the place starts out at
local SPRINT_SPEED = 28
-- an avatar that's slower or faster than these isn't at a pace of its own: it's rooted, or a power has it running
local MIN_OWN_SPEED = 2
local MAX_OWN_SPEED = 40
-- seconds a press of shift is deaf for after one that counted
local SPRINT_COOLDOWN = 1
local SPRINT_KEY_CODES: { [Enum.KeyCode]: true } = table.freeze({
	[Enum.KeyCode.LeftShift] = true :: true,
	[Enum.KeyCode.RightShift] = true :: true,
})
-- the second jump: studs a second the root is brought up to, what it's pushed with, + for how long
local LIFT_SPEED = 30
local LIFT_MAX_FORCE = 20000
local LIFT_POWER = 1250
local LIFT_DURATION = 0.3
-- seconds until the next one
local LIFT_COOLDOWN = 1
local LIFT_NAME = "DoubleJumpVelocity"
-- an avatar that leaves the ground faster than this has a power out that jumps for it
local MAX_OWN_JUMP_POWER = 50
-- the states of a body that's in the air on its own legs: one that flies or is thrown is in neither
local AIRBORNE_STATES: { [Enum.HumanoidStateType]: true } = table.freeze({
	[Enum.HumanoidStateType.Jumping] = true :: true,
	[Enum.HumanoidStateType.Freefall] = true :: true,
})
-- studs a second a body is knocked about by at most as it goes limp
local RAGDOLL_SHOVE = 15
-- the one death every body of the game dies. a game whose editor has a page of them has none that goes limp: which
-- one somebody else picked isn't known on this client
local IS_DEATH_LIMP = TransitionDefinition.getDeath(nil).Motion == "Limp"
-- Variables
-- References
-- Private Functions
-- the humanoid of the player's own avatar, as long as it's up
local function getHumanoid(): Humanoid?
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
		return nil
	end
	return humanoid
end

local function stand(body: Body)
	local handle = body.Handle
	body.Handle = nil
	if handle then
		handle.Stop()
	end
end

local function setCharacter(body: Body, character: Model?)
	for _, v in body.CharacterConnections do
		v:Disconnect()
	end
	table.clear(body.CharacterConnections)
	stand(body)
	body.Character = character
	if not character then
		return
	end
	-- the server writes onto a body that it's down, that's all any client hears of it
	local function update()
		assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
		local isDead = AttributeDefinition.get(character, AttributeDefinition.IsDead)
		if isDead and not body.Handle then
			body.Handle = VFXService:NewScope(character).start(
				ClientVFXDefinition.Ragdoll,
				table.freeze({
					Shove = RAGDOLL_SHOVE,
				})
			)
		elseif not isDead then
			stand(body)
		end
	end
	table.insert(
		body.CharacterConnections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(update)
	)
	update()
end

local function addBody(self: MovementService, player: Player)
	if self._Bodies[player] then
		return
	end
	local body: Body = {
		Character = nil,
		Handle = nil,
		Connections = {},
		CharacterConnections = {},
	}
	self._Bodies[player] = body
	table.insert(
		body.Connections,
		player.CharacterAdded:Connect(function(character: Model)
			setCharacter(body, character)
		end)
	)
	table.insert(
		body.Connections,
		player.CharacterRemoving:Connect(function(character: Model)
			if body.Character == character then
				setCharacter(body, nil)
			end
		end)
	)
	setCharacter(body, player.Character)
end

local function removeBody(self: MovementService, player: Player)
	local body = self._Bodies[player]
	if not body then
		return
	end
	self._Bodies[player] = nil
	setCharacter(body, nil)
	for _, v in body.Connections do
		v:Disconnect()
	end
	table.clear(body.Connections)
end
-- Class
local MovementService = {} :: MovementServiceImpl
MovementService.__index = MovementService

function MovementService:GetIfSprinting(): boolean
	assert(self.IsInitialized, `the movement service isn't initialized`)
	local humanoid = getHumanoid()
	return humanoid ~= nil and humanoid.WalkSpeed == SPRINT_SPEED
end

function MovementService:ToggleSprint(): Result<true, string>
	assert(self.IsInitialized, `the movement service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local humanoid = getHumanoid()
	if not humanoid then
		return Result.err(`there's no avatar to run with`)
	end
	if not ShellService:GetIsGameplayHudVisible() then
		return Result.err(`the avatar is behind a menu`)
	end
	local now = os.clock()
	if now - self._SprintedAt < SPRINT_COOLDOWN then
		return Result.err(`the last press was less than {SPRINT_COOLDOWN} s ago`)
	end
	-- the pace is read off the avatar: nothing is kept that a new avatar, a root or a power could leave behind
	local walkSpeed = humanoid.WalkSpeed
	if walkSpeed <= MIN_OWN_SPEED or walkSpeed >= MAX_OWN_SPEED then
		return Result.err(`the pace of the avatar isn't its own`)
	end
	self._SprintedAt = now
	humanoid.WalkSpeed = if walkSpeed == SPRINT_SPEED then StarterPlayer.CharacterWalkSpeed else SPRINT_SPEED
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function MovementService:Lift(): Result<true, string>
	assert(self.IsInitialized, `the movement service isn't initialized`)
	local humanoid = getHumanoid()
	local avatar = humanoid and humanoid.Parent
	local rootPart = if avatar and avatar:IsA("Model") then avatar.PrimaryPart else nil
	if not humanoid or not rootPart then
		return Result.err(`there's no avatar to lift`)
	end
	if not AIRBORNE_STATES[humanoid:GetState()] then
		return Result.err(`the avatar isn't in the air`)
	end
	if humanoid.UseJumpPower and humanoid.JumpPower > MAX_OWN_JUMP_POWER then
		return Result.err(`a power jumps for the avatar`)
	end
	local now = os.clock()
	if now - self._LiftedAt < LIFT_COOLDOWN then
		return Result.err(`the last lift was less than {LIFT_COOLDOWN} s ago`)
	end
	self._LiftedAt = now
	-- the body is its own client's to move: the old place had its server push whatever part a client named
	local velocity = Instance.new("BodyVelocity")
	velocity.Name = LIFT_NAME
	velocity.MaxForce = Vector3.new(0, LIFT_MAX_FORCE, 0)
	velocity.P = LIFT_POWER
	velocity.Velocity = Vector3.new(0, LIFT_SPEED, 0)
	velocity.Parent = rootPart
	Debris:AddItem(velocity, LIFT_DURATION)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- what a body does by itself in a game that has more of it than the engine gives: shift goes between a walk + a run,
-- a jump that's asked for in the air lifts once more, + whoever is down hangs loose from their joints on this screen.
-- nothing of it is the server's to hear of. a key + a jump are all it listens to so far, touch + gamepad have neither
return ServiceLocker(function(): MovementService
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_SprintedAt = -math.huge,
		_LiftedAt = -math.huge,
		_Bodies = {} :: { [Player]: Body },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, MovementService)

	table.insert(
		self._Connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
			-- a capital typed into the chat isn't a run: the old place took every press of the key for one
			if isProcessed or not SPRINT_KEY_CODES[input.KeyCode] then
				return
			end
			self:ToggleSprint()
		end)
	)
	-- held, the key asks over + over: the jump off the ground is the engine's, the first ask in the air is the lift
	table.insert(
		self._Connections,
		UserInputService.JumpRequest:Connect(function()
			self:Lift()
		end)
	)

	if IS_DEATH_LIMP then
		table.insert(
			self._Connections,
			Players.PlayerAdded:Connect(function(player: Player)
				addBody(self, player)
			end)
		)
		table.insert(
			self._Connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				removeBody(self, player)
			end)
		)
		for _, player in Players:GetPlayers() do
			addBody(self, player)
		end
		table.insert(self._CleanUpCallbacks, function()
			for player in table.clone(self._Bodies) do
				removeBody(self, player)
			end
		end)
	end

	return self
end, function(self: MovementService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
