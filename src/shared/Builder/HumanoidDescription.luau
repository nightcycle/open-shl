--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
type AccessoryInfo = {
	AccessoryType: Enum.AccessoryType,
	AssetId: number,
	IsLayered: boolean,
	Order: number?,
	Puffiness: number?,
}
type EquippedEmote = {
	Name: string,
	Slot: number,
}
export type AnimationGroup = "Climb" | "Fall" | "Idle" | "Jump" | "Mood" | "Run" | "Swim" | "Walk"
export type TextureGroup = "Pants" | "Shirt" | "GraphicTShirt"
type BoolGroup = "StaticFacialAnimation" | "UseAvatarSettings"
export type ScaleGroup = "BodyType" | "Depth" | "Head" | "Height" | "Proportion" | "Width"
type HumanoidConfigEntry =
	{
		Type: "BodyColor",
		Group: Enum.BodyPart,
		Color: Color3,
	}
	| {
		Type: "Animation",
		Group: AnimationGroup,
		AssetId: number,
	}
	| {
		Type: "Accessory",
		Info: AccessoryInfo,
	}
	| {
		Type: "BodyPart",
		Group: Enum.BodyPart,
		AssetId: number,
	}
	| {
		Type: "Texture",
		Group: TextureGroup,
		AssetId: number,
	}
	| {
		Type: "Bool",
		Group: BoolGroup,
		Value: boolean,
	}
	| {
		Type: "Emote",
		Name: string,
		AssetIds: { number },
		Slots: { number },
	}
	| {
		Type: "Scale",
		Group: ScaleGroup,
		Value: number,
	}

export type AssetIdOrUrl = string | number
export type Builder = {
	addEmote: (self: Builder, name: string, assetId: AssetIdOrUrl, isEquipped: boolean?) -> Builder,
	addBodyColor: (self: Builder, color: Color3, bodyPart: Enum.BodyPart?) -> Builder,
	addBodyPart: (self: Builder, assetId: AssetIdOrUrl, bodyPart: Enum.BodyPart) -> Builder,
	addAnimation: (self: Builder, assetId: AssetIdOrUrl, group: AnimationGroup) -> Builder,
	addAccessory: (
		self: Builder,
		assetId: AssetIdOrUrl,
		group: Enum.AccessoryType,
		isLayered: boolean?,
		order: number?,
		puffiness: number?
	) -> Builder,
	addTexture: (self: Builder, assetId: AssetIdOrUrl, group: TextureGroup) -> Builder,
	setStaticFacialAnimation: (self: Builder, value: boolean) -> Builder,
	setUseAvatarSettings: (self: Builder, value: boolean) -> Builder,
	addScale: (self: Builder, value: number, group: ScaleGroup) -> Builder,
	build: (self: Builder) -> HumanoidDescription,
}
-- Constants
local MAX_EQUIPPED_EMOTES = 8
local RIGID_ACCESSORY_TYPES: { [Enum.AccessoryType]: boolean } = table.freeze({
	[Enum.AccessoryType.Hat] = true,
	[Enum.AccessoryType.Hair] = true,
	[Enum.AccessoryType.Face] = true,
	[Enum.AccessoryType.Neck] = true,
	[Enum.AccessoryType.Shoulder] = true,
	[Enum.AccessoryType.Front] = true,
	[Enum.AccessoryType.Back] = true,
	[Enum.AccessoryType.Waist] = true,
})
-- Variables
-- References
-- Private Functions
local function filter<V>(entries: { V }, fn: (V) -> boolean): { V }
	local out: { V } = {}
	for _, entry in entries do
		if fn(entry) then
			table.insert(out, entry)
		end
	end
	return out
end
function getAssetId(assetId: AssetIdOrUrl): number
	if type(assetId) == "number" then
		return assetId
	else
		local numStr = string.match(assetId, "%d+")
		local num = tonumber(numStr)
		assert(num, `no assetId found from url "{assetId}"`)
		return num
	end
end

local function toHumanoidDescription(entries: { HumanoidConfigEntry }): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	local accessories: { AccessoryInfo } = {}
	local emotes: { [string]: { number } } = {}
	local equippedEmotes: { EquippedEmote } = {}
	for _, entry in entries do
		if entry.Type == "BodyColor" then
			if entry.Group == Enum.BodyPart.Head then
				desc.HeadColor = entry.Color
			elseif entry.Group == Enum.BodyPart.Torso then
				desc.TorsoColor = entry.Color
			elseif entry.Group == Enum.BodyPart.LeftArm then
				desc.LeftArmColor = entry.Color
			elseif entry.Group == Enum.BodyPart.RightArm then
				desc.RightArmColor = entry.Color
			elseif entry.Group == Enum.BodyPart.LeftLeg then
				desc.LeftLegColor = entry.Color
			elseif entry.Group == Enum.BodyPart.RightLeg then
				desc.RightLegColor = entry.Color
			end
		elseif entry.Type == "BodyPart" then
			if entry.Group == Enum.BodyPart.Head then
				desc.Head = entry.AssetId
			elseif entry.Group == Enum.BodyPart.Torso then
				desc.Torso = entry.AssetId
			elseif entry.Group == Enum.BodyPart.LeftArm then
				desc.LeftArm = entry.AssetId
			elseif entry.Group == Enum.BodyPart.RightArm then
				desc.RightArm = entry.AssetId
			elseif entry.Group == Enum.BodyPart.LeftLeg then
				desc.LeftLeg = entry.AssetId
			elseif entry.Group == Enum.BodyPart.RightLeg then
				desc.RightLeg = entry.AssetId
			end
		elseif entry.Type == "Animation" then
			if entry.Group == "Climb" then
				desc.ClimbAnimation = entry.AssetId
			elseif entry.Group == "Fall" then
				desc.FallAnimation = entry.AssetId
			elseif entry.Group == "Idle" then
				desc.IdleAnimation = entry.AssetId
			elseif entry.Group == "Jump" then
				desc.JumpAnimation = entry.AssetId
			elseif entry.Group == "Mood" then
				desc.MoodAnimation = entry.AssetId
			elseif entry.Group == "Run" then
				desc.RunAnimation = entry.AssetId
			elseif entry.Group == "Swim" then
				desc.SwimAnimation = entry.AssetId
			elseif entry.Group == "Walk" then
				desc.WalkAnimation = entry.AssetId
			end
		elseif entry.Type == "Accessory" then
			local info = entry.Info
			table.insert(accessories, {
				AssetId = info.AssetId,
				AccessoryType = info.AccessoryType,
				IsLayered = info.IsLayered,
				Order = if info.IsLayered then info.Order else nil,
				Puffiness = if info.IsLayered then info.Puffiness else nil,
			})
		elseif entry.Type == "Texture" then
			if entry.Group == "Pants" then
				desc.Pants = entry.AssetId
			elseif entry.Group == "Shirt" then
				desc.Shirt = entry.AssetId
			elseif entry.Group == "GraphicTShirt" then
				desc.GraphicTShirt = entry.AssetId
			elseif entry.Group == "Face" then
				desc.Face = entry.AssetId
			end
		elseif entry.Type == "Bool" then
			if entry.Group == "StaticFacialAnimation" then
				desc.StaticFacialAnimation = entry.Value
			elseif entry.Group == "UseAvatarSettings" then
				desc.UseAvatarSettings = entry.Value
			end
		elseif entry.Type == "Emote" then
			emotes[entry.Name] = table.clone(entry.AssetIds)
			for _, slot in entry.Slots do
				table.insert(equippedEmotes, { Name = entry.Name, Slot = slot })
			end
		elseif entry.Type == "Scale" then
			if entry.Group == "BodyType" then
				desc.BodyTypeScale = entry.Value
			elseif entry.Group == "Depth" then
				desc.DepthScale = entry.Value
			elseif entry.Group == "Head" then
				desc.HeadScale = entry.Value
			elseif entry.Group == "Height" then
				desc.HeightScale = entry.Value
			elseif entry.Group == "Proportion" then
				desc.ProportionScale = entry.Value
			elseif entry.Group == "Width" then
				desc.WidthScale = entry.Value
			end
		end
	end
	desc:SetAccessories(accessories, true)
	desc:SetEmotes(emotes)
	local setEquippedEmotes = (desc.SetEquippedEmotes :: unknown) :: (HumanoidDescription, { EquippedEmote }) -> ()
	setEquippedEmotes(desc, equippedEmotes)
	return desc
end

local function builder(
	priorEntries: { HumanoidConfigEntry },
	fn: (({ HumanoidConfigEntry }) -> { HumanoidConfigEntry })?
): Builder
	priorEntries = table.clone(priorEntries)
	if fn then
		priorEntries = fn(priorEntries)
	end
	TableUtil.deepFreeze(priorEntries)

	local out: Builder = {
		addEmote = function(_self: Builder, name: string, assetIdOrUrl: AssetIdOrUrl, isEquipped: boolean?): Builder
			local assetId = getAssetId(assetIdOrUrl)
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				local slots: { number } = {}
				local occupiedSlots: { [number]: boolean } = {}
				for _, entry in entries do
					if entry.Type == "Emote" then
						if entry.Name == name then
							if isEquipped ~= false then
								slots = table.clone(entry.Slots)
							end
						else
							for _, slot in entry.Slots do
								occupiedSlots[slot] = true
							end
						end
					end
				end
				if isEquipped and #slots == 0 then
					for slot = 1, MAX_EQUIPPED_EMOTES do
						if not occupiedSlots[slot] then
							table.insert(slots, slot)
							break
						end
					end
					assert(#slots > 0, "All eight emote slots are already equipped")
				end
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Emote" or entry.Name ~= name
				end)
				table.insert(entries, {
					Type = "Emote",
					Name = name,
					AssetIds = { assetId },
					Slots = slots,
				})
				return entries
			end)
		end,
		addBodyColor = function(_self: Builder, color: Color3, bodyPart: Enum.BodyPart?): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "BodyColor" or (bodyPart ~= nil and entry.Group ~= bodyPart)
				end)
				local parts: { Enum.BodyPart } = {}
				if bodyPart then
					table.insert(parts, bodyPart)
				else
					parts = Enum.BodyPart:GetEnumItems()
				end
				for _, part in parts do
					table.insert(entries, {
						Type = "BodyColor",
						Color = color,
						Group = part,
					})
				end

				return entries
			end)
		end,
		addBodyPart = function(_self: Builder, assetIdOrUrl: AssetIdOrUrl, bodyPart: Enum.BodyPart): Builder
			local assetId = getAssetId(assetIdOrUrl)
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "BodyPart" or entry.Group ~= bodyPart
				end)
				table.insert(entries, { Type = "BodyPart", Group = bodyPart, AssetId = assetId })
				return entries
			end)
		end,
		addAnimation = function(_self: Builder, assetIdOrUrl: AssetIdOrUrl, group: AnimationGroup): Builder
			local assetId = getAssetId(assetIdOrUrl)
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Animation" or entry.Group ~= group
				end)
				table.insert(entries, { Type = "Animation", Group = group, AssetId = assetId })
				return entries
			end)
		end,
		addAccessory = function(
			_self: Builder,
			assetIdOrUrl: AssetIdOrUrl,
			group: Enum.AccessoryType,
			isLayered: boolean?,
			order: number?,
			puffiness: number?
		): Builder
			local assetId = getAssetId(assetIdOrUrl)
			assert(group ~= Enum.AccessoryType.Unknown, "An accessory must have a known AccessoryType")
			assert(isLayered or RIGID_ACCESSORY_TYPES[group], "This AccessoryType requires a layered accessory")
			assert(isLayered or (order == nil and puffiness == nil), "Rigid accessories cannot have layer settings")
			local info: AccessoryInfo = {
				AssetId = assetId,
				AccessoryType = group,
				IsLayered = isLayered == false,
				Order = if isLayered then order or 0 else nil,
				Puffiness = if isLayered then puffiness or 1 else nil,
			}
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Accessory" or entry.Info.AssetId ~= assetId
				end)
				table.insert(entries, { Type = "Accessory", Info = info })
				return entries
			end)
		end,
		addTexture = function(_self: Builder, assetIdOrUrl: AssetIdOrUrl, group: TextureGroup): Builder
			local assetId = getAssetId(assetIdOrUrl)
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Texture" or entry.Group ~= group
				end)
				table.insert(entries, { Type = "Texture", Group = group, AssetId = assetId })
				return entries
			end)
		end,
		setStaticFacialAnimation = function(_self: Builder, value: boolean): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Bool" or entry.Group ~= "StaticFacialAnimation"
				end)
				table.insert(entries, { Type = "Bool", Group = "StaticFacialAnimation", Value = value })
				return entries
			end)
		end,
		setUseAvatarSettings = function(_self: Builder, value: boolean): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Bool" or entry.Group ~= "UseAvatarSettings"
				end)
				table.insert(entries, { Type = "Bool", Group = "UseAvatarSettings", Value = value })
				return entries
			end)
		end,
		addScale = function(_self: Builder, value: number, group: ScaleGroup): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry): boolean
					return entry.Type ~= "Scale" or entry.Group ~= group
				end)
				table.insert(entries, { Type = "Scale", Group = group, Value = value })
				return entries
			end)
		end,
		build = function(_self: Builder): HumanoidDescription
			return toHumanoidDescription(priorEntries)
		end,
	}
	table.freeze(out)
	return out
end
-- Class
return {
	fromDescription = function(desc: HumanoidDescription): Builder
		local entries: { HumanoidConfigEntry } = {}
		local bodyColors: { [Enum.BodyPart]: Color3 } = {
			[Enum.BodyPart.Head] = desc.HeadColor,
			[Enum.BodyPart.Torso] = desc.TorsoColor,
			[Enum.BodyPart.LeftArm] = desc.LeftArmColor,
			[Enum.BodyPart.RightArm] = desc.RightArmColor,
			[Enum.BodyPart.LeftLeg] = desc.LeftLegColor,
			[Enum.BodyPart.RightLeg] = desc.RightLegColor,
		}
		for group, color in bodyColors do
			table.insert(entries, { Type = "BodyColor", Group = group, Color = color })
		end
		local bodyParts: { [Enum.BodyPart]: number } = {
			[Enum.BodyPart.Head] = desc.Head,
			[Enum.BodyPart.Torso] = desc.Torso,
			[Enum.BodyPart.LeftArm] = desc.LeftArm,
			[Enum.BodyPart.RightArm] = desc.RightArm,
			[Enum.BodyPart.LeftLeg] = desc.LeftLeg,
			[Enum.BodyPart.RightLeg] = desc.RightLeg,
		}
		for group, assetId in bodyParts do
			table.insert(entries, { Type = "BodyPart", Group = group, AssetId = assetId })
		end
		local animations: { [AnimationGroup]: number } = {
			Climb = desc.ClimbAnimation,
			Fall = desc.FallAnimation,
			Idle = desc.IdleAnimation,
			Jump = desc.JumpAnimation,
			Mood = desc.MoodAnimation,
			Run = desc.RunAnimation,
			Swim = desc.SwimAnimation,
			Walk = desc.WalkAnimation,
		}
		for group, assetId in animations do
			table.insert(entries, { Type = "Animation", Group = group :: AnimationGroup, AssetId = assetId })
		end
		local textures: { [TextureGroup]: number } = {
			Pants = desc.Pants,
			Shirt = desc.Shirt,
			GraphicTShirt = desc.GraphicTShirt,
		}
		for group, assetId in textures do
			table.insert(entries, { Type = "Texture", Group = group :: TextureGroup, AssetId = assetId })
		end
		local bools: { [BoolGroup]: boolean } = {
			StaticFacialAnimation = desc.StaticFacialAnimation,
			UseAvatarSettings = desc.UseAvatarSettings,
		}
		for group, value in bools do
			table.insert(entries, { Type = "Bool", Group = group :: BoolGroup, Value = value })
		end
		local scales: { [ScaleGroup]: number } = {
			BodyType = desc.BodyTypeScale,
			Depth = desc.DepthScale,
			Head = desc.HeadScale,
			Height = desc.HeightScale,
			Proportion = desc.ProportionScale,
			Width = desc.WidthScale,
		}
		for group, value in scales do
			table.insert(entries, { Type = "Scale", Group = group :: ScaleGroup, Value = value })
		end
		local accessories: { AccessoryInfo } = desc:GetAccessories(true)
		for _, info in accessories do
			table.insert(entries, { Type = "Accessory", Info = table.clone(info) })
		end
		local equippedEmotes: { EquippedEmote } = desc:GetEquippedEmotes()
		local emotes: { [string]: { number } } = desc:GetEmotes()
		for name, assetIds in emotes do
			local slots: { number } = {}
			for _, equipped in equippedEmotes do
				if equipped.Name == name then
					table.insert(slots, equipped.Slot)
				end
			end
			table.insert(entries, { Type = "Emote", Name = name, AssetIds = table.clone(assetIds), Slots = slots })
		end
		return builder(entries)
	end,
	new = function(): Builder
		return builder({})
	end,
}
