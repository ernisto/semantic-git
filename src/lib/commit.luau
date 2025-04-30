local git = require('@pkg/git')
local regex = require('@lune/regex')
local config = require('@config/init')

local commit_config = config.commits.get_or_create()
local capture_fields = table.freeze(commit_config.commit.captures)

-- cache
local kind_by_field = {}
local dynamic_matched_kinds = table.clone(commit_config.kinds)
local commit_matcher = regex.new(commit_config.commit.match)

for field, value in commit_config.commit.captures do
	local fields = {}
	kind_by_field[field] = fields

	for kind_name, kind in commit_config.kinds do
		kind.name = kind_name

		local eq_value = kind[`eq_{field}`]
		if not eq_value then continue end

		dynamic_matched_kinds[kind_name] = nil
		fields[eq_value] = kind
	end
end

-- functions
export type kind = string
export type semantic_commit = git.commit & { kinds: { [string]: { string } } }

local cache = {}
local function try_parse(commit: git.commit): semantic_commit?
	if cache[commit] then return cache[commit] end

	local captures = commit_matcher:captures(commit.message.raw)
	if not captures then return end

	local semantic_commit = table.clone(commit) :: any
	semantic_commit.kinds = {}

	for field, index in capture_fields do
		local capture = captures:get(index :: number)
		local value = capture and capture.text
		semantic_commit[field] = value

		if not capture then continue end
		for kind_name, kind in dynamic_matched_kinds do
			local kind_captures = {}

			local matcher = kind[`match_{field}`]
			if matcher then kind_captures = { string.match(value, matcher) } end

			local lower_matcher = kind[`match_lower_{field}`]
			if lower_matcher then kind_captures = { string.match(string.lower(value), lower_matcher) } end

			if #kind_captures == 0 then continue end
			semantic_commit.kinds[kind_name] = table.freeze(kind_captures)
		end
		local kind = kind_by_field[field][value]
		if kind then semantic_commit.kinds[kind.name] = table.freeze {} end
	end
	assert(next(semantic_commit.kinds), `this commit dont match with any kind '{commit.message.title}'`)

	cache[commit] = semantic_commit
	table.freeze(semantic_commit.kinds)
	return table.freeze(semantic_commit)
end
local function parse(commit: git.commit): semantic_commit
	return try_parse(commit) or error(`invalid commit {commit.id} ({commit.message.title})`)
end

local function index_commits_by_kind(commit_ids: { git.sha1 }): { [kind]: { semantic_commit } }
	local commits_by_kind = {}
	for name in commit_config.kinds do
		commits_by_kind[name] = {}
	end

	for _, commit_id in commit_ids do
		local commit = git.commit.read_from_id(commit_id)
		local semcom = parse(commit)

		for name in semcom.kinds do
			table.insert(commits_by_kind[name], semcom)
		end
	end
	return commits_by_kind
end

-- module
return table.freeze {
	index_commits_by_kind = index_commits_by_kind,
	try_parse = try_parse,
	parse = parse,
}
