--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
local ConfigurePanel = require("@self/ConfigurePanel")
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local ItemList = require("@self/ItemList")
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
-- Hooks
local useArtifactScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useArtifactScene")
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
export type HiddenTag = AppearanceType.HiddenTag
export type ActionInfo =
	{
		Type: "AddItem",
		ItemDefinition: ItemDefinition,
	}
	| {
		Type: "RemoveItem",
		ItemDefinition: ItemDefinition,
	}
	| {
		Type: "SetTagVisibility",
		Tag: HiddenTag,
		IsVisible: boolean,
	}
	| {
		Type: "Exit",
	}

export type Properties = Frame.Properties & {
	ItemDefinitions: { ItemDefinition },
	OnAction: (ActionInfo) -> (),
}
-- Constants
local ROTATION_INC_DEG = 45
-- Variables
-- References
-- Private Functions
local e = React.createElement
function scene(props: {})
	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local rotationDeg, setRotationDeg = React.useState(0)
	local artifactScene, refreshScene = useArtifactScene()
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport or not artifactScene then
			return function() end
		end
		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")
		local cleanUp: () -> () = function() end
		task.spawn(function()
			assert(artifactScene.IsAlive, `bad scene`)
			artifactScene.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = artifactScene.CameraMount.CFrame
			camera.Parent = viewport
		end)
		return function()
			cleanUp()
			worldModel:Destroy()
			camera:Destroy()
			refreshScene()
		end
	end, { viewportRef.current :: any })
	React.useEffect(function()
		if artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone then
			task.spawn(function()
				RigUtil.moveTo(
					artifactScene.Rig.Value,
					artifactScene.RigAnchor.CFrame * CFrame.Angles(0, math.rad(rotationDeg), 0)
				)
			end)
		end
	end, { rotationDeg :: any, artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone })

	return e(React.Fragment, {}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				BackgroundTransparency = 1,
				ref = viewportRef,
				Size = UDim2.fromScale(1, 1),
			} :: ViewportFrame.Properties
		),

		TurnCharacter = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.225, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Right = artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone and e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = ">",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg + ROTATION_INC_DEG)
				end,
			}),

			Left = artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone and e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "<",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg - ROTATION_INC_DEG)
				end,
			}),
		}),
	})
end
-- Class
return function(props: Properties)
	local selectedItem: ItemDefinition?, setSelectedItem: (ItemDefinition?) -> () =
		React.useState(nil :: ItemDefinition?)
	local groups = React.useMemo(function(): { ItemList.RarityItemGroup }
		local rarityGroups: { [PseudoEnum.Rarity]: { ItemDefinition } } = {}
		for i, itemDef in props.ItemDefinitions do
			if itemDef.Rarity then
				local group = rarityGroups[itemDef.Rarity] or {}
				rarityGroups[itemDef.Rarity] = group

				table.insert(group, itemDef)
			else
				warn(`no rarity for "{itemDef.Id}"`)
			end
		end
		local out: { ItemList.RarityItemGroup } = {}
		for rarity, defs in rarityGroups do
			table.insert(
				out,
				table.freeze({
					Rarity = rarity :: PseudoEnum.Rarity,
					ItemDefinitions = table.freeze(defs),
				})
			)
		end

		table.sort(out, function(a: ItemList.RarityItemGroup, b: ItemList.RarityItemGroup)
			local aValue = PseudoEnum.getValueFromEnumItem("Rarity", (a.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			local bValue = PseudoEnum.getValueFromEnumItem("Rarity", (b.Rarity or "VeryCommon") :: PseudoEnum.Rarity)
			return aValue < bValue
		end)
		table.freeze(out)
		return out
	end, { props.ItemDefinitions })

	return e(Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Scene = e(scene, {}),
			ConfigurePanel = selectedItem and e(
				ConfigurePanel,
				{
					SelectedItemDefinition = selectedItem,
					AnchorPoint = Vector2.new(1, 0.5),
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = UDim2.fromScale(0.95, 0.5),
					Size = UDim2.fromScale(0.3, 0.8),
					SetVisibility = function(tag: HiddenTag, toVisibility: boolean)
						props.OnAction({
							Type = "SetTagVisibility",
							Tag = tag,
							IsVisible = toVisibility,
						})
					end,
					OnRemove = function(itemDef: ItemDefinition)
						props.OnAction({
							Type = "RemoveItem",
							ItemDefinition = itemDef,
						})
					end,
					OnWear = function(itemDef: ItemDefinition)
						props.OnAction({
							Type = "AddItem",
							ItemDefinition = itemDef,
						})
					end,
				} :: ConfigurePanel.Properties
			),
			ItemList = e(
				ItemList,
				{
					SelectedItemDefinition = selectedItem,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0.05, 0.5),
					Size = UDim2.fromScale(0.3, 0.8),
					ItemGroups = groups,
					OnClick = function(item: ItemDefinition)
						if item == selectedItem then
							setSelectedItem(nil)
						else
							setSelectedItem(item)
						end
					end,
				} :: ItemList.Properties
			),
			Exit = e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.3,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.9),
				Size = UDim2.fromScale(0.15, 0.1),
				Text = "Exit",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Exit",
					})
				end,
			}),
		}
	))
end
