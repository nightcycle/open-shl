--!strict
-- Services
-- Packages
-- Modules
local BankDefinition = require("@game/ServerScriptService/Server/Definition/Bank")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TeamId = CombatType.TeamId
-- what a bank has come to
export type State = {
	IsOpen: boolean,
	-- the town was told of the robbery that's under way
	IsAlarmed: boolean,
	-- seconds of looks that found a robber on the list
	Elapsed: number,
	-- everybody who came in since it opened, by their side as they did, + whether they went down since
	Robbers: { [Player]: boolean },
	Guards: { [Player]: boolean },
	-- the credits each vault still holds + whether its door is open, by the number of the vault
	Stored: { number },
	IsVaultOpen: { boolean },
}
-- who is put outside as it shuts: everybody on a list who's still up
export type Filed = {
	Robbers: { Player },
	Guards: { Player },
}
-- the credits a round of a pad hands each of those it pays
export type Payments = { [Player]: number }
-- Constants
local VAULTS = BankDefinition.VAULTS
-- Variables
-- References
-- Private Functions
local function getVaults(): ({ number }, { boolean })
	return table.freeze(table.clone(VAULTS)), table.freeze(table.create(#VAULTS, false))
end

-- nobody is on a list, the vaults are full + shut + the town may be told
local function reset(isOpen: boolean): State
	local stored, isVaultOpen = getVaults()
	return table.freeze({
		IsOpen = isOpen,
		IsAlarmed = false,
		Elapsed = 0,
		Robbers = table.freeze({}),
		Guards = table.freeze({}),
		Stored = stored,
		IsVaultOpen = isVaultOpen,
	})
end

-- as the server starts, + as a shut one opens: full + with nobody in it
local function new(): State
	return reset(true)
end

-- somebody of a side came into an open bank: they're on the list of that side from then on, once. true as the
-- first robber of a robbery is, which is when the town hears of it
local function enter(state: State, player: Player, teamId: TeamId): (State, boolean)
	if not state.IsOpen then
		return state, false
	end
	local isRobber = teamId == BankDefinition.ROBBER_TEAM_ID
	local list = if isRobber then state.Robbers else state.Guards
	if list[player] ~= nil then
		return state, false
	end
	local filed = table.clone(list)
	filed[player] = false
	table.freeze(filed)
	local isFirst = isRobber and not state.IsAlarmed
	local nextState = table.clone(state)
	if isRobber then
		nextState.Robbers = filed
		nextState.IsAlarmed = true
	else
		nextState.Guards = filed
	end
	return table.freeze(nextState), isFirst
end

-- they went down or are gone: whoever was on a list stays on it, + is never on it again as somebody who's up
local function down(state: State, player: Player): State
	if state.Robbers[player] ~= false and state.Guards[player] ~= false then
		return state
	end
	local nextState = table.clone(state)
	if state.Robbers[player] == false then
		local robbers = table.clone(state.Robbers)
		robbers[player] = true
		nextState.Robbers = table.freeze(robbers)
	end
	if state.Guards[player] == false then
		local guards = table.clone(state.Guards)
		guards[player] = true
		nextState.Guards = table.freeze(guards)
	end
	return table.freeze(nextState)
end

-- the button of a vault was pushed. true if that opened it: one of a shut bank or one that's open already isn't
local function press(state: State, vaultIndex: number): (State, boolean)
	if not state.IsOpen or state.IsVaultOpen[vaultIndex] ~= false then
		return state, false
	end
	local isVaultOpen = table.clone(state.IsVaultOpen)
	isVaultOpen[vaultIndex] = true
	local nextState = table.clone(state)
	nextState.IsVaultOpen = table.freeze(isVaultOpen)
	return table.freeze(nextState), true
end

-- a round of the pad of a vault: everybody who stands on it is handed the same, in the order they stepped on +
-- for as long as the vault has it. nothing comes out of a vault that's shut or of a bank that is
local function pay(state: State, vaultIndex: number, standing: { Player }): (State, Payments)
	local payments: Payments = {}
	local stored = state.Stored[vaultIndex]
	if not state.IsOpen or state.IsVaultOpen[vaultIndex] ~= true or stored == nil then
		return state, table.freeze(payments)
	end
	local left = stored
	for _, player in standing do
		if left <= 0 then
			break
		end
		if payments[player] == nil then
			local amount = math.min(BankDefinition.PAY_AMOUNT, left)
			payments[player] = amount
			left -= amount
		end
	end
	if left == stored then
		return state, table.freeze(payments)
	end
	local nextStored = table.clone(state.Stored)
	nextStored[vaultIndex] = left
	local nextState = table.clone(state)
	nextState.Stored = table.freeze(nextStored)
	return table.freeze(nextState), table.freeze(payments)
end

-- what somebody couldn't be handed goes back into its vault, which never holds more than it opened with
local function refund(state: State, vaultIndex: number, amount: number): State
	local stored = state.Stored[vaultIndex]
	if not state.IsOpen or stored == nil then
		return state
	end
	local nextStored = table.clone(state.Stored)
	nextStored[vaultIndex] = math.min(VAULTS[vaultIndex], stored + amount)
	local nextState = table.clone(state)
	nextState.Stored = table.freeze(nextStored)
	return table.freeze(nextState)
end

-- a look at an open bank, dt seconds after the one before. true if it shuts: its vaults are empty, every robber
-- on the list went down, or the looks that found one there add up to more than a robbery may take. the clock
-- only runs while a robber is on the list, so a bank nobody robs stays open for good
local function step(state: State, dt: number): (State, boolean)
	if not state.IsOpen then
		return state, false
	end
	local total = 0
	for _, stored in state.Stored do
		total += stored
	end
	if total <= 0 then
		return state, true
	end
	local count, downCount = 0, 0
	for _, isDown in state.Robbers do
		count += 1
		if isDown then
			downCount += 1
		end
	end
	if count == 0 then
		return state, false
	end
	local nextState = table.clone(state)
	nextState.Elapsed += dt
	table.freeze(nextState)
	return nextState, downCount == count or nextState.Elapsed > BankDefinition.MAX_DURATION
end

-- it shuts. everybody who came in + is still up is put outside, wherever they are by now
local function close(state: State): (State, Filed)
	local robbers: { Player }, guards: { Player } = {}, {}
	for player, isDown in state.Robbers do
		if not isDown then
			table.insert(robbers, player)
		end
	end
	for player, isDown in state.Guards do
		if not isDown then
			table.insert(guards, player)
		end
	end
	return reset(false), table.freeze({ Robbers = table.freeze(robbers), Guards = table.freeze(guards) })
end

-- a robbery that's under way counts for nothing: the bank is as it was before anybody came in, open if it was
local function void(state: State): State
	return reset(state.IsOpen)
end

-- whether a shut bank opens at that hour of the day
local function getIfReopening(hour: number): boolean
	local reopenHour = BankDefinition.REOPEN_HOUR
	return hour >= reopenHour.Min and hour < reopenHour.Max
end
-- Class
-- what a robbery comes to, step by step: who's in on it, what the vaults still hold + when it's over. nothing in
-- here waits, touches the map or knows a clock, every answer is a new state. every function is in from the start,
-- one that's assigned afterwards the checker only knows for the widest type it has
local Util = {
	new = new,
	enter = enter,
	down = down,
	press = press,
	pay = pay,
	refund = refund,
	step = step,
	close = close,
	void = void,
	getIfReopening = getIfReopening,
}

return Util
