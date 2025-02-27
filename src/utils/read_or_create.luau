local fs = require('@lune/fs')

-- module
local function read_or_create(path: string, default_content: string): (string, string?)
	local ancestors = string.split(path, '/')
	local file_name = table.remove(ancestors) or error(`no path provided`)

	local safe_dir = ''
	local missing_dir

	for index, name in ancestors do
		safe_dir ..= name .. '/'
		if missing_dir == nil and fs.isDir(safe_dir) then continue end

		missing_dir = path:sub(#safe_dir - #name)
		fs.writeDir(safe_dir)
	end
	safe_dir ..= file_name

	if missing_dir == nil and fs.isFile(safe_dir) then return fs.readFile(safe_dir) end
	fs.writeFile(safe_dir, default_content)

	warn(
		`Could not possible find config '{path}'. A default config was been created (missing {missing_dir or file_name})`
	)
	return default_content
end

return read_or_create
