--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local Types = {}

-- a colour by the part it plays, so a widget asks for what it draws + not for a blue
export type Palette = {
	Accent: Color3, -- what's picked, a title or what a title stands on
	AccentLight: Color3, -- a bar or a fill
	Field: Color3, -- what a panel is filled with
	FieldAlt: Color3, -- a cell, a card or a cover on a field
	Text: Color3, -- what's read on a field
	TextStrong: Color3, -- what has to stand out on one
	TextOnAccent: Color3,
	Positive: Color3, -- a yes, a gain or what's healthy
	Negative: Color3,
	Warning: Color3,
}
Types.Palette = Type.strictInterface({
	Accent = Type.Color3,
	AccentLight = Type.Color3,
	Field = Type.Color3,
	FieldAlt = Type.Color3,
	Text = Type.Color3,
	TextStrong = Type.Color3,
	TextOnAccent = Type.Color3,
	Positive = Type.Color3,
	Negative = Type.Color3,
	Warning = Type.Color3,
})

export type Fonts = {
	Heading: Font, -- a title, a tab or a caption
	Body: Font, -- what's read + what a button says
	Note: Font, -- the small print
}
Types.Fonts = Type.strictInterface({
	Heading = Type.Font,
	Body = Type.Font,
	Note = Type.Font,
})

-- for a text that isn't scaled to its box
export type TextSizes = {
	Body: number,
	Button: number,
	Note: number,
}
Types.TextSizes = Type.strictInterface({
	Body = Type.numberPositive,
	Button = Type.numberPositive,
	Note = Type.numberPositive,
})

export type Stroke = {
	Color3: Color3,
	Thickness: number,
	Transparency: number,
}
Types.Stroke = Type.strictInterface({
	Color3 = Type.Color3,
	Thickness = Type.numberPositive,
	Transparency = Type.numberConstrained(0, 1),
})

-- the edge of whatever is drawn as a box
export type Border = {
	Color3: Color3,
	SizePixel: number,
	CornerRadius: UDim?, -- left out, a box keeps its corners
	Stroke: Stroke?, -- left out, there's no outline beyond the border
}
Types.Border = Type.strictInterface({
	Color3 = Type.Color3,
	SizePixel = Type.numberMin(0),
	CornerRadius = Type.optional(Type.UDim),
	Stroke = Type.optional(Types.Stroke),
})

-- a part of a picture or a frame, in scale of it
export type Area = {
	Position: UDim2,
	Size: UDim2,
}
Types.Area = Type.strictInterface({
	Position = Type.UDim2,
	Size = Type.UDim2,
})

-- where a part of a widget is on it, in scale of it
export type Placement = {
	AnchorPoint: Vector2?, -- left out, it's put by its top left corner
	Position: UDim2,
	Size: UDim2,
}
Types.Placement = Type.strictInterface({
	AnchorPoint = Type.optional(Type.Vector2),
	Position = Type.UDim2,
	Size = Type.UDim2,
})

-- what a panel is drawn as when it has no art of its own: a box, one picture laid over the frame that carries it, or
-- one of the panels the engine draws by itself
export type PanelLook =
	{
		Type: "Frame",
		BackgroundColor3: Color3,
		BackgroundTransparency: number,
		BorderColor3: Color3,
		BorderSizePixel: number,
	}
	| {
		Type: "Image",
		Image: string,
		ImageColor3: Color3,
		ScaleType: Enum.ScaleType,
		SliceCenter: Rect?, -- only a sliced picture has one
		-- the picture is drawn larger than the panel that's seen on it, this is where it leaves room for what's held
		Body: Area,
	}
	| {
		Type: "Engine",
		-- the engine draws its own art for one + takes no color for it
		Style: Enum.FrameStyle,
	}
Types.PanelLook = Type.union(
	Type.strictInterface({
		Type = Type.literal("Frame"),
		BackgroundColor3 = Type.Color3,
		BackgroundTransparency = Type.numberConstrained(0, 1),
		BorderColor3 = Type.Color3,
		BorderSizePixel = Type.numberMin(0),
	}),
	Type.strictInterface({
		Type = Type.literal("Image"),
		Image = Type.string,
		ImageColor3 = Type.Color3,
		ScaleType = Type.enum(Enum.ScaleType),
		SliceCenter = Type.optional(Type.Rect),
		Body = Types.Area,
	}),
	Type.strictInterface({
		Type = Type.literal("Engine"),
		Style = Type.enum(Enum.FrameStyle),
	})
)

export type Motion = {
	Slide: TweenInfo, -- a panel that comes in from off the screen + leaves the same way
	Open: TweenInfo, -- one that grows from where it's anchored
	Close: TweenInfo,
}
Types.Motion = Type.strictInterface({
	Slide = Type.TweenInfo,
	Open = Type.TweenInfo,
	Close = Type.TweenInfo,
})

-- what's different about a button for as long as the pointer is on it or it's held down. whatever is left out stays as
-- it's drawn at rest
export type ButtonTint = {
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	ImageColor3: Color3?,
	ImageTransparency: number?,
}
Types.ButtonTint = Type.strictInterface({
	BackgroundColor3 = Type.optional(Type.Color3),
	BackgroundTransparency = Type.optional(Type.numberConstrained(0, 1)),
	ImageColor3 = Type.optional(Type.Color3),
	ImageTransparency = Type.optional(Type.numberConstrained(0, 1)),
})

-- what shuts a panel: a picture, or a word on a box where there's no art to press
export type ExitButtonLook =
	{
		Type: "Image",
		Image: string,
		Size: UDim2,
		-- a game whose buttons only do what the engine does to them by itself has neither
		Hover: ButtonTint?,
		Press: ButtonTint?,
	}
	| {
		Type: "Text",
		Text: string,
		Size: UDim2,
		FontFace: Font,
		TextColor3: Color3,
		BackgroundColor3: Color3,
		BorderColor3: Color3,
		BorderSizePixel: number,
	}
Types.ExitButtonLook = Type.union(
	Type.strictInterface({
		Type = Type.literal("Image"),
		Image = Type.string,
		Size = Type.UDim2,
		Hover = Type.optional(Types.ButtonTint),
		Press = Type.optional(Types.ButtonTint),
	}),
	Type.strictInterface({
		Type = Type.literal("Text"),
		Text = Type.string,
		Size = Type.UDim2,
		FontFace = Type.Font,
		TextColor3 = Type.Color3,
		BackgroundColor3 = Type.Color3,
		BorderColor3 = Type.Color3,
		BorderSizePixel = Type.numberMin(0),
	})
)

export type ServerIdLook = {
	-- left out, the text stands on nothing
	Backing: {
		BackgroundColor3: Color3,
		BorderColor3: Color3,
	}?,
	FontFace: Font,
	TextColor3: Color3,
	TextSize: number?, -- left out, it's scaled to its box
	-- left out, it's centered the way the engine does it
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
}
Types.ServerIdLook = Type.strictInterface({
	Backing = Type.optional(Type.strictInterface({
		BackgroundColor3 = Type.Color3,
		BorderColor3 = Type.Color3,
	})),
	FontFace = Type.Font,
	TextColor3 = Type.Color3,
	TextSize = Type.optional(Type.numberPositive),
	TextXAlignment = Type.optional(Type.enum(Enum.TextXAlignment)),
	TextYAlignment = Type.optional(Type.enum(Enum.TextYAlignment)),
})

export type BalanceCounterLook = {
	BackgroundColor3: Color3,
	BackgroundTransparency: number?, -- left out, nothing is seen through its box
	BorderColor3: Color3,
	BorderSizePixel: number,
	-- what a balance is written in, every currency has one
	TextColors: {
		Credits: Color3,
		Gems: Color3,
		[PseudoEnum.Currency]: Color3,
	},
	FontFace: Font?, -- left out, it's written like a heading
	-- what stands before the amount. left out, the amount is followed by what its currency is called
	Prefix: string?,
	TextStrokeTransparency: number?, -- left out, the text has no outline
	TextXAlignment: Enum.TextXAlignment?, -- left out, it's centered the way the engine does it
}
Types.BalanceCounterLook = Type.strictInterface({
	BackgroundColor3 = Type.Color3,
	BackgroundTransparency = Type.optional(Type.numberConstrained(0, 1)),
	BorderColor3 = Type.Color3,
	BorderSizePixel = Type.numberMin(0),
	TextColors = Type.intersection(
		Type.strictInterface({
			Credits = Type.Color3,
			Gems = Type.Color3,
		}),
		Type.map(EconomyType.Currency, Type.Color3)
	),
	FontFace = Type.optional(Type.Font),
	Prefix = Type.optional(Type.string),
	TextStrokeTransparency = Type.optional(Type.numberConstrained(0, 1)),
	TextXAlignment = Type.optional(Type.enum(Enum.TextXAlignment)),
})

export type NameTagLook = {
	FontFace: Font,
	TextColor3: Color3,
	TextSize: number?, -- left out, it's scaled to its box
	TextStrokeColor3: Color3?, -- left out, it's the black the engine outlines a text in
	TextStrokeTransparency: number,
	MaxDistance: number?, -- how many studs off it's still read from. left out, there's no end to that
	Name: Placement,
	-- where what somebody tells about themselves is read in place of their name. left out, a tag only ever names
	Bio: Placement?,
	-- where what somebody plays by is read, in a game where that's their own pick. left out, a tag doesn't say
	Mode: Placement?,
	-- what's read on somebody who has no name yet. left out, it's what roblox knows them as
	Placeholder: string?,
	-- the sign over the head of somebody who's in a menu. left out, they're tagged like anybody else
	Away: {
		Text: string,
		FontFace: Font,
		TextColor3: Color3,
	}?,
}
Types.NameTagLook = Type.strictInterface({
	FontFace = Type.Font,
	TextColor3 = Type.Color3,
	TextSize = Type.optional(Type.numberPositive),
	TextStrokeColor3 = Type.optional(Type.Color3),
	TextStrokeTransparency = Type.numberConstrained(0, 1),
	MaxDistance = Type.optional(Type.numberPositive),
	Name = Types.Placement,
	Bio = Type.optional(Types.Placement),
	Mode = Type.optional(Types.Placement),
	Placeholder = Type.optional(Type.string),
	Away = Type.optional(Type.strictInterface({
		Text = Type.string,
		FontFace = Type.Font,
		TextColor3 = Type.Color3,
	})),
})

export type DialogLook = {
	-- the bar a button of it is drawn on. left out, a button is a box with the border of the look
	ButtonImage: string?,
	-- a dialog that's a plain card filling the frame it's handed, with what it says scaled into the parts of it. left
	-- out, it's drawn on the panel of the look
	Card: {
		BackgroundColor3: Color3,
		BorderColor3: Color3,
		BorderSizePixel: number,
		FontFace: Font,
		TitleColor3: Color3, -- the title is written straight onto the card, it stands on no tag
		TextColor3: Color3,
		-- where each part of it is, in scale of the card
		Title: Area,
		Body: Area,
		Buttons: Area, -- the row its buttons share
	}?,
}
Types.DialogLook = Type.strictInterface({
	ButtonImage = Type.optional(Type.string),
	Card = Type.optional(Type.strictInterface({
		BackgroundColor3 = Type.Color3,
		BorderColor3 = Type.Color3,
		BorderSizePixel = Type.numberMin(0),
		FontFace = Type.Font,
		TitleColor3 = Type.Color3,
		TextColor3 = Type.Color3,
		Title = Types.Area,
		Body = Types.Area,
		Buttons = Types.Area,
	})),
})

-- what a widget of the kit doesn't share with the rest of it, under the name of its component
export type Widgets = {
	BalanceCounter: BalanceCounterLook,
	Dialog: DialogLook,
	ExitButton: ExitButtonLook,
	NameTag: NameTagLook,
	ServerId: ServerIdLook,
}
Types.Widgets = Type.strictInterface({
	BalanceCounter = Types.BalanceCounterLook,
	Dialog = Types.DialogLook,
	ExitButton = Types.ExitButtonLook,
	NameTag = Types.NameTagLook,
	ServerId = Types.ServerIdLook,
})

-- how a game looks. every game answers for every part of it, so a widget that reads one is drawn in all of them
export type Style = {
	Palette: Palette,
	Fonts: Fonts,
	TextSizes: TextSizes,
	Border: Border,
	Panel: PanelLook,
	Motion: Motion,
	Widgets: Widgets,
}
Types.Style = Type.strictInterface({
	Palette = Types.Palette,
	Fonts = Types.Fonts,
	TextSizes = Types.TextSizes,
	Border = Types.Border,
	Panel = Types.PanelLook,
	Motion = Types.Motion,
	Widgets = Types.Widgets,
})
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return Types
