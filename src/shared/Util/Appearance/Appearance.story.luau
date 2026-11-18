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
local PatternDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Pattern")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type ItemDefinition = AppearanceType.ItemDefinition
type ItemGroup = AppearanceType.ItemGroup
type Scale = AppearanceType.Scale
type TextureGroup = AppearanceType.TextureGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
-- a body the look is stood up in
type Body = {
	Name: string,
	Scale: Scale?,
}
-- Constants
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local FOLDER_NAME = "AppearanceStory"
local HEAD_NAME = "Head"
-- studs in front of the camera the rigs stand at + between one rig and the next
local CAMERA_DISTANCE = 16
local RIG_DISTANCE = 6
local ARTIFACT_CATEGORY = "artifacts"
-- what a hero wears, a category at a time
local ITEM_GROUPS: { ItemGroup } = table.freeze({ "costume" :: ItemGroup, "cosmetics" })
local SKIN_COLOR = Color3.fromRGB(255, 194, 158)
local COLORS: { Color3 } = table.freeze({
	Color3.fromRGB(13, 105, 172),
	Color3.fromRGB(239, 184, 56),
	Color3.fromRGB(77, 77, 77),
	Color3.fromRGB(196, 40, 28),
	Color3.fromRGB(75, 151, 75),
	Color3.fromRGB(245, 245, 245),
})
-- the smallest + the largest body of a game with body sizes, the one body of a game without
local BODIES: { Body } = {}
do
	local sizes = CharacterEditorDefinition.SCALE
	if sizes then
		local smallest, largest = sizes.Heights[1], sizes.Heights[#sizes.Heights]
		table.insert(BODIES, {
			Name = "smallest",
			Scale = { Height = smallest, Width = smallest * sizes.WidthRatios[1] },
		})
		table.insert(BODIES, {
			Name = "largest",
			Scale = { Height = largest, Width = largest * sizes.WidthRatios[#sizes.WidthRatios] },
		})
	else
		table.insert(BODIES, { Name = "the one body" })
	end
end
table.freeze(BODIES)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getText(vector: Vector3): string
	return string.format("%.3f, %.3f, %.3f", vector.X, vector.Y, vector.Z)
end

-- one item of every category a hero wears, each category a step further down its own list: in a game whose suit
-- comes a limb to a category every limb is of another suit
local function newLook(suit: number, hasPatterns: boolean, isNeon: boolean, eyeHue: number, scale: Scale?): Appearance
	local patterns = PatternDefinition.list()
	local items: { Item } = {}
	local categoryCount = 0
	for _, group: ItemGroup in ITEM_GROUPS do
		local categories: { string } = table.clone(ItemAppearanceDefinition.listCategories(group))
		table.sort(categories)
		for _, category in categories do
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
			categoryCount += 1
			local definition: ItemDefinition = definitions[(suit + categoryCount - 2) % #definitions + 1]
			local textureGroups: { [TextureGroupKey]: TextureGroup? } = {}
			for index, key: TextureGroupKey in definition.TextureGroups do
				local step = categoryCount + index
				textureGroups[key] = {
					-- the one group of a face is the color its eyes are drawn in
					Color = if definition.Type == "Face"
						then Color3.fromHSV(eyeHue, 0.8, 0.8)
						else COLORS[step % #COLORS + 1],
					Material = if isNeon and key == "Secondary"
						then Enum.Material.Neon
						else Enum.Material.SmoothPlastic,
					Transparency = 0,
					Pattern = if hasPatterns and #patterns > 0 then patterns[step % #patterns + 1].Key else nil,
				}
			end
			table.insert(items, { DefinitionId = definition.Id, TextureGroups = textureGroups })
		end
	end
	return table.freeze({
		Items = items,
		SkinColor = SKIN_COLOR,
		Scale = scale,
		Transitions = {},
		HiddenTags = {},
	})
end

-- what's on the rig, read back off it: the items that made it on, the size of the body + how far the stand-in of a
-- piece is off the limb it's worn on. a piece is fitted to its stand-in, so one that's off is a piece that doesn't fit
local function getReport(rig: Model, body: Body, look: Appearance, errors: { string }): { string }
	local lines: { string } = {}
	local wornIds: { [string]: true? } = {}
	local wornCount = 0
	local pieceCount, worstGap, worstName = 0, 0, ""
	for _, item in rig:GetChildren() do
		if not item:HasTag(ItemUtil.ITEM_TAG) then
			continue
		end
		wornIds[item.Name] = true
		wornCount += 1
		local pieces: { Instance } = if item:IsA("Folder") then item:GetChildren() else { item }
		for _, piece in pieces do
			local root = if piece:IsA("Model") then piece:FindFirstChild("root") else nil
			local attachment = if root then root:FindFirstChildWhichIsA("Attachment") else nil
			local limb = if attachment then rig:FindFirstChild(attachment.Name) else nil
			if
				not root
				or not root:IsA("BasePart")
				or not limb
				or not limb:IsA("BasePart")
				or limb.Name == HEAD_NAME
			then
				continue
			end
			pieceCount += 1
			local gap = (root.Size - limb.Size).Magnitude
			if gap >= worstGap then
				worstGap = gap
				worstName = `{item.Name} on {limb.Name}: stand-in {getText(root.Size)}, limb {getText(limb.Size)}`
			end
		end
	end
	local notWorn: { string } = {}
	for _, item in look.Items do
		local definitionRes = ItemAppearanceDefinition.get(item.DefinitionId)
		local isFace = definitionRes.IsOk and definitionRes.Value.Type == "Face"
		if not isFace and not wornIds[item.DefinitionId] then
			table.insert(notWorn, item.DefinitionId)
		end
	end
	local scale = body.Scale
	table.insert(
		lines,
		`{body.Name}{if scale then string.format(" (%.3f tall, %.3f broad)", scale.Height, scale.Width) else ""}: {wornCount} items worn`
	)
	if #notWorn > 0 then
		table.insert(lines, `  nothing to sit on: {table.concat(notWorn, ", ")}`)
	end
	local torso = rig:FindFirstChild("UpperTorso")
	local head = rig:FindFirstChild(RigUtil.FAKE_HEAD_NAME)
	if torso and torso:IsA("BasePart") and head and head:IsA("BasePart") then
		table.insert(lines, `  torso {getText(torso.Size)}, head {getText(head.Size)}`)
	end
	if pieceCount > 0 then
		table.insert(
			lines,
			`  {pieceCount} pieces with a stand-in, the furthest off its limb by {string.format("%.3f", worstGap)}`
		)
		table.insert(lines, `  ({worstName})`)
	end
	for _, message in errors do
		table.insert(lines, `  error: {message}`)
	end
	return lines
end

-- the rigs stand side by side in front of the camera + face it
local function getGround(index: number): CFrame
	local camera = Workspace.CurrentCamera
	local cameraCFrame = if camera then camera.CFrame else CFrame.new(0, 20, 0)
	local look = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
	local right = forward:Cross(Vector3.yAxis)
	local middle = cameraCFrame.Position + forward * CAMERA_DISTANCE - Vector3.yAxis * 4
	local position = middle + right * RIG_DISTANCE * (index - (#BODIES + 1) / 2)
	return CFrame.lookAt(position, position - forward)
end
-- Class
-- the look is out in the world of the place, the frame of the story holds what was read back off each rig
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Suit = UILabs.Slider(2, 1, 14, 1),
		HasPatterns = UILabs.Boolean(true),
		IsNeon = UILabs.Boolean(false),
		EyeHue = UILabs.Slider(0.33, 0, 1, 0.01),
	},
}, function(props)
	local suit: number = props.controls.Suit
	local hasPatterns: boolean = props.controls.HasPatterns
	local isNeon: boolean = props.controls.IsNeon
	local eyeHue: number = props.controls.EyeHue
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
			local report: { string } = {}
			for index, body in BODIES do
				local ground = getGround(index)
				local description = HumanoidDescriptionBuilder.new():build()
				local rigF =
					Future.awaitUntil(RigUtil.createFromDescription(description, ground, folder), getIfCanceled)
				description:Destroy()
				if rigF.IsCanceled then
					return
				end
				local rig: Model = rigF.Value
				rig.Name = body.Name
				local rootPart = rig.PrimaryPart
				if rootPart then
					-- nothing holds it up in a place that isn't running
					rootPart.Anchored = true
				end
				local look = newLook(suit, hasPatterns, isNeon, eyeHue, body.Scale)
				local resF = Future.awaitUntil(AppearanceUtil.apply(rig, look), getIfCanceled)
				if resF.IsCanceled then
					return
				end
				-- a body of another size stands at another height
				RigUtil.moveTo(rig, ground)
				for _, line in getReport(rig, body, look, if resF.Value.IsErr then resF.Value.Value else {}) do
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
	end, { suit :: any, hasPatterns, isNeon, eyeHue })

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
