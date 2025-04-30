local serde = require('@lune/serde')
local fs = require('@lune/fs')

local read_or_create = require('@utils/read_or_create')
local env = require('@config/env')
local git = require('@pkg/git')

-- types
type lua_regex = string
export type config = {
	pre_release: { [any]: pre_release },
	build_metadata: build_metadata,
	major: field,
	minor: field,
	patch: field,
}
export type pre_release = { match_branch: lua_regex, fields: { env.placeholder } }
export type build_metadata = {
	default: { env.placeholder },
	force: { env.placeholder }?,
}
export type field = {
	overwrite: number | 'current'?,
	commit_kinds: { string },
}

-- defs
local current_path = string.match(debug.info(1, 's'), '^%[string "(.+)"%]')
local default_content = fs.readFile(`{current_path}/../semantic-version.yaml`)

-- functions
local function get_or_create(): config
	local raw = read_or_create('.github/semantic-version.yaml', default_content)
	return serde.decode('yaml', raw)
end
local function compute_pre_release(config: config, branch: git.head): { string }?
	local variables = {
		commit = git.commit.read_from_id(branch.commit_id),
	}
	for index, branch_pre_release in config.pre_release do
		local matching_branch = branch_pre_release.match_branch
		if matching_branch then
			local captures = { string.match(branch.name, matching_branch) }
			if #captures == 0 then continue end

			variables.captures = captures
		end
		assert(branch_pre_release.fields, `missing field 'fields' from pre-release '{index}'`)
		return env.compute_fields(env:extends(variables), branch_pre_release.fields)
	end
	return
end

-- module
return table.freeze {
	get_or_create = get_or_create,
	compute_pre_release = compute_pre_release,
}
