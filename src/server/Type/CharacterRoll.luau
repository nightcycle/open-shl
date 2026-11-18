--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
type PowerGroup = PowerType.PowerGroup

local Types = {}

-- a color the way a data file spells it: red, green + blue out of 255
export type Channels = { number }
do -- Types.Channels
	local isChannel = Type.intersection(Type.integer, Type.numberConstrained(0, 255))
	Types.Channels = Type.strictArray(isChannel, isChannel, isChannel)
end

export type NamedColor = {
	Name: string,
	Color: Channels,
}
Types.NamedColor = Type.strictInterface({
	Name = Type.string,
	Color = Types.Channels,
})

export type WeightedColor = {
	Name: string,
	Color: Channels,
	Weight: number, -- how many draws out of all the weights of its list land on it
}
Types.WeightedColor = Type.strictInterface({
	Name = Type.string,
	Color = Types.Channels,
	Weight = Type.intersection(Type.integer, Type.numberPositive),
})

-- a color a costume is built around, along with the one it's set off against
export type PrimaryColor = {
	Name: string,
	Color: Channels,
	Opposite: string, -- the name of another of them
}
Types.PrimaryColor = Type.strictInterface({
	Name = Type.string,
	Color = Types.Channels,
	Opposite = Type.string,
})

-- how often each of the things a roll may go without comes up, 0 is never + 1 is always
export type Chances = {
	OppositeSecondary: number,
	FacialHair: number,
	Emblem: number,
	HeadPiece: number,
	Cape: number,
	Glasses: number,
	Hat: number,
	HyphenatedLastName: number,
	Title: number,
	Suffix: number,
	ColorAlias: number,
}
do -- Types.Chances
	local isChance = Type.numberConstrained(0, 1)
	Types.Chances = Type.strictInterface({
		OppositeSecondary = isChance,
		FacialHair = isChance,
		Emblem = isChance,
		HeadPiece = isChance,
		Cape = isChance,
		Glasses = isChance,
		Hat = isChance,
		HyphenatedLastName = isChance,
		Title = isChance,
		Suffix = isChance,
		ColorAlias = isChance,
	})
end

-- an item that makes no sense without a power: whoever is dealt the one carries the other
export type ForcedPower = {
	ItemId: string,
	PowerId: string,
}
Types.ForcedPower = Type.strictInterface({
	ItemId = Type.string,
	PowerId = Type.string,
})

-- the groups a character is dealt out of together + how many of them it gets
export type PowerKind = {
	Name: string,
	Groups: { PowerGroup },
	Count: number,
}
Types.PowerKind = Type.strictInterface({
	Name = Type.string,
	Groups = Type.array(PowerType.PowerGroup),
	Count = Type.intersection(Type.integer, Type.numberMin(0)),
})

-- everything a character is rolled from that isn't the catalogue of its game. a power id the game has no row for yet
-- is passed over, so the lists can name what's still to be built
export type Tables = {
	Primaries: { PrimaryColor },
	HairColors: { WeightedColor },
	SkinColors: { WeightedColor },
	EyeColors: { WeightedColor },
	PantsColors: { NamedColor },
	DetailColors: { NamedColor },
	ShirtColors: { NamedColor },
	Chances: Chances,
	NeverRolled: { string }, -- item ids
	ForcedPowers: { ForcedPower },
	PowerKinds: { PowerKind },
	StarterPowerIds: { string }, -- what a new player may be dealt
	FirstNames: { string },
	LastNames: { string },
	Titles: { string },
	Suffixes: { string },
	AliasAdjectives: { string },
	AliasNouns: { string },
	Origins: { string },
	Motivations: { string },
}
do -- Types.Tables
	local function isFilled(value: { unknown }): (boolean, string?)
		if #value == 0 then
			return false, `a list nothing can be drawn from`
		end
		return true
	end
	local function newFilled(validator: (value: unknown) -> (boolean, string?)): (value: unknown) -> (boolean, string?)
		return Type.intersection(Type.array(validator), isFilled)
	end
	local isShape = Type.strictInterface({
		Primaries = newFilled(Types.PrimaryColor),
		HairColors = newFilled(Types.WeightedColor),
		SkinColors = newFilled(Types.WeightedColor),
		EyeColors = newFilled(Types.WeightedColor),
		PantsColors = newFilled(Types.NamedColor),
		DetailColors = newFilled(Types.NamedColor),
		ShirtColors = newFilled(Types.NamedColor),
		Chances = Types.Chances,
		NeverRolled = Type.array(Type.string),
		ForcedPowers = Type.array(Types.ForcedPower),
		PowerKinds = Type.array(Types.PowerKind),
		StarterPowerIds = Type.array(Type.string),
		FirstNames = newFilled(Type.string),
		LastNames = newFilled(Type.string),
		Titles = newFilled(Type.string),
		Suffixes = newFilled(Type.string),
		AliasAdjectives = newFilled(Type.string),
		AliasNouns = newFilled(Type.string),
		Origins = newFilled(Type.string),
		Motivations = newFilled(Type.string),
	})
	-- a primary is set off against another of the list, one that names a color there isn't has nothing to be set off against
	local function isLinked(value: Tables): (boolean, string?)
		for _, primary in value.Primaries do
			local isFound = false
			for _, other in value.Primaries do
				isFound = isFound or other.Name == primary.Opposite
			end
			if not isFound then
				return false, `no primary "{primary.Opposite}" for "{primary.Name}" to be set off against`
			end
		end
		return true
	end
	Types.Tables = Type.intersection(isShape, isLinked)
end

-- what a roll reads of an entry of the catalogue: something a player owns as one, made of one item or, for a suit,
-- of one per limb
export type Entry = {
	ItemIds: { string },
	IsOwned: boolean,
}
Types.Entry = Type.strictInterface({
	ItemIds = Type.array(Type.string),
	IsOwned = Type.boolean,
})

-- everything a roll draws from
export type Source = {
	Tables: Tables,
	Entries: { Entry },
}
Types.Source = Type.strictInterface({
	Tables = Types.Tables,
	Entries = Type.array(Types.Entry),
})

return Types
