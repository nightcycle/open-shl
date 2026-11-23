--!strict
-- every place of every universe in the deploy config is this code, built with the switches of that place + published
-- to it. what goes where is all in the config, this only walks it. all of it is built before any of it is published,
-- so a place that doesn't build leaves every other one as it was. one without an id yet is built + left at that
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
-- Packages
-- Modules
local deploy = require("../modules/deploy")
-- Types
type Env = deploy.Env
type PlaceConfig = deploy.PlaceConfig
type UniverseConfig = deploy.UniverseConfig
type Build = {
	universeName: string,
	placeName: string,
	universe: UniverseConfig,
	place: PlaceConfig,
	rbxlPath: string,
}
-- Constants
local BUILD_PATH = "build"
local DEFAULT_VERSION_TYPE = "published"
-- nobody opens a story in a place that's live, so what's built here goes without them. a place that wants them all the
-- same says so in the env of its config
local DEFAULT_STORIES_ENABLED = "false"
-- the harness answers whoever is in the place it runs in, which can only ever be an agent in studio. no place of the
-- config gets a say in this one
local HARNESS_ENABLED = "false"
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
-- Class
do
	local config = deploy.readConfig(getEnv("DEPLOY_CONFIG") or deploy.DEFAULT_CONFIG_PATH)
	local universeFilter = getEnv("UNIVERSE")
	local placeFilter = getEnv("PLACE")
	-- builds everything without sending any of it anywhere
	local isDryRun = getEnv("DRY_RUN") == "true"
	local builds: { Build } = {}

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
			local env = deploy.getBuildEnv(universe, place)
			env.PROJECT = projectPath
			env.STORIES_ENABLED = env.STORIES_ENABLED or DEFAULT_STORIES_ENABLED
			env.HARNESS_ENABLED = HARNESS_ENABLED

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
			table.insert(builds, {
				universeName = universeName,
				placeName = placeName,
				universe = universe,
				place = place,
				rbxlPath = rbxlPath,
			})
		end
	end

	-- the last place built isn't what a terminal or an open studio expects to find
	run("lune", { "run", "scripts/proj/build-config.lune.luau" })
	assert(#builds > 0, `nothing in the deploy config matches what was asked for`)

	-- nothing goes out before all of it is built + every key is there, so a run that fails this far has changed no place
	print("")
	local uploads: { Build } = {}
	for _, build in builds do
		if build.universe.universe_id <= 0 or build.place.place_id <= 0 then
			print(`{build.universeName}/{build.placeName} skipped: no id yet`)
		elseif isDryRun then
			print(`dry run: {build.rbxlPath} isn't published`)
		else
			assert(
				getEnv(build.universe.api_key_env),
				`the key of {build.universeName} is read from {build.universe.api_key_env}, which isn't set`
			)
			table.insert(uploads, build)
		end
	end

	for _, build in uploads do
		print(`publishing {build.universeName}/{build.placeName} to place {build.place.place_id}`)
		run("rbxcloud", {
			"experience",
			"publish",
			"--filename",
			build.rbxlPath,
			"--place-id",
			tostring(build.place.place_id),
			"--universe-id",
			tostring(build.universe.universe_id),
			"--version-type",
			build.place.version_type or DEFAULT_VERSION_TYPE,
		}, {
			RBXCLOUD_API_KEY = getEnv(build.universe.api_key_env) :: string,
		})
	end

	print(`\n{#builds} place(s) built, {#uploads} published`)
end
