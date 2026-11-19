--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Item")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
local WornUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Worn")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Appearance = AppearanceType.Appearance
type Clothes = AppearanceUtil.Clothes
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type ItemGroup = AppearanceType.ItemGroup
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- one of the two a character is out as + the look it's stood up in
type Identity = {
	Name: string,
	Look: Appearance,
}
-- Constants
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local FOLDER_NAME = "IdentitiesStory"
local HEAD_NAME = "Head"
local ROOT_NAME = "HumanoidRootPart"
-- studs in front of the camera the rigs stand at + between one rig and the next
local CAMERA_DISTANCE = 16
local RIG_DISTANCE = 6
local ARTIFACT_CATEGORY = "artifacts"
local COSTUME_GROUP: ItemGroup = "costume"
local COSMETICS_GROUP: ItemGroup = "cosmetics"
local CLOTHING_GROUP: ItemGroup = "clothing"
local HAIR_KEY: TextureGroupKey = "Hair"
-- the three colors of a costume, picked once for all of it
local CHANNELS: { TextureGroupKey } = table.freeze({ "Primary" :: TextureGroupKey, "Secondary", "Tertiary" })
local GLOW_MATERIAL = Enum.Material.Neon
local NO_GLOW = "None"
local GLOWS: { string } = table.freeze({ "Secondary", "Primary", "Tertiary", NO_GLOW })
-- what a color is picked out of: the palette of a game that has one
local COLORS: { Color3 } = CharacterEditorDefinition.PALETTE
	or table.freeze({
		Color3.fromRGB(13, 105, 172),
		Color3.fromRGB(239, 184, 56),
		Color3.fromRGB(77, 77, 77),
		Color3.fromRGB(196, 40, 28),
		Color3.fromRGB(75, 151, 75),
		Color3.fromRGB(245, 245, 245),
		Color3.fromRGB(255, 194, 158),
		Color3.fromRGB(86, 66, 54),
	})
-- where a pick starts out, in a palette of the old grid + in the few colors a game without one is shown in
local HAS_PALETTE = CharacterEditorDefinition.PALETTE ~= nil
local DEFAULT_PRIMARY = if HAS_PALETTE then 4 else 1
local DEFAULT_SECONDARY = if HAS_PALETTE then 6 else 2
local DEFAULT_TERTIARY = if HAS_PALETTE then 9 else 6
local DEFAULT_HAIR = if HAS_PALETTE then 49 else 8
local DEFAULT_SKIN = if HAS_PALETTE then 50 else 7
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getColor(index: number): Color3
	return COLORS[(index - 1) % #COLORS + 1]
end

local function getText(color: Color3): string
	return string.format("%d, %d, %d", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

-- an id typed into a box, 0 for anything that's none
local function getAssetId(text: string): number
	local id = tonumber(text)
	return if id and id > 0 then math.floor(id) else 0
end

-- one item of every category of the group, each category a step further down its own list: in a game whose suit
-- comes a limb to a category every limb is of another suit, so every joint of the body is a seam
local function insertItems(items: { Item }, group: ItemGroup, step: number)
	local categories: { string } = table.clone(ItemAppearanceDefinition.listCategories(group))
	table.sort(categories)
	for index, category in categories do
		if category == ARTIFACT_CATEGORY then
			continue
		end
		local definitions: { ItemDefinition } = table.clone(ItemAppearanceDefinition.list(group, category))
		if #definitions == 0 then
			continue
		end
		-- a library has no order of its own
		table.sort(definitions, function(a: ItemDefinition, b: ItemDefinition): boolean
			return a.Id < b.Id
		end)
		local definition: ItemDefinition = definitions[(step + index - 2) % #definitions + 1]
		table.insert(items, { DefinitionId = definition.Id, TextureGroups = {} })
	end
end

local function newLook(items: { Item }, skinColor: Color3): Appearance
	return table.freeze({
		Items = items,
		SkinColor = skinColor,
		Transitions = {},
		HiddenTags = {},
	})
end

-- everything the look wears of an item group in one color, the way a pick of the editor writes it
local function setColor(
	look: Appearance,
	itemGroup: ItemGroup,
	key: TextureGroupKey,
	color: Color3,
	isGlowing: boolean
): Appearance
	return WornUtil.set(
		look,
		{ Type = "WornTexture", ItemGroup = itemGroup, Group = key },
		function(group: TextureGroup): TextureGroup
			return TextureGroupConstructor.new(
				color,
				if isGlowing then GLOW_MATERIAL else group.Material,
				group.Transparency
			)
		end
	)
end

-- the hero in a costume of three colors + the civilian the hero is under it: the same hair, face + skin
local function newIdentities(
	suit: number,
	colors: { [TextureGroupKey]: Color3 },
	hairColor: Color3,
	skinColor: Color3,
	glow: string
): { Identity }
	local cosmetics: { Item } = {}
	insertItems(cosmetics, COSMETICS_GROUP, suit)
	local heroItems: { Item } = table.clone(cosmetics)
	insertItems(heroItems, COSTUME_GROUP, suit)
	local civilianItems: { Item } = table.clone(cosmetics)
	insertItems(civilianItems, CLOTHING_GROUP, suit)
	local hero = newLook(heroItems, skinColor)
	for _, key: TextureGroupKey in CHANNELS do
		local color = colors[key]
		if color then
			hero = setColor(hero, COSTUME_GROUP, key, color, glow == key)
		end
	end
	hero = setColor(hero, COSMETICS_GROUP, HAIR_KEY, hairColor, false)
	local civilian = setColor(newLook(civilianItems, skinColor), COSMETICS_GROUP, HAIR_KEY, hairColor, false)
	return {
		{ Name = "hero", Look = hero },
		{ Name = "civilian", Look = civilian },
	}
end

-- what's on the rig, read back off it: the items that made it on, what's left to see of the body + what it has on,
-- how much of each color of the costume there is + whether all of it took the pick
local function getReport(
	rig: Model,
	identity: Identity,
	colors: { [TextureGroupKey]: Color3 },
	glow: string,
	errors: { string }
): { string }
	local lines: { string } = {}
	local wornIds: { [string]: true? } = {}
	local wornCount = 0
	local counts: { [TextureGroupKey]: number } = {}
	local offCounts: { [TextureGroupKey]: number } = {}
	for _, item in rig:GetChildren() do
		if not item:HasTag(ItemUtil.ITEM_TAG) then
			continue
		end
		wornIds[item.Name] = true
		wornCount += 1
		local indexRes = ItemAppearanceDefinition.getIndex(item.Name)
		if indexRes.IsErr or indexRes.Value.Group ~= COSTUME_GROUP then
			continue
		end
		local parts = item:QueryDescendants("BasePart") :: { BasePart }
		if item:IsA("BasePart") then
			table.insert(parts, item)
		end
		for _, part in parts do
			local attribute = part:GetAttribute("TextureGroup")
			local key: TextureGroupKey? = if AppearanceType.TextureGroupKey(attribute)
				then attribute :: TextureGroupKey
				else nil
			local color: Color3? = if key then colors[key] else nil
			if not key or not color then
				continue
			end
			counts[key] = (counts[key] or 0) + 1
			-- a part keeps its color in fewer bits than a pick has
			if part.Color:ToHex() ~= color:ToHex() or (glow == key and part.Material ~= GLOW_MATERIAL) then
				offCounts[key] = (offCounts[key] or 0) + 1
			end
		end
	end
	local notWorn: { string } = {}
	for _, item in identity.Look.Items do
		local definitionRes = ItemAppearanceDefinition.get(item.DefinitionId)
		local isFace = definitionRes.IsOk and definitionRes.Value.Type == "Face"
		if not isFace and not wornIds[item.DefinitionId] then
			table.insert(notWorn, item.DefinitionId)
		end
	end
	table.insert(lines, `{identity.Name}: {wornCount} items worn`)
	if #notWorn > 0 then
		table.insert(lines, `  no room or nothing to sit on: {table.concat(notWorn, ", ")}`)
	end
	local hidden: { string } = {}
	for _, limb in rig:GetChildren() do
		local isBody = limb:IsA("BasePart") and not limb:HasTag(ItemUtil.ITEM_TAG)
		local isOther = limb.Name == HEAD_NAME or limb.Name == ROOT_NAME or limb.Name == RigUtil.FAKE_HEAD_NAME
		if isBody and not isOther and limb:IsA("BasePart") and limb.Transparency >= 1 then
			table.insert(hidden, limb.Name)
		end
	end
	table.sort(hidden)
	table.insert(
		lines,
		if #hidden > 0
			then `  {#hidden} parts of the body aren't drawn: {table.concat(hidden, ", ")}`
			else `  all of the body is drawn`
	)
	local humanoid = rig:FindFirstChildWhichIsA("Humanoid")
	local description = if humanoid then humanoid:GetAppliedDescription() else nil
	if description then
		table.insert(
			lines,
			string.format(
				"  body type %.2f, proportion %.2f, shirt %d, pants %d, torso %s, legs %s",
				description.BodyTypeScale,
				description.ProportionScale,
				description.Shirt,
				description.Pants,
				getText(description.TorsoColor),
				getText(description.LeftLegColor)
			)
		)
		description:Destroy()
	end
	for _, key: TextureGroupKey in CHANNELS do
		local count, color = counts[key] or 0, colors[key]
		if count > 0 and color then
			table.insert(
				lines,
				`  {key}: {count} parts in {getText(color)}{if glow == key then ", glowing" else ""}, {offCounts[key] or 0} that aren't`
			)
		end
	end
	local head = rig:FindFirstChild(RigUtil.FAKE_HEAD_NAME)
	local faceCount = 0
	if head then
		for _, decal in head:GetChildren() do
			if decal:IsA("Decal") then
				faceCount += 1
			end
		end
	end
	table.insert(lines, `  a face of {faceCount} {if faceCount == 1 then "picture" else "pictures"}`)
	for _, message in errors do
		table.insert(lines, `  error: {message}`)
	end
	return lines
end

-- the rigs stand side by side in front of the camera + face it
local function getGround(index: number, count: number): CFrame
	local camera = Workspace.CurrentCamera
	local cameraCFrame = if camera then camera.CFrame else CFrame.new(0, 20, 0)
	local look = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
	local right = forward:Cross(Vector3.yAxis)
	local middle = cameraCFrame.Position + forward * CAMERA_DISTANCE - Vector3.yAxis * 4
	local position = middle + right * RIG_DISTANCE * (index - (count + 1) / 2)
	return CFrame.lookAt(position, position - forward)
end
-- Class
-- the two identities of one character are out in the world of the place, the frame of the story holds what was read
-- back off each rig. a shirt + pants only go on in a game whose bodies wear the ones of an account
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Suit = UILabs.Slider(2, 1, 14, 1),
		Primary = UILabs.Slider(DEFAULT_PRIMARY, 1, #COLORS, 1),
		Secondary = UILabs.Slider(DEFAULT_SECONDARY, 1, #COLORS, 1),
		Tertiary = UILabs.Slider(DEFAULT_TERTIARY, 1, #COLORS, 1),
		Hair = UILabs.Slider(DEFAULT_HAIR, 1, #COLORS, 1),
		Skin = UILabs.Slider(DEFAULT_SKIN, 1, #COLORS, 1),
		Glow = UILabs.Choose(GLOWS),
		Shirt = UILabs.String("0"),
		Pants = UILabs.String("0"),
	},
}, function(props)
	local suit: number = props.controls.Suit
	local primary: number = props.controls.Primary
	local secondary: number = props.controls.Secondary
	local tertiary: number = props.controls.Tertiary
	local hair: number = props.controls.Hair
	local skin: number = props.controls.Skin
	local glow: string = props.controls.Glow
	local shirt: number = getAssetId(props.controls.Shirt)
	local pants: number = getAssetId(props.controls.Pants)
	local lines: { string }, setLines: ({ string }) -> () = React.useState({} :: { string })
	React.useEffect(function()
		local isCanceled = false
		local function getIfCanceled(): boolean
			return isCanceled
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		-- whatever is left in the camera is neither saved with the place nor synced anywhere
		folder.Parent = Workspace.CurrentCamera or Workspace
		setLines({ "dressing.." })
		task.spawn(function()
			local colors: { [TextureGroupKey]: Color3 } = {
				Primary = getColor(primary),
				Secondary = getColor(secondary),
				Tertiary = getColor(tertiary),
			}
			local clothes: Clothes = { Shirt = shirt, Pants = pants }
			local identities = newIdentities(suit, colors, getColor(hair), getColor(skin), glow)
			local report: { string } = {}
			if not AppearanceUtil.HAS_OWN_CLOTHES then
				table.insert(report, `a body of this game wears no shirt or pants of an account`)
			end
			for index, identity in identities do
				local ground = getGround(index, #identities)
				local description = HumanoidDescriptionBuilder.new():build()
				local rigF =
					Future.awaitUntil(RigUtil.createFromDescription(description, ground, folder), getIfCanceled)
				description:Destroy()
				if rigF.IsCanceled then
					return
				end
				local rig: Model = rigF.Value
				rig.Name = identity.Name
				local rootPart = rig.PrimaryPart
				if rootPart then
					-- nothing holds it up in a place that isn't running
					rootPart.Anchored = true
				end
				local resF = Future.awaitUntil(AppearanceUtil.apply(rig, identity.Look, clothes), getIfCanceled)
				if resF.IsCanceled then
					return
				end
				-- the body a look is built on can stand at another height than the one the rig came as
				RigUtil.moveTo(rig, ground)
				local errors: { string } = if resF.Value.IsErr then resF.Value.Value else {}
				for _, line in getReport(rig, identity, colors, glow, errors) do
					table.insert(report, line)
				end
			end
			if not isCanceled then
				setLines(report)
			end
		end)
		return function()
			isCanceled = true
			folder:Destroy()
		end
	end, { suit :: any, primary, secondary, tertiary, hair, skin, glow, shirt, pants })

	local children: { [string]: any } = {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		}),
	}
	for index, line in lines do
		children[`Line{index}`] = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			FontFace = FONT,
			LayoutOrder = index,
			Size = UDim2.fromScale(1, 0),
			Text = line,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.3,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(520, 0),
	}, children)
end)
