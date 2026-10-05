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
	Position: Vector3,
	Rotation: Vector3,
	Scale: Vector3,
}
type LayeredAccessoryBlob = {
	AssetId: number,
	Order: number,
	AccessoryType: "Pants" | "Shirt",
	Puffiness: string, -- "1.000"
}
type AnimationGroup = "Climb" | "Fall" | "Idle" | "Jump" | "Mood" | "Run" | "Swim" | "Walk"
type ClothingGroup = "Pants" | "Shirt" | "GraphicTShirt"
type BoolGroup = "StaticFacialAnimation" | "UseAvatarSettings"
type ScaleGroup = "BodyType" | "Depth" | "Head" | "Height" | "Proportion" | "Width"
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
		Group: Enum.AccessoryType,
		AssetId: number,
		Puffiness: number?,
		Order: number?,
	}
	| {
		Type: "Clothing",
		Group: ClothingGroup,
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
		AssetId: number,
		IsEquipped: boolean?,
	}
	| {
		Type: "Scale",
	}
export type Builder = {
	addEmote: (self: Builder, name: string, assetId: number) -> Builder,
	addBodyColor: (self: Builder, color: Color3, bodyPart: Enum.BodyPart?) -> Builder,
	build: (self: Builder) -> HumanoidDescription,
}
-- Constants
-- Variables
-- References
-- Private Functions
function filter<V>(entries: { V }, fn: (V) -> V?): { V }
	local out = {}
	for i, v in entries do
		table.insert(out, v)
	end
	if table.isfrozen(entries) then
		table.freeze(out)
	end
	return out
end
function toHumanoidDescription(entries: { HumanoidConfigEntry }): HumanoidDescription
	return
end
function builder(
	priorEntries: { HumanoidConfigEntry },
	fn: (({ HumanoidConfigEntry }) -> { HumanoidConfigEntry })?
): Builder
	priorEntries = table.clone(priorEntries)
	if fn then
		priorEntries = fn(priorEntries)
	end
	TableUtil.deepFreeze(priorEntries)

	local out: Builder = {
		addEmote = function(self: Builder, name: string, assetId: number): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry)
					if entry.Type == "Emote" and entry.Name == name then
						return
					end
					return entry
				end)
				table.insert(entries, {
					Type = "Emote",
					Name = name,
					AssetId = assetId,
				})
				return entries
			end)
		end,
		addBodyColor = function(self: Builder, color: Color3, bodyPart: Enum.BodyPart?): Builder
			return builder(priorEntries, function(entries: { HumanoidConfigEntry }): { HumanoidConfigEntry }
				entries = filter(entries, function(entry: HumanoidConfigEntry)
					if bodyPart then
						if entry.Type == "BodyColor" then
							return
						end
					else
						if entry.Type == "BodyColor" then
							return
						end
					end
					return entry
				end)
				local parts: { Enum.BodyPart } = {}
				if bodyPart then
					table.insert(parts, bodyPart)
				else
					for i, bodyPart in Enum.BodyPart:GetEnumItems() do
						table.insert(parts, bodyPart)
					end
				end
				for i, v in parts do
					table.insert(entries, {
						Type = "BodyColor",
						Color = color,
						Group = v,
					})
				end

				return entries
			end)
		end,
		build = function(self): HumanoidDescription
			return toHumanoidDescription(priorEntries)
		end,
	}
	table.freeze(out)
	return out
end
-- Class
return {
	new = function(): Builder
		return builder({})
	end,
}
