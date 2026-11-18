--!strict
-- prints what the pipeline builds one place of the deploy config with, as lines a shell takes in:
--   eval "$(UNIVERSE=shl2 PLACE=roleplay lune run scripts/proj/env.lune.luau)"
-- from then on the build scripts of that terminal make the place the pipeline would. whatever another place of the
-- config is built with + this one isn't gets unset, so going from one to the next leaves nothing of the last behind
-- Services
local process = require("@lune/process")
-- Packages
-- Modules
local deploy = require("../modules/deploy")
-- Types
-- Constants
local NAME_PATTERN = "^[%a_][%w_]*$"
-- Variables
-- References
-- Private Functions
-- a workflow hands an input that was left empty over as an empty string, which counts as unset
local function getEnv(name: string): string?
	local value = process.env[name]
	if value == nil or value == "" then
		return nil
	end
	return value
end

local function getSortedKeys(dict: { [string]: any }): { string }
	local keys: { string } = {}
	for key in dict do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

-- a value is free to hold anything, the one thing single quotes can't is another of them
local function quote(value: string): string
	return `'{(string.gsub(value, "'", "'\\''"))}'`
end
-- Class
do
	local config = deploy.readConfig(getEnv("DEPLOY_CONFIG") or deploy.DEFAULT_CONFIG_PATH)
	local universeName = getEnv("UNIVERSE") or ""
	local universe = config.universes[universeName]
	assert(
		universe,
		`UNIVERSE must be one of {table.concat(getSortedKeys(config.universes), ", ")}, received "{universeName}"`
	)
	local placeName = getEnv("PLACE") or ""
	local place = universe.places[placeName]
	assert(place, `PLACE must be one of {table.concat(getSortedKeys(universe.places), ", ")}, received "{placeName}"`)
	local env = deploy.getBuildEnv(universe, place)

	local isLeftover: { [string]: boolean } = {}
	for _, otherUniverse in config.universes do
		for _, otherPlace in otherUniverse.places do
			for name in deploy.getBuildEnv(otherUniverse, otherPlace) do
				isLeftover[name] = env[name] == nil
			end
		end
	end

	local lines: { string } = {}
	for _, name in getSortedKeys(isLeftover) do
		assert(string.match(name, NAME_PATTERN), `"{name}" isn't a name a shell can export`)
		if isLeftover[name] then
			table.insert(lines, `unset {name}`)
		end
	end
	for _, name in getSortedKeys(env) do
		table.insert(lines, `export {name}={quote(env[name])}`)
	end
	print(table.concat(lines, "\n"))
end
