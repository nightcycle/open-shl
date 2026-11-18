--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type BaseInventory = BaseType.BaseInventory
type PlacedFurniture = BaseType.PlacedFurniture
type ResidenceId = BaseType.ResidenceId
type PublicProfile = ProfileType.PublicProfile
type QuestState = QuestType.QuestState
type ExpressionId = RoleplayType.ExpressionId
type Snapshot = SessionType.Snapshot
type ResidenceState = SessionType.ResidenceState
type FurniturePlacement = SessionType.FurniturePlacement
type FurnitureMove = SessionType.FurnitureMove
type DailyReward = SessionType.DailyReward
export type Validator = (value: unknown) -> (boolean, string?)
export type Kind = "Event" | "Function"
export type Direction = "ClientToServer" | "ServerToClient"
-- a player gets Count calls of a remote within Duration seconds, the server drops whatever is over it
export type RateLimit = {
	Count: number,
	Duration: number,
}
export type Remote = {
	Name: string,
	Kind: Kind,
	Direction: Direction,
	Argument: Validator, -- a remote carries one value, or nil when there's nothing to say
	Returns: Validator?, -- checks the Result a function answers with
	RateLimit: RateLimit?, -- every remote a client calls has one
	IsExclusive: boolean?, -- a function that turns a player down while an earlier call of theirs is being answered
}
-- _Signature is never set, it only carries the types
export type ClientEvent<T> = {
	Name: string,
	Kind: "Event",
	Direction: "ClientToServer",
	Argument: Validator,
	RateLimit: RateLimit,
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
	RateLimit: RateLimit,
	IsExclusive: boolean,
	_Signature: (V, T) -> (),
}
-- Constants
local FOLDER_NAME = "Remotes"
-- a button a player can keep pressing
local INPUT_LIMIT: RateLimit = table.freeze({ Count = 60, Duration = 10 })
-- an answer the server has to work for
local REQUEST_LIMIT: RateLimit = table.freeze({ Count = 30, Duration = 10 })
-- every press + release of an ability, as well as what the effects of a player's own avatar pass on
local ABILITY_LIMIT: RateLimit = table.freeze({ Count = 150, Duration = 10 })
-- the text filter is a web call
local FILTER_LIMIT: RateLimit = table.freeze({ Count = 10, Duration = 10 })
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

local function newClientEvent(name: string, argument: Validator, rateLimit: RateLimit): any
	return register({
		Name = name,
		Kind = "Event",
		Direction = "ClientToServer",
		Argument = argument,
		RateLimit = rateLimit,
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

local function newClientFunction(
	name: string,
	argument: Validator,
	returns: Validator,
	rateLimit: RateLimit,
	isExclusive: boolean?
): any
	return register({
		Name = name,
		Kind = "Function",
		Direction = "ClientToServer",
		Argument = argument,
		Returns = isResult(returns),
		RateLimit = rateLimit,
		IsExclusive = isExclusive == true,
	})
end
-- Class
local Module = {}

Module.FOLDER_NAME = FOLDER_NAME

-- session
Module.GetSession =
	newClientFunction("GetSession", Type.none, SessionType.Snapshot, REQUEST_LIMIT) :: ClientFunction<Snapshot, nil>

-- characters
Module.SelectCharacter =
	newClientFunction("SelectCharacter", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>
Module.SwapIdentity =
	newClientFunction("SwapIdentity", Type.none, CharacterType.IdentityKey, REQUEST_LIMIT) :: ClientFunction<IdentityKey, nil>
-- the filter yields in the middle of a save, a second one would work on the slot the first is about to replace
Module.SaveCharacter =
	newClientFunction("SaveCharacter", isEditedCharacter, isCharacter, REQUEST_LIMIT, true) :: ClientFunction<Character, Character>
Module.FilterText =
	newClientFunction("FilterText", Type.string, Type.string, FILTER_LIMIT) :: ClientFunction<string, string>
Module.CharacterChanged = newServerEvent("CharacterChanged", isCharacter) :: ServerEvent<Character>
Module.SetInMenu = newClientEvent("SetInMenu", Type.boolean, INPUT_LIMIT) :: ClientEvent<boolean>

-- roleplay
Module.SetExpression =
	newClientEvent("SetExpression", Type.optional(RoleplayType.ExpressionId), INPUT_LIMIT) :: ClientEvent<ExpressionId?>
Module.SetMasked = newClientEvent("SetMasked", Type.boolean, INPUT_LIMIT) :: ClientEvent<boolean>
Module.SetHandcuffed = newClientEvent("SetHandcuffed", Type.boolean, INPUT_LIMIT) :: ClientEvent<boolean>
Module.SetApartmentLocked = newClientEvent("SetApartmentLocked", Type.boolean, INPUT_LIMIT) :: ClientEvent<boolean>

-- economy
Module.PurchaseProduct =
	newClientFunction("PurchaseProduct", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>
Module.PurchaseFurniture =
	newClientFunction("PurchaseFurniture", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>
Module.PurchaseTheme =
	newClientFunction("PurchaseTheme", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>
Module.InventoryChanged = newServerEvent("InventoryChanged", BaseType.BaseInventory) :: ServerEvent<BaseInventory>
Module.ArtifactGranted = newServerEvent("ArtifactGranted", Type.string) :: ServerEvent<string>
Module.DailyRewardGranted = newServerEvent("DailyRewardGranted", SessionType.DailyReward) :: ServerEvent<DailyReward>

-- residences
-- an error is why the door stays shut. once it answered, the server counts the player as inside + tells them of
-- every change until they say they left
Module.EnterResidence = newClientFunction(
	"EnterResidence",
	BaseType.ResidenceId,
	SessionType.ResidenceState,
	REQUEST_LIMIT
) :: ClientFunction<ResidenceState, ResidenceId>
Module.LeaveResidence = newClientEvent("LeaveResidence", Type.none, INPUT_LIMIT) :: ClientEvent<nil>
Module.ResidenceChanged = newServerEvent("ResidenceChanged", SessionType.ResidenceState) :: ServerEvent<ResidenceState>
-- the base of a residence, only its owner builds on it
Module.PlaceFurniture =
	newClientFunction("PlaceFurniture", isPlacement, isPlaced, REQUEST_LIMIT) :: ClientFunction<PlacedFurniture, FurniturePlacement>
-- a piece goes a stud or an eighth of a turn with every press of an arrow, across its pad that's a lot of them
Module.MoveFurniture =
	newClientFunction("MoveFurniture", isMove, isPlaced, INPUT_LIMIT) :: ClientFunction<PlacedFurniture, FurnitureMove>
Module.RemoveFurniture =
	newClientFunction("RemoveFurniture", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>
Module.SetBaseTheme =
	newClientFunction("SetBaseTheme", Type.string, Type.literal(true), REQUEST_LIMIT) :: ClientFunction<true, string>

-- quests
-- the server picks the goal, an error is the line the quest giver turns the player down with
Module.StartQuest =
	newClientFunction("StartQuest", isQuestType, QuestType.QuestState, REQUEST_LIMIT) :: ClientFunction<QuestState, PseudoEnum.QuestType>
Module.CancelQuest = newClientEvent("CancelQuest", Type.none, INPUT_LIMIT) :: ClientEvent<nil>
Module.QuestChanged = newServerEvent("QuestChanged", QuestType.QuestState) :: ServerEvent<QuestState>

-- tutorial
Module.SetTutorialEnabled = newClientEvent("SetTutorialEnabled", Type.boolean, INPUT_LIMIT) :: ClientEvent<boolean>

-- profiles
Module.GetProfiles =
	newClientFunction("GetProfiles", Type.none, isProfiles, REQUEST_LIMIT) :: ClientFunction<{ PublicProfile }, nil>
Module.ProfilesChanged = newServerEvent("ProfilesChanged", isProfiles) :: ServerEvent<{ PublicProfile }>

-- abilities
-- one remote each way, so a press + the claim that follows it arrive in the order they were made in
Module.AbilityReported =
	newClientEvent("AbilityReported", AbilityType.Report, ABILITY_LIMIT) :: ClientEvent<AbilityType.Report>
Module.AbilityUpdated = newServerEvent("AbilityUpdated", AbilityType.Update) :: ServerEvent<AbilityType.Update>

-- effects
Module.VFXReplicated = newServerEvent("VFXReplicated", VFXType.Message) :: ServerEvent<VFXType.Message>
-- only for what a player's own machine does to their own avatar, the server passes it on to everybody else
Module.VFXReported = newClientEvent("VFXReported", VFXType.Message, ABILITY_LIMIT) :: ClientEvent<VFXType.Message>

Module.list = function(): { Remote }
	return table.freeze(table.clone(Remotes))
end

return Module
