--!strict
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local function pascalToKebab(path: string): string
	local pathSegments = path:split("/")
	local file = table.remove(pathSegments, #pathSegments)
	assert(file, `bad file`)
	local fileParts = file:split("%p")
	local str = table.remove(fileParts, 1)
	assert(str, `bad file name`)
	local ext = table.concat(fileParts, ".")
	local dir = table.concat(pathSegments, "/")
	local noSpace = string.gsub(str, "%s+", "")
	local kebab = string.gsub(noSpace, "(%a)(%u)", "%1-%2")
	print(`moving from "{str}" to "{string.lower(kebab)}"`)
	if fs.isFile(path) then
		return dir .. "/" .. string.lower(kebab) .. "." .. ext
	else
		return dir .. "/" .. string.lower(kebab)
	end
end
if fs.isDir(process.args[1]) then
	for i, file in fs.readDir(process.args[1]) do
		fs.move(process.args[1] .. "/" .. file, "temp")
		fs.move("temp", pascalToKebab(process.args[1] .. "/" .. file))
	end
elseif fs.isFile(process.args[1]) then
	fs.move(process.args[1], "temp")
	fs.move("temp", pascalToKebab(process.args[1]))
else
	print(`unknown path "{process.args[1]}"`)
	process.exit(1)
end
process.exit(0)
