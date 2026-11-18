--!strict
-- every place of every universe in the deploy config is this code, built with the switches of that place + published
-- to it. what goes where is all in the config, this only walks it
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
-- Packages
-- Modules
-- Types
type Env = { [string]: string }
type PlaceConfig = {
	place_id: number,
	version_type: string?,
	env: { [string]: any }?,
}
type UniverseConfig = {
	universe_id: number,
	api_key_env: string,
	env: { [string]: any }?,
	places: { [string]: PlaceConfig },
}
type DeployConfig = {
	universes: { [string]: UniverseConfig },
}
-- Constants
local DEFAULT_CONFIG_PATH = "deploy.yml"
local BUILD_PATH = "build"
local DEFAULT_VERSION_TYPE = "published"
local VERSION_TYPES = { "published", "saved" }
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

local function run(program: string, params: { string }, env: Env?)
	local result = process.exec(program, params, {
		env = env,
		stdio = "inherit",
	})
	assert(result.ok, `"{program} {table.concat(params, " ")}" failed with code {result.code}`)
end

local function readConfig(path: string): DeployConfig
	assert(fs.isFile(path), `no deploy config at "{path}"`)
	local config = serde.decode("yaml", fs.readFile(path))
	assert(type(config.universes) == "table", `"{path}" has no universes`)
	for universeName, universe in config.universes do
		local at = `universe "{universeName}"`
		assert(type(universe.universe_id) == "number", `{at} needs a universe_id`)
		assert(type(universe.api_key_env) == "string", `{at} needs an api_key_env`)
		assert(type(universe.places) == "table", `{at} has no places`)
		for placeName, place in universe.places do
			at = `place "{placeName}" of universe "{universeName}"`
			assert(type(place.place_id) == "number", `{at} needs a place_id`)
			assert(
				place.version_type == nil or table.find(VERSION_TYPES, place.version_type) ~= nil,
				`{at} has a version_type that's neither "published" nor "saved"`
			)
		end
	end
	return config
end

-- what the build scripts of one place are run with. its own word comes last, so it has the say over its universe
local function getBuildEnv(universe: UniverseConfig, place: PlaceConfig, projectPath: string): Env
	local env: Env = {
		PROJECT = projectPath,
	}
	-- an id that isn't filled in yet is left unset, which the build scripts know how to take
	if universe.universe_id > 0 then
		env.UNIVERSE_ID = tostring(universe.universe_id)
	end
	if place.place_id > 0 then
		env.PLACE_ID = tostring(place.place_id)
	end
	for otherName, other in universe.places do
		if other.place_id > 0 then
			local key = string.upper((string.gsub(otherName, "[^%w]", "_")))
			env[`{key}_PLACE_ID`] = tostring(other.place_id)
		end
	end
	for _, extra: { [string]: any }? in { universe.env, place.env } do
		for key, value in extra or {} do
			env[key] = tostring(value)
		end
	end
	return env
end
-- Class
do
	local config = readConfig(getEnv("DEPLOY_CONFIG") or DEFAULT_CONFIG_PATH)
	local universeFilter = getEnv("UNIVERSE")
	local placeFilter = getEnv("PLACE")
	-- builds everything without sending any of it anywhere
	local isDryRun = getEnv("DRY_RUN") == "true"
	local count = 0

	for _, universeName in getSortedKeys(config.universes) do
		if universeFilter and universeFilter ~= universeName then
			continue
		end
		local universe = config.universes[universeName]
		for _, placeName in getSortedKeys(universe.places) do
			if placeFilter and placeFilter ~= placeName then
				continue
			end
			local place = universe.places[placeName]
			-- a project file names its sources relative to itself, so it's written next to the default one
			local projectPath = `{universeName}-{placeName}.project.json`
			local rbxlPath = `{BUILD_PATH}/{universeName}/{placeName}.rbxl`
			local env = getBuildEnv(universe, place, projectPath)
			count += 1

			print(`\nbuilding {universeName}/{placeName}`)
			fs.writeDir(`{BUILD_PATH}/{universeName}`)
			local isBuilt, msg = pcall(function()
				run("lune", { "run", "scripts/proj/config.lune.luau" }, env)
				run("lune", { "run", "scripts/proj/build-config.lune.luau" }, env)
				run("rojo", { "build", projectPath, "-o", rbxlPath })
			end)
			-- whether it built or not, the project file was only there for this
			if fs.isFile(projectPath) then
				fs.removeFile(projectPath)
			end
			assert(isBuilt, msg)

			if isDryRun then
				print(`dry run: {rbxlPath} isn't published`)
				continue
			end
			assert(
				universe.universe_id > 0 and place.place_id > 0,
				`{universeName}/{placeName} has no ids to publish to yet`
			)
			local apiKey = getEnv(universe.api_key_env)
			assert(apiKey, `the key of {universeName} is read from {universe.api_key_env}, which isn't set`)
			print(`publishing {universeName}/{placeName} to place {place.place_id}`)
			run("rbxcloud", {
				"experience",
				"publish",
				"--filename",
				rbxlPath,
				"--place-id",
				tostring(place.place_id),
				"--universe-id",
				tostring(universe.universe_id),
				"--version-type",
				place.version_type or DEFAULT_VERSION_TYPE,
			}, {
				RBXCLOUD_API_KEY = apiKey :: string,
			})
		end
	end

	-- the last place built isn't what a terminal or an open studio expects to find
	run("lune", { "run", "scripts/proj/build-config.lune.luau" })
	assert(count > 0, `nothing in the deploy config matches what was asked for`)
	print(`\n{count} place(s) {if isDryRun then "built" else "published"}`)
end
