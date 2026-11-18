--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Types
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

-- what a panel is drawn as when it has no art of its own: a box, or one picture laid over the frame that carries it
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

export type ExitButtonLook = {
	Image: string,
	Size: UDim2,
	-- a game whose buttons only do what the engine does to them by itself has neither
	Hover: ButtonTint?,
	Press: ButtonTint?,
}
Types.ExitButtonLook = Type.strictInterface({
	Image = Type.string,
	Size = Type.UDim2,
	Hover = Type.optional(Types.ButtonTint),
	Press = Type.optional(Types.ButtonTint),
})

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

-- what a widget of the kit doesn't share with the rest of it, under the name of its component
export type Widgets = {
	ExitButton: ExitButtonLook,
	ServerId: ServerIdLook,
}
Types.Widgets = Type.strictInterface({
	ExitButton = Types.ExitButtonLook,
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
