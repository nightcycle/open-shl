--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Types
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionSectionType = require("@game/ServerScriptService/Server/Type/SessionSection")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type PlayerSave = SaveType.PlayerSave
type SavePatch = LegacyImportType.SavePatch
type SessionSection = SessionSectionType.SessionSection
type Sessions = SessionSectionType.Sessions
type Snapshot = SessionType.Snapshot
-- Constants
-- Variables
-- References
-- Private Functions
-- whatever the patch holds takes the place of what a new save starts out with. the importer of this game is at its
-- first version, so a save that's due it was never played: a first visit that can't ask the old stores ends in a kick
local function import(save: PlayerSave, patch: SavePatch)
	save.Characters = patch.Characters or save.Characters
	save.ActiveCharacterId = patch.ActiveCharacterId or save.ActiveCharacterId
	save.Balances = patch.Balances or save.Balances
	save.Inventory = patch.Inventory or save.Inventory
	save.BaseLayout = patch.BaseLayout or save.BaseLayout
	save.LastDailyRewardAt = patch.LastDailyRewardAt or save.LastDailyRewardAt
	if patch.IsTutorialEnabled ~= nil then
		save.IsTutorialEnabled = patch.IsTutorialEnabled
	end
end

-- the furniture + themes the player owns, the build menu sells + places by them
local function snapshot(out: Snapshot, save: PlayerSave)
	out.Inventory = save.Inventory
end

-- a save of this game holds both, they're only short in the save of another one
local function setAttributes(player: Player, save: PlayerSave)
	assert(save.IsTutorialEnabled ~= nil and save.IsApartmentLocked ~= nil, `a save of this game has its settings`)
	AttributeDefinition.set(player, AttributeDefinition.IsTutorialEnabled, save.IsTutorialEnabled)
	AttributeDefinition.set(player, AttributeDefinition.IsApartmentLocked, save.IsApartmentLocked)
end

-- the inventory a client was handed with its snapshot follows the save from here, whoever changed it
local function replicate(player: Player, save: PlayerSave, priorSave: PlayerSave)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local inventory = save.Inventory
	assert(inventory, `a save of this game has its inventory`)
	if not StateUtil.getIfEqual(inventory, priorSave.Inventory) then
		NetworkService:Fire(RemoteDefinition.InventoryChanged, player, inventory)
	end
end

-- the captain is this game's, + so is the word of a client that it's had enough of him
local function start(sessions: Sessions): (() -> ())?
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local tutorialConnection = NetworkService:Connect(
		RemoteDefinition.SetTutorialEnabled,
		function(player: Player, isEnabled: boolean)
			local saveRes = sessions.Update(player, function(save: PlayerSave): PlayerSave?
				if save.IsTutorialEnabled == isEnabled then
					return nil
				end
				save.IsTutorialEnabled = isEnabled
				return save
			end)
			if saveRes.IsErr then
				warn(`tutorial err: {saveRes.Value}`)
			end
		end
	)
	return function()
		tutorialConnection:Disconnect()
	end
end
-- Class
-- superhero life 2 keeps nothing in a section: what's its own was in the save before a game had one + stays there
local Section: SessionSection = table.freeze({
	Patch = LegacyImportType.SHL2SavePatch,
	Import = import,
	Snapshot = snapshot,
	SetAttributes = setAttributes,
	Replicate = replicate,
	Start = start,
})

return Section
