--!strict
-- turns the customization catalogue of a legacy place into item templates the way lib/character holds them, plus the
-- tables a game keeps beside them: what an entry was called in a legacy save, what it cost + who started with it.
-- the place is only ever read. an entry the library of SHL2 already has is borrowed instead of written a second time.
-- a catalogue that was fitted to another body than the one its items are worn on is stood onto that one, where a
-- shell that reaches across a joint is cut on it so each half moves with its own part of the limb. a brick comes apart
-- into two bricks right here. a wedge or a cylinder on its side doesn't, only studio can cut one: --cut-jobs writes a
-- place of those parts with scripts/util/cut-parts.luau in it, --take-cuts takes the pieces out of that place once
-- studio cut + saved it. they're kept beside the library + worn in place of their part from then on
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
local Place = require("../modules/place")
local game = require("../modules/game")
local rojo = require("../modules/rojo")
local rojoValue = require("../modules/rojo-value")
-- Types
-- lune hands out roblox datatypes without typing them
type CFrameValue = any
type Vector3Value = any
type Color3Value = any
type TextureGroupMap = { [string]: string }
-- one item per limb group, each a set of pieces named after the body parts of that group
type LimbCategoryRule = {
	Kind: "Limb",
	Group: string,
	TextureGroups: TextureGroupMap,
}
-- pieces named after body parts, straight under the entry
type PiecesCategoryRule = {
	Kind: "Pieces",
	Group: string,
	Category: string,
	TextureGroups: TextureGroupMap,
}
-- a single piece that sits on an attachment another worn item brings along
type MountCategoryRule = {
	Kind: "Mount",
	Group: string,
	Category: string,
	TextureGroups: TextureGroupMap,
	Anchor: string,
}
-- a part of the body a piece is worn on: where its middle is from the middle of the root part while every joint is
-- straight + the joint it hangs off the part above it by, with how high that one is
type SegmentRule = {
	Part: string,
	Position: { number },
	Size: { number },
	Joint: string?,
	Top: number?,
}
-- a limb of the body the legacy game ran + the parts that stand where it stood, from the top down
type BodyLimbRule = {
	Position: { number },
	Segments: { SegmentRule },
}
-- where a piece that stays in one piece is worn
type PlaceRule = {
	Limb: string,
	Part: string,
}
-- the list a legacy menu offered the entries of a category by. from a count of it on they had to be paid for
type PickerRule = {
	Path: string,
	PaidFrom: number?,
	-- what a character wears without ever picking, it isn't on the list
	Default: string?,
}
-- one item per model of the entry, each welded to a limb of the legacy body + cut up into the parts that limb is now
type SplitCategoryRule = {
	Kind: "Split",
	Group: string,
	TextureGroups: TextureGroupMap,
	Models: { { Name: string, Limb: string, Category: string } },
	-- a part that's only there for another item to sit on, by its name: the attachment it becomes
	Mounts: { [string]: string },
}
-- a single stiff piece: on a part of the body, or on an attachment another worn item brings along
type WornCategoryRule = {
	Kind: "Worn",
	Group: string,
	Category: string,
	TextureGroups: TextureGroupMap,
	-- the model inside of the entry, one named after its entry when there's none
	PieceName: string?,
	Place: PlaceRule?,
	-- the entries that are worn somewhere else than the rest
	Places: { [string]: PlaceRule }?,
	Anchor: string?,
	Tags: { string },
}
-- a single mesh the library of SHL2 may have under any name: borrowed when it does, written as its own piece when not
type MeshBorrowCategoryRule = {
	Kind: "MeshBorrow",
	Group: string,
	Category: string,
	Own: WornCategoryRule,
}
-- a decal, it becomes an image instead of a template
type FaceCategoryRule = {
	Kind: "Face",
	Group: string,
	Category: string,
	Slot: string,
	-- the model of the entry whose stand-in holds the decal, an entry without one holds it itself
	PieceName: string?,
	NameSuffix: string,
	TextureGroups: { string },
}
-- already in the library of SHL2 under the same name
type BorrowCategoryRule = {
	Kind: "Borrow",
	Group: string,
	Category: string,
}
-- how the entries of one legacy category are built + where they go
type CategoryRule =
	LimbCategoryRule
	| PiecesCategoryRule
	| MountCategoryRule
	| FaceCategoryRule
	| BorrowCategoryRule
	| SplitCategoryRule
	| WornCategoryRule
	| MeshBorrowCategoryRule
type LimbRule = {
	-- the folder of a legacy save + the model inside of a suit
	Name: string,
	Category: string,
	Parts: { string },
	-- the legacy game painted the bare body parts of a limb group, a head only ever has the skin color
	HasBase: boolean,
	Tags: { string },
}
type GameRules = {
	CataloguePath: string,
	-- the body the pieces were fitted to, when the place holds one + it's the one they're worn on
	RigPath: string?,
	PatternPath: string?,
	-- a module of the place that lists what every player owns from the start as { name, category } pairs
	StarterPath: string?,
	StarterTableName: string?,
	PriceAdjustPath: string?,
	-- the body the catalogue was fitted to when it's another one than the items are worn on: its limbs, by the name a
	-- legacy piece was welded to
	Body: { [string]: BodyLimbRule }?,
	-- the menus the entries were picked from, by legacy category + the name of the list in the script of each
	Pickers: { [string]: PickerRule }?,
	PickerTableName: string?,
	-- holds a value per channel: the color a new character wore it in. without it a part keeps the color it's stored in
	DefaultColorPath: string?,
	-- a value of a piece that says whether the hair still shows with it
	HairShownName: string?,
	-- a value of a piece that holds what a save calls it
	SaveNameName: string?,
	-- the legacy game never reset the material a part was authored with
	IsMaterialKept: boolean?,
	-- a body part with a shell on it was made invisible, the shell was all there was to see of the limb
	IsBodyHidden: boolean?,
	CategoryNames: { string },
	Categories: { [string]: CategoryRule },
	Limbs: { LimbRule },
	-- the part that stands in for the body part a piece is worn on
	StandInName: string,
	-- value objects whose presence on a piece says something about the item
	MarkerNames: { string },
	-- by the number a legacy entry stores, from 0
	Rarities: { string },
	BaseTextureGroup: string?,
	BaseColor: { number }?,
	-- how much wider than the body part its painted layer is on every axis, so the two don't flicker
	BaseInflation: number?,
	-- a limb that wears no suit still needs something to paint
	BareLimbKey: string?,
	BareLimbName: string?,
	-- the one pattern that is a material instead of an image
	PatternMaterials: { [string]: string },
}
-- what a legacy part draws. a brick, a wedge or a cylinder is written as a part of the size it's drawn in, whatever
-- mesh made it that size. anything else is carried over as it is
type ShapeKind = "Block" | "Wedge" | "Cylinder" | "Carried"
type Shape = {
	Path: string,
	Part: roblox.Instance,
	Kind: ShapeKind,
	Size: Vector3Value,
	-- against the limb the piece was welded to
	CFrame: CFrameValue,
}
-- where two parts of a limb meet
type Joint = {
	Name: string,
	Height: number,
}
type Picker = {
	Order: { [string]: number },
	PaidFrom: number?,
	Default: string?,
}
type Piece = {
	Name: string,
	StandIn: roblox.Instance?,
	Parts: { roblox.Instance },
	Markers: { string },
}
type EntryRow = {
	LegacyCategory: string,
	LegacyName: string,
	Rarity: string?,
	Cost: number?,
	-- its place on the list it was picked from
	Order: number?,
	IsStarter: boolean,
	IsBorrowed: boolean,
	ShaveHead: boolean?,
	ShaveBeard: boolean?,
	ItemIds: { string },
	LimbItemIds: { [string]: string }?,
}
type FaceRow = {
	Id: string,
	Slot: string,
	Key: string,
	Name: string,
	Image: string,
	LegacyAssetId: number,
	Color: { number },
	TextureGroups: { string },
}
type PatternRow = {
	Key: string,
	Name: string,
	Image: string,
	LegacyAssetId: number,
	Rarity: string?,
	IsStarter: boolean,
	Material: string?,
}
type Output = { path: string, contents: string }
-- the pieces studio cut a part into, from the top down, + the part they were cut from
type CutRow = {
	Part: string,
	Pieces: { string },
}
-- a part only studio can cut + the heights to cut it on, against the middle of its limb
type CutJob = {
	Id: string,
	Part: string,
	Shape: Shape,
	Heights: { number },
}
type Context = {
	rules: GameRules,
	game: string,
	-- where the items of the game are written to
	libraryPath: string,
	rig: roblox.Instance?,
	starters: { [string]: string },
	pickers: { [string]: Picker },
	-- the color a recolored part starts out in, by its texture group
	defaultColors: { [string]: Color3Value },
	-- the file each legacy image has under asset/image, by its id
	imagePaths: { [string]: string },
	outputs: { Output },
	entries: { EntryRow },
	faces: { FaceRow },
	borrows: { string },
	-- the entries that stand for wearing nothing
	empties: { EntryRow },
	-- what became of every part that reaches across a joint
	joints: { string },
	-- the pieces studio cut, by the id of their part
	cuts: { [string]: CutRow },
	-- how many parts of a piece needed studio so far, the next one is told apart by it
	cutCounts: { [string]: number },
	cutJobs: { CutJob },
	notes: { string },
	failures: { string },
	-- per category of the library, for the summary
	itemCounts: { [string]: number },
	contentMeshIds: { [string]: boolean },
	rigMeshIds: { [string]: boolean },
}
-- Constants
local USAGE = "Usage: lune run scripts/util/convert-catalogue.lune.luau <game> <place.rbxl> [--out <dir>] [--force | -f]"
	.. " [--cut-jobs <jobs.rbxl>] [--take-cuts <cut.rbxl>]"
local PATH_DELIMITER = "/"
local ID_DELIMITER = "_"
-- the library of SHL2, an entry it has already is borrowed from there
local BORROW_PATH = game.BORROW_PATH
-- the table import-images lands the legacy images by, so a row written here can't name another file than it does
local IMAGE_TABLE_PATH = "asset/legacy-ids.tsv"
local IMAGE_TABLE_DELIMITER = "\t"
local IMAGE_PATH_PREFIX = "asset/image/"
local ROOT_NAME = "root"
local BASE_NAME = "base"
local MESH_NAME = "mesh"
local TEXTURE_GROUP_ATTRIBUTE = "TextureGroup"
local MATERIAL_SMOOTH_PLASTIC = 272
-- what a computed offset is rounded to, a float that went through a matrix comes back with noise at the end
local CFRAME_PRECISION = 1e6
local SIZE_TOLERANCE = 1e-3
local LIST_KEYS = { "Entries", "Extras", "Empty", "ItemIds", "TextureGroups" }
local UNION_EXTENSION = ".rbxm"
-- the pieces studio cut sit beside the library they're worn in, a folder the game is never built from
local CUTS_SUFFIX = ".cuts"
local CUTS_INDEX_NAME = "index.tsv"
local CUTS_INDEX_HEADER = "id\tpart\tpieces"
local CUTS_COLUMN_DELIMITER = "\t"
local CUTS_PIECE_DELIMITER = ","
-- what studio runs over the place of --cut-jobs, the place carries it along
local CUT_SCRIPT_PATH = "scripts/util/cut-parts.luau"
local CUT_SCRIPT_NAME = "CutParts"
local CUT_JOBS_NAME = "Jobs"
local CUT_PIECES_PATH = "Workspace/Cuts"
local CUT_HEIGHT_DELIMITER = ","
-- a part can't be thinner than this, so nothing is cut off a shell that reaches less far across a joint
local JOINT_TOLERANCE = 1e-3
-- how far off an axis a part may be turned + still count as standing square to it
local AXIS_TOLERANCE = 1e-4
-- how fine a shape that can't be cut is sampled to find the part of the limb that holds most of it
local SAMPLE_COUNT = 24
-- the corners of a wedge in halves of its size: the slope climbs towards the back
local WEDGE_CORNERS = {
	{ -1, -1, -1 },
	{ 1, -1, -1 },
	{ -1, -1, 1 },
	{ 1, -1, 1 },
	{ -1, 1, 1 },
	{ 1, 1, 1 },
}
local SHAPE_NAMES: { [ShapeKind]: string } = {
	Block = "brick",
	Wedge = "wedge",
	Cylinder = "cylinder",
	Carried = "mesh",
}
-- a part of SHL1 is named after the channel it's colored by, which are the texture groups of this codebase
local CHANNEL_TEXTURE_GROUPS: TextureGroupMap = {
	Primary = "Primary",
	Secondary = "Secondary",
	Tertiary = "Tertiary",
	Hair = "Hair",
}
local RULES: { [string]: GameRules } = {
	shl3 = {
		CataloguePath = "ReplicatedStorage/Customization",
		RigPath = "ReplicatedStorage/Mannequin",
		PatternPath = "ReplicatedStorage/Textures",
		StarterPath = "ReplicatedStorage/DataModule",
		StarterTableName = "starter_data",
		PriceAdjustPath = "Workspace/PriceAdjust",
		CategoryNames = {
			"Suits",
			"Shirts",
			"Pants",
			"Accessories",
			"Emblems",
			"Capes",
			"Hair",
			"FacialHair",
			"Hats",
			"Glasses",
			"Eyes",
			"Mouths",
		},
		Categories = {
			Suits = {
				Kind = "Limb",
				Group = "costume",
				TextureGroups = { Primary = "Primary", Secondary = "Secondary" },
			},
			Shirts = {
				Kind = "Pieces",
				Group = "clothing",
				Category = "shirts",
				TextureGroups = { Main = "Primary", Detail = "Secondary" },
			},
			Pants = {
				Kind = "Pieces",
				Group = "clothing",
				Category = "pants",
				TextureGroups = { Main = "Primary", Detail = "Secondary" },
			},
			Accessories = {
				Kind = "Pieces",
				Group = "costume",
				Category = "accessories",
				TextureGroups = { Primary = "Primary", Secondary = "Secondary" },
			},
			Emblems = {
				Kind = "Mount",
				Group = "costume",
				Category = "emblems",
				TextureGroups = { Primary = "Primary", Secondary = "Secondary" },
				Anchor = "EmblemAttachment",
			},
			-- a cape only ever had the one color, whatever its parts were called
			Capes = {
				Kind = "Mount",
				Group = "costume",
				Category = "capes",
				TextureGroups = { Primary = "Primary", Secondary = "Primary" },
				Anchor = "CapeAttachment",
			},
			Hair = { Kind = "Borrow", Group = "cosmetics", Category = "hair" },
			FacialHair = { Kind = "Borrow", Group = "cosmetics", Category = "facial-hair" },
			Hats = { Kind = "Borrow", Group = "clothing", Category = "hats" },
			Glasses = { Kind = "Borrow", Group = "clothing", Category = "glasses" },
			-- the eyes were tinted, the mouth never was
			Eyes = {
				Kind = "Face",
				Group = "cosmetics",
				Category = "eyes",
				Slot = "Eyes",
				PieceName = "Eyes",
				NameSuffix = " Eyes",
				TextureGroups = { "Primary" },
			},
			Mouths = {
				Kind = "Face",
				Group = "cosmetics",
				Category = "mouth",
				Slot = "Mouth",
				PieceName = "Mouth",
				NameSuffix = " Mouth",
				TextureGroups = {},
			},
		},
		Limbs = {
			-- taking the mask off takes the head piece off, which is what a hood does here
			{ Name = "Head", Category = "suit-head", Parts = { "Head" }, HasBase = false, Tags = { "Hood" } },
			{
				Name = "Torso",
				Category = "suit-torso",
				Parts = { "UpperTorso", "LowerTorso" },
				HasBase = true,
				Tags = {},
			},
			{
				Name = "Left Arm",
				Category = "suit-left-arm",
				Parts = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
				HasBase = true,
				Tags = {},
			},
			{
				Name = "Right Arm",
				Category = "suit-right-arm",
				Parts = { "RightUpperArm", "RightLowerArm", "RightHand" },
				HasBase = true,
				Tags = {},
			},
			{
				Name = "Left Leg",
				Category = "suit-left-leg",
				Parts = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
				HasBase = true,
				Tags = {},
			},
			{
				Name = "Right Leg",
				Category = "suit-right-leg",
				Parts = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
				HasBase = true,
				Tags = {},
			},
		},
		StandInName = "Middle",
		MarkerNames = { "ShaveHead", "ShaveBeard" },
		Rarities = { "VeryCommon", "Common", "Uncommon", "Rare", "Legendary" },
		BaseTextureGroup = "Tertiary",
		-- what a new legacy character started with
		BaseColor = { 0, 0, 0 },
		BaseInflation = 0.02,
		BareLimbKey = "bodysuit",
		BareLimbName = "Bodysuit",
		PatternMaterials = { Neon = "Neon" },
	},
	shl1 = {
		CataloguePath = "ServerStorage/Customization",
		-- the block body of an R15 avatar, read off the joints of the mannequin SHL3's pieces were fitted to. it stands
		-- in the box of the R6 body this catalogue was built around: same torso, same head, arms + legs of the same
		-- width in the same place, the arms 0.047 short of the shoulder line
		Body = {
			Head = {
				Position = { 0, 2.15, 0 },
				Segments = { { Part = "Head", Position = { 0, 2.15, 0 }, Size = { 2, 1, 1 } } },
			},
			Torso = {
				Position = { 0, 0.65, 0 },
				Segments = {
					{ Part = "UpperTorso", Position = { 0, 0.84998, 0 }, Size = { 2, 1.60003, 1 } },
					{
						Part = "LowerTorso",
						Position = { 0, -0.15003, 0 },
						Size = { 2, 0.40006, 1 },
						Joint = "waist",
						Top = 0.05,
					},
				},
			},
			["Left Arm"] = {
				Position = { -1.5, 0.65, 0 },
				Segments = {
					{ Part = "LeftUpperArm", Position = { -1.5, 1.01867, 0 }, Size = { 1, 1.16867, 1 } },
					{
						Part = "LeftLowerArm",
						Position = { -1.5, 0.42593, 0 },
						Size = { 1, 1.05192, 1 },
						Joint = "elbow",
						Top = 0.68462,
					},
					{
						Part = "LeftHand",
						Position = { -1.5, -0.20005, 0 },
						Size = { 1, 0.30003, 1 },
						Joint = "wrist",
						Top = -0.075,
					},
				},
			},
			["Right Arm"] = {
				Position = { 1.5, 0.65, 0 },
				Segments = {
					{ Part = "RightUpperArm", Position = { 1.5, 1.01867, 0 }, Size = { 1, 1.16867, 1 } },
					{
						Part = "RightLowerArm",
						Position = { 1.5, 0.42593, 0 },
						Size = { 1, 1.05192, 1 },
						Joint = "elbow",
						Top = 0.68462,
					},
					{
						Part = "RightHand",
						Position = { 1.5, -0.20005, 0 },
						Size = { 1, 0.30003, 1 },
						Joint = "wrist",
						Top = -0.075,
					},
				},
			},
			["Left Leg"] = {
				Position = { -0.5, -1.35, 0 },
				Segments = {
					{ Part = "LeftUpperLeg", Position = { -0.5, -0.77078, 0 }, Size = { 1, 1.21657, 1 } },
					{
						Part = "LeftLowerLeg",
						Position = { -0.5, -1.5509, 0 },
						Size = { 1, 1.19309, 1 },
						Joint = "knee",
						Top = -1.17188,
					},
					{
						Part = "LeftFoot",
						Position = { -0.5, -2.2, 0 },
						Size = { 1, 0.3, 1 },
						Joint = "ankle",
						Top = -2.09806,
					},
				},
			},
			["Right Leg"] = {
				Position = { 0.5, -1.35, 0 },
				Segments = {
					{ Part = "RightUpperLeg", Position = { 0.5, -0.77078, 0 }, Size = { 1, 1.21657, 1 } },
					{
						Part = "RightLowerLeg",
						Position = { 0.5, -1.5509, 0 },
						Size = { 1, 1.19309, 1 },
						Joint = "knee",
						Top = -1.17188,
					},
					{
						Part = "RightFoot",
						Position = { 0.5, -2.2, 0 },
						Size = { 1, 0.3, 1 },
						Joint = "ankle",
						Top = -2.09806,
					},
				},
			},
		},
		-- the scripts of the creator's pages, each with the list its arrows step through. what's past the free ones
		-- took a pass, the emblems past theirs the group
		Pickers = {
			Bodies = { Path = "ServerStorage/MainGui/MainFrame/BodyParts/LeftButtons/Suits/Script", PaidFrom = 4 },
			Hats = { Path = "ServerStorage/MainGui/MainFrame/BodyParts/LeftButtons/Mask/Script", PaidFrom = 7 },
			Hair = { Path = "ServerStorage/MainGui/MainFrame/NormalChar/LeftButtons/Hair/Script", PaidFrom = 13 },
			Faces = {
				Path = "ServerStorage/MainGui/MainFrame/NormalChar/LeftButtons/Face/Script",
				PaidFrom = 7,
				Default = "Head0",
			},
			ChestPieces = {
				Path = "ServerStorage/MainGui/MainFrame/BodyParts/LeftButtons/Emblems/Script",
				PaidFrom = 4,
			},
			Capes = { Path = "ServerStorage/MainGui/MainFrame/BodyParts/LeftButtons/Capes/Script" },
			Other = { Path = "ServerStorage/MainGui/MainFrame/BodyParts/LeftButtons/Other/Script" },
		},
		PickerTableName = "objects",
		DefaultColorPath = "ServerStorage/MainGui",
		HairShownName = "Hair",
		SaveNameName = "Vader",
		IsMaterialKept = true,
		IsBodyHidden = true,
		CategoryNames = { "Bodies", "Hats", "Hair", "Faces", "ChestPieces", "Capes", "Other" },
		Categories = {
			-- a suit is five shells that could be mixed, the limb categories are the ones SHL3 mixes its suits by
			Bodies = {
				Kind = "Split",
				Group = "costume",
				TextureGroups = CHANNEL_TEXTURE_GROUPS,
				Models = {
					{ Name = "Chest", Limb = "Torso", Category = "suit-torso" },
					{ Name = "Arm1", Limb = "Left Arm", Category = "suit-left-arm" },
					{ Name = "Arm2", Limb = "Right Arm", Category = "suit-right-arm" },
					{ Name = "Leg1", Limb = "Left Leg", Category = "suit-left-leg" },
					{ Name = "Leg2", Limb = "Right Leg", Category = "suit-right-leg" },
				},
				Mounts = { EmblemAnchor = "EmblemAttachment" },
			},
			Hats = {
				Kind = "Worn",
				Group = "costume",
				Category = "hats",
				TextureGroups = CHANNEL_TEXTURE_GROUPS,
				PieceName = "Hat",
				Place = { Limb = "Head", Part = "Head" },
				Tags = {},
			},
			Hair = {
				Kind = "MeshBorrow",
				Group = "cosmetics",
				Category = "hair",
				Own = {
					Kind = "Worn",
					Group = "cosmetics",
					Category = "hair",
					TextureGroups = CHANNEL_TEXTURE_GROUPS,
					PieceName = "Hair",
					Place = { Limb = "Head", Part = "Head" },
					Tags = { "Hair" },
				},
			},
			-- a face is one picture of the whole of it, nothing of it is tinted
			Faces = {
				Kind = "Face",
				Group = "cosmetics",
				Category = "face",
				Slot = "Face",
				NameSuffix = "",
				TextureGroups = {},
			},
			-- an emblem sits on the anchor the chest of the worn suit brings along
			ChestPieces = {
				Kind = "Worn",
				Group = "costume",
				Category = "emblems",
				TextureGroups = CHANNEL_TEXTURE_GROUPS,
				PieceName = "Emblem",
				Anchor = "EmblemAttachment",
				Tags = {},
			},
			Capes = {
				Kind = "Worn",
				Group = "costume",
				Category = "capes",
				TextureGroups = CHANNEL_TEXTURE_GROUPS,
				PieceName = "Cape",
				Place = { Limb = "Torso", Part = "UpperTorso" },
				Tags = {},
			},
			-- what's strapped to the back rides on the chest, a gun on the forearm it's built around: neither bends
			Other = {
				Kind = "Worn",
				Group = "costume",
				Category = "extras",
				TextureGroups = CHANNEL_TEXTURE_GROUPS,
				Place = { Limb = "Torso", Part = "UpperTorso" },
				Places = {
					LeftGunArm = { Limb = "Left Arm", Part = "LeftLowerArm" },
					RightGunArm = { Limb = "Right Arm", Part = "RightLowerArm" },
				},
				Tags = {},
			},
		},
		Limbs = {},
		StandInName = "Middle",
		MarkerNames = {},
		-- nothing of this catalogue has a rarity
		Rarities = {},
		PatternMaterials = {},
	},
}
-- Variables
-- References
local CFrame = (roblox :: any).CFrame
local Vector3 = (roblox :: any).Vector3
-- Private Functions
local function parseArgs(args: { string }): (string, string, string, boolean, string?, string?)
	local values: { string } = {}
	local outPath = "."
	local isForced = false
	local cutJobsPath: string? = nil
	local takeCutsPath: string? = nil
	local index = 1
	while index <= #args do
		local arg = args[index]
		if arg == "--force" or arg == "-f" then
			isForced = true
		elseif arg == "--out" then
			index += 1
			outPath = (assert(args[index], `Expected a directory after --out\n{USAGE}`):gsub("\\", "/"))
		elseif arg == "--cut-jobs" then
			index += 1
			cutJobsPath = (assert(args[index], `Expected a place to write after --cut-jobs\n{USAGE}`):gsub("\\", "/"))
		elseif arg == "--take-cuts" then
			index += 1
			takeCutsPath = (assert(args[index], `Expected a place after --take-cuts\n{USAGE}`):gsub("\\", "/"))
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(values, (arg:gsub("\\", "/")))
		end
		index += 1
	end
	assert(#values == 2, `Expected a game and a place\n{USAGE}`)
	return values[1], values[2], outPath, isForced, cutJobsPath, takeCutsPath
end

local function read(inst: roblox.Instance, name: string): any
	-- lune's Instance typedef leaves out dynamic property indexing
	return (inst :: any)[name]
end

local function getSortedChildren(inst: roblox.Instance, className: string?): { roblox.Instance }
	local children: { roblox.Instance } = {}
	for _, child in inst:GetChildren() do
		if className == nil or child.ClassName == className then
			table.insert(children, child)
		end
	end
	-- a place file keeps no order worth keeping, a sorted one makes two runs write the same files
	table.sort(children, function(a: roblox.Instance, b: roblox.Instance): boolean
		return a.Name < b.Name
	end)
	return children
end

-- "LeftLowerArm", "Spaghetti Strap Top" + "Hat12" all become what a file of the library is called
local function toKebab(name: string): string
	local spaced = name:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2")
	local key = spaced:lower():gsub("[^%w]+", "-")
	key = key:gsub("^%-+", ""):gsub("%-+$", "")
	return key
end

local function getItemId(group: string, category: string, key: string): string
	for _, value in { group, category, key } do
		assert(
			value ~= "" and value:find(ID_DELIMITER, 1, true) == nil and value:find(PATH_DELIMITER, 1, true) == nil,
			`"{value}" can't be part of an item id`
		)
	end
	return table.concat({ group, category, key }, ID_DELIMITER)
end

local function getAssetId(content: any): string?
	if content == nil or content.SourceType.Name ~= "Uri" then
		return nil
	end
	return (content.Uri :: string):match("(%d+)%s*$")
end

local function round(value: number): number
	local rounded = math.round(value * CFRAME_PRECISION) / CFRAME_PRECISION
	-- a negative zero is still written with its sign
	return if rounded == 0 then 0 else rounded
end

local function getIfIdentity(cframe: CFrameValue): boolean
	local components = { cframe:GetComponents() }
	for index, value in { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } do
		if round(components[index]) ~= value then
			return false
		end
	end
	return true
end

local function toCFrameValue(cframe: CFrameValue): rojo.StrictPropertyValue
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cframe:GetComponents()
	return {
		CFrame = {
			position = { round(x), round(y), round(z) },
			orientation = {
				{ round(r00), round(r01), round(r02) },
				{ round(r10), round(r11), round(r12) },
				{ round(r20), round(r21), round(r22) },
			},
		},
	}
end

local function newAttributes(
	values: { [string]: string | boolean }
): { Attributes: { [string]: rojo.StrictPropertyValue } }
	local attributes: { [string]: rojo.StrictPropertyValue } = {}
	for name, value in values do
		attributes[name] = rojoValue.toValue(value)
	end
	return { Attributes = attributes }
end

local function note(context: Context, message: string)
	table.insert(context.notes, message)
end

local function fail(context: Context, category: string, name: string, reason: string)
	table.insert(context.failures, `{category}/{name}: {reason}`)
end

-- a name is only taken once inside of a piece, the second "primary" is "primary-2"
local function newNameGetter(): (name: string) -> string
	local counts: { [string]: number } = {}
	return function(name: string): string
		local count = (counts[name] or 0) + 1
		counts[name] = count
		return if count == 1 then name else `{name}-{count}`
	end
end

local function newMeshNode(context: Context, mesh: roblox.Instance): rojo.ModelNode
	local properties: rojo.NodeProperties = {
		MeshType = rojoValue.toValue(read(mesh, "MeshType"), "Enum"),
	}
	local meshId = getAssetId(read(mesh, "MeshContent"))
	if meshId then
		properties.MeshContent = rojoValue.toValue(read(mesh, "MeshContent"))
		context.contentMeshIds[meshId] = true
	end
	if getAssetId(read(mesh, "TextureContent")) then
		properties.TextureContent = rojoValue.toValue(read(mesh, "TextureContent"))
	end
	local scale: Vector3Value = read(mesh, "Scale")
	if scale ~= Vector3.one then
		properties.Scale = rojoValue.toValue(scale)
	end
	local offset: Vector3Value = read(mesh, "Offset")
	if offset ~= Vector3.zero then
		properties.Offset = rojoValue.toValue(offset)
	end
	local vertexColor: Vector3Value = read(mesh, "VertexColor")
	if vertexColor ~= Vector3.one then
		properties.VertexColor = rojoValue.toValue(vertexColor)
	end
	return { Name = MESH_NAME, ClassName = "SpecialMesh", Properties = properties }
end

-- how a part looks whatever its shape is. one that's recolored starts out in the color a new character wore it in,
-- where the game kept one
local function newSurface(
	context: Context,
	path: string,
	part: roblox.Instance,
	textureGroup: string?
): rojo.NodeProperties
	local defaultColor = if textureGroup then context.defaultColors[textureGroup] else nil
	local properties: rojo.NodeProperties = {
		Color = rojoValue.toValue(defaultColor or read(part, "Color")),
	}
	local material = read(part, "Material")
	if textureGroup and material.Value ~= MATERIAL_SMOOTH_PLASTIC and not context.rules.IsMaterialKept then
		-- the legacy game reset whatever it recolored to smooth plastic on every rebuild, what was authored never showed
		note(context, `{path}: authored material {material.Name} of a "{textureGroup}" part dropped`)
		properties.Material = { Enum = MATERIAL_SMOOTH_PLASTIC }
	else
		properties.Material = rojoValue.toValue(material, "Enum")
	end
	if read(part, "Transparency") ~= 0 then
		properties.Transparency = rojoValue.toValue(read(part, "Transparency"), "Float32")
	end
	if read(part, "Reflectance") ~= 0 then
		properties.Reflectance = rojoValue.toValue(read(part, "Reflectance"), "Float32")
	end
	if textureGroup then
		properties.Attributes = newAttributes({ [TEXTURE_GROUP_ATTRIBUTE] = textureGroup })
	end
	return properties
end

-- a part of a legacy piece, placed by where it sat against the stand-in
local function newPartNode(
	context: Context,
	path: string,
	part: roblox.Instance,
	name: string,
	origin: CFrameValue,
	textureGroup: string?,
	keptAttachmentNames: { string }
): rojo.ModelNode
	local properties = newSurface(context, path, part, textureGroup)
	properties.Size = rojoValue.toValue(read(part, "Size"))
	local offset: CFrameValue = origin:ToObjectSpace(read(part, "CFrame"))
	if not getIfIdentity(offset) then
		properties.CFrame = toCFrameValue(offset)
	end
	if part.ClassName == "MeshPart" then
		local meshId = assert(getAssetId(read(part, "MeshContent")), `{path} is a MeshPart without a mesh`)
		context.contentMeshIds[meshId] = true
		properties.MeshContent = rojoValue.toValue(read(part, "MeshContent"))
		properties.InitialSize = rojoValue.toValue(read(part, "InitialSize"))
		properties.RenderFidelity = rojoValue.toValue(read(part, "RenderFidelity"), "Enum")
		if getAssetId(read(part, "TextureContent")) then
			properties.TextureContent = rojoValue.toValue(read(part, "TextureContent"))
		end
		if read(part, "DoubleSided") then
			properties.DoubleSided = rojoValue.toValue(true)
		end
	elseif part.ClassName == "Part" then
		local shape = read(part, "Shape")
		if shape.Name ~= "Block" then
			properties.Shape = rojoValue.toValue(shape, "Enum")
		end
	else
		error(`{path} is a {part.ClassName}, which can't be written as a model file`)
	end

	local children: { rojo.ModelNode } = {}
	for _, child in getSortedChildren(part) do
		if child.ClassName == "SpecialMesh" then
			table.insert(children, newMeshNode(context, child))
		elseif child.ClassName == "Attachment" and table.find(keptAttachmentNames, child.Name) then
			local attachmentCFrame: CFrameValue = read(child, "CFrame")
			table.insert(children, {
				Name = child.Name,
				ClassName = "Attachment",
				Properties = if getIfIdentity(attachmentCFrame)
					then nil
					else { CFrame = toCFrameValue(attachmentCFrame) } :: rojo.NodeProperties,
			})
		elseif child:IsA("BasePart") then
			-- the legacy game only ever welded what sat right under a piece
			note(context, `{path}: "{child.Name}" sits inside of another part, dropped`)
		end
	end
	return {
		Name = name,
		ClassName = part.ClassName,
		Properties = properties,
		Children = if #children > 0 then children else nil,
	}
end

-- the layer over a body part that takes the color the legacy game gave the body part itself
local function newBaseNode(context: Context, bodyPart: roblox.Instance): rojo.ModelNode
	local rules = context.rules
	local color = assert(rules.BaseColor, "a painted layer needs a color")
	local inflation = assert(rules.BaseInflation, "a painted layer needs to know how far it stands off the body")
	local textureGroup = assert(rules.BaseTextureGroup, "a painted layer needs a texture group")
	local meshId = assert(getAssetId(read(bodyPart, "MeshContent")), `rig part "{bodyPart.Name}" has no mesh`)
	context.rigMeshIds[meshId] = true
	return {
		Name = BASE_NAME,
		ClassName = "MeshPart",
		Properties = {
			Color = { Color3 = color },
			Size = rojoValue.toValue(read(bodyPart, "Size") + Vector3.one * inflation),
			Material = { Enum = MATERIAL_SMOOTH_PLASTIC },
			MeshContent = rojoValue.toValue(read(bodyPart, "MeshContent")),
			InitialSize = rojoValue.toValue(read(bodyPart, "InitialSize")),
			RenderFidelity = rojoValue.toValue(read(bodyPart, "RenderFidelity"), "Enum"),
			Attributes = newAttributes({ [TEXTURE_GROUP_ATTRIBUTE] = textureGroup }),
		} :: rojo.NodeProperties,
	}
end

-- everything of a legacy sub-model that gets worn: the stand-in, what shows + what it's marked with
local function readPiece(context: Context, path: string, name: string, model: roblox.Instance?): Piece
	local rules = context.rules
	local piece: Piece = { Name = name, StandIn = nil, Parts = {}, Markers = {} }
	if model == nil then
		return piece
	end
	for _, child in getSortedChildren(model) do
		if child:IsA("BasePart") then
			if child.Name == rules.StandInName then
				assert(piece.StandIn == nil, `{path} has two "{rules.StandInName}"`)
				piece.StandIn = child
			elseif read(child, "Transparency") >= 1 then
				note(context, `{path}: "{child.Name}" is invisible, dropped`)
			else
				table.insert(piece.Parts, child)
			end
		elseif table.find(rules.MarkerNames, child.Name) then
			table.insert(piece.Markers, child.Name)
		elseif child.ClassName == "Model" or child.ClassName == "Folder" then
			note(context, `{path}: "{child.Name}" ({child.ClassName}) isn't part of the piece, dropped`)
		end
	end
	return piece
end

-- what a piece is worn by: an invisible part the size of what it was fitted to, holding the one attachment that
-- names its anchor
local function newRootNode(rojoId: string, size: rojo.StrictPropertyValue, anchorName: string): rojo.ModelNode
	return {
		Name = ROOT_NAME,
		ClassName = "Part",
		Properties = {
			Size = size,
			Transparency = { Float32 = 1 },
			Attributes = newAttributes({ Rojo_Id = rojoId }),
		} :: rojo.NodeProperties,
		Children = { { Name = anchorName, ClassName = "Attachment" } },
	}
end

local function newModelNode(name: string, rojoId: string, children: { rojo.ModelNode }): rojo.ModelNode
	return {
		Name = name,
		ClassName = "Model",
		Properties = {
			Attributes = newAttributes({ Rojo_Target_PrimaryPart = rojoId }),
		} :: rojo.NodeProperties,
		Children = children,
	}
end

-- a piece the way an item wears it: a root with everything else placed against it
local function newPieceNode(
	context: Context,
	path: string,
	rojoId: string,
	piece: Piece,
	anchorName: string,
	textureGroups: TextureGroupMap,
	baseBodyPart: roblox.Instance?,
	keptAttachmentNames: { string }
): rojo.ModelNode
	local standIn = piece.StandIn
	local fittedTo = standIn or baseBodyPart
	assert(fittedTo, `{path} has no "{context.rules.StandInName}" to fit it to its anchor`)
	local origin: CFrameValue = if standIn then read(standIn, "CFrame") else CFrame.identity
	if standIn and baseBodyPart then
		local delta: Vector3Value = read(standIn, "Size") - read(baseBodyPart, "Size")
		if delta.Magnitude > SIZE_TOLERANCE then
			note(context, `{path}: the stand-in isn't the size of the rig's "{baseBodyPart.Name}"`)
		end
	end

	local children: { rojo.ModelNode } = {
		newRootNode(rojoId, rojoValue.toValue(read(fittedTo, "Size")), anchorName),
	}
	if baseBodyPart then
		table.insert(children, newBaseNode(context, baseBodyPart))
	end
	local getName = newNameGetter()
	for _, part in piece.Parts do
		local textureGroup = textureGroups[part.Name]
		if textureGroup == nil then
			note(context, `{path}: "{part.Name}" was never recolored, it keeps its color`)
		end
		table.insert(
			children,
			newPartNode(
				context,
				`{path}/{part.Name}`,
				part,
				getName(toKebab(part.Name)),
				origin,
				textureGroup,
				keptAttachmentNames
			)
		)
	end
	return newModelNode(toKebab(piece.Name), rojoId, children)
end

-- an item of one piece is that piece, one of several is a folder of them
local function newItemNode(
	pieces: { rojo.ModelNode },
	attributes: { [string]: string | boolean },
	tags: { string }
): rojo.ModelJSON
	assert(#pieces > 0, "an item needs a piece")
	local itemAttributes = newAttributes(attributes)
	local properties: rojo.NodeProperties = {}
	local item: rojo.ModelJSON = { ClassName = "Folder", Properties = properties, Children = pieces }
	if #pieces == 1 then
		local piece = pieces[1]
		local pieceProperties = piece.Properties
		local pieceAttributes = pieceProperties and pieceProperties.Attributes
		if pieceAttributes then
			-- what points the piece at its root stays on it
			for name, value in pieceAttributes.Attributes do
				itemAttributes.Attributes[name] = value
			end
		end
		item = { ClassName = piece.ClassName, Properties = properties, Children = piece.Children }
	end
	properties.Attributes = itemAttributes
	if #tags > 0 then
		properties.Tags = tags
	end
	return item
end

local function getRojoId(context: Context, group: string, category: string, key: string, pieceName: string?): string
	-- unique in the whole project, the library of SHL2 uses its paths the same way
	local names = { context.game, group, category, key }
	if pieceName then
		table.insert(names, toKebab(pieceName))
	end
	table.insert(names, ROOT_NAME)
	return table.concat(names, PATH_DELIMITER)
end

local function writeItem(context: Context, group: string, category: string, key: string, item: rojo.ModelJSON): string
	local id = getItemId(group, category, key)
	local libraryCategory = `{group}/{category}`
	context.itemCounts[libraryCategory] = (context.itemCounts[libraryCategory] or 0) + 1
	table.insert(context.outputs, {
		path = `{context.libraryPath}/{libraryCategory}/{key}.model.json`,
		contents = rojoValue.encode(item :: any),
	})
	return id
end

local function readImagePaths(path: string): { [string]: string }
	assert(fs.isFile(path), `No table of the legacy ids at "{path}"`)
	local lines = fs.readFile(path):split("\n")
	local header = lines[1]:gsub("\r", ""):split(IMAGE_TABLE_DELIMITER)
	local idColumn = assert(table.find(header, "id"), `"{path}" has no id column`)
	local targetColumn = assert(table.find(header, "target"), `"{path}" has no target column`)
	local paths: { [string]: string } = {}
	for index = 2, #lines do
		local cells = lines[index]:gsub("\r", ""):split(IMAGE_TABLE_DELIMITER)
		local target = cells[targetColumn]
		-- whatever isn't a file is an id that stays in the cloud or one that was dropped
		if target and target:sub(1, #IMAGE_PATH_PREFIX) == IMAGE_PATH_PREFIX then
			paths[cells[idColumn]] = target
		end
	end
	return paths
end

local function getRigPart(context: Context, name: string): roblox.Instance?
	local rig = context.rig
	local rigPart = if rig then rig:FindFirstChild(name) else nil
	return if rigPart and rigPart:IsA("BasePart") then rigPart else nil
end

local function getRarity(context: Context, entry: roblox.Instance): string?
	-- a catalogue that has none names none
	if #context.rules.Rarities == 0 then
		return nil
	end
	local value = entry:FindFirstChild("Rarity")
	local index = if value then read(value, "Value") + 1 else 1
	return assert(context.rules.Rarities[index], `"{entry.Name}" has rarity {index - 1}, which has no name`)
end

-- what a menu handed out without a pass: the entries ahead of the paid ones + the one nobody has to pick
local function getIfFree(picker: Picker, name: string): boolean
	local order = picker.Order[name]
	if order == nil then
		return picker.Default == name
	end
	local paidFrom = picker.PaidFrom
	return paidFrom == nil or order < paidFrom
end

local function getItemAttributes(name: string, rarity: string?): { [string]: string | boolean }
	local attributes: { [string]: string | boolean } = { Name = name }
	if rarity then
		attributes.Rarity = rarity
	end
	return attributes
end

local function newEntryRow(context: Context, legacyCategory: string, entry: roblox.Instance): EntryRow
	local cost = entry:FindFirstChild("Cost")
	local picker = context.pickers[legacyCategory]
	local row: EntryRow = {
		LegacyCategory = legacyCategory,
		LegacyName = entry.Name,
		Rarity = getRarity(context, entry),
		-- as stored, what a player paid was this times the price adjustment, rounded up to the next hundred
		Cost = if cost then read(cost, "Value") else nil,
		Order = if picker then picker.Order[entry.Name] else nil,
		-- a game that sold by the menu started everybody with what the menu gave away
		IsStarter = if picker then getIfFree(picker, entry.Name) else context.starters[entry.Name] ~= nil,
		IsBorrowed = false,
		ItemIds = {},
	}
	if picker and row.Order == nil and picker.Default ~= entry.Name then
		note(context, `{legacyCategory}/{entry.Name}: not on the list of its menu, nobody could pick it`)
	end
	local starterCategory = context.starters[entry.Name]
	if starterCategory and starterCategory ~= legacyCategory then
		note(context, `{legacyCategory}/{entry.Name}: the starter list files it under "{starterCategory}"`)
	end
	return row
end

local function addMarkers(row: EntryRow, attributes: { [string]: string | boolean }, markers: { string })
	for _, marker in markers do
		attributes[marker] = true
		if marker == "ShaveHead" then
			row.ShaveHead = true
		elseif marker == "ShaveBeard" then
			row.ShaveBeard = true
		end
	end
end

local function getMountAnchorNames(rules: GameRules): { string }
	local names: { string } = {}
	for _, rule in rules.Categories do
		if rule.Kind == "Mount" then
			table.insert(names, rule.Anchor)
		end
	end
	table.sort(names)
	return names
end

local function convertLimbEntry(
	context: Context,
	legacyCategory: string,
	rule: LimbCategoryRule,
	entry: roblox.Instance
)
	local rules = context.rules
	local key = toKebab(entry.Name)
	local row = newEntryRow(context, legacyCategory, entry)
	local limbItemIds: { [string]: string } = {}
	local mountAnchorNames = getMountAnchorNames(rules)
	for _, limb in rules.Limbs do
		local path = `{legacyCategory}/{entry.Name}/{limb.Name}`
		local limbModel = entry:FindFirstChild(limb.Name)
		if limbModel == nil then
			note(context, `{path}: the suit has no such limb`)
			continue
		end
		local attributes = getItemAttributes(entry.Name, row.Rarity)
		local pieces: { rojo.ModelNode } = {}
		local isShown = false
		for _, partName in limb.Parts do
			local piece = readPiece(context, `{path}/{partName}`, partName, limbModel:FindFirstChild(partName))
			local baseBodyPart = if limb.HasBase then getRigPart(context, partName) else nil
			if limb.HasBase and not baseBodyPart then
				fail(context, legacyCategory, entry.Name, `the rig has no "{partName}" to paint under "{limb.Name}"`)
				continue
			end
			if #piece.Parts == 0 and not baseBodyPart then
				continue
			end
			isShown = isShown or #piece.Parts > 0
			addMarkers(row, attributes, piece.Markers)
			table.insert(
				pieces,
				newPieceNode(
					context,
					`{path}/{partName}`,
					getRojoId(context, rule.Group, limb.Category, key, if #limb.Parts > 1 then partName else nil),
					piece,
					partName,
					rule.TextureGroups,
					baseBodyPart,
					mountAnchorNames
				)
			)
		end
		for _, child in getSortedChildren(limbModel, "Model") do
			if table.find(limb.Parts, child.Name) == nil then
				fail(context, legacyCategory, entry.Name, `"{limb.Name}/{child.Name}" isn't a body part of that limb`)
			end
		end
		if not isShown then
			-- nothing but the stand-ins, the bare limb of the game covers it
			note(context, `{path}: nothing to show, no item written`)
			continue
		end
		local id = writeItem(context, rule.Group, limb.Category, key, newItemNode(pieces, attributes, limb.Tags))
		limbItemIds[limb.Name] = id
		table.insert(row.ItemIds, id)
	end
	row.LimbItemIds = limbItemIds
	table.insert(context.entries, row)
end

local function convertPiecesEntry(
	context: Context,
	legacyCategory: string,
	rule: PiecesCategoryRule,
	entry: roblox.Instance
)
	local key = toKebab(entry.Name)
	local row = newEntryRow(context, legacyCategory, entry)
	local attributes = getItemAttributes(entry.Name, row.Rarity)
	local models = getSortedChildren(entry, "Model")
	local pieces: { rojo.ModelNode } = {}
	for _, model in models do
		local path = `{legacyCategory}/{entry.Name}/{model.Name}`
		if getRigPart(context, model.Name) == nil then
			fail(context, legacyCategory, entry.Name, `"{model.Name}" isn't a body part of the rig`)
			continue
		end
		local piece = readPiece(context, path, model.Name, model)
		if #piece.Parts == 0 then
			note(context, `{path}: nothing to show, piece dropped`)
			continue
		end
		if piece.StandIn == nil then
			fail(context, legacyCategory, entry.Name, `"{model.Name}" has no "{context.rules.StandInName}"`)
			continue
		end
		addMarkers(row, attributes, piece.Markers)
		table.insert(
			pieces,
			newPieceNode(
				context,
				path,
				getRojoId(context, rule.Group, rule.Category, key, if #models > 1 then model.Name else nil),
				piece,
				model.Name,
				rule.TextureGroups,
				nil,
				{}
			)
		)
	end
	if #pieces > 0 then
		table.insert(
			row.ItemIds,
			writeItem(context, rule.Group, rule.Category, key, newItemNode(pieces, attributes, {}))
		)
	else
		fail(context, legacyCategory, entry.Name, "no piece could be converted")
	end
	table.insert(context.entries, row)
end

local function convertMountEntry(
	context: Context,
	legacyCategory: string,
	rule: MountCategoryRule,
	entry: roblox.Instance
)
	local key = toKebab(entry.Name)
	local path = `{legacyCategory}/{entry.Name}`
	local row = newEntryRow(context, legacyCategory, entry)
	local attributes = getItemAttributes(entry.Name, row.Rarity)
	local piece = readPiece(context, path, entry.Name, entry)
	if piece.StandIn == nil or #piece.Parts == 0 then
		fail(context, legacyCategory, entry.Name, `it needs a "{context.rules.StandInName}" and a part that shows`)
	else
		addMarkers(row, attributes, piece.Markers)
		-- the legacy game turned the attachment twice before it placed the stand-in on it, the two turns cancel out
		local pieceNode = newPieceNode(
			context,
			path,
			getRojoId(context, rule.Group, rule.Category, key),
			piece,
			rule.Anchor,
			rule.TextureGroups,
			nil,
			{}
		)
		table.insert(
			row.ItemIds,
			writeItem(context, rule.Group, rule.Category, key, newItemNode({ pieceNode }, attributes, {}))
		)
	end
	table.insert(context.entries, row)
end

local function convertFaceEntry(
	context: Context,
	legacyCategory: string,
	rule: FaceCategoryRule,
	entry: roblox.Instance
)
	local row = newEntryRow(context, legacyCategory, entry)
	local name = entry.Name
	local keyName = if name:sub(-#rule.NameSuffix) == rule.NameSuffix then name:sub(1, -#rule.NameSuffix - 1) else name
	local key = toKebab(keyName)
	local pieceName = rule.PieceName
	local pieceModel = if pieceName then entry:FindFirstChild(pieceName) else nil
	local standIn = pieceModel and pieceModel:FindFirstChild(context.rules.StandInName)
	-- an entry that's the head itself holds its picture
	local holder = if pieceName then standIn else entry
	local decal = holder and holder:FindFirstChildOfClass("Decal")
	local assetId = decal and getAssetId(read(decal, "TextureContent"))
	local imagePath = assetId and context.imagePaths[assetId]
	if decal == nil or assetId == nil then
		fail(context, legacyCategory, name, "no decal with an image")
	elseif imagePath == nil then
		fail(context, legacyCategory, name, `image {assetId} has no file in "{IMAGE_TABLE_PATH}"`)
	elseif imagePath:match("([^/]+)%.%w+$") ~= key then
		-- the game finds the image of a face by the key of its id
		fail(context, legacyCategory, name, `its image is "{imagePath}", which isn't named "{key}"`)
	else
		local id = getItemId(rule.Group, rule.Category, key)
		local color = read(decal, "Color3")
		table.insert(context.faces, {
			Id = id,
			Slot = rule.Slot,
			Key = key,
			Name = name,
			-- a face item is its image
			Image = imagePath,
			LegacyAssetId = assert(tonumber(assetId), `"{assetId}" isn't a number`),
			Color = { color.R, color.G, color.B },
			TextureGroups = rule.TextureGroups,
		})
		table.insert(row.ItemIds, id)
	end
	table.insert(context.entries, row)
end

local function getNodeAttribute(properties: rojo.NodeProperties?, name: string): string?
	local attributes = properties and properties.Attributes
	local value = attributes and attributes.Attributes[name]
	local stringValue = value and value.String
	return if type(stringValue) == "string" then stringValue else nil
end

local function toCFrame(value: rojo.PropertyValue?): CFrameValue
	if type(value) ~= "table" then
		return CFrame.identity
	end
	local cframe = (value :: any).CFrame
	local p, o = cframe.position, cframe.orientation
	return CFrame.new(p[1], p[2], p[3], o[1][1], o[1][2], o[1][3], o[2][1], o[2][2], o[2][3], o[3][1], o[3][2], o[3][3])
end

local function toVector3(value: rojo.PropertyValue?): Vector3Value?
	if type(value) ~= "table" then
		return nil
	end
	local vector = (value :: any).Vector3
	return Vector3.new(vector[1], vector[2], vector[3])
end

local function getNodeAssetId(properties: rojo.NodeProperties?): string?
	local content = properties and properties.MeshContent
	local uri = if type(content) == "table" and type((content :: any).Content) == "table"
		then (content :: any).Content.Uri
		else nil
	return if type(uri) == "string" then uri:match("(%d+)%s*$") else nil
end

-- where a borrowed item differs from the legacy entry it stands for. only a part with a mesh can be matched up, the
-- mesh is what says which part of the one is which part of the other
local function compareBorrowed(context: Context, path: string, piece: Piece, item: rojo.ModelJSON)
	type Shown = { MeshId: string, Size: Vector3Value?, Scale: Vector3Value?, Offset: CFrameValue }
	local shown: { Shown } = {}
	local function addShown(properties: rojo.NodeProperties?, children: { rojo.ModelNode }, offset: CFrameValue)
		local meshId = getNodeAssetId(properties)
		local scale: Vector3Value? = nil
		for _, child in children do
			local meshProperties = child.Properties
			if child.ClassName == "SpecialMesh" and meshProperties and getNodeAssetId(meshProperties) then
				meshId = getNodeAssetId(meshProperties)
				scale = toVector3(meshProperties.Scale) or Vector3.one
			end
		end
		if meshId then
			table.insert(shown, {
				MeshId = meshId,
				Size = if scale or properties == nil then nil else toVector3(properties.Size),
				Scale = scale,
				Offset = offset,
			})
		end
	end
	local function getAnchorCFrame(children: { rojo.ModelNode }): CFrameValue
		for _, child in children do
			if child.ClassName == "Attachment" then
				return toCFrame(child.Properties and child.Properties.CFrame)
			end
		end
		return CFrame.identity
	end
	local itemChildren: { rojo.ModelNode } = item.Children or {}
	if item.ClassName == "Model" then
		local rootAnchor: CFrameValue = CFrame.identity
		for _, child in itemChildren do
			if child.Name == ROOT_NAME then
				rootAnchor = getAnchorCFrame(child.Children or {})
			end
		end
		for _, child in itemChildren do
			if child.Name ~= ROOT_NAME then
				local partCFrame = toCFrame(child.Properties and child.Properties.CFrame)
				addShown(child.Properties, child.Children or {}, rootAnchor:Inverse() * partCFrame)
			end
		end
	else
		addShown(item.Properties, itemChildren, getAnchorCFrame(itemChildren):Inverse())
	end

	local standIn = assert(piece.StandIn, `{path} has no stand-in to measure from`)
	local matchCount = 0
	for _, part in piece.Parts do
		local meshId = getAssetId(if part.ClassName == "MeshPart" then read(part, "MeshContent") else nil)
		local legacySize: Vector3Value = read(part, "Size")
		local nativeSize: Vector3Value? = if part.ClassName == "MeshPart" then read(part, "InitialSize") else nil
		if meshId == nil then
			continue
		end
		for _, other in shown do
			if other.MeshId ~= meshId then
				continue
			end
			matchCount += 1
			-- a mesh under a plain part is sized by its scale, which only says something next to the size it came with
			local size: Vector3Value? = other.Size or if nativeSize then nativeSize * other.Scale else nil
			if size == nil then
				break
			end
			local ratio = (size.X / legacySize.X + size.Y / legacySize.Y + size.Z / legacySize.Z) / 3
			local legacyOffset: CFrameValue = read(standIn, "CFrame"):ToObjectSpace(read(part, "CFrame"))
			local drift = (other.Offset.Position - legacyOffset.Position * ratio).Magnitude
			note(
				context,
				string.format("%s: borrowed, %.3fx the legacy size, %.3f studs off once scaled", path, ratio, drift)
			)
			break
		end
	end
	if matchCount == 0 then
		note(context, `{path}: borrowed, no mesh of it could be matched up to compare ({#piece.Parts} legacy parts)`)
	end
end

local function readBorrowable(group: string, category: string): { [string]: { Key: string, Item: rojo.ModelJSON } }
	local items: { [string]: { Key: string, Item: rojo.ModelJSON } } = {}
	local categoryPath = `{BORROW_PATH}/{group}/{category}`
	assert(fs.isDir(categoryPath), `"{categoryPath}" isn't there to borrow from`)
	for _, fileName in fs.readDir(categoryPath) do
		local key = fileName:match("^(.*)%.model%.json$")
		if key == nil then
			continue
		end
		local item: rojo.ModelJSON = serde.decode("json", fs.readFile(`{categoryPath}/{fileName}`))
		local name = getNodeAttribute(item.Properties, "Name")
		if name then
			items[name:lower()] = { Key = key, Item = item }
		end
	end
	return items
end

local function convertBorrowEntry(
	context: Context,
	legacyCategory: string,
	rule: BorrowCategoryRule,
	entry: roblox.Instance,
	borrowable: { [string]: { Key: string, Item: rojo.ModelJSON } }
)
	local row = newEntryRow(context, legacyCategory, entry)
	local path = `{legacyCategory}/{entry.Name}`
	-- the two libraries don't agree on capitals
	local match = borrowable[entry.Name:lower()]
	if match == nil then
		fail(
			context,
			legacyCategory,
			entry.Name,
			`nothing of "{BORROW_PATH}/{rule.Group}/{rule.Category}" has its name`
		)
	else
		row.IsBorrowed = true
		table.insert(row.ItemIds, getItemId(rule.Group, rule.Category, match.Key))
		table.insert(context.borrows, table.concat({ rule.Group, rule.Category, match.Key }, PATH_DELIMITER))
		local attributes: { [string]: string | boolean } = {}
		for _, model in getSortedChildren(entry, "Model") do
			local piece = readPiece(context, `{path}/{model.Name}`, model.Name, model)
			addMarkers(row, attributes, piece.Markers)
			if piece.StandIn then
				compareBorrowed(context, path, piece, match.Item)
			end
		end
		if row.ShaveHead or row.ShaveBeard then
			note(context, `{path}: borrowed, its markers are only in the entry table`)
		end
	end
	table.insert(context.entries, row)
end

-- a limb that wears no suit still gets painted, so every limb group that has a base also has an item that is only that
local function convertBareLimbs(context: Context): EntryRow?
	local rules = context.rules
	local key, name = rules.BareLimbKey, rules.BareLimbName
	if key == nil or name == nil then
		return nil
	end
	local group: string? = nil
	for _, rule in rules.Categories do
		if rule.Kind == "Limb" then
			group = rule.Group
		end
	end
	local limbGroup = assert(group, "a bare limb needs a limb category")
	local limbItemIds: { [string]: string } = {}
	local row: EntryRow = {
		LegacyCategory = "",
		LegacyName = name,
		Rarity = assert(rules.Rarities[1], "a game needs a rarity"),
		IsStarter = true,
		IsBorrowed = false,
		ItemIds = {},
		LimbItemIds = limbItemIds,
	}
	for _, limb in rules.Limbs do
		if not limb.HasBase then
			continue
		end
		local pieces: { rojo.ModelNode } = {}
		for _, partName in limb.Parts do
			local bodyPart = assert(getRigPart(context, partName), `the rig has no "{partName}"`)
			table.insert(
				pieces,
				newPieceNode(
					context,
					`{name}/{limb.Name}/{partName}`,
					getRojoId(context, limbGroup, limb.Category, key, partName),
					{ Name = partName, StandIn = nil, Parts = {}, Markers = {} },
					partName,
					{},
					bodyPart,
					{}
				)
			)
		end
		local id = writeItem(
			context,
			limbGroup,
			limb.Category,
			key,
			newItemNode(pieces, getItemAttributes(name, row.Rarity), limb.Tags)
		)
		table.insert(row.ItemIds, id)
		limbItemIds[limb.Name] = id
	end
	return row
end

local function newVector(values: { number }): Vector3Value
	return Vector3.new(values[1], values[2], values[3])
end

local function toVectorValue(vector: Vector3Value): rojo.StrictPropertyValue
	return { Vector3 = { round(vector.X), round(vector.Y), round(vector.Z) } }
end

local function roundCFrame(cframe: CFrameValue): CFrameValue
	local components = { cframe:GetComponents() }
	for index, value in components do
		components[index] = round(value)
	end
	return CFrame.new(table.unpack(components))
end

local function getBody(context: Context): { [string]: BodyLimbRule }
	return assert(context.rules.Body, `the rules of "{context.game}" don't say which body its catalogue was fitted to`)
end

local function getSegment(limb: BodyLimbRule, partName: string): SegmentRule
	for _, segment in limb.Segments do
		if segment.Part == partName then
			return segment
		end
	end
	error(`the limb has no "{partName}"`)
end

-- where the limb a piece was welded to is, seen from the part that stands there now
local function getOffset(limb: BodyLimbRule, segment: SegmentRule): CFrameValue
	return CFrame.new(newVector(limb.Position) - newVector(segment.Position))
end

-- the part of a limb that's at a height
local function getSegmentIndex(limb: BodyLimbRule, height: number): number
	local index = 1
	while index < #limb.Segments and height < (limb.Segments[index + 1].Top or -math.huge) do
		index += 1
	end
	return index
end

-- why a part draws nothing, nil for one that shows
local function getHiddenReason(part: roblox.Instance): string?
	if read(part, "Transparency") >= 1 then
		return "is invisible"
	end
	for _, child in part:GetChildren() do
		if child:IsA("DataModelMesh") then
			local scale: Vector3Value = read(child, "Scale")
			-- how the legacy game kept "none" on a list of things to wear
			if scale.X == 0 or scale.Y == 0 or scale.Z == 0 then
				return "is scaled to nothing"
			end
		end
	end
	return nil
end

-- what a part draws + where against the middle of its limb, nil for one that draws nothing
local function readShape(context: Context, path: string, part: roblox.Instance, origin: CFrameValue): Shape?
	local reason = getHiddenReason(part)
	if reason then
		note(context, `{path}: "{part.Name}" {reason}, dropped`)
		return nil
	end
	local size: Vector3Value = read(part, "Size")
	local kind: ShapeKind = if part.ClassName == "WedgePart"
		then "Wedge"
		elseif part.ClassName == "Part" and read(part, "Shape").Name == "Block" then "Block"
		else "Carried"
	local meshCount = 0
	for _, child in getSortedChildren(part) do
		if not child:IsA("DataModelMesh") then
			continue
		end
		meshCount += 1
		assert(meshCount == 1, `{path}: "{part.Name}" has two meshes`)
		local meshType: string = if child.ClassName == "SpecialMesh"
			then read(child, "MeshType").Name
			else child.ClassName
		if kind == "Carried" then
			continue
		elseif meshType == "Brick" or meshType == "BlockMesh" then
			kind = "Block"
		elseif meshType == "Wedge" then
			kind = "Wedge"
		elseif meshType == "CylinderMesh" then
			kind = "Cylinder"
		else
			kind = "Carried"
			continue
		end
		-- a mesh of these kinds fills its part, its scale is how much bigger than the part it's drawn
		assert(read(child, "Offset") == Vector3.zero, `{path}: the mesh of "{part.Name}" is drawn off its part`)
		size *= read(child, "Scale")
	end
	return {
		Path = `{path}/{part.Name}`,
		Part = part,
		Kind = kind,
		Size = size,
		CFrame = origin:ToObjectSpace(read(part, "CFrame")),
	}
end

-- everything of a legacy model that shows, but for its stand-in + the parts a rule has another use for
local function readShapes(
	context: Context,
	path: string,
	model: roblox.Instance,
	standIn: roblox.Instance,
	skippedNames: { [string]: string }
): { Shape }
	if getHiddenReason(standIn) == nil then
		note(context, `{path}: the stand-in showed in the legacy game, it still isn't worn`)
	end
	for _, decal in getSortedChildren(standIn, "Decal") do
		local assetId = getAssetId(read(decal, "TextureContent"))
		if assetId then
			note(context, `{path}: the stand-in holds the decal {assetId}, nothing of a stand-in is carried over`)
		end
	end
	local origin: CFrameValue = read(standIn, "CFrame")
	local shapes: { Shape } = {}
	for _, child in getSortedChildren(model) do
		if not child:IsA("BasePart") or child.Name == standIn.Name or skippedNames[child.Name] then
			continue
		end
		local shape = readShape(context, path, child, origin)
		if shape then
			table.insert(shapes, shape)
		end
	end
	return shapes
end

-- a shape as a part of a piece, placed against the root of that piece
local function newShapeNode(
	context: Context,
	shape: Shape,
	name: string,
	cframe: CFrameValue,
	textureGroup: string?
): rojo.ModelNode
	local part = shape.Part
	local properties = newSurface(context, shape.Path, part, textureGroup)
	if not getIfIdentity(cframe) then
		properties.CFrame = toCFrameValue(cframe)
	end
	local className = "Part"
	local children: { rojo.ModelNode } = {}
	if shape.Kind == "Carried" then
		assert(
			part.ClassName == "Part" or part.ClassName == "WedgePart",
			`{shape.Path} is a {part.ClassName}, which can't be written as a model file`
		)
		className = part.ClassName
		properties.Size = rojoValue.toValue(read(part, "Size"))
		if className == "Part" and read(part, "Shape").Name ~= "Block" then
			properties.Shape = rojoValue.toValue(read(part, "Shape"), "Enum")
		end
		for _, child in getSortedChildren(part, "SpecialMesh") do
			table.insert(children, newMeshNode(context, child))
		end
	else
		properties.Size = toVectorValue(shape.Size)
		if shape.Kind == "Wedge" then
			className = "WedgePart"
		elseif shape.Kind == "Cylinder" then
			-- the mesh fills its part the way a cylinder that's wider one way than the other needs
			table.insert(children, { Name = MESH_NAME, ClassName = "CylinderMesh" })
		end
	end
	return {
		Name = name,
		ClassName = className,
		Properties = properties,
		Children = if #children > 0 then children else nil,
	}
end

-- a union names the asset that holds its geometry, there's nothing of it to write down. it's taken out of the place
-- as it is + names its asset the way every union of lib does
local function newUnionOutput(
	context: Context,
	shape: Shape,
	name: string,
	cframe: CFrameValue,
	textureGroup: string?
): Output
	local union = shape.Part:Clone()
	for _, child in union:GetChildren() do
		child:Destroy()
	end
	-- lune's Instance typedef leaves out dynamic property indexing
	local properties = union :: any
	union.Name = name
	properties.CFrame = roundCFrame(cframe)
	properties.Anchored = false
	local defaultColor = if textureGroup then context.defaultColors[textureGroup] else nil
	if defaultColor then
		properties.Color = defaultColor
	end
	if textureGroup then
		if not read(union, "UsePartColor") then
			-- one that keeps the colors of the parts it was made of would never show the color it's given
			note(context, `{shape.Path}: the union kept the colors of its parts, it takes the one of its channel now`)
			properties.UsePartColor = true
		end
		union:SetAttribute(TEXTURE_GROUP_ATTRIBUTE, textureGroup)
	end
	local contents = Place.serialize(union)
	return { path = name .. UNION_EXTENSION, contents = contents }
end

-- how high a shape reaches from the root part of the body, lowest + highest. the size of what's carried over as it
-- is isn't known here, it counts as its middle
local function getHeights(limb: BodyLimbRule, shape: Shape): (number, number)
	local _, y, _, _, _, _, upX, upY, upZ = shape.CFrame:GetComponents()
	local middle = limb.Position[2] + y
	local size = shape.Size
	if shape.Kind == "Carried" then
		return middle, middle
	elseif shape.Kind == "Wedge" then
		local low, high = math.huge, -math.huge
		for _, corner in WEDGE_CORNERS do
			local height = middle + (upX * corner[1] * size.X + upY * corner[2] * size.Y + upZ * corner[3] * size.Z) / 2
			low, high = math.min(low, height), math.max(high, height)
		end
		return low, high
	end
	local reach = if shape.Kind == "Cylinder"
		then math.abs(upY) * size.Y / 2 + math.sqrt((upX * size.X / 2) ^ 2 + (upZ * size.Z / 2) ^ 2)
		else (math.abs(upX) * size.X + math.abs(upY) * size.Y + math.abs(upZ) * size.Z) / 2
	return middle - reach, middle + reach
end

-- the joints of a limb something that reaches from one height to another lies across, from the top down
local function getCrossed(limb: BodyLimbRule, low: number, high: number): { Joint }
	local crossed: { Joint } = {}
	for _, segment in limb.Segments do
		local name, top = segment.Joint, segment.Top
		if name and top and top > low + JOINT_TOLERANCE and top < high - JOINT_TOLERANCE then
			table.insert(crossed, { Name = name, Height = top })
		end
	end
	return crossed
end

-- a brick that stands square to a joint comes apart on the plane of it into two bricks that share that face, a
-- cylinder that stands on one into two cylinders. nothing else leaves whole parts behind
local function cut(limb: BodyLimbRule, shape: Shape, crossed: { Joint }): { Shape }?
	local _, y, _, _, _, _, upX, upY, upZ = shape.CFrame:GetComponents()
	local axis: number? = nil
	for index, up in { upX, upY, upZ } do
		local isSquare = math.abs(math.abs(up) - 1) < AXIS_TOLERANCE
		if isSquare and (shape.Kind == "Block" or (shape.Kind == "Cylinder" and index == 2)) then
			axis = index
		end
	end
	if axis == nil then
		return nil
	end
	local sizes = { shape.Size.X, shape.Size.Y, shape.Size.Z }
	local middle = limb.Position[2] + y
	local heights = { middle + sizes[axis] / 2 }
	for _, joint in crossed do
		table.insert(heights, joint.Height)
	end
	table.insert(heights, middle - sizes[axis] / 2)
	local shapes: { Shape } = {}
	for index = 1, #heights - 1 do
		local high, low = heights[index], heights[index + 1]
		local cutSizes = table.clone(sizes)
		cutSizes[axis] = high - low
		table.insert(shapes, {
			Path = shape.Path,
			Part = shape.Part,
			Kind = shape.Kind,
			Size = newVector(cutSizes),
			CFrame = shape.CFrame + Vector3.new(0, (high + low) / 2 - middle, 0),
		})
	end
	return shapes
end

-- how much of a shape each part of a limb holds, as shares of 1
local function getShares(limb: BodyLimbRule, shape: Shape): { number }
	local _, y, _, _, _, _, upX, upY, upZ = shape.CFrame:GetComponents()
	local size = shape.Size
	local counts: { number } = table.create(#limb.Segments, 0)
	local total = 0
	for xIndex = 1, SAMPLE_COUNT do
		local u = (xIndex - 0.5) / SAMPLE_COUNT - 0.5
		for yIndex = 1, SAMPLE_COUNT do
			local v = (yIndex - 0.5) / SAMPLE_COUNT - 0.5
			for zIndex = 1, SAMPLE_COUNT do
				local w = (zIndex - 0.5) / SAMPLE_COUNT - 0.5
				local isInside = if shape.Kind == "Wedge"
					then v <= w
					elseif shape.Kind == "Cylinder" then u * u + w * w <= 0.25
					else true
				if isInside then
					local height = limb.Position[2] + y + upX * u * size.X + upY * v * size.Y + upZ * w * size.Z
					local index = getSegmentIndex(limb, height)
					counts[index] += 1
					total += 1
				end
			end
		end
	end
	for index, count in counts do
		counts[index] = count / total
	end
	return counts
end

local function describe(shape: Shape): string
	local size = shape.Size
	return string.format(
		'"%s" (%s %g x %g x %g)',
		shape.Part.Name,
		SHAPE_NAMES[shape.Kind],
		round(size.X),
		round(size.Y),
		round(size.Z)
	)
end

-- a part only studio can cut is named after its piece + how many of those came before it, which stays the same from one
-- run to the next
local function getCutId(context: Context, piecePath: string): string
	local names: { string } = string.split(piecePath, PATH_DELIMITER)
	local key = `{toKebab(names[#names - 1])}-{toKebab(names[#names])}`
	local count = (context.cutCounts[key] or 0) + 1
	context.cutCounts[key] = count
	return `{key}-{count}`
end

local function readCut(context: Context, fileName: string): roblox.Instance
	local path = `{context.libraryPath}{CUTS_SUFFIX}/{fileName}`
	assert(fs.isFile(path), `"{path}" is listed among the pieces studio cut, it isn't there`)
	local union = roblox.deserializeModel(fs.readFile(path))[1]
	assert(union and union.ClassName == "UnionOperation", `"{path}" doesn't hold a union`)
	return union
end

-- the parts of a limb a shape ends up on. one that lies across a joint is cut on it when that leaves whole parts, is
-- worn as the pieces studio cut it into, or goes whole to the part that holds most of it + is listed for studio to cut
local function split(context: Context, limb: BodyLimbRule, shape: Shape): { { Shape: Shape, Index: number } }
	local low, high = getHeights(limb, shape)
	local crossed = getCrossed(limb, low, high)
	if #crossed == 0 then
		return { { Shape = shape, Index = getSegmentIndex(limb, (low + high) / 2) } }
	end
	local jointNames: { string } = {}
	for _, joint in crossed do
		table.insert(jointNames, joint.Name)
	end
	-- two parts of a piece can share a name + a size, where it sat on the limb tells them apart
	local position: Vector3Value = shape.CFrame.Position
	local piecePath = shape.Path:match("^(.*)/[^/]+$") or shape.Path
	local part =
		string.format("%s %s at %.3f, %.3f, %.3f", piecePath, describe(shape), position.X, position.Y, position.Z)
	local across = `{part}: across the {table.concat(jointNames, " + ")}`
	local halves = cut(limb, shape, crossed)
	if halves then
		local placed: { { Shape: Shape, Index: number } } = {}
		local parts: { string } = {}
		for _, half in halves do
			local halfLow, halfHigh = getHeights(limb, half)
			local index = getSegmentIndex(limb, (halfLow + halfHigh) / 2)
			table.insert(placed, { Shape = half, Index = index })
			table.insert(parts, string.format("%s %.3f", limb.Segments[index].Part, halfHigh - halfLow))
		end
		table.insert(context.joints, `{across}, cut: {table.concat(parts, " + ")}`)
		return placed
	end
	-- what's left is for studio to cut. the pieces it cut before are worn in place of the part
	local id = getCutId(context, piecePath)
	local heights: { number } = {}
	for _, joint in crossed do
		table.insert(heights, joint.Height - limb.Position[2])
	end
	table.insert(context.cutJobs, { Id = id, Part = part, Shape = shape, Heights = heights })
	local row = context.cuts[id]
	if row then
		-- a catalogue that changed since studio cut it would wear the pieces of another part
		assert(row.Part == part, `the pieces of "{id}" were cut from {row.Part}, it's {part} now: cut them again`)
		assert(#row.Pieces == #crossed + 1, `"{id}" lies across {#crossed} joint(s), it was cut into {#row.Pieces}`)
		local placed: { { Shape: Shape, Index: number } } = {}
		local parts: { string } = {}
		for _, fileName in row.Pieces do
			local union = readCut(context, fileName)
			union.Name = shape.Part.Name
			local piece: Shape = {
				Path = shape.Path,
				Part = union,
				Kind = "Carried",
				Size = read(union, "Size"),
				CFrame = read(union, "CFrame"),
			}
			local index = getSegmentIndex(limb, limb.Position[2] + piece.CFrame.Position.Y)
			table.insert(placed, { Shape = piece, Index = index })
			table.insert(parts, limb.Segments[index].Part)
		end
		table.insert(context.joints, `{across}, cut by studio: {table.concat(parts, " + ")}`)
		return placed
	end
	local shares = getShares(limb, shape)
	local best = 1
	for index, share in shares do
		if share > shares[best] then
			best = index
		end
	end
	table.insert(
		context.joints,
		string.format(
			"%s, whole on %s which holds %d%% of it: TO CUT IN STUDIO (--cut-jobs)",
			across,
			limb.Segments[best].Part,
			math.round(shares[best] * 100)
		)
	)
	return { { Shape = shape, Index = best } }
end

-- an item that holds a union can't be one text file, it's a folder of its parts the way the library of SHL2 keeps
-- such an item
local function writeItemFolder(
	context: Context,
	group: string,
	category: string,
	key: string,
	item: rojo.ModelJSON,
	files: { Output }
): string
	local id = getItemId(group, category, key)
	local libraryCategory = `{group}/{category}`
	local itemPath = `{context.libraryPath}/{libraryCategory}/{key}`
	context.itemCounts[libraryCategory] = (context.itemCounts[libraryCategory] or 0) + 1
	local meta: rojo.MetaJSON = { className = item.ClassName, properties = item.Properties }
	table.insert(context.outputs, {
		path = `{itemPath}/init.meta.json`,
		contents = rojoValue.encode(meta :: any),
	})
	local children: { rojo.ModelNode } = item.Children or {}
	for _, child in children do
		local model: rojo.ModelJSON = {
			ClassName = child.ClassName,
			Properties = child.Properties,
			Children = child.Children,
		}
		table.insert(context.outputs, {
			path = `{itemPath}/{child.Name}.model.json`,
			contents = rojoValue.encode(model :: any),
		})
	end
	for _, file in files do
		table.insert(context.outputs, { path = `{itemPath}/{file.path}`, contents = file.contents })
	end
	return id
end

-- the item of a limb that wears a union: a folder of its pieces, where a piece that holds one is a folder of its parts
-- in turn + every other piece stays the one text file it would have been a part of
local function writeLimbFolder(
	context: Context,
	group: string,
	category: string,
	key: string,
	item: rojo.ModelJSON,
	files: { [string]: { Output } }
): string
	local id = getItemId(group, category, key)
	local libraryCategory = `{group}/{category}`
	local itemPath = `{context.libraryPath}/{libraryCategory}/{key}`
	context.itemCounts[libraryCategory] = (context.itemCounts[libraryCategory] or 0) + 1
	-- an item of one piece is that piece, there'd be no folder of pieces to put the union of one into
	assert(item.ClassName == "Folder", `{id} is a single piece, a union of it has nowhere to go`)
	local meta: rojo.MetaJSON = { className = item.ClassName, properties = item.Properties }
	table.insert(context.outputs, {
		path = `{itemPath}/init.meta.json`,
		contents = rojoValue.encode(meta :: any),
	})
	local pieces: { rojo.ModelNode } = item.Children or {}
	for _, piece in pieces do
		local pieceFiles = files[piece.Name]
		if pieceFiles == nil then
			local model: rojo.ModelJSON = {
				ClassName = piece.ClassName,
				Properties = piece.Properties,
				Children = piece.Children,
			}
			table.insert(context.outputs, {
				path = `{itemPath}/{piece.Name}.model.json`,
				contents = rojoValue.encode(model :: any),
			})
			continue
		end
		local piecePath = `{itemPath}/{piece.Name}`
		local pieceMeta: rojo.MetaJSON = { className = piece.ClassName, properties = piece.Properties }
		table.insert(context.outputs, {
			path = `{piecePath}/init.meta.json`,
			contents = rojoValue.encode(pieceMeta :: any),
		})
		local children: { rojo.ModelNode } = piece.Children or {}
		for _, child in children do
			local model: rojo.ModelJSON = {
				ClassName = child.ClassName,
				Properties = child.Properties,
				Children = child.Children,
			}
			table.insert(context.outputs, {
				path = `{piecePath}/{child.Name}.model.json`,
				contents = rojoValue.encode(model :: any),
			})
		end
		for _, file in pieceFiles do
			table.insert(context.outputs, { path = `{piecePath}/{file.path}`, contents = file.contents })
		end
	end
	return id
end

-- the size a stand-in stands for: a brick mesh makes it as big as what the piece sits on
local function getStandInSize(standIn: roblox.Instance): Vector3Value
	local size: Vector3Value = read(standIn, "Size")
	for _, child in standIn:GetChildren() do
		local isBrick = child.ClassName == "BlockMesh"
			or (child.ClassName == "SpecialMesh" and read(child, "MeshType").Name == "Brick")
		if isBrick then
			size *= read(child, "Scale")
		end
	end
	return size
end

-- a save names a piece by a value the piece carries. that's the name of its entry, but for where a piece was copied
-- + the value left as it was
local function noteSaveName(context: Context, path: string, entry: roblox.Instance, model: roblox.Instance)
	local name = context.rules.SaveNameName
	local value = if name then model:FindFirstChild(name) else nil
	if value and value.ClassName == "StringValue" and read(value, "Value") ~= entry.Name then
		note(context, `{path}: a save calls it "{read(value, "Value")}", the name of another entry`)
	end
end

-- a hat says whether the hair still shows under it, one that says no leaves no room for any
local function addHairMarker(
	context: Context,
	row: EntryRow,
	attributes: { [string]: string | boolean },
	model: roblox.Instance
)
	local name = context.rules.HairShownName
	if name == nil then
		return
	end
	for _, child in model:GetChildren() do
		if child.Name == name and child.ClassName == "BoolValue" and read(child, "Value") == false then
			attributes.ShaveHead = true
			row.ShaveHead = true
		end
	end
end

local function convertSplitEntry(
	context: Context,
	legacyCategory: string,
	rule: SplitCategoryRule,
	entry: roblox.Instance
)
	local rules = context.rules
	local body = getBody(context)
	local key = toKebab(entry.Name)
	local row = newEntryRow(context, legacyCategory, entry)
	local limbItemIds: { [string]: string } = {}
	for _, modelRule in rule.Models do
		local path = `{legacyCategory}/{entry.Name}/{modelRule.Name}`
		local model = entry:FindFirstChild(modelRule.Name)
		local standIn = model and model:FindFirstChild(rules.StandInName)
		if model == nil or standIn == nil then
			fail(context, legacyCategory, entry.Name, `no "{modelRule.Name}" with a "{rules.StandInName}"`)
			continue
		end
		noteSaveName(context, path, entry, model)
		local limb = assert(body[modelRule.Limb], `the body has no "{modelRule.Limb}"`)
		local origin: CFrameValue = read(standIn, "CFrame")
		local nodes: { { rojo.ModelNode } } = {}
		-- the pieces studio cut, by the part of the limb they're worn on: a union can't be written into a model file
		local files: { [string]: { Output } } = {}
		local isAnyFile = false
		local getNames: { (name: string) -> string } = {}
		for index in limb.Segments do
			nodes[index] = {}
			getNames[index] = newNameGetter()
		end

		local shapes = readShapes(context, path, model, standIn, rule.Mounts)
		for _, shape in shapes do
			local textureGroup = rule.TextureGroups[shape.Part.Name]
			if textureGroup == nil then
				note(context, `{path}: "{shape.Part.Name}" was never recolored, it keeps its color`)
			end
			if shape.Kind == "Carried" then
				note(context, `{path}: the size of "{shape.Part.Name}" isn't known, it's worn where its middle is`)
			end
			for _, placed in split(context, limb, shape) do
				local index = placed.Index
				local name = getNames[index](toKebab(shape.Part.Name))
				local cframe: CFrameValue = getOffset(limb, limb.Segments[index]) * placed.Shape.CFrame
				if placed.Shape.Part.ClassName == "UnionOperation" then
					local pieceName = toKebab(limb.Segments[index].Part)
					local pieceFiles = files[pieceName] or {}
					files[pieceName] = pieceFiles
					table.insert(pieceFiles, newUnionOutput(context, placed.Shape, name, cframe, textureGroup))
					isAnyFile = true
				else
					table.insert(nodes[index], newShapeNode(context, placed.Shape, name, cframe, textureGroup))
				end
			end
		end
		-- what another item sits on stays a part of its own, so the attachment isn't taken for the one of the root
		for _, child in getSortedChildren(model) do
			local mountName = rule.Mounts[child.Name]
			if mountName == nil or not child:IsA("BasePart") then
				continue
			end
			local offset: CFrameValue = origin:ToObjectSpace(read(child, "CFrame"))
			local index = getSegmentIndex(limb, limb.Position[2] + offset.Position.Y)
			local cframe: CFrameValue = getOffset(limb, limb.Segments[index]) * offset
			local properties: rojo.NodeProperties = {
				Size = toVectorValue(getStandInSize(child)),
				Transparency = { Float32 = 1 },
			}
			if not getIfIdentity(cframe) then
				properties.CFrame = toCFrameValue(cframe)
			end
			table.insert(nodes[index], {
				Name = getNames[index](toKebab(child.Name)),
				ClassName = "Part",
				Properties = properties,
				Children = { { Name = mountName, ClassName = "Attachment" } },
			})
		end
		if #shapes == 0 then
			note(context, `{path}: nothing to show, no item written`)
			continue
		end

		-- every part of the limb gets its piece, also one the shell leaves bare: the limb under it was hidden whole
		local pieces: { rojo.ModelNode } = {}
		for index, segment in limb.Segments do
			local rojoId = getRojoId(
				context,
				rule.Group,
				modelRule.Category,
				key,
				if #limb.Segments > 1 then segment.Part else nil
			)
			local children: { rojo.ModelNode } =
				{ newRootNode(rojoId, toVectorValue(newVector(segment.Size)), segment.Part) }
			table.move(nodes[index], 1, #nodes[index], 2, children)
			table.insert(pieces, newModelNode(toKebab(segment.Part), rojoId, children))
		end
		local attributes = getItemAttributes(entry.Name, row.Rarity)
		if rules.IsBodyHidden then
			attributes.IsBodyHidden = true
		end
		local item = newItemNode(pieces, attributes, {})
		local id = if isAnyFile
			then writeLimbFolder(context, rule.Group, modelRule.Category, key, item, files)
			else writeItem(context, rule.Group, modelRule.Category, key, item)
		limbItemIds[modelRule.Name] = id
		table.insert(row.ItemIds, id)
	end
	row.LimbItemIds = limbItemIds
	table.insert(context.entries, row)
end

-- a piece that stays in one piece, as the single item of its entry
local function writeWorn(
	context: Context,
	legacyCategory: string,
	rule: WornCategoryRule,
	entry: roblox.Instance,
	row: EntryRow,
	model: roblox.Instance,
	standIn: roblox.Instance,
	shapes: { Shape }
)
	local key = toKebab(entry.Name)
	local path = `{legacyCategory}/{entry.Name}`
	local rojoId = getRojoId(context, rule.Group, rule.Category, key)
	-- what sits on a worn attachment is placed against its own stand-in
	local anchorName = rule.Anchor or ""
	local rootSize: Vector3Value = getStandInSize(standIn)
	local offset: CFrameValue = CFrame.identity
	if rule.Anchor == nil then
		-- on the body it stands where it stood on the limb it was welded to
		local places = rule.Places
		local place = assert((places and places[entry.Name]) or rule.Place, `{path} has nowhere to be worn`)
		local limb = assert(getBody(context)[place.Limb], `the body has no "{place.Limb}"`)
		local segment = getSegment(limb, place.Part)
		anchorName = segment.Part
		rootSize = newVector(segment.Size)
		offset = getOffset(limb, segment)
	end

	local children: { rojo.ModelNode } = { newRootNode(rojoId, toVectorValue(rootSize), anchorName) }
	local files: { Output } = {}
	local getName = newNameGetter()
	for _, shape in shapes do
		local textureGroup = rule.TextureGroups[shape.Part.Name]
		if textureGroup == nil then
			note(context, `{path}: "{shape.Part.Name}" was never recolored, it keeps its color`)
		end
		local name = getName(toKebab(shape.Part.Name))
		local cframe: CFrameValue = offset * shape.CFrame
		if shape.Part.ClassName == "UnionOperation" then
			table.insert(files, newUnionOutput(context, shape, name, cframe, textureGroup))
		else
			table.insert(children, newShapeNode(context, shape, name, cframe, textureGroup))
		end
	end
	local attributes = getItemAttributes(entry.Name, row.Rarity)
	addHairMarker(context, row, attributes, model)
	local item = newItemNode({ newModelNode(key, rojoId, children) }, attributes, rule.Tags)
	local id = if #files > 0
		then writeItemFolder(context, rule.Group, rule.Category, key, item, files)
		else writeItem(context, rule.Group, rule.Category, key, item)
	table.insert(row.ItemIds, id)
end

-- the model of an entry that's worn in one piece + what it's placed against
local function getWornModel(
	context: Context,
	legacyCategory: string,
	rule: WornCategoryRule,
	entry: roblox.Instance
): (roblox.Instance?, roblox.Instance?)
	local model = entry:FindFirstChild(rule.PieceName or entry.Name)
	local standIn = model and model:FindFirstChild(context.rules.StandInName)
	if model == nil or standIn == nil then
		fail(context, legacyCategory, entry.Name, `no piece with a "{context.rules.StandInName}"`)
		return nil, nil
	end
	noteSaveName(context, `{legacyCategory}/{entry.Name}`, entry, model)
	return model, standIn
end

-- the legacy game kept "nothing" on its lists as a piece that draws nothing. what names it wears no item
local function addEmpty(context: Context, row: EntryRow)
	note(context, `{row.LegacyCategory}/{row.LegacyName}: nothing of it shows, it stands for wearing nothing`)
	table.insert(context.empties, row)
end

local function convertWornEntry(
	context: Context,
	legacyCategory: string,
	rule: WornCategoryRule,
	entry: roblox.Instance
)
	local model, standIn = getWornModel(context, legacyCategory, rule, entry)
	if model == nil or standIn == nil then
		return
	end
	local row = newEntryRow(context, legacyCategory, entry)
	local shapes = readShapes(context, `{legacyCategory}/{entry.Name}`, model, standIn, {})
	if #shapes == 0 then
		addEmpty(context, row)
		return
	end
	writeWorn(context, legacyCategory, rule, entry, row, model, standIn, shapes)
	table.insert(context.entries, row)
end

-- the items of a category of SHL2's library that are a single mesh, by the id of that mesh
local function readBorrowableMeshes(
	context: Context,
	group: string,
	category: string
): { [string]: { Key: string, Item: rojo.ModelJSON } }
	local items: { [string]: { Key: string, Item: rojo.ModelJSON } } = {}
	local categoryPath = `{BORROW_PATH}/{group}/{category}`
	assert(fs.isDir(categoryPath), `"{categoryPath}" isn't there to borrow from`)
	local fileNames = fs.readDir(categoryPath)
	table.sort(fileNames)
	for _, fileName in fileNames do
		local key = fileName:match("^(.*)%.model%.json$")
		if key == nil then
			continue
		end
		local item: rojo.ModelJSON = serde.decode("json", fs.readFile(`{categoryPath}/{fileName}`))
		local meshId = getNodeAssetId(item.Properties)
		if meshId == nil then
			continue
		end
		local other = items[meshId]
		if other then
			note(context, `{categoryPath}: "{key}" is the mesh of "{other.Key}" again, the first one is borrowed`)
		else
			items[meshId] = { Key = key, Item = item }
		end
	end
	return items
end

-- where a borrowed mesh differs from the legacy part it stands for. the legacy one is a mesh under a part, drawn
-- around the origin the mesh was made with. the borrowed one is a mesh part, drawn around the middle of its box. so
-- how far apart the two are also holds how far off its box the mesh was made, which isn't known here
local function compareBorrowedMesh(context: Context, path: string, shape: Shape, key: string, item: rojo.ModelJSON)
	local size = toVector3(item.Properties and item.Properties.Size)
	local initialSize = toVector3(item.Properties and item.Properties.InitialSize)
	local scale: Vector3Value = Vector3.one
	for _, mesh in getSortedChildren(shape.Part, "SpecialMesh") do
		scale = read(mesh, "Scale")
		if read(mesh, "VertexColor") ~= Vector3.one then
			note(context, `{path}: borrowed, the tint its mesh was drawn with isn't on "{key}"`)
		end
	end
	if size == nil or initialSize == nil then
		note(context, `{path}: borrowed as "{key}", which has no size of its own to compare`)
		return
	end
	local anchor: CFrameValue = CFrame.identity
	local children: { rojo.ModelNode } = item.Children or {}
	for _, child in children do
		if child.ClassName == "Attachment" then
			anchor = toCFrame(child.Properties and child.Properties.CFrame)
		end
	end
	local legacySize: Vector3Value = initialSize * scale
	local drift = (anchor:Inverse().Position - shape.CFrame.Position).Magnitude
	note(
		context,
		string.format(
			'%s: borrowed as "%s", %.3f x %.3f x %.3f the legacy size, its middle %.3f studs from the legacy origin',
			path,
			key,
			size.X / legacySize.X,
			size.Y / legacySize.Y,
			size.Z / legacySize.Z,
			drift
		)
	)
end

local function convertMeshBorrowEntry(
	context: Context,
	legacyCategory: string,
	rule: MeshBorrowCategoryRule,
	entry: roblox.Instance,
	borrowable: { [string]: { Key: string, Item: rojo.ModelJSON } }
)
	local model, standIn = getWornModel(context, legacyCategory, rule.Own, entry)
	if model == nil or standIn == nil then
		return
	end
	local path = `{legacyCategory}/{entry.Name}`
	local row = newEntryRow(context, legacyCategory, entry)
	local shapes = readShapes(context, path, model, standIn, {})
	if #shapes == 0 then
		addEmpty(context, row)
		return
	end
	-- only an entry that's nothing but the mesh is the item of SHL2 that's nothing but the mesh
	local meshId: string? = nil
	if #shapes == 1 then
		for _, mesh in getSortedChildren(shapes[1].Part, "SpecialMesh") do
			meshId = getAssetId(read(mesh, "MeshContent"))
		end
	end
	local match = if meshId then borrowable[meshId] else nil
	if match then
		local line = table.concat({ rule.Group, rule.Category, match.Key }, PATH_DELIMITER)
		row.IsBorrowed = true
		table.insert(row.ItemIds, getItemId(rule.Group, rule.Category, match.Key))
		-- two entries can be the same mesh, the list names what's borrowed once
		if table.find(context.borrows, line) == nil then
			table.insert(context.borrows, line)
		end
		compareBorrowedMesh(context, path, shapes[1], match.Key, match.Item)
	else
		writeWorn(context, legacyCategory, rule.Own, entry, row, model, standIn, shapes)
	end
	table.insert(context.entries, row)
end

-- the color a new character wore each channel in, which is what a part of that channel is written in
local function readDefaultColors(place: roblox.DataModel, rules: GameRules): { [string]: Color3Value }
	local colors: { [string]: Color3Value } = {}
	local path = rules.DefaultColorPath
	if path == nil then
		return colors
	end
	local holder = Place.findInstance(place, path)
	for _, rule in rules.Categories do
		local textureGroups: TextureGroupMap = if rule.Kind == "MeshBorrow"
			then rule.Own.TextureGroups
			elseif rule.Kind == "Split" or rule.Kind == "Worn" then rule.TextureGroups
			else {}
		for channel, textureGroup in textureGroups do
			for _, value in holder:GetChildren() do
				if value.Name == channel and value.ClassName == "BrickColorValue" then
					colors[textureGroup] = read(value, "Value").Color
				end
			end
			-- a part of a channel without one would be left in the placeholder it's stored in, which nobody ever saw
			assert(colors[textureGroup], `"{path}" holds no color for "{channel}"`)
		end
	end
	return colors
end

-- the lists the menus of the place stepped through, by legacy category
local function readPickers(place: roblox.DataModel, rules: GameRules): { [string]: Picker }
	local pickers: { [string]: Picker } = {}
	local tableName = rules.PickerTableName
	local pickerRules: { [string]: PickerRule } = rules.Pickers or {}
	for legacyCategory, rule in pickerRules do
		assert(tableName, "a menu is read by the name of the list its script keeps")
		local source: string = read(Place.findInstance(place, rule.Path), "Source")
		local body = assert(
			source:match("local%s+" .. tableName .. "%s*=%s*(%b{})"),
			`"{rule.Path}" keeps no list named "{tableName}"`
		)
		local order: { [string]: number } = {}
		local count = 0
		for name in body:gmatch('"([^"]+)"') do
			count += 1
			order[name] = count
		end
		assert(count > 0, `the list of "{rule.Path}" is empty`)
		pickers[legacyCategory] = { Order = order, PaidFrom = rule.PaidFrom, Default = rule.Default }
	end
	return pickers
end

local function readStarters(source: string, tableName: string): { [string]: string }
	local starters: { [string]: string } = {}
	-- the module declares the name more than once, only one of them holds pairs
	for body in source:gmatch("local%s+" .. tableName .. "%s*=%s*(%b{})") do
		for name, category in (body :: string):gmatch('{%s*"([^"]+)"%s*,%s*"([^"]+)"%s*}') do
			starters[name :: string] = category :: string
		end
	end
	assert(next(starters) ~= nil, `no "{tableName}" table that lists anything in the starter module`)
	return starters
end

local function readPatterns(context: Context, folder: roblox.Instance): { PatternRow }
	local rules = context.rules
	local rows: { PatternRow } = {}
	for _, decal in getSortedChildren(folder, "Decal") do
		local assetId = getAssetId(read(decal, "TextureContent"))
		if assetId == nil then
			fail(context, folder.Name, decal.Name, "no image")
			continue
		end
		local imagePath = context.imagePaths[assetId]
		if imagePath == nil then
			fail(context, folder.Name, decal.Name, `image {assetId} has no file in "{IMAGE_TABLE_PATH}"`)
			continue
		end
		table.insert(rows, {
			Key = toKebab(decal.Name),
			Name = decal.Name,
			-- a pattern that is a material still has its image, it's what the picker shows
			Image = imagePath,
			-- a save holds the url of the image, which the engine has spelled more than one way: go by the number
			LegacyAssetId = assert(tonumber(assetId), `"{assetId}" isn't a number`),
			Rarity = getRarity(context, decal),
			IsStarter = context.starters[decal.Name] ~= nil,
			Material = rules.PatternMaterials[decal.Name],
		})
	end
	return rows
end

-- lune writes an empty table as an object, these are lists whether they hold something or not
local function encodeRows(value: rojo.JSONValue): string
	-- a game without faces or patterns still has the file, whoever reads the tables reads all three
	if type(value) == "table" and next(value :: { [any]: any }) == nil then
		return "[]"
	end
	local json = serde.encode("json", value, true)
	for _, key in LIST_KEYS do
		json = json:gsub('("' .. key .. '"%s*:%s*){}', "%1[]")
	end
	return json
end

-- the pieces studio cut that are kept beside a library, by the id of the part each set was cut from
local function readCuts(libraryPath: string): { [string]: CutRow }
	local rows: { [string]: CutRow } = {}
	local path = `{libraryPath}{CUTS_SUFFIX}/{CUTS_INDEX_NAME}`
	if not fs.isFile(path) then
		return rows
	end
	local lines = fs.readFile(path):gsub("\r", ""):split("\n")
	assert(lines[1] == CUTS_INDEX_HEADER, `"{path}" doesn't start with its header`)
	for index = 2, #lines do
		local line = lines[index]
		if line == "" then
			continue
		end
		local columns = line:split(CUTS_COLUMN_DELIMITER)
		assert(#columns == 3, `"{path}" line {index} doesn't have its 3 columns`)
		rows[columns[1]] = { Part = columns[2], Pieces = columns[3]:split(CUTS_PIECE_DELIMITER) }
	end
	return rows
end

-- the pieces of the place studio cut + saved are put beside the library, with what each was cut from. they replace
-- whatever was cut before
local function takeCuts(libraryPath: string, placePath: string)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local folder = Place.findInstance(place, CUT_PIECES_PATH)
	local rows: { [string]: CutRow } = {}
	local ids: { string } = {}
	local outputs: { Output } = {}
	for _, piece in getSortedChildren(folder) do
		assert(piece.ClassName == "UnionOperation", `"{piece.Name}" of the cut place is no union`)
		local id, order, part = piece:GetAttribute("Id"), piece:GetAttribute("Order"), piece:GetAttribute("Part")
		assert(
			typeof(id) == "string" and typeof(order) == "number" and typeof(part) == "string",
			`"{piece.Name}" of the cut place doesn't say what it was cut from`
		)
		local row = rows[id]
		if row == nil then
			row = { Part = part, Pieces = {} }
			rows[id] = row
			table.insert(ids, id)
		end
		local fileName = `{id}-{order}{UNION_EXTENSION}`
		row.Pieces[order] = fileName
		-- what told the pieces apart in the place is said by the file + the index from here on
		for _, name in { "Id", "Order", "Part" } do
			piece:SetAttribute(name, nil)
		end
		table.insert(outputs, { path = fileName, contents = (Place.serialize(piece)) })
	end
	assert(#ids > 0, `"{placePath}" holds no cut pieces: run {CUT_SCRIPT_NAME} in studio + save it first`)
	table.sort(ids)
	local lines = { CUTS_INDEX_HEADER }
	for _, id in ids do
		local row = rows[id]
		table.insert(
			lines,
			table.concat({ id, row.Part, table.concat(row.Pieces, CUTS_PIECE_DELIMITER) }, CUTS_COLUMN_DELIMITER)
		)
	end
	local directory = `{libraryPath}{CUTS_SUFFIX}`
	if fs.isDir(directory) then
		fs.removeDir(directory)
	end
	fs.writeDir(directory)
	for _, output in outputs do
		fs.writeFile(`{directory}/{output.path}`, output.contents)
	end
	fs.writeFile(`{directory}/{CUTS_INDEX_NAME}`, table.concat(lines, "\n") .. "\n")
	print(`took {#outputs} pieces of {#ids} parts into "{directory}"`)
end

-- a place of every part only studio can cut, each where it sits against the middle of its limb + saying how high to
-- cut it, with the script that does it
local function writeCutJobs(context: Context, path: string)
	local place = roblox.Instance.new("DataModel")
	local jobs = roblox.Instance.new("Folder")
	jobs.Name = CUT_JOBS_NAME
	jobs.Parent = place:GetService("Workspace")
	for _, job in context.cutJobs do
		local shape = job.Shape
		local part: roblox.Instance
		local stretch = 1
		-- lune's Instance typedef leaves out dynamic property indexing
		local properties: any
		if shape.Kind == "Wedge" then
			part = roblox.Instance.new("WedgePart")
			properties = part
			properties.Size = shape.Size
			properties.CFrame = shape.CFrame
		else
			assert(shape.Kind == "Cylinder", `{job.Part} is neither a wedge nor a cylinder, nothing says how to cut it`)
			-- the cylinder of a mesh stands along the y of its part + is as wide each way as the part is. the one a
			-- part can be lies along its x + is round: it's handed over round, as wide as it's high where it lies, +
			-- says how much wider it gets once it's cut
			local cframe: CFrameValue = shape.CFrame
			local _, _, _, _, _, _, upX, _, upZ = cframe:GetComponents()
			local isXUp = math.abs(math.abs(upX) - 1) < AXIS_TOLERANCE
			assert(
				isXUp or math.abs(math.abs(upZ) - 1) < AXIS_TOLERANCE,
				`{job.Part} doesn't lie square on its side, nothing says how to cut it`
			)
			local high = if isXUp then shape.Size.X else shape.Size.Z
			local wide = if isXUp then shape.Size.Z else shape.Size.X
			part = roblox.Instance.new("Part")
			properties = part
			properties.Shape = (roblox :: any).Enum.PartType.Cylinder
			properties.Size = Vector3.new(shape.Size.Y, high, high)
			properties.CFrame =
				CFrame.fromMatrix(cframe.Position, cframe.YVector, if isXUp then cframe.XVector else cframe.ZVector)
			stretch = wide / high
		end
		part.Name = job.Id
		properties.Anchored = true
		for _, name in { "Color", "Material", "Transparency", "Reflectance" } do
			properties[name] = read(shape.Part, name)
		end
		local heights: { string } = {}
		for _, height in job.Heights do
			table.insert(heights, string.format("%.6f", height))
		end
		part:SetAttribute("Id", job.Id)
		part:SetAttribute("Part", job.Part)
		part:SetAttribute("Heights", table.concat(heights, CUT_HEIGHT_DELIMITER))
		part:SetAttribute("Stretch", stretch)
		part.Parent = jobs
	end
	local module = roblox.Instance.new("ModuleScript")
	module.Name = CUT_SCRIPT_NAME;
	(module :: any).Source = fs.readFile(CUT_SCRIPT_PATH)
	module.Parent = place:GetService("ServerStorage")
	local directory = assert(path:match("^(.*)/[^/]+$"), `"{path}" names no folder to write a place into`)
	fs.writeDir(directory)
	fs.writeFile(path, roblox.serializePlace(place))
	print(
		`\n{#context.cutJobs} parts for studio to cut are in "{path}": open it, run `
			.. `require(game.ServerStorage.{CUT_SCRIPT_NAME})() from the command bar, save, then --take-cuts`
	)
end

local function printList(title: string, lines: { string })
	print(`\n{title} ({#lines})`)
	for _, line in lines do
		print(`  {line}`)
	end
end
-- Class
do
	local gameId, placePath, outPath, isForced, cutJobsPath, takeCutsPath = parseArgs(process.args)
	local rules = assert(RULES[gameId], `No rules for the catalogue of "{gameId}"`)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	-- a game is written into the folders it's built from
	local content = game.CONTENTS[game.getId(gameId)]
	local libraryPath = content.CharacterPath
	local dataPath = `{content.DataPath}/catalogue`
	for _, path in { libraryPath, dataPath } do
		local fullPath = `{outPath}/{path}`
		if fs.isDir(fullPath) then
			-- both are written whole, an item fixed by hand would be gone without a word
			assert(isForced, `"{fullPath}" already exists, pass --force to replace it`)
		end
	end

	if takeCutsPath then
		takeCuts(libraryPath, takeCutsPath)
	end

	local place = roblox.deserializePlace(fs.readFile(placePath))
	local catalogue = Place.findInstance(place, rules.CataloguePath)
	local rigPath, starterPath, starterTableName = rules.RigPath, rules.StarterPath, rules.StarterTableName
	local context: Context = {
		rules = rules,
		game = gameId,
		libraryPath = libraryPath,
		rig = if rigPath then Place.findInstance(place, rigPath) else nil,
		starters = if starterPath and starterTableName
			then readStarters(read(Place.findInstance(place, starterPath), "Source"), starterTableName)
			else {},
		pickers = readPickers(place, rules),
		defaultColors = readDefaultColors(place, rules),
		imagePaths = readImagePaths(IMAGE_TABLE_PATH),
		outputs = {},
		entries = {},
		faces = {},
		borrows = {},
		empties = {},
		joints = {},
		cuts = readCuts(libraryPath),
		cutCounts = {},
		cutJobs = {},
		notes = {},
		failures = {},
		itemCounts = {},
		contentMeshIds = {},
		rigMeshIds = {},
	}

	local entryCounts: { [string]: number } = {}
	local names: { [string]: string } = {}
	for _, categoryFolder in getSortedChildren(catalogue) do
		if rules.Categories[categoryFolder.Name] == nil then
			table.insert(context.failures, `{categoryFolder.Name}: no rule for the category, none of it was converted`)
		end
	end
	for _, legacyCategory in rules.CategoryNames do
		local rule = rules.Categories[legacyCategory]
		local categoryFolder =
			assert(catalogue:FindFirstChild(legacyCategory), `the catalogue has no "{legacyCategory}"`)
		local borrowable = if rule.Kind == "Borrow" then readBorrowable(rule.Group, rule.Category) else {}
		local borrowableMeshes = if rule.Kind == "MeshBorrow"
			then readBorrowableMeshes(context, rule.Group, rule.Category)
			else {}
		local entries = getSortedChildren(categoryFolder)
		entryCounts[legacyCategory] = #entries
		for _, entry in entries do
			-- a save names an entry without its category, so a name can only be taken once
			assert(names[entry.Name] == nil, `"{entry.Name}" is in "{legacyCategory}" and "{names[entry.Name]}"`)
			names[entry.Name] = legacyCategory
			if rule.Kind == "Limb" then
				convertLimbEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "Pieces" then
				convertPiecesEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "Mount" then
				convertMountEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "Face" then
				convertFaceEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "Split" then
				convertSplitEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "Worn" then
				convertWornEntry(context, legacyCategory, rule, entry)
			elseif rule.Kind == "MeshBorrow" then
				convertMeshBorrowEntry(context, legacyCategory, rule, entry, borrowableMeshes)
			else
				convertBorrowEntry(context, legacyCategory, rule, entry, borrowable)
			end
		end
	end
	local bareLimbRow = convertBareLimbs(context)
	local patternPath, priceAdjustPath = rules.PatternPath, rules.PriceAdjustPath
	local patterns: { PatternRow } = if patternPath
		then readPatterns(context, Place.findInstance(place, patternPath))
		else {}
	for name, category in context.starters do
		if names[name] == nil and catalogue:FindFirstChild(category) then
			note(context, `{category}/{name}: in the starter list, not in the catalogue`)
		end
	end

	table.sort(context.borrows)
	table.insert(context.outputs, {
		path = `{libraryPath}/borrow.txt`,
		contents = `# what {gameId} wears out of the library of SHL2 ({BORROW_PATH}), one <group>/<category>/<key> per line\n`
			.. "# written by scripts/util/convert-catalogue.lune.luau\n"
			.. table.concat(context.borrows, "\n")
			.. "\n",
	})
	table.insert(context.outputs, {
		path = `{dataPath}/entry.json`,
		contents = encodeRows({
			-- what a cost was multiplied by before it was rounded up to the next hundred
			PriceAdjust = if priceAdjustPath then read(Place.findInstance(place, priceAdjustPath), "Value") else nil,
			Entries = context.entries,
			-- what the catalogue never had + the library needs
			Extras = { bareLimbRow },
			-- what a save can name that leaves a character with nothing on
			Empty = if #context.empties > 0 then context.empties else nil,
		} :: any),
	})
	table.insert(context.outputs, { path = `{dataPath}/face.json`, contents = encodeRows(context.faces :: any) })
	table.insert(context.outputs, { path = `{dataPath}/pattern.json`, contents = encodeRows(patterns :: any) })

	-- nothing is touched until everything converted
	for _, path in { libraryPath, dataPath } do
		local fullPath = `{outPath}/{path}`
		if fs.isDir(fullPath) then
			fs.removeDir(fullPath)
		end
	end
	for _, output in context.outputs do
		local fullPath = `{outPath}/{output.path}`
		fs.writeDir(assert(fullPath:match("^(.*)/[^/]+$")))
		fs.writeFile(fullPath, output.contents)
	end

	table.sort(context.notes)
	table.sort(context.failures)
	printList("notes", context.notes)
	if rules.Body then
		table.sort(context.joints)
		printList("across a joint", context.joints)
	end
	printList("failed", context.failures)
	print("\nlegacy entries")
	local entryCount, pricedCount, borrowedCount = 0, 0, 0
	for _, legacyCategory in rules.CategoryNames do
		print(`  {legacyCategory}: {entryCounts[legacyCategory]} ({rules.Categories[legacyCategory].Kind})`)
		entryCount += entryCounts[legacyCategory]
	end
	for _, row in context.entries do
		pricedCount += if row.Cost and row.Cost > 0 then 1 else 0
		borrowedCount += if row.IsBorrowed then 1 else 0
	end
	print("items")
	local libraryCategories: { string } = {}
	local itemCount = 0
	for libraryCategory, count in context.itemCounts do
		table.insert(libraryCategories, libraryCategory)
		itemCount += count
	end
	table.sort(libraryCategories)
	for _, libraryCategory in libraryCategories do
		print(`  {libraryCategory}: {context.itemCounts[libraryCategory]}`)
	end
	local contentMeshCount, rigMeshCount = 0, 0
	for _ in context.contentMeshIds do
		contentMeshCount += 1
	end
	for _ in context.rigMeshIds do
		rigMeshCount += 1
	end
	print(
		`{entryCount} entries: {borrowedCount} borrowed, {#context.faces} faces, {pricedCount} priced, `
			.. `{#context.failures} failed`
	)
	if #context.empties > 0 then
		print(`{#context.empties} entries stand for wearing nothing`)
	end
	print(`{itemCount} new items, {#patterns} patterns, {#context.outputs} files written under "{outPath}"`)
	print(`{contentMeshCount} mesh ids carried, {rigMeshCount} mesh ids of the rig used for the painted layers`)
	if cutJobsPath then
		writeCutJobs(context, cutJobsPath)
	end
end
