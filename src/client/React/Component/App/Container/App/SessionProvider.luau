--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
-- Hooks
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
local SessionInventoryContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Inventory")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
type Character = SessionService.Character
type IdentityKey = SessionService.IdentityKey
type BaseInventory = SessionService.BaseInventory
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
type Owned = SessionService.Owned
export type Properties = {
	children: { [string]: React.ReactNode }?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local characters = useSignalState(SessionService.CharactersChanged, function(): { Character }
		return SessionService:GetCharacters()
	end)
	local activeCharacterId = useSignalState(SessionService.ActiveCharacterChanged, function(): string
		return SessionService:GetActiveCharacterId()
	end)
	local activeIdentityKey = useSignalState(SessionService.ActiveCharacterChanged, function(): IdentityKey
		return SessionService:GetActiveIdentityKey()
	end)
	local inventory = useSignalState(SessionService.InventoryChanged, function(): BaseInventory
		return SessionService:GetInventory()
	end)
	local owned = useSignalState(SessionService.OwnedChanged, function(): Owned
		return SessionService:GetOwned()
	end)

	local credits = usePlayerAttribute(AttributeDefinition.Credits)
	local gems = usePlayerAttribute(AttributeDefinition.Gems)
	local powerLimit = usePlayerAttribute(AttributeDefinition.PowerLimit)
	-- the passes of every game are listened for, the ones a game doesn't sell are never set on its players
	local hasFifthPower = usePlayerAttribute(AttributeDefinition.HasFifthPower)
	local hasExtraCharacterSlots = usePlayerAttribute(AttributeDefinition.HasExtraCharacterSlots)
	local hasMultiHair = usePlayerAttribute(AttributeDefinition.HasMultiHair)
	local hasExtraPowers = usePlayerAttribute(AttributeDefinition.HasExtraPowers)
	local hasAdvancedRoleplay = usePlayerAttribute(AttributeDefinition.HasAdvancedRoleplay)
	local entitlements = React.useMemo(function(): { EntitlementKey }
		local out: { EntitlementKey } = {}
		if hasFifthPower then
			table.insert(out, "FifthPower")
		end
		if hasExtraCharacterSlots then
			table.insert(out, "ExtraCharacterSlots")
		end
		if hasMultiHair then
			table.insert(out, "MultiHair")
		end
		if hasExtraPowers then
			table.insert(out, "ExtraPowers")
		end
		if hasAdvancedRoleplay then
			table.insert(out, "AdvancedRoleplay")
		end
		table.freeze(out)
		return out
	end, { hasFifthPower, hasExtraCharacterSlots, hasMultiHair, hasExtraPowers, hasAdvancedRoleplay })

	return e(SessionCharactersContext.Provider, {
		value = characters,
	}, {
		ActiveCharacterId = e(SessionActiveCharacterIdContext.Provider, {
			value = activeCharacterId,
		}, {
			ActiveIdentityKey = e(SessionActiveIdentityKeyContext.Provider, {
				value = activeIdentityKey,
			}, {
				Inventory = e(SessionInventoryContext.Provider, {
					value = inventory,
				}, {
					Credits = e(SessionCreditsContext.Provider, {
						value = credits,
					}, {
						Gems = e(SessionGemsContext.Provider, {
							value = gems,
						}, {
							PowerLimit = e(SessionPowerLimitContext.Provider, {
								value = powerLimit,
							}, {
								Entitlements = e(SessionEntitlementsContext.Provider, {
									value = entitlements,
								}, {
									Owned = e(SessionOwnedContext.Provider, {
										value = owned,
									}, props.children),
								}),
							}),
						}),
					}),
				}),
			}),
		}),
	})
end
