--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local Result = TypeUnionLib.Result
-- Modules
local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
local ApartmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Apartment")
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local MapDefinition = require("@game/ReplicatedStorage/Shared/Definition/Map")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local ResidenceType = require("@game/ServerScriptService/Server/Type/Residence")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SharedResidenceType = require("@game/ReplicatedStorage/Shared/Type/Residence")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type TextureGroupKey = AppearanceType.TextureGroupKey
type PlayerSave = SaveType.PlayerSave
type Session = SessionService.Session
type ResidenceState = SharedResidenceType.SHL3State
type State = SharedResidenceType.State
type Slot = ResidenceType.Slot
type Rooms = ResidenceType.Rooms
type Rule = ResidenceType.Rule
-- Constants
-- the number a flat is named by, the last thing in the id of its anchor
local SLOT_NUMBER_PATTERN = "%d+$"
-- studs past where a talk with the salesman is had that the server still sells from: where an avatar stands is its
-- client's to say first, the server's reading runs behind it
local SALE_LENIENCY = 10
local SALE_REACH = ApartmentDefinition.CONVERSATION_DISTANCE + SALE_LENIENCY
local SALESMAN_LOOK = ApartmentDefinition.SALESMAN_LOOK
local SALESMAN_ROOT_NAME = "HumanoidRootPart"
local SALESMAN_HEAD_NAME = "Head"
local SALESMAN_LABEL_NAME = "NameLabel"
local PROMPT_ACTION_TEXT = "Talk"
local DRESS_TIMEOUT = 20
-- the pad of the lobby that takes an owner up to their flat
local ENTRANCE_PAD_NAME = "Telepad"
-- seconds before somebody who waits for a flat is told again that there's none, as long as the line is read for
local FULL_ALERT_COOLDOWN = 6
-- Variables
-- References
-- Private Functions
local function getSlots(): { Slot }
	local out: { Slot } = {}
	local numbers: { [string]: number } = {}
	for _, anchor in MapDefinition.list(MapDefinition.ApartmentAnchor) do
		local idRes = MapDefinition.get(anchor, MapDefinition.ResidenceId)
		local digits = if idRes.IsOk then string.match(idRes.Value, SLOT_NUMBER_PATTERN) else nil
		local number = if digits then tonumber(digits) else nil
		if
			idRes.IsErr
			or not number
			or not SharedResidenceType.SHL3ResidenceId(idRes.Value)
			or numbers[idRes.Value]
		then
			warn(`{anchor:GetFullName()} isn't the anchor of a flat`)
			continue
		end
		numbers[idRes.Value] = number
		table.insert(out, {
			Id = idRes.Value,
			-- nothing of the tower shows who lives where
			SetOwner = function(_player: Player?) end,
		})
	end
	if #out == 0 then
		warn(`the map has no flats, nobody gets a residence`)
	end
	-- the old place handed out the last free anchor it came by: the top floor goes first
	table.sort(out, function(a: Slot, b: Slot): boolean
		return numbers[a.Id] > numbers[b.Id]
	end)
	return out
end

-- a number that's no flat is no flat: a save is never narrowed to the ones there are
local function getTier(save: PlayerSave): number?
	local section = save.SHL3
	if not section or ApartmentDefinition.get(section.ApartmentTier).IsErr then
		return nil
	end
	return section.ApartmentTier
end

-- any flat but the one that's owned is sold at its full price, a dearer one + a cheaper one alike. nothing is paid
-- back for the one it takes the place of
local function purchase(salesmanRoot: BasePart?, player: Player, tier: number): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local rowRes = ApartmentDefinition.get(tier)
	if rowRes.IsErr then
		return rowRes
	end
	local row = rowRes.Value
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local character = player.Character
	local rootPart = if character then character.PrimaryPart else nil
	if
		not character
		or not rootPart
		or AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
	then
		return Result.err(`there's no avatar to buy a flat with`)
	end
	-- the old place sold to whoever fired its remote, wherever they stood
	if not salesmanRoot or (rootPart.Position - salesmanRoot.Position).Magnitude > SALE_REACH then
		return Result.err(`the salesman is too far away`)
	end
	local save = sessionOpt.Value.Save
	if not save.SHL3 then
		return Result.err(`the save of {player.Name} keeps no flat`)
	end
	-- the old place charged for it again
	if getTier(save) == row.Tier then
		return Result.err(`"{row.Name}" is already owned`)
	end
	return EconomyService:Spend(player, row.Currency, row.Price, function(t: PlayerSave)
		local section = t.SHL3
		if section then
			section.ApartmentTier = row.Tier
		end
	end)
end

-- the look of the salesman as the items of the game, each in the colors his record gave it
local function newSalesmanAppearance(): Appearance
	local items: { Item } = {}
	for _, piece in SALESMAN_LOOK.Items do
		local definitionRes = ItemAppearanceDefinition.get(piece.DefinitionId)
		if definitionRes.IsErr then
			warn(`salesman err: {definitionRes.Value}`)
			continue
		end
		local item: Item = {
			DefinitionId = piece.DefinitionId,
			TextureGroups = {},
		}
		for _, key: TextureGroupKey in definitionRes.Value.TextureGroups do
			local color = piece.Colors[key]
				or (if key == "Hair" then SALESMAN_LOOK.HairColor else nil)
				or (if key == "Skin" then SALESMAN_LOOK.SkinColor else nil)
			if color then
				item.TextureGroups[key] = TextureGroupConstructor.new(color)
			end
		end
		table.insert(items, item)
	end
	return {
		Items = items,
		SkinColor = SALESMAN_LOOK.SkinColor,
		Scale = SALESMAN_LOOK.Scale,
		Transitions = {},
		HiddenTags = {},
	}
end

-- the map has him bare, with the engine's own dialog of the old place under his head. here he's dressed + talked to
-- through a prompt, which a client opens the panel of his flats on
local function setUpSalesman(salesman: Model): BasePart?
	local rootPart = salesman:FindFirstChild(SALESMAN_ROOT_NAME)
	local head = salesman:FindFirstChild(SALESMAN_HEAD_NAME)
	if not rootPart or not rootPart:IsA("BasePart") then
		warn(`{salesman:GetFullName()} has no root, nobody is sold a flat`)
		return nil
	end
	for _, desc in salesman:GetDescendants() do
		if desc:IsA("Dialog") then
			desc:Destroy()
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = ApartmentDefinition.SALESMAN_NAME
	prompt.ActionText = PROMPT_ACTION_TEXT
	prompt.MaxActivationDistance = ApartmentDefinition.CONVERSATION_DISTANCE
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = rootPart

	-- the old place wrote the name of his record over the label as it dressed him, the map's own word for him stays
	local label = if head then head:FindFirstChild(SALESMAN_LABEL_NAME) else nil
	local text = if label then label:FindFirstChildWhichIsA("TextLabel", true) else nil
	if text then
		text.Text = ApartmentDefinition.SALESMAN_NAME
	end
	-- the dress is a web call. a body that's built anew may come with a new head, the label is kept out of its way
	if label then
		label.Parent = nil
	end
	task.spawn(function()
		local f = Future.timeout(AppearanceUtil.apply(salesman, newSalesmanAppearance(), nil), DRESS_TIMEOUT)
		if f.IsCanceled then
			warn(`salesman err: he wasn't dressed in time`)
		elseif f.Value.IsErr then
			warn(`salesman err: {table.concat(f.Value.Value, ", ")}`)
		end
		local newHead = salesman:FindFirstChild(SALESMAN_HEAD_NAME)
		if label and newHead then
			label.Parent = newHead
		end
	end)
	return rootPart
end

-- the requests only this game takes: a flat is bought from the salesman in the lobby of the tower
local function start(rooms: Rooms): (() -> ())?
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local connections: { RBXScriptConnection } = {}

	-- the server holds the whole map, whatever streaming does to a client
	local salesmanRoot: BasePart? = nil
	for _, salesman in MapDefinition.list(MapDefinition.ApartmentSalesman) do
		salesmanRoot = salesmanRoot or setUpSalesman(salesman)
	end
	if not salesmanRoot then
		warn(`the map has no salesman, nobody is sold a flat`)
	end
	NetworkService:Handle(
		RemoteDefinition.PurchaseApartment,
		function(player: Player, tier: number): Result<true, string>
			return purchase(salesmanRoot, player, tier)
		end
	)
	-- whatever wrote the flat of a save: a first one is moved into right away, a change keeps the anchor the visit
	-- began at
	local changedConnection = SessionService.Changed:Connect(
		function(player: Player, session: Session, priorSession: Session)
			if (getTier(session.Save) ~= nil) ~= (getTier(priorSession.Save) ~= nil) then
				rooms.Rehouse(player)
			end
		end
	)

	-- the tower has fewer flats than a server has players. the old place built the room of whoever was one too many
	-- far out over the sea, here they wait for a flat + are told so where they'd go up
	local alertedAt: { [Player]: number } = {}
	local function onPadTouched(pad: BasePart, hit: BasePart)
		local player, character = TouchUtil.getToucher(hit)
		local sessionOpt = if player then SessionService:Get(player) else nil
		if not player or not character or not sessionOpt or sessionOpt.IsNone then
			return
		end
		if
			not getTier(sessionOpt.Value.Save)
			or AttributeDefinition.get(player, AttributeDefinition.ResidenceId) ~= nil
			or not TouchUtil.getIfNear(character, pad, TouchUtil.REACH)
		then
			return
		end
		local now = os.clock()
		local priorTime = alertedAt[player]
		if priorTime and now - priorTime < FULL_ALERT_COOLDOWN then
			return
		end
		alertedAt[player] = now
		-- a place without the strip has nowhere to say it
		if AlertService.IsInitialized then
			AlertService:Announce(ApartmentDefinition.FULL_ALERT, { player })
		end
	end
	for _, entrance in MapDefinition.list(MapDefinition.ApartmentEntrance) do
		local pad = entrance:FindFirstChild(ENTRANCE_PAD_NAME)
		if not pad or not pad:IsA("BasePart") then
			warn(`{entrance:GetFullName()} has no pad, nobody who waits for a flat is told`)
			continue
		end
		local entrancePad: BasePart = pad
		table.insert(
			connections,
			entrancePad.Touched:Connect(function(hit: BasePart)
				onPadTouched(entrancePad, hit)
			end)
		)
	end
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		alertedAt[player] = nil
	end)

	return function()
		changedConnection:Disconnect()
		removingConnection:Disconnect()
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(alertedAt)
	end
end
-- Class
-- a residence of superhero life 3 is a flat of the apartment tower: it's bought from the salesman in its lobby, how
-- good a one is all there is to it + nobody but its owner gets in
local Rule: Rule = table.freeze({
	GetSlots = getSlots,
	-- only whoever bought a flat has one
	GetIfHoused = function(save: PlayerSave): boolean
		return getTier(save) ~= nil
	end,
	-- the lobby has one pad for everybody + no door to knock on
	GetIfLocked = function(_save: PlayerSave): boolean
		return true
	end,
	NewState = function(residenceId: string, owner: Player, save: PlayerSave): State
		local state: ResidenceState = {
			ResidenceId = residenceId,
			OwnerUserId = owner.UserId,
			Tier = getTier(save) or 0,
		}
		return table.freeze(state)
	end,
	Start = start,
})

return Rule
