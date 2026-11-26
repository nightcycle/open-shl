--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local EditableCharacterProvider =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/EditableCharacterProvider")
local Page = require("@self/Page")
local Row = require("@self/Row")
local Stage = require("@self/Stage")
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SetIsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetIsHeroFocus")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
local Types = require("@self/Types")
type Character = CharacterType.Character
type Step = Types.Step
type TextFilter = EditorTypes.TextFilter
export type FilteredText = EditorTypes.FilteredText
export type ActionInfo = EditorTypes.ActionInfo
export type Properties = EditorTypes.Properties
-- where the walk is. the draft isn't the walk's: it's the one editor's from the first stop to the last, whichever
-- way the stops are gone through
type Walk = {
	StepIndex: number,
	-- the stop whose page is on its way off the screen, the stop after it was cut to otherwise
	SlidFrom: number?,
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local STEPS: { Step } = {}
for _, page in CONSTANTS.PAGES do
	for index, title in page.Titles do
		table.insert(
			STEPS,
			table.freeze({
				Page = page,
				Index = index,
				Title = title,
			})
		)
	end
end
table.freeze(STEPS)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the identity + the page of the game's editor a stop is about, whenever the walk gets to one
local function focus(props: {
	Step: Step,
})
	local setIsHeroFocus = React.useContext(SetIsHeroFocusContext)
	local setPath = React.useContext(SetPathContext)
	local step = props.Step
	React.useEffect(function()
		-- the identity first: a page of the other one is closed to a path
		if setIsHeroFocus then
			setIsHeroFocus(step.Page.IdentityKey == "Main")
		end
		if setPath then
			setPath(step.Page.Key)
		end
		return function() end
	end, { step })
	return nil
end

-- the pages as the strip they were: a stop that's cut to is simply there, one that's slid to comes up from under the
-- screen while the page before it leaves at the top
local function strip(props: {
	Step: Step,
	LeavingStep: Step?,
	Notice: string?,
	FilteredText: FilteredText?,
	IsPeaceful: boolean,
	OnPeaceful: (isPeaceful: boolean) -> (),
	OnForward: (draft: Character) -> (),
	OnPurchase: (id: string) -> (),
})
	local style = React.useContext(StyleContext)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local leavingStep = props.LeavingStep
	useTween(frameRef, style.Motion.Slide, {
		Position = if leavingStep then UDim2.fromScale(0, -1) else UDim2.new(),
	}, {})
	return e("Frame", {
		BackgroundTransparency = 1,
		ref = frameRef,
		Size = UDim2.fromScale(1, 1),
	}, {
		Leaving = leavingStep and e(
			Page,
			{
				Step = leavingStep,
			} :: Page.Properties
		),
		Page = e(
			Page,
			{
				Position = if leavingStep then UDim2.fromScale(0, 1) else nil,
				Step = props.Step,
				Notice = props.Notice,
				FilteredText = props.FilteredText,
				IsPeaceful = props.IsPeaceful,
				OnPeaceful = props.OnPeaceful,
				OnForward = props.OnForward,
				OnPurchase = props.OnPurchase,
			} :: Page.Properties
		),
	})
end

-- the bar the mannequin is turned with. it's parked under the screen + comes up the first time the booth shows
local function rotateBar(props: {
	IsUp: boolean,
	OnTurn: (direction: number) -> (),
	OnReset: () -> (),
})
	local style = React.useContext(StyleContext)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local isUp = props.IsUp
	useTween(frameRef, style.Motion.Slide, {
		Position = if isUp then CONSTANTS.ROTATE_POSITION else CONSTANTS.ROTATE_PARKED_POSITION,
	}, { isUp })
	-- a component of its own can't be reached to be moved, so the bar rides on a frame that can
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = CONSTANTS.ROTATE_PARKED_POSITION,
		ref = frameRef,
		Size = CONSTANTS.ROTATE_SIZE,
		ZIndex = 2,
	}, {
		Bar = e(
			Row,
			{
				BackgroundColor3 = style.Palette.Accent,
				BackgroundTransparency = CONSTANTS.ROTATE_TRANSPARENCY,
				Size = UDim2.fromScale(1, 1),
				Text = CONSTANTS.ROTATE_TEXT,
				LeftPosition = CONSTANTS.ROW_LEFT_POSITION,
				RightPosition = CONSTANTS.ROW_RIGHT_POSITION,
				ArrowSize = CONSTANTS.ROW_ARROW_SIZE,
				NamePosition = CONSTANTS.ROW_NAME_POSITION,
				NameSize = CONSTANTS.ROW_NAME_SIZE,
				OnStep = props.OnTurn,
				OnName = props.OnReset,
			} :: Row.Properties
		),
	})
end

local function walker(props: Properties)
	local style = React.useContext(StyleContext)
	local walk: Walk, setWalk: (Walk) -> () = React.useState(function(): Walk
		return {
			StepIndex = 1,
		}
	end)
	-- how far the mannequin is turned, a step back leaves it the way it stands
	local turn, setTurn = React.useState(0)
	-- whether the player sits fights out once the walk is through. it's nothing of the draft: the walk starts out
	-- the way the player is
	local isPeaceful, setIsPeaceful = React.useState(props.IsPeaceful == true)
	local stepIndex = walk.StepIndex
	local step = STEPS[stepIndex]
	local isRestart = stepIndex <= CONSTANTS.RESTART_STEP_COUNT

	local function goOn(draft: Character)
		if props.IsSaving then
			return
		end
		-- the last stop is left into the game, as what was made. the mode is the player's + not the character's, so
		-- it's asked for by itself, ahead of the character it's first played in
		if stepIndex == #STEPS then
			props.OnAction({
				Type = "SetPeaceful",
				IsPeaceful = isPeaceful,
			})
			props.OnAction({
				Type = "Save",
				Character = draft,
			})
			return
		end
		-- the walk goes on without the answer: what it opens shows up on its row whenever it's in
		if step.Page.IsGroupAsked then
			props.OnAction({
				Type = "CheckGroupPerk",
			})
		end
		setWalk({
			StepIndex = stepIndex + 1,
			SlidFrom = if step.Page.IsSlidingOut and STEPS[stepIndex + 1].Page ~= step.Page then stepIndex else nil,
		})
	end

	-- a step back only shows the stop before again: whatever was picked, there or on a stop after it, stays picked.
	-- from the first stops there's nothing to go back to: what was made so far is given up
	local function goBack()
		if props.IsSaving then
			return
		end
		if isRestart then
			props.OnAction({
				Type = "Exit",
			})
			return
		end
		setWalk({
			StepIndex = stepIndex - 1,
		})
	end

	local strips: { [string]: React.ReactNode } = {}
	-- keyed by the stop, so every stop starts out where a strip is put + none of them is carried over
	strips[`Strip-{stepIndex}`] = e(strip, {
		Step = step,
		LeavingStep = if walk.SlidFrom then STEPS[walk.SlidFrom] else nil,
		Notice = props.ErrorMessage,
		FilteredText = props.FilteredText,
		IsPeaceful = isPeaceful,
		OnPeaceful = setIsPeaceful,
		OnForward = goOn,
		OnPurchase = function(id: string)
			props.OnAction({
				Type = "Purchase",
				Id = id,
			})
		end,
	})

	return e(React.Fragment, {}, {
		-- one editor for the whole of the walk: it starts out from what's stored + only the way out starts it over
		Editor = e(EditableCharacterProvider, {
			FilteredText = props.FilteredText,
			OnFilterText = function(filter: TextFilter)
				props.OnAction({
					Type = "FilterText",
					Filter = filter,
				})
			end,
		}, {
			Focus = e(focus, {
				Step = step,
			}),
			Stage = e(Stage, {
				Turn = turn,
			}),
			Strips = e(React.Fragment, {}, strips),
		}),
		RotateBar = e(rotateBar, {
			IsUp = step.Page.Kind ~= "Cover",
			OnTurn = function(direction: number)
				setTurn(turn + direction * CONSTANTS.TURN_STEP_RAD)
			end,
			OnReset = function()
				setTurn(0)
			end,
		}),
		Back = e("TextButton", {
			BackgroundColor3 = style.Palette.Accent,
			BorderSizePixel = 0,
			FontFace = style.Fonts.Heading,
			Position = CONSTANTS.BACK_POSITION,
			Size = CONSTANTS.BACK_SIZE,
			Text = if isRestart then CONSTANTS.RESTART_TEXT else CONSTANTS.BACK_TEXT,
			TextColor3 = style.Palette.TextOnAccent,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = 2,
			[React.Event.Activated] = goBack,
		}),
	})
end
-- Class
-- the editor as a walk: one page at a time in one direction, the mannequin of the booth in the gap between the two
-- panels of a page. there's a way back one stop at a time, which takes nothing back, + none ahead but the button of
-- the page. it ends on its last page, which saves
return function(props: Properties): React.ReactNode
	local character = React.useContext(CharacterContext)
	local walkers: { [string]: React.ReactNode } = {}
	-- keyed by the character, so another one is walked from the start
	walkers[`Walker-{character.Id}`] = e(walker, props)
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- what's behind the booth for as long as it isn't there yet
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = CONSTANTS.COVER_COLOR,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Walkers = e(React.Fragment, {}, walkers),
			-- nothing is pressed while the draft is on its way, what changed in the meantime wouldn't be stored
			Blocker = props.IsSaving and e("Frame", {
				Active = true,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10,
			}),
		}
	))
end
