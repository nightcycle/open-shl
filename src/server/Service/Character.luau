--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
local Future = TypeUnionLib.Future
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterShareUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Share")
local CharacterSlotUtil = require("@game/ServerScriptService/Server/Util/CharacterSlot")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PaletteUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Palette")
local PatternAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Pattern")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local SpawnDefinition = require("@game/ServerScriptService/Server/Definition/Spawn")
local TextFilterUtil = require("@game/ServerScriptService/Server/Util/TextFilter")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Appearance = AppearanceType.Appearance
type Scale = AppearanceType.Scale
type Character = CharacterType.Character
type Power = CharacterType.Power
type IdentityKey = CharacterType.IdentityKey
type EntitlementKey = EconomyType.EntitlementKey
type Identity = IdentityType.Identity
type PowerSkin = IdentityType.PowerSkin
type PlayerSave = SaveType.PlayerSave
type Profile = {
	Name: string,
	Backstory: string,
	Alignment: PseudoEnum.Alignment,
}
-- the texts of both identities once they're through the filter
type Profiles = {
	Main: Profile,
	Secret: Profile,
}
type CharacterServiceImpl = {
	__index: CharacterServiceImpl,
	Sanitise: (self: CharacterService, player: Player, edited: Character) -> Result<Character, string>,
}
export type CharacterService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_IsSwapping: { [Player]: true? },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: CharacterServiceImpl
))
-- Constants
local HAIR_CATEGORY = "hair"
local MAX_NAME_LENGTH = CharacterEditorDefinition.MAX_NAME_LENGTH
local MAX_BACKSTORY_LENGTH = CharacterEditorDefinition.MAX_BACKSTORY_LENGTH
-- the longest text an editor has looked at before it's saved: a game with no backstory still has its names
local MAX_FILTERED_LENGTH = math.max(MAX_NAME_LENGTH, MAX_BACKSTORY_LENGTH)
local FILTER_TIMEOUT = 5
-- what an identity goes by when its name was left empty, nil in a game where an empty name stays empty
local NAME_DEFAULTS = CharacterEditorDefinition.NAME_DEFAULTS
-- the sizes a body can have are the game's own, nil in a game where every body is the size it comes in
local SCALE = CharacterEditorDefinition.SCALE
local SCALE_EPSILON = CharacterEditorDefinition.SCALE_EPSILON
-- a game that holds nothing back has nothing to ask about what a character wears
local HAS_LISTINGS = #AccessDefinition.list() > 0
-- the order a character is gone through in
local IDENTITY_KEYS: { IdentityKey } = table.freeze({ "Main" :: IdentityKey, "Secret" })
-- Variables
-- References
-- Private Functions
local function getCharacter(save: PlayerSave, characterId: string): Character?
	for _, character in save.Characters do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

local function clip(text: string, maxLength: number): string?
	local length = utf8.len(text)
	if not length then
		return nil
	end
	if length <= maxLength then
		return text
	end
	local cutOff = utf8.offset(text, maxLength + 1)
	return if cutOff then string.sub(text, 1, cutOff - 1) else text
end

local function filterText(player: Player, text: string): Result<string, string>
	local f = Future.timeout(TextFilterUtil.filter(text, player.UserId), FILTER_TIMEOUT)
	if f.IsCanceled then
		return Result.err(`the filter took too long`)
	end
	return f.Value
end

-- yields. a text the slot already holds went through the filter when it was stored, so it's kept as it is + it's
-- what the slot falls back to when the filter has no answer
local function filterProfileText(
	player: Player,
	text: string,
	maxLength: number,
	priorText: string
): Result<string, string>
	local clippedText = clip(text, maxLength)
	if not clippedText then
		return Result.err(`a text of the character can't be read`)
	end
	if clippedText == "" or clippedText == priorText then
		return Result.ok(clippedText)
	end
	local filterRes = filterText(player, clippedText)
	if filterRes.IsErr then
		warn(`text of {player.Name} kept as it was: {filterRes.Value}`)
		return Result.ok(priorText)
	end
	return filterRes
end

-- a name that's empty is the one the game makes up for its identity from the name of the account, where it makes one
-- up. that name is public the way it is, it doesn't go through the filter
local function getName(player: Player, identityKey: IdentityKey, name: string): string
	local default = if NAME_DEFAULTS then NAME_DEFAULTS[identityKey] else nil
	if name ~= "" or not default then
		return name
	end
	return clip(string.format(default, player.Name), MAX_NAME_LENGTH) or name
end

local function filterProfile(
	player: Player,
	identityKey: IdentityKey,
	profile: Profile,
	priorProfile: Profile
): Result<Profile, string>
	local nameRes = filterProfileText(player, profile.Name, MAX_NAME_LENGTH, priorProfile.Name)
	if nameRes.IsErr then
		return nameRes
	end
	local backstoryRes = filterProfileText(player, profile.Backstory, MAX_BACKSTORY_LENGTH, priorProfile.Backstory)
	if backstoryRes.IsErr then
		return backstoryRes
	end
	return Result.ok({
		-- a name the filter blanked out reads as unset, the name tag shows the user name for it
		Name = getName(player, identityKey, if string.match(nameRes.Value, "^#+$") then "" else nameRes.Value),
		Backstory = backstoryRes.Value,
		Alignment = profile.Alignment,
	})
end

-- turns down whoever asks to be another character in the middle of a fight: the line they're turned down with, nil
-- if they aren't. their client hears why the way it does when a menu stays shut to it, which is what it takes this
-- for: it's back where it would be had the button been faded in time
local function refuseFighting(player: Player): string?
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local isInMenu = SessionService:GetIfInMenu(player)
	local refusal = FightingUtil.getCharacterRefusal(player.Character, isInMenu, CombatDefinition.getTime())
	if not refusal then
		return nil
	end
	NetworkService:Fire(RemoteDefinition.MenuRefused, player, refusal)
	return `the avatar is in a fight`
end

local function getPowers(character: Character, powerLimit: number): Result<{ Power }, string>
	local out: { Power } = {}
	local ids: { string } = {}
	for _, power in character.Powers do
		table.insert(out, { Id = power.Id })
		table.insert(ids, power.Id)
	end
	-- what a character may hold is one question of the powers of the game, the editor asks the same one
	local loadoutError = PowerDefinition.getLoadoutError(ids, powerLimit)
	if loadoutError then
		return Result.err(loadoutError)
	end
	return Result.ok(out)
end

local function getPowerSkins(identity: Identity, powers: { Power }): { [string]: PowerSkin }
	local out: { [string]: PowerSkin } = {}
	for _, power in powers do
		local powerSkin = identity.PowerSkins[power.Id]
		local definitionRes = PowerDefinition.get(power.Id)
		if not powerSkin or powerSkin.ColorGroups.Primary == nil or definitionRes.IsErr then
			continue
		end
		local colorOpt = PowerDefinition.getColor(definitionRes.Value, powerSkin.ColorGroups.Primary)
		if colorOpt.IsSome then
			out[power.Id] = {
				Id = power.Id,
				ColorGroups = {
					Primary = colorOpt.Value,
				},
			}
		end
	end
	return out
end

local function getIfMultiHair(appearance: Appearance): boolean
	local count = 0
	for _, item in appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == HAIR_CATEGORY then
			count += 1
		end
	end
	return count > 1
end

-- a size is kept when it's one the game offers, any other is the size a body starts at. a game without sizes keeps
-- none, + a look that was never given one is left without
local function getScale(scale: Scale?): Scale?
	if not SCALE or not scale then
		return nil
	end
	local isOffered = false
	for _, height in SCALE.Heights do
		isOffered = isOffered or math.abs(scale.Height - height) < SCALE_EPSILON
	end
	if not isOffered then
		return SCALE.Default
	end
	for _, ratio in SCALE.WidthRatios do
		if math.abs(scale.Width / scale.Height - ratio) < SCALE_EPSILON then
			return scale
		end
	end
	return SCALE.Default
end

-- what a look holds beyond its items is checked against the game as well: a size nobody can pick or a pattern there's
-- no image for would be stored for good + never be seen, a color that's off the palette of the game is one no picker
-- of it could have put there
local function fixAppearance(appearance: Appearance): Appearance
	local fixedAppearance = PaletteUtil.apply(AppearanceConstructor.fix(appearance))
	return FreezeUtil.delta(fixedAppearance, function(t: Appearance): Appearance
		t.Scale = getScale(t.Scale)
		for _, item in t.Items do
			for _, textureGroup in item.TextureGroups do
				local pattern = if textureGroup then textureGroup.Pattern else nil
				if textureGroup and pattern ~= nil and PatternAppearanceDefinition.get(pattern).IsErr then
					textureGroup.Pattern = nil
				end
			end
		end
		return t
	end)
end

local function newIdentity(
	identity: Identity,
	profile: Profile,
	powers: { Power },
	entitlements: { EntitlementKey }
): Result<Identity, string>
	local appearance = fixAppearance(identity.Appearance)
	if getIfMultiHair(appearance) and not table.find(entitlements, "MultiHair") then
		return Result.err(`more than one hair needs the multi hair pass`)
	end
	return Result.ok({
		Profile = profile,
		PowerSkins = getPowerSkins(identity, powers),
		Appearance = appearance,
	})
end

-- yields. the text goes first: the filter yields, everything after it reads the session the way it is by then
local function filterProfiles(player: Player, edited: Character): Result<Profiles, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local priorSessionOpt = SessionService:Get(player)
	local prior = if priorSessionOpt.IsSome then getCharacter(priorSessionOpt.Value.Save, edited.Id) else nil
	local main, secret = edited.Identities.Main, edited.Identities.Secret
	local priorSecret = prior and prior.Identities.Secret
	if not prior or not secret or not priorSecret then
		return Result.err(`no slot holds the character`)
	end
	local mainProfileRes = filterProfile(player, "Main", main.Profile, prior.Identities.Main.Profile)
	if mainProfileRes.IsErr then
		return mainProfileRes
	end
	local secretProfileRes = filterProfile(player, "Secret", secret.Profile, priorSecret.Profile)
	if secretProfileRes.IsErr then
		return secretProfileRes
	end
	return Result.ok({
		Main = mainProfileRes.Value,
		Secret = secretProfileRes.Value,
	})
end

-- what's left of a character a client handed in once it's held to the game: the powers it may hold, each look down
-- to what the game has + what both identities have the same. it can't yield
local function newSanitised(player: Player, edited: Character, profiles: Profiles): Result<Character, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local main, secret = edited.Identities.Main, edited.Identities.Secret
	if not secret then
		return Result.err(`no slot holds the character`)
	end
	local entitlements = SessionService:GetEntitlements(player)
	local powersRes = getPowers(edited, ProductDefinition.getPowerLimit(entitlements))
	if powersRes.IsErr then
		return powersRes
	end
	local mainRes = newIdentity(main, profiles.Main, powersRes.Value, entitlements)
	if mainRes.IsErr then
		return mainRes
	end
	local secretRes = newIdentity(secret, profiles.Secret, powersRes.Value, entitlements)
	if secretRes.IsErr then
		return secretRes
	end
	-- whatever the client made of it, what the identities of the game have the same is the hero's
	return Result.ok(CharacterShareUtil.apply({
		Id = edited.Id,
		Powers = powersRes.Value,
		Identities = {
			Main = mainRes.Value,
			Secret = secretRes.Value,
		},
	}, "Main"))
end

-- an item the list of its category leaves out is nobody's: nothing opens it + no row of an editor steps to it. what a
-- slot held of those may stay, like anything else it held
local function getUnlistedError(character: Character, kept: AccessDefinition.Kept): string?
	for _, identityKey: IdentityKey in IDENTITY_KEYS do
		local identity = character.Identities[identityKey]
		local keptIds = kept.ItemIds[identityKey]
		if not identity then
			continue
		end
		for _, item in identity.Appearance.Items do
			local definitionRes = ItemAppearanceDefinition.get(item.DefinitionId)
			if
				definitionRes.IsOk
				and definitionRes.Value.Order == nil
				and definitionRes.Value.IsStarter == false
				and not (keptIds and keptIds[item.DefinitionId])
			then
				return `"{definitionRes.Value.Name or item.DefinitionId}" isn't on offer`
			end
		end
	end
	return nil
end

-- what a character holds that its player doesn't have, as the line they're turned down with. whatever the slot held
-- before may stay where it was: what a pad dressed it in, what came over from the old game + what was saved before
-- anything was held back. once it's off it has to be got the way everybody gets it to go back on. nothing is taken
-- off silently: an editor never sends such a character, so only a client that was tampered with reads the line
local function getAccessError(player: Player, character: Character, prior: Character): string?
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if not HAS_LISTINGS then
		return nil
	end
	local kept = AccessDefinition.getKept(prior)
	local listing = AccessDefinition.getUnowned(character, SessionService:GetOwned(player), kept)[1]
	if not listing then
		return getUnlistedError(character, kept)
	end
	local lock = listing.Lock
	if not lock then
		return `"{listing.Name}" isn't owned`
	elseif lock.Type == "GroupPerk" then
		return `"{listing.Name}" is for members of the group`
	end
	local passRes = ProductDefinition.getFromEntitlement(lock.Key)
	return `"{listing.Name}" needs the {if passRes.IsOk then passRes.Value.Name else lock.Key} pass`
end

-- yields. nothing a client hands in is stored as it came, the slot keeps its id + takes what's left of the rest
local function saveCharacter(player: Player, edited: Character): Result<Character, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local profilesRes = filterProfiles(player, edited)
	if profilesRes.IsErr then
		return profilesRes
	end
	local sessionOpt = if SessionService.IsInitialized then SessionService:Get(player) else Option.none()
	local prior = if sessionOpt.IsSome then getCharacter(sessionOpt.Value.Save, edited.Id) else nil
	if sessionOpt.IsNone or not prior then
		return Result.err(`no slot holds the character`)
	end
	-- the character that's out changes on the avatar as it's saved: its look + its powers. for whoever is in a
	-- fight that's another character all the same
	local fightError = if edited.Id == sessionOpt.Value.Save.ActiveCharacterId then refuseFighting(player) else nil
	if fightError then
		return Result.err(fightError)
	end
	local characterRes = newSanitised(player, edited, profilesRes.Value)
	if characterRes.IsErr then
		return characterRes
	end
	local character = characterRes.Value
	local accessError = getAccessError(player, character, prior)
	if accessError then
		return Result.err(accessError)
	end
	local saveRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		for index, other in t.Characters do
			if other.Id == character.Id then
				t.Characters[index] = character
			end
		end
		return t
	end)
	if saveRes.IsErr then
		return saveRes
	end
	local saved = getCharacter(saveRes.Value, character.Id)
	if not saved then
		return Result.err(`no slot holds the character`)
	end
	return Result.ok(saved)
end

-- what a player asks to own of what the game holds back at a price, by one of its items or its power. the price +
-- everything it hands over are the listing's, nothing of either is the client's to say
local function purchaseItem(player: Player, id: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local listing = AccessDefinition.getOf(id)
	local access = if listing then AccessDefinition.getListingAccess(listing) else nil
	if not listing or not access or access.Type ~= "Price" then
		return Result.err(`"{id}" isn't sold`)
	end
	local powerId = listing.PowerId
	-- a power is listed ahead of its ability, nobody pays for one they couldn't hold
	if powerId and PowerDefinition.get(powerId).IsErr then
		return Result.err(`"{listing.Name}" isn't out yet`)
	end
	if not EconomyService.IsInitialized then
		return Result.err(`nothing is sold yet`)
	end
	return EconomyService:Purchase(player, {
		Id = listing.Id,
		Name = listing.Name,
		Price = access.Amount,
		Currency = access.Currency,
	}, function(save: PlayerSave): { string }
		assert(SessionService.IsInitialized, `the session service isn't initialized`)
		local owned = SessionService:GetOwnedOf(save)
		assert(owned, `a game that sells something keeps what was bought`)
		return if powerId then owned.PowerIds else owned.ItemIds
	end, listing.ItemIds or { powerId :: string })
end

-- a character dealt anew out of what the player has, under the id of the slot it was asked for. nothing is stored:
-- it's a draft, it only becomes the character by a save, which holds it to everything a save is held to
local function rollCharacter(player: Player, characterId: string): Result<Character, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone or not getCharacter(sessionOpt.Value.Save, characterId) then
		return Result.err(`no slot holds the character`)
	end
	local rollRes = CharacterSlotUtil.roll(SessionService:GetOwned(player))
	if rollRes.IsErr then
		return rollRes
	end
	return Result.ok(FreezeUtil.delta(rollRes.Value, function(t: Character): Character
		t.Id = characterId
		return t
	end))
end

local function selectCharacter(player: Player, characterId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if not getCharacter(sessionOpt.Value.Save, characterId) then
		return Result.err(`no slot holds the character`)
	end
	-- nobody walks out of a fight as somebody else
	local fightError = refuseFighting(player)
	if fightError then
		return Result.err(fightError)
	end
	local saveRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		if t.ActiveCharacterId == characterId then
			return nil
		end
		t.ActiveCharacterId = characterId
		return t
	end)
	if saveRes.IsErr then
		return saveRes
	end
	-- a selected character is always worn as the identity the game has one come in as (its super identity, unless
	-- the game says another), the one that's worn already included. whoever the server put in a costume stays who it
	-- says
	local costumeOpt = if AvatarService.IsInitialized then AvatarService:GetCostume(player) else Option.none()
	local identityKey: IdentityKey = if costumeOpt.IsSome
		then costumeOpt.Value.IdentityKey
		else SpawnDefinition.START_IDENTITY_KEY
	return SessionService:SetActiveIdentity(player, identityKey)
end

-- the client plays the animation of the transformation + asks once, the server picks the moment the costume
-- changes behind it. nothing about the swap is read from the client
local function swapIdentity(self: CharacterService, player: Player): Result<IdentityKey, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	local characterOpt = SessionService:GetActiveCharacter(player)
	local avatar = player.Character
	if sessionOpt.IsNone or characterOpt.IsNone or not avatar then
		return Result.err(`there's no avatar to swap`)
	end
	if self._IsSwapping[player] then
		return Result.err(`a swap is already underway`)
	end
	-- whoever the server put in a costume is who it says, there's nobody else to become
	if AvatarService.IsInitialized and AvatarService:GetCostume(player).IsSome then
		return Result.err(`there's nobody to swap to in a costume`)
	end
	local character = characterOpt.Value
	local identityKey: IdentityKey = sessionOpt.Value.ActiveIdentityKey
	local nextIdentityKey: IdentityKey = if identityKey == "Main" then "Secret" else "Main"
	local identity = character.Identities[identityKey]
	if not identity or not character.Identities[nextIdentityKey] then
		return Result.err(`the character has no identity to swap to`)
	end
	local transformation = identity.Appearance.Transitions.Transformation
	local definition = TransitionDefinition.getTransformation(transformation and transformation.Style)
	self._IsSwapping[player] = true
	local effect = definition.Effect
	if effect then
		task.delay(effect.StartDelay, function()
			if AvatarService.IsInitialized and player.Character == avatar then
				AvatarService:PlayEffect(avatar, effect)
			end
		end)
	end
	task.delay(definition.SwapDelay, function()
		if not self.IsInitialized or not SessionService.IsInitialized then
			return
		end
		self._IsSwapping[player] = nil
		local newSessionOpt = SessionService:Get(player)
		if
			newSessionOpt.IsNone
			or newSessionOpt.Value.Save.ActiveCharacterId ~= character.Id
			or newSessionOpt.Value.ActiveIdentityKey ~= identityKey
		then
			return
		end
		local identityRes = SessionService:SetActiveIdentity(player, nextIdentityKey)
		if identityRes.IsErr then
			warn(`swap err: {identityRes.Value}`)
		end
	end)
	return Result.ok(nextIdentityKey :: any) :: TypeUnionLib.Ok<IdentityKey>
end

-- the slots an entitlement unlocks come with it, whenever + however it was granted
local function fillSlots(player: Player)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return
	end
	local slotCount = ProductDefinition.getCharacterSlotCount(SessionService:GetEntitlements(player))
	if #sessionOpt.Value.Save.Characters >= slotCount then
		return
	end
	-- a slot that's added later is filled out of what its player has by then
	local owned = SessionService:GetOwned(player)
	local saveRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		for _ = #t.Characters + 1, slotCount do
			table.insert(t.Characters, CharacterSlotUtil.newBlank(owned))
		end
		return t
	end)
	if saveRes.IsErr then
		warn(`slot err: {saveRes.Value}`)
	end
end
-- Class
local CharacterService = {} :: CharacterServiceImpl
CharacterService.__index = CharacterService

-- yields. a character a client handed in the way a save would store it: its texts through the filter, its powers +
-- its looks held to the game. nothing is written, + what its player has isn't asked about: both are up to whoever
-- stores it
function CharacterService:Sanitise(player: Player, edited: Character): Result<Character, string>
	local profilesRes = filterProfiles(player, edited)
	if profilesRes.IsErr then
		return profilesRes
	end
	if not self.IsInitialized or not SessionService.IsInitialized or SessionService:Get(player).IsNone then
		return Result.err(`no slot holds the character`)
	end
	return newSanitised(player, edited, profilesRes.Value)
end

return ServiceLocker(function(): CharacterService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_IsSwapping = {} :: { [Player]: true? },
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CharacterService)

	NetworkService:Handle(
		RemoteDefinition.SelectCharacter,
		function(player: Player, characterId: string): Result<true, string>
			return selectCharacter(player, characterId)
		end
	)
	NetworkService:Handle(RemoteDefinition.SwapIdentity, function(player: Player): Result<IdentityKey, string>
		return swapIdentity(self, player)
	end)
	NetworkService:Handle(
		RemoteDefinition.SaveCharacter,
		function(player: Player, character: Character): Result<Character, string>
			return saveCharacter(player, character)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.RollCharacter,
		function(player: Player, characterId: string): Result<Character, string>
			return rollCharacter(player, characterId)
		end
	)
	-- only a game that holds something back has anything to sell here
	if HAS_LISTINGS then
		NetworkService:Handle(RemoteDefinition.PurchaseItem, function(player: Player, id: string): Result<true, string>
			return purchaseItem(player, id)
		end)
	end
	NetworkService:Handle(RemoteDefinition.FilterText, function(player: Player, text: string): Result<string, string>
		local clippedText = clip(text, MAX_FILTERED_LENGTH)
		if not clippedText then
			return Result.err(`the text can't be read`)
		end
		if clippedText == "" then
			return Result.ok(clippedText)
		end
		local filterRes = filterText(player, clippedText)
		if filterRes.IsErr then
			-- what the filter threw isn't a line a menu can show
			warn(`text of {player.Name} wasn't filtered: {filterRes.Value}`)
			return Result.err(`the text couldn't be filtered`)
		end
		return filterRes
	end)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		fillSlots(player)
	end)
	local changedConnection = SessionService.Changed:Connect(function(player: Player)
		fillSlots(player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		self._IsSwapping[player] = nil
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		changedConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	for _, player in Players:GetPlayers() do
		fillSlots(player)
	end

	return self
end, function(self: CharacterService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
