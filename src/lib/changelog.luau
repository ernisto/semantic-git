local env = require('@config/env')
local config = require('@config/init')
local fs = require('@lune/fs')

-- init
local changelog_config = config.change_log.get_or_create()

export type node = string | {
	title: node,
	body: { node }?,
	list: {
		from: node,
		map: node,
	}?,
}
local function format(env: env.env, node: node, ancestry: { string }): string
	if typeof(node) == 'string' then return tostring(env:compute(node)) end
	ancestry = table.clone(ancestry)
	local body = ''

	if node.list then
		assert(typeof(node.list.from) == 'string', `invalid list.from ({table.concat(ancestry, '.')})`)
		local from = env:compute(node.list.from) or {}
		assert(typeof(from) == 'table', `invalid evaluated list.from ({table.concat(ancestry, '.')})`)

		if #from == 0 and not next(from) then return '' end
		for index, value in from do
			table.insert(ancestry, index)
			local iter_env = env:extends { index = index, value = value }
			body ..= format(iter_env, node.list.map, ancestry) .. '\n'
			table.remove(ancestry)
		end
	end
	local children: { node }? = if typeof(node.body) == 'string' then { node.body } else node.body
	if children then
		for index, child in children do
			table.insert(ancestry, tostring(index))
			body ..= format(env, child, ancestry)
			table.remove(ancestry)
		end
	end
	return (if node.title then `{string.rep('#', #ancestry + 1)} {format(env, node.title, {})}\n` else '') .. body
end
local function write(env: env.env, path: string)
	fs.writeFile(path, format(env, changelog_config, {}))
end

-- module
return table.freeze {
	write = write,
}
