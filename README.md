A library to enforce semantics in your git repository. You should to use together [ernisto/git](https://github.com/ernisto/git)

# Installation
this module officially can be installed only via [pesde](https://github.com/pesde-pkg/pesde)
```bash
pesde add ernisto/semantic_git
```

# Documentation

## Version
Utilities related with [semantic version](https://semver.org/)
```luau
function is_valid(input: string): raw_semver?

assert(is_valid("1.2.3"))
assert(is_valid("v1.2.3"))
assert(is_valid("v1.2.3-beta+sha.3BD94F65"))
assert(not is_valid("version 1.2"))
```
```luau
function try_parse(input: string): version?
function parse(input: raw_version): version

local maybe_ver = version.try_parse("v1.2.3") --> version
local ver = version.parse("v1.2.3") --> version

local maybe_ver = version.try_parse("version 1.2") --> nil
local ver = version.try_parse("version 1.2") --> error
```
```luau
function new_from(version: version, patch: partial_version): version

local v1 = version.parse("1.2.3")
local v2 = version.new_from(v1, { patch = 3 })
assert(v2.patch == 3 and v2.minor == 2 and v2.patch == 3)
```
```luau
function is_latest(version1: version, version2: version): boolean
function is_oldest(version1: version, version2: version): boolean

local v1 = { major = 1, minor = 2, patch = 3 }
local v2 = { major = 1, minor = 3, patch = 0 }
assert(version.is_oldest(v1, v2))
assert(version.is_latest(v2, v1))

table.sort({v1, v2}, version.is_latest)
```
```luau
function tostring(version: version): raw_string

assert(
    version.tostring({ major = 1, minor = 2, patch = 3 }) == "1.2.3"
) 
```

## Commit
```luau
function try_parse(commit: git.commit): semantic_commit?
function parse(commit: git.commit): semantic_commit

local commit = parse(git.commit.read_from_id(id))

print('commit', id)
for kind, kind_captures in commit.kinds do
    print(kind, '{', kind_captures, '}')
end
```
```luau
function index_commits_by_kind(commit_ids: {git.sha1}): { [kind]: {semantic_commit} }

for kind, commits in index_commits_by_kind() do
    print('COMMITS OF KIND', kind)
    for _,commit in commits do print(commit) end
end
```

## Branch
```luau
function get_prev_version(branch: git.head): (version?, {git.sha1})

local current_branch = git.branch.read_current()
local prev_version, post_commit_ids = get_prev_version(current_branch)
```
```luau
function eval_update_level(commit_ids: {git.sha1}): version?

local current_branch = git.branch.read_current()
local prev_version, post_commit_ids = get_prev_version(current_branch)

local update_level = eval_update_level(post_commit_ids)
if update_level then
    print(`we need increase the version`)
else
    warn(`no relevant updates`)
end
```
```luau
function get_next_version(branch: git.head, prev_version: version, commit_ids: {git.sha1}): version?

local current_branch = git.branch.read_current()
local prev_version, post_commit_ids = get_prev_version(current_branch)
local new_version = get_next_version(current_branch, prev_version, post_commit_ids)

if not new_version then
    warn(`no relevant updates`)
end
```

## Change log
```luau
function write(env: config.env, path: path)

local env = config.env:extends {
    version = branch.get_current_version()
}
changelog.write(env, "CHANGELOG.md")
```