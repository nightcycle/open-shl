--!strict
-- Services
-- Packages
-- Modules
-- Types
type StrictPropertyValue =
	{
		Color3: { number },
	}
	| {
		Bool: boolean,
	}
	| {
		Float32: number,
	}
	| {
		String: string,
	}
	| {
		Vector3: { number },
	}
	| {
		Vector2: { number },
	}
	| {
		CFrame: {
			position: { number },
			orientation: { number },
		},
	}
	| {
		UDim: { number },
	}
	| {
		UDim2: { number },
	}
type PropertyValue = boolean | number | { number } | string | StrictPropertyValue
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
	Children: { ModelNode },
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

return Module
