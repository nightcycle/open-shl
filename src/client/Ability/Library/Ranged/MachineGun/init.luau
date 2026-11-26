--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local MachineGun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/MachineGun")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RayFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Ray")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
-- Constants
local BINDINGS = MachineGun.Layout.Bindings
-- what the bar says in place of the count while the clip is being filled
local RELOAD_TEXT = "Reloading"
-- Variables
-- References
-- Private Functions
-- Class
local powerRes = PowerDefinition.get(MachineGun.Layout.Id)
assert(powerRes.IsOk, `no power is registered as "{MachineGun.Layout.Id}"`)
local clip = MachineGun.Config.Clip
assert(clip, `"{MachineGun.Layout.Id}" has no clip to count`)
local caption = powerRes.Value.Name
local size = clip.Size

return RayFactory
	.new(MachineGun, {
		CastAnimation = "GunShooting",
		HoldAnimation = "GunHolding",
	})
	-- the bar in the corner of the screen for as long as the gun is out: what's left in the clip as this machine
	-- has it, on its way up while it's being filled
	:Run(
		BINDINGS.Hold,
		ClientVFXDefinition.Gauge,
		function(context: ClientContext): ClientVFXType.Gauge
			local record = context.Record
			return {
				Caption = caption,
				Max = size,
				Read = function(): (number, string?)
					local rounds, isFilling = RayFactory.getRounds(MachineGun, record)
					return rounds, if isFilling then RELOAD_TEXT else nil
				end,
			}
		end
	)
	:Run(BINDINGS.Hold, ClientVFXDefinition.Cursor, function(): ClientVFXType.Cursor
		return { Image = "CursorGun" }
	end)
	-- the pointer says it's being filled as well. the clip fills up with the gun put away, the pointer of a gun
	-- that's away is nobody's to change: so it's asked about while the gun is out rather than held while it fills
	:While(
		BINDINGS.Hold,
		function(context: ClientContext): VFXType.Cleanup
			local record = context.Record
			local handle: VFXType.Handle? = nil
			local connection = RunService.Heartbeat:Connect(function()
				local _, isFilling = RayFactory.getRounds(MachineGun, record)
				if isFilling and not handle then
					handle = context.VFX.start(
						ClientVFXDefinition.Cursor,
						{ Image = "CursorReload" } :: ClientVFXType.Cursor
					)
				elseif not isFilling and handle then
					handle.Stop()
					handle = nil
				end
			end)
			return function()
				connection:Disconnect()
				if handle then
					handle.Stop()
				end
			end
		end
	)
	:Build()
