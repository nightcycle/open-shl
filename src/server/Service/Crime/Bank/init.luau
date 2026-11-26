--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BankDefinition = require("@game/ServerScriptService/Server/Definition/Bank")
local BeamSweeper = require("@self/Beams")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local EnvironmentService = require("@game/ServerScriptService/Server/Service/Environment")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RobberyUtil = require("@self/Robbery")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
local TeamService = require("@game/ServerScriptService/Server/Service/Team")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- somebody whose touch of a part of the bank counts
type Visitor = {
	Player: Player,
	Character: Model,
	TeamId: TeamId,
}
export type Runner = {
	Destroy: () -> (),
}
-- a half of the door of a vault, + what the map says of it
type Half = {
	Model: Model,
	ClosedPivot: CFrame,
	Slide: number,
}
-- a vault of a bank: a button that opens it + a pad that hands out what it holds
type Vault = {
	Index: number,
	IsOpen: boolean,
	Halves: { Half },
	Trigger: BasePart?,
	-- what the button is made of while nobody pushed it
	Material: Enum.Material,
	-- who stepped on its pad since its last round, in the order they did
	Standing: { Player },
	-- runs out as its halves got to where they slide to
	RestThread: thread?,
}
-- Constants
-- what the map files the parts of a bank under, + the pattern its vaults are numbered by
local FRONT_DOOR_NAME = "FrontDoor"
local ROBBER_SPAWN_NAME = "VillainSpawn"
local GUARD_SPAWN_NAME = "HeroSpawn"
local DOORS_NAME = "Doors"
local PADS_NAME = "MoneyGivers"
local VAULT_PATTERN = "^Vault(%d+)$"
local BUTTON_NAME = "Button"
local TRIGGER_NAME = "Trigger"
local PAD_NAME = "MoneyPad"
-- what the old place kept its books in, on the map: the state of a bank is the server's own
local LEDGER_NAME = "BankPeeps"
-- a button that was pushed glows until the bank shuts
local PRESSED_MATERIAL = Enum.Material.Neon
-- Variables
-- References
-- Private Functions
local function cancel(thread: thread?)
	if thread and coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
end

-- the number a vault is filed under
local function getIndex(inst: Instance): number?
	local digits = string.match(inst.Name, VAULT_PATTERN)
	return if digits then tonumber(digits) else nil
end

-- one bank of the map, from when it's in the world until what's returned is called
local function run(model: Model): () -> ()
	assert(AlertService.IsInitialized, `the alert service isn't initialized`)
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(TeamService.IsInitialized, `the team service isn't initialized`)
	local state = RobberyUtil.new()
	local vaults: { [number]: Vault } = {}
	local connections: { RBXScriptConnection } = {}
	-- what tells that somebody on a list went down, for as long as a robbery has them on one
	local watches: { [Player]: { RBXScriptConnection } } = {}

	-- listed first: what's under something that's destroyed goes with it
	local books: { Instance } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ValueBase") or descendant.Name == LEDGER_NAME then
			table.insert(books, descendant)
		end
	end
	for _, book in books do
		book:Destroy()
	end

	local frontDoor = model:FindFirstChild(FRONT_DOOR_NAME)
	local robberSpawn, guardSpawn = model:FindFirstChild(ROBBER_SPAWN_NAME), model:FindFirstChild(GUARD_SPAWN_NAME)

	local function getVault(index: number): Vault
		local vault = vaults[index]
		if not vault then
			vault = {
				Index = index,
				IsOpen = false,
				Halves = {},
				Material = Enum.Material.Plastic,
				Standing = {},
			}
			vaults[index] = vault
		end
		return vault
	end

	local function unwatch(player: Player)
		local watch = watches[player]
		if watch then
			watches[player] = nil
			for _, connection in watch do
				connection:Disconnect()
			end
		end
	end

	-- the look of the front door: in the way of everybody while the bank is shut
	local function setDoor(isOpen: boolean)
		if frontDoor and frontDoor:IsA("BasePart") then
			local door = BankDefinition.DOOR
			frontDoor.Transparency = if isOpen then door.OpenTransparency else door.ShutTransparency
			frontDoor.CanCollide = not isOpen
		end
	end

	-- every client slides the halves it has by what's said here, the server only has them where they come to rest
	local function setVault(vault: Vault, isOpen: boolean)
		cancel(vault.RestThread)
		vault.IsOpen = isOpen
		local trigger = vault.Trigger
		if trigger then
			trigger.Material = if isOpen then PRESSED_MATERIAL else vault.Material
		end
		local now = Workspace:GetServerTimeNow()
		-- the time goes out first: a client that draws between the two is still on its way to where the half was
		for _, half in vault.Halves do
			MapDefinition.set(half.Model, MapDefinition.ChangedAt, now)
			MapDefinition.set(half.Model, MapDefinition.IsOpen, isOpen)
		end
		vault.RestThread = task.delay(BankDefinition.VAULT_DOOR.Duration, function()
			vault.RestThread = nil
			for _, half in vault.Halves do
				half.Model:PivotTo(half.ClosedPivot + Vector3.new(0, if isOpen then half.Slide else 0, 0))
			end
		end)
	end

	-- a touch only counts for an avatar that's up, out of every menu + that the server has at the part, where
	-- players fight + for somebody on a side. nobody robs a bank from where no beam + no hero gets at them
	local function getVisitor(part: BasePart, hit: BasePart): Visitor?
		local player, character = TouchUtil.getToucher(hit)
		if
			not player
			or not character
			or not ModeDefinition.getIfPVPEnabled()
			or not TakeDownUtil.getIfAlive(character)
			or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
			or not TouchUtil.getIfNear(character, part, TouchUtil.REACH)
		then
			return nil
		end
		local teamId: TeamId? = TeamService:GetTeamId(player)
		if not teamId then
			return nil
		end
		return {
			Player = player,
			Character = character,
			TeamId = teamId :: TeamId,
		}
	end

	-- whoever is at any part of an open bank is in it: the door they came through is a thin sheet, somebody fast
	-- may get past it without a touch. the first robber of a robbery has the town told
	local function file(visitor: Visitor)
		local player, character = visitor.Player, visitor.Character
		local isFirst: boolean
		state, isFirst = RobberyUtil.enter(state, player, visitor.TeamId)
		if isFirst then
			AlertService:Announce(BankDefinition.ALERT)
		end
		-- watched from when they're on a list until they go down, which takes the watch off again
		local isUp = state.Robbers[player] == false or state.Guards[player] == false
		if not isUp or watches[player] then
			return
		end
		local function onDown()
			unwatch(player)
			state = RobberyUtil.down(state, player)
		end
		watches[player] = {
			character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
				if AttributeDefinition.get(character, AttributeDefinition.IsDead) then
					onDown()
				end
			end),
			-- an avatar that's gone went down as far as the bank can tell: its player left or dressed anew
			character.AncestryChanged:Connect(function()
				if not character:IsDescendantOf(Workspace) then
					onDown()
				end
			end),
		}
	end

	-- nobody is on a list any more + every vault is shut
	local function clear()
		for player in table.clone(watches) do
			unwatch(player)
		end
		for _, vault in vaults do
			table.clear(vault.Standing)
			if vault.IsOpen then
				setVault(vault, false)
			end
		end
	end

	-- everybody who came in + is still up is put outside by the door, wherever they got to since
	local function evict(players: { Player }, spot: Instance?)
		if not spot or not spot:IsA("BasePart") then
			return
		end
		for _, player in players do
			local character = player.Character
			if character and character:IsDescendantOf(Workspace) and TakeDownUtil.getIfAlive(character) then
				character:PivotTo(spot.CFrame)
			end
		end
	end

	local function close()
		local filed: RobberyUtil.Filed
		state, filed = RobberyUtil.close(state)
		setDoor(false)
		clear()
		evict(filed.Robbers, robberSpawn)
		evict(filed.Guards, guardSpawn)
	end

	-- a round of every pad: everybody who stepped on one since the last is handed their share of its vault
	local function pay()
		for _, vault in vaults do
			local standing: { Player } = {}
			for _, player in vault.Standing do
				-- somebody who left since is handed nothing
				if SessionService:Get(player).IsSome then
					table.insert(standing, player)
				end
			end
			table.clear(vault.Standing)
			local payments: RobberyUtil.Payments
			state, payments = RobberyUtil.pay(state, vault.Index, standing)
			for _, player in standing do
				local amount = payments[player]
				if not amount then
					continue
				end
				local grantRes = EconomyService:Grant(player, PseudoEnum.Currency.Credits, amount)
				if grantRes.IsErr then
					warn(`bank err: {player.Name} isn't handed {amount}: {grantRes.Value}`)
					state = RobberyUtil.refund(state, vault.Index, amount)
				end
			end
		end
	end

	-- the look the old place took every few seconds: a robbery that's over shuts the bank, a shut one opens in the
	-- morning of the city
	local function check()
		if state.IsOpen then
			local isOver: boolean
			state, isOver = RobberyUtil.step(state, BankDefinition.CHECK_INTERVAL)
			if isOver then
				close()
			end
		elseif RobberyUtil.getIfReopening(EnvironmentService:GetClockTime()) then
			state = RobberyUtil.new()
			setDoor(true)
		end
	end

	if frontDoor and frontDoor:IsA("BasePart") then
		table.insert(
			connections,
			frontDoor.Touched:Connect(function(hit: BasePart)
				local visitor = getVisitor(frontDoor, hit)
				if visitor then
					file(visitor)
				end
			end)
		)
	else
		warn(`{model:GetFullName()} has no "{FRONT_DOOR_NAME}", nobody is seen coming in`)
	end
	if not robberSpawn or not guardSpawn then
		warn(`{model:GetFullName()} lacks a spot to put somebody outside at`)
	end

	local doors = model:FindFirstChild(DOORS_NAME)
	local doorFolders: { Instance } = if doors then doors:GetChildren() else {}
	for _, folder in doorFolders do
		local index = getIndex(folder)
		if not index or not BankDefinition.VAULTS[index] then
			continue
		end
		local vault = getVault(index)
		for _, child in folder:GetChildren() do
			if not child:IsA("Model") or not child:HasTag(MapDefinition.VaultDoor.Name) then
				continue
			end
			local slideRes = MapDefinition.get(child, MapDefinition.Slide)
			if slideRes.IsErr then
				warn(slideRes.Value)
				continue
			end
			local half: Half = {
				Model = child,
				ClosedPivot = child:GetPivot(),
				Slide = slideRes.Value,
			}
			table.insert(vault.Halves, half)
			MapDefinition.set(child, MapDefinition.ClosedPivot, half.ClosedPivot)
			MapDefinition.set(child, MapDefinition.SlideDuration, BankDefinition.VAULT_DOOR.Duration)
			MapDefinition.set(child, MapDefinition.IsOpen, false)
			MapDefinition.set(child, MapDefinition.ChangedAt, 0)
		end
		local button = folder:FindFirstChild(BUTTON_NAME)
		local trigger = button and button:FindFirstChild(TRIGGER_NAME)
		if not trigger or not trigger:IsA("BasePart") then
			warn(`{folder:GetFullName()} has no button, it stays shut`)
			continue
		end
		vault.Trigger = trigger
		vault.Material = trigger.Material
		-- only the side that robs it opens a vault, + only one of an open bank
		table.insert(
			connections,
			trigger.Touched:Connect(function(hit: BasePart)
				local visitor = getVisitor(trigger, hit)
				if not visitor or visitor.TeamId ~= BankDefinition.ROBBER_TEAM_ID then
					return
				end
				file(visitor)
				local isOpened: boolean
				state, isOpened = RobberyUtil.press(state, index)
				if isOpened then
					setVault(vault, true)
				end
			end)
		)
	end

	local pads = model:FindFirstChild(PADS_NAME)
	local padFolders: { Instance } = if pads then pads:GetChildren() else {}
	for _, folder in padFolders do
		local index = getIndex(folder)
		if not index or not BankDefinition.VAULTS[index] then
			continue
		end
		local pad = folder:FindFirstChild(PAD_NAME)
		if not pad or not pad:IsA("BasePart") then
			warn(`{folder:GetFullName()} has no pad, nothing is handed out of it`)
			continue
		end
		local vault = getVault(index)
		table.insert(
			connections,
			pad.Touched:Connect(function(hit: BasePart)
				local visitor = getVisitor(pad, hit)
				if not visitor or visitor.TeamId ~= BankDefinition.ROBBER_TEAM_ID then
					return
				end
				file(visitor)
				if not table.find(vault.Standing, visitor.Player) then
					table.insert(vault.Standing, visitor.Player)
				end
			end)
		)
	end
	for index in BankDefinition.VAULTS do
		if not vaults[index] then
			warn(`{model:GetFullName()} has no vault {index}`)
		end
	end
	setDoor(state.IsOpen)

	local checkThread = task.spawn(function()
		task.wait(BankDefinition.START_DELAY)
		while true do
			task.wait(BankDefinition.CHECK_INTERVAL)
			check()
		end
	end)
	local payThread = task.spawn(function()
		while true do
			task.wait(BankDefinition.PAY_INTERVAL)
			pay()
		end
	end)
	-- a server that stops its fights while the bank is robbed has the robbery count for nothing: the bank is as it
	-- was before anybody came in + nobody is put outside. told at once, of what it started by
	local stopMode = ModeDefinition.observe(function(isPVP: boolean)
		if not isPVP then
			state = RobberyUtil.void(state)
			clear()
		end
	end)

	return function()
		stopMode()
		cancel(checkThread)
		cancel(payThread)
		for _, connection in connections do
			connection:Disconnect()
		end
		for player in table.clone(watches) do
			unwatch(player)
		end
		for _, vault in vaults do
			cancel(vault.RestThread)
		end
	end
end
-- Class
-- the bank of the map: it stands open, the side that robs it walks in, pushes the button of a vault + stands on the
-- pad behind its door for what the vault holds, through a hall of beams that sweep it. the first robber in has
-- the town told. once it's over the bank shuts, everybody who came in is put outside + it opens again in the
-- morning of the city. the old place paid out of a shut bank + more than a vault held, + its buttons compared a
-- color with a team: here a pad hands out what's there while its door is open, + a button opens its door
return {
	new = function(): Runner
		local sweeper = BeamSweeper.new()
		-- the server holds the whole map, a bank is run from when it's in the world
		local stopBanks = MapDefinition.observe(MapDefinition.Bank, function(model: Model): (() -> ())?
			return run(model)
		end)

		return table.freeze({
			Destroy = function()
				stopBanks()
				sweeper.Destroy()
			end,
		})
	end,
}
