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
		local powerSkin = identity.PowerSkins[power.Id]
		local colorOpt =
			PowerDefinition.getColor(powerDefRes.Value, if powerSkin then powerSkin.ColorGroups.Primary else nil)
		out[power.Id] = {
			Id = power.Id,
			Color = if colorOpt.IsSome then colorOpt.Value else nil,
		}
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
	-- the color goes with the power, picking it again starts over from the default
	return Result.ok(StateUtil.editIdentities(setPowers(state, powers), function(identity: Identity): Identity
		return if identity.PowerSkins[powerId] == nil then identity else setPowerSkin(identity, powerId, nil)
	end))
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
	local powerDef = powerDefRes.Value
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

return Util
