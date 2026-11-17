--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type BaseInventory = BaseType.BaseInventory
type BaseLayout = BaseType.BaseLayout
type PlacedFurniture = BaseType.PlacedFurniture
type PublicProfile = ProfileType.PublicProfile
type QuestState = QuestType.QuestState
type ExpressionId = RoleplayType.ExpressionId
type Snapshot = SessionType.Snapshot
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
type DailyReward = SessionType.DailyReward
export type Validator = (value: unknown) -> (boolean, string?)
export type Kind = "Event" | "Function"
export type Direction = "ClientToServer" | "ServerToClient"
export type Remote = {
	Name: string,
	Kind: Kind,
	Direction: Direction,
	Argument: Validator, -- a remote carries one value, or nil when there's nothing to say
	Returns: Validator?, -- checks the Result a function answers with
}
-- _Signature is never set, it only carries the types
export type ClientEvent<T> = {
	Name: string,
	Kind: "Event",
	Direction: "ClientToServer",
	Argument: Validator,
	_Signature: (T) -> (),
}
export type ServerEvent<T> = {
	Name: string,
	Kind: "Event",
	Direction: "ServerToClient",
	Argument: Validator,
	_Signature: (T) -> (),
}
export type ClientFunction<V, T> = {
	Name: string,
	Kind: "Function",
	Direction: "ClientToServer",
	Argument: Validator,
	Returns: Validator,
	_Signature: (V, T) -> (),
}
-- Constants
local FOLDER_NAME = "Remotes"
local isCharacter = CharacterType.Character
-- the character type lets any key into Identities, a client may only hand in the two every character is made of
local isEditedCharacter = Type.intersection(
	isCharacter,
	Type.interface({
		Identities = Type.strictInterface({
			Main = Type.table,
			Secret = Type.table,
		}),
	})
)
local isPlacement = SessionType.FurniturePlacement
local isMove = SessionType.FurnitureMove
local isPlaced = BaseType.PlacedFurniture
local isProfiles = Type.array(ProfileType.PublicProfile)
local isQuestType = Type.literal(table.unpack(PseudoEnum.getEnumItems("QuestType")))
-- Variables
local Remotes: { Remote } = {}
-- References
-- Private Functions
local function register(remote: Remote): any
	for _, other in Remotes do
		assert(other.Name ~= remote.Name, `duplicate remote "{remote.Name}"`)
	end
	table.freeze(remote)
	table.insert(Remotes, remote)
	return remote
end

-- how a Result is checked once it crossed a remote
local function isResult(check: Validator): Validator
	local isOk = Type.strictInterface({
		Type = Type.literal("Result"),
		IsOk = Type.literal(true),
		IsErr = Type.literal(false),
		Value = check,
	})
	local isErr = Type.strictInterface({
		Type = Type.literal("Result"),
		IsOk = Type.literal(false),
		IsErr = Type.literal(true),
		Value = Type.string,
	})
	-- picked by hand, a union would swallow why the value inside is bad
	return function(value: unknown): (boolean, string?)
		if type(value) == "table" and (value :: any).IsOk == true then
			return isOk(value)
		end
		return isErr(value)
	end
end

local function newClientEvent(name: string, argument: Validator): any
	return register({
		Name = name,
		Kind = "Event",
		Direction = "ClientToServer",
		Argument = argument,
	})
end

local function newServerEvent(name: string, argument: Validator): any
	return register({
		Name = name,
		Kind = "Event",
		Direction = "ServerToClient",
		Argument = argument,
	})
end

local function newClientFunction(name: string, argument: Validator, returns: Validator): any
	return register({
		Name = name,
		Kind = "Function",
		Direction = "ClientToServer",
		Argument = argument,
		Returns = isResult(returns),
	})
end
-- Class
local Module = {}

Module.FOLDER_NAME = FOLDER_NAME

-- session
Module.GetSession = newClientFunction("GetSession", Type.none, SessionType.Snapshot) :: ClientFunction<Snapshot, nil>

-- characters
Module.SelectCharacter =
	newClientFunction("SelectCharacter", Type.string, Type.literal(true)) :: ClientFunction<true, string>
Module.SwapIdentity =
	newClientFunction("SwapIdentity", Type.none, CharacterType.IdentityKey) :: ClientFunction<IdentityKey, nil>
Module.SaveCharacter =
	newClientFunction("SaveCharacter", isEditedCharacter, isCharacter) :: ClientFunction<Character, Character>
Module.FilterText = newClientFunction("FilterText", Type.string, Type.string) :: ClientFunction<string, string>
Module.CharacterChanged = newServerEvent("CharacterChanged", isCharacter) :: ServerEvent<Character>
Module.SetInMenu = newClientEvent("SetInMenu", Type.boolean) :: ClientEvent<boolean>

-- roleplay
Module.SetExpression =
	newClientEvent("SetExpression", Type.optional(RoleplayType.ExpressionId)) :: ClientEvent<ExpressionId?>
Module.SetMasked = newClientEvent("SetMasked", Type.boolean) :: ClientEvent<boolean>
Module.SetHandcuffed = newClientEvent("SetHandcuffed", Type.boolean) :: ClientEvent<boolean>
Module.SetApartmentLocked = newClientEvent("SetApartmentLocked", Type.boolean) :: ClientEvent<boolean>

-- economy
Module.PurchaseProduct =
	newClientFunction("PurchaseProduct", Type.string, Type.literal(true)) :: ClientFunction<true, string>
Module.PurchaseFurniture =
	newClientFunction("PurchaseFurniture", Type.string, Type.literal(true)) :: ClientFunction<true, string>
Module.PurchaseTheme =
	newClientFunction("PurchaseTheme", Type.string, Type.literal(true)) :: ClientFunction<true, string>
Module.InventoryChanged = newServerEvent("InventoryChanged", BaseType.BaseInventory) :: ServerEvent<BaseInventory>
Module.ArtifactGranted = newServerEvent("ArtifactGranted", Type.string) :: ServerEvent<string>
Module.DailyRewardGranted = newServerEvent("DailyRewardGranted", SessionType.DailyReward) :: ServerEvent<DailyReward>

-- base
Module.GetBaseLayout =
	newClientFunction("GetBaseLayout", Type.none, BaseType.BaseLayout) :: ClientFunction<BaseLayout, nil>
Module.BaseLayoutChanged = newServerEvent("BaseLayoutChanged", BaseType.BaseLayout) :: ServerEvent<BaseLayout>
Module.PlaceFurniture =
	newClientFunction("PlaceFurniture", isPlacement, isPlaced) :: ClientFunction<PlacedFurniture, FurniturePlacement>
Module.MoveFurniture =
	newClientFunction("MoveFurniture", isMove, isPlaced) :: ClientFunction<PlacedFurniture, FurnitureMove>
Module.RemoveFurniture =
	newClientFunction("RemoveFurniture", Type.string, Type.literal(true)) :: ClientFunction<true, string>
Module.SetBaseTheme = newClientFunction("SetBaseTheme", Type.string, Type.literal(true)) :: ClientFunction<true, string>

-- quests
-- the server picks the goal, an error is the line the quest giver turns the player down with
Module.StartQuest =
	newClientFunction("StartQuest", isQuestType, QuestType.QuestState) :: ClientFunction<QuestState, PseudoEnum.QuestType>
Module.CancelQuest = newClientEvent("CancelQuest", Type.none) :: ClientEvent<nil>
Module.QuestChanged = newServerEvent("QuestChanged", QuestType.QuestState) :: ServerEvent<QuestState>

-- tutorial
Module.SetTutorialEnabled = newClientEvent("SetTutorialEnabled", Type.boolean) :: ClientEvent<boolean>

-- profiles
Module.GetProfiles = newClientFunction("GetProfiles", Type.none, isProfiles) :: ClientFunction<{ PublicProfile }, nil>
Module.ProfilesChanged = newServerEvent("ProfilesChanged", isProfiles) :: ServerEvent<{ PublicProfile }>

-- combat
Module.InsufficientEnergy = newServerEvent("InsufficientEnergy", Type.none) :: ServerEvent<nil>

Module.list = function(): { Remote }
	return table.freeze(table.clone(Remotes))
end

return Module
