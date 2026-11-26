--!strict
-- Services
-- Packages
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Session = SessionService.Session
type Character = CharacterType.Character
-- Constants
-- what a column read until its player had walked the pages of the creator: a slot nobody made a hero in yet
local EMPTY_TEXT = "None"
-- the three sides its creator had a hero picked from, in the words of its buttons
local ALIGNMENT_TEXTS: { [PseudoEnum.Alignment]: string } = table.freeze({
	LawfulGood = "HERO",
	NeutralGood = "HERO",
	ChaoticGood = "HERO",
	LawfulNeutral = "OTHER",
	TrueNeutral = "OTHER",
	ChaoticNeutral = "OTHER",
	LawfulEvil = "VILLAIN",
	NeutralEvil = "VILLAIN",
	ChaoticEvil = "VILLAIN",
})
local PEACEFUL_TEXT = "RP"
local FIGHTING_TEXT = "PVP"
-- Variables
-- References
-- Private Functions
-- the character that's played, once somebody was made in its slot: a hero without a name is one nobody made yet
local function getPlayed(session: Session): Character?
	local save = session.Save
	for _, character in save.Characters do
		if character.Id == save.ActiveCharacterId then
			return if character.Identities.Main.Profile.Name ~= "" then character else nil
		end
	end
	return nil
end
-- Class
-- the three columns of the old place, in its order: which side the hero of a player is on, the hero's name (also
-- while the civilian is out) + if the player fights. the first two are of whoever is played right now
return table.freeze({
	table.freeze({
		Name = "Alignment",
		ClassName = "StringValue" :: "StringValue",
		Get = function(session: Session): string
			local character = getPlayed(session)
			return if character then ALIGNMENT_TEXTS[character.Identities.Main.Profile.Alignment] else EMPTY_TEXT
		end,
	}),
	table.freeze({
		Name = "Alias",
		ClassName = "StringValue" :: "StringValue",
		Get = function(session: Session): string
			local character = getPlayed(session)
			return if character then character.Identities.Main.Profile.Name else EMPTY_TEXT
		end,
	}),
	-- the pick is kept with the save, so it's told from the moment its player is in: the old place started every
	-- visit out at "None"
	table.freeze({
		Name = "Mode",
		ClassName = "StringValue" :: "StringValue",
		Get = function(session: Session): string
			local section = session.Save.SHL1
			assert(section, `a save of this game has its section`)
			return if section.IsPeaceful then PEACEFUL_TEXT else FIGHTING_TEXT
		end,
	}),
})
