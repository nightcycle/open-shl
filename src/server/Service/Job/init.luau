--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local JobDefinition = require("@game/ServerScriptService/Server/Definition/Job")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local ShiftUtil = require("@self/Shift")
local TouchUtil = require("@game/ServerScriptService/Server/Util/Touch")
-- Types
local JobType = require("@game/ServerScriptService/Server/Type/Job")
local SharedJobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type JobId = SharedJobType.JobId
type Shift = JobType.Shift
-- a part of the map that takes whoever steps on it on for one job
type Pad = {
	Part: BasePart,
	JobId: JobId,
	-- whoever it took on + hasn't seen far enough from it since: it doesn't take them on again
	Lingering: { [Player]: true },
}
-- somebody at their job
type Work = {
	Pad: Pad,
	-- the avatar that was taken on, the one its player comes back as wasn't
	Character: Model,
	Shift: Shift,
	Connections: { RBXScriptConnection },
}
type JobServiceImpl = {
	__index: JobServiceImpl,
}
export type JobService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Pads: { Pad },
		-- nothing of a shift is kept between two visits
		_Works: { [Player]: Work },
		_Random: Random,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: JobServiceImpl
))
-- Constants
local RULE = JobDefinition.RULE
-- what a job pays in
local CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
-- Variables
-- References
-- Private Functions
-- whether the server has an avatar by the pad it was taken on at
local function getIfAround(character: Model, pad: Pad): boolean
	local rootPart = character.PrimaryPart
	return rootPart ~= nil and (rootPart.Position - pad.Part.Position).Magnitude <= RULE.Radius
end

-- whoever was seen far enough from the pad may be taken on by it again, + so may whoever comes back another visit
local function audit(pad: Pad)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	for player in table.clone(pad.Lingering) do
		local character = player.Character
		if SessionService:Get(player).IsNone or not character or not getIfAround(character, pad) then
			pad.Lingering[player] = nil
		end
	end
end

-- the shift is over, however it came to be. what was earned was counted here answer by answer, so it's handed over
-- at every end the server sees: the old place kept the cheque of whoever went down or left
local function finish(self: JobService, player: Player, isTold: boolean)
	local work = self._Works[player]
	if not work then
		return
	end
	self._Works[player] = nil
	for _, connection in work.Connections do
		connection:Disconnect()
	end
	local paycheck = work.Shift.Paycheck
	if paycheck > 0 and EconomyService.IsInitialized then
		local grantRes = EconomyService:Grant(player, CURRENCY, paycheck)
		if grantRes.IsErr then
			warn(`paycheck err: {grantRes.Value}`)
		end
	end
	if isTold and NetworkService.IsInitialized then
		NetworkService:Fire(RemoteDefinition.JobChanged, player, nil)
	end
end

local function onTouched(self: JobService, pad: Pad, hit: BasePart)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local player, character = TouchUtil.getToucher(hit)
	if not player or not character or SessionService:Get(player).IsNone then
		return
	end
	if
		AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
		or not TouchUtil.getIfNear(character, pad.Part, TouchUtil.REACH)
	then
		return
	end
	audit(pad)
	if pad.Lingering[player] or self._Works[player] then
		return
	end
	-- somebody who's held has nowhere to go to work from
	if AttributeDefinition.get(character, AttributeDefinition.IsJailed) then
		return
	end
	-- the screen of a job is a menu, + a menu is where whoever is in a fight would walk out of it: the pad of the old
	-- place handed anybody a forcefield mid-fight
	if FightingUtil.getMenuRefusal(character, true, CombatDefinition.getTime()) then
		return
	end
	local work: Work = {
		Pad = pad,
		Character = character,
		Shift = ShiftUtil.new(RULE, pad.JobId, JobDefinition.getCards(pad.JobId), self._Random),
		Connections = {},
	}
	local function leave()
		if self.IsInitialized and self._Works[player] == work then
			finish(self, player, true)
		end
	end
	table.insert(
		work.Connections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
			if AttributeDefinition.get(character, AttributeDefinition.IsDead) then
				leave()
			end
		end)
	)
	-- an avatar that's gone left its job as far as the pad can tell: its player dressed anew or reset
	table.insert(
		work.Connections,
		character.AncestryChanged:Connect(function()
			if not character:IsDescendantOf(Workspace) then
				leave()
			end
		end)
	)
	pad.Lingering[player] = true
	self._Works[player] = work
	-- the first card is answered whenever
	NetworkService:Fire(RemoteDefinition.JobChanged, player, ShiftUtil.getShown(work.Shift, CombatDefinition.getTime()))
end

local function onAnswered(self: JobService, player: Player, isYes: boolean)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local work = self._Works[player]
	if not work or work.Shift.EndText ~= nil then
		return
	end
	-- the screen holds the root of whoever is at a job where it stood, so only a client that moved it gets here
	if not getIfAround(work.Character, work.Pad) then
		finish(self, player, true)
		return
	end
	-- an answer that's early is dropped: the pace was the client's to keep in the old place, it's the ceiling of what
	-- a job pays
	local now = os.clock()
	if not ShiftUtil.getIfReady(RULE, work.Shift, now) then
		return
	end
	work.Shift = ShiftUtil.answer(RULE, work.Shift, isYes, JobDefinition.getCards(work.Pad.JobId), self._Random, now)
	-- the client reads its own wait off this, which is never over before the server's
	NetworkService:Fire(
		RemoteDefinition.JobChanged,
		player,
		ShiftUtil.getShown(work.Shift, CombatDefinition.getTime() + RULE.ReadDuration)
	)
end
-- Class
local JobService = {} :: JobServiceImpl
JobService.__index = JobService

-- the jobs of the map: whoever steps on a pad is asked one card after the other + paid for every answer once they
-- leave. the server deals the cards, keeps the four a shift is judged by, the pace + the cheque: its old place had
-- the client do all of it + say what it was owed. a client only ever says yes, no or that it's leaving, + is told
-- what to draw. both sides work, in whatever mode: only whoever is held or in a fight is turned down
return ServiceLocker(function(): JobService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Pads = {},
		_Works = {},
		-- no two servers deal the same shift
		_Random = Random.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, JobService)

	-- the server holds the whole map, whatever streaming does to a client
	for _, part in MapDefinition.list(MapDefinition.JobPad) do
		local idRes = MapDefinition.get(part, MapDefinition.JobId)
		-- a pad that's spelt wrong mustn't pass for one that was taken out on purpose
		if idRes.IsErr then
			error(idRes.Value)
		end
		local jobId = idRes.Value
		assert(SharedJobType.JobId(jobId), `{part:GetFullName()} takes on for "{jobId}", which isn't a job of the game`)
		local pad: Pad = {
			Part = part,
			JobId = jobId :: JobId,
			Lingering = {},
		}
		table.insert(self._Pads, pad)
		table.insert(
			self._Connections,
			part.Touched:Connect(function(hit: BasePart)
				onTouched(self, pad, hit)
			end)
		)
	end

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.AnswerJob, function(player: Player, isYes: boolean)
			onAnswered(self, player, isYes)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.RetireJob, function(player: Player)
			finish(self, player, true)
		end)
	)
	-- the session is still held as this is heard, so the cheque of whoever leaves mid-shift is in their last save
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		finish(self, player, false)
		for _, pad in self._Pads do
			pad.Lingering[player] = nil
		end
	end)
	-- a pad that nobody steps on still lets go of whoever walked off
	local auditThread = task.spawn(function()
		while true do
			task.wait(RULE.AuditInterval)
			for _, pad in self._Pads do
				audit(pad)
			end
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		removingConnection:Disconnect()
		task.cancel(auditThread)
		-- a server that stops pays what was earned up to then
		for player in table.clone(self._Works) do
			finish(self, player, true)
		end
	end)

	return self
end, function(self: JobService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
