--!strict
-- pulls a single instance out of a place file as an rbxm, the output is what unpack-rbxm expects as input. a whole
-- map comes out through export-map, which does the same for every piece its config lists
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
-- Packages
-- Modules
local Place = require("../modules/place")
-- Types
type Output = { path: string, contents: string }
type Options = {
	placePath: string,
	instPath: string,
	outPath: string,
	isSplitByChild: boolean,
	isScriptStripped: boolean,
	knownScriptsPath: string?,
	reportPath: string?,
}
-- Constants
local USAGE = "Usage: lune run scripts/util/export-rbxm.lune.luau <place.rbxl> <Service/Path/To/Instance> "
	.. "<out.rbxm or directory> [--children | -c] [--strip-scripts | -s] "
	.. "[--known-scripts <list.tsv>] [--report <stripped.tsv>]\n"
	.. '       a name that siblings share says which of them it means: "Workspace/Terrain#2". a "/" inside of a name '
	.. 'is spelled "%2F", a "#" is "%23" and a "%" is "%25"'
-- the flags that are followed by a path of their own
local VALUE_FLAGS = { "--known-scripts", "--report" }
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): Options
	local paths: { string } = {}
	local values: { [string]: string } = {}
	local isSplitByChild = false
	local isScriptStripped = false
	local valueFlag: string? = nil
	for _, arg in args do
		if valueFlag then
			values[valueFlag] = (arg:gsub("\\", "/"))
			valueFlag = nil
		elseif arg == "--children" or arg == "-c" then
			isSplitByChild = true
		elseif arg == "--strip-scripts" or arg == "-s" then
			isScriptStripped = true
		elseif table.find(VALUE_FLAGS, arg) then
			valueFlag = arg
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(paths, (arg:gsub("\\", "/")))
		end
	end
	assert(valueFlag == nil, `Expected a path after {valueFlag}\n{USAGE}`)
	assert(#paths == 3, `Expected a place, an instance path and an output path\n{USAGE}`)
	local knownScriptsPath, reportPath = values["--known-scripts"], values["--report"]
	assert(
		isScriptStripped or (knownScriptsPath == nil and reportPath == nil),
		`--known-scripts and --report are about the scripts that --strip-scripts leaves behind\n{USAGE}`
	)
	return {
		placePath = paths[1],
		instPath = paths[2],
		outPath = paths[3],
		isSplitByChild = isSplitByChild,
		isScriptStripped = isScriptStripped,
		knownScriptsPath = knownScriptsPath,
		reportPath = reportPath,
	}
end

local function getChildOutputs(dir: string, inst: roblox.Instance): { Output }
	local outputs: { Output } = {}
	local children = inst:GetChildren()
	-- same duplicate naming as unpack-rbxm, so both tools agree on what a sibling is called
	local reserved: { [string]: boolean } = {}
	local used: { [string]: boolean } = {}
	for _, child in children do
		reserved[child.Name:lower()] = true
	end
	for _, child in children do
		local childName = child.Name
		local suffix = 0
		while used[childName:lower()] do
			repeat
				suffix += 1
				childName = `{child.Name}_{suffix}`
			until not reserved[childName:lower()] and not used[childName:lower()]
		end
		used[childName:lower()] = true
		assert(
			Place.getIfFileName(childName),
			`Invalid filename: {childName}\nrojo names an instance after its file, so "{child.Name}" can't be a file `
				.. `of its own: export "{inst.Name}" whole instead`
		)
		if childName ~= child.Name then
			-- rojo names an instance after its file, the built place will have it under the new name
			print(`"{child.Name}" shares its name with a sibling, it's exported as "{childName}"`)
		end
		table.insert(outputs, {
			path = `{dir}/{childName}.rbxm`,
			contents = (Place.serialize(child)),
		})
	end
	return outputs
end
-- Class
do
	local options = parseArgs(process.args)
	assert(fs.isFile(options.placePath), `No place file found at "{options.placePath}"`)
	local place = roblox.deserializePlace(fs.readFile(options.placePath))
	local inst = Place.findInstance(place, options.instPath)
	local refusal = Place.getRefusal(place, inst)
	assert(refusal == nil, `"{options.instPath}" isn't exported: {refusal}`)

	local stripped: { Place.StrippedScript } = {}
	if options.isScriptStripped then
		local knownScriptsPath = options.knownScriptsPath
		stripped = Place.stripScripts(inst, if knownScriptsPath then Place.readKnownScripts(knownScriptsPath) else nil)
		for _, strippedScript in stripped do
			print(`stripped {strippedScript.className} "{inst.Name}/{strippedScript.path}"`)
		end
	end

	local outputs: { Output }
	local dir: string
	if options.isSplitByChild then
		dir = options.outPath
		outputs = getChildOutputs(dir, inst)
		assert(#outputs > 0, `"{options.instPath}" has no children to export`)
	else
		assert(options.outPath:lower():match("%.rbxm$"), `Expected an .rbxm output path: {options.outPath}`)
		local parentDir = options.outPath:match("^(.*)/[^/]+$")
		dir = if parentDir == "" then "/" else parentDir or "."
		outputs = { { path = options.outPath, contents = (Place.serialize(inst)) } }
	end

	-- reject collisions before touching the disk
	for _, output in outputs do
		assert(not fs.isFile(output.path) and not fs.isDir(output.path), `Output already exists: {output.path}`)
	end
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
	for _, output in outputs do
		fs.writeFile(output.path, output.contents)
		print(`wrote "{output.path}"`)
	end
	if options.isScriptStripped then
		-- what was written is read back, a script that's still in there is never left for a build to pick up
		for _, output in outputs do
			Place.countWritten(output.path)
		end
		print(`{#stripped} script(s) stripped, none in the output`)
	end
	local reportPath = options.reportPath
	if reportPath then
		fs.writeFile(reportPath, Place.getStrippedReport(stripped))
		print(`wrote "{reportPath}"`)
	end
	print("export complete")
end
