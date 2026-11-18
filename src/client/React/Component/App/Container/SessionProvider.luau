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
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
-- Types
type Character = SessionService.Character
type IdentityKey = SessionService.IdentityKey
type BaseInventory = SessionService.BaseInventory
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
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

	local credits = usePlayerAttribute(AttributeDefinition.Credits)
	local gems = usePlayerAttribute(AttributeDefinition.Gems)
	local powerLimit = usePlayerAttribute(AttributeDefinition.PowerLimit)
	local hasFifthPower = usePlayerAttribute(AttributeDefinition.HasFifthPower)
	local hasExtraCharacterSlots = usePlayerAttribute(AttributeDefinition.HasExtraCharacterSlots)
	local hasMultiHair = usePlayerAttribute(AttributeDefinition.HasMultiHair)
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
		table.freeze(out)
		return out
	end, { hasFifthPower, hasExtraCharacterSlots, hasMultiHair })

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
								}, props.children),
							}),
						}),
					}),
				}),
			}),
		}),
	})
end
