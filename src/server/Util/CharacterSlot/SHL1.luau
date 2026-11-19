--!strict
-- Services
-- Packages
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
-- Constants
-- the grey of the mannequin the old creator stood everybody on, medium stone grey. a skin that's off the grid of the
-- game would be another color by the first save
local SKIN_COLOR: Color3 = assert(
	CharacterEditorDefinition.getPaletteColor(BrickColor.new(194).Color),
	`the skin of a new character isn't a color of the game`
)
-- the page of the old creator that asked for a side read HERO until it was touched, whoever walked past it was one
local ALIGNMENT: PseudoEnum.Alignment = PseudoEnum.Alignment.NeutralGood
-- Variables
-- References
-- Private Functions
-- a slot nobody made a character in yet: the bare mannequin with nothing on, no power + no name. it's empty for as
-- long as its hero has no name, the server gives one to every character that's saved
local function new(): Character
	return FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		for _, identity in t.Identities do
			if identity then
				identity.Appearance.SkinColor = SKIN_COLOR
				identity.Profile.Alignment = ALIGNMENT
			end
		end
		return t
	end)
end

-- the old game had nobody start out as anybody: every row it saved to is there from the first visit on, empty
local function list(): { Character }
	local out: { Character } = {}
	for _ = 1, ProductDefinition.getCharacterSlotCount({}) do
		table.insert(out, new())
	end
	return out
end
-- Class
return table.freeze({
	List = list,
	New = new,
})
