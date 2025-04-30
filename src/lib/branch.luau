local semantic_commit = require('@lib/commit')
local version = require('@utils/version')
local config = require('@config/init')
local git = require('@pkg/git')

-- code
local version_config = config.versions.get_or_create()

-- functions
local function get_prev_version(branch: git.head): (version.version?, { git.sha1 })
	local function is_version_tag(ref: git.ref)
		return ref.kind == 'tags' and version.try_parse(ref.name)
	end
	local result = git.query.ref_by_later_commit {
		commit_id = branch.commit_id,
		predicate = is_version_tag,
	}
	local tag = result.ref or error(`no version tag found`)
	return version.parse(tag.name), result.later_commit_ids
end
local function eval_update_level(commit_ids: { git.sha1 }): number?
	local commits_by_kind = semantic_commit.index_commits_by_kind(commit_ids)
	for _, commit_kind in version_config.major.commit_kinds do
		if #commits_by_kind[commit_kind] > 0 then return 3 end
	end
	for _, commit_kind in version_config.minor.commit_kinds do
		if #commits_by_kind[commit_kind] > 0 then return 2 end
	end
	for _, commit_kind in version_config.patch.commit_kinds do
		if #commits_by_kind[commit_kind] > 0 then return 1 end
	end
	return
end

local function get_next_pre_release(branch: git.head, last_version: version.version): { string }?
	local pre_release = config.versions.compute_pre_release(version_config, branch)
	if not pre_release then return end

	local last_pre_release = last_version and last_version.pre_release
	if not last_pre_release then return pre_release end

	local is_same = table.concat(pre_release, '.') == table.concat(last_pre_release, '.', 1, #pre_release)
	if not is_same then return pre_release end

	local last_accumulator = tonumber(last_pre_release[#pre_release + 1])
	if not last_accumulator then return pre_release end

	table.insert(pre_release, tostring(last_accumulator + 1))
	return pre_release
end
local function get_next_version(
	branch: git.head,
	prev_version: version.version,
	commit_ids: { git.sha1 }
): version.version?
	local update_level = eval_update_level(commit_ids)
	if not update_level then return end

	local new_version: version.partial_version = {}
	local env = config.env:extends {
		commit = git.commit.read_from_id(branch.commit_id),
	}

	local pre_release = get_next_pre_release(branch, prev_version)
	if not pre_release then
		local locked_fields =
			{ version_config.patch.overwrite, version_config.minor.overwrite, version_config.major.overwrite }
		local current_fields = { prev_version.patch, prev_version.minor, prev_version.major }
		while
			locked_fields[update_level]
			and (tonumber(locked_fields[update_level]) or 0) <= current_fields[update_level]
		do
			update_level -= 1
		end

		new_version = if update_level == 1
			then { patch = prev_version.patch + 1 }
			elseif update_level == 2 then { minor = prev_version.minor + 1, patch = 0 }
			elseif update_level == 3 then { major = prev_version.major + 1, minor = 0, patch = 0 }
			else { build_metadata = env:compute_fields(version_config.build_metadata.default) }
	end
	return version.new_from(version.new_from(prev_version, new_version), {
		major = tonumber(version_config.major.overwrite or ''),
		minor = tonumber(version_config.minor.overwrite or ''),
		patch = tonumber(version_config.patch.overwrite or ''),
		pre_release = pre_release or {},
		build_metadata = if version_config.build_metadata.force
			then env:compute_fields(version_config.build_metadata.force)
			else new_version.build_metadata or {},
	})
end

-- module
return table.freeze {
	eval_update_level = eval_update_level,
	get_next_version = get_next_version,
	get_prev_version = get_prev_version,
}
