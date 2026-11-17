--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Components
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local CharacterEnergyContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Energy")
local CharacterHealthContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Health")
local CharacterIsEnergyInsufficientContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/IsEnergyInsufficient")
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
type Character = CharacterContext.Character
export type Properties = {
	children: { [string]: React.ReactNode }?,
}
-- Constants
local ENERGY_WARNING_DURATION = 2
-- what the menus are shown for as long as the server hasn't said who the avatar is
local BLANK_CHARACTER = CharacterConstructor.new()
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local characters = React.useContext(SessionCharactersContext)
	local activeCharacterId = React.useContext(SessionActiveCharacterIdContext)
	local character = React.useMemo(function(): Character
		for _, other in characters do
			if other.Id == activeCharacterId then
				return other
			end
		end
		return BLANK_CHARACTER
	end, { characters :: any, activeCharacterId })

	local health = useCharacterAttribute(AttributeDefinition.Health)
	local energy = useCharacterAttribute(AttributeDefinition.Energy)
	local isEnergyInsufficient, setIsEnergyInsufficient = React.useState(false)
	React.useEffect(function()
		assert(NetworkService.IsInitialized, `the network service isn't initialized`)
		local thread: thread?
		local connection = NetworkService:Connect(RemoteDefinition.InsufficientEnergy, function()
			if thread then
				task.cancel(thread)
			end
			setIsEnergyInsufficient(true)
			thread = task.delay(ENERGY_WARNING_DURATION, function()
				thread = nil
				setIsEnergyInsufficient(false)
			end)
		end)
		return function()
			connection:Disconnect()
			if thread then
				task.cancel(thread)
			end
		end
	end, {})

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		Health = e(CharacterHealthContext.Provider, {
			value = health,
		}, {
			Energy = e(CharacterEnergyContext.Provider, {
				value = energy,
			}, {
				IsEnergyInsufficient = e(CharacterIsEnergyInsufficientContext.Provider, {
					value = isEnergyInsufficient,
				}, props.children),
			}),
		}),
	})
end
