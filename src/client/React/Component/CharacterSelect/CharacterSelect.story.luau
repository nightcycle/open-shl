--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
type Character = ParentComponent.Character
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newCharacter(slot: number): Character
	local rng = Random.new(slot)
	return FreezeUtil.delta(RandomCharacter.Character(RandomUtil.newSeed(rng)), function(t: Character): Character
		-- every other hero goes without a name, the menu has a placeholder for those
		if slot % 2 == 1 then
			t.Identities.Main.Profile.Name = `Hero {slot}`
		end
		local powerDefinitions = PowerDefinition.list()
		for i = 1, PowerDefinition.DEFAULT_LIMIT do
			table.insert(t.Powers, {
				Id = powerDefinitions[rng:NextInteger(1, #powerDefinitions)].Id,
			})
		end
		return t
	end)
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		SlotCount = UILabs.Slider(10, 0, 20, 1),
		IsSelectFailing = UILabs.Boolean(false),
	},
}, function(props)
	local slotCount: number = props.controls.SlotCount
	local characters = React.useMemo(function(): { Character }
		local out: { Character } = {}
		for slot = 1, slotCount do
			table.insert(out, newCharacter(slot))
		end
		table.freeze(out)
		return out
	end, { slotCount })
	local activeCharacterId, setActiveCharacterId = React.useState("")
	local isOpen, setIsOpen = React.useState(true)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)

	return e(SessionCharactersContext.Provider, {
		value = characters,
	}, {
		ActiveCharacterId = e(SessionActiveCharacterIdContext.Provider, {
			value = activeCharacterId,
		}, {
			Menu = isOpen and e(
				ParentComponent,
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					ErrorMessage = errorMessage,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Select" then
							if props.controls.IsSelectFailing then
								setErrorMessage(`no slot holds the character`)
							else
								setErrorMessage(nil)
								setActiveCharacterId(action.CharacterId)
								setIsOpen(false)
							end
						elseif action.Type == "Edit" then
							-- there's no editor in here, the menu says so the way it does when the shell has none
							setErrorMessage(`no "CharacterEditor" screen`)
						elseif action.Type == "Exit" then
							setErrorMessage(nil)
							setIsOpen(false)
						end
					end,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
				} :: ParentComponent.Properties
			),
			-- stands in for the hud button, the menu opens on whoever was selected last
			Characters = not isOpen and e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 140, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.2, 0.1),
				Text = "Characters",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					setIsOpen(true)
				end,
			}),
		}),
	})
end)
