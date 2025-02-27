local version = require('@utils/version')
export type version = version.version

local commit = require('commit')
export type commit = commit.semantic_commit

local placeholder_env = require('@config/env')
local changelog = require('changelog')
local branch = require('branch')

-- module
return table.freeze {
	placeholder_env = placeholder_env,
	changelog = changelog,
	version = version,
	branch = branch,
	commit = commit,
}
