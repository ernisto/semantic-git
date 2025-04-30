local read_or_create = require('@utils/read_or_create')
local serde = require('@lune/serde')
local fs = require('@lune/fs')

-- defs
local current_path = string.match(debug.info(1, 's'), '^%[string "(.+)"%]')
local default_content = fs.readFile(`{current_path}/../semantic-changelog.yaml`)

-- functions
local function get_or_create()
	local raw = read_or_create('.github/semantic-changelog.yaml', default_content)
	return serde.decode('yaml', raw)
end

-- module
return table.freeze {
	get_or_create = get_or_create,
}
