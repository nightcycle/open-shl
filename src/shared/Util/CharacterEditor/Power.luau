--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
export type EditorState = CharacterEditorType.EditorState
export type PowerValue = CharacterEditorType.PowerValue
type Character = CharacterType.Character
type Power = CharacterType.Power
type Identity = IdentityType.Identity
type PowerSkin = IdentityType.PowerSkin
type PowerGroup = PowerType.PowerGroup
type PowerDefinition = PowerType.PowerDefinition
-- Constants
-- Variables
-- References
-- Private Functions
local function findIndex(character: Character, powerId: string): number?
	for i, power in character.Powers do
		if power.Id == powerId then
			return i
		end
	end
	return nil
end

local function getDefinition(group: PowerGroup, powerId: string): Result<PowerDefinition, string>
	local powerDefRes = PowerDefinition.get(powerId)
	if powerDefRes.IsErr then
		return Result.err(`no power "{powerId}"`)
	end
	if powerDefRes.Value.Group ~= group then
		return Result.err(`"{powerDefRes.Value.Name}" isn't on that list`)
	end
	return powerDefRes
end

local function setPowers(state: EditorState, powers: { Power }): EditorState
	table.freeze(powers)
	local character = table.clone(state.Character)
	character.Powers = powers
	table.freeze(character)
	return StateUtil.setCharacter(state, character)
end

local function setPowerSkin(identity: Identity, powerId: string, powerSkin: PowerSkin?): Identity
	local out = table.clone(identity)
	out.PowerSkins = FreezeUtil.delta(identity.PowerSkins, function(t: { [string]: PowerSkin }): { [string]: PowerSkin }
		t[powerId] = powerSkin :: PowerSkin
		return t
	end)
	table.freeze(out)
	return out
end

-- a held power the way a list shows it: in the color the identity in focus has it in
local function newValue(identity: Identity, powerDef: PowerDefinition): PowerValue
	local powerSkin = identity.PowerSkins[powerDef.Id]
	local colorOpt = PowerDefinition.getColor(powerDef, if powerSkin then powerSkin.ColorGroups.Primary else nil)
	return {
		Id = powerDef.Id,
		Color = if colorOpt.IsSome then colorOpt.Value else nil,
	}
end

-- the color goes with the power, picking it again starts over from the default
local function dropPowerSkins(state: EditorState, powerIds: { string }): EditorState
	return StateUtil.editIdentities(state, function(identity: Identity): Identity
		local out = identity
		for _, powerId in powerIds do
			if out.PowerSkins[powerId] ~= nil then
				out = setPowerSkin(out, powerId, nil)
			end
		end
		return out
	end)
end

local function setColor(state: EditorState, powerDef: PowerDefinition, color: Color3): Result<EditorState, string>
	local powerId = powerDef.Id
	if not findIndex(state.Character, powerId) then
		return Result.err(`"{powerDef.Name}" isn't one of the character's powers`)
	end
	local colorGroup = powerDef.ColorGroups.Primary
	if not colorGroup then
		return Result.err(`"{powerDef.Name}" can't be recolored`)
	end
	-- compared as hex, a color that went through a save or a remote may not be bit equal to its choice
	local hex = color:ToHex()
	local choice: Color3? = if colorGroup.Default:ToHex() == hex then colorGroup.Default else nil
	for _, colorChoice in colorGroup.Choices do
		if colorChoice:ToHex() == hex then
			choice = colorChoice
		end
	end
	if not choice then
		return Result.err(`"{powerDef.Name}" doesn't come in that color`)
	end
	return Result.ok(StateUtil.editIdentities(state, function(identity: Identity): Identity
		local powerSkin = identity.PowerSkins[powerId]
		local skinColor = if powerSkin then powerSkin.ColorGroups.Primary else nil
		if skinColor and skinColor:ToHex() == hex then
			return identity
		end
		return setPowerSkin(identity, powerId, {
			Id = powerId,
			ColorGroups = {
				Primary = choice,
			},
		})
	end))
end

-- a power of the slot, or what's wrong with it as one
local function getSlotDefinition(slotKey: string, powerId: string): Result<PowerDefinition, string>
	local powerDefRes = PowerDefinition.get(powerId)
	if powerDefRes.IsErr then
		return Result.err(`no power "{powerId}"`)
	end
	local slot = PowerDefinition.getSlot(powerId)
	if not slot or slot.Key ~= slotKey then
		return Result.err(`"{powerDefRes.Value.Name}" isn't on that list`)
	end
	return powerDefRes
end

-- Class
local Util = {}

function Util.list(state: EditorState, group: PowerGroup): { [string]: PowerValue }
	local identity = StateUtil.getIdentity(state)
	local out: { [string]: PowerValue } = {}
	for _, power in state.Character.Powers do
		local powerDefRes = PowerDefinition.get(power.Id)
		if powerDefRes.IsErr or powerDefRes.Value.Group ~= group then
			continue
		end
		out[power.Id] = newValue(identity, powerDefRes.Value)
	end
	return out
end

-- what the character holds of a slot of the game, which is one power at most
function Util.listSlot(state: EditorState, slotKey: string): { [string]: PowerValue }
	local identity = StateUtil.getIdentity(state)
	local out: { [string]: PowerValue } = {}
	for _, power in state.Character.Powers do
		local powerDefRes = PowerDefinition.get(power.Id)
		local slot = PowerDefinition.getSlot(power.Id)
		if powerDefRes.IsErr or not slot or slot.Key ~= slotKey then
			continue
		end
		out[power.Id] = newValue(identity, powerDefRes.Value)
	end
	return out
end

-- one limit across every group, the order powers are picked in is their order on the hotbar
function Util.setSelected(
	state: EditorState,
	group: PowerGroup,
	powerId: string,
	isSelected: boolean
): Result<EditorState, string>
	local powerDefRes = getDefinition(group, powerId)
	if powerDefRes.IsErr then
		return powerDefRes
	end
	local index = findIndex(state.Character, powerId)
	if isSelected == (index ~= nil) then
		return Result.ok(state)
	end
	local powers = table.clone(state.Character.Powers)
	if isSelected then
		local limit = state.Entitlements.PowerLimit
		if #powers >= limit then
			return Result.err(`a character holds up to {limit} powers`)
		end
		-- a power that was never recolored has no skin, it's tinted with its default
		table.insert(powers, table.freeze({ Id = powerId }))
		return Result.ok(setPowers(state, powers))
	end
	table.remove(powers, index)
	return Result.ok(dropPowerSkins(setPowers(state, powers), { powerId }))
end

-- a slot holds one power, so a pick takes the place of what the slot held. the powers stay in the order of the slots,
-- which is their order on the hotbar
function Util.setSlotted(
	state: EditorState,
	slotKey: string,
	powerId: string,
	isSelected: boolean
): Result<EditorState, string>
	local powerDefRes = getSlotDefinition(slotKey, powerId)
	if powerDefRes.IsErr then
		return powerDefRes
	end
	if isSelected == (findIndex(state.Character, powerId) ~= nil) then
		return Result.ok(state)
	end
	-- what's held by the key of its slot, a power of no slot keeps its place after them
	local heldBySlot: { [string]: Power } = {}
	local unslotted: { Power } = {}
	local droppedIds: { string } = {}
	for _, power in state.Character.Powers do
		local slot = PowerDefinition.getSlot(power.Id)
		if not slot then
			table.insert(unslotted, power)
		elseif slot.Key == slotKey then
			table.insert(droppedIds, power.Id)
		else
			heldBySlot[slot.Key] = power
		end
	end
	if isSelected then
		heldBySlot[slotKey] = table.freeze({ Id = powerId })
	end
	local powers: { Power } = {}
	local powerIds: { string } = {}
	for _, slot in PowerDefinition.listSlots() do
		local power = heldBySlot[slot.Key]
		if power then
			table.insert(powers, power)
			table.insert(powerIds, power.Id)
		end
	end
	for _, power in unslotted do
		table.insert(powers, power)
		table.insert(powerIds, power.Id)
	end
	-- what the server asks of a character that's saved is asked of the draft
	local problem: string? = if isSelected
		then PowerDefinition.getLoadoutError(powerIds, state.Entitlements.PowerLimit)
		else nil
	if problem then
		return Result.err(problem)
	end
	return Result.ok(dropPowerSkins(setPowers(state, powers), droppedIds))
end

function Util.setColor(
	state: EditorState,
	group: PowerGroup,
	powerId: string,
	color: Color3
): Result<EditorState, string>
	local powerDefRes = getDefinition(group, powerId)
	if powerDefRes.IsErr then
		return powerDefRes
	end
	return setColor(state, powerDefRes.Value, color)
end

function Util.setSlotColor(
	state: EditorState,
	slotKey: string,
	powerId: string,
	color: Color3
): Result<EditorState, string>
	local powerDefRes = getSlotDefinition(slotKey, powerId)
	if powerDefRes.IsErr then
		return powerDefRes
	end
	return setColor(state, powerDefRes.Value, color)
end

return Util
