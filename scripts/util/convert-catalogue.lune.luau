--!strict
-- turns the customization catalogue of a legacy place into item templates the way lib/character holds them, plus the
-- tables a game keeps beside them: what an entry was called in a legacy save, what it cost + who started with it.
-- the place is only ever read. an entry the library of SHL2 already has is borrowed instead of written a second time
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
local game = require("../modules/game")
local rojo = require("../modules/rojo")
local rojoValue = require("../modules/rojo-value")
-- Types
-- lune hands out roblox datatypes without typing them
type CFrameValue = any
type Vector3Value = any
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
-- a decal, it becomes an image instead of a template
type FaceCategoryRule = {
	Kind: "Face",
	Group: string,
	Category: string,
	Slot: string,
	PieceName: string,
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
type CategoryRule = LimbCategoryRule | PiecesCategoryRule | MountCategoryRule | FaceCategoryRule | BorrowCategoryRule
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
	RigPath: string,
	PatternPath: string,
	-- a module of the place that lists what every player owns from the start as { name, category } pairs
	StarterPath: string,
	StarterTableName: string,
	PriceAdjustPath: string,
	CategoryNames: { string },
	Categories: { [string]: CategoryRule },
	Limbs: { LimbRule },
	-- the part that stands in for the body part a piece is worn on
	StandInName: string,
	-- value objects whose presence on a piece says something about the item
	MarkerNames: { string },
	-- by the number a legacy entry stores, from 0
	Rarities: { string },
	BaseTextureGroup: string,
	BaseColor: { number },
	-- how much wider than the body part its painted layer is on every axis, so the two don't flicker
	BaseInflation: number,
	-- a limb that wears no suit still needs something to paint
	BareLimbKey: string?,
	BareLimbName: string?,
	-- the one pattern that is a material instead of an image
	PatternMaterials: { [string]: string },
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
	Rarity: string,
	Cost: number?,
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
	Rarity: string,
	IsStarter: boolean,
	Material: string?,
}
type Output = { path: string, contents: string }
type Context = {
	rules: GameRules,
	game: string,
	-- where the items of the game are written to
	libraryPath: string,
	rig: roblox.Instance,
	starters: { [string]: string },
	-- the file each legacy image has under asset/image, by its id
	imagePaths: { [string]: string },
	outputs: { Output },
	entries: { EntryRow },
	faces: { FaceRow },
	borrows: { string },
	notes: { string },
	failures: { string },
	-- per category of the library, for the summary
	itemCounts: { [string]: number },
	contentMeshIds: { [string]: boolean },
	rigMeshIds: { [string]: boolean },
}
-- Constants
local USAGE =
	"Usage: lune run scripts/util/convert-catalogue.lune.luau <game> <place.rbxl> [--out <dir>] [--force | -f]"
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
local LIST_KEYS = { "Entries", "Extras", "ItemIds", "TextureGroups" }
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
}
-- Variables
-- References
local CFrame = (roblox :: any).CFrame
local Vector3 = (roblox :: any).Vector3
-- Private Functions
local function parseArgs(args: { string }): (string, string, string, boolean)
	local values: { string } = {}
	local outPath = "."
	local isForced = false
	local index = 1
	while index <= #args do
		local arg = args[index]
		if arg == "--force" or arg == "-f" then
			isForced = true
		elseif arg == "--out" then
			index += 1
			outPath = (assert(args[index], `Expected a directory after --out\n{USAGE}`):gsub("\\", "/"))
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(values, (arg:gsub("\\", "/")))
		end
		index += 1
	end
	assert(#values == 2, `Expected a game and a place\n{USAGE}`)
	return values[1], values[2], outPath, isForced
end

local function read(inst: roblox.Instance, name: string): any
	-- lune's Instance typedef leaves out dynamic property indexing
	return (inst :: any)[name]
end

local function findInstance(place: roblox.DataModel, instPath: string): roblox.Instance
	local inst: roblox.Instance? = nil
	for _, name in instPath:split(PATH_DELIMITER) do
		local parent: roblox.Instance = inst or place
		inst = assert(parent:FindFirstChild(name), `No instance at "{name}" in "{instPath}"`)
	end
	return assert(inst, `Expected an instance path, received "{instPath}"`)
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

-- "LeftLowerArm" + "Spaghetti Strap Top" both become what a file of the library is called
local function toKebab(name: string): string
	local spaced = name:gsub("(%l)(%u)", "%1 %2")
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
	local properties: rojo.NodeProperties = {
		Color = rojoValue.toValue(read(part, "Color")),
		Size = rojoValue.toValue(read(part, "Size")),
	}
	local offset: CFrameValue = origin:ToObjectSpace(read(part, "CFrame"))
	if not getIfIdentity(offset) then
		properties.CFrame = toCFrameValue(offset)
	end
	local material = read(part, "Material")
	if textureGroup and material.Value ~= MATERIAL_SMOOTH_PLASTIC then
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
	if textureGroup then
		properties.Attributes = newAttributes({ [TEXTURE_GROUP_ATTRIBUTE] = textureGroup })
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
	local meshId = assert(getAssetId(read(bodyPart, "MeshContent")), `rig part "{bodyPart.Name}" has no mesh`)
	context.rigMeshIds[meshId] = true
	return {
		Name = BASE_NAME,
		ClassName = "MeshPart",
		Properties = {
			Color = { Color3 = rules.BaseColor },
			Size = rojoValue.toValue(read(bodyPart, "Size") + Vector3.one * rules.BaseInflation),
			Material = { Enum = MATERIAL_SMOOTH_PLASTIC },
			MeshContent = rojoValue.toValue(read(bodyPart, "MeshContent")),
			InitialSize = rojoValue.toValue(read(bodyPart, "InitialSize")),
			RenderFidelity = rojoValue.toValue(read(bodyPart, "RenderFidelity"), "Enum"),
			Attributes = newAttributes({ [TEXTURE_GROUP_ATTRIBUTE] = rules.BaseTextureGroup }),
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

-- a piece the way an item wears it: an invisible root the size of what it was fitted to, holding the one attachment
-- that names its anchor, with everything else placed against it
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
		{
			Name = ROOT_NAME,
			ClassName = "Part",
			Properties = {
				Size = rojoValue.toValue(read(fittedTo, "Size")),
				Transparency = { Float32 = 1 },
				Attributes = newAttributes({ Rojo_Id = rojoId }),
			} :: rojo.NodeProperties,
			Children = { { Name = anchorName, ClassName = "Attachment" } },
		},
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
	return {
		Name = toKebab(piece.Name),
		ClassName = "Model",
		Properties = {
			Attributes = newAttributes({ Rojo_Target_PrimaryPart = rojoId }),
		} :: rojo.NodeProperties,
		Children = children,
	}
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
	local rigPart = context.rig:FindFirstChild(name)
	return if rigPart and rigPart:IsA("BasePart") then rigPart else nil
end

local function getRarity(context: Context, entry: roblox.Instance): string
	local value = entry:FindFirstChild("Rarity")
	local index = if value then read(value, "Value") + 1 else 1
	return assert(context.rules.Rarities[index], `"{entry.Name}" has rarity {index - 1}, which has no name`)
end

local function newEntryRow(context: Context, legacyCategory: string, entry: roblox.Instance): EntryRow
	local cost = entry:FindFirstChild("Cost")
	local row: EntryRow = {
		LegacyCategory = legacyCategory,
		LegacyName = entry.Name,
		Rarity = getRarity(context, entry),
		-- as stored, what a player paid was this times the price adjustment, rounded up to the next hundred
		Cost = if cost then read(cost, "Value") else nil,
		IsStarter = context.starters[entry.Name] ~= nil,
		IsBorrowed = false,
		ItemIds = {},
	}
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
		local attributes: { [string]: string | boolean } = { Name = entry.Name, Rarity = row.Rarity }
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
	local attributes: { [string]: string | boolean } = { Name = entry.Name, Rarity = row.Rarity }
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
	local attributes: { [string]: string | boolean } = { Name = entry.Name, Rarity = row.Rarity }
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
	local pieceModel = entry:FindFirstChild(rule.PieceName)
	local standIn = pieceModel and pieceModel:FindFirstChild(context.rules.StandInName)
	local decal = standIn and standIn:FindFirstChildOfClass("Decal")
	local assetId = decal and getAssetId(read(decal, "TextureContent"))
	local imagePath = assetId and context.imagePaths[assetId]
	if decal == nil or assetId == nil then
		fail(context, legacyCategory, name, "no decal with an image")
	elseif imagePath == nil then
		fail(context, legacyCategory, name, `image {assetId} has no file in "{IMAGE_TABLE_PATH}"`)
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
			newItemNode(pieces, { Name = name, Rarity = row.Rarity }, limb.Tags)
		)
		table.insert(row.ItemIds, id)
		limbItemIds[limb.Name] = id
	end
	return row
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
	local json = serde.encode("json", value, true)
	for _, key in LIST_KEYS do
		json = json:gsub('("' .. key .. '"%s*:%s*){}', "%1[]")
	end
	return json
end

local function printList(title: string, lines: { string })
	print(`\n{title} ({#lines})`)
	for _, line in lines do
		print(`  {line}`)
	end
end
-- Class
do
	local gameId, placePath, outPath, isForced = parseArgs(process.args)
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

	local place = roblox.deserializePlace(fs.readFile(placePath))
	local catalogue = findInstance(place, rules.CataloguePath)
	local context: Context = {
		rules = rules,
		game = gameId,
		libraryPath = libraryPath,
		rig = findInstance(place, rules.RigPath),
		starters = readStarters(read(findInstance(place, rules.StarterPath), "Source"), rules.StarterTableName),
		imagePaths = readImagePaths(IMAGE_TABLE_PATH),
		outputs = {},
		entries = {},
		faces = {},
		borrows = {},
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
			else
				convertBorrowEntry(context, legacyCategory, rule, entry, borrowable)
			end
		end
	end
	local bareLimbRow = convertBareLimbs(context)
	local patterns = readPatterns(context, findInstance(place, rules.PatternPath))
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
			PriceAdjust = read(findInstance(place, rules.PriceAdjustPath), "Value"),
			Entries = context.entries,
			-- what the catalogue never had + the library needs
			Extras = { bareLimbRow },
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
	print(`{itemCount} new items, {#patterns} patterns, {#context.outputs} files written under "{outPath}"`)
	print(`{contentMeshCount} mesh ids carried, {rigMeshCount} mesh ids of the rig used for the painted layers`)
end
