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
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
-- Types
type Character = ParentComponent.Character
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
-- Constants
-- what the game the layout was made for hands out: five slots, ten to whoever has the pass
local SLOT_COUNT = 5
local MAX_SLOT_COUNT = 10
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newCharacter(slot: number): Character
	local rng = Random.new(slot)
	return FreezeUtil.delta(RandomCharacter.Character(RandomUtil.newSeed(rng)), function(t: Character): Character
		-- the last hero goes without a name, the list has a placeholder for those
		if slot < MAX_SLOT_COUNT then
			t.Identities.Main.Profile.Name = `Hero {slot}`
		end
		-- every other one is of another height, so the camera has something to frame
		if slot % 2 == 0 then
			t.Identities.Main.Appearance.Scale = {
				Height = 1.4,
				Width = 1.4,
			}
		end
		return t
	end)
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		SlotCount = UILabs.Slider(SLOT_COUNT, 0, MAX_SLOT_COUNT, 1),
		HasExtraSlots = UILabs.Boolean(false),
		IsSelectFailing = UILabs.Boolean(false),
	},
}, function(props)
	local slotCount: number = props.controls.SlotCount
	local hasExtraSlots: boolean = props.controls.HasExtraSlots
	local characters = React.useMemo(function(): { Character }
		local out: { Character } = {}
		for slot = 1, slotCount do
			table.insert(out, newCharacter(slot))
		end
		table.freeze(out)
		return out
	end, { slotCount })
	local entitlements = React.useMemo(function(): { EntitlementKey }
		local out: { EntitlementKey } = {}
		if hasExtraSlots then
			table.insert(out, "ExtraCharacterSlots")
		end
		table.freeze(out)
		return out
	end, { hasExtraSlots })
	local activeCharacterId, setActiveCharacterId = React.useState("")
	local isOpen, setIsOpen = React.useState(true)
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)

	return StyleStory.provide(props.controls.Style, {
		Characters = e(SessionCharactersContext.Provider, {
			value = characters,
		}, {
			ActiveCharacterId = e(SessionActiveCharacterIdContext.Provider, {
				value = activeCharacterId,
			}, {
				Entitlements = e(SessionEntitlementsContext.Provider, {
					value = entitlements,
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
								elseif action.Type == "BuySlots" then
									-- nothing is sold in here either
									setErrorMessage(`the pass can't be bought right now`)
								end
							end,
							SizeConstraint = Enum.SizeConstraint.RelativeXY,
						} :: ParentComponent.Properties
					),
					-- stands in for the hud button, the menu opens on whoever was selected last
					Open = not isOpen and e("TextButton", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(20, 166, 230),
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
			}),
		}),
	})
end)
