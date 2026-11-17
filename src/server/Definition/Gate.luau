--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
export type GateDefinition =
	{
		-- stays where the last press of the button sent it
		Type: "Slide",
		Id: string,
		DoorName: string,
		Offset: Vector3, -- from closed to open, in the space of the world
		Duration: number,
		Cooldown: number,
		OpenColor: BrickColor, -- of the button
		ClosedColor: BrickColor,
	}
	| {
		-- shuts again on its own
		Type: "Swing",
		Id: string,
		DoorName: string,
		Angle: number, -- degrees around the z axis of the door's pivot
		Duration: number,
		HoldDuration: number,
		Cooldown: number,
		ReadyMaterial: Enum.Material, -- of the button
		BusyMaterial: Enum.Material,
	}
-- Constants
local GATES: { [string]: GateDefinition } = {
	BankVault = {
		Type = "Slide" :: "Slide",
		Id = "BankVault",
		DoorName = "Door",
		Offset = Vector3.new(0, 0, -14.4),
		Duration = 10.8,
		Cooldown = 1,
		OpenColor = BrickColor.new("Lime green"),
		ClosedColor = BrickColor.new("Really red"),
	},
	RefineryGate = {
		Type = "Swing" :: "Swing",
		Id = "RefineryGate",
		DoorName = "Gate",
		Angle = 80,
		Duration = 2.4,
		HoldDuration = 8,
		Cooldown = 1,
		ReadyMaterial = Enum.Material.Neon,
		BusyMaterial = Enum.Material.SmoothPlastic,
	},
}
TableUtil.deepFreeze(GATES)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

for id, DEFINITION in GATES do
	assert(DEFINITION.Id == id, `"{id}" gate is filed under the wrong id`)
end

-- what a player steps on to work a gate, it sits next to the door inside of the gate
Module.BUTTON_NAME = "Button"

Module.get = function(id: string): Result<GateDefinition, string>
	local definition = GATES[id]
	if not definition then
		return Result.err(`there's no "{id}" gate`)
	end
	return Result.ok(definition)
end

return Module
