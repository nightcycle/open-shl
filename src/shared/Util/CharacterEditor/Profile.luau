--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
export type EditorState = CharacterEditorType.EditorState
type ProfileKey = CharacterEditorType.ProfileKey
type AlignmentAxis = CharacterEditorType.AlignmentAxis
type Morality = CharacterEditorType.Morality
type Order = CharacterEditorType.Order
type Identity = IdentityType.Identity
-- Constants
local LINE_BREAK_PATTERN = "[\r\n]+"
local ALIGNMENTS: { [Order]: { [Morality]: PseudoEnum.Alignment } } = table.freeze({
	Lawful = table.freeze({
		Good = PseudoEnum.Alignment.LawfulGood,
		Neutral = PseudoEnum.Alignment.LawfulNeutral,
		Evil = PseudoEnum.Alignment.LawfulEvil,
	}),
	Neutral = table.freeze({
		Good = PseudoEnum.Alignment.NeutralGood,
		Neutral = PseudoEnum.Alignment.TrueNeutral,
		Evil = PseudoEnum.Alignment.NeutralEvil,
	}),
	Chaotic = table.freeze({
		Good = PseudoEnum.Alignment.ChaoticGood,
		Neutral = PseudoEnum.Alignment.ChaoticNeutral,
		Evil = PseudoEnum.Alignment.ChaoticEvil,
	}),
})
-- Variables
-- References
-- Private Functions
local function getAxes(alignment: PseudoEnum.Alignment): (Order, Morality)
	for order: Order, moralities in ALIGNMENTS do
		for morality: Morality, value in moralities do
			if value == alignment then
				return order, morality
			end
		end
	end
	return "Neutral", "Neutral"
end

-- the profile is a flat record, the appearance next to it stays the very same table
local function setAlignment(identity: Identity, alignment: PseudoEnum.Alignment): Identity
	local profile = table.clone(identity.Profile)
	profile.Alignment = alignment
	table.freeze(profile)
	local out = table.clone(identity)
	out.Profile = profile
	table.freeze(out)
	return out
end

-- Class
local Util = {}

function Util.getText(state: EditorState, key: ProfileKey): string
	local profile = StateUtil.getIdentity(state).Profile
	return if key == "Name" then profile.Name else profile.Backstory
end

function Util.setText(
	state: EditorState,
	key: ProfileKey,
	text: string,
	maxLength: number?,
	isMultiLine: boolean
): Result<EditorState, string>
	-- text that isn't utf8 can't be cut to length or shown by a label, the server turns it down as well
	if not utf8.len(text) then
		return Result.err(`the text can't be read`)
	end
	if not isMultiLine then
		text = string.gsub(text, LINE_BREAK_PATTERN, " ")
	end
	if maxLength then
		local cutOff = utf8.offset(text, maxLength + 1)
		if cutOff then
			text = string.sub(text, 1, cutOff - 1)
		end
	end
	if Util.getText(state, key) == text then
		return Result.ok(state)
	end
	local identity = StateUtil.getIdentity(state)
	local profile = table.clone(identity.Profile)
	if key == "Name" then
		profile.Name = text
	else
		profile.Backstory = text
	end
	table.freeze(profile)
	local editedIdentity = table.clone(identity)
	editedIdentity.Profile = profile
	table.freeze(editedIdentity)
	return Result.ok(StateUtil.setFocusedIdentity(state, editedIdentity))
end

function Util.getAlignment(state: EditorState, axis: AlignmentAxis): string
	local order, morality = getAxes(StateUtil.getIdentity(state).Profile.Alignment)
	return if axis == "Morality" then morality else order
end

function Util.setAlignment(state: EditorState, axis: AlignmentAxis, value: unknown): Result<EditorState, string>
	local order: Order, morality: Morality = getAxes(StateUtil.getIdentity(state).Profile.Alignment)
	if axis == "Morality" then
		if not CharacterEditorType.Morality(value) then
			return Result.err(`"{tostring(value)}" isn't a morality`)
		end
		morality = value :: Morality
	else
		if not CharacterEditorType.Order(value) then
			return Result.err(`"{tostring(value)}" isn't an order`)
		end
		order = value :: Order
	end
	local alignment: PseudoEnum.Alignment = ALIGNMENTS[order][morality]
	return Result.ok(StateUtil.editIdentities(state, function(identity: Identity): Identity
		return if identity.Profile.Alignment == alignment then identity else setAlignment(identity, alignment)
	end))
end

return Util
