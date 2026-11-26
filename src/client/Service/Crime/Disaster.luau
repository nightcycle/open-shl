--!strict
-- Services
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local DisasterDefinition = require("@game/ReplicatedStorage/Shared/Definition/Disaster")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
-- Types
type Fireball = DisasterDefinition.Fireball
export type Drawer = {
	Destroy: () -> (),
}
-- Constants
local BAR = DisasterDefinition.BAR
-- the part of a target its bar sits on, + the two boxes of the bar: the map has all of them
local VISUAL_NAME = "Visual"
local FRAME_NAME = "Frame"
local FILL_NAME = "Health"
-- pixels the fill stops short of its frame, on all four sides
local FILL_INSET = 10
local FIREBALL_NAME = "DisasterFireball"
-- Variables
-- References
-- Private Functions
-- as wide as the share of its health the target has left
local function getFillSize(health: number, maxHealth: number): UDim2
	local share = math.clamp(health / maxHealth, 0, 1)
	return UDim2.new(share, -FILL_INSET * share, 1, -FILL_INSET)
end
-- Class
-- what a client draws of a disaster: the bar over a target + the ball of light of one that blows up. the server
-- says nothing of either, both are read off the target: it wears its health the way an avatar does, + the map keeps
-- it around for good, so everybody sees it fall from wherever they are. smoke + wreck are the server's own instances
return {
	new = function(): Drawer
		-- the frame of every bar that's in the world: where nobody fights no target takes anything + none shows one
		local frames: { [GuiObject]: true } = {}
		local fireballs: { [BasePart]: true } = {}

		-- white + a stud across, to its full size + color in a flash while it thins out to nothing
		local function burst(position: Vector3, fireball: Fireball)
			local ball = Instance.new("Part")
			ball.Name = FIREBALL_NAME
			ball.Shape = Enum.PartType.Ball
			ball.Size = Vector3.one
			ball.Anchored = true
			ball.CanCollide = false
			ball.CanQuery = false
			ball.CanTouch = false
			ball.CastShadow = false
			ball.Material = Enum.Material.Neon
			ball.Color = Color3.new(1, 1, 1)
			ball.Position = position
			ball.Parent = Workspace
			fireballs[ball] = true
			TweenService:Create(ball, TweenInfo.new(fireball.GrowDuration, Enum.EasingStyle.Linear), {
				Size = Vector3.one * fireball.Size,
				Color = fireball.Color,
			}):Play()
			TweenService:Create(ball, TweenInfo.new(fireball.FadeDuration, Enum.EasingStyle.Linear), {
				Transparency = 1,
			}):Play()
			task.delay(fireball.Lifetime, function()
				fireballs[ball] = nil
				ball:Destroy()
			end)
		end

		-- under streaming a target comes + goes like anything else would, + one that was blown up comes back as a new
		-- instance
		local stopTargets = MapDefinition.observe(MapDefinition.DisasterTarget, function(target: Model): (() -> ())?
			local idRes = MapDefinition.get(target, MapDefinition.DisasterId)
			if idRes.IsErr then
				warn(idRes.Value)
				return nil
			end
			local disasterRes = DisasterDefinition.get(idRes.Value)
			if disasterRes.IsErr then
				warn(`{target:GetFullName()}: {disasterRes.Value}`)
				return nil
			end
			local disaster = disasterRes.Value
			local consequence = disaster.Consequence
			local visual = target:FindFirstChild(VISUAL_NAME)
			local gui = visual and visual:FindFirstChildOfClass("BillboardGui")
			local frame = gui and gui:FindFirstChild(FRAME_NAME)
			local fill = frame and frame:FindFirstChild(FILL_NAME)
			if
				not visual
				or not visual:IsA("BasePart")
				or not frame
				or not frame:IsA("GuiObject")
				or not fill
				or not fill:IsA("GuiObject")
			then
				warn(`{target:GetFullName()} has no bar to draw its health on`)
				return nil
			end

			frames[frame] = true
			frame.Visible = ModeDefinition.getIfPVPEnabled()
			local health = AttributeDefinition.get(target, AttributeDefinition.Health)
			fill.Size = getFillSize(health, disaster.MaxHealth)
			fill.BackgroundColor3 = BAR.Color
			local flashThread: thread? = nil
			local healthConnection = target
				:GetAttributeChangedSignal(AttributeDefinition.Health.Name)
				:Connect(function()
					local priorHealth = health
					health = AttributeDefinition.get(target, AttributeDefinition.Health)
					fill.Size = getFillSize(health, disaster.MaxHealth)
					-- it blinks for what comes off, a target that's whole again just is
					if health >= priorHealth then
						return
					end
					if flashThread and coroutine.status(flashThread) == "suspended" then
						task.cancel(flashThread)
					end
					fill.BackgroundColor3 = BAR.FlashColor
					flashThread = task.delay(BAR.FlashDuration, function()
						fill.BackgroundColor3 = BAR.Color
					end)
				end)
			-- one that's down as it comes in fell before this client could see it
			local isDead = AttributeDefinition.get(target, AttributeDefinition.IsDead)
			local deadConnection = target:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
				local wasDead = isDead
				isDead = AttributeDefinition.get(target, AttributeDefinition.IsDead)
				if isDead and not wasDead and consequence.Type == "Blast" then
					burst(visual.Position, consequence.Fireball)
				end
			end)

			return function()
				healthConnection:Disconnect()
				deadConnection:Disconnect()
				if flashThread and coroutine.status(flashThread) == "suspended" then
					task.cancel(flashThread)
				end
				frames[frame] = nil
			end
		end)

		local stopMode = ModeDefinition.observe(function(isPVP: boolean)
			for frame in frames do
				frame.Visible = isPVP
			end
		end)

		return table.freeze({
			Destroy = function()
				stopMode()
				stopTargets()
				for ball in fireballs do
					ball:Destroy()
				end
				table.clear(fireballs)
			end,
		})
	end,
}
