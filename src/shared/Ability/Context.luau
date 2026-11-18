--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Aim = AbilityType.Aim
type Stimulus = AbilityType.Stimulus
type Memory = AbilityType.Memory
type ClientContext = AbilityType.ClientContext
type ServerContext = AbilityType.ServerContext
-- everything about one ability of one character that stays the same from hook to hook
export type ClientSetup = {
	AbilityId: string,
	Character: Model,
	Player: Player?,
	Color: Color3?,
	VFX: VFXType.ClientScope,
	GetAim: () -> Aim,
	-- has the machine of the half fire the binding
	Raise: (name: string, payload: unknown, aim: Aim?) -> (),
}
export type ServerSetup = {
	AbilityId: string,
	Character: Model,
	Player: Player?,
	Color: Color3?,
	VFX: VFXType.ServerScope,
	Raise: (name: string, payload: unknown, aim: Aim?) -> (),
}
type Signal = {
	Name: string,
	Payload: VFXType.Validator,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- checked where it's raised, so a mistake shows up next to whoever made it
local function raise(abilityId: string, signal: Signal, payload: unknown, send: (name: string, payload: unknown) -> ())
	local success, msg = signal.Payload(payload)
	if not success then
		warn(`"{signal.Name}" of "{abilityId}" was raised with a bad payload: {msg}`)
		return
	end
	send(signal.Name, payload)
end

-- only the binding that's running has a payload to be read
local function read(stimulus: Stimulus?, signal: Signal): any
	return if stimulus and stimulus.BindingName == signal.Name then stimulus.Payload else nil
end
-- Class
local Module = {}

-- what a hook of a client half is run with. the same wherever the half runs: a client or a story
Module.newClient = function(setup: ClientSetup, stimulus: Stimulus?, memory: Memory, record: Memory): ClientContext
	return table.freeze({
		AbilityId = setup.AbilityId,
		Character = setup.Character,
		Player = setup.Player,
		Color = setup.Color,
		Aim = stimulus and stimulus.Aim,
		Memory = memory,
		Record = record,
		VFX = setup.VFX,
		getAim = setup.GetAim,
		raise = function(signal: any, payload: unknown)
			raise(setup.AbilityId, signal, payload, function(name: string)
				setup.Raise(name, payload, setup.GetAim())
			end)
		end,
		read = function(signal: any): any
			return read(stimulus, signal)
		end,
	}) :: any
end

Module.newServer = function(setup: ServerSetup, stimulus: Stimulus?, memory: Memory, record: Memory): ServerContext
	return table.freeze({
		AbilityId = setup.AbilityId,
		Character = setup.Character,
		Player = setup.Player,
		Color = setup.Color,
		Aim = stimulus and stimulus.Aim,
		Memory = memory,
		Record = record,
		VFX = setup.VFX,
		raise = function(signal: any, payload: unknown)
			raise(setup.AbilityId, signal, payload, function(name: string)
				setup.Raise(name, payload, stimulus and stimulus.Aim)
			end)
		end,
		read = function(signal: any): any
			return read(stimulus, signal)
		end,
	}) :: any
end

return Module
