--!strict
-- Services
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Kind = EnvironmentType.Precipitation
export type Drawer = {
	-- has it rain or snow on the avatar of the local player, or neither
	Set: (kind: Kind?) -> (),
	Destroy: () -> (),
}
-- Constants
local PRECIPITATION = EnvironmentDefinition.CLIMATE.Precipitation
-- where the lighting of a place keeps what falls, by its kind
local EMITTERS_NAME = "Precipitation"
local BLOCK_NAME = "PrecipitationBlock"
local EMITTER_NAME = "Precip"
-- Variables
-- References
-- Private Functions
-- nothing sees, touches or is stopped by it, so no power has to tell it from the world: it only carries what falls
local function newBlock(): Part
	local block = Instance.new("Part")
	block.Name = BLOCK_NAME
	block.Size = PRECIPITATION.BlockSize
	block.Transparency = 1
	block.Anchored = true
	block.CanCollide = false
	block.CanQuery = false
	block.CanTouch = false
	return block
end
-- Class
return {
	new = function(): Drawer
		-- what was asked for last, + what falls: the two differ for as long as one kind is swapped for the other
		local wantedKind: Kind? = nil
		local kind: Kind? = nil
		local swapThread: thread? = nil
		local block = newBlock()
		local emitter: ParticleEmitter? = nil
		local emitterKind: Kind? = nil
		local stepConnection: RBXScriptConnection? = nil
		local roofParams = RaycastParams.new()
		roofParams.FilterType = Enum.RaycastFilterType.Exclude
		-- whose body the search for a roof looks past
		local roofAvatar: Model? = nil
		-- a place that came without one is told so once, not on every frame
		local isWarned: { [string]: true } = {}

		local function clear()
			if emitter then
				emitter:Destroy()
				emitter = nil
				emitterKind = nil
			end
			block.Parent = nil
		end

		-- dry is where something is overhead of every spot that's asked, + none of it too far up to count
		local function getIfRoofed(avatar: Model, root: BasePart): boolean
			if roofAvatar ~= avatar then
				roofAvatar = avatar
				roofParams.FilterDescendantsInstances = { avatar }
			end
			for _, offset in PRECIPITATION.RoofOffsets do
				local result =
					Workspace:Raycast(root.Position + offset, Vector3.new(0, PRECIPITATION.RoofReach, 0), roofParams)
				if not result or (result.Position - root.Position).Magnitude >= PRECIPITATION.RoofDistance then
					return false
				end
			end
			return true
		end

		local function fall(fallingKind: Kind): ParticleEmitter?
			if emitter and emitterKind == fallingKind then
				return emitter
			end
			if emitter then
				emitter:Destroy()
				emitter = nil
				emitterKind = nil
			end
			local emitters = Lighting:FindFirstChild(EMITTERS_NAME)
			local template = emitters and emitters:FindFirstChild(fallingKind)
			if not template or not template:IsA("ParticleEmitter") then
				if not isWarned[fallingKind] then
					isWarned[fallingKind] = true
					warn(`the lighting has no "{fallingKind}" to fall, the sky stays dry`)
				end
				return nil
			end
			-- it comes the way the place has it, its rate + all
			local newEmitter = template:Clone()
			newEmitter.Name = EMITTER_NAME
			newEmitter.Parent = block
			emitter = newEmitter
			emitterKind = fallingKind
			return newEmitter
		end

		-- it falls from a block that rides above the avatar + moves the way the avatar does, so what's on its way
		-- down keeps up with a run. what's faster than that takes its rain along outright
		local function step()
			local avatar = Players.LocalPlayer.Character
			local root = avatar and avatar.PrimaryPart
			if not kind or not avatar or not root or getIfRoofed(avatar, root) then
				clear()
				return
			end
			local velocity = root.AssemblyLinearVelocity
			block.CFrame = CFrame.new(root.Position + Vector3.new(0, PRECIPITATION.Height, 0))
			block.AssemblyLinearVelocity = velocity
			block.Parent = Workspace
			local falling = fall(kind)
			if falling then
				falling.LockedToPart = velocity.Magnitude > PRECIPITATION.LockSpeed
			end
		end

		-- nothing is asked of a frame under a sky that drops nothing
		local function update()
			if kind and not stepConnection then
				stepConnection = RunService.Heartbeat:Connect(step)
			elseif not kind and stepConnection then
				stepConnection:Disconnect()
				stepConnection = nil
				clear()
			end
		end

		local function stopSwap()
			if swapThread and coroutine.status(swapThread) == "suspended" then
				task.cancel(swapThread)
			end
			swapThread = nil
		end

		return table.freeze({
			Set = function(newKind: Kind?)
				if newKind == wantedKind then
					return
				end
				stopSwap()
				local wasKind = kind
				wantedKind = newKind
				-- a rain doesn't turn into a snow mid air: the sky is empty for a moment in between
				if wasKind and newKind and wasKind ~= newKind then
					kind = nil
					update()
					swapThread = task.delay(PRECIPITATION.SwapGap, function()
						kind = newKind
						update()
					end)
					return
				end
				kind = newKind
				update()
			end,
			Destroy = function()
				stopSwap()
				if stepConnection then
					stepConnection:Disconnect()
					stepConnection = nil
				end
				block:Destroy()
			end,
		})
	end,
}
