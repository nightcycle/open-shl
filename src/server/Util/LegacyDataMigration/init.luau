--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
export type TextureGroup = {
	BrickColor: string,
	Material: string?,
}

export type Item = {
	Name: string,
	Primary: TextureGroup?,
	Secondary: TextureGroup?,
	EyeTransparency: number?,
}

export type Power = {
	Name: string,
	MasterColor: string?,
}

export type SharedValues = {
	Powers: { Power },
	Alignment: string,
	CharacterID: string,
	DeathAnimation: string,
	TransformationAnimation: string,
}

export type Identity = {
	SharedValues: SharedValues,
	UniqueValues: {
		Backstory: string,
		Nombre: string,
	},
	SkinColor: string,
	Items: { Item },
}

export type Outfit = {
	Items: { Item },
}

export type StarterSuit = {
	SecretIdentity: Identity,
	SuperIdentity: Identity,
}

-- Constants
-- From DataCoder.luau, Customizables.rbxm and the BrickColor palette.
-- The legacy Powers model is unavailable, so no power codes are assumed.
local ENCODING_CONVERSIONS: { [string]: string } = {
	["b1"] = "White",
	["b2"] = "Grey",
	["b3"] = "Light yellow",
	["b5"] = "Brick yellow",
	["b6"] = "Light green (Mint)",
	["b9"] = "Light reddish violet",
	["b11"] = "Pastel Blue",
	["b12"] = "Light orange brown",
	["b18"] = "Nougat",
	["b21"] = "Bright red",
	["b22"] = "Med. reddish violet",
	["b23"] = "Bright blue",
	["b24"] = "Bright yellow",
	["b25"] = "Earth orange",
	["b26"] = "Black",
	["b27"] = "Dark grey",
	["b28"] = "Dark green",
	["b29"] = "Medium green",
	["b36"] = "Lig. Yellowich orange",
	["b37"] = "Bright green",
	["b38"] = "Dark orange",
	["b39"] = "Light bluish violet",
	["b40"] = "Transparent",
	["b41"] = "Tr. Red",
	["b42"] = "Tr. Lg blue",
	["b43"] = "Tr. Blue",
	["b44"] = "Tr. Yellow",
	["b45"] = "Light blue",
	["b47"] = "Tr. Flu. Reddish orange",
	["b48"] = "Tr. Green",
	["b49"] = "Tr. Flu. Green",
	["b50"] = "Phosph. White",
	["b100"] = "Light red",
	["b101"] = "Medium red",
	["b102"] = "Medium blue",
	["b103"] = "Light grey",
	["b104"] = "Bright violet",
	["b105"] = "Br. yellowish orange",
	["b106"] = "Bright orange",
	["b107"] = "Bright bluish green",
	["b108"] = "Earth yellow",
	["b110"] = "Bright bluish violet",
	["b111"] = "Tr. Brown",
	["b112"] = "Medium bluish violet",
	["b113"] = "Tr. Medi. reddish violet",
	["b115"] = "Med. yellowish green",
	["b116"] = "Med. bluish green",
	["b118"] = "Light bluish green",
	["b119"] = "Br. yellowish green",
	["b120"] = "Lig. yellowish green",
	["b121"] = "Med. yellowish orange",
	["b123"] = "Br. reddish orange",
	["b124"] = "Bright reddish violet",
	["b125"] = "Light orange",
	["b126"] = "Tr. Bright bluish violet",
	["b127"] = "Gold",
	["b128"] = "Dark nougat",
	["b131"] = "Silver",
	["b133"] = "Neon orange",
	["b134"] = "Neon green",
	["b135"] = "Sand blue",
	["b136"] = "Sand violet",
	["b137"] = "Medium orange",
	["b138"] = "Sand yellow",
	["b140"] = "Earth blue",
	["b141"] = "Earth green",
	["b143"] = "Tr. Flu. Blue",
	["b145"] = "Sand blue metallic",
	["b146"] = "Sand violet metallic",
	["b147"] = "Sand yellow metallic",
	["b148"] = "Dark grey metallic",
	["b149"] = "Black metallic",
	["b150"] = "Light grey metallic",
	["b151"] = "Sand green",
	["b153"] = "Sand red",
	["b154"] = "Dark red",
	["b157"] = "Tr. Flu. Yellow",
	["b158"] = "Tr. Flu. Red",
	["b168"] = "Gun metallic",
	["b176"] = "Red flip/flop",
	["b178"] = "Yellow flip/flop",
	["b179"] = "Silver flip/flop",
	["b180"] = "Curry",
	["b190"] = "Fire Yellow",
	["b191"] = "Flame yellowish orange",
	["b192"] = "Reddish brown",
	["b193"] = "Flame reddish orange",
	["b194"] = "Medium stone grey",
	["b195"] = "Royal blue",
	["b196"] = "Dark Royal blue",
	["b198"] = "Bright reddish lilac",
	["b199"] = "Dark stone grey",
	["b200"] = "Lemon metalic",
	["b208"] = "Light stone grey",
	["b209"] = "Dark Curry",
	["b210"] = "Faded green",
	["b211"] = "Turquoise",
	["b212"] = "Light Royal blue",
	["b213"] = "Medium Royal blue",
	["b216"] = "Rust",
	["b217"] = "Brown",
	["b218"] = "Reddish lilac",
	["b219"] = "Lilac",
	["b220"] = "Light lilac",
	["b221"] = "Bright purple",
	["b222"] = "Light purple",
	["b223"] = "Light pink",
	["b224"] = "Light brick yellow",
	["b225"] = "Warm yellowish orange",
	["b226"] = "Cool yellow",
	["b232"] = "Dove blue",
	["b268"] = "Medium lilac",
	["b301"] = "Slime green",
	["b302"] = "Smoky grey",
	["b303"] = "Dark blue",
	["b304"] = "Parsley green",
	["b305"] = "Steel blue",
	["b306"] = "Storm blue",
	["b307"] = "Lapis",
	["b308"] = "Dark indigo",
	["b309"] = "Sea green",
	["b310"] = "Shamrock",
	["b311"] = "Fossil",
	["b312"] = "Mulberry",
	["b313"] = "Forest green",
	["b314"] = "Cadet blue",
	["b315"] = "Electric blue",
	["b316"] = "Eggplant",
	["b317"] = "Moss",
	["b318"] = "Artichoke",
	["b319"] = "Sage green",
	["b320"] = "Ghost grey",
	["b321"] = "Lilac",
	["b322"] = "Plum",
	["b323"] = "Olivine",
	["b324"] = "Laurel green",
	["b325"] = "Quill grey",
	["b327"] = "Crimson",
	["b328"] = "Mint",
	["b329"] = "Baby blue",
	["b330"] = "Carnation pink",
	["b331"] = "Persimmon",
	["b332"] = "Maroon",
	["b333"] = "Gold",
	["b334"] = "Daisy orange",
	["b335"] = "Pearl",
	["b336"] = "Fog",
	["b337"] = "Salmon",
	["b338"] = "Terra Cotta",
	["b339"] = "Cocoa",
	["b340"] = "Wheat",
	["b341"] = "Buttermilk",
	["b342"] = "Mauve",
	["b343"] = "Sunrise",
	["b344"] = "Tawny",
	["b345"] = "Rust",
	["b346"] = "Cashmere",
	["b347"] = "Khaki",
	["b348"] = "Lily white",
	["b349"] = "Seashell",
	["b350"] = "Burgundy",
	["b351"] = "Cork",
	["b352"] = "Burlap",
	["b353"] = "Beige",
	["b354"] = "Oyster",
	["b355"] = "Pine Cone",
	["b356"] = "Fawn brown",
	["b357"] = "Hurricane grey",
	["b358"] = "Cloudy grey",
	["b359"] = "Linen",
	["b360"] = "Copper",
	["b361"] = "Medium brown", -- Lune calls this Dirt brown; use the Studio name.
	["b362"] = "Bronze",
	["b363"] = "Flint",
	["b364"] = "Dark taupe",
	["b365"] = "Burnt Sienna",
	["b1001"] = "Institutional white",
	["b1002"] = "Mid gray",
	["b1003"] = "Really black",
	["b1004"] = "Really red",
	["b1005"] = "Deep orange",
	["b1006"] = "Alder",
	["b1007"] = "Dusty Rose",
	["b1008"] = "Olive",
	["b1009"] = "New Yeller",
	["b1010"] = "Really blue",
	["b1011"] = "Navy blue",
	["b1012"] = "Deep blue",
	["b1013"] = "Cyan",
	["b1014"] = "CGA brown",
	["b1015"] = "Magenta",
	["b1016"] = "Pink",
	["b1017"] = "Deep orange",
	["b1018"] = "Teal",
	["b1019"] = "Toothpaste",
	["b1020"] = "Lime green",
	["b1021"] = "Camo",
	["b1022"] = "Grime",
	["b1023"] = "Lavender",
	["b1024"] = "Pastel light blue",
	["b1025"] = "Pastel orange",
	["b1026"] = "Pastel violet",
	["b1027"] = "Pastel blue-green",
	["b1028"] = "Pastel green",
	["b1029"] = "Pastel yellow",
	["b1030"] = "Pastel brown",
	["b1031"] = "Royal purple",
	["b1032"] = "Hot pink",
	["i1 1 15"] = "Skull",
	["i1 2 1"] = "Head",
	["i2 1 1"] = "Necklace",
	["i2 1 2"] = "Leather Belt",
	["i2 1 3"] = "Analog Watch",
	["i2 1 4"] = "Tie",
	["i2 1 5"] = "Bowtie",
	["i2 1 6"] = "Scarf",
	["i2 1 7"] = "Bracelet",
	["i2 1 8"] = "Backpack",
	["i2 2 1"] = "Shades",
	["i2 2 2"] = "Nerd Glasses",
	["i2 2 3"] = "Hipster Glasses",
	["i2 2 4"] = "Sunglasses",
	["i2 3 1"] = "Generic Gloves",
	["i2 4 1"] = "Fedora",
	["i2 4 2"] = "Side Cap",
	["i2 4 3"] = "Backwards Cap",
	["i2 4 4"] = "Headphones",
	["i2 4 5"] = "Cap",
	["i2 5 1"] = "Open Zipper Jacket",
	["i2 5 2"] = "Vest",
	["i2 5 3"] = "Half Closed Zipper Jacket",
	["i2 5 4"] = "Closed Hoodie",
	["i2 5 5"] = "Open Coat",
	["i2 5 6"] = "Closed Zipper Jacket",
	["i2 5 7"] = "Half Closed Jacket",
	["i2 5 8"] = "Open Jacket",
	["i2 5 9"] = "Closed Jacket",
	["i2 5 10"] = "Cardigan",
	["i2 5 11"] = "Bullet Proof Vest",
	["i2 6 1"] = "Normal Pants",
	["i2 6 2"] = "Cargo Shorts",
	["i2 6 3"] = "Cargo Pants",
	["i2 6 4"] = "Normal Shorts",
	["i2 6 5"] = "Short Shorts",
	["i2 6 6"] = "Overall Pants",
	["i2 7 1"] = "Tube Top",
	["i2 7 2"] = "Dress Shirt",
	["i2 7 3"] = "T-Shirt",
	["i2 7 4"] = "Spaghetti Strap",
	["i2 7 5"] = "V-Neck T-Shirt",
	["i2 7 6"] = "Tank Top",
	["i2 7 7"] = "V-Neck",
	["i2 7 8"] = "Normal Shirt",
	["i2 8 1"] = "Shoes",
	["i2 8 2"] = "Boots",
	["i2 8 3"] = "Flats",
	["i2 8 4"] = "Flip Flops",
	["i2 8 5"] = "Sneakers",
	["i2 9 1"] = "Generic Socks",
	["i2 9 2"] = "Tall Socks",
	["i3 1 1"] = "Surprised Eyebrows",
	["i3 1 2"] = "Happy Eyebrows",
	["i3 1 3"] = "Angry Eyebrows",
	["i3 1 4"] = "Neutral Eyebrows",
	["i3 1 5"] = "Sad Eyebrows",
	["i3 2 1"] = "Angry Eyes",
	["i3 2 2"] = "Neutral Eyes",
	["i3 2 3"] = "Sad Eyes",
	["i3 2 4"] = "Surprised Eyes",
	["i3 2 5"] = "Happy Eyes",
	["i3 3 1"] = "Soul Patch",
	["i3 3 2"] = "Mustache",
	["i3 3 3"] = "Beard",
	["i3 3 4"] = "Goatee",
	["i3 4 1"] = "Scene Hair",
	["i3 4 2"] = "Mohawk Hair",
	["i3 4 3"] = "Club Kid Hair",
	["i3 4 4"] = "Princeton Hair",
	["i3 4 5"] = "Miss Hair",
	["i3 4 6"] = "Swoosh Hair",
	["i3 4 7"] = "Beautiful Hair",
	["i3 4 8"] = "Shaggy Hair",
	["i3 4 9"] = "Bob Hair",
	["i3 4 10"] = "Manga Hero Hair",
	["i3 4 11"] = "Beautiful People Hair",
	["i3 4 12"] = "Fabulous Hair",
	["i3 4 13"] = "Politician Hair",
	["i3 4 14"] = "Lovely Locks Hair",
	["i3 4 15"] = "Ultraflash Hair",
	["i3 4 16"] = "Animazing hair",
	["i3 4 17"] = "Wavy Hair",
	["i3 4 18"] = "Dream Hair",
	["i3 4 19"] = "Stylish Hair",
	["i3 4 20"] = "Roblohunk Hair",
	["i3 4 21"] = "Straight Hair",
	["i3 4 22"] = "Spiked Hair",
	["i3 4 23"] = "True Hair",
	["i3 4 24"] = "Action Ponytail",
	["i3 4 25"] = "Crazy Hair",
	["i3 5 1"] = "Happy Mouth",
	["i3 5 2"] = "Neutral Mouth",
	["i3 5 3"] = "Sad Mouth",
	["i3 5 4"] = "Surprised Mouth",
	["i3 5 5"] = "Angry Mouth",
	["i4 1 1"] = "Wrist Armor",
	["i4 1 2"] = "Shoulder Pads",
	["i4 1 3"] = "Forearm Pads",
	["i4 1 4"] = "Gloves",
	["i4 1 5"] = "Interior Pads",
	["i4 2 1"] = "Belt",
	["i4 2 2"] = "Center Armor",
	["i4 2 3"] = "Upper Armor",
	["i4 2 4"] = "Side Armor",
	["i4 2 5"] = "X-Armor",
	["i4 3 1"] = "Basic Emblem",
	["i4 3 2"] = "Heart Emblem",
	["i4 3 3"] = "Star Emblem",
	["i4 3 4"] = "Diamond Emblem",
	["i4 3 5"] = "Circle Emblem",
	["i4 3 6"] = "Lightning Emblem",
	["i4 3 7"] = "Shield Emblem",
	["i4 4 1"] = "Bandana",
	["i4 4 2"] = "Bandana II",
	["i4 5 1"] = "Eye Mask",
	["i4 5 2"] = "Head Mask",
	["i4 5 3"] = "No Mouth Head Mask",
	["i4 5 4"] = "Ski Mask",
	["i4 5 5"] = "Super Sunglasses",
	["i4 6 1"] = "Hood",
	["i4 6 2"] = "Cowl",
	["i4 7 1"] = "Shorts",
	["i4 7 2"] = "Leotard Shorts",
	["i4 8 1"] = "Super Boots",
	["i4 8 2"] = "Super Shoes",
	["i4 8 3"] = "Tall Super Boots",
	["i4 9 1"] = "Cape",
	["i4 9 2"] = "Mini Cape",
	["i4 10 1"] = "Sleeveless  Suit",
	["i4 10 2"] = "Full Suit",
	["i4 11 1"] = "Knee Pads",
	["m1"] = "Slate",
	["m2"] = "DiamondPlate",
	["m3"] = "Ice",
	["m4"] = "Brick",
	["m5"] = "Fabric",
	["m6"] = "WoodPlanks",
	["m7"] = "Wood",
	["m8"] = "CorrodedMetal",
	["m9"] = "Grass",
	["m10"] = "Granite",
	["m11"] = "Sand",
	["m12"] = "Metal",
	["m13"] = "Plastic",
	["m14"] = "Concrete",
	["m15"] = "Foil",
	["m16"] = "Marble",
	["m17"] = "Pebble",
	["m19"] = "SmoothPlastic",
	["m20"] = "Cobblestone",
	["nons"] = "aoih0592j0jf9j2035",
}
-- Variables
-- References
-- Private Functions
local isArray = Type.array(Type.any)
local isItem = Type.intersection(
	isArray,
	Type.union(
		Type.strictArray(Type.string, Type.optional(Type.string), Type.optional(Type.string)),
		Type.strictArray(Type.string, Type.string, Type.string, Type.string, Type.string),
		Type.strictArray(Type.string, Type.string, Type.string, Type.numberConstrained(0, 1), Type.string, Type.string)
	)
)
local isPower = Type.intersection(Type.array(Type.string), Type.strictArray(Type.string, Type.optional(Type.string)))
local isSharedValues = Type.intersection(
	isArray,
	Type.strictArray(Type.array(isPower), Type.string, Type.string, Type.string, Type.string)
)
local isUniqueValues = Type.intersection(Type.array(Type.string), Type.strictArray(Type.string, Type.string))
local isIdentity = Type.intersection(
	isArray,
	Type.interface({
		[1] = isSharedValues,
		[2] = isUniqueValues,
		[3] = Type.string,
	})
)
local isStarterSuit = Type.intersection(isArray, Type.strictArray(isIdentity, isIdentity))

local function decode(value: string): string
	local decoded = ENCODING_CONVERSIONS[value]
	if decoded then
		return decoded
	end
	local colorNumber = value:match("^b(%d+)$")
	if colorNumber then
		local number = tonumber(colorNumber)
		local color = if number then ENCODING_CONVERSIONS[`b{number}`] else nil
		assert(color, `Unknown BrickColor code: {value}`)
		return color
	end
	assert(not value:match("^[imp]%d"), `Unresolved legacy code: {value}`)
	return value
end

local function readTextureGroup(values: { unknown }, index: number): TextureGroup?
	if values[index] == nil then
		return nil
	end
	local material = values[index + 1] :: string?
	return {
		BrickColor = decode(values[index] :: string),
		Material = if material ~= nil then decode(material) else nil,
	}
end

local function convertItem(raw: unknown, path: string): Item
	local success, message = isItem(raw)
	assert(success, `{path}: {message}`)
	local values = raw :: { unknown }
	local item: Item = {
		Name = decode(values[1] :: string),
		Primary = readTextureGroup(values, 2),
	}
	if #values == 5 then
		item.Secondary = readTextureGroup(values, 4)
	elseif #values == 6 then
		item.EyeTransparency = values[4] :: number
		item.Secondary = readTextureGroup(values, 5)
	end
	return item
end

local function convertItems(values: { unknown }, start: number, path: string): { Item }
	local items: { Item } = {}
	for index = start, #values do
		table.insert(items, convertItem(values[index], `{path}[{index}]`))
	end
	return items
end

local function convertIdentity(raw: unknown, path: string): Identity
	local values = raw :: { unknown }
	local shared = values[1] :: { unknown }
	local unique = values[2] :: { string }
	local powers: { Power } = {}
	for _, power in shared[1] :: { { string } } do
		table.insert(powers, {
			Name = decode(power[1]),
			MasterColor = if power[2] ~= nil then decode(power[2]) else nil,
		})
	end
	return {
		SharedValues = {
			Powers = powers,
			Alignment = decode(shared[2] :: string),
			CharacterID = decode(shared[3] :: string),
			DeathAnimation = decode(shared[4] :: string),
			TransformationAnimation = decode(shared[5] :: string),
		},
		UniqueValues = {
			Backstory = decode(unique[1]),
			Nombre = decode(unique[2]),
		},
		SkinColor = decode(values[3] :: string),
		Items = convertItems(values, 4, path),
	}
end

-- Class
local Module = {}

Module.convertOutfit = function(raw: unknown): Outfit
	local success, message = isArray(raw)
	assert(success, `outfit: {message}`)
	return { Items = convertItems(raw :: { unknown }, 1, "outfit") }
end

Module.convertStarterSuit = function(raw: unknown): StarterSuit
	local success, message = isStarterSuit(raw)
	assert(success, `starter-suit: {message}`)
	local values = raw :: { unknown }
	return {
		SecretIdentity = convertIdentity(values[1], "starter-suit[1]"),
		SuperIdentity = convertIdentity(values[2], "starter-suit[2]"),
	}
end

return Module
