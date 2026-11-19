--!strict
-- Services
-- Packages
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
type Appearance = AppearanceType.Appearance
type Scale = AppearanceType.Scale
type Builder = HumanoidDescriptionBuilder.Builder
-- how far a body leans to the two taller builds a description knows
type Build = {
	BodyType: number,
	Proportion: number,
}
-- the color of a body that's bare + the parts of it each category of clothing puts skin on
type Bare = {
	Color: Color3,
	Group: AppearanceType.ItemGroup,
	Parts: { [string]: { Enum.BodyPart } },
}
-- Constants
local HEAD_NAME = "Head"
-- the pieces of a game are fitted to the body it builds. a game that names no build has the one a description comes
-- with, which is the body the pieces of shl2 were fitted to
local BUILD: Build? = GameDefinition.tune(nil :: Build?, {
	-- the plain block body: next to it the one a description comes with has arms a quarter + legs nearly a third longer
	shl3 = table.freeze({ BodyType = 0, Proportion = 0 }),
})
-- where a body with nothing on is a mannequin: its torso + arms are only skin under a shirt, its legs under pants. a
-- game that names no such color has skin all over
local BARE: Bare? = GameDefinition.tune(nil :: Bare?, {
	shl3 = table.freeze({
		Color = Color3.fromRGB(159, 161, 172),
		Group = "clothing" :: AppearanceType.ItemGroup,
		Parts = table.freeze({
			shirts = table.freeze({ Enum.BodyPart.Torso, Enum.BodyPart.LeftArm, Enum.BodyPart.RightArm }),
			pants = table.freeze({ Enum.BodyPart.LeftLeg, Enum.BodyPart.RightLeg }),
		}),
	}),
})
-- the sizes a body can have are the game's own, in a game without any every body is the size it comes in
local SCALE = CharacterEditorDefinition.SCALE
local SCALE_EPSILON = CharacterEditorDefinition.SCALE_EPSILON
-- what a part of the body carries while a worn piece stands for it: how see-through it was until the piece went on
local SHOWN_TRANSPARENCY_ATTRIBUTE = "ShownTransparency"
-- Variables
-- References
-- Private Functions
-- a look that was never given a size, or holds one its game doesn't offer, has the size a body starts at
local function getScale(appearance: Appearance?): Scale?
	if not SCALE then
		return nil
	end
	local scale = if appearance then appearance.Scale else nil
	if not scale then
		return SCALE.Default
	end
	local isOffered = false
	for _, height in SCALE.Heights do
		isOffered = isOffered or math.abs(scale.Height - height) < SCALE_EPSILON
	end
	if not isOffered then
		return SCALE.Default
	end
	for _, ratio in SCALE.WidthRatios do
		if math.abs(scale.Width / scale.Height - ratio) < SCALE_EPSILON then
			return scale
		end
	end
	return SCALE.Default
end

local function getIfWorn(appearance: Appearance, group: AppearanceType.ItemGroup, category: string): boolean
	for _, item in appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if
			itemDefIndexRes.IsOk
			and itemDefIndexRes.Value.Group == group
			and itemDefIndexRes.Value.Category == category
		then
			return true
		end
	end
	return false
end

-- a head grows with the height of its body + all but keeps its size as the body broadens
local function getHeadScale(scale: Scale): number
	return scale.Height * (scale.Width - 0.05) * (0.925 / scale.Width ^ 1.075)
end
-- Class
local Util = {}

-- the body of the game onto a description, in the size of the look where the game has sizes
function Util.describe(builder: Builder, appearance: Appearance?): Builder
	if BUILD then
		builder = builder:addScale(BUILD.BodyType, "BodyType"):addScale(BUILD.Proportion, "Proportion")
	end
	local scale = getScale(appearance)
	if scale then
		builder = builder
			:addScale(scale.Height, "Height")
			:addScale(scale.Width, "Width")
			-- a body is as deep as it's broad
			:addScale(scale.Width, "Depth")
			:addScale(getHeadScale(scale), "Head")
	end
	return builder
end

-- the color of a bare body onto the parts of a description no clothing of the look puts skin on. a suit covers them
-- anyway, the head is skin whatever is worn
function Util.describeBare(builder: Builder, appearance: Appearance): Builder
	if not BARE then
		return builder
	end
	for category, bodyParts in BARE.Parts do
		if getIfWorn(appearance, BARE.Group, category) then
			continue
		end
		for _, bodyPart in bodyParts do
			builder = builder:addBodyColor(BARE.Color, bodyPart)
		end
	end
	return builder
end

-- a piece that stands for the part of the body it's worn on is all there is to see of it. the part stays where it is,
-- the piece + the rest of the body hang off it
function Util.hide(limb: BasePart)
	-- under two pieces it goes back to how it was before the first
	if limb:GetAttribute(SHOWN_TRANSPARENCY_ATTRIBUTE) == nil then
		limb:SetAttribute(SHOWN_TRANSPARENCY_ATTRIBUTE, limb.Transparency)
	end
	limb.Transparency = 1
end

-- every part of the body is drawn the way it was again: whatever stood for one has come off
function Util.show(rig: Model)
	for _, limb in rig:GetChildren() do
		local transparency = limb:GetAttribute(SHOWN_TRANSPARENCY_ATTRIBUTE)
		if limb:IsA("BasePart") and type(transparency) == "number" then
			limb.Transparency = transparency
			limb:SetAttribute(SHOWN_TRANSPARENCY_ATTRIBUTE, nil)
		end
	end
end

-- how much of a piece worn on that part of the body is left on the body of the look, along each axis of the part.
-- nil in a game without body sizes: every piece is worn the size it was made
function Util.getFit(appearance: Appearance, limbName: string): Vector3?
	local scale = getScale(appearance)
	if not scale then
		return nil
	end
	-- a head keeps its shape
	if limbName == HEAD_NAME then
		return Vector3.one * getHeadScale(scale)
	end
	return Vector3.new(scale.Width, scale.Height, scale.Width)
end

return Util
