--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local BalanceCounter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BalanceCounter")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
-- "Toggle" is the button the drawer is opened + shut with, "Shop" the one under the balance. the rest are its lines
export type ActionType = "Toggle" | "Swap" | "ToggleMode" | "ToggleMask" | "Reset" | "NewCharacter" | "Saves" | "Shop"
export type ActionInfo = {
	Type: ActionType,
}
export type Properties = RobloxComponents.FrameProperties & {
	IsOpen: boolean,
	-- the button of the shop is also the way back out of it
	IsShopOpen: boolean,
	-- if the avatar is the hero right now. left out for as long as there's no avatar to say
	IsHero: boolean?,
	-- its player sits fights out
	IsPeaceful: boolean,
	-- what can't be pressed right now: it's drawn half gone + does nothing
	Dead: { [ActionType]: boolean }?,
	OnAction: (ActionInfo) -> (),
}
-- what one button is drawn with, the rest of it is the same for all of them
type ButtonInfo = {
	Type: ActionType,
	Position: UDim2,
	Size: UDim2,
	Text: string,
	BackgroundColor3: Color3,
	BackgroundTransparency: number,
	BorderSizePixel: number,
	TextColor3: Color3,
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the hud of the first game: words on boxes. one drawer on the left edge holds every way out of playing, the balance
-- + the way to more of it sit under the ticker. nothing of it travels, the drawer is put where it's seen or where it
-- isn't
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local credits = React.useContext(SessionCreditsContext)
	local palette = style.Palette
	local border = style.Border
	local dead = props.Dead

	local function button(info: ButtonInfo): React.ReactNode
		-- one that's of no use is a label: nothing darkens under a press that does nothing
		if dead and dead[info.Type] then
			return e("TextLabel", {
				BackgroundColor3 = info.BackgroundColor3,
				BackgroundTransparency = 1 - (1 - info.BackgroundTransparency) * (1 - CONSTANTS.DEAD_FADE),
				BorderColor3 = border.Color3,
				BorderSizePixel = info.BorderSizePixel,
				FontFace = style.Fonts.Body,
				Position = info.Position,
				Size = info.Size,
				Text = info.Text,
				TextColor3 = info.TextColor3,
				TextScaled = true,
				TextTransparency = CONSTANTS.DEAD_FADE,
				TextWrapped = true,
			})
		end
		return e("TextButton", {
			BackgroundColor3 = info.BackgroundColor3,
			BackgroundTransparency = info.BackgroundTransparency,
			BorderColor3 = border.Color3,
			BorderSizePixel = info.BorderSizePixel,
			FontFace = style.Fonts.Body,
			Position = info.Position,
			Size = info.Size,
			Text = info.Text,
			TextColor3 = info.TextColor3,
			TextScaled = true,
			TextWrapped = true,
			[React.Event.Activated] = function()
				props.OnAction({
					Type = info.Type,
				})
			end,
		})
	end
	-- a line of the drawer. it has no box of its own, only a place for what's on it
	local function line(y: number, children: { [string]: React.ReactNode }): React.ReactNode
		return e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(CONSTANTS.LINE_X, y),
			Size = CONSTANTS.LINE_SIZE,
		}, children)
	end
	-- what a line is for, read up against the button that does it
	local function label(text: string): React.ReactNode
		return e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Size = CONSTANTS.LABEL_SIZE,
			Text = text,
			TextColor3 = palette.Text,
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
	-- the blue button at the end of a line, with the edge the engine gives a box
	local function lineButton(actionType: ActionType, text: string): React.ReactNode
		return button({
			Type = actionType,
			Position = CONSTANTS.BUTTON.Position,
			Size = CONSTANTS.BUTTON.Size,
			Text = text,
			BackgroundColor3 = palette.Field,
			BackgroundTransparency = CONSTANTS.BUTTON_TRANSPARENCY,
			BorderSizePixel = border.SizePixel,
			TextColor3 = palette.Text,
		})
	end

	local isHero = props.IsHero
	local swapText = if isHero == nil
		then CONSTANTS.SWAP_TEXT
		elseif isHero then CONSTANTS.SWAP_TO_SECRET_TEXT
		else CONSTANTS.SWAP_TO_HERO_TEXT

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Drawer = e("Frame", {
				BackgroundTransparency = 1,
				Position = if props.IsOpen then CONSTANTS.OPEN_POSITION else CONSTANTS.SHUT_POSITION,
				Size = UDim2.fromScale(1, 1),
			}, {
				Body = e("Frame", {
					BackgroundColor3 = palette.Field,
					BackgroundTransparency = CONSTANTS.BODY_TRANSPARENCY,
					BorderSizePixel = 0,
					Position = CONSTANTS.BODY.Position,
					Size = CONSTANTS.BODY.Size,
				}, {
					SwapLine = line(CONSTANTS.SWAP_LINE_Y, {
						Label = label(swapText),
						Button = lineButton("Swap", CONSTANTS.SWAP_BUTTON_TEXT),
					}),
					ModeLine = line(CONSTANTS.MODE_LINE_Y, {
						Label = label(CONSTANTS.MODE_TEXT),
						Button = lineButton(
							"ToggleMode",
							if props.IsPeaceful then CONSTANTS.PEACEFUL_TEXT else CONSTANTS.FIGHTING_TEXT
						),
					}),
					MaskLine = line(CONSTANTS.MASK_LINE_Y, {
						Label = label(CONSTANTS.MASK_TEXT),
						Button = lineButton("ToggleMask", CONSTANTS.MASK_BUTTON_TEXT),
					}),
					ResetLine = line(CONSTANTS.RESET_LINE_Y, {
						Reset = button({
							Type = "Reset",
							Position = CONSTANTS.RESET.Position,
							Size = CONSTANTS.RESET.Size,
							Text = CONSTANTS.RESET_TEXT,
							BackgroundColor3 = palette.Negative,
							BackgroundTransparency = CONSTANTS.RESET_TRANSPARENCY,
							BorderSizePixel = border.SizePixel,
							TextColor3 = palette.Text,
						}),
						NewCharacter = button({
							Type = "NewCharacter",
							Position = CONSTANTS.NEW_CHARACTER.Position,
							Size = CONSTANTS.NEW_CHARACTER.Size,
							Text = CONSTANTS.NEW_CHARACTER_TEXT,
							BackgroundColor3 = palette.Negative,
							BackgroundTransparency = CONSTANTS.RESET_TRANSPARENCY,
							BorderSizePixel = border.SizePixel,
							TextColor3 = palette.Text,
						}),
					}),
					SavesLine = line(CONSTANTS.SAVES_LINE_Y, {
						Saves = button({
							Type = "Saves",
							Position = CONSTANTS.SAVES.Position,
							Size = CONSTANTS.SAVES.Size,
							Text = CONSTANTS.SAVES_TEXT,
							BackgroundColor3 = palette.Accent,
							BackgroundTransparency = 0,
							BorderSizePixel = 0,
							TextColor3 = CONSTANTS.SAVES_TEXT_COLOR,
						}),
					}),
				}),
				-- it says the same whether the drawer is out or not
				Menu = button({
					Type = "Toggle",
					Position = CONSTANTS.MENU.Position,
					Size = CONSTANTS.MENU.Size,
					Text = CONSTANTS.MENU_TEXT,
					BackgroundColor3 = palette.Accent,
					BackgroundTransparency = CONSTANTS.MENU_TRANSPARENCY,
					BorderSizePixel = 0,
					TextColor3 = palette.TextOnAccent,
				}),
			}),
			Balance = e(
				BalanceCounter,
				{
					Position = CONSTANTS.BALANCE.Position,
					Size = CONSTANTS.BALANCE.Size,
					TextWrapped = true,
					Currency = PseudoEnum.Currency.Credits,
					Balance = credits,
				} :: BalanceCounter.Properties
			),
			-- the box the panel of the shop opens in, all this draws of it is the button that hangs off its top
			Shop = e("Frame", {
				BackgroundTransparency = 1,
				Position = CONSTANTS.SHOP.Position,
				Size = CONSTANTS.SHOP.Size,
			}, {
				Button = button({
					Type = "Shop",
					Position = CONSTANTS.SHOP_BUTTON.Position,
					Size = CONSTANTS.SHOP_BUTTON.Size,
					Text = if props.IsShopOpen then CONSTANTS.SHOP_OPEN_TEXT else CONSTANTS.SHOP_TEXT,
					BackgroundColor3 = palette.Accent,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					TextColor3 = CONSTANTS.SHOP_TEXT_COLOR,
				}),
			}),
		}
	))
end
