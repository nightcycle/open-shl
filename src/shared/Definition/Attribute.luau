--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type ResidenceId = BaseType.ResidenceId
type IdentityKey = CharacterType.IdentityKey
type EntitlementKey = EconomyType.EntitlementKey
type ExpressionId = RoleplayType.ExpressionId
export type Validator = (value: unknown) -> (boolean, string?)
export type Owner = "Player" | "Character"
-- _Signature is never set, it only carries the type of the value
export type Attribute<V> = {
	Name: string,
	Owner: Owner,
	Validator: Validator,
	Default: any,
	_Signature: (V) -> (),
}
-- Constants
local MAX_HEALTH = 100
local MAX_ENERGY = 200
local ENTITLEMENT_KEYS: { EntitlementKey } =
	table.freeze({ "FifthPower" :: EntitlementKey, "ExtraCharacterSlots", "MultiHair" })
local OWNER_CLASS_NAMES: { [Owner]: string } = table.freeze({
	Player = "Player",
	Character = "Model",
})
-- Variables
local Attributes: { Attribute<any> } = {}
-- References
-- Private Functions
local function new(owner: Owner, name: string, validator: Validator, default: any): any
	for _, other in Attributes do
		assert(other.Name ~= name, `duplicate attribute "{name}"`)
	end
	assert(validator(default))
	local attribute = table.freeze({
		Name = name,
		Owner = owner,
		Validator = validator,
		Default = default,
	})
	table.insert(Attributes, attribute :: any)
	return attribute
end
-- Class
local Module = {}

Module.MAX_HEALTH = MAX_HEALTH
Module.MAX_ENERGY = MAX_ENERGY

-- on the character
Module.Health = new("Character", "Health", Type.numberConstrained(0, MAX_HEALTH), MAX_HEALTH) :: Attribute<number>
Module.Energy = new("Character", "Energy", Type.numberConstrained(0, MAX_ENERGY), MAX_ENERGY) :: Attribute<number>
Module.IsDead = new("Character", "IsDead", Type.boolean, false) :: Attribute<boolean>
-- "" falls back to the user name
Module.PersonaName = new("Character", "PersonaName", Type.string, "") :: Attribute<string>
Module.IdentityKey = new("Character", "IdentityKey", CharacterType.IdentityKey, "Main") :: Attribute<IdentityKey>
Module.IsInMenu = new("Character", "IsInMenu", Type.boolean, false) :: Attribute<boolean>
Module.IsMasked = new("Character", "IsMasked", Type.boolean, true) :: Attribute<boolean>
Module.IsHandcuffed = new("Character", "IsHandcuffed", Type.boolean, false) :: Attribute<boolean>
Module.ExpressionId =
	new("Character", "ExpressionId", Type.optional(RoleplayType.ExpressionId), nil) :: Attribute<ExpressionId?>

-- on the player
Module.Credits =
	new("Player", "Credits", EconomyType.Balance, ProductDefinition.STARTING_BALANCES.Credits) :: Attribute<number>
Module.Gems = new("Player", "Gems", EconomyType.Balance, ProductDefinition.STARTING_BALANCES.Gems) :: Attribute<number>
Module.PowerLimit = new(
	"Player",
	"PowerLimit",
	Type.intersection(Type.integer, Type.numberConstrained(PowerDefinition.DEFAULT_LIMIT, PowerDefinition.PASS_LIMIT)),
	PowerDefinition.DEFAULT_LIMIT
) :: Attribute<number>
Module.HasFifthPower = new("Player", "HasFifthPower", Type.boolean, false) :: Attribute<boolean>
Module.HasExtraCharacterSlots = new("Player", "HasExtraCharacterSlots", Type.boolean, false) :: Attribute<boolean>
Module.HasMultiHair = new("Player", "HasMultiHair", Type.boolean, false) :: Attribute<boolean>
-- "" until the server picked one
Module.ActiveCharacterId = new("Player", "ActiveCharacterId", Type.string, "") :: Attribute<string>
Module.IsTutorialEnabled = new("Player", "IsTutorialEnabled", Type.boolean, true) :: Attribute<boolean>
Module.IsApartmentLocked = new("Player", "IsApartmentLocked", Type.boolean, true) :: Attribute<boolean>
-- nil for as long as the player has no residence
Module.ResidenceId = new("Player", "ResidenceId", Type.optional(BaseType.ResidenceId), nil) :: Attribute<ResidenceId?>

Module.list = function(owner: Owner?): { Attribute<any> }
	local out: { Attribute<any> } = {}
	for _, attribute in Attributes do
		if owner == nil or attribute.Owner == owner then
			table.insert(out, attribute)
		end
	end
	table.freeze(out)
	return out
end

Module.fromCurrency = function(currency: PseudoEnum.Currency): Attribute<number>
	return if currency == PseudoEnum.Currency.Credits then Module.Credits else Module.Gems
end

Module.fromEntitlement = function(key: EntitlementKey): Attribute<boolean>
	if key == "FifthPower" then
		return Module.HasFifthPower
	elseif key == "ExtraCharacterSlots" then
		return Module.HasExtraCharacterSlots
	end
	return Module.HasMultiHair
end

Module.fix = function<V>(attribute: Attribute<V>, value: unknown): V
	if value == nil then
		return attribute.Default
	end
	local success, msg = attribute.Validator(value)
	if not success then
		warn(`bad "{attribute.Name}" attribute: {msg}`)
		return attribute.Default
	end
	return value :: any
end

Module.get = function<V>(inst: Instance?, attribute: Attribute<V>): V
	return Module.fix(attribute, if inst then inst:GetAttribute(attribute.Name) else nil)
end

Module.set = function<V>(inst: Instance, attribute: Attribute<V>, value: V)
	assert(RunService:IsServer(), `only the server sets attributes`)
	assert(inst:IsA(OWNER_CLASS_NAMES[attribute.Owner]), `"{attribute.Name}" belongs on a {attribute.Owner}`)
	local success, msg = attribute.Validator(value)
	assert(success, `bad "{attribute.Name}" value: {msg}`)
	inst:SetAttribute(attribute.Name, value)
end

Module.setDefaults = function(inst: Instance, owner: Owner)
	for _, attribute in Module.list(owner) do
		Module.set(inst, attribute, attribute.Default)
	end
end

Module.setEntitlements = function(player: Instance, entitlements: { EntitlementKey })
	for _, key: EntitlementKey in ENTITLEMENT_KEYS do
		Module.set(player, Module.fromEntitlement(key), table.find(entitlements, key) ~= nil)
	end
end

return Module
