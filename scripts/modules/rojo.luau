--!strict
-- Services
-- Packages
-- Modules
-- Types
export type JSONValue = boolean | number | string | { JSONValue } | { [string]: JSONValue }
-- Explicit Rojo values are tagged objects whose payload may contain nested
-- arrays/objects (CFrames, sequences, fonts, attributes, etc.). No userdata.
export type StrictPropertyValue = { [string]: JSONValue }
export type PropertyValue = JSONValue
export type NodeProperties = {
	[string]: PropertyValue,
	Attributes: {
		Attributes: { [string]: StrictPropertyValue },
	}?,
	Tags: { string }?,
}
export type ProjectNode =
	{
		["$className"]: string,
		["$properties"]: NodeProperties?,
		[string]: ProjectNode,
	}
	| {
		["$path"]: string,
		["$properties"]: NodeProperties?,
		[string]: ProjectNode,
	}

export type ProjectJSON = {
	name: string,
	tree: ProjectNode,
	[string]: nil, -- I'll add the other properties as I need them
}
export type MetaJSON = {
	className: string,
	properties: NodeProperties?,
}
export type ModelNode = {
	Name: string,
	ClassName: string,
	Properties: NodeProperties?,
	Children: { ModelNode }?,
}
export type ModelJSON = {
	ClassName: string,
	Properties: NodeProperties?,
	Children: { ModelNode }?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

return Module
