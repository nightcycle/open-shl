--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type IdentityKey = CharacterType.IdentityKey
local Types = {}

-- who said a line, as their player tells it: an avatar that's out of range isn't on a client, its player is
export type Speaker = {
	-- of the account
	Name: string,
	-- who their avatar was last dressed as, "" for somebody who has no avatar yet
	Alias: string,
	IdentityKey: IdentityKey,
	IsPeaceful: boolean,
	-- nil for somebody on no side
	SideColor: Color3?,
}
Types.Speaker = Type.strictInterface({
	Name = Type.string,
	Alias = Type.string,
	IdentityKey = CharacterType.IdentityKey,
	IsPeaceful = Type.boolean,
	SideColor = Type.optional(Type.Color3),
})

-- who reads it
export type Viewer = {
	IsPeaceful: boolean,
	IsMuting: boolean,
}
Types.Viewer = Type.strictInterface({
	IsPeaceful = Type.boolean,
	IsMuting = Type.boolean,
})

-- how a game has its lines read
export type Rule = {
	-- how the name of a speaker is written ahead of what they said, around one %s
	PrefixFormat: string,
	-- whoever mutes reads nothing of a speaker who made the other pick about fights
	IsMutedByMode: boolean,
	-- a hero is named in the color of their side + a civilian in this one. without it a name is left the way the
	-- engine writes one
	CivilianColor: Color3?,
}
Types.Rule = Type.strictInterface({
	PrefixFormat = Type.string,
	IsMutedByMode = Type.boolean,
	CivilianColor = Type.optional(Type.Color3),
})

-- what a viewer reads of a line. a prefix of "" is a line without a name
export type Line = {
	Prefix: string,
	Text: string,
	Color: Color3?,
}
-- Constants
-- what the old game put in the place of a whole line, the name with it
local MUTED_TEXT = "[MUTED]"
local HERO_KEY: IdentityKey = "Main"
-- a name is written into rich text, where these would be read as the start of a tag or an escape
local ESCAPES: { [string]: string } = table.freeze({
	["&"] = "&amp;",
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
})
-- the engine takes a prefix of "" for none given + writes the name of the account: this is what reads as nothing
local BLANK_PREFIX_TEXT = " "
-- Variables
-- References
-- Private Functions
local function escape(text: string): string
	return (text:gsub("[&<>\"']", ESCAPES))
end
-- Class
local Module = {}

Module.Speaker = Types.Speaker
Module.Viewer = Types.Viewer
Module.Rule = Types.Rule
Module.MUTED_TEXT = MUTED_TEXT

-- what the viewer reads of something the speaker said. a line nobody said (the engine's own) passes as it is, + a
-- speaker goes by the name of whoever they play: the account's is only for somebody who's nobody yet
Module.get = function(speaker: Speaker?, text: string, viewer: Viewer, rule: Rule): Line
	if not speaker then
		return table.freeze({
			Prefix = "",
			Text = text,
		})
	end
	if rule.IsMutedByMode and viewer.IsMuting and speaker.IsPeaceful ~= viewer.IsPeaceful then
		return table.freeze({
			Prefix = "",
			Text = MUTED_TEXT,
		})
	end
	local color: Color3? = nil
	if rule.CivilianColor then
		color = if speaker.IdentityKey == HERO_KEY then speaker.SideColor else rule.CivilianColor
	end
	return table.freeze({
		Prefix = if speaker.Alias ~= "" then speaker.Alias else speaker.Name,
		Text = text,
		Color = color,
	})
end

-- the name as the window of the engine takes it: rich text ahead of what was said
Module.getPrefixText = function(line: Line, rule: Rule): string
	if line.Prefix == "" then
		return BLANK_PREFIX_TEXT
	end
	local text = rule.PrefixFormat:format(escape(line.Prefix))
	local color = line.Color
	return if color then `<font color="#{color:ToHex()}">{text}</font>` else text
end

-- the whole of it on one line of a log, the way the old game wrote one. what was said is the engine's + comes as rich
-- text already, so only the name is made safe for it
Module.getLogText = function(line: Line): string
	return if line.Prefix == "" then line.Text else `{escape(line.Prefix)}: {line.Text}`
end

return Module
