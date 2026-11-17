--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local QuestDefinition = require("@game/ReplicatedStorage/Shared/Definition/Quest")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
type QuestState = ParentComponent.QuestState
type Status = "Active" | "Succeeded" | "Failed" | "None"
-- Constants
local QUEST_TYPES: { PseudoEnum.QuestType } = table.clone(PseudoEnum.getEnumItems("QuestType"))
local STATUSES: { Status } = { "Active", "Succeeded", "Failed", "None" }
local FIND_ITEM_NAME = QuestDefinition.FIND_ITEMS[1]
local TARGET_ALIAS = QuestDefinition.getTargetAlias(nil, "Player1")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		QuestType = UILabs.Choose(QUEST_TYPES),
		Status = UILabs.Choose(STATUSES),
		SecondsRemaining = UILabs.Slider(QuestDefinition.DURATION, 0, QuestDefinition.DURATION, 1),
	},
}, function(props)
	local questType: PseudoEnum.QuestType = props.controls.QuestType :: PseudoEnum.QuestType
	local status: Status = props.controls.Status :: Status
	local secondsRemaining: number = props.controls.SecondsRemaining
	local isCanceled, setIsCanceled = React.useState(false)
	React.useEffect(function()
		setIsCanceled(false)
		return function() end
	end, { questType :: any, status })

	local quest = React.useMemo(function(): QuestState?
		if status == "None" then
			return nil
		end
		local goalName: string? = nil
		if questType == PseudoEnum.QuestType.Find then
			goalName = FIND_ITEM_NAME
		elseif questType == PseudoEnum.QuestType.Target then
			goalName = TARGET_ALIAS
		end
		local instructionRes = QuestDefinition.formatInstruction(questType, goalName)
		if instructionRes.IsErr then
			warn(`instruction err: {instructionRes.Value}`)
			return nil
		end
		return {
			Type = questType,
			Instruction = instructionRes.Value,
			SecondsRemaining = secondsRemaining,
			Status = if isCanceled then "Failed" else status,
		}
	end, { questType :: any, status, secondsRemaining, isCanceled })

	return e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ClipsDescendants = true, -- the banner hides above the frame
			Quest = quest,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "Cancel" then
					setIsCanceled(true)
				end
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)
end)
