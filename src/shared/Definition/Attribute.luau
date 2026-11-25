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
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type ResidenceId = BaseType.ResidenceId
type IdentityKey = CharacterType.IdentityKey
type TeamId = CombatType.TeamId
type EntitlementKey = EconomyType.EntitlementKey
type ExpressionId = RoleplayType.ExpressionId
export type Validator = (value: unknown) -> (boolean, string?)
export type Owner = "Player" | "Character" | "Workspace"
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
local ASSET_ID: Validator = Type.intersection(Type.integer, Type.numberMin(0))
-- only what the game's own passes hand out, the keys of another game are never set on a player
local ENTITLEMENT_KEYS: { EntitlementKey } = ProductDefinition.listEntitlements()
local OWNER_CLASS_NAMES: { [Owner]: string } = table.freeze({
	Player = "Player",
	Character = "Model",
	Workspace = "Workspace",
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
-- the most is what an avatar has, a body nobody plays may come with more of it
Module.Health = new("Character", "Health", Type.numberMin(0), MAX_HEALTH) :: Attribute<number>
Module.Energy = new("Character", "Energy", Type.numberConstrained(0, MAX_ENERGY), MAX_ENERGY) :: Attribute<number>
Module.IsDead = new("Character", "IsDead", Type.boolean, false) :: Attribute<boolean>
-- "" falls back to the user name
Module.PersonaName = new("Character", "PersonaName", Type.string, "") :: Attribute<string>
Module.IdentityKey = new("Character", "IdentityKey", CharacterType.IdentityKey, "Main") :: Attribute<IdentityKey>
Module.IsInMenu = new("Character", "IsInMenu", Type.boolean, false) :: Attribute<boolean>
-- when the fight it's in is over, on the clock of the server. nil for one that didn't lose health since it came in
Module.FightingUntil = new("Character", "FightingUntil", Type.optional(Type.numberMin(0)), nil) :: Attribute<number?>
-- the prop the server counts as in its hand, nil for an empty hand + in a game without props
Module.HeldPropId = new("Character", "HeldPropId", Type.optional(Type.string), nil) :: Attribute<string?>
-- its player sat fights out: it hurts nobody + nobody hurts it. nil in a game where nobody gets to pick, which is a
-- character that fights
Module.IsPeaceful = new("Character", "IsPeaceful", Type.optional(Type.boolean), nil) :: Attribute<boolean?>
-- the side it came in on + keeps for as long as it's in the world, whatever its player picks after. nil in a game or
-- a place without sides
Module.TeamId = new("Character", "TeamId", Type.optional(CombatType.TeamId), nil) :: Attribute<TeamId?>
-- how many it downed since it came in, nil without sides
Module.KillStreak = new(
	"Character",
	"KillStreak",
	Type.optional(Type.intersection(Type.integer, Type.numberMin(0))),
	nil
) :: Attribute<number?>
-- the user id of the player whose hit took the last of its health. nil for one that's up, that went down any other
-- way + in a game where downing somebody is worth nothing
Module.DownedBy = new("Character", "DownedBy", Type.optional(Type.integer), nil) :: Attribute<number?>
-- it's held: it has no powers + isn't let out by anything but getting away. nil in a game without a jail
Module.IsJailed = new("Character", "IsJailed", Type.optional(Type.boolean), nil) :: Attribute<boolean?>
-- it made trouble while it was held, which is the end of being left alone for it
Module.IsTroublesome = new("Character", "IsTroublesome", Type.optional(Type.boolean), nil) :: Attribute<boolean?>
Module.IsMasked = new("Character", "IsMasked", Type.boolean, true) :: Attribute<boolean>
Module.IsHandcuffed = new("Character", "IsHandcuffed", Type.boolean, false) :: Attribute<boolean>
-- nothing takes health off it
Module.IsInvulnerable = new("Character", "IsInvulnerable", Type.boolean, false) :: Attribute<boolean>
-- nobody plays it: what a disaster is made of, what rises from the graves. nil on an avatar
Module.IsNonPlayer = new("Character", "IsNonPlayer", Type.optional(Type.boolean), nil) :: Attribute<boolean?>
-- nobody is shown who it is
Module.IsNameHidden = new("Character", "IsNameHidden", Type.boolean, false) :: Attribute<boolean>
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
Module.HasExtraPowers = new("Player", "HasExtraPowers", Type.boolean, false) :: Attribute<boolean>
Module.HasAdvancedRoleplay = new("Player", "HasAdvancedRoleplay", Type.boolean, false) :: Attribute<boolean>
-- "" until the server picked one
Module.ActiveCharacterId = new("Player", "ActiveCharacterId", Type.string, "") :: Attribute<string>
-- who their avatar was last dressed as: an avatar that's out of range isn't on a client, its player is. "" until the
-- first dress
Module.ActivePersonaName = new("Player", "ActivePersonaName", Type.string, "") :: Attribute<string>
Module.IsTutorialEnabled = new("Player", "IsTutorialEnabled", Type.boolean, true) :: Attribute<boolean>
Module.IsApartmentLocked = new("Player", "IsApartmentLocked", Type.boolean, true) :: Attribute<boolean>
-- whoever was sent to this server by the game picked their mode on the way, they aren't asked again
Module.IsModeChosen = new("Player", "IsModeChosen", Type.boolean, false) :: Attribute<boolean>
-- the shirt + the pants the account of the player has on, by their asset ids: 0 for one it wears none of. nil until
-- the server asked, which it only does in a game whose characters wear them
Module.ShirtAssetId = new("Player", "ShirtAssetId", Type.optional(ASSET_ID), nil) :: Attribute<number?>
Module.PantsAssetId = new("Player", "PantsAssetId", Type.optional(ASSET_ID), nil) :: Attribute<number?>
-- the server is theirs. a client is told, it never works it out
Module.IsServerOwner = new("Player", "IsServerOwner", Type.boolean, false) :: Attribute<boolean>
-- nil for as long as the player has no residence
Module.ResidenceId = new("Player", "ResidenceId", Type.optional(BaseType.ResidenceId), nil) :: Attribute<ResidenceId?>

-- on the workspace
-- if a private server lets its players fight, which is up to whoever set it up. nil until its server knows + on
-- every place that's built for one mode, but for those of a game whose private servers have a toggle
Module.IsPVP = new("Workspace", "IsPVP", Type.optional(Type.boolean), nil) :: Attribute<boolean?>
-- somebody owns this server, as the engine has it
Module.IsPrivateServer = new("Workspace", "IsPrivateServer", Type.boolean, false) :: Attribute<boolean>

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
	elseif key == "MultiHair" then
		return Module.HasMultiHair
	elseif key == "ExtraPowers" then
		return Module.HasExtraPowers
	elseif key == "AdvancedRoleplay" then
		return Module.HasAdvancedRoleplay
	end
	-- a key that's added without an attribute is one the checker lets through
	error(`no attribute for the "{key}" entitlement`)
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
