--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local RentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Rent")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local AppHasHudShownContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/HasHudShown")
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionRentedIdsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/RentedIds")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterSelectTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/Types")
export type Character = SessionCharactersContext.Character
export type ActionInfo = CharacterSelectTypes.ActionInfo
export type Properties = CharacterSelectTypes.Properties
-- which of the two panels of the page is up + how it got there
type View = {
	-- how often the list was put up. every time is a new pair of panels: one that's put somewhere is simply there
	Visit: number,
	IsListShown: boolean,
	-- the list is on its way out again, the one move of the page that's slid
	IsLeaving: boolean,
	-- there was no empty row for a new suit: the row that's pressed is the one that's made over
	IsReplacing: boolean,
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local START_VIEW: View = table.freeze({
	Visit = 0,
	IsListShown = false,
	IsLeaving = false,
	IsReplacing = false,
})
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a row is empty until a hero was saved to it: every saved hero has a name
local function getIfEmpty(character: Character): boolean
	return character.Identities.Main.Profile.Name == ""
end

-- what the rows stand on is the panel of the look. one the engine draws takes no color of its own
local function board(props: {
	Position: UDim2,
	Size: UDim2,
	children: { [string]: React.ReactNode }?,
}): React.ReactNode
	local style = React.useContext(StyleContext)
	local panel = style.Panel
	if panel.Type == "Engine" then
		return e("Frame", {
			Position = props.Position,
			Size = props.Size,
			Style = panel.Style,
		}, props.children)
	elseif panel.Type == "Frame" then
		return e("Frame", {
			BackgroundColor3 = panel.BackgroundColor3,
			BackgroundTransparency = panel.BackgroundTransparency,
			BorderColor3 = panel.BorderColor3,
			BorderSizePixel = panel.BorderSizePixel,
			Position = props.Position,
			Size = props.Size,
		}, props.children)
	end
	-- a picture was drawn for the one menu it's the panel of, not to lie under five rows
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = props.Position,
		Size = props.Size,
	}, props.children)
end

-- a box with one word on it, in the dark the engine writes in. left without something to do it's half there
local function button(props: {
	BackgroundColor3: Color3,
	Position: UDim2,
	Size: UDim2,
	Text: string,
	ZIndex: number?,
	OnClick: (() -> ())?,
})
	local style = React.useContext(StyleContext)
	local onClick = props.OnClick
	local transparency = if onClick then 0 else CONSTANTS.DEAD_TRANSPARENCY
	return e("TextButton", {
		Active = onClick ~= nil,
		AutoButtonColor = onClick ~= nil,
		BackgroundColor3 = props.BackgroundColor3,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		FontFace = style.Fonts.Heading,
		Position = props.Position,
		Size = props.Size,
		Text = props.Text,
		TextColor3 = style.Border.Color3,
		TextScaled = true,
		TextTransparency = transparency,
		TextWrapped = true,
		ZIndex = props.ZIndex,
		[React.Event.Activated] = onClick,
	})
end

-- a white button of the page, written on in the font of a row
local function card(
	props: {
		Position: UDim2,
		Text: string,
		-- why the button didn't lead anywhere, said on it in place of what it's for
		Notice: string?,
		OnClick: () -> (),
	}
)
	local style = React.useContext(StyleContext)
	local border = style.Border
	local notice = props.Notice
	return e("TextButton", {
		-- a button that didn't do what it's for is red for as long as it says why
		BackgroundColor3 = if notice then style.Palette.Negative else CONSTANTS.CARD_COLOR,
		BorderColor3 = border.Color3,
		BorderSizePixel = border.SizePixel,
		FontFace = style.Fonts.Body,
		Position = props.Position,
		Size = CONSTANTS.CHOICE_SIZE,
		Text = notice or props.Text,
		TextColor3 = if notice then style.Palette.Text else border.Color3,
		TextScaled = true,
		TextWrapped = true,
		[React.Event.Activated] = props.OnClick,
	})
end

-- a slot: a white bar with the name its hero fights under at the left + what can be done with it at the right
local function row(props: {
	Index: number,
	Text: string,
	children: { [string]: React.ReactNode }?,
})
	local style = React.useContext(StyleContext)
	local border = style.Border
	return e("Frame", {
		BackgroundColor3 = CONSTANTS.CARD_COLOR,
		BorderColor3 = border.Color3,
		BorderSizePixel = border.SizePixel,
		Position = UDim2.fromScale(0, (props.Index - 1) * CONSTANTS.ROW_PITCH),
		Size = CONSTANTS.ROW_SIZE,
	}, {
		Text = e("TextLabel", {
			-- it's a name somebody gave, not a word of the game
			AutoLocalize = false,
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Size = CONSTANTS.NAME_SIZE,
			Text = props.Text,
			TextColor3 = border.Color3,
			TextScaled = true,
			TextWrapped = true,
		}),
		Buttons = e(React.Fragment, {}, props.children),
	})
end

-- the line under the rows: what the list is up for, or why what was asked of a row didn't happen
local function note(props: {
	Text: string?,
	ErrorMessage: string?,
})
	local style = React.useContext(StyleContext)
	local errorMessage = props.ErrorMessage
	return e("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = style.Fonts.Body,
		Position = CONSTANTS.NOTE_POSITION,
		Size = CONSTANTS.NOTE_SIZE,
		Text = errorMessage or props.Text or "",
		TextColor3 = if errorMessage then style.Palette.Negative else style.Palette.Text,
		TextScaled = true,
		TextWrapped = true,
	})
end

-- one of the two panels that swap places: it's put where it stands + slid to wherever it's sent from there
local function mover(props: {
	Position: UDim2,
	Goal: UDim2,
	children: { [string]: React.ReactNode }?,
})
	local style = React.useContext(StyleContext)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local goal = props.Goal
	useTween(frameRef, style.Motion.Slide, {
		Position = goal,
	}, { goal })
	return e("Frame", {
		BackgroundTransparency = 1,
		Position = props.Position,
		ref = frameRef,
		Size = UDim2.fromScale(1, 1),
	}, props.children)
end

-- the page a session starts on: a new suit or one of the saved ones, with the rows behind the second button. there's
-- no way out of it but one of the two
local function creator(props: {
	Characters: { Character },
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
})
	local view: View, setView: (View) -> () = React.useState(START_VIEW)
	local characters = props.Characters
	local isListUp = view.IsListShown and not view.IsLeaving

	local function showList(isReplacing: boolean)
		setView({
			Visit = view.Visit + 1,
			IsListShown = true,
			IsLeaving = false,
			IsReplacing = isReplacing,
		})
	end

	-- a new suit is made in the first row that holds none. with every row taken one of the suits has to go
	local function startNew()
		for _, character in characters do
			if getIfEmpty(character) then
				props.OnAction({
					Type = "Edit",
					CharacterId = character.Id,
				})
				return
			end
		end
		showList(true)
	end

	local rows: { [string]: React.ReactNode } = {}
	for index, character in characters do
		local isEmpty = getIfEmpty(character)
		rows[`Row-{index}`] = e(row, {
			Index = index,
			Text = if isEmpty then CONSTANTS.EMPTY_TEXT else character.Identities.Main.Profile.Name,
		}, {
			Load = e(button, {
				BackgroundColor3 = CONSTANTS.LIST_LOAD_COLOR,
				Position = CONSTANTS.LIST_LOAD_POSITION,
				Size = CONSTANTS.BUTTON_SIZE,
				Text = if view.IsReplacing then CONSTANTS.REPLACE_TEXT else CONSTANTS.LOAD_TEXT,
				-- there's nothing to load from a row nobody was saved to
				OnClick = if view.IsReplacing
					then function()
						props.OnAction({
							Type = "Edit",
							CharacterId = character.Id,
						})
					end
					elseif not isEmpty then function()
						props.OnAction({
							Type = "Select",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
		})
	end

	local panels: { [string]: React.ReactNode } = {}
	-- keyed by the visit, so both panels start out where that visit puts them
	panels[`Panels-{view.Visit}`] = e(React.Fragment, {}, {
		Choice = e(mover, {
			Position = if view.IsListShown then CONSTANTS.CHOICE_AWAY_POSITION else UDim2.new(),
			Goal = if isListUp then CONSTANTS.CHOICE_AWAY_POSITION else UDim2.new(),
		}, {
			New = e(card, {
				Position = CONSTANTS.NEW_POSITION,
				Text = CONSTANTS.NEW_TEXT,
				-- with the list away this button is where a refusal is read
				Notice = if isListUp then nil else props.ErrorMessage,
				OnClick = startNew,
			}),
			LoadSuit = e(card, {
				Position = CONSTANTS.LOAD_SUIT_POSITION,
				Text = CONSTANTS.LOAD_SUIT_TEXT,
				OnClick = function()
					showList(false)
				end,
			}),
		}),
		Loader = e(mover, {
			Position = if view.IsListShown then UDim2.new() else CONSTANTS.LIST_PARKED_POSITION,
			Goal = if isListUp then UDim2.new() else CONSTANTS.LIST_PARKED_POSITION,
		}, {
			Board = e(board, {
				Position = CONSTANTS.LIST_POSITION,
				Size = CONSTANTS.LIST_SIZE,
			}, {
				Rows = e(React.Fragment, {}, rows),
				Note = e(note, {
					Text = if view.IsReplacing then CONSTANTS.REPLACE_NOTE_TEXT else nil,
					ErrorMessage = if isListUp then props.ErrorMessage else nil,
				}),
				Back = e(button, {
					BackgroundColor3 = CONSTANTS.CARD_COLOR,
					Position = CONSTANTS.BACK_POSITION,
					Size = CONSTANTS.LEAVE_SIZE,
					Text = CONSTANTS.BACK_TEXT,
					-- its top edge is over the foot of the note
					ZIndex = 2,
					OnClick = function()
						setView({
							Visit = view.Visit,
							IsListShown = true,
							IsLeaving = true,
							IsReplacing = view.IsReplacing,
						})
					end,
				}),
			}),
		}),
	})

	return e(React.Fragment, {}, {
		-- the page, behind the top bar as well
		Backdrop = e("Frame", {
			Active = true,
			BackgroundColor3 = CONSTANTS.PAGE_COLOR,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, -1),
			Size = UDim2.fromScale(1, 2),
			ZIndex = -1,
		}),
		Panels = e(React.Fragment, {}, panels),
	})
end

-- the same rows over the game, for whoever is played already: a row takes them in or is loaded in their place
local function saves(props: {
	Characters: { Character },
	ActiveCharacterId: string,
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
})
	local style = React.useContext(StyleContext)
	local credits = React.useContext(SessionCreditsContext)
	local rentedIds = React.useContext(SessionRentedIdsContext)
	local characters = props.Characters
	local errorMessage = props.ErrorMessage
	-- the row that was told to keep whoever is played, until the rows say it did or the line under them why it didn't
	local savingId: string?, setSavingId: (string?) -> () = React.useState(nil :: string?)
	React.useEffect(function()
		setSavingId(nil)
		return function() end
	end, { characters :: any, rentedIds })
	React.useEffect(function()
		if errorMessage then
			setSavingId(nil)
		end
		return function() end
	end, { errorMessage })

	-- what a row asks to keep whoever is played: the fee for each thing they still have on of what was rented for
	-- them. the server asks the same of what it holds
	local keepPrice = 0
	for _, character in characters do
		if character.Id == props.ActiveCharacterId then
			keepPrice = RentDefinition.getKeepPrice(rentedIds, character)
		end
	end
	local isAffordable = credits >= keepPrice

	local rows: { [string]: React.ReactNode } = {}
	for index, character in characters do
		local isEmpty = getIfEmpty(character)
		local isPlayed = character.Id == props.ActiveCharacterId
		rows[`Row-{index}`] = e(row, {
			Index = index,
			Text = if character.Id == savingId
				then CONSTANTS.SAVING_TEXT
				elseif isEmpty then CONSTANTS.EMPTY_TEXT
				else character.Identities.Main.Profile.Name,
		}, {
			Save = e(button, {
				BackgroundColor3 = style.Palette.Positive,
				Position = CONSTANTS.SAVE_POSITION,
				Size = CONSTANTS.BUTTON_SIZE,
				Text = CONSTANTS.SAVE_TEXT,
				-- whoever is played is in their own row as they are: there's only something to keep there while they
				-- have something rented on. no row takes them while that can't be paid for
				OnClick = if isAffordable and (not isPlayed or keepPrice > 0)
					then function()
						setSavingId(character.Id)
						props.OnAction({
							Type = "Copy",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
			Load = e(button, {
				BackgroundColor3 = style.Palette.AccentLight,
				Position = CONSTANTS.LOAD_POSITION,
				Size = CONSTANTS.BUTTON_SIZE,
				Text = CONSTANTS.LOAD_TEXT,
				-- there's nothing to load from a row nobody was saved to
				OnClick = if not isEmpty
					then function()
						props.OnAction({
							Type = "Select",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
		})
	end

	return e(board, {
		Position = CONSTANTS.PANEL_POSITION,
		Size = CONSTANTS.PANEL_SIZE,
	}, {
		Rows = e(React.Fragment, {}, rows),
		Note = e(note, {
			Text = if keepPrice > 0
				then string.format(CONSTANTS.KEEP_NOTE_TEXT, keepPrice, keepPrice / RentDefinition.KEEP_PRICE)
				else nil,
			ErrorMessage = errorMessage,
		}),
		Exit = e(button, {
			BackgroundColor3 = style.Palette.Accent,
			Position = CONSTANTS.EXIT_POSITION,
			Size = CONSTANTS.LEAVE_SIZE,
			Text = CONSTANTS.EXIT_TEXT,
			OnClick = function()
				props.OnAction({
					Type = "Exit",
				})
			end,
		}),
	})
end
-- Class
-- the save slots of the game, as the two things the old place drew them as. before the player was in the game it's
-- the page of its creator: a new suit or a saved one. afterwards it's the panel of saved suits over the game, where
-- whoever is played can be kept in a row as well
return function(props: Properties): React.ReactNode
	local characters = React.useContext(SessionCharactersContext)
	local activeCharacterId = React.useContext(SessionActiveCharacterIdContext)
	local hasHudShown = React.useContext(AppHasHudShownContext)
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Creator = not hasHudShown and e(creator, {
				Characters = characters,
				ErrorMessage = props.ErrorMessage,
				OnAction = props.OnAction,
			}),
			Saves = hasHudShown and e(saves, {
				Characters = characters,
				ActiveCharacterId = activeCharacterId,
				ErrorMessage = props.ErrorMessage,
				OnAction = props.OnAction,
			}),
		}
	))
end
