local placeholder_env = require('env')
export type placeholder = placeholder_env.placeholder
export type env = placeholder_env.env

return table.freeze {
	change_log = require('changelog'),
	versions = require('versions'),
	commits = require('commits'),
	env = placeholder_env,
}
